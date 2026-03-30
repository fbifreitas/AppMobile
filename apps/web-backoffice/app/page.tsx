export default function HomePage() {
  return (
    <main>
      <section className="hero">
        <h1>Backoffice Web iniciado</h1>
        <p>
          Estrutura inicial pronta para evoluir os modulos de <strong>integracao</strong>,
          <strong> operacao</strong> e <strong>governanca</strong>.
        </p>
        <div className="badges">
          <span className="badge">Next.js + TypeScript</span>
          <span className="badge">CI separado do mobile</span>
          <span className="badge">Deploy com webhook opcional</span>
        </div>
        <a className="cta" href="/health">
          Validar rota de health
        </a>
      </section>
    </main>
  );
}
