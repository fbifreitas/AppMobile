# AGENT OPERATING SYSTEM

## Objetivo
Ser o sistema operacional de execucao do agente para tarefas deste repositorio, mantendo a direcao multi-brand ativa.

## Escopo
- Documento operacional ativo.
- Nao substitui a direcao arquitetural multi-brand.
- Ler junto com README.md, GEMINI.md, .github/copilot-instructions.md e docs estrategicos de arquitetura.

## Fluxo padrao do agente
1. Classificar tarefa por camada e dominio.
2. Ler fontes oficiais por tema (SOURCE_OF_TRUTH_MATRIX.md).
3. Confirmar backlog de referencia (estrategico ou tatico).
4. Executar mudanca no menor escopo possivel.
5. Validar (testes, lint, build, links) conforme tipo de trabalho.
6. Registrar evidencia de conclusao.
7. Atualizar docs/backlog quando houver impacto.
8. Aplicar regra de parada quando houver risco (WHEN_TO_STOP_AND_ASK.md).

## Classificacao por camada
- corporate
- platform-core
- shared-foundation
- domain-inspection
- domain-wellness
- domain-church
- experience-layer
- data-intelligence
- legacy

## Leitura por intencao
- Arquitetura/escopo: docs/03-architecture/* e docs/04-engineering/*
- Operacao diaria: docs/05-operations/01_OPERATING_MODEL.md
- Fonte oficial por tema: docs/05-operations/SOURCE_OF_TRUTH_MATRIX.md
- Inicio de tarefa: docs/05-operations/TASK_BRIEF_TEMPLATE.md
- Criterio de pronto: docs/05-operations/DONE_CHECKLIST_BY_WORK_TYPE.md
- Limite de autonomia: docs/05-operations/WHEN_TO_STOP_AND_ASK.md

## Escolha de backlog
- Estrategico: docs/BACKLOG_V2_PRIORIDADES.md
- Tatico mobile/operacao: docs/05-operations/tactical-backlogs/BACKLOG_FUNCIONALIDADES.md
- Tatico web/backoffice: docs/05-operations/tactical-backlogs/BACKLOG_BACKOFFICE_WEB.md
- Tatico integracao: docs/05-operations/tactical-backlogs/BACKLOG_INTEGRACAO_WEB_MOBILE.md

## Validacao minima
- Documentacao: links e ponteiros atualizados.
- Codigo: testes/lint/build conforme frente.
- Backlog: status e rastreabilidade atualizados quando aplicavel.

## Procedimento de execucao (anti-travamento)
- Para comandos pesados (`flutter analyze`, `flutter test`, `mvn test`, build web), executar de forma serial (nunca em paralelo).
- Usar timeout explicito por comando e registrar comando/resultado ao final.
- Em Flutter, preferir sequencia:
  - `flutter pub get` (uma vez no inicio da sessao)
  - `flutter analyze --no-pub`
  - `flutter test --no-pub`
- Se houver interrupcao/timeout recorrente no terminal do agente, executar no terminal nativo (VS Code/PowerShell externo) e registrar evidencia no resumo da entrega.
- Se processo ficar preso, encerrar `flutter`/`dart` pendentes antes de nova tentativa.

## Regra de Ouro (TDD)
- Todo pacote de desenvolvimento deve ser orientado a testes (TDD sempre que viavel).
- Nao subir pacote sem executar os testes relevantes da mudanca.
- Nao considerar entrega pronta com testes falhando ou nao executados.
- Se ambiente/ferramenta impedir execucao de testes, registrar bloqueio explicitamente e tratar como risco de release.

## Evidencia de conclusao
- Arquivos alterados
- Validacoes executadas
- Riscos residuais
- Proximo passo recomendado

## Criterios de parada
Parar e pedir alinhamento quando houver risco de violar fronteira de camada/dominio ou conflito entre docs ativos.
Ver detalhes em docs/05-operations/WHEN_TO_STOP_AND_ASK.md.
