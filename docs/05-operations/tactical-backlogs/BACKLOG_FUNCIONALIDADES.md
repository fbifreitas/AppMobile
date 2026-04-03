> [NOTA DE ESCOPO - OPERACIONAL ATIVO]
> Este e um documento operacional ativo.
> Este documento nao substitui a direcao arquitetural V2 corporativa do repositorio.
> Deve ser lido em conjunto com README.md, GEMINI.md, .github/copilot-instructions.md e os documentos ativos da V2 em docs/.

> [31/03/2026] **Ajuste operacional:**
> Esteira de distribuição Android ajustada para garantir que builds automáticos sejam enviados apenas ao grupo "prod-testers" no Firebase App Distribution. Builds manuais permitem seleção de grupo, com padrão "testers-internos". Mudança documentada para rastreabilidade e prevenção de erros operacionais. (Ver detalhes no plano operacional e workflows)
# Backlog de Funcionalidades Nao Implementadas

Atualizado em: 2026-04-01

## Objetivo
Registrar funcionalidades pendentes para evolucao do AppMobile, com foco em priorizacao de produto e previsibilidade tecnica.

## Backlog complementar de backoffice web
Para planejamento do sistema web de backoffice (APIs, painéis e configurações para suportar o app mobile), consultar `docs/05-operations/tactical-backlogs/BACKLOG_BACKOFFICE_WEB.md`.

## Backlog complementar de integração web-mobile
Para segurança, contratos e comunicação bidirecional entre app e backoffice, consultar `docs/05-operations/tactical-backlogs/BACKLOG_INTEGRACAO_WEB_MOBILE.md`.

## Plano de execucao (proximos 30 dias)
Para transformar backlog em entrega com marcos semanais, ownership e criterios de aceite, consultar `docs/05-operations/runbooks/PLANO_EXECUCAO_30_DIAS_WEB_MOBILE.md`.

## Cabecalho executavel (padrao)

Usar este cabecalho nos itens priorizados:
- Camada
- Dominio
- Area
- Objetivo
- Arquivos provaveis
- Dependencias
- Testes obrigatorios
- Evidencia esperada
- Docs que precisam ser atualizados
- Criterio de pronto

## 🎯 Roadmap de Priorização

A sequência de implementação foi definida considerando:
- **Dependências técnicas**: itens que desbloqueiam outros
- **Crítica para NBR**: conformidade regulatória não é negociável
- **Impacto no fluxo**: validação em checkin/revisão

**Fluxo de implementação recomendado:**

```
Step 1️⃣ (CRÍTICA) → BL-012 + BL-001
    ↓
Step 2️⃣ (ALTA) → BL-002 + BL-008 + BL-015
    ↓
Step 3️⃣ (ALTA) → BL-003 + BL-006
    ↓
Step 4️⃣ (ALTA) → BL-010
    ↓
Step 5️⃣ (MÉDIA) → BL-004, BL-005, BL-007, BL-009, BL-016, BL-037, BL-038, BL-039
  ↓
Step 6️⃣ (DÉBITO TÉCNICO) → BL-013 + BL-014 + BL-036
  ↓
Step 7️⃣ (BOAS PRÁTICAS) → BL-017, BL-018, BL-019, BL-020, BL-021, BL-022, BL-023, BL-024, BL-025, BL-026, BL-027, BL-028
  ↓
Step 8️⃣ (BACKEND BLOQUEADO — aguarda Onda 1 BOW) → BL-031 (depende de BOW-100 + BOW-101 + BOW-102), BL-032, BL-033, BL-034, BL-035, BL-029, BL-030
```

---

## Itens Priorizados

| Seq | ID | Funcionalidade | Status | Prioridade | Criterio de pronto |
|---|---|---|---|---|---|
| **1️⃣ AGORA** | **BL-012** | **Menus de checkin etapa 1 e 2 dinamicos via backend (sessoes NBR)** | Em andamento | 🔴 **CRÍTICA** | Sessoes de captura (fachada, ambiente, elemento) com requisitos obrigatorio/desejavel configuravel via API, sem hardcoding |
| **2️⃣ AGORA** | **BL-001** | **Integracao de envio do JSON final da vistoria para sistema web (API real)** | Em andamento | 🔴 **CRÍTICA** | JSON de encerramento enviado para endpoint autenticado com retentativa e log de sucesso/erro |
| 3️⃣ | BL-002 | Fila offline para exportacao/sincronizacao de vistorias finalizadas | Concluido | 🟠 Alta | Se sem internet, arquivo entra em fila local e sincroniza automaticamente ao reconectar |
| 4️⃣ | BL-008 | Auditoria de fallback por etapa (checkin, step2, camera, review) | Concluido | 🟠 Alta | Relatorio interno mostra consistencia de payload, retomada por etapa e pilha de navegacao ao retomar vistoria |
| 5️⃣ | BL-015 | Associar capturas iniciadas na camera com checkin etapa 2 e revisao | Concluído | 🟠 Alta | Captura iniciada fora da etapa 2 atualiza cards/pendencias obrigatorias no checkin e preserva fotos anteriores na revisao |
| 6️⃣ | BL-003 | Tela de detalhes da vistoria concluida (somente leitura) | Concluido | 🟠 Alta | Aba Vistorias permite abrir detalhes completos sem edicao |
| 7️⃣ | BL-006 | Modo desenvolvedor: editor completo de mocks para menus dinamicos da camera | Concluido | 🟠 Alta | Painel dev permite editar cenarios e menus dinamicos sem alterar codigo |
| 8️⃣ | BL-010 | Endurecimento de bloqueio de recursos dev em release final | Concluido | 🟠 Alta | Recursos dev nao aparecem para usuario final sem desbloqueio autorizado |
| 9️⃣ | BL-004 | Exibir protocolo/ID externo no card e no historico de vistorias | Concluido | 🟡 Media | Card mostra ID do job e protocolo externo quando existir |
| 🔟 | BL-005 | Regras de retencao e limpeza de arquivos JSON exportados | Concluído | 🟡 Media | Politica configuravel (ex.: manter ultimos N dias) com limpeza segura |
| 1️⃣1️⃣ | BL-016 | Diretorio de exportacao JSON configuravel para conferencia operacional | Concluido | 🟡 Media | Export permite alternar destino (interno/externo) sem perder rastreabilidade e fluxo de sync |
| 1️⃣2️⃣ | BL-037 | Matriz de pendencia tecnica com linguagem operacional e acao guiada | Concluido | 🟠 Alta | Matriz apresenta texto simples e link/acao direta para levar o usuario ao ponto exato da pendencia no fluxo |
| 1️⃣3️⃣ | BL-038 | Preservar classificacao revisada ao retornar da camera para revisao | Concluido | 🟠 Alta | Fotos ja classificadas nao regressam para status laranja ao adicionar nova captura e voltar para revisao |
| 1️⃣4️⃣ | BL-039 | Agrupar revisao no topo por fotos obrigatorias e fotos capturadas | Concluido | 🟡 Media | Topo da revisao exibe agrupadores claros de obrigatorias e capturadas, alinhado ao bloco de pendencias |
| 1️⃣5️⃣ | BL-007 | Seed de cenarios de QA por perfil (1, 3, 10 vistorias; ativas/concluidas) | Pendente | 🟡 Media | Um toque aplica cenarios pre-definidos para homologacao |
| 1️⃣6️⃣ | BL-009 | Telemetria de fluxo (inicio, retomada, conclusao, falhas de integracao) | Pendente | 🟡 Media | Eventos minimos registrados para diagnostico operacional |
| ⏸️  | BL-011 | Flavors de distribuicao (prod, internal, dev) | Adiado | 🟡 Media | Entrypoints e pipeline separados para builds internos e producao |
| ⚡ | BL-036 | Cache de Flutter/pub no pipeline CI (débito técnico) | Pendente | 🔵 Baixa (pos-funcional) | Pipeline reduz tempo de build cacheando `.pub-cache` e `.dart_tool` com chave baseada em `pubspec.lock` |
| 🔧 | BL-013 | Auditoria de Clean Code e SOLID (débito técnico) | Planejado | 🔵 Baixa (pos-funcional) | Relatorio técnico com achados, plano de refatoracao e aplicacao incremental por modulo sem regressao funcional |
| 🧪 | BL-014 | Evolução da suíte de testes com prática TDD (débito técnico) | Em andamento | 🔵 Baixa (pos-funcional) | Cobertura de testes ampliada por fluxo crítico, com testes criados/atualizados a cada entrega funcional |
| 🧱 | BL-017 | Contract testing de APIs mobile-backend | Planejado | 🟠 Alta | Contratos de request/response validados em CI para endpoints críticos (config dinâmica e sync) |
| 🧬 | BL-018 | Mutation testing para regras críticas | Planejado | 🟡 Media | Mutation score mínimo definido e monitorado para serviços críticos |
| 📈 | BL-019 | Quality gate de cobertura por módulo | Planejado | 🟠 Alta | CI bloqueia merge quando cobertura mínima por módulo regredir |
| 🧭 | BL-020 | Fronteiras de arquitetura e inversão de dependência | Planejado | 🟠 Alta | Camadas desacopladas com interfaces explícitas entre domínio, aplicação e infraestrutura |
| ⚠️ | BL-021 | Estratégia padronizada de tratamento de erros | Planejado | 🟠 Alta | Erros tipados, mensagens consistentes e ausência de catch silencioso nos fluxos críticos |
| 🔗 | BL-022 | Observabilidade com correlation id por vistoria | Planejado | 🟡 Media | Eventos de ponta a ponta rastreáveis por job/correlation id |
| 🔐 | BL-023 | Hardening de segurança e gestão de secrets | Em andamento | 🟠 Alta | Segredos fora do código, validação de configuração e checklist de segurança em release |
| ⚡ | BL-024 | Performance budgets em fluxos críticos | Planejado | 🟡 Media | Metas de tempo por etapa monitoradas com alerta de regressão |
| 📦 | BL-025 | Governança de dependências e vulnerabilidades | Planejado | 🟡 Media | Rotina de atualização com scanner e política de correção de CVEs |
| 🧾 | BL-026 | ADRs para decisões arquiteturais | Planejado | 🟡 Media | Decisões técnicas relevantes registradas com contexto e trade-offs |
| 🚩 | BL-027 | Ciclo de vida de feature flags | Planejado | 🟡 Media | Processo de criação, auditoria e remoção de flags sem acúmulo técnico |
| ✅ | BL-028 | Definition of Done reforçada | Planejado | 🟠 Alta | Entrega só conclui com testes, observabilidade mínima, documentação e checklist QA |
| 🗓️ | BL-029 | Agenda em calendário com jobs agendados do usuário | Concluido | 🟠 Alta | Aba Agenda exibe calendário mensal/semanal com jobs por data e navegação para detalhes |
| 🔔 | BL-030 | Sininho de mensagens com central backend-app e push | Concluido | 🔴 Crítica | Mensagens vinculadas a job/proposta aparecem na central e geram notificação no celular mesmo com app fechado |
| 🔐 | BL-031 | Tela de login e autenticação do App | Em andamento | 🔴 Crítica | Usuário autentica com backend, sessão persistida com expiração/renovação, controle de tentativas, MFA readiness e logout seguro |
| 🧾 | BL-032 | Onboarding de usuários CLT e PJ no app | Concluido | 🔴 Crítica | Fluxo coleta dados obrigatórios por tipo (CLT/PJ), incluindo dados pessoais e bancários para PJ |
| ⏳ | BL-033 | Estado aguardando aprovação do cadastro (backoffice) | Concluido | 🟠 Alta | Após onboarding, usuário sem aprovação visualiza tela estática de aguardando aprovação com atualização de status |
| ⚙️ | BL-034 | Configurações para atualização de dados cadastrais | Concluido | 🟠 Alta | Menu configurações permite editar os mesmos dados do onboarding com validação e envio ao backend |
| 🧑 | BL-035 | Foto do usuário no topo com captura e atualização | Concluido | 🟠 Alta | Foto do onboarding aparece no topo da Home e pode ser atualizada por captura de câmera (sem galeria) |
| 4️⃣0️⃣ | BL-040 | Corrigir consistência NBR: obrigatoriedade de Entorno no Checkin Etapa 2 e Revisão | Concluído | 🔴 Crítica | Entorno obrigatório deve ser consistente em Checkin Etapa 2 e Pendências Técnicas; ação "Ir para pendência" não pode travar fluxo |
| 4️⃣1️⃣ | BL-041 | Reorganizar Revisão de Fotos com acordeões de obrigatórias e capturadas no bloco inferior | Concluído | 🟠 Alta | Bloco "Revisão de Fotos Obrigatórias" deve ficar abaixo, com dois acordeões independentes e estados visuais OK/NOK |
| 4️⃣2️⃣ | BL-042 | Exibir ID do JOB em Novas Propostas e simular aceite por deslize com movimentação de card | Concluído | 🟠 Alta | Card de proposta mostra ID do job e, ao aceitar, sai de propostas e entra em "Meus Jobs Agendados" via mock atualizado |
| 4️⃣3️⃣ | BL-043 | Remover overlay fixo de comandos rápidos por voz na câmera | Concluído | 🟡 Media | Componente de voz não pode cobrir a área principal de captura/classificação |
| 4️⃣4️⃣ | BL-044 | Adicionar colapso lateral dos menus dinâmicos da câmera com abertura padrão expandida | Concluído | 🟠 Alta | Menu lateral inicia expandido e permite ocultar/mostrar via controle lateral sem impactar captura |
| 4️⃣5️⃣ | BL-045 | Mover exportação da vistoria de Configurações para Hub Operacional | Concluído | 🟡 Media | Entrada de exportação deve estar no Hub Operacional e removida de Configurações |
| 4️⃣6️⃣ | BL-046 | Corrigir logout em Configurações com retorno para tela de login (mock) | Concluído | 🔴 Crítica | Ação "Sair da conta" limpa sessão mock e retorna para login consistentemente |
| 4️⃣7️⃣ | BL-047 | Ajustar onboarding do app para fluxo exclusivamente PJ com validações de CNPJ/Agência/Conta/Banco | Concluído | 🔴 Crítica | Tela inicial não deve pedir CLT/PJ e campos PJ devem validar formato e consistência mínima |
| 4️⃣8️⃣ | BL-048 | Criar ação no Hub Operacional para resetar mock de onboarding | Concluído | 🟠 Alta | Operador deve conseguir zerar estado de onboarding para reteste sem reinstalar app |
| 4️⃣9️⃣ | BL-049 | Consolidar GitHub Project como fonte primária do backlog com sincronização total dos itens BL | Em andamento | 🟠 Alta | Todos os BL (pendentes, em andamento, concluídos e adiados) devem existir no board com status e critérios atualizados |
| 5️⃣0️⃣ | BL-050 | Corrigir botão "Concluir" do onboarding encoberto pelo rodapé do Android | Concluído | 🟠 Alta | Botão final do onboarding deve permanecer totalmente visível em Android (botões/gestos), permitindo concluir o fluxo sem obstrução |
| 5️⃣1️⃣ | BL-051 | Unificar persistência dinâmica de obrigatoriedade e política de fotos (mín/máx) entre Checkin, Câmera, Revisão e Menu | Em andamento | 🔴 Crítica | Mesma regra dinâmica deve governar validação e indicadores em todas as telas, com suporte a mínimo/máximo de fotos sem divergência de payload |
| 5️⃣2️⃣ | BL-052 | Unificar pacote de parametrização operacional do HUB para Check-in e Câmera por níveis | Em andamento | 🔴 Crítica | Mesmo documento do modo desenvolvedor deve definir menus do check-in e níveis da câmera, incluindo material e estado, sem contratos paralelos |
| 5️⃣3️⃣ | BL-054 | UX progressiva no Check-in etapa 1 e 2 com acordeões por pergunta e resumo inline da resposta | Em andamento | 🟠 Alta | Exibir apenas a próxima pergunta pendente, colapsar respostas já preenchidas com status visual OK/NOK e manter feedback de progresso x/y durante o preenchimento |
| 5️⃣4️⃣ | BL-055 | Revisar hierarquia visual e regras de casing por nível no Menu de Vistoria e Check-in Etapa 2 | Concluído | 🟠 Alta | Nível 1 em Title Case, nível 2 em CAIXA ALTA, nível 3 em Title Case, com acordeões iniciando recolhidos conforme regra operacional |
| 5️⃣5️⃣ | BL-056 | Tela dedicada de onboarding de permissões Android e iOS com reentrada obrigatória para usuários sem etapa de onboarding (ex.: CLTs criados via web) | Pendente | 🔴 Crítica | Usuário concede permissões essenciais no onboarding inicial e, quando autenticado sem onboarding concluído, é redirecionado para tela de permissões antes de usar fluxos operacionais |

---

## Descricoes dos Itens

### Bloco executavel prioritario (inicio)

#### BL-012
- Camada: experience-layer
- Dominio: domain-inspection
- Area: mobile check-in
- Objetivo: menus check-in etapa 1 e 2 dinamicos via backend
- Arquivos provaveis: `lib/screens/*checkin*`, `lib/services/*config*`, `lib/state/*`
- Dependencias: BOW-008, INT-003
- Testes obrigatorios: widget tests de fluxo check-in + validacao de contrato de config
- Evidencia esperada: telas e payload final coerentes com configuracao dinamica
- Docs a atualizar: este backlog e backlog de integracao relacionado
- Criterio de pronto: sem hardcoding de sessoes obrigatorias no fluxo critico

#### BL-001
- Camada: experience-layer
- Dominio: domain-inspection
- Area: mobile sync/integracao
- Objetivo: envio do JSON final para API real com rastreabilidade
- Arquivos provaveis: `lib/services/*sync*`, `lib/repositories/*`, `lib/state/*`
- Dependencias: BOW-010, INT-006, INT-007
- Testes obrigatorios: testes de sync com sucesso/falha/retry
- Evidencia esperada: protocolo de retorno persistido e exibido
- Docs a atualizar: este backlog e backlog de integracao
- Criterio de pronto: sync real autenticado com retentativa e log de resultado

### BL-012
Tornar os menus de checkin etapa 1 e etapa 2 dinamicos via backend, permitindo adicionar/remover sessoes e definir obrigatoriedade (NBR) sem novo deploy do app.

Observacao 2026-03-30 (Em andamento): adicionado fallback de configuracao dinamica por modo desenvolvedor, com documento JSON local configuravel no painel de dados mock. Fluxo de leitura agora prioriza mock local quando habilitado, depois API, depois cache, e por ultimo fallback hardcoded.

### BL-001
Enviar o JSON final da vistoria para a API web oficial com autenticacao, registro de sucesso/erro e rastreabilidade por job.

Observacao 2026-03-30: payloads de origem financeira para criacao de processo devem ser tratados e normalizados no backoffice/integracao (docs/05-operations/tactical-backlogs/BACKLOG_BACKOFFICE_WEB.md e docs/05-operations/tactical-backlogs/BACKLOG_INTEGRACAO_WEB_MOBILE.md). O app mobile consome apenas campos operacionais expostos pelas APIs internas (jobs/config/sync), evitando acoplamento ao contrato externo bruto.

Observacao 2026-03-30 (Em andamento): sincronizacao final passou a interpretar metadados de resposta da API (ex.: process_id/process_number/status) e a expor protocolo no feedback de conclusao. Adicionado tambem modo desenvolvedor para resposta mock de sync quando a integracao web definitiva ainda nao estiver disponivel.

### BL-002
Criar fila offline para armazenar vistorias finalizadas quando nao houver conectividade e sincronizar automaticamente quando a rede retornar.

### BL-008
Implementar auditoria de fallback por etapa (checkin, step2, camera e review) para identificar inconsistencias de payload e problemas de retomada.

### BL-015
Garantir que capturas iniciadas diretamente pela camera (fora do fluxo da etapa 2) sejam conciliadas automaticamente com os requisitos do checkin etapa 2 e com as pendencias da revisao final.

Observacao 2026-03-30: ajustada a persistencia do status das fotos obrigatorias do check-in na revisao/menu de vistoria, reconstruindo o indicador tambem a partir do payload salvo da etapa 2 para evitar perda visual do status OK ao voltar no fluxo.

Observacao 2026-03-30 (CORRIGIDO): bug do status verde desaparecendo ao voltar para Menu de Vistoria - `InspectionMenuScreen` agora consulta tambem `appState.step2Payload` (nao apenas `InspectionSession`) para recalcular status das fotos obrigatorias, garantindo persistencia mesmo quando sessao nao foi sincronizada. Adicionado metodo `_countCompletedMandatoryFields()` que reconstroi indicador a partir de ambas fontes de dados.

Observacao 2026-03-30: iniciada a centralizacao da navegacao do fluxo Home -> Check-in -> Camera -> Revisao com coordinator injetavel, reduzindo acoplamento entre telas e abrindo caminho para testes estaveis de retorno da camera e retomada da pilha.

Observacao 2026-03-30: estendida a centralizacao para hubs secundarios (Home, Hub operacional e Centro de integracao), concentrando o despacho de atalhos e centrais em um coordinator unico para reduzir switches duplicados e facilitar testes de navegacao.

Observacao 2026-03-30: a tela Menu de Vistoria passou a delegar a abertura da revisao ao coordinator do fluxo, e a cobertura automatizada agora valida tambem os atalhos do header da Home e os entrypoints secundarios de navegacao.

### BL-003
Disponibilizar tela de detalhes da vistoria concluida em modo somente leitura, acessivel pela aba Vistorias, sem qualquer possibilidade de edicao.

### BL-006
Expandir o painel de modo desenvolvedor para editar mocks completos, incluindo menus dinamicos de camera e cenarios de teste sem alteracao de codigo.

Observacao 2026-03-30 (CONCLUIDO): painel de mock ganhou presets QA (1/3/10), edicao de JSON de configuracao dinamica, resposta de sync e editor avancado para agenda e mensagens com aplicacao em runtime.

### BL-010
Fortalecer bloqueios de recursos de desenvolvimento em build de release para impedir exposicao acidental de funcionalidades internas ao usuario final.

Observacao 2026-03-30 (CONCLUIDO): acesso a recursos dev bloqueado em release no estado global, com feedback de bloqueio nas configuracoes e protecao de tela no painel de mocks sem desbloqueio autorizado.

Observacao 2026-03-31: bloqueio de acesso em release esta concluido, mas a remocao fisica do modulo desenvolvedor do binario final ainda nao foi aplicada.

### BL-004
Exibir identificadores operacionais (ID do job e protocolo externo) no card da home e no historico, facilitando rastreio e suporte.

Observacao 2026-03-30 (CONCLUIDO): card da Home e lista de Vistorias concluidas passaram a exibir ID externo e Protocolo quando disponiveis. Fluxo de conclusao da revisao agora persiste referencias externas recebidas do backend no job atual, e testes cobrem a renderizacao no card ativo e no historico.

### BL-005
Definir politica de retencao e limpeza dos JSONs exportados, com regras seguras para manter historico util sem crescimento indefinido de armazenamento.

Observacao 2026-03-31 (CONCLUIDO): configuracao de retencao (dias) adicionada ao Hub Operacional junto da configuracao de exportacao, com acao de limpeza imediata e politica persistida em preferencias. Servico de exportacao aplica limpeza segura por idade dos arquivos JSON de vistoria.

### BL-016
Permitir configuracao do diretorio de exportacao do JSON final (interno e/ou externo para conferencia operacional), mantendo consistencia com fila offline e rastreabilidade por job.

Observacao 2026-03-30 (CONCLUIDO): adicionada configuracao em `Configuracoes` para destino da exportacao (interno/externo) e subdiretorio customizavel. A resolucao efetiva aplica fallback automatico para interno quando externo nao estiver disponivel, preservando o fluxo de sincronizacao e a rastreabilidade por job.

Observacao 2026-03-30: apos revisao UX do Menu de Vistoria, os itens BL-037, BL-038 e BL-039 foram priorizados para entrar na sequencia do BL-016.

### BL-037
Evoluir a matriz de pendencia tecnica para linguagem comum ao usuario operacional, com mensagens objetivas e acao guiada por pendencia.

Observacao 2026-03-30 (CONCLUIDO): matriz atualizada com linguagem mais operacional e atalho "Ir para pendencia" para navegacao direta dentro da tela de revisao. Cobertura de regressao adicionada para garantir a renderizacao da acao guiada.

Detalhamento:
1. Reescrever descricoes tecnicas em texto orientado a tarefa.
2. Adicionar link/botao "ir para pendencia" para levar ao ponto correto do fluxo (check-in, camera ou revisao).
3. Exibir contexto minimo: o que falta, onde resolver e como confirmar conclusao.

### BL-038
Garantir preservacao da classificacao ja revisada quando o usuario retorna da camera com novas fotos.

Observacao 2026-03-30 (CONCLUIDO): revisao passou a persistir e reidratar capturas revisadas no draft de recovery, mantendo classificacoes existentes ao voltar da camera para a revisao. Testes de regressao validam que a captura ja revisada permanece classificada enquanto novas capturas entram como pendentes ate revisao.

Detalhamento:
1. Reconciliar capturas novas sem resetar classificacao existente.
2. Manter status verde dos itens ja classificados quando nao houver alteracao de conteudo/classificacao.
3. Cobrir com testes de navegacao e regressao do fluxo revisao -> camera -> revisao.

### BL-039
Reorganizar o topo da revisao de fotos com agrupadores equivalentes ao bloco de pendencias.

Observacao 2026-03-30 (CONCLUIDO): topo da revisao atualizado com agrupadores de "Fotos obrigatorias" e "Fotos capturadas", com contadores de progresso por grupo. Cobertura automatizada adicionada para preservar a leitura do resumo no topo.

Observacao 2026-04-01 (Em andamento): retomada de ajustes UX no Menu de Vistoria para deduplicar itens obrigatorios com mesmo titulo (ex.: Fachada), exibir progresso x/y por bloco e reforcar navegacao do atalho "Ir para pendencia" com foco direto na secao correspondente.

Observacao 2026-04-01 (Em andamento): estrutura visual do Menu de Vistoria padronizada por secoes em accordion (Pendencias tecnicas por etapa, Revisao de fotos e Encerramento), mantendo compatibilidade com validacoes automatizadas existentes.

Observacao 2026-04-01 (Em andamento): padrao de texto aplicado no menu e telas irmas com primeiro nivel em caixa alta e niveis internos em Title Case para leitura operacional consistente.

Observacao 2026-04-01 (CONCLUIDO): pendencias tecnicas passaram a refletir contagem por obrigatoriedade (x/y), com exibicao da etapa de Finalizacao e alinhamento do fluxo Maestro ao novo titulo em caixa alta no Menu de Vistoria.

Detalhamento:
1. Separar "Fotos obrigatorias" e "Fotos capturadas" no topo da tela.
2. Mostrar totais e progresso por agrupador para leitura rapida.
3. Alinhar semantica visual com a secao "Ver pendencias de vistoria".

### BL-007
Criar seeds de QA pre-definidos (ex.: 1, 3 e 10 vistorias, ativas e concluidas) para acelerar homologacao e testes de apresentacao.

### BL-009
Registrar telemetria minima do fluxo de vistoria (inicio, retomada, conclusao e falhas de integracao) para diagnostico operacional.

### BL-011
Estruturar flavors de distribuicao (prod, internal e dev) para separar pacotes e pipelines quando estiver proximo ao go-live.

Observacao 2026-03-31: item mantido como pre-requisito tecnico para reduzir tamanho real do pacote removendo codigo/dev tools do artefato de producao.

### BL-053
Remover modulo desenvolvedor do pacote final (empacotamento enxuto para producao).

Status: Pendente
Prioridade: Alta
Criterio de pronto: build de producao sem telas/servicos/mock dev vinculados, validado por analise de tamanho de APK/AAB e checklist de regressao.

Observacao 2026-03-31: fluxo Git atualizado para impedir push direto na main e exigir homologacao em `release/*`/`homolog/*` com smoke Maestro USB antes de PR.

### BL-036
Adicionar cache de dependências Flutter/pub ao workflow do GitHub Actions (`android_ci.yml`) usando `actions/cache@v4`, cacheando `.pub-cache` e `.dart_tool` com chave baseada em `pubspec.lock`. Reduz o tempo de execução do job de build (atualmente 8-15 min) eliminando o download repetido de pacotes a cada run.

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.pub-cache
      .dart_tool
    key: ${{ runner.os }}-pub-${{ hashFiles('pubspec.lock') }}
```

### BL-013
Realizar auditoria arquitetural e de qualidade de codigo (Clean Code e SOLID), consolidando debitos tecnicos e plano de refatoracao para execucao quando o backlog funcional estiver menor.

### BL-014
Evoluir a suíte de testes do app com prática TDD contínua, cobrindo regras de negócio críticas, fluxos de fallback/retomada e integrações, evitando avanço funcional sem proteção de testes.

Observacao 2026-03-31 (Em andamento): iniciada migracao da automacao E2E para Maestro para reduzir fragilidade operacional de execucao local e estabilizar fluxo critico de login em dispositivo fisico.

### BL-054
Aplicar UX progressiva no Check-in etapa 1 e etapa 2, exibindo somente a próxima pergunta pendente, mantendo as respostas preenchidas em modo colapsado com resumo na linha e status visual operacional.

Observacao 2026-04-01 (Em andamento): iniciada implementacao de acordeoes por pergunta no check-in para reduzir deslocamento vertical e reforcar percepção de seguranca durante o preenchimento.

### BL-055
Aplicar revisão de taxonomia visual dos menus no fluxo de vistoria, corrigindo o entendimento de níveis de título e padronizando comportamento de collapse inicial por seção.

Observacao 2026-04-01 (Concluído): ajuste aplicado no Menu de Vistoria (Nível 1 em Title Case; divisões da tela em CAIXA ALTA; subtítulos em Title Case) e na Etapa 2 com acordeões independentes iniciando recolhidos, mantendo compatibilidade com configuração dinâmica vinda do sistema web. Cobertura de regressão atualizada para os novos comportamentos de expansão.

### BL-056
Adicionar tela específica de onboarding para coleta/concessão de permissões obrigatórias (Android e iOS), cobrindo tanto o primeiro acesso após instalação quanto usuários que entram por login sem ter passado pelo onboarding (ex.: CLTs cadastrados via módulo web).

Detalhamento:
1. Listar permissões operacionais obrigatórias por plataforma (localização, câmera, microfone e notificações quando aplicável).
2. Bloquear acesso ao fluxo principal até concluir a etapa de permissões mínimas obrigatórias.
3. Implementar verificação de estado no login para redirecionar usuários sem onboarding/permissões concluídas para a nova tela.

### BL-017
Adicionar contract tests entre mobile e backend para validar schemas e evitar quebra silenciosa de integrações críticas.

### BL-018
Aplicar mutation testing em serviços críticos para medir efetividade real da suíte de testes além da cobertura tradicional.

### BL-019
Estabelecer quality gates por módulo para impedir regressão de cobertura em serviços, estados e fluxos principais.

### BL-020
Fortalecer fronteiras arquiteturais com inversão de dependência, reduzindo acoplamento entre UI e infraestrutura.

### BL-021
Padronizar tratamento de erros com tipagem e mensagens consistentes para usuário, suporte e observabilidade.

### BL-022
Implantar correlation id por vistoria para rastrear eventos de início, retomada, exportação, sync e falhas.

### BL-023
Endurecer segurança operacional do app e pipeline com política de secrets, validações e checklist de release seguro.

Observacao 2026-03-30 (Em andamento): workflows de deploy backend/web ajustados para validar `VPS_HOST`, `VPS_USER` e `VPS_SSH_KEY` antes da etapa SSH, com skip explicito quando os segredos nao estiverem configurados. Em revisao final de compatibilidade no parser do GitHub Actions.

### BL-024
Definir performance budgets por fluxo crítico e monitorar regressões de tempo no ciclo de entrega.

### BL-025
Criar governança contínua de dependências, atualizações e vulnerabilidades com critérios de resposta.

### BL-026
Adotar ADRs para registrar decisões arquiteturais e reduzir retrabalho em mudanças estruturais.

### BL-027
Padronizar ciclo de vida de feature flags para evitar acúmulo de código morto e inconsistências de comportamento.

### BL-028
Reforçar Definition of Done com critérios obrigatórios de teste, qualidade técnica, QA e documentação.

Lista básica operacional (obrigatória para todo pacote):
1. Registrar demanda no backlog antes de implementar e manter status atualizado.
2. Ler contexto completo do projeto e limitar mudanças ao escopo solicitado.
3. Não remover código/arquivos fora do requisito explícito.
4. Escrever/atualizar testes para o comportamento alterado (TDD sempre que viável).
5. Executar `flutter analyze` antes de commit/push.
6. Executar `flutter test` antes de commit/push.
7. Validar e incrementar `version` no `pubspec.yaml` antes de merge/push/publicação.
8. Usar mensagem de commit/publicação no padrão acordado: `[versão] - [tipo alteração]: [resumo curto em português]`.
9. Atualizar documentação e observações do backlog no fechamento da entrega.

Observacao 2026-03-31: checklist operacional dedicado publicado em `docs/qa/CHECKLIST_OPERACIONAL_PRE_PUSH.md` para padronizar gate de backlog, testes, analyze, versionamento e padrão de commit antes do push.

### BL-029
Implementar a aba Agenda com visualização em calendário para o usuário consultar os jobs agendados por dia, semana e mês.

Observacao 2026-03-30 (CONCLUIDO): criada aba Agenda com grade mensal, marcacao de dias com jobs e lista de compromissos por dia selecionado.

### BL-030
Evoluir o sininho de mensagens para central de comunicação backend-app, sempre vinculada a job ou proposta, com push notification mesmo com aplicativo fechado.

Observacao 2026-03-30 (CONCLUIDO): central de mensagens implementada com contador de nao lidas no header, marcacao individual/geral de leitura e alimentacao por mocks do painel dev para simulacao de push/backend.

### BL-031
Introduzir autenticação com tela de login, gerenciamento de sessão e proteção de acesso às áreas internas do app.

Observacao 2026-03-30 (PARCIAL): fluxo de autenticacao com estado persistido localmente, logout seguro e roteamento condicional para login/onboarding/aguardando aprovacao/home.
Observacao 2026-03-31 (EM ANDAMENTO): reforcada a testabilidade da tela de login para automacao Maestro com identificadores semanticos estaveis em campos e botao de submit.
Observacao 2026-04-02 (REPLANEJADO): validado que o app ainda nao autentica contra backend real; passam a ser obrigatorios neste item o login backend-first, refresh/revogacao de sessao, trilha de auditoria de acesso, controle de tentativas/lockout e readiness para MFA/FIDO2.
Observacao 2026-04-03 (SEQUENCIAMENTO): BL-031 depende dos cards de backend BOW-100 (Tenant+Membership), BOW-101 (User entity retrofit) e BOW-102 (JWT auth backend). Não iniciar o lado mobile enquanto o backend não tiver JWT funcional com GET /auth/me retornando tenant context correto.

### BL-032
Criar onboarding de novos usuários para perfis CLT e PJ, com coleta de dados cadastrais completos e captura de foto pelo app.

Observacao 2026-03-30 (CONCLUIDO): onboarding em etapas com selecao CLT/PJ, dados pessoais e bloco bancario para PJ, integrado ao estado de autenticacao.

### BL-033
Adicionar tela de aguardando aprovação de cadastro para usuários onboarded que dependem de liberação do backoffice.

Observacao 2026-03-30 (CONCLUIDO): tela dedicada de aguardando aprovacao adicionada, com acao de verificacao de status e simulacao de aprovacao em ambiente de desenvolvimento.

### BL-034
Disponibilizar atualização cadastral no menu de configurações, mantendo consistência com os campos definidos no onboarding.

Observacao 2026-03-30 (CONCLUIDO): configuracoes agora possuem entrada de atualizacao cadastral com persistencia de nome/documento e sincronizacao com dados exibidos no app.

### BL-035
Exibir foto do usuário na Home e permitir atualização por câmera, sem upload da galeria, preparando base para validação facial futura.

Observacao 2026-03-30 (CONCLUIDO): foto de usuario exibida no header da Home, com atualizacao por captura de camera nas configuracoes e persistencia local da referencia da imagem.

### BL-040
Corrigir divergência entre Checkin Etapa 2 e Revisão para o item obrigatório "Entorno", eliminando falso verde no checkin e bloqueio ao usar "Ir para pendência".

Observacao 2026-03-30 (CONCLUIDO): campo obrigatório "Entorno" adicionado ao Checkin Etapa 2 (urbano) e refletido na revisão/pêndencias. Atalhos "Ir para pendência" agora expandem a seção de destino antes do scroll para evitar travamento de fluxo.

### BL-041
Reorganizar o bloco de revisão de fotos para a área inferior com agrupamento "Revisão de Fotos Obrigatórias", contendo dois acordeões independentes: "Fotos Obrigatórias" e "Fotos Capturadas".

Observacao 2026-03-30 (CONCLUIDO): bloco inferior foi remodelado com dois acordeões independentes e status visual OK/NOK para cada grupo.

### BL-042
No card de Novas Propostas, exibir ID do JOB e implementar simulação do aceite por deslize, movendo o item aceito para "Meus Jobs Agendados" no mock.

**Implementado:** `ProposalsSection` convertido para `StatefulWidget` gerenciando lista local. ID exibido como `_InfoTag`. Swipe usa `confirmDismiss → true` + `onDismissed` para animação limpa. Aceite converte `ProposalOffer` em `Job` e adiciona em `AppState.jobs` via Provider. SnackBar de confirmação exibido. Testes: 2/2 ✅

### BL-043
Remover o componente de comandos rápidos por voz da câmera por comprometer a área útil de captura e classificação.

### BL-044
Adicionar controle lateral para ocultar/mostrar menus dinâmicos na câmera, com comportamento padrão inicial expandido.

### BL-045
Transferir a funcionalidade de exportação da vistoria do menu Configurações para o Hub Operacional.

**Implementado:** Bloco "Exportação da vistoria" removido de `settings_screen.dart` (incluindo state fields `_exportFolderController`, `_exportMode`, `_loadingExportSettings`, `_usingExternalExportBase`, métodos `_loadExportSettings`, lógica de export em `_saveSettings` e UI do Divider ao botão). `_ExportSettingsCard` (StatefulWidget com estado próprio) adicionado ao `operational_hub_screen.dart`. 110/110 testes ✅

### BL-046
Corrigir o fluxo de "Sair da conta" em Configurações para funcionar em mock e retornar para a tela inicial de login.

Observacao 2026-03-30 (CONCLUIDO): logout em Configurações limpa sessão mock completa (email/perfil/documentos), retorna para a raiz e exibe Login de forma consistente.

### BL-047
Simplificar onboarding do app para perfil PJ (sem seletor CLT/PJ) e aplicar validações de CNPJ, Agência, Conta e Banco.

Observacao 2026-03-30 (CONCLUIDO): onboarding passou a iniciar direto no fluxo PJ (2 etapas), removendo seletor CLT/PJ e validando CNPJ (14 dígitos + DV), banco, agência e conta.

### BL-048
Adicionar no Hub Operacional uma ação de reset do mock de onboarding para permitir retestes completos do fluxo.

Observacao 2026-03-30 (CONCLUIDO): Hub Operacional recebeu ação "Resetar mock de onboarding", retornando o usuário ao estado de cadastro sem reinstalar o app.

### BL-049
Consolidar o GitHub Project como fonte principal do backlog, garantindo sincronização integral dos itens BL e status com rastreabilidade.

Observacao 2026-04-01 (Em andamento): criado o resumo executivo continuo de implantacao (`docs/05-operations/release-governance/RESUMO_EXECUTIVO_CONTINUO.md`) com snapshot de branches, versao, gates de promocao e estado homolog -> main para reduzir perda de contexto entre sessoes e suportar decisao de merge com rastreabilidade.

Observacao 2026-04-01 (Em andamento): formalizado procedimento de excecao para mantenedor unico na promocao homolog -> main (ajuste temporario de aprovacao minima da branch protegida para 0, merge da PR e restore imediato para 1), com registro obrigatorio de evidencias.

Observacao 2026-04-01 (Despriorizado): configuracao de notificacao por e-mail para aprovacao de PR no celular movida para segundo plano do backlog operacional, pois o fluxo atual usa aprovacao/merge por CLI quando necessario.

Observacao 2026-04-01 (Em acompanhamento): divergencia de notificacao por e-mail entre ambientes - homolog envia e-mail de distribuicao, enquanto distribuicoes originadas de `main`/producao nao confirmaram recebimento nesta sessao.

Observacao 2026-04-02 (CONCLUIDO): ciclo de promocao homolog -> main finalizado por PR com excecao controlada de aprovacao minima e restauracao imediata da protecao (1 aprovacao), workflows chave em verde e equalizacao de ambientes concluida com `origin/main` e `origin/homolog` em 0/0 de divergencia.

### BL-050
Corrigir a área de ação final do onboarding para evitar que o botão "Concluir" fique encoberto pela barra de navegação do Android, garantindo conclusão do fluxo com usabilidade consistente.

Observacao 2026-03-30 (Concluído): botão movido do `body` (Column) para `Scaffold.bottomNavigationBar` com `SafeArea(top: false, minimum: EdgeInsets.fromLTRB(20, 8, 20, 20))` e altura fixa de 54dp via `SizedBox`. O `Scaffold` gerencia corretamente o inset do rodapé do Android independente de modo de gestos ou botões de navegação. 3 testes passando.

### BL-051
Unificar a persistência e o consumo das regras dinâmicas de obrigatoriedade entre Checkin Etapa 1/2, Câmera, Revisão e Menu de Vistoria, preparando o app para receber parâmetros normativos do módulo web (incluindo mínimo/máximo de fotos).

Observacao 2026-03-30 (Em andamento): refatoração big-bang aplicada no fluxo mobile para consumir `step2Config` dinâmica de forma consistente em Revisão, Câmera em lote e Menu de Vistoria; export final da revisão passou a usar a lista de capturas atualizada em memória (incluindo capturas adicionadas na própria revisão); contrato dinâmico da etapa 2 recebeu suporte a `minFotos` e `maxFotos`, com validação de limite máximo na Etapa 2 e sinalização operacional na Revisão.

Observacao 2026-03-30 (Em andamento): corrigida a persistencia do snapshot dinamico da Etapa 2 no draft de recuperacao para evitar perda de `step2Config` ao avancar/retomar o fluxo. Menu de Vistoria, Revisao, Camera e auditoria de fallback passaram a resolver a mesma configuracao persistida por um unico caminho no servico dinamico, reduzindo divergencia de indicador e obrigatorios entre telas.

Observacao 2026-03-30 (Concluido): reforcado o caminho de persistencia do indicador em retomadas com payload parcial/corrompido da Etapa 2, substituindo parse direto por restauracao resiliente (`restoreStep2Model`) em Home/Revisao e adicionando regressao para manter sinalizacao de obrigatorios pendentes sem quebra de tela.

### BL-052
Unificar no Hub Operacional um pacote único de parametrização para o modo desenvolvedor, deixando explícito o que pertence ao Check-in e o que pertence à Câmera, com organização por níveis configuráveis.

Observacao 2026-03-30 (Em andamento): o documento JSON local do modo desenvolvedor passou a servir como fonte unificada para `step1`, `step2` e `camera`, eliminando a separação entre contrato de check-in e pacote isolado da câmera. A câmera agora pode consumir também níveis dinâmicos de `material` e `estado` por tipo de imóvel no mesmo documento salvo pelo HUB operacional. Próximo passo: evoluir o editor visual do HUB para manipular níveis sem edição manual de JSON.

Observacao 2026-03-30 (Em andamento): o app passou a ter tambem unificacao no codigo de leitura do documento, com um pacote unico de configuracao compartilhado entre Check-in Etapa 1, Etapa 2 e Camera, reduzindo duplicacao de parser e abrindo caminho para evolucao por niveis e por subtipo sem contratos paralelos.

Observacao 2026-03-30 (Em andamento): o pacote unificado passou a suportar niveis explicitos com resolucao por subtipo em `step1` e `camera` (`levels` e `levelsBySubtipo`), incluindo dependencia entre niveis (`dependsOn`) e fallback para niveis base quando nao houver override do subtipo.

Observacao 2026-03-30 (Em andamento): Check-in Etapa 1 passou a renderizar niveis dinamicos em runtime a partir do pacote unificado (com selecao por chips, dependencia entre niveis e persistencia em `step1.niveis`), mantendo compatibilidade com `porOndeComecar` para o fluxo atual de abertura da camera.

Observacao 2026-03-30 (Em andamento): definido checklist de validacao go/no-go para implantacao do pacote dinamico, cobrindo estrutura de niveis, dominio da informacao, regra normativa da Etapa 2, integracao entre telas e mock unificado do Hub Operacional (`docs/qa/CHECKLIST_GO_NO_GO_PACOTE_DINAMICO.md`).

Observacao 2026-03-30 (Em andamento): cobertura de regressao da BL-052 foi ampliada no servico de menus para camera com cenarios de fallback por subtipo nao configurado, fallback padrao sem niveis e saneamento de IDs invalidos de niveis, reduzindo risco de divergencia de ordem/visibilidade em runtime.

Observacao 2026-03-30 (Em andamento): adicionados testes de widget da camera para validar ordem e visibilidade dinamica dos seletores por nivel/subtipo (`test/screens/overlay_camera_screen_test.dart`), com modo deterministico de dados de teste na tela para evitar dependencia de inicializacao de hardware/servicos no ambiente de teste.

---

## Lista de evolução de testes (débito técnico)

1. BT-TEST-001 [Em progresso]: mapear cobertura atual por módulo (state, services, screens) e identificar lacunas.
2. BT-TEST-002 [Concluído]: criar testes de unidade para `checkin_dynamic_config_service.dart` (parse, fallback, cache).
3. BT-TEST-003 [Concluído]: criar testes de unidade para `inspection_sync_service.dart` e `inspection_sync_queue_service.dart` (sucesso, falha, retry).
4. BT-TEST-004: criar testes da auditoria de fallback (`inspection_fallback_audit_service.dart`) para cenários saudável, alerta e falha.
5. BT-TEST-005: criar testes de widget para aba Vistorias e detalhe read-only (`completed_inspections_screen.dart` e `completed_inspection_detail_screen.dart`).
6. BT-TEST-006: adicionar regra de PR/CI para exigir alteração de teste quando houver alteração funcional.
7. BT-TEST-007: registrar baseline de cobertura e meta incremental por sprint.

---

## 🚀 Itens Críticos para Começar Agora

### BL-012: Menus de Checkin Dinâmicos (Prioridade #1)
**Por que agora?** Validação NBR é bloqueadora e está hardcoded. Sem dinâmica, cada ajuste de obrigatoriedade precisa deploy.

**Dependências:** 
- Contrato de API definido

**Exemplo de impacto:** Se o cliente quiser remover "Micro Detalhes" como obrigatório, hoje é deploy. Amanhã será 1 API call.

---

### BL-001: Integração API Real (Prioridade #2)
**Por que após BL-012?** Precisa saber qual é a estrutura de "checkinSessions" (BL-012) que será enviada no JSON final.

**Dependências:**
- BL-012 estar estável (estrutura de sessões conhecida)
- Endpoint da API web definido

**Fluxo:** Job finalizado → Valida BL-012 (obrigatórios) → Envia JSON via BL-001

---

## Observacao sobre Flavors (BL-011)
No momento, a estrategia aprovada e manter build unico para reduzir complexidade enquanto o app ainda nao esta em producao.

Quando revisitar BL-011:
1. A ate 2 sprints do go-live.
2. Quando houver necessidade real de distribuicao paralela (cliente final x equipe interna).
3. Quando requisitos de seguranca/compliance exigirem separacao formal de pacote.

---

## Detalhamento BL-012: Menus de Checkin Dinamicos

### Contexto
Atualmente, os menus de checkin etapa 1 e 2 estão hardcoded em `lib/config/checkin_step2_config.dart`. Cada sessão de captura (ex: fachada, ambiente, elemento inicial) possui:
- Título
- Ícone
- Requisitos de captura (Macro Local, Ambiente, Elemento)
- Flag `obrigatorio` (booleano)

Estes requisitos são baseados em padrões NBR e validados durante o checkout/revisão final de uma vistoria.

### Requisito
Permitir configuração dinâmica via backend para:
1. Adicionar/remover sessões de captura
2. Alterar obrigatoriedade (obrigatorio vs desejável) sem deploy
3. Adaptar para diferentes tipos de imóvel ou contextos

### Estrutura Proposta
```json
{
  "checkinSessions": [
    {
      "id": "fachada",
      "titulo": "Fachada",
      "icon": "building",
      "obrigatorio": true,
      "cameraMacroLocal": true,
      "cameraAmbiente": true,
      "cameraElementoInicial": true,
      "descricao": "Captura obrigatória NBR 16500"
    },
    {
      "id": "ambiente",
      "titulo": "Ambiente Interno",
      "icon": "door",
      "obrigatorio": false,
      "cameraMacroLocal": true,
      "cameraAmbiente": true,
      "cameraElementoInicial": false,
      "descricao": "Sessão desejável para contexto"
    }
  ]
}
```

### Validação na Revisão
O campo `obrigatorio` é crítico pois bloqueia finalização se não atendido (CheckinReviewScreen valida).

---

## Dependencias Tecnicas
1. Definicao do contrato da API web para recebimento do JSON de vistoria.
2. Definicao de politica de autenticacao para integracao mobile -> web.
3. Decisao sobre destino dos arquivos locais (apenas cache local ou sincronizacao obrigatoria).
4. **Define contrato de API para checkin sessions configurável (BL-012)**.
5. **Cache local de sessões com fallback para config hardcoded se offline (BL-012)**.
6. **Definir política de destino de exportacao JSON (BL-016) sem comprometer sync offline e limpeza (BL-005)**.
7. **Definir contrato de agenda de jobs por usuário (BL-029) com data/hora/status e paginação**.
8. **Definir contrato de mensagens vinculadas a job/proposta e eventos de push (BL-030)**.
9. **Definir provedor de push notification e estratégia de token/device registration (BL-030)**.
10. **Definir política de autenticação (login, refresh token, expiração e logout) para mobile (BL-031)**.
11. **Definir fluxos e validações de onboarding CLT/PJ no backend e no app (BL-032/BL-033/BL-034)**.
12. **Definir diretriz de captura de foto via câmera e regras anti-galeria para onboarding/perfil (BL-032/BL-035)**.

---

## 📝 Notas para Colaboradores

Ao pegar um item para implementar:
1. ✅ Verifique se as dependências já foram satisfeitas
2. ✅ Atualize o status de `Pendente` para `Em Progresso`
3. ✅ Crie branch com padrão: `feature/BL-XXX-descricao-curto`
4. ✅ Commit com prefixo: `feat/BL-XXX: descrição`
5. ✅ Aplicar TDD no ciclo: escrever/ajustar teste, implementar, validar `flutter analyze` e `flutter test`
6. ✅ Atualize este arquivo ao terminar (marque como `Concluído`)
