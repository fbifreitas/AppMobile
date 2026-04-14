'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';

type JobSummary = {
  id: number;
  caseId: number;
  tenantId: string;
  title: string;
  status: string;
  assignedTo: number | null;
  deadlineAt: string | null;
  createdAt: string;
};

type JobPageResponse = {
  content: JobSummary[];
  totalElements: number;
};

type AssignmentInfo = {
  userId: number;
  offeredAt: string;
  respondedAt: string | null;
  response: string | null;
};

type JobDetail = JobSummary & {
  updatedAt: string;
  assignments: AssignmentInfo[];
};

type TimelineEntry = {
  fromStatus: string | null;
  toStatus: string;
  actorId: string;
  reason: string | null;
  occurredAt: string;
};

type JobTimeline = {
  jobId: number;
  entries: TimelineEntry[];
};

const DEFAULT_TENANT = 'tenant-default';
const DEFAULT_ACTOR = 'backoffice-operator';

function formatDateTime(value?: string | null): string {
  if (!value) {
    return '-';
  }

  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? value : parsed.toLocaleString('pt-BR');
}

export default function BackofficeJobsPage() {
  const [items, setItems] = useState<JobSummary[]>([]);
  const [status, setStatus] = useState('');
  const [tenantId, setTenantId] = useState(DEFAULT_TENANT);
  const [actorId, setActorId] = useState(DEFAULT_ACTOR);
  const [page, setPage] = useState(0);
  const [size, setSize] = useState(10);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [detailLoading, setDetailLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selected, setSelected] = useState<JobDetail | null>(null);
  const [timeline, setTimeline] = useState<JobTimeline | null>(null);
  const [assignUserId, setAssignUserId] = useState('');
  const [cancelReason, setCancelReason] = useState('');

  const loadJobs = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams({
        tenantId: tenantId.trim() || DEFAULT_TENANT,
        actorId: actorId.trim() || DEFAULT_ACTOR,
        page: String(page),
        size: String(size)
      });

      if (status.trim()) {
        params.set('status', status.trim().toUpperCase());
      }

      const response = await fetch(`/api/jobs?${params.toString()}`);
      if (!response.ok) {
        throw new Error(`Falha ao consultar jobs (${response.status})`);
      }

      const data: JobPageResponse = await response.json();
      setItems(data.content ?? []);
      setTotal(data.totalElements ?? 0);
      if ((data.content ?? []).length === 0) {
        setSelected(null);
        setTimeline(null);
      }
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Erro inesperado ao carregar jobs');
    } finally {
      setLoading(false);
    }
  }, [actorId, page, size, status, tenantId]);

  const loadJobContext = useCallback(async (jobId: number) => {
    setDetailLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams({
        tenantId: tenantId.trim() || DEFAULT_TENANT,
        actorId: actorId.trim() || DEFAULT_ACTOR
      });

      const [detailResponse, timelineResponse] = await Promise.all([
        fetch(`/api/jobs/${jobId}?${params.toString()}`),
        fetch(`/api/jobs/${jobId}/timeline?${params.toString()}`)
      ]);

      if (!detailResponse.ok) {
        throw new Error(`Falha ao carregar detalhe do job (${detailResponse.status})`);
      }

      if (!timelineResponse.ok) {
        throw new Error(`Falha ao carregar timeline do job (${timelineResponse.status})`);
      }

      const detailData: JobDetail = await detailResponse.json();
      const timelineData: JobTimeline = await timelineResponse.json();
      setSelected(detailData);
      setTimeline(timelineData);
      setAssignUserId(detailData.assignedTo != null ? String(detailData.assignedTo) : '');
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Erro inesperado ao carregar contexto do job');
    } finally {
      setDetailLoading(false);
    }
  }, [actorId, tenantId]);

  const refreshCurrentSelection = useCallback(async () => {
    if (!selected) {
      return;
    }
    await loadJobContext(selected.id);
  }, [loadJobContext, selected]);

  const handleAssign = useCallback(async () => {
    if (!selected) {
      return;
    }

    const normalizedUserId = Number(assignUserId);
    if (!Number.isFinite(normalizedUserId) || normalizedUserId <= 0) {
      setError('Informe um userId numerico valido para atribuir o job.');
      return;
    }

    setActionLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams({
        tenantId: tenantId.trim() || DEFAULT_TENANT,
        actorId: actorId.trim() || DEFAULT_ACTOR
      });

      const response = await fetch(`/api/jobs/${selected.id}/assign?${params.toString()}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId: normalizedUserId })
      });

      if (!response.ok) {
        throw new Error(`Falha ao atribuir job (${response.status})`);
      }

      await loadJobs();
      await refreshCurrentSelection();
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Erro inesperado ao atribuir job');
    } finally {
      setActionLoading(false);
    }
  }, [actorId, assignUserId, loadJobs, refreshCurrentSelection, selected, tenantId]);

  const handleCancel = useCallback(async () => {
    if (!selected) {
      return;
    }

    setActionLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams({
        tenantId: tenantId.trim() || DEFAULT_TENANT,
        actorId: actorId.trim() || DEFAULT_ACTOR
      });

      const response = await fetch(`/api/jobs/${selected.id}/cancel?${params.toString()}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reason: cancelReason.trim() || null })
      });

      if (!response.ok) {
        throw new Error(`Falha ao cancelar job (${response.status})`);
      }

      await loadJobs();
      await refreshCurrentSelection();
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Erro inesperado ao cancelar job');
    } finally {
      setActionLoading(false);
    }
  }, [actorId, cancelReason, loadJobs, refreshCurrentSelection, selected, tenantId]);

  const handleAccept = useCallback(async () => {
    if (!selected) {
      return;
    }

    setActionLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams({
        tenantId: tenantId.trim() || DEFAULT_TENANT,
        actorId: assignUserId.trim() || String(selected.assignedTo ?? "")
      });

      const response = await fetch(`/api/jobs/${selected.id}/accept?${params.toString()}`, {
        method: 'POST'
      });

      if (!response.ok) {
        throw new Error(`Falha ao aceitar job (${response.status})`);
      }

      await loadJobs();
      await refreshCurrentSelection();
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Erro inesperado ao aceitar job');
    } finally {
      setActionLoading(false);
    }
  }, [assignUserId, loadJobs, refreshCurrentSelection, selected, tenantId]);

  useEffect(() => {
    loadJobs();
  }, [loadJobs]);

  const totalPages = useMemo(() => {
    if (size <= 0) {
      return 1;
    }
    return Math.max(1, Math.ceil(total / size));
  }, [size, total]);

  return (
    <main className="ops-shell">
      <section className="ops-header">
        <div>
          <p className="eyebrow">FW-001 + FW-002</p>
          <h1>Jobs operacionais</h1>
          <p className="ops-subtitle">Lista, detalhe, timeline e acoes operacionais do job sem sair do backoffice.</p>
        </div>
        <div className="ops-header-actions">
          <a className="ghost" href="/backoffice/cases">Criar novo case</a>
          <a className="ghost" href="/">Voltar ao dashboard</a>
        </div>
      </section>

      <section className="ops-filters">
        <label>
          Tenant
          <input value={tenantId} onChange={(event) => setTenantId(event.target.value)} />
        </label>
        <label>
          Actor
          <input value={actorId} onChange={(event) => setActorId(event.target.value)} />
        </label>
        <label>
          Status
          <select value={status} onChange={(event) => setStatus(event.target.value)}>
            <option value="">Todos</option>
            <option value="ELIGIBLE_FOR_DISPATCH">ELIGIBLE_FOR_DISPATCH</option>
            <option value="OFFERED">OFFERED</option>
            <option value="ACCEPTED">ACCEPTED</option>
            <option value="AWAITING_SCHEDULING">AWAITING_SCHEDULING</option>
            <option value="IN_EXECUTION">IN_EXECUTION</option>
            <option value="FIELD_COMPLETED">FIELD_COMPLETED</option>
            <option value="SUBMITTED">SUBMITTED</option>
            <option value="CLOSED">CLOSED</option>
          </select>
        </label>
        <label>
          Tamanho
          <select value={size} onChange={(event) => {
            setPage(0);
            setSize(Number(event.target.value));
          }}>
            <option value={10}>10</option>
            <option value={20}>20</option>
            <option value={50}>50</option>
          </select>
        </label>
        <button type="button" onClick={loadJobs}>Aplicar filtros</button>
      </section>

      {error ? <div className="ops-error">{error}</div> : null}

      <section className="ops-grid">
        <article className="ops-card">
          <div className="ops-card-header">
            <div>
              <h2>Fila de jobs</h2>
              <p>{total} registros para os filtros atuais</p>
            </div>
            <div className="pagination-actions">
              <button type="button" disabled={page <= 0 || loading} onClick={() => setPage((current) => Math.max(0, current - 1))}>Anterior</button>
              <span>{page + 1} / {totalPages}</span>
              <button type="button" disabled={loading || page + 1 >= totalPages} onClick={() => setPage((current) => current + 1)}>Proxima</button>
            </div>
          </div>

          {loading ? <p>Carregando jobs...</p> : null}
          {!loading ? (
            <table>
              <thead>
                <tr>
                  <th>Job</th>
                  <th>Case</th>
                  <th>Status</th>
                  <th>Responsavel</th>
                  <th>Prazo</th>
                  <th>Acao</th>
                </tr>
              </thead>
              <tbody>
                {items.map((item) => (
                  <tr key={item.id}>
                    <td>
                      <strong>#{item.id}</strong>
                      <div>{item.title}</div>
                    </td>
                    <td>{item.caseId}</td>
                    <td>{item.status}</td>
                    <td>{item.assignedTo ?? '-'}</td>
                    <td>{formatDateTime(item.deadlineAt)}</td>
                    <td>
                      <button type="button" onClick={() => loadJobContext(item.id)}>Detalhe</button>
                    </td>
                  </tr>
                ))}
                {items.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="empty-row">Nenhum job encontrado para os filtros atuais.</td>
                  </tr>
                ) : null}
              </tbody>
            </table>
          ) : null}
        </article>

        <article className="ops-card">
          <div className="ops-card-header">
            <div>
              <h2>Detalhe do job</h2>
              <p>Timeline, assignments e acoes de despacho/cancelamento.</p>
            </div>
          </div>

          {detailLoading ? <p>Carregando detalhe...</p> : null}
          {!detailLoading && !selected ? <p>Selecione um job para consultar o contexto operacional.</p> : null}
          {!detailLoading && selected ? (
            <>
              <dl className="ops-detail-list">
                <dt>Job</dt><dd>#{selected.id}</dd>
                <dt>Case</dt><dd>{selected.caseId}</dd>
                <dt>Status</dt><dd>{selected.status}</dd>
                <dt>Tenant</dt><dd>{selected.tenantId}</dd>
                <dt>Criado em</dt><dd>{formatDateTime(selected.createdAt)}</dd>
                <dt>Atualizado em</dt><dd>{formatDateTime(selected.updatedAt)}</dd>
                <dt>Prazo</dt><dd>{formatDateTime(selected.deadlineAt)}</dd>
              </dl>

              <div className="ops-inline-form">
                <label>
                  userId para assign
                  <input value={assignUserId} onChange={(event) => setAssignUserId(event.target.value)} placeholder="Ex: 42" />
                </label>
                <button type="button" disabled={actionLoading} onClick={handleAssign}>Assign</button>
                <button type="button" disabled={actionLoading || selected.assignedTo == null} onClick={handleAccept}>Aceitar job</button>
              </div>

              <div className="ops-inline-form">
                <label>
                  Motivo do cancelamento
                  <input value={cancelReason} onChange={(event) => setCancelReason(event.target.value)} placeholder="Motivo opcional" />
                </label>
                <button type="button" disabled={actionLoading} onClick={handleCancel}>Cancelar job</button>
              </div>

              <section className="ops-subsection">
                <h3>Assignments</h3>
                {selected.assignments.length === 0 ? <p>Nenhum assignment registrado.</p> : (
                  <ul className="ops-list">
                    {selected.assignments.map((assignment) => (
                      <li key={`${assignment.userId}-${assignment.offeredAt}`}>
                        User {assignment.userId} | oferta {formatDateTime(assignment.offeredAt)} | resposta {assignment.response ?? '-'}
                      </li>
                    ))}
                  </ul>
                )}
              </section>

              <section className="ops-subsection">
                <h3>Timeline</h3>
                {!timeline || timeline.entries.length === 0 ? <p>Nenhum evento registrado.</p> : (
                  <ul className="ops-list">
                    {timeline.entries.map((entry, index) => (
                      <li key={`${entry.occurredAt}-${index}`}>
                        {entry.fromStatus ?? 'START'} -&gt; {entry.toStatus} | {entry.actorId} | {formatDateTime(entry.occurredAt)}
                        {entry.reason ? ` | ${entry.reason}` : ''}
                      </li>
                    ))}
                  </ul>
                )}
              </section>
            </>
          ) : null}
        </article>
      </section>
    </main>
  );
}
