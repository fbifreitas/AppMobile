'use client';

import { Suspense } from 'react';
import { FormEvent, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';

type LoginResponse = {
  membershipRole: string;
};

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [tenantId, setTenantId] = useState('tenant-platform');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          tenantId,
          email,
          password,
          deviceInfo: 'web-backoffice',
        }),
      });

      const body = (await response.json()) as LoginResponse & { message?: string; error?: string };
      if (!response.ok) {
        throw new Error(body.message || body.error || 'Falha ao autenticar');
      }

      const nextPath = searchParams.get('next');
      const defaultTarget = body.membershipRole === 'PLATFORM_ADMIN'
        ? '/backoffice/platform/tenants'
        : '/backoffice/users';
      router.replace(nextPath || defaultTarget);
      router.refresh();
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : 'Falha ao autenticar');
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="login-shell">
      <section className="login-card">
        <p className="eyebrow">Pacote A Compass</p>
        <h1>Login web real</h1>
        <p className="subtitle">
          Acesso autenticado para plataforma e backoffice usando o backend real de auth.
        </p>

        <form onSubmit={onSubmit}>
          <label>
            Tenant ID
            <input value={tenantId} onChange={(event) => setTenantId(event.target.value)} required />
          </label>

          <label>
            E-mail
            <input type="email" value={email} onChange={(event) => setEmail(event.target.value)} required />
          </label>

          <label>
            Senha
            <input type="password" value={password} onChange={(event) => setPassword(event.target.value)} required />
          </label>

          <button type="submit" disabled={loading}>
            {loading ? 'Entrando...' : 'Entrar'}
          </button>
        </form>

        {error ? <p className="error">{error}</p> : null}
      </section>

      <style jsx>{`
        .login-shell {
          min-height: 100vh;
          display: grid;
          place-items: center;
          padding: 24px;
          background:
            radial-gradient(circle at top left, rgba(255, 159, 28, 0.22), transparent 36%),
            radial-gradient(circle at bottom right, rgba(0, 165, 207, 0.22), transparent 30%),
            linear-gradient(180deg, #f5f7fb 0%, #eef3f7 100%);
        }

        .login-card {
          width: min(460px, 100%);
          background: rgba(255, 255, 255, 0.96);
          border: 1px solid #d8deea;
          border-radius: 24px;
          padding: 28px;
          box-shadow: 0 24px 60px rgba(23, 32, 51, 0.14);
        }

        .eyebrow {
          margin: 0;
          text-transform: uppercase;
          letter-spacing: 0.08em;
          font-size: 0.76rem;
          font-weight: 700;
          color: #007ca0;
        }

        h1 {
          margin: 8px 0;
          color: #172033;
        }

        .subtitle {
          margin: 0 0 18px;
          color: #4f5d75;
        }

        form {
          display: grid;
          gap: 12px;
        }

        label {
          display: grid;
          gap: 6px;
          color: #172033;
          font-weight: 600;
        }

        input {
          height: 42px;
          border: 1px solid #c7d1e3;
          border-radius: 10px;
          padding: 0 12px;
          font: inherit;
        }

        button {
          margin-top: 8px;
          height: 44px;
          border: 0;
          border-radius: 12px;
          background: linear-gradient(90deg, #007ca0, #ff9f1c);
          color: #fff;
          font-weight: 700;
          cursor: pointer;
        }

        .error {
          margin: 14px 0 0;
          color: #b42318;
        }
      `}</style>
    </main>
  );
}

export default function LoginPage() {
  return (
    <Suspense fallback={<main className="login-shell"><section className="login-card">Carregando login...</section></main>}>
      <LoginForm />
    </Suspense>
  );
}
