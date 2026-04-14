'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { resolveUiLanguage, t } from '../../lib/ui_strings';

type InspectionStatus = 'SUBMITTED' | 'RECEIVED';

type InspectionItem = {
  id: number;
  jobId: number;
  fieldAgentId: number;
  protocolId: string;
  status: string;
  submittedAt: string;
  updatedAt: string;
};

type InspectionListResponse = {
  page: number;
  size: number;
  total: number;
  summary?: {
    receivedToday: number;
    pendingIntake: number;
    syncErrors: number;
    submitted: number;
  };
  items: InspectionItem[];
};

type InspectionDetail = {
  id: number;
  submissionId?: number;
  jobId: number;
  tenantId: string;
  fieldAgentId: number;
  idempotencyKey: string;
  protocolId: string;
  status: string;
  submittedAt: string;
  updatedAt: string;
  payload: unknown;
};

async function extractErrorMessage(response: Response, fallback: string): Promise<string> {
  try {
    const payload = await response.json() as { error?: string; message?: string };
    return payload.error || payload.message || fallback;
  } catch {
    return fallback;
  }
}

export default function BackofficeInspectionsPage() {
  const uiLanguage = useMemo(() => resolveUiLanguage(), []);
  const [items, setItems] = useState<InspectionItem[]>([]);
  const [status, setStatus] = useState<string>('');
  const [from, setFrom] = useState<string>('');
  const [to, setTo] = useState<string>('');
  const [fieldAgentId, setFieldAgentId] = useState<string>('');
  const [page, setPage] = useState<number>(0);
  const [size, setSize] = useState<number>(10);
  const [total, setTotal] = useState<number>(0);
  const [backendSummary, setBackendSummary] = useState({
    receivedToday: 0,
    pendingIntake: 0,
    syncErrors: 0,
    submitted: 0
  });
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [selected, setSelected] = useState<InspectionDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState<boolean>(false);

  const loadInspections = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams({ page: String(page), size: String(size) });
      if (status.trim()) params.set('status', status.trim().toUpperCase());
      if (from.trim()) params.set('from', new Date(from).toISOString());
      if (to.trim()) params.set('to', new Date(to).toISOString());
      if (fieldAgentId.trim()) params.set('fieldAgentId', fieldAgentId.trim());

      const response = await fetch(`/api/inspections?${params.toString()}`);
      if (!response.ok) {
        throw new Error(
          await extractErrorMessage(
            response,
            `${t(uiLanguage, 'queryInspectionsFailed')} (${response.status})`,
          ),
        );
      }

      const data: InspectionListResponse = await response.json();
      setItems(data.items ?? []);
      setTotal(data.total ?? 0);
      setBackendSummary({
        receivedToday: data.summary?.receivedToday ?? 0,
        pendingIntake: data.summary?.pendingIntake ?? 0,
        syncErrors: data.summary?.syncErrors ?? 0,
        submitted: data.summary?.submitted ?? 0
      });
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : t(uiLanguage, 'unexpectedLoadInspections'),
      );
    } finally {
      setLoading(false);
    }
  }, [fieldAgentId, from, page, size, status, to, uiLanguage]);

  const loadDetail = useCallback(async (inspectionId: number) => {
    setDetailLoading(true);
    setError(null);

    try {
      const response = await fetch(`/api/inspections/${inspectionId}`);
      if (!response.ok) {
        throw new Error(
          await extractErrorMessage(
            response,
            `${t(uiLanguage, 'queryDetailFailed')} (${response.status})`,
          ),
        );
      }
      const data: InspectionDetail = await response.json();
      setSelected(data);
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : t(uiLanguage, 'unexpectedLoadDetail'),
      );
    } finally {
      setDetailLoading(false);
    }
  }, [uiLanguage]);

  useEffect(() => {
    loadInspections();
  }, [loadInspections]);

  const summary = useMemo(() => {
    return {
      total,
      submitted: backendSummary.submitted,
      received: backendSummary.pendingIntake,
      today: backendSummary.receivedToday,
      syncErrors: backendSummary.syncErrors
    };
  }, [backendSummary.pendingIntake, backendSummary.receivedToday, backendSummary.submitted, backendSummary.syncErrors, total]);

  const totalPages = useMemo(() => {
    if (size <= 0) {
      return 1;
    }
    return Math.max(1, Math.ceil(total / size));
  }, [size, total]);

  const pageLabel = useMemo(() => `${page + 1} / ${totalPages}`, [page, totalPages]);

  return (
    <main className="inspections-shell">
      <section className="header">
        <div>
          <p className="eyebrow">BOW-123</p>
          <h1>{t(uiLanguage, 'inspectionsReceived')}</h1>
          <p className="subtitle">{t(uiLanguage, 'inspectionsSubtitle')}</p>
        </div>
        <a className="ghost" href="/">{t(uiLanguage, 'backToDashboard')}</a>
      </section>

      <section className="stats-grid">
        <article className="stat-card"><span>{t(uiLanguage, 'totalFiltered')}</span><strong>{summary.total}</strong></article>
        <article className="stat-card"><span>{t(uiLanguage, 'receivedTodayPage')}</span><strong>{summary.today}</strong></article>
        <article className="stat-card"><span>{t(uiLanguage, 'pendingIntake')}</span><strong>{summary.received}</strong></article>
        <article className="stat-card"><span>{t(uiLanguage, 'syncErrors')}</span><strong>{summary.syncErrors}</strong></article>
      </section>

      <section className="filters">
        <label>
          {t(uiLanguage, 'status')}
          <select value={status} onChange={(event) => setStatus(event.target.value)}>
            <option value="">{uiLanguage === 'en' ? 'All' : 'Todos'}</option>
            <option value="SUBMITTED">SUBMITTED</option>
            <option value="RECEIVED">RECEIVED</option>
          </select>
        </label>
        <label>
          {t(uiLanguage, 'from')}
          <input type="datetime-local" value={from} onChange={(event) => setFrom(event.target.value)} />
        </label>
        <label>
          {t(uiLanguage, 'to')}
          <input type="datetime-local" value={to} onChange={(event) => setTo(event.target.value)} />
        </label>
        <label>
          {t(uiLanguage, 'fieldAgent')}
          <input value={fieldAgentId} onChange={(event) => setFieldAgentId(event.target.value)} placeholder="ID" />
        </label>
        <label>
          {t(uiLanguage, 'pageSize')}
          <select value={size} onChange={(event) => {
            setPage(0);
            setSize(Number(event.target.value));
          }}>
            <option value={10}>10</option>
            <option value={20}>20</option>
            <option value={50}>50</option>
          </select>
        </label>
        <button type="button" onClick={loadInspections}>{t(uiLanguage, 'applyFilters')}</button>
      </section>

      {error ? <div className="error-box">{error}</div> : null}

      <section className="content-grid">
        <article className="table-wrap">
          <div className="pagination-bar">
            <span>{uiLanguage === 'en' ? `Page ${pageLabel}` : `Pagina ${pageLabel}`}</span>
            <div className="pagination-actions">
              <button type="button" disabled={page <= 0 || loading} onClick={() => setPage((current) => Math.max(0, current - 1))}>
                {t(uiLanguage, 'previous')}
              </button>
              <button type="button" disabled={loading || page + 1 >= totalPages} onClick={() => setPage((current) => current + 1)}>
                {t(uiLanguage, 'next')}
              </button>
            </div>
          </div>
          {loading ? <p>{t(uiLanguage, 'loadingInspections')}</p> : null}
          {!loading ? (
            <table>
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Job</th>
                  <th>{t(uiLanguage, 'fieldAgent')}</th>
                  <th>{uiLanguage === 'en' ? 'Protocol' : 'Protocolo'}</th>
                  <th>{t(uiLanguage, 'status')}</th>
                  <th>{uiLanguage === 'en' ? 'Submitted at' : 'Submetido em'}</th>
                  <th>{uiLanguage === 'en' ? 'Action' : 'Acao'}</th>
                </tr>
              </thead>
              <tbody>
                {items.map((item) => (
                  <tr key={item.id}>
                    <td>{item.id}</td>
                    <td>{item.jobId}</td>
                    <td>{item.fieldAgentId}</td>
                    <td>{item.protocolId}</td>
                    <td>{item.status}</td>
                    <td>{new Date(item.submittedAt).toLocaleString(uiLanguage === 'en' ? 'en-US' : 'pt-BR')}</td>
                    <td>
                      <button type="button" onClick={() => loadDetail(item.id)}>{t(uiLanguage, 'detail')}</button>
                    </td>
                  </tr>
                ))}
                {items.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="empty-row">{t(uiLanguage, 'noInspectionsForFilters')}</td>
                  </tr>
                ) : null}
              </tbody>
            </table>
          ) : null}
        </article>

        <article className="detail-wrap">
          <h2>{t(uiLanguage, 'technicalDetail')}</h2>
          {detailLoading ? <p>{t(uiLanguage, 'loadingDetail')}</p> : null}
          {!detailLoading && !selected ? <p>{t(uiLanguage, 'selectInspectionForPayload')}</p> : null}
          {!detailLoading && selected ? (
            <>
              <dl>
                <dt>Inspection ID</dt><dd>{selected.id}</dd>
                <dt>Job ID</dt><dd>{selected.jobId}</dd>
                <dt>{uiLanguage === 'en' ? 'Protocol' : 'Protocolo'}</dt><dd>{selected.protocolId}</dd>
                <dt>{t(uiLanguage, 'status')}</dt><dd>{selected.status}</dd>
                <dt>Idempotency</dt><dd>{selected.idempotencyKey}</dd>
              </dl>
              <pre>{JSON.stringify(selected.payload, null, 2)}</pre>
            </>
          ) : null}
        </article>
      </section>

      <style jsx>{`
        .inspections-shell {
          max-width: 1200px;
          margin: 0 auto;
          padding: 28px 16px 56px;
        }

        .header {
          display: flex;
          justify-content: space-between;
          align-items: end;
          gap: 12px;
          border: 1px solid #d8deea;
          border-radius: 16px;
          padding: 16px;
          background: #f7f6f1;
        }

        .eyebrow {
          margin: 0;
          letter-spacing: 0.08em;
          text-transform: uppercase;
          color: #007ca0;
          font-size: 0.76rem;
          font-weight: 700;
        }

        h1 {
          margin: 6px 0;
        }

        .subtitle {
          margin: 0;
          color: #4f5d75;
        }

        .ghost {
          text-decoration: none;
          border: 1px solid #d8deea;
          border-radius: 10px;
          padding: 10px 14px;
          color: #172033;
          background: #fff;
          font-weight: 700;
        }

        .stats-grid {
          margin-top: 14px;
          display: grid;
          gap: 12px;
          grid-template-columns: repeat(4, minmax(0, 1fr));
        }

        .stat-card {
          border: 1px solid #d8deea;
          border-radius: 12px;
          padding: 12px;
          background: #fff;
        }

        .stat-card span {
          display: block;
          color: #4f5d75;
        }

        .stat-card strong {
          font-size: 1.5rem;
          color: #172033;
        }

        .filters {
          margin-top: 14px;
          display: grid;
          gap: 10px;
          grid-template-columns: repeat(6, minmax(0, 1fr));
          align-items: end;
        }

        .filters label {
          display: flex;
          flex-direction: column;
          gap: 6px;
          font-weight: 600;
          color: #2a3550;
        }

        .filters input,
        .filters select,
        .filters button {
          border: 1px solid #cdd6e6;
          border-radius: 10px;
          padding: 10px;
          font: inherit;
          background: #fff;
        }

        .filters button {
          cursor: pointer;
          font-weight: 700;
          background: linear-gradient(90deg, #00a5cf, #ff9f1c);
          color: #fff;
          border: none;
        }

        .error-box {
          margin-top: 12px;
          background: #fff1f0;
          border: 1px solid #ffc6c2;
          padding: 10px;
          border-radius: 10px;
          color: #8f1913;
        }

        .content-grid {
          margin-top: 14px;
          display: grid;
          gap: 12px;
          grid-template-columns: 1.3fr 1fr;
        }

        .table-wrap,
        .detail-wrap {
          border: 1px solid #d8deea;
          border-radius: 14px;
          padding: 12px;
          background: #fff;
          overflow: auto;
        }

        .pagination-bar {
          display: flex;
          justify-content: space-between;
          align-items: center;
          gap: 12px;
          margin-bottom: 10px;
        }

        .pagination-actions {
          display: flex;
          gap: 8px;
        }

        table {
          width: 100%;
          border-collapse: collapse;
        }

        th,
        td {
          border-bottom: 1px solid #edf1f7;
          text-align: left;
          padding: 10px 8px;
          font-size: 0.92rem;
          vertical-align: top;
        }

        th {
          background: #f5f8ff;
          color: #2a3550;
          font-weight: 700;
        }

        td button {
          border: 1px solid #d0d9ea;
          background: #fff;
          border-radius: 8px;
          padding: 6px 10px;
          cursor: pointer;
        }

        .empty-row {
          text-align: center;
          color: #5d6b84;
        }

        dl {
          display: grid;
          grid-template-columns: 120px 1fr;
          gap: 6px 10px;
        }

        dt {
          color: #4f5d75;
        }

        dd {
          margin: 0;
          font-weight: 600;
          color: #172033;
        }

        pre {
          background: #0f172a;
          color: #d5e4ff;
          padding: 12px;
          border-radius: 10px;
          overflow: auto;
          font-size: 0.78rem;
          margin: 0;
        }

        @media (max-width: 1080px) {
          .filters {
            grid-template-columns: repeat(2, minmax(0, 1fr));
          }

          .content-grid {
            grid-template-columns: 1fr;
          }

          .stats-grid {
            grid-template-columns: repeat(2, minmax(0, 1fr));
          }
        }
      `}</style>
    </main>
  );
}
