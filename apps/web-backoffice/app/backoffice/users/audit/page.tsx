'use client';

import { useEffect, useState } from 'react';

interface UserAuditEntry {
  id: string;
  userId: number;
  userEmail: string;
  actorId: string;
  action: string;
  correlationId: string;
  details?: string;
  createdAt: string;
}

interface UserAuditResponse {
  count: number;
  items: UserAuditEntry[];
}

export default function UserAuditPage() {
  const [items, setItems] = useState<UserAuditEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function loadAudit() {
      setLoading(true);
      setError(null);

      try {
        const response = await fetch('/api/users/audit', {
          headers: {
            'X-Tenant-Id': 'tenant-default',
            'X-Correlation-Id': `web-users-audit-${Date.now()}`,
            'X-Actor-Id': 'backoffice-auditor',
          },
        });

        if (!response.ok) {
          throw new Error(`Falha ao carregar auditoria (${response.status})`);
        }

        const body: UserAuditResponse = await response.json();
        setItems(body.items || []);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Erro inesperado');
      } finally {
        setLoading(false);
      }
    }

    loadAudit();
  }, []);

  return (
    <main className="audit-shell">
      <section className="audit-header">
        <div>
          <p className="eyebrow">Segurança operacional</p>
          <h1>Trilha de auditoria de usuários</h1>
          <p className="subtitle">Últimas ações administrativas registradas no backend para gestão de usuários.</p>
        </div>
        <div className="actions">
          <a className="ghost" href="/backoffice/users">Voltar para usuários</a>
          <a className="ghost" href="/backoffice/users/pending">Fila de aprovação</a>
        </div>
      </section>

      {error ? <div className="error-box">{error}</div> : null}
      {loading ? <div className="loading-box">Carregando auditoria...</div> : null}

      {!loading ? (
        <section className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Quando</th>
                <th>Ação</th>
                <th>Usuário alvo</th>
                <th>Ator</th>
                <th>Correlation</th>
                <th>Detalhes</th>
              </tr>
            </thead>
            <tbody>
              {items.map((entry) => (
                <tr key={entry.id}>
                  <td>{new Date(entry.createdAt).toLocaleString('pt-BR')}</td>
                  <td><span className="action-badge">{entry.action}</span></td>
                  <td>
                    <strong>{entry.userEmail}</strong>
                    <small>ID {entry.userId}</small>
                  </td>
                  <td>{entry.actorId}</td>
                  <td>{entry.correlationId}</td>
                  <td>{entry.details || 'Sem detalhes adicionais'}</td>
                </tr>
              ))}
              {items.length === 0 ? (
                <tr>
                  <td colSpan={6} className="empty-row">Nenhum evento auditado encontrado.</td>
                </tr>
              ) : null}
            </tbody>
          </table>
        </section>
      ) : null}

      <style jsx>{`
        .audit-shell {
          max-width: 1180px;
          margin: 0 auto;
          padding: 32px 18px 56px;
        }

        .audit-header {
          display: flex;
          justify-content: space-between;
          gap: 16px;
          align-items: flex-end;
          flex-wrap: wrap;
          background: #f7f6f1;
          border: 1px solid #d8deea;
          border-radius: 20px;
          padding: 20px;
          box-shadow: 0 14px 36px rgba(7, 11, 18, 0.2);
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
          margin: 8px 0;
          color: #172033;
        }

        .subtitle {
          margin: 0;
          color: #4f5d75;
        }

        .actions {
          display: flex;
          gap: 10px;
          flex-wrap: wrap;
        }

        .actions a {
          text-decoration: none;
          font-weight: 700;
          border-radius: 10px;
          padding: 10px 14px;
          border: 1px solid #d8deea;
          background: #fff;
          color: #172033;
        }

        .error-box,
        .loading-box {
          margin-top: 18px;
          background: #fff;
          border: 1px solid #d8deea;
          border-radius: 14px;
          padding: 16px;
          color: #172033;
        }

        .table-wrap {
          margin-top: 18px;
          background: #fff;
          border: 1px solid #d8deea;
          border-radius: 16px;
          overflow: auto;
        }

        table {
          width: 100%;
          border-collapse: collapse;
          min-width: 980px;
        }

        th,
        td {
          text-align: left;
          padding: 14px 16px;
          border-bottom: 1px solid #edf1f7;
          vertical-align: top;
        }

        th {
          background: #f7f9fc;
          color: #4f5d75;
          font-size: 0.78rem;
          text-transform: uppercase;
          letter-spacing: 0.06em;
        }

        td strong,
        td small {
          display: block;
        }

        td small {
          color: #6a7790;
          margin-top: 4px;
        }

        .action-badge {
          display: inline-flex;
          align-items: center;
          padding: 6px 10px;
          border-radius: 999px;
          background: #edf7fb;
          color: #006b86;
          font-weight: 700;
          font-size: 0.78rem;
        }

        .empty-row {
          text-align: center;
          color: #6a7790;
        }

        @media (max-width: 768px) {
          .audit-shell {
            padding: 24px 14px 42px;
          }
        }
      `}</style>
    </main>
  );
}