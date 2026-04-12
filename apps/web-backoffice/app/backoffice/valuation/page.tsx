'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';

type IntakeValidation = {
  result: string;
  validatedBy: number | null;
  validatedAt: string | null;
  notes: string | null;
  issues: unknown;
};

type ValuationProcessItem = {
  id: number;
  inspectionId: number;
  tenantId: string;
  status: string;
  method: string;
  assignedAnalystId: number | null;
  reportId: number | null;
  createdAt: string;
  updatedAt: string;
};

type ValuationProcessListResponse = {
  total: number;
  items: ValuationProcessItem[];
};

type ValuationProcessDetail = ValuationProcessItem & {
  latestIntakeValidation?: IntakeValidation | null;
};

async function extractErrorMessage(response: Response, fallback: string): Promise<string> {
  try {
    const payload = await response.json() as { error?: string; message?: string };
    return payload.error || payload.message || fallback;
  } catch {
    return fallback;
  }
}

export default function BackofficeValuationPage() {
  const [items, setItems] = useState<ValuationProcessItem[]>([]);
  const [selected, setSelected] = useState<ValuationProcessDetail | null>(null);
  const [statusFilter, setStatusFilter] = useState('');
  const [inspectionIdInput, setInspectionIdInput] = useState('');
  const [assignedAnalystIdInput, setAssignedAnalystIdInput] = useState('');
  const [validationResult, setValidationResult] = useState<'VALIDATED' | 'REJECTED'>('VALIDATED');
  const [validationNotes, setValidationNotes] = useState('');
  const [validationIssues, setValidationIssues] = useState('[]');
  const [loading, setLoading] = useState(true);
  const [detailLoading, setDetailLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const loadProcesses = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams();
      if (statusFilter.trim()) {
        params.set('status', statusFilter.trim());
      }

      const response = await fetch(`/api/valuation/processes?${params.toString()}`);
      if (!response.ok) {
        throw new Error(await extractErrorMessage(response, `Failed to load valuation processes (${response.status})`));
      }

      const payload: ValuationProcessListResponse = await response.json();
      setItems(payload.items ?? []);
      if (selected) {
        const refreshed = payload.items.find((item) => item.id === selected.id);
        if (!refreshed) {
          setSelected(null);
        }
      }
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while loading valuation processes');
    } finally {
      setLoading(false);
    }
  }, [selected, statusFilter]);

  const loadDetail = useCallback(async (processId: number) => {
    setDetailLoading(true);
    setError(null);

    try {
      const response = await fetch(`/api/valuation/processes/${processId}`);
      if (!response.ok) {
        throw new Error(await extractErrorMessage(response, `Failed to load valuation process detail (${response.status})`));
      }

      const payload: ValuationProcessDetail = await response.json();
      setSelected(payload);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while loading valuation detail');
    } finally {
      setDetailLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadProcesses();
  }, [loadProcesses]);

  const handleCreate = useCallback(async () => {
    setSubmitting(true);
    setError(null);
    setMessage(null);

    try {
      const inspectionId = Number(inspectionIdInput);
      const assignedAnalystId = assignedAnalystIdInput.trim().length > 0 ? Number(assignedAnalystIdInput) : null;

      if (!Number.isFinite(inspectionId) || inspectionId <= 0) {
        throw new Error('Inspection ID must be a positive number');
      }

      const response = await fetch('/api/valuation/processes', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Actor-Id': '9001'
        },
        body: JSON.stringify({
          inspectionId,
          method: 'BASIC',
          assignedAnalystId
        })
      });

      if (!response.ok) {
        throw new Error(await extractErrorMessage(response, `Failed to create valuation process (${response.status})`));
      }

      const payload: ValuationProcessDetail = await response.json();
      setMessage(`Valuation process ${payload.id} ready`);
      setInspectionIdInput('');
      await loadProcesses();
      await loadDetail(payload.id);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while creating valuation process');
    } finally {
      setSubmitting(false);
    }
  }, [assignedAnalystIdInput, inspectionIdInput, loadDetail, loadProcesses]);

  const handleValidateIntake = useCallback(async () => {
    if (!selected) {
      return;
    }

    setSubmitting(true);
    setError(null);
    setMessage(null);

    try {
      const parsedIssues = JSON.parse(validationIssues);
      const response = await fetch(`/api/valuation/processes/${selected.id}/validate-intake`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Actor-Id': '9001'
        },
        body: JSON.stringify({
          result: validationResult,
          issues: parsedIssues,
          notes: validationNotes
        })
      });

      if (!response.ok) {
        throw new Error(await extractErrorMessage(response, `Failed to validate intake (${response.status})`));
      }

      setMessage(`Intake ${validationResult.toLowerCase()} for process ${selected.id}`);
      await loadProcesses();
      await loadDetail(selected.id);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while validating intake');
    } finally {
      setSubmitting(false);
    }
  }, [loadDetail, loadProcesses, selected, validationIssues, validationNotes, validationResult]);

  const stats = useMemo(() => {
    const pendingIntake = items.filter((item) => item.status === 'PENDING_INTAKE').length;
    const readyForSign = items.filter((item) => item.status === 'READY_FOR_SIGN').length;
    return {
      total: items.length,
      pendingIntake,
      readyForSign
    };
  }, [items]);

  return (
    <main className="operations-shell">
      <section className="page-header">
        <div>
          <p className="eyebrow">FW-006 + BOW-140</p>
          <h1>Valuation intake workspace</h1>
          <p className="subtitle">
            Intake validation and process tracking over the real backend aggregates.
          </p>
        </div>
        <a className="ghost" href="/">Back to dashboard</a>
      </section>

      <section className="stats-grid">
        <article className="stat-card"><span>Total processes</span><strong>{stats.total}</strong></article>
        <article className="stat-card"><span>Pending intake</span><strong>{stats.pendingIntake}</strong></article>
        <article className="stat-card"><span>Ready for sign</span><strong>{stats.readyForSign}</strong></article>
      </section>

      <section className="workspace-grid">
        <article className="panel">
          <h2>Create or recover process</h2>
          <div className="form-grid">
            <label>
              Inspection ID
              <input value={inspectionIdInput} onChange={(event) => setInspectionIdInput(event.target.value)} placeholder="Inspection ID" />
            </label>
            <label>
              Assigned analyst ID
              <input value={assignedAnalystIdInput} onChange={(event) => setAssignedAnalystIdInput(event.target.value)} placeholder="Optional analyst ID" />
            </label>
          </div>
          <button type="button" disabled={submitting} onClick={handleCreate}>Create or recover</button>
        </article>

        <article className="panel">
          <h2>Filters</h2>
          <div className="form-grid">
            <label>
              Status
              <select value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)}>
                <option value="">All</option>
                <option value="PENDING_INTAKE">PENDING_INTAKE</option>
                <option value="INTAKE_VALIDATED">INTAKE_VALIDATED</option>
                <option value="INTAKE_REJECTED">INTAKE_REJECTED</option>
                <option value="PROCESSING">PROCESSING</option>
                <option value="READY_FOR_SIGN">READY_FOR_SIGN</option>
              </select>
            </label>
          </div>
          <button type="button" disabled={loading} onClick={() => void loadProcesses()}>Reload list</button>
        </article>
      </section>

      {error ? <div className="error-box">{error}</div> : null}
      {message ? <div className="message-box">{message}</div> : null}

      <section className="content-grid">
        <article className="panel table-panel">
          <h2>Processes</h2>
          {loading ? <p>Loading valuation processes...</p> : null}
          {!loading ? (
            <table>
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Inspection</th>
                  <th>Status</th>
                  <th>Method</th>
                  <th>Report</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {items.map((item) => (
                  <tr key={item.id}>
                    <td>{item.id}</td>
                    <td>{item.inspectionId}</td>
                    <td>{item.status}</td>
                    <td>{item.method}</td>
                    <td>{item.reportId ?? '-'}</td>
                    <td>
                      <button type="button" onClick={() => void loadDetail(item.id)}>Open</button>
                    </td>
                  </tr>
                ))}
                {items.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="empty-row">No valuation process found for the current filter.</td>
                  </tr>
                ) : null}
              </tbody>
            </table>
          ) : null}
        </article>

        <article className="panel detail-panel">
          <h2>Process detail</h2>
          {detailLoading ? <p>Loading process detail...</p> : null}
          {!detailLoading && !selected ? <p>Select a process to inspect or validate intake.</p> : null}
          {!detailLoading && selected ? (
            <>
              <dl>
                <dt>Process ID</dt><dd>{selected.id}</dd>
                <dt>Inspection ID</dt><dd>{selected.inspectionId}</dd>
                <dt>Status</dt><dd>{selected.status}</dd>
                <dt>Report ID</dt><dd>{selected.reportId ?? '-'}</dd>
                <dt>Assigned analyst</dt><dd>{selected.assignedAnalystId ?? '-'}</dd>
              </dl>

              <div className="validation-box">
                <h3>Validate intake</h3>
                <label>
                  Result
                  <select value={validationResult} onChange={(event) => setValidationResult(event.target.value as 'VALIDATED' | 'REJECTED')}>
                    <option value="VALIDATED">VALIDATED</option>
                    <option value="REJECTED">REJECTED</option>
                  </select>
                </label>
                <label>
                  Notes
                  <textarea value={validationNotes} onChange={(event) => setValidationNotes(event.target.value)} rows={3} />
                </label>
                <label>
                  Issues JSON
                  <textarea value={validationIssues} onChange={(event) => setValidationIssues(event.target.value)} rows={6} />
                </label>
                <button type="button" disabled={submitting} onClick={handleValidateIntake}>Submit intake validation</button>
              </div>

              <div className="json-box">
                <h3>Latest intake validation</h3>
                <pre>{JSON.stringify(selected.latestIntakeValidation ?? null, null, 2)}</pre>
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
        .content-grid { grid-template-columns: 1.2fr 1fr; }
        .form-grid {
          display: grid;
          gap: 10px;
          grid-template-columns: repeat(2, minmax(0, 1fr));
          margin-top: 12px;
        }
        label {
          display: flex;
          flex-direction: column;
          gap: 6px;
          color: #2a3550;
          font-weight: 600;
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
        .validation-box, .json-box { margin-top: 16px; }
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
          .workspace-grid, .content-grid, .stats-grid, .form-grid { grid-template-columns: 1fr; }
        }
      `}</style>
    </main>
  );
}
