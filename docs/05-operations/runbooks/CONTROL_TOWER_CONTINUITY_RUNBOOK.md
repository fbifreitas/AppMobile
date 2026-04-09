# CONTROL_TOWER_CONTINUITY_RUNBOOK

Atualizado em: 2026-04-08

## Objetivo
Orientar a operacao quando houver anomalia no fluxo `config -> finalized inspection -> valuation -> report` usando a control tower operacional do backoffice.

## Entrada primaria
- Tela: `/backoffice/operations`
- API: `/api/backoffice/operations/control-tower`

## Procedimento
1. Filtrar o tenant afetado na control tower.
2. Ler os alertas ativos e identificar o `endpointKey` afetado.
3. Localizar o evento recente pelo `correlationId`, `protocolId`, `jobId`, `processId` ou `reportId`.
4. Classificar o incidente:
   - `mobile.inspections.finalized`: problema de envio, retry ou idempotencia;
   - `backoffice.valuation.validate-intake`: problema de intake;
   - `backoffice.reports.generate` ou `backoffice.reports.review`: problema de laudo/processo tecnico;
   - `backoffice.config.*`: problema de publish/approve/rollback.
5. Decidir a acao:
   - retry seguro quando houver duplicidade idempotente;
   - rollback quando houver pacote/configuracao afetada;
   - tratamento manual de intake/report quando a falha estiver apos o recebimento da vistoria.

## Checks obrigatorios
1. Verificar `X-Correlation-Id` e `X-Trace-Id` antes de abrir log bruto.
2. Verificar backlog operacional:
   - `pendingIntake`
   - `processing`
   - `pendingConfigApprovals`
3. Verificar se houve cleanup de retention recente antes de assumir perda de evidencia.

## Saida esperada
- incidente classificado;
- identificador tecnico localizado;
- acao operacional definida;
- tenant impactado isolado.
