'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';

type ReportItem = {
  id: number;
  valuationProcessId: number;
  tenantId: string;
  status: string;
  generatedBy: string | null;
  approvedBy: string | null;
  createdAt: string;
  updatedAt: string;
};

type ReportListResponse = {
  total: number;
  items: ReportItem[];
};

type ReportDetail = ReportItem & {
  reviewNotes: string | null;
  content: unknown;
};

const tenantId = 'tenant-default';

export default function BackofficeReportsPage() {
  const [items, setItems] = useState<ReportItem[]>([]);
  const [selected, setSelected] = useState<ReportDetail | null>(null);
  const [statusFilter, setStatusFilter] = useState('');
  const [valuationProcessIdInput, setValuationProcessIdInput] = useState('');
  const [reviewAction, setReviewAction] = useState<'APPROVE' | 'RETURN_FOR_CHANGES'>('APPROVE');
  const [reviewNotes, setReviewNotes] = useState('');
  const [loading, setLoading] = useState(true);
  const [detailLoading, setDetailLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const loadReports = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams({ tenantId });
      if (statusFilter.trim()) {
        params.set('status', statusFilter.trim());
      }

      const response = await fetch(`/api/reports?${params.toString()}`);
      if (!response.ok) {
        throw new Error(`Failed to load reports (${response.status})`);
      }

      const payload: ReportListResponse = await response.json();
      setItems(payload.items ?? []);
      if (selected) {
        const refreshed = payload.items.find((item) => item.id === selected.id);
        if (!refreshed) {
          setSelected(null);
        }
      }
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while loading reports');
    } finally {
      setLoading(false);
    }
  }, [selected, statusFilter]);

  const loadDetail = useCallback(async (reportId: number) => {
    setDetailLoading(true);
    setError(null);

    try {
      const response = await fetch(`/api/reports/${reportId}?tenantId=${tenantId}`);
      if (!response.ok) {
        throw new Error(`Failed to load report detail (${response.status})`);
      }

      const payload: ReportDetail = await response.json();
      setSelected(payload);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while loading report detail');
    } finally {
      setDetailLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadReports();
  }, [loadReports]);

  const handleGenerate = useCallback(async () => {
    setSubmitting(true);
    setError(null);
    setMessage(null);

    try {
      const valuationProcessId = Number(valuationProcessIdInput);
      if (!Number.isFinite(valuationProcessId) || valuationProcessId <= 0) {
        throw new Error('Valuation process ID must be a positive number');
      }

      const response = await fetch(`/api/reports/generate/${valuationProcessId}?tenantId=${tenantId}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Actor-Id': '9001'
        },
        body: JSON.stringify({})
      });

      if (!response.ok) {
        throw new Error(`Failed to generate report (${response.status})`);
      }

      const payload: ReportDetail = await response.json();
      setMessage(`Report ${payload.id} generated`);
      setValuationProcessIdInput('');
      await loadReports();
      await loadDetail(payload.id);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while generating report');
    } finally {
      setSubmitting(false);
    }
  }, [loadDetail, loadReports, valuationProcessIdInput]);

  const handleReview = useCallback(async () => {
    if (!selected) {
      return;
    }

    setSubmitting(true);
    setError(null);
    setMessage(null);

    try {
      const response = await fetch(`/api/reports/${selected.id}/review?tenantId=${tenantId}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Actor-Id': '9001'
        },
        body: JSON.stringify({
          action: reviewAction,
          notes: reviewNotes
        })
      });

      if (!response.ok) {
        throw new Error(`Failed to review report (${response.status})`);
      }

      setMessage(`Report ${selected.id} reviewed with action ${reviewAction}`);
      await loadReports();
      await loadDetail(selected.id);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while reviewing report');
    } finally {
      setSubmitting(false);
    }
  }, [loadDetail, loadReports, reviewAction, reviewNotes, selected]);

  const stats = useMemo(() => {
    const generated = items.filter((item) => item.status === 'GENERATED').length;
    const readyForSign = items.filter((item) => item.status === 'READY_FOR_SIGN').length;
    return {
      total: items.length,
      generated,
      readyForSign
    };
  }, [items]);

  return (
    <main className="operations-shell">
      <section className="page-header">
        <div>
          <p className="eyebrow">FW-007 + BOW-141</p>
          <h1>Basic report workspace</h1>
          <p className="subtitle">
            Generate and review report drafts backed by the valuation process state machine.
          </p>
        </div>
        <a className="ghost" href="/">Back to dashboard</a>
      </section>

      <section className="stats-grid">
        <article className="stat-card"><span>Total reports</span><strong>{stats.total}</strong></article>
        <article className="stat-card"><span>Generated</span><strong>{stats.generated}</strong></article>
        <article className="stat-card"><span>Ready for sign</span><strong>{stats.readyForSign}</strong></article>
      </section>

      <section className="workspace-grid">
        <article className="panel">
          <h2>Generate report</h2>
          <label>
            Valuation process ID
            <input value={valuationProcessIdInput} onChange={(event) => setValuationProcessIdInput(event.target.value)} placeholder="Valuation process ID" />
          </label>
          <button type="button" disabled={submitting} onClick={handleGenerate}>Generate draft</button>
        </article>

        <article className="panel">
          <h2>Filters</h2>
          <label>
            Status
            <select value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)}>
              <option value="">All</option>
              <option value="GENERATED">GENERATED</option>
              <option value="READY_FOR_SIGN">READY_FOR_SIGN</option>
              <option value="RETURNED">RETURNED</option>
            </select>
          </label>
          <button type="button" disabled={loading} onClick={() => void loadReports()}>Reload list</button>
        </article>
      </section>

      {error ? <div className="error-box">{error}</div> : null}
      {message ? <div className="message-box">{message}</div> : null}

      <section className="content-grid">
        <article className="panel table-panel">
          <h2>Reports</h2>
          {loading ? <p>Loading reports...</p> : null}
          {!loading ? (
            <table>
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Process</th>
                  <th>Status</th>
                  <th>Generated by</th>
                  <th>Updated</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {items.map((item) => (
                  <tr key={item.id}>
                    <td>{item.id}</td>
                    <td>{item.valuationProcessId}</td>
                    <td>{item.status}</td>
                    <td>{item.generatedBy ?? '-'}</td>
                    <td>{new Date(item.updatedAt).toLocaleString('en-US')}</td>
                    <td>
                      <button type="button" onClick={() => void loadDetail(item.id)}>Open</button>
                    </td>
                  </tr>
                ))}
                {items.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="empty-row">No report found for the current filter.</td>
                  </tr>
                ) : null}
              </tbody>
            </table>
          ) : null}
        </article>

        <article className="panel detail-panel">
          <h2>Report detail</h2>
          {detailLoading ? <p>Loading report detail...</p> : null}
          {!detailLoading && !selected ? <p>Select a report to inspect or review it.</p> : null}
          {!detailLoading && selected ? (
            <>
              <dl>
                <dt>Report ID</dt><dd>{selected.id}</dd>
                <dt>Process ID</dt><dd>{selected.valuationProcessId}</dd>
                <dt>Status</dt><dd>{selected.status}</dd>
                <dt>Generated by</dt><dd>{selected.generatedBy ?? '-'}</dd>
                <dt>Approved by</dt><dd>{selected.approvedBy ?? '-'}</dd>
              </dl>

              <div className="review-box">
                <h3>Review report</h3>
                <label>
                  Action
                  <select value={reviewAction} onChange={(event) => setReviewAction(event.target.value as 'APPROVE' | 'RETURN_FOR_CHANGES')}>
                    <option value="APPROVE">APPROVE</option>
                    <option value="RETURN_FOR_CHANGES">RETURN_FOR_CHANGES</option>
                  </select>
                </label>
                <label>
                  Notes
                  <textarea value={reviewNotes} onChange={(event) => setReviewNotes(event.target.value)} rows={4} />
                </label>
                <button type="button" disabled={submitting} onClick={handleReview}>Submit review</button>
              </div>

              <div className="json-box">
                <h3>Report content</h3>
                <pre>{JSON.stringify(selected.content, null, 2)}</pre>
              </div>
            </>
          ) : null}
        </article>
      </section>

      <style jsx>{`
        .operations-shell {
          max-width: 1280px;
          margin: 0 auto;
          padding: 28px 16px 56px;
        }
        .page-header {
          display: flex;
          justify-content: space-between;
          gap: 16px;
          align-items: end;
          background: #f7f6f1;
          border: 1px solid #d8deea;
          border-radius: 16px;
          padding: 18px;
        }
        .eyebrow {
          margin: 0;
          text-transform: uppercase;
          letter-spacing: 0.08em;
          color: #007ca0;
          font-size: 0.78rem;
          font-weight: 700;
        }
        h1, h2, h3 { margin: 0; }
        .subtitle { margin: 8px 0 0; color: #4f5d75; }
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
          grid-template-columns: repeat(3, minmax(0, 1fr));
        }
        .stat-card, .panel {
          border: 1px solid #d8deea;
          border-radius: 14px;
          background: #fff;
          padding: 14px;
        }
        .stat-card span { display: block; color: #4f5d75; }
        .stat-card strong { font-size: 1.5rem; color: #172033; }
        .workspace-grid, .content-grid {
          display: grid;
          gap: 12px;
          margin-top: 14px;
        }
        .workspace-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        .content-grid { grid-template-columns: 1.1fr 1fr; }
        label {
          display: flex;
          flex-direction: column;
          gap: 6px;
          color: #2a3550;
          font-weight: 600;
          margin-top: 12px;
        }
        input, select, textarea, button {
          border: 1px solid #cdd6e6;
          border-radius: 10px;
          padding: 10px;
          font: inherit;
          background: #fff;
        }
        button {
          margin-top: 12px;
          cursor: pointer;
          font-weight: 700;
          color: #fff;
          border: none;
          background: linear-gradient(90deg, #007ca0, #ff9f1c);
        }
        .error-box, .message-box {
          margin-top: 14px;
          border-radius: 10px;
          padding: 10px 12px;
        }
        .error-box {
          background: #fff1f0;
          border: 1px solid #ffc6c2;
          color: #8f1913;
        }
        .message-box {
          background: #eef9f1;
          border: 1px solid #bfe6ca;
          color: #175b2f;
        }
        .table-panel, .detail-panel { overflow: auto; }
        table {
          width: 100%;
          border-collapse: collapse;
          margin-top: 12px;
        }
        th, td {
          border-bottom: 1px solid #edf1f7;
          text-align: left;
          padding: 10px 8px;
          font-size: 0.92rem;
        }
        th { background: #f5f8ff; color: #2a3550; }
        .empty-row { text-align: center; color: #5d6b84; }
        dl {
          display: grid;
          grid-template-columns: 150px 1fr;
          gap: 6px 10px;
          margin-top: 12px;
        }
        dt { color: #4f5d75; }
        dd { margin: 0; font-weight: 600; color: #172033; }
        .review-box, .json-box { margin-top: 16px; }
        pre {
          margin: 8px 0 0;
          background: #0f172a;
          color: #d5e4ff;
          border-radius: 10px;
          padding: 12px;
          overflow: auto;
          font-size: 0.78rem;
        }
        @media (max-width: 1080px) {
          .workspace-grid, .content-grid, .stats-grid { grid-template-columns: 1fr; }
        }
      `}</style>
    </main>
  );
}
