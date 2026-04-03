'use client';

import { useEffect, useState } from 'react';
import { UserPendingList } from './components/UserPendingList';

interface User {
  id: number;
  email: string;
  nome: string;
  tipo: string;
  cpf?: string;
  cnpj?: string;
  status: string;
  createdAt: string;
}

interface UserListResponse {
  total: number;
  users: User[];
}

export default function UsersPendingPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadUsers = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const response = await fetch('/api/users/pending', {
        method: 'GET',
        headers: {
          'X-Tenant-Id': 'tenant-default',
          'X-Correlation-Id': `web-pending-${Date.now()}`,
        },
      });

      if (!response.ok) {
        throw new Error(`Erro ao carregar usuários: ${response.status}`);
      }

      const data: UserListResponse = await response.json();
      setUsers(data.users || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao carregar usuários');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadUsers();
  }, []);

  const handleApprove = async (userId: number) => {
    try {
      const response = await fetch(`/api/users/${userId}/approve`, {
        method: 'POST',
        headers: {
          'X-Tenant-Id': 'tenant-default',
          'X-Correlation-Id': `web-approve-${Date.now()}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ action: 'approve' }),
      });

      if (!response.ok) {
        throw new Error(`Erro ao aprovar usuário: ${response.status}`);
      }

      // Remove user from list
      setUsers(users.filter((u) => u.id !== userId));
      alert('Usuário aprovado com sucesso!');
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Erro ao aprovar usuário');
    }
  };

  const handleReject = async (userId: number, reason: string) => {
    try {
      const response = await fetch(`/api/users/${userId}/reject`, {
        method: 'POST',
        headers: {
          'X-Tenant-Id': 'tenant-default',
          'X-Correlation-Id': `web-reject-${Date.now()}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ action: 'reject', reason }),
      });

      if (!response.ok) {
        throw new Error(`Erro ao rejeitar usuário: ${response.status}`);
      }

      // Remove user from list
      setUsers(users.filter((u) => u.id !== userId));
      alert('Usuário rejeitado com sucesso!');
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Erro ao rejeitar usuário');
    }
  };

  return (
    <main className="page">
      <div className="container">
        <header className="page-header">
          <h1>Aprovação de Usuários</h1>
          <p>Gerenciar cadastros aguardando aprovação</p>
        </header>

        {error && (
          <div className="error-message">
            <strong>Erro:</strong> {error}
            <button onClick={loadUsers}>Tentar novamente</button>
          </div>
        )}

        {isLoading ? (
          <div className="loading">
            <p>Carregando usuários...</p>
          </div>
        ) : (
          <>
            <div className="stats">
              <div className="stat-card">
                <span className="stat-label">Aguardando aprovação</span>
                <span className="stat-value">{users.length}</span>
              </div>
            </div>
            <UserPendingList
              users={users}
              onApprove={handleApprove}
              onReject={handleReject}
            />
          </>
        )}
      </div>

      <style jsx>{`
        .page {
          padding: 20px;
          background: #f5f5f5;
          min-height: 100vh;
        }

        .container {
          max-width: 1200px;
          margin: 0 auto;
        }

        .page-header {
          margin-bottom: 30px;
        }

        .page-header h1 {
          margin: 0;
          font-size: 32px;
          color: #333;
        }

        .page-header p {
          margin: 8px 0 0 0;
          color: #666;
        }

        .error-message {
          background: #ffebee;
          border: 1px solid #ef5350;
          border-radius: 4px;
          padding: 16px;
          margin-bottom: 20px;
          color: #c62828;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }

        .error-message button {
          background: #f44336;
          color: white;
          border: none;
          padding: 6px 12px;
          border-radius: 4px;
          cursor: pointer;
          font-size: 12px;
        }

        .loading {
          text-align: center;
          padding: 40px;
          color: #666;
        }

        .stats {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
          gap: 20px;
          margin-bottom: 30px;
        }

        .stat-card {
          background: white;
          border-radius: 8px;
          padding: 20px;
          box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
          display: flex;
          flex-direction: column;
          gap: 8px;
        }

        .stat-label {
          font-size: 12px;
          color: #999;
          text-transform: uppercase;
          font-weight: bold;
        }

        .stat-value {
          font-size: 32px;
          font-weight: bold;
          color: #333;
        }
      `}</style>
    </main>
  );
}
