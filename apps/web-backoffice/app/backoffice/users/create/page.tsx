'use client';

import { FormEvent, useState } from 'react';

type UserRole = 'ADMIN' | 'OPERATOR' | 'FIELD_AGENT' | 'VIEWER';

interface CreateUserPayload {
  email: string;
  nome: string;
  tipo: string;
  cpf?: string;
  cnpj?: string;
  role: UserRole;
  externalId?: string;
}

export default function CreateUserPage() {
  const [payload, setPayload] = useState<CreateUserPayload>({
    email: '',
    nome: '',
    tipo: 'PJ',
    cpf: '',
    cnpj: '',
    role: 'FIELD_AGENT',
    externalId: '',
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [feedback, setFeedback] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSubmitting(true);
    setError(null);
    setFeedback(null);

    try {
      const response = await fetch('/api/users', {
        method: 'POST',
        headers: {
          'X-Tenant-Id': 'tenant-default',
          'X-Correlation-Id': `web-users-create-${Date.now()}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        const body = await response.json();
        throw new Error(body?.message || `Falha ao criar usuário (${response.status})`);
      }

      setFeedback('Usuário criado e aprovado com sucesso.');
      setPayload({
        email: '',
        nome: '',
        tipo: 'PJ',
        cpf: '',
        cnpj: '',
        role: 'FIELD_AGENT',
        externalId: '',
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro inesperado ao criar usuário');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <main className="form-shell">
      <section className="form-card">
        <header>
          <p className="eyebrow">Cadastro web</p>
          <h1>Novo usuário</h1>
          <p>Usuários cadastrados por este formulário entram como APPROVED com origem WEB_CREATED.</p>
        </header>

        <form onSubmit={onSubmit}>
          <label>
            Nome
            <input
              required
              value={payload.nome}
              onChange={(e) => setPayload((prev) => ({ ...prev, nome: e.target.value }))}
            />
          </label>

          <label>
            E-mail
            <input
              required
              type="email"
              value={payload.email}
              onChange={(e) => setPayload((prev) => ({ ...prev, email: e.target.value }))}
            />
          </label>

          <div className="grid-2">
            <label>
              Tipo
              <select
                value={payload.tipo}
                onChange={(e) => setPayload((prev) => ({ ...prev, tipo: e.target.value }))}
              >
                <option value="PJ">PJ</option>
                <option value="CLT">CLT</option>
              </select>
            </label>

            <label>
              Role
              <select
                value={payload.role}
                onChange={(e) => setPayload((prev) => ({ ...prev, role: e.target.value as UserRole }))}
              >
                <option value="ADMIN">ADMIN</option>
                <option value="OPERATOR">OPERATOR</option>
                <option value="FIELD_AGENT">FIELD_AGENT</option>
                <option value="VIEWER">VIEWER</option>
              </select>
            </label>
          </div>

          <div className="grid-2">
            <label>
              CPF
              <input
                value={payload.cpf}
                onChange={(e) => setPayload((prev) => ({ ...prev, cpf: e.target.value }))}
              />
            </label>

            <label>
              CNPJ
              <input
                value={payload.cnpj}
                onChange={(e) => setPayload((prev) => ({ ...prev, cnpj: e.target.value }))}
              />
            </label>
          </div>

          <label>
            External ID (opcional)
            <input
              value={payload.externalId}
              onChange={(e) => setPayload((prev) => ({ ...prev, externalId: e.target.value }))}
            />
          </label>

          <div className="actions">
            <a href="/backoffice/users" className="ghost">Voltar para listagem</a>
            <button type="submit" disabled={isSubmitting}>
              {isSubmitting ? 'Criando...' : 'Criar usuário'}
            </button>
          </div>
        </form>

        {feedback ? <p className="success">{feedback}</p> : null}
        {error ? <p className="error">{error}</p> : null}
      </section>

      <style jsx>{`
        .form-shell {
          max-width: 860px;
          margin: 0 auto;
          padding: 32px 18px 56px;
        }

        .form-card {
          background: #f7f6f1;
          border: 1px solid #d8deea;
          border-radius: 20px;
          padding: 22px;
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

        p {
          color: #4f5d75;
        }

        form {
          margin-top: 18px;
          display: grid;
          gap: 12px;
        }

        label {
          display: grid;
          gap: 6px;
          color: #172033;
          font-weight: 600;
        }

        input,
        select {
          height: 40px;
          border: 1px solid #c7d1e3;
          border-radius: 10px;
          padding: 0 10px;
          font: inherit;
          color: #172033;
          background: #fff;
        }

        .grid-2 {
          display: grid;
          gap: 12px;
          grid-template-columns: repeat(2, minmax(0, 1fr));
        }

        .actions {
          margin-top: 8px;
          display: flex;
          justify-content: space-between;
          gap: 10px;
          flex-wrap: wrap;
          align-items: center;
        }

        .ghost {
          text-decoration: none;
          color: #172033;
          font-weight: 700;
        }

        button {
          border: none;
          border-radius: 10px;
          background: linear-gradient(90deg, #00a5cf, #ff9f1c);
          color: #fff;
          font-weight: 700;
          padding: 10px 14px;
          cursor: pointer;
        }

        button:disabled {
          opacity: 0.7;
          cursor: wait;
        }

        .success {
          margin-top: 12px;
          border: 1px solid #69a66d;
          background: #ecf8ee;
          border-radius: 10px;
          padding: 10px;
          color: #14581b;
        }

        .error {
          margin-top: 12px;
          border: 1px solid #c34f4f;
          background: #fff3f3;
          border-radius: 10px;
          padding: 10px;
          color: #8e1f1f;
        }

        @media (max-width: 640px) {
          .grid-2 {
            grid-template-columns: minmax(0, 1fr);
          }
        }
      `}</style>
    </main>
  );
}
