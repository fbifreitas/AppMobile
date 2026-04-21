'use client';

import React from 'react';

export default function BackofficeConfigPage() {
  return (
    <main className="ops-shell">
      <section className="ops-header">
        <div>
          <p className="eyebrow">FW-004 + BOW-121</p>
          <h1>Governanca operacional do check-in e captura</h1>
          <p className="ops-subtitle">
            Separe politica operacional, gates de captura, referencias inteligentes e matriz
            normativa sem perder previsibilidade de uso, treinamento e retomada no app.
          </p>
        </div>
        <div className="ops-header-actions">
          <a className="ghost" href="/">
            Voltar ao dashboard
          </a>
          <a className="ghost" href="/backoffice/inspections">
            Ver vistorias recebidas
          </a>
        </div>
      </section>

      <section className="ops-stack">
        <article className="ops-card">
          <div className="ops-card-header">
            <div>
              <h2>Modelo alvo da governanca</h2>
              <p>O processo antigo de configuracao manual foi quebrado em dominios separados.</p>
            </div>
          </div>

          <ul className="ops-list">
            <li>`Operational Policy Config`: UX do app, rollout, labels, step 2 e flags.</li>
            <li>`Capture Gate Policy`: check-in 1, GPS, permissao e localizacao disponivel.</li>
            <li>`Operational Reference Governance`: tipo, subtipo, candidatos e composicao.</li>
            <li>`Normative Matrix Governance`: obrigatoriedade, min/max fotos e alternativas.</li>
            <li>`Resolve Preview`: simulacao do que um job real recebera no mobile.</li>
          </ul>

          <section className="ops-subsection">
            <h3>Diretriz de operacao</h3>
            <ul className="ops-list">
              <li>Captura continua fluida; bloqueio normativo acontece apenas na finalizacao.</li>
              <li>Fallback e retomada do app precisam continuar compativeis com qualquer mudanca.</li>
              <li>A inteligencia complementa a base estatica; nao substitui treinamento operacional.</li>
            </ul>
          </section>
        </article>

        <article className="ops-card">
          <div className="ops-card-header">
            <div>
              <h2>Operational Policy Config</h2>
              <p>
                Esta tela nao e mais o editor primario da taxonomia do imovel ou da camera.
                Politicas de UX, rollout, labels e comportamento operacional precisam ser
                governadas sem misturar arvore de captura e referencia inteligente.
              </p>
            </div>
          </div>

          <section className="ops-subsection">
            <h3>O que saiu desta tela</h3>
            <ul className="ops-list">
              <li>Editor manual de `tipo`, `subtipo` e arvore da camera.</li>
              <li>Composicao manual de `ambiente {'>'} elemento {'>'} material {'>'} estado`.</li>
              <li>Pacote unico tentando governar politica, referencia e norma ao mesmo tempo.</li>
            </ul>
          </section>

          <section className="ops-subsection">
            <h3>O que continua sendo governado aqui</h3>
            <ul className="ops-list">
              <li>Politica operacional do app e previsibilidade de uso.</li>
              <li>Diretrizes de rollout e treinamento.</li>
              <li>Separacao clara entre fluxo operacional e inteligencia.</li>
            </ul>
          </section>

          <div className="ops-header-actions">
            <a className="ghost" href="/backoffice/operations">
              Abrir workspace de operacoes
            </a>
          </div>
          <p className="ops-subtitle">
            O editor legado foi retirado desta pagina para evitar fonte duplicada de verdade.
          </p>
        </article>

        <article className="ops-card">
          <div className="ops-card-header">
            <div>
              <h2>Capture Gate Policy</h2>
              <p>Pre-condicoes para abrir e usar a camera, sem misturar com obrigatoriedade normativa.</p>
            </div>
          </div>
          <ul className="ops-list">
            <li>`Check-in 1` concluido antes da captura.</li>
            <li>`GPS` do aparelho ativo.</li>
            <li>Permissao de localizacao concedida.</li>
            <li>Posicao atual disponivel no momento da foto.</li>
          </ul>
        </article>

        <article className="ops-card">
          <div className="ops-card-header">
            <div>
              <h2>Operational Reference Governance</h2>
              <p>Perfis globais, regionais e historicos agora vivem no workspace operacional.</p>
            </div>
          </div>
          <p className="ops-subtitle">
            Use a torre operacional para revisar referencias persistidas, rebuild historico/regional
            e candidatos de subtipo antes de alterar o comportamento do job.
          </p>
          <div className="ops-header-actions">
            <a className="ghost" href="/backoffice/operations">
              Abrir governanca de referencias
            </a>
          </div>
        </article>

        <article className="ops-card">
          <div className="ops-card-header">
            <div>
              <h2>Normative Matrix Governance</h2>
              <p>Matriz estatica para previsibilidade operacional e treinamento de uso.</p>
            </div>
          </div>
          <ul className="ops-list">
            <li>Obrigatoriedade por dimensao do fato.</li>
            <li>`min/max photos` por perfil operacional.</li>
            <li>Alternativas aceitas para cumprir evidencia.</li>
            <li>Justificativa quando houver excecao.</li>
            <li>Bloqueio apenas na finalizacao da vistoria.</li>
          </ul>
          <div className="ops-header-actions">
            <a className="ghost" href="/backoffice/operations">
              Abrir matriz normativa e preview
            </a>
          </div>
        </article>

        <article className="ops-card">
          <div className="ops-card-header">
            <div>
              <h2>Resolve Preview</h2>
              <p>Checklist do que precisa ser conferido ao simular um job real.</p>
            </div>
          </div>
          <ul className="ops-list">
            <li>Tipo, subtipo e candidatos de subtipo.</li>
            <li>Gates de captura aplicados ao dispositivo.</li>
            <li>Composicao inicial da camera e sugestoes de menu.</li>
            <li>Matriz normativa que sera cobrada na revisao/finalizacao.</li>
            <li>Compatibilidade do payload com fallback e retomada do app.</li>
          </ul>
        </article>
      </section>
    </main>
  );
}
