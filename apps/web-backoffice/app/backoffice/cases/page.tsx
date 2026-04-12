'use client';

import type { FormEvent } from 'react';
import { useMemo, useState } from 'react';

type CreateCaseResponse = {
  caseId: number;
  caseNumber: string;
  jobId: number;
  jobStatus: string;
  createdAt: string;
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

export default function BackofficeCasesPage() {
  const [tenantId, setTenantId] = useState(DEFAULT_TENANT);
  const [actorId, setActorId] = useState(DEFAULT_ACTOR);
  const [number, setNumber] = useState('');
  const [propertyAddress, setPropertyAddress] = useState('');
  const [propertyLatitude, setPropertyLatitude] = useState('');
  const [propertyLongitude, setPropertyLongitude] = useState('');
  const [inspectionType, setInspectionType] = useState('ENTRY');
  const [deadline, setDeadline] = useState('');
  const [jobTitle, setJobTitle] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [createdCases, setCreatedCases] = useState<CreateCaseResponse[]>([]);

  const lastCreated = useMemo(() => createdCases[0] ?? null, [createdCases]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSubmitting(true);
    setError(null);

    try {
      const params = new URLSearchParams({
        tenantId: tenantId.trim() || DEFAULT_TENANT,
        actorId: actorId.trim() || DEFAULT_ACTOR
      });

      const response = await fetch(`/api/cases?${params.toString()}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          number: number.trim(),
          propertyAddress: propertyAddress.trim(),
          propertyLatitude: propertyLatitude.trim() ? Number(propertyLatitude) : null,
          propertyLongitude: propertyLongitude.trim() ? Number(propertyLongitude) : null,
          inspectionType,
          deadline: deadline ? new Date(deadline).toISOString() : null,
          jobTitle: jobTitle.trim()
        })
      });

      if (!response.ok) {
        throw new Error(`Falha ao criar case (${response.status})`);
      }

      const data: CreateCaseResponse = await response.json();
      setCreatedCases((current) => [data, ...current].slice(0, 5));
      setNumber('');
      setPropertyAddress('');
      setPropertyLatitude('');
      setPropertyLongitude('');
      setJobTitle('');
      setDeadline('');
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Erro inesperado ao criar case');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <main className="ops-shell">
      <section className="ops-header">
        <div>
          <p className="eyebrow">FW-003</p>
          <h1>Cases operacionais</h1>
          <p className="ops-subtitle">Criacao minima do case com job inicial e rastreabilidade imediata para a operacao.</p>
        </div>
        <div className="ops-header-actions">
          <a className="ghost" href="/backoffice/jobs">Abrir fila de jobs</a>
          <a className="ghost" href="/">Voltar ao dashboard</a>
        </div>
      </section>

      {error ? <div className="ops-error">{error}</div> : null}

      <section className="ops-grid">
        <article className="ops-card">
          <div className="ops-card-header">
            <div>
              <h2>Novo case</h2>
              <p>Fluxo minimo para iniciar atendimento web sem chamar a API manualmente.</p>
            </div>
          </div>

          <form className="ops-form" onSubmit={handleSubmit}>
            <label>
              Tenant
              <input value={tenantId} onChange={(event) => setTenantId(event.target.value)} />
            </label>
            <label>
              Actor
              <input value={actorId} onChange={(event) => setActorId(event.target.value)} />
            </label>
            <label>
              Numero do case
              <input value={number} onChange={(event) => setNumber(event.target.value)} required placeholder="CASE-2026-0001" />
            </label>
            <label>
              Endereco do imovel
              <input value={propertyAddress} onChange={(event) => setPropertyAddress(event.target.value)} required placeholder="Rua Exemplo, 100 - Centro" />
            </label>
            <label>
              Latitude do imovel
              <input value={propertyLatitude} onChange={(event) => setPropertyLatitude(event.target.value)} placeholder="-23.550520" />
            </label>
            <label>
              Longitude do imovel
              <input value={propertyLongitude} onChange={(event) => setPropertyLongitude(event.target.value)} placeholder="-46.633308" />
            </label>
            <label>
              Tipo de vistoria
              <select value={inspectionType} onChange={(event) => setInspectionType(event.target.value)}>
                <option value="ENTRY">ENTRY</option>
                <option value="EXIT">EXIT</option>
                <option value="PERIODIC">PERIODIC</option>
              </select>
            </label>
            <label>
              Deadline
              <input type="datetime-local" value={deadline} onChange={(event) => setDeadline(event.target.value)} />
            </label>
            <label className="ops-form-span">
              Titulo do job inicial
              <input value={jobTitle} onChange={(event) => setJobTitle(event.target.value)} required placeholder="Vistoria de entrada - apto 22" />
            </label>
            <button type="submit" disabled={submitting}>{submitting ? 'Criando...' : 'Criar case'}</button>
          </form>
        </article>

        <article className="ops-card">
          <div className="ops-card-header">
            <div>
              <h2>Rastreabilidade imediata</h2>
              <p>Consulta minima do que acabou de ser criado no fluxo web.</p>
            </div>
          </div>

          {!lastCreated ? <p>Nenhum case criado nesta sessao.</p> : (
            <>
              <dl className="ops-detail-list">
                <dt>Case</dt><dd>{lastCreated.caseNumber}</dd>
                <dt>Case ID</dt><dd>{lastCreated.caseId}</dd>
                <dt>Job ID</dt><dd>{lastCreated.jobId}</dd>
                <dt>Status do job</dt><dd>{lastCreated.jobStatus}</dd>
                <dt>Criado em</dt><dd>{formatDateTime(lastCreated.createdAt)}</dd>
              </dl>
              <a className="cta" href="/backoffice/jobs">Ir para fila de jobs</a>
            </>
          )}

          {createdCases.length > 1 ? (
            <section className="ops-subsection">
              <h3>Ultimos criados nesta sessao</h3>
              <ul className="ops-list">
                {createdCases.map((item) => (
                  <li key={`${item.caseId}-${item.jobId}`}>
                    {item.caseNumber} | job #{item.jobId} | {item.jobStatus}
                  </li>
                ))}
              </ul>
            </section>
          ) : null}
        </article>
      </section>
    </main>
  );
}
