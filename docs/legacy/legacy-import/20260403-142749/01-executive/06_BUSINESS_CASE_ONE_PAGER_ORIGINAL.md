# Business Case / One-Pager — Plataforma de Vistorias, Avaliação e Orquestração de Mercado

## 1. Resumo executivo

A plataforma proposta resolve um problema estrutural do mercado de avaliação imobiliária: a operação de vistoria e avaliação ainda é fragmentada, manual, pouco rastreável e difícil de escalar entre financeiras, empresas de avaliação e vistoriadores.

No estágio inicial, a solução acelera a operação de uma empresa de avaliação âncora, integrando a demanda já existente de uma financeira e substituindo processos manuais de distribuição, execução e acompanhamento de vistorias.

No médio e longo prazo, a plataforma evolui para uma infraestrutura white label e multi-tenant, capaz de conectar múltiplas financeiras, múltiplas empresas de avaliação e uma rede escalável de vistoriadores, com controle de qualidade, rastreabilidade técnica, geração de laudos e liquidação financeira entre participantes.

Em termos de tese, a plataforma não é apenas um software operacional. Ela tem potencial para se tornar a camada de orquestração, confiança e liquidação do ecossistema de inspeção e avaliação imobiliária.

## 2. Problema de mercado

Hoje o fluxo de vistoria e avaliação costuma apresentar os seguintes problemas:

- distribuição manual ou semi-manual de ordens de serviço;
- baixa visibilidade do status real de cada processo;
- dificuldade de escalar rede de vistoriadores por região;
- retrabalho operacional por falta de padronização;
- dependência de pessoas-chave para coordenação;
- pouca rastreabilidade entre demanda, vistoria, cálculo e laudo;
- dificuldade de integrar múltiplos demandantes e operadores técnicos;
- ausência de uma camada de inteligência para preço, repasse, qualidade e SLA.

O resultado é um processo com custo alto, baixa previsibilidade, pouca governança e baixa capacidade de expansão para mercado.

## 3. Oportunidade

A oportunidade está em construir uma plataforma que atue em três níveis:

### Nível 1 — Eficiência operacional
Digitaliza o fluxo de ponta a ponta entre demanda, vistoria, avaliação e laudo.

### Nível 2 — Escala organizacional
Permite que uma empresa de avaliação opere melhor, com mais controle, produtividade e padronização.

### Nível 3 — Infraestrutura de mercado
Transforma a plataforma em um hub onde:
- financeiras plugam demanda;
- empresas de avaliação operam tecnicamente;
- vistoriadores executam em campo;
- a plataforma distribui, controla, mede, liquida e gera confiança.

## 4. Solução proposta

A solução é uma plataforma composta por:

- **App mobile do vistoriador** para aceite de jobs, check-in, captura de dados e fotos, execução offline e sincronização;
- **Backoffice web** para operação, despacho, revisão técnica, acompanhamento de SLA, valuation e emissão de laudo;
- **Camada de integração** para receber demanda de financeiras e outros parceiros;
- **Motor técnico** para processar dados conforme a NBR 14653;
- **Camada de orquestração** para controlar estados do processo;
- **Camada de pricing e settlement** para repasse e futura liquidação multi-partes.

## 5. Proposta de valor

### Para a empresa de avaliação
- mais produtividade;
- menos operação manual;
- maior controle sobre vistoriadores;
- melhor rastreabilidade;
- base pronta para escalar clientes e regiões.

### Para a financeira
- mais previsibilidade de SLA;
- mais transparência do processo;
- melhor qualidade e consistência das entregas;
- menor dependência de operação humana para acompanhamento.

### Para o vistoriador
- fluxo digital claro;
- recebimento organizado de jobs;
- histórico operacional;
- base futura para ganhos, repasses e reputação.

### Para o mercado
- uma infraestrutura que pode conectar oferta e demanda de vistoria e avaliação de forma padronizada.

## 6. Modelo de negócio

A plataforma pode monetizar por múltiplas alavancas ao longo do tempo.

### Curto prazo
- licença / assinatura SaaS da empresa de avaliação âncora;
- implantação e integração com financeira;
- cobrança por usuário, operação ou unidade de serviço.

### Médio prazo
- cobrança por job processado;
- cobrança por tenant / operação;
- cobrança por módulos premium (dispatch, control tower, SLA, analytics).

### Longo prazo
- fee por intermediação de demanda;
- fee por matching;
- fee por settlement;
- fee por white label;
- fee por integrações/APIs;
- fee por serviços complementares de inteligência, compliance e auditoria.

## 7. Estratégia de entrada no mercado

### Fase 1 — Go live controlado
Atender a empresa de avaliação âncora e uma financeira já conectada.

Objetivos:
- substituir distribuição manual;
- digitalizar a execução da vistoria;
- estruturar o fluxo técnico e documental;
- ganhar confiabilidade operacional.

### Fase 2 — Consolidação
Expandir para mais financeiras dentro da mesma estrutura operacional.

### Fase 3 — White label
Abrir a plataforma para outras empresas de avaliação como clientes.

### Fase 4 — Marketplace
Permitir que a plataforma encontre empresa de avaliação e rede de vistoriadores adequadas para cada demanda.

## 8. Diferenciais competitivos

- arquitetura preparada para white label e multi-tenant desde o início;
- modelo canônico próprio, desacoplado da financeira e da empresa de avaliação;
- rastreabilidade ponta a ponta;
- operação mobile offline-first;
- valuation e laudo integrados ao fluxo;
- preparação para distribuição inteligente de jobs;
- preparação para pricing, repasse e settlement;
- evolução natural para marketplace multi-lados.

## 9. Capacidades estratégicas futuras

Além do core atual, a plataforma pode evoluir para:

- matching inteligente por região, SLA, qualidade e custo;
- score de reputação de vistoriadores e empresas;
- control tower operacional;
- pricing dinâmico;
- settlement multi-partes;
- trilha regulatória e compliance como produto;
- APIs para terceiros;
- hub de serviços complementares ao processo imobiliário.

## 10. Riscos e mitigação

### Risco 1 — nascer acoplada ao arranjo atual
**Mitigação:** modelo canônico próprio, anti-corruption layer e arquitetura multi-organização.

### Risco 2 — operação crescer antes da plataforma estar pronta
**Mitigação:** lançamento focado no estágio 1 com fronteiras corretas.

### Risco 3 — dificuldade de escalar qualidade
**Mitigação:** trilha de auditoria, orchestrator, intelligence e governança técnica.

### Risco 4 — complexidade de evolução para marketplace
**Mitigação:** tratar job, case, tenant, partner e settlement como objetos centrais desde já.

## 11. Indicadores de sucesso

### Operacionais
- tempo de alocação de job;
- taxa de aceite;
- tempo total do ciclo;
- taxa de retrabalho;
- taxa de cancelamento;
- SLA por parceiro e por região.

### Financeiros
- custo por job;
- margem operacional;
- valor médio por job;
- valor médio de repasse;
- receita por cliente / tenant.

### Técnicos
- taxa de pendência técnica;
- taxa de contestação;
- tempo de geração de laudo;
- rastreabilidade completa dos artefatos.

## 12. Tese final

A melhor forma de lançar é começar pequeno, atendendo a operação real da empresa de avaliação âncora.

A melhor forma de construir é não nascer pequeno na arquitetura.

A plataforma deve entrar no mercado como solução operacional de alta eficiência, mas ser construída desde o início para evoluir para uma infraestrutura de mercado de vistorias e avaliação imobiliária.

Esse é o business case:
**resolver um problema operacional imediato e, ao mesmo tempo, construir um ativo estratégico com potencial de se tornar a camada de coordenação do setor.**
