'use client';

import React from 'react';
import ConfigTargetingPanel from '../../components/config_targeting_panel';

export default function BackofficeConfigPage() {
  return (
    <main className="ops-shell">
      <section className="ops-header">
        <div>
          <p className="eyebrow">FW-004 + BOW-121</p>
          <h1>Configuracao dinamica de check-in</h1>
          <p className="ops-subtitle">
            Publicacao, aprovacao, resolucao efetiva e rollback de pacotes por tenant para fechar
            o fluxo operacional de configuracao no backoffice.
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
              <h2>Gate operacional e dependencias cruzadas</h2>
              <p>Fechamento esperado para considerar FW-004/BOW-121 operacionais.</p>
            </div>
          </div>

          <ul className="ops-list">
            <li>Publicar pacote com `rules.checkinSections` valido por tenant.</li>
            <li>Aprovar pacote sem chamada manual ao backend.</li>
            <li>Validar resolve efetivo por escopo e janela de rollout.</li>
            <li>Executar rollback e confirmar remocao do pacote efetivo.</li>
            <li>Preservar rastreabilidade por correlation id e auditoria recente.</li>
          </ul>

          <section className="ops-subsection">
            <h3>Dependencias cruzadas</h3>
            <ul className="ops-list">
              <li>`INT-003`: assinatura e entrega segura do payload ao mobile.</li>
              <li>`INT-004`: rollout e rollback refletidos no consumo do app.</li>
              <li>`BOW-130`: consumo mobile da configuracao real como caminho principal.</li>
            </ul>
          </section>
        </article>

        <article className="ops-card">
          <div className="ops-card-header">
            <div>
              <h2>Central de configuracoes</h2>
              <p>
                Esta tela concentra o catalogo de pacotes, auditoria recente e simulacao de
                resolucao efetiva para tenant, role, usuario e dispositivo.
              </p>
            </div>
          </div>
          <ConfigTargetingPanel />
        </article>
      </section>
    </main>
  );
}
