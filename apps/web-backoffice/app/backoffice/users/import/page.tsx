'use client';

import { FormEvent, useState } from 'react';

interface ImportUserPayload {
  email: string;
  nome: string;
  tipo: string;
  cpf?: string;
  cnpj?: string;
  role: string;
  externalId?: string;
}

interface ImportUsersResponse {
  submitted: number;
  imported: number;
  skipped: number;
  skippedEmails: string[];
}

const EXAMPLE_JSON = JSON.stringify(
  [
    {
      email: 'analista.ad@empresa.com',
      nome: 'Analista AD',
      tipo: 'CLT',
      role: 'OPERATOR',
      externalId: 'ad-001',
    },
    {
      email: 'vistoriador@empresa.com',
      nome: 'Vistoriador Externo',
      tipo: 'PJ',
      role: 'FIELD_AGENT',
      cnpj: '00.000.000/0001-00',
      externalId: 'ad-002',
    },
  ],
  null,
  2,
);

export default function ImportUsersPage() {
  const [source, setSource] = useState('AD_IMPORT');
  const [rawJson, setRawJson] = useState(EXAMPLE_JSON);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [result, setResult] = useState<ImportUsersResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSubmitting(true);
    setResult(null);
    setError(null);

    try {
      const users = JSON.parse(rawJson) as ImportUserPayload[];
      if (!Array.isArray(users) || users.length === 0) {
        throw new Error('Informe um array JSON com pelo menos um usuário.');
      }

      const response = await fetch('/api/users/import', {
        method: 'POST',
        headers: {
          'X-Tenant-Id': 'tenant-default',
          'X-Correlation-Id': `web-users-import-${Date.now()}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ source, users }),
      });

      const body = await response.json();
      if (!response.ok) {
        throw new Error(body?.message || `Falha na importação (${response.status})`);
      }

      setResult(body as ImportUsersResponse);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro inesperado na importação');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <main className="import-shell">
      <section className="import-card">
        <header>
          <p className="eyebrow">Importação em lote</p>
          <h1>Importar usuários de diretório</h1>
          <p>Suporte inicial para AD/LDAP via payload JSON. E-mails duplicados são ignorados.</p>
        </header>

        <form onSubmit={onSubmit}>
          <label>
            Origem
            <select value={source} onChange={(e) => setSource(e.target.value)}>
              <option value="AD_IMPORT">AD_IMPORT</option>
              <option value="WEB_CREATED">WEB_CREATED</option>
            </select>
          </label>

          <label>
            Payload JSON de usuários
            <textarea
              value={rawJson}
              onChange={(e) => setRawJson(e.target.value)}
              rows={16}
            />
          </label>

          <div className="actions">
            <a href="/backoffice/users" className="ghost">Voltar para listagem</a>
            <button type="submit" disabled={isSubmitting}>
              {isSubmitting ? 'Importando...' : 'Importar usuários'}
            </button>
          </div>
        </form>

        {result ? (
          <section className="result-box">
            <h2>Resultado</h2>
            <p>Recebidos: {result.submitted}</p>
            <p>Importados: {result.imported}</p>
            <p>Ignorados: {result.skipped}</p>
            {result.skippedEmails.length > 0 ? (
              <ul>
                {result.skippedEmails.map((email) => (
                  <li key={email}>{email}</li>
                ))}
              </ul>
            ) : null}
          </section>
        ) : null}

        {error ? <p className="error">{error}</p> : null}
      </section>

      <style jsx>{`
        .import-shell {
          max-width: 980px;
          margin: 0 auto;
          padding: 32px 18px 56px;
        }

        .import-card {
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
          margin-top: 16px;
          display: grid;
          gap: 12px;
        }

        label {
          display: grid;
          gap: 6px;
          color: #172033;
          font-weight: 600;
        }

        select,
        textarea {
          border: 1px solid #c7d1e3;
          border-radius: 10px;
          padding: 10px;
          font: inherit;
          color: #172033;
          background: #fff;
        }

        textarea {
          min-height: 280px;
          resize: vertical;
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

        .result-box {
          margin-top: 14px;
          border: 1px solid #7cb38b;
          background: #effbf2;
          border-radius: 10px;
          padding: 12px;
          color: #165428;
        }

        .result-box h2 {
          margin-top: 0;
          color: #165428;
        }

        .result-box ul {
          margin: 6px 0 0;
          padding-left: 18px;
        }

        .error {
          margin-top: 14px;
          border: 1px solid #c34f4f;
          background: #fff3f3;
          border-radius: 10px;
          padding: 10px;
          color: #8e1f1f;
        }
      `}</style>
    </main>
  );
}
