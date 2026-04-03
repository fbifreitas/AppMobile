'use client';

import { useState } from 'react';

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

interface UserListProps {
  users: User[];
  onApprove: (userId: number) => Promise<void>;
  onReject: (userId: number, reason: string) => Promise<void>;
}

export function UserPendingList({ users, onApprove, onReject }: UserListProps) {
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleApprove = async (userId: number) => {
    setIsLoading(true);
    try {
      await onApprove(userId);
      setSelectedUser(null);
    } catch (error) {
      console.error('Erro ao aprovar usuário:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleReject = async (userId: number) => {
    if (!rejectionReason.trim()) {
      alert('Motivo da rejeição é obrigatório');
      return;
    }

    setIsLoading(true);
    try {
      await onReject(userId, rejectionReason);
      setSelectedUser(null);
      setRejectionReason('');
    } catch (error) {
      console.error('Erro ao rejeitar usuário:', error);
    } finally {
      setIsLoading(false);
    }
  };

  if (users.length === 0) {
    return (
      <div className="empty-state">
        <p>Nenhum usuário aguardando aprovação</p>
      </div>
    );
  }

  return (
    <>
      <div className="user-list">
        {users.map((user) => (
          <div key={user.id} className="user-card">
            <div className="user-header">
              <h3>{user.nome}</h3>
              <span className="user-type">{user.tipo}</span>
            </div>
            <div className="user-details">
              <p><strong>Email:</strong> {user.email}</p>
              <p><strong>CPF/CNPJ:</strong> {user.cpf || user.cnpj || 'N/A'}</p>
              <p><strong>Solicitado em:</strong> {new Date(user.createdAt).toLocaleDateString('pt-BR')}</p>
            </div>
            <div className="user-actions">
              <button
                className="btn btn-approve"
                onClick={() => handleApprove(user.id)}
                disabled={isLoading}
              >
                ✓ Aprovar
              </button>
              <button
                className="btn btn-reject"
                onClick={() => setSelectedUser(user)}
                disabled={isLoading}
              >
                ✕ Rejeitar
              </button>
            </div>
          </div>
        ))}
      </div>

      {selectedUser && (
        <div className="modal-overlay">
          <div className="modal">
            <h2>Rejeitar usuário: {selectedUser.nome}</h2>
            <textarea
              placeholder="Motivo da rejeição (obrigatório)"
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              disabled={isLoading}
            />
            <div className="modal-actions">
              <button
                className="btn btn-cancel"
                onClick={() => {
                  setSelectedUser(null);
                  setRejectionReason('');
                }}
                disabled={isLoading}
              >
                Cancelar
              </button>
              <button
                className="btn btn-reject"
                onClick={() => handleReject(selectedUser.id)}
                disabled={isLoading}
              >
                {isLoading ? 'Processando...' : 'Confirmar Rejeição'}
              </button>
            </div>
          </div>
        </div>
      )}

      <style jsx>{`
        .user-list {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
          gap: 20px;
          margin: 20px 0;
        }

        .user-card {
          border: 1px solid #e0e0e0;
          border-radius: 8px;
          padding: 20px;
          background: #f9f9f9;
        }

        .user-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 12px;
        }

        .user-header h3 {
          margin: 0;
          font-size: 18px;
        }

        .user-type {
          background: #e3f2fd;
          color: #1976d2;
          padding: 4px 8px;
          border-radius: 4px;
          font-size: 12px;
          font-weight: bold;
        }

        .user-details {
          margin: 12px 0;
          font-size: 14px;
          color: #666;
        }

        .user-details p {
          margin: 8px 0;
        }

        .user-actions {
          display: flex;
          gap: 10px;
          margin-top: 16px;
        }

        .btn {
          flex: 1;
          padding: 10px;
          border: none;
          border-radius: 4px;
          cursor: pointer;
          font-weight: bold;
          transition: all 0.2s;
        }

        .btn:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }

        .btn-approve {
          background: #4caf50;
          color: white;
        }

        .btn-approve:hover:not(:disabled) {
          background: #45a049;
        }

        .btn-reject {
          background: #f44336;
          color: white;
        }

        .btn-reject:hover:not(:disabled) {
          background: #da190b;
        }

        .btn-cancel {
          background: #9e9e9e;
          color: white;
        }

        .modal-overlay {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(0, 0, 0, 0.5);
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 1000;
        }

        .modal {
          background: white;
          border-radius: 8px;
          padding: 30px;
          max-width: 500px;
          width: 90%;
          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .modal h2 {
          margin-top: 0;
        }

        .modal textarea {
          width: 100%;
          min-height: 100px;
          padding: 10px;
          border: 1px solid #ddd;
          border-radius: 4px;
          font-family: inherit;
          font-size: 14px;
          margin: 16px 0;
        }

        .modal-actions {
          display: flex;
          gap: 10px;
        }

        .empty-state {
          text-align: center;
          padding: 40px;
          color: #666;
        }
      `}</style>
    </>
  );
}
