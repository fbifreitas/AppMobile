'use client';

import { useEffect, useMemo, useState } from 'react';

type UserStatus = 'AWAITING_APPROVAL' | 'APPROVED' | 'REJECTED';

interface User {
  id: number;
  email: string;
  nome: string;
  tipo: string;
  cpf?: string;
  cnpj?: string;
  status: UserStatus;
  role?: string;
  source?: string;
  externalId?: string;
  createdAt: string;
}

interface UserListResponse {
  total: number;
  users: User[];
}

interface OnboardingStatus {
  userId: number;
  onboardingPolicy: string;
  pendingSteps: string[];
  awaitingApproval: boolean;
}

const STATUS_TABS: Array<{ label: string; value: 'ALL' | UserStatus }> = [
  { label: 'Todos', value: 'ALL' },
  { label: 'Aguardando aprovação', value: 'AWAITING_APPROVAL' },
  { label: 'Aprovados', value: 'APPROVED' },
  { label: 'Rejeitados', value: 'REJECTED' },
];

function sourceLabel(source?: string): string {
  if (source === 'MOBILE_ONBOARDING') return 'Mobile';
  if (source === 'WEB_CREATED') return 'Web';
  if (source === 'AD_IMPORT') return 'AD';
  return 'N/A';
}

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [activeStatus, setActiveStatus] = useState<'ALL' | UserStatus>('ALL');
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [onboardingStatuses, setOnboardingStatuses] = useState<Record<number, OnboardingStatus>>({});

  async function loadUsers(status: 'ALL' | UserStatus) {
    setLoading(true);
    setError(null);

    try {
      const query = status === 'ALL' ? '' : `?status=${status}`;
      const response = await fetch(`/api/users${query}`, {
        method: 'GET',
        headers: {
          'X-Tenant-Id': 'tenant-default',
          'X-Correlation-Id': `web-users-list-${Date.now()}`,
        },
      });

      if (!response.ok) {
        throw new Error(`Falha ao carregar usuários (${response.status})`);
      }

      const data: UserListResponse = await response.json();
      setUsers(data.users || []);

      const onboardingResponse = await fetch('/api/users/onboarding-statuses', {
        method: 'GET',
        headers: {
          'X-Tenant-Id': 'tenant-default',
          'X-Correlation-Id': `web-users-onboarding-${Date.now()}`,
        },
      });

      if (onboardingResponse.ok) {
        const onboardingItems: OnboardingStatus[] = await onboardingResponse.json();
        setOnboardingStatuses(Object.fromEntries(onboardingItems.map((item) => [item.userId, item])));
      } else {
        setOnboardingStatuses({});
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro inesperado');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadUsers(activeStatus);
  }, [activeStatus]);

  const stats = useMemo(() => {
    const summary = {
      total: users.length,
      awaiting: 0,
      approved: 0,
      rejected: 0,
    };

    users.forEach((u) => {
      if (u.status === 'AWAITING_APPROVAL') summary.awaiting += 1;
      if (u.status === 'APPROVED') summary.approved += 1;
      if (u.status === 'REJECTED') summary.rejected += 1;
    });

    return summary;
  }, [users]);

  return (
    <main className="users-shell">
      <section className="users-header">
        <div>
          <p className="eyebrow">Gestão de identidade</p>
          <h1>Usuários do Backoffice</h1>
          <p className="subtitle">Fluxos integrados de mobile onboarding, cadastro web e importação AD.</p>
        </div>
        <div className="actions">
          <a className="ghost" href="/backoffice/users/audit">Auditoria</a>
          <a className="ghost" href="/backoffice/users/pending">Fila de aprovação</a>
          <a className="ghost" href="/backoffice/users/import">Importar AD</a>
          <a className="cta" href="/backoffice/users/create">Novo usuário</a>
        </div>
      </section>

      <section className="stats-grid" aria-label="Resumo de usuários">
        <article className="stat-card"><span>Total</span><strong>{stats.total}</strong></article>
        <article className="stat-card"><span>Aguardando</span><strong>{stats.awaiting}</strong></article>
        <article className="stat-card"><span>Aprovados</span><strong>{stats.approved}</strong></article>
        <article className="stat-card"><span>Rejeitados</span><strong>{stats.rejected}</strong></article>
      </section>

      <section className="filters" aria-label="Filtros de status">
        {STATUS_TABS.map((tab) => (
          <button
            key={tab.value}
            type="button"
            className={tab.value === activeStatus ? 'filter active' : 'filter'}
            onClick={() => setActiveStatus(tab.value)}
          >
            {tab.label}
          </button>
        ))}
      </section>

      {error ? (
        <div className="error-box">
          <p>{error}</p>
          <button type="button" onClick={() => loadUsers(activeStatus)}>Tentar novamente</button>
        </div>
      ) : null}

      {loading ? (
        <div className="loading-box">Carregando usuários...</div>
      ) : (
        <section className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Nome</th>
                <th>Email</th>
                <th>Role</th>
                <th>Origem</th>
                <th>Status</th>
                <th>Pendencias</th>
                <th>Criado em</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr key={user.id}>
                  <td>
                    <strong>{user.nome}</strong>
                    <small>{user.tipo}</small>
                  </td>
                  <td>{user.email}</td>
                  <td>{user.role || 'FIELD_AGENT'}</td>
                  <td>
                    <span className="source-badge">{sourceLabel(user.source)}</span>
                  </td>
                  <td>{user.status}</td>
                  <td>
                    {onboardingStatuses[user.id]?.pendingSteps?.length ? (
                      <>
                        <strong>{onboardingStatuses[user.id].onboardingPolicy}</strong>
                        <small>{onboardingStatuses[user.id].pendingSteps.join(', ')}</small>
                      </>
                    ) : (
                      <span className="done-badge">Sem pendencias</span>
                    )}
                  </td>
                  <td>{new Date(user.createdAt).toLocaleString('pt-BR')}</td>
                </tr>
              ))}
              {users.length === 0 ? (
                <tr>
                  <td colSpan={6} className="empty-row">Nenhum usuário encontrado para este filtro.</td>
                </tr>
              ) : null}
            </tbody>
          </table>
        </section>
      )}

      <style jsx>{`
        .users-shell {
          max-width: 1120px;
          margin: 0 auto;
          padding: 32px 18px 56px;
        }

        .users-header {
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
          max-width: 70ch;
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
        }

        .actions .ghost {
          background: #fff;
          color: #172033;
        }

        .actions .cta {
          background: linear-gradient(90deg, #00a5cf, #ff9f1c);
          color: #fff;
          border: none;
        }

        .stats-grid {
          margin-top: 18px;
          display: grid;
          gap: 12px;
          grid-template-columns: repeat(4, minmax(0, 1fr));
        }

        .stat-card {
          background: #fff;
          border: 1px solid #d8deea;
          border-radius: 14px;
          padding: 14px;
          display: flex;
          flex-direction: column;
          gap: 8px;
        }

        .stat-card span {
          color: #4f5d75;
          font-size: 0.8rem;
          text-transform: uppercase;
          letter-spacing: 0.06em;
        }

        .stat-card strong {
          font-size: 1.8rem;
          color: #172033;
        }

        .filters {
          margin-top: 16px;
          display: flex;
          gap: 8px;
          flex-wrap: wrap;
        }

        .filter {
          border: 1px solid #d8deea;
          background: #fff;
          color: #172033;
          border-radius: 999px;
          padding: 8px 12px;
          font-weight: 600;
          cursor: pointer;
        }

        .filter.active {
          background: #172033;
          color: #fff;
          border-color: #172033;
        }

        .error-box,
        .loading-box {
          margin-top: 16px;
          background: #fff;
          border: 1px solid #d8deea;
          border-radius: 12px;
          padding: 14px;
          color: #172033;
        }

        .error-box {
          border-color: #c34f4f;
          background: #fff3f3;
        }

        .error-box button {
          margin-top: 10px;
          border: none;
          border-radius: 8px;
          background: #c34f4f;
          color: #fff;
          padding: 8px 12px;
          cursor: pointer;
        }

        .table-wrap {
          margin-top: 16px;
          overflow-x: auto;
          background: #fff;
          border: 1px solid #d8deea;
          border-radius: 14px;
        }

        table {
          width: 100%;
          border-collapse: collapse;
        }

        th,
        td {
          text-align: left;
          padding: 12px;
          border-bottom: 1px solid #edf1f8;
          color: #172033;
          white-space: nowrap;
          vertical-align: top;
        }

        td strong {
          display: block;
          color: #172033;
        }

        td small {
          color: #5d6f8e;
        }

        .source-badge {
          display: inline-block;
          border-radius: 999px;
          background: #e8f7fc;
          color: #0d6c88;
          font-size: 0.75rem;
          font-weight: 700;
          padding: 4px 8px;
        }

        .done-badge {
          display: inline-block;
          border-radius: 999px;
          background: #edf7ed;
          color: #217a3a;
          font-size: 0.75rem;
          font-weight: 700;
          padding: 4px 8px;
        }

        .empty-row {
          text-align: center;
          color: #5d6f8e;
          font-style: italic;
        }

        @media (max-width: 900px) {
          .stats-grid {
            grid-template-columns: repeat(2, minmax(0, 1fr));
          }
        }

        @media (max-width: 640px) {
          .stats-grid {
            grid-template-columns: minmax(0, 1fr);
          }
        }
      `}</style>
    </main>
  );
}
