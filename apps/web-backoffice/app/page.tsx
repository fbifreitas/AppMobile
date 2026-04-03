import OperationalStatusPanel from "./components/operational_status_panel";
import ConfigTargetingPanel from "./components/config_targeting_panel";

export default function HomePage() {
  return (
    <main className="landing-shell">
      <section className="hero">
        <p className="eyebrow">Operacao centralizada</p>
        <h1>Painel de comando do ecossistema AppMobile</h1>
        <p className="hero-copy">
          Base inicial do backoffice para coordenar <strong>integracao</strong>,
          <strong> operacao</strong> e <strong> governanca</strong> com rastreabilidade e
          foco em continuidade.
        </p>
        <div className="badges" aria-label="Stack e capacidades iniciais">
          <span className="badge">Next.js 14 + TypeScript</span>
          <span className="badge">Health checks por proxy</span>
          <span className="badge">Pipeline CI dedicada</span>
        </div>
        <div className="hero-actions">
          <a className="cta" href="/health">
            Verificar health endpoint
          </a>
          <a className="ghost" href="https://localhost/api/actuator/health">
            Validar API local
          </a>
          <a className="ghost" href="/backoffice/users">
            Gerenciar usuários
          </a>
          <a className="ghost" href="/backoffice/users/audit">
            Auditar usuários
          </a>
          <a className="ghost" href="/backoffice/users/pending">
            Aprovar usuários
          </a>
        </div>
      </section>

      <section className="overview-grid" aria-label="Visao inicial dos modulos">
        <article className="panel panel-integration">
          <h2>Integracao</h2>
          <p>Contratos versionados, idempotencia de sincronizacao e trilha por correlationId.</p>
        </article>
        <article className="panel panel-operations">
          <h2>Operacao</h2>
          <p>Orquestracao de filas, monitoramento de falhas e suporte ao fluxo mobile em campo.</p>
        </article>
        <article className="panel panel-governance">
          <h2>Governanca</h2>
          <p>Controle de releases, rastreabilidade de backlog e seguranca de segredos por ambiente.</p>
        </article>
      </section>

      <OperationalStatusPanel />
      <ConfigTargetingPanel />
    </main>
  );
}
