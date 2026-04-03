# Plano de Execucao 30 Dias (Web + Mobile)

Atualizado em: 2026-03-29

## Objetivo
Sair de backlog para execucao com entregas verificaveis em 30 dias, priorizando:
1. Fundacao tecnica (stack, contratos e seguranca).
2. Integracao bidirecional confiavel entre Web e Mobile.
3. Primeira trilha operacional para check-in dinamico e sync de vistoria.

## Escopo da janela de 30 dias
1. BOW: 001, 004, 006, 008, 010, 011.
2. INT: 001, 002, 003, 004, 006, 007, 011, 012, 016.
3. BL suporte: BL-001, BL-012, BL-017, BL-021, BL-022, BL-023.

## Time minimo e ownership
1. Tech Lead Plataforma: arquitetura final, decisoes tecnicas, gate de seguranca.
2. Backend Squad: APIs, idempotencia, assinatura, anti-replay, observabilidade.
3. Frontend Web Squad: painel de configuracao check-in, painel operacional basico.
4. Mobile Squad: integracao de contrato, validacao de pacote, ACK/NACK, tratamento de erros.
5. QA/Automation: contract tests, testes E2E de resiliencia, criterios de aceite.
6. DevOps/SRE: CI/CD, secrets, monitoracao, alertas e runbooks.

## Plano semanal

### Semana 1 - Sprint Zero tecnica
1. Fechar padrao de arquitetura e repositorio de contratos OpenAPI (INT-002, BOW-006).
2. Subir base de API gateway com autenticacao e correlation id (INT-001, BOW-004).
3. Definir padrao de idempotencia para operacoes criticas (BOW-011, INT-006).
4. Publicar politica de secrets e rotacao por ambiente/tenant (BOW-005 referencia, INT-013 preparatorio).

Entregaveis:
1. Documento de contratos v1 aprovado por backend e mobile.
2. Gateway respondendo endpoints de health e autenticacao tecnica.
3. Matriz de erros padrao para mobile e web.

### Semana 2 - Downlink seguro (Web -> Mobile)
1. Implementar canal de configuracao remota assinada (INT-003, INT-011).
2. Implementar rollout/rollback por tenant e versao de app (INT-004, INT-014 base).
3. Entregar endpoint funcional de check-in dinamico (BOW-008).
4. Criar tela web minima para publicacao de versao de check-in (BOW-009 base funcional).

Entregaveis:
1. Pacote de configuracao assinado e validavel no mobile.
2. Operacao de rollback em um passo no backoffice.
3. Registro de publicacao com auditoria e correlation id.

### Semana 3 - Uplink resiliente (Mobile -> Web)
1. Implementar recebimento de vistoria final com idempotencia (BOW-010, INT-006).
2. Implementar protocolo unico de entrega e endpoint de status (INT-007, BOW-012 base).
3. Implementar anti-replay (nonce/timestamp/janela) para escrita critica (INT-012).
4. Adequar mobile para handshake de sync com codigos de erro padronizados (BL-001, BL-021).

Entregaveis:
1. Vistoria final persistida sem duplicidade em reenvio.
2. Protocolo consultavel pelo suporte e pelo mobile.
3. Testes de resiliencia com cenarios offline/retry aprovados.

### Semana 4 - Estabilizacao e Go/No-Go
1. Ativar contract tests no CI bloqueando quebra de contrato (INT-016, BL-017).
2. Montar dashboard minimo de operacao de integracao (INT-009, INT-018 baseline).
3. Definir e testar runbooks de incidente (timeout, fila, assinatura invalida, replay).
4. Homologar fluxo ponta a ponta com QA e negocio.

Entregaveis:
1. Pipeline com gates de contrato e qualidade.
2. Painel com p95, erro, retry e backlog por tenant.
3. Ata de Go/No-Go com riscos e mitigacoes.

## Criterios de aceite da janela (30 dias)
1. Mobile consome configuracao remota assinada com validacao de integridade.
2. Mobile envia vistoria final com idempotencia e recebe protocolo rastreavel.
3. Backoffice executa rollout e rollback de configuracao por tenant.
4. Quebra de contrato falha CI automaticamente.
5. Time operacional consegue diagnosticar falha por dashboard + logs + correlation id.

## Riscos principais e mitigacao
1. Divergencia de contrato entre squads.
Mitigacao: OpenAPI como fonte unica + contract test obrigatorio.

2. Complexidade de seguranca atrasando feature.
Mitigacao: escopo minimo viavel com assinatura + anti-replay so nos endpoints criticos.

3. Falta de observabilidade no inicio.
Mitigacao: baseline obrigatoria na Semana 1 (logs estruturados + metricas minimas).

4. Dependencia de aprovacao externa (seguranca/compliance).
Mitigacao: checkpoint formal no fim da Semana 2 com evidencias tecnicas.

## Checklist da segunda-feira (acao imediata)
1. Nomear owners por frente (backend, web, mobile, qa, devops).
2. Abrir epicos no tracker: Fundacao, Downlink, Uplink, Estabilizacao.
3. Criar repositorio/pasta de contratos OpenAPI e publicar versao v1.
4. Configurar gate de CI inicial para lint + schema + contract tests (mesmo que parcial).
5. Agendar cerimonia de alinhamento tecnico de 60 minutos com todos os leads.

## Referencias
1. docs/BACKLOG_BACKOFFICE_WEB.md
2. docs/BACKLOG_INTEGRACAO_WEB_MOBILE.md
3. docs/BACKLOG_FUNCIONALIDADES.md