'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';

type Overview = {
  totalRequests24h: number;
  errorRequests24h: number;
  retryOrDuplicateCount24h: number;
  operationalBacklog: number;
  pendingIntake: number;
  reportsReadyForSign: number;
  pendingConfigApprovals: number;
  alertCount: number;
};

type EndpointMetric = {
  endpointKey: string;
  totalRequests: number;
  successCount: number;
  warningCount: number;
  errorCount: number;
  retryCount: number;
  p95LatencyMs: number;
  lastHttpStatus: number | null;
  lastSeenAt: string | null;
};

type AlertItem = {
  code: string;
  severity: string;
  title: string;
  description: string;
  endpointKey: string;
  metricValue: number;
  triggeredAt: string | null;
};

type RecentEventItem = {
  occurredAt: string;
  channel: string;
  eventType: string;
  endpointKey: string | null;
  outcome: string;
  httpStatus: number | null;
  latencyMs: number | null;
  summary: string | null;
  correlationId: string | null;
  traceId: string | null;
  protocolId: string | null;
  jobId: number | null;
  processId: number | null;
  reportId: number | null;
};

type RetentionSummary = {
  retentionDays: number;
  trackedEvents: number;
  expiringEvents: number;
  oldestRetainedEventAt: string | null;
  lastCleanupAt: string | null;
  lastCleanupDeletedCount: number;
};

type ContinuitySummary = {
  status: string;
  checklist: Array<{
    code: string;
    status: string;
    title: string;
    action: string;
  }>;
};

type ControlTowerResponse = {
  generatedAt: string;
  overview: Overview;
  endpointMetrics: EndpointMetric[];
  alerts: AlertItem[];
  recentEvents: RecentEventItem[];
  retention: RetentionSummary;
  continuity: ContinuitySummary;
};

const tenantId = 'tenant-default';

export default function BackofficeOperationsPage() {
  const [dashboard, setDashboard] = useState<ControlTowerResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [runningRetention, setRunningRetention] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const loadDashboard = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const response = await fetch(`/api/operations/control-tower?tenantId=${tenantId}`);
      if (!response.ok) {
        throw new Error(`Failed to load control tower (${response.status})`);
      }

      const payload: ControlTowerResponse = await response.json();
      setDashboard(payload);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while loading control tower');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadDashboard();
  }, [loadDashboard]);

  const handleRunRetention = useCallback(async () => {
    setRunningRetention(true);
    setError(null);
    setMessage(null);

    try {
      const response = await fetch(`/api/operations/control-tower/retention/run?tenantId=${tenantId}`, {
        method: 'POST',
        headers: {
          'X-Actor-Id': '9001'
        }
      });
      if (!response.ok) {
        throw new Error(`Failed to run retention cleanup (${response.status})`);
      }

      const payload = (await response.json()) as { deletedEvents: number };
      setMessage(`Retention cleanup executed. Deleted events: ${payload.deletedEvents}`);
      await loadDashboard();
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unexpected error while running retention cleanup');
    } finally {
      setRunningRetention(false);
    }
  }, [loadDashboard]);

  const cards = useMemo(() => {
    if (!dashboard) {
      return [];
    }
    return [
      ['Requests 24h', dashboard.overview.totalRequests24h],
      ['Errors 24h', dashboard.overview.errorRequests24h],
      ['Retries / duplicates', dashboard.overview.retryOrDuplicateCount24h],
      ['Operational backlog', dashboard.overview.operationalBacklog],
      ['Pending intake', dashboard.overview.pendingIntake],
      ['Ready for sign', dashboard.overview.reportsReadyForSign],
      ['Pending config approvals', dashboard.overview.pendingConfigApprovals],
      ['Active alerts', dashboard.overview.alertCount]
    ];
  }, [dashboard]);

  return (
    <main className="operations-shell">
      <section className="page-header">
        <div>
          <p className="eyebrow">FW-005 + BOW-150 + INT-009/010/018/019/020</p>
          <h1>Operational control tower</h1>
          <p className="subtitle">
            Unified operational visibility for config, finalized inspections, valuation and reports.
          </p>
        </div>
        <div className="hero-actions">
          <a className="ghost" href="/">Back to dashboard</a>
          <button type="button" disabled={runningRetention} onClick={() => void handleRunRetention()}>
            {runningRetention ? 'Running retention...' : 'Run retention cleanup'}
          </button>
          <button type="button" disabled={loading} onClick={() => void loadDashboard()}>
            Reload control tower
          </button>
        </div>
      </section>

      {error ? <div className="error-box">{error}</div> : null}
      {message ? <div className="message-box">{message}</div> : null}

      <section className="stats-grid">
        {cards.map(([label, value]) => (
          <article className="stat-card" key={label}>
            <span>{label}</span>
            <strong>{value}</strong>
          </article>
        ))}
      </section>

      {loading ? <p>Loading control tower...</p> : null}

      {!loading && dashboard ? (
        <>
          <section className="workspace-grid">
            <article className="panel">
              <h2>Active alerts</h2>
              <div className="list-stack">
                {dashboard.alerts.map((alert) => (
                  <div className="status-row" key={`${alert.code}-${alert.triggeredAt}`}>
                    <strong>{alert.severity}</strong>
                    <div>
                      <p>{alert.title}</p>
                      <small>{alert.endpointKey} • metric {alert.metricValue}</small>
                    </div>
                  </div>
                ))}
                {dashboard.alerts.length === 0 ? <p>No active alerts for the current tenant.</p> : null}
              </div>
            </article>

            <article className="panel">
              <h2>Retention and continuity</h2>
              <dl>
                <dt>Retention days</dt><dd>{dashboard.retention.retentionDays}</dd>
                <dt>Tracked events</dt><dd>{dashboard.retention.trackedEvents}</dd>
                <dt>Expiring events</dt><dd>{dashboard.retention.expiringEvents}</dd>
                <dt>Last cleanup</dt><dd>{dashboard.retention.lastCleanupAt ? new Date(dashboard.retention.lastCleanupAt).toLocaleString('en-US') : '-'}</dd>
                <dt>Deleted on last cleanup</dt><dd>{dashboard.retention.lastCleanupDeletedCount}</dd>
                <dt>Continuity status</dt><dd>{dashboard.continuity.status}</dd>
              </dl>
            </article>
          </section>

          <section className="panel table-panel">
            <h2>Endpoint metrics</h2>
            <table>
              <thead>
                <tr>
                  <th>Endpoint</th>
                  <th>Total</th>
                  <th>Success</th>
                  <th>Warning</th>
                  <th>Error</th>
                  <th>Retry</th>
                  <th>P95 ms</th>
                  <th>Last status</th>
                  <th>Last seen</th>
                </tr>
              </thead>
              <tbody>
                {dashboard.endpointMetrics.map((metric) => (
                  <tr key={metric.endpointKey}>
                    <td>{metric.endpointKey}</td>
                    <td>{metric.totalRequests}</td>
                    <td>{metric.successCount}</td>
                    <td>{metric.warningCount}</td>
                    <td>{metric.errorCount}</td>
                    <td>{metric.retryCount}</td>
                    <td>{metric.p95LatencyMs}</td>
                    <td>{metric.lastHttpStatus ?? '-'}</td>
                    <td>{metric.lastSeenAt ? new Date(metric.lastSeenAt).toLocaleString('en-US') : '-'}</td>
                  </tr>
                ))}
                {dashboard.endpointMetrics.length === 0 ? (
                  <tr>
                    <td colSpan={9} className="empty-row">No endpoint metrics found for the current tenant.</td>
                  </tr>
                ) : null}
              </tbody>
            </table>
          </section>

          <section className="content-grid">
            <article className="panel table-panel">
              <h2>Recent events</h2>
              <table>
                <thead>
                  <tr>
                    <th>Occurred at</th>
                    <th>Type</th>
                    <th>Endpoint</th>
                    <th>Outcome</th>
                    <th>Protocol</th>
                    <th>Job</th>
                    <th>Process</th>
                    <th>Report</th>
                  </tr>
                </thead>
                <tbody>
                  {dashboard.recentEvents.map((event) => (
                    <tr key={`${event.occurredAt}-${event.eventType}-${event.traceId}`}>
                      <td>{new Date(event.occurredAt).toLocaleString('en-US')}</td>
                      <td>{event.eventType}</td>
                      <td>{event.endpointKey ?? '-'}</td>
                      <td>{event.outcome}</td>
                      <td>{event.protocolId ?? '-'}</td>
                      <td>{event.jobId ?? '-'}</td>
                      <td>{event.processId ?? '-'}</td>
                      <td>{event.reportId ?? '-'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </article>

            <article className="panel">
              <h2>Continuity checklist</h2>
              <div className="list-stack">
                {dashboard.continuity.checklist.map((item) => (
                  <div className="status-row" key={item.code}>
                    <strong>{item.status}</strong>
                    <div>
                      <p>{item.title}</p>
                      <small>{item.action}</small>
                    </div>
                  </div>
                ))}
              </div>
            </article>
          </section>
        </>
      ) : null}
    </main>
  );
}
