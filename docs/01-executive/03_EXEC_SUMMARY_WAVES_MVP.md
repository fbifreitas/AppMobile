# EXEC SUMMARY WAVES MVP

Atualizado em: 2026-04-04

## Objetivo
Traduzir a estrategia em leitura executiva de entrega: o que ja esta pronto, o que esta em execucao agora e o que falta por onda para avancar milestones.

## Leitura rapida
- Onda 1 e o milestone de lancamento.
- Onda 1 nao precisa 100% concluida para lancar; precisa do MVP interno funcional fechado.
- Ondas 2, 3 e 4 seguem como evolucao de robustez, escala multi-tenant e marketplace.

## Onda 1 - Go-live controlado (0-90 dias)
### MVP interno da Onda 1 (gate de lancamento)
1. Mobile operando fluxo real de vistoria com configuracao dinamica e sync real.
2. Web/backoffice operando users, inspections e configuracao operacional.
3. Integracao web-mobile com idempotencia, contrato e rastreabilidade minima.

### Ja pronto (funcional)
1. Mobile: fluxo de check-in/camera/revisao/historico ja maduro, fila offline e varios BL concluidos.
2. Web: dashboard inicial, users (list/create/import/pending/audit) e painel de inspections recebidas.
3. Plataforma: IAM base, auth backend-first, RBAC/policy, integration hub e erro canonico base.

### Em execucao agora
1. BOW-120, BOW-121, BOW-122.
2. BL-012, BL-001, BL-051, BL-052, BL-054, BL-031.
3. INT-026 e INT-028.

### Falta para fechar MVP interno e lancar
1. Fechar BOW-120/121/122 com consumo ponta a ponta no app.
2. Fechar BOW-130 e BOW-131 (mobile ligado ao backend real sem fallback estrutural como caminho principal).
3. Fechar BL-012 + BL-001 + BL-051 + BL-052 + BL-031.
4. Fechar gate tecnico de integracao: INT-001/002/016 e consolidar INT-003/004/006.
5. Fechar BL-056 (permissoes obrigatorias antes do uso operacional em campo).

### Avanco estimado
- Onda 1: ~56%

## Onda 2 - Robustez operacional (90-180 dias)
### Foco executivo
Escalar com confiabilidade: workforce, dispatch completo, notificacoes, SLA, telemetria e orquestracao.

### Ja pronto (base parcial)
1. Dispatch basico ja aparece no dominio de jobs.
2. Aprovacao web de usuarios ja esta operacional.

### Em execucao agora
1. Nao ha trilha formal de fechamento de Onda 2 ativa; existem pre-implementacoes parciais.

### Falta para milestone da onda
1. BOW-200, BOW-201, BOW-202, BOW-203, BOW-210, BOW-211 fechados.

### Avanco estimado
- Onda 2: ~18%

## Onda 3 - White-label multi-tenant (180-270 dias)
### Foco executivo
Escala comercial: multi-tenant real com isolamento forte, branding por tenant e federacao por tenant.

### Ja pronto (base parcial)
1. Fundacao tenant/membership ativa.
2. Configuracao por tenant com targeting/rollout/rollback ja presente no backoffice.
3. Abstracao de provider pronta para evoluir OIDC/SAML.

### Em execucao agora
1. Evolucao parcial de fundacao (sem fechamento de isolamento forte e sem tenant management completo).

### Falta para milestone da onda
1. BOW-300, BOW-301, BOW-302, BOW-303 fechados.

### Avanco estimado
- Onda 3: ~21%

## Onda 4 - Marketplace (270-365+ dias)
### Foco executivo
Operar ecossistema: provider network, matching, settlement multiparte e control tower.

### Ja pronto
1. Sem entrega estrutural fechada de marketplace no codigo ativo.

### Em execucao agora
1. Nao ha frente dedicada ativa de Onda 4.

### Falta para milestone da onda
1. BOW-400, BOW-401, BOW-402, BOW-403.

### Avanco estimado
- Onda 4: ~0-2%

## Linha do tempo executiva
1. Agora ate lancamento: fechar MVP interno da Onda 1.
2. Pos-lancamento imediato: consolidar Onda 2 (robustez operacional).
3. Escala comercial: consolidar Onda 3 (multi-tenant/white-label real).
4. Expansao de ecossistema: executar Onda 4 (marketplace).

## Regra de governanca
Toda mudanca de status de onda deve refletir em:
1. backlog estrategico (`docs/BACKLOG_V2_PRIORIDADES.md`)
2. backlog tatico correspondente (backoffice, front/web, mobile, integracao)
3. evidencia em codigo/testes e registro de release
