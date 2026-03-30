# Backlog de Funcionalidades Nao Implementadas

Atualizado em: 2026-03-30

## Objetivo
Registrar funcionalidades pendentes para evolucao do AppMobile, com foco em priorizacao de produto e previsibilidade tecnica.

## Backlog complementar de backoffice web
Para planejamento do sistema web de backoffice (APIs, painéis e configurações para suportar o app mobile), consultar `docs/BACKLOG_BACKOFFICE_WEB.md`.

## Backlog complementar de integração web-mobile
Para segurança, contratos e comunicação bidirecional entre app e backoffice, consultar `docs/BACKLOG_INTEGRACAO_WEB_MOBILE.md`.

## Plano de execucao (proximos 30 dias)
Para transformar backlog em entrega com marcos semanais, ownership e criterios de aceite, consultar `docs/PLANO_EXECUCAO_30_DIAS_WEB_MOBILE.md`.

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
Step 8️⃣ (FUNCIONAL PRÓXIMO CICLO) → BL-029, BL-030, BL-031, BL-032, BL-033, BL-034, BL-035
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
| 7️⃣ | BL-006 | Modo desenvolvedor: editor completo de mocks para menus dinamicos da camera | Pendente | 🟠 Alta | Painel dev permite editar cenarios e menus dinamicos sem alterar codigo |
| 8️⃣ | BL-010 | Endurecimento de bloqueio de recursos dev em release final | Pendente | 🟠 Alta | Recursos dev nao aparecem para usuario final sem desbloqueio autorizado |
| 9️⃣ | BL-004 | Exibir protocolo/ID externo no card e no historico de vistorias | Pendente | 🟡 Media | Card mostra ID do job e protocolo externo quando existir |
| 🔟 | BL-005 | Regras de retencao e limpeza de arquivos JSON exportados | Pendente | 🟡 Media | Politica configuravel (ex.: manter ultimos N dias) com limpeza segura |
| 1️⃣1️⃣ | BL-016 | Diretorio de exportacao JSON configuravel para conferencia operacional | Concluido | 🟡 Media | Export permite alternar destino (interno/externo) sem perder rastreabilidade e fluxo de sync |
| 1️⃣2️⃣ | BL-037 | Matriz de pendencia tecnica com linguagem operacional e acao guiada | Em andamento | 🟠 Alta | Matriz apresenta texto simples e link/acao direta para levar o usuario ao ponto exato da pendencia no fluxo |
| 1️⃣3️⃣ | BL-038 | Preservar classificacao revisada ao retornar da camera para revisao | Em andamento | 🟠 Alta | Fotos ja classificadas nao regressam para status laranja ao adicionar nova captura e voltar para revisao |
| 1️⃣4️⃣ | BL-039 | Agrupar revisao no topo por fotos obrigatorias e fotos capturadas | Em andamento | 🟡 Media | Topo da revisao exibe agrupadores claros de obrigatorias e capturadas, alinhado ao bloco de pendencias |
| 1️⃣5️⃣ | BL-007 | Seed de cenarios de QA por perfil (1, 3, 10 vistorias; ativas/concluidas) | Pendente | 🟡 Media | Um toque aplica cenarios pre-definidos para homologacao |
| 1️⃣6️⃣ | BL-009 | Telemetria de fluxo (inicio, retomada, conclusao, falhas de integracao) | Pendente | 🟡 Media | Eventos minimos registrados para diagnostico operacional |
| ⏸️  | BL-011 | Flavors de distribuicao (prod, internal, dev) | Adiado | 🟡 Media | Entrypoints e pipeline separados para builds internos e producao |
| ⚡ | BL-036 | Cache de Flutter/pub no pipeline CI (débito técnico) | Pendente | 🔵 Baixa (pos-funcional) | Pipeline reduz tempo de build cacheando `.pub-cache` e `.dart_tool` com chave baseada em `pubspec.lock` |
| 🔧 | BL-013 | Auditoria de Clean Code e SOLID (débito técnico) | Planejado | 🔵 Baixa (pos-funcional) | Relatorio técnico com achados, plano de refatoracao e aplicacao incremental por modulo sem regressao funcional |
| 🧪 | BL-014 | Evolução da suíte de testes com prática TDD (débito técnico) | Planejado | 🔵 Baixa (pos-funcional) | Cobertura de testes ampliada por fluxo crítico, com testes criados/atualizados a cada entrega funcional |
| 🧱 | BL-017 | Contract testing de APIs mobile-backend | Planejado | 🟠 Alta | Contratos de request/response validados em CI para endpoints críticos (config dinâmica e sync) |
| 🧬 | BL-018 | Mutation testing para regras críticas | Planejado | 🟡 Media | Mutation score mínimo definido e monitorado para serviços críticos |
| 📈 | BL-019 | Quality gate de cobertura por módulo | Planejado | 🟠 Alta | CI bloqueia merge quando cobertura mínima por módulo regredir |
| 🧭 | BL-020 | Fronteiras de arquitetura e inversão de dependência | Planejado | 🟠 Alta | Camadas desacopladas com interfaces explícitas entre domínio, aplicação e infraestrutura |
| ⚠️ | BL-021 | Estratégia padronizada de tratamento de erros | Planejado | 🟠 Alta | Erros tipados, mensagens consistentes e ausência de catch silencioso nos fluxos críticos |
| 🔗 | BL-022 | Observabilidade com correlation id por vistoria | Planejado | 🟡 Media | Eventos de ponta a ponta rastreáveis por job/correlation id |
| 🔐 | BL-023 | Hardening de segurança e gestão de secrets | Planejado | 🟠 Alta | Segredos fora do código, validação de configuração e checklist de segurança em release |
| ⚡ | BL-024 | Performance budgets em fluxos críticos | Planejado | 🟡 Media | Metas de tempo por etapa monitoradas com alerta de regressão |
| 📦 | BL-025 | Governança de dependências e vulnerabilidades | Planejado | 🟡 Media | Rotina de atualização com scanner e política de correção de CVEs |
| 🧾 | BL-026 | ADRs para decisões arquiteturais | Planejado | 🟡 Media | Decisões técnicas relevantes registradas com contexto e trade-offs |
| 🚩 | BL-027 | Ciclo de vida de feature flags | Planejado | 🟡 Media | Processo de criação, auditoria e remoção de flags sem acúmulo técnico |
| ✅ | BL-028 | Definition of Done reforçada | Planejado | 🟠 Alta | Entrega só conclui com testes, observabilidade mínima, documentação e checklist QA |
| 🗓️ | BL-029 | Agenda em calendário com jobs agendados do usuário | Pendente | 🟠 Alta | Aba Agenda exibe calendário mensal/semanal com jobs por data e navegação para detalhes |
| 🔔 | BL-030 | Sininho de mensagens com central backend-app e push | Pendente | 🔴 Crítica | Mensagens vinculadas a job/proposta aparecem na central e geram notificação no celular mesmo com app fechado |
| 🔐 | BL-031 | Tela de login e autenticação do App | Pendente | 🔴 Crítica | Usuário autentica com backend, sessão persistida com expiração/renovação e logout seguro |
| 🧾 | BL-032 | Onboarding de usuários CLT e PJ no app | Pendente | 🔴 Crítica | Fluxo coleta dados obrigatórios por tipo (CLT/PJ), incluindo dados pessoais e bancários para PJ |
| ⏳ | BL-033 | Estado aguardando aprovação do cadastro (backoffice) | Pendente | 🟠 Alta | Após onboarding, usuário sem aprovação visualiza tela estática de aguardando aprovação com atualização de status |
| ⚙️ | BL-034 | Configurações para atualização de dados cadastrais | Pendente | 🟠 Alta | Menu configurações permite editar os mesmos dados do onboarding com validação e envio ao backend |
| 🧑 | BL-035 | Foto do usuário no topo com captura e atualização | Pendente | 🟠 Alta | Foto do onboarding aparece no topo da Home e pode ser atualizada por captura de câmera (sem galeria) |

---

## Descricoes dos Itens

### BL-012
Tornar os menus de checkin etapa 1 e etapa 2 dinamicos via backend, permitindo adicionar/remover sessoes e definir obrigatoriedade (NBR) sem novo deploy do app.

Observacao 2026-03-30 (Em andamento): adicionado fallback de configuracao dinamica por modo desenvolvedor, com documento JSON local configuravel no painel de dados mock. Fluxo de leitura agora prioriza mock local quando habilitado, depois API, depois cache, e por ultimo fallback hardcoded.

### BL-001
Enviar o JSON final da vistoria para a API web oficial com autenticacao, registro de sucesso/erro e rastreabilidade por job.

Observacao 2026-03-30: payloads de origem financeira para criacao de processo devem ser tratados e normalizados no backoffice/integracao (docs/BACKLOG_BACKOFFICE_WEB.md e docs/BACKLOG_INTEGRACAO_WEB_MOBILE.md). O app mobile consome apenas campos operacionais expostos pelas APIs internas (jobs/config/sync), evitando acoplamento ao contrato externo bruto.

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

### BL-010
Fortalecer bloqueios de recursos de desenvolvimento em build de release para impedir exposicao acidental de funcionalidades internas ao usuario final.

### BL-004
Exibir identificadores operacionais (ID do job e protocolo externo) no card da home e no historico, facilitando rastreio e suporte.

### BL-005
Definir politica de retencao e limpeza dos JSONs exportados, com regras seguras para manter historico util sem crescimento indefinido de armazenamento.

### BL-016
Permitir configuracao do diretorio de exportacao do JSON final (interno e/ou externo para conferencia operacional), mantendo consistencia com fila offline e rastreabilidade por job.

Observacao 2026-03-30 (CONCLUIDO): adicionada configuracao em `Configuracoes` para destino da exportacao (interno/externo) e subdiretorio customizavel. A resolucao efetiva aplica fallback automatico para interno quando externo nao estiver disponivel, preservando o fluxo de sincronizacao e a rastreabilidade por job.

Observacao 2026-03-30: apos revisao UX do Menu de Vistoria, os itens BL-037, BL-038 e BL-039 foram priorizados para entrar na sequencia do BL-016.

### BL-037
Evoluir a matriz de pendencia tecnica para linguagem comum ao usuario operacional, com mensagens objetivas e acao guiada por pendencia.

Observacao 2026-03-30 (Em andamento): matriz atualizada com linguagem mais operacional e atalho "Ir para pendencia" para navegação direta dentro da tela de revisão.

Detalhamento:
1. Reescrever descricoes tecnicas em texto orientado a tarefa.
2. Adicionar link/botao "ir para pendencia" para levar ao ponto correto do fluxo (check-in, camera ou revisao).
3. Exibir contexto minimo: o que falta, onde resolver e como confirmar conclusao.

### BL-038
Garantir preservacao da classificacao ja revisada quando o usuario retorna da camera com novas fotos.

Observacao 2026-03-30 (Em andamento): revisao passou a persistir e reidratar capturas revisadas no draft de recovery, mantendo classificacoes existentes ao voltar da camera para a revisao.

Detalhamento:
1. Reconciliar capturas novas sem resetar classificacao existente.
2. Manter status verde dos itens ja classificados quando nao houver alteracao de conteudo/classificacao.
3. Cobrir com testes de navegacao e regressao do fluxo revisao -> camera -> revisao.

### BL-039
Reorganizar o topo da revisao de fotos com agrupadores equivalentes ao bloco de pendencias.

Observacao 2026-03-30 (Em andamento): topo da revisão atualizado com agrupadores de "Fotos obrigatorias" e "Fotos capturadas", com contadores de progresso por grupo.

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

### BL-029
Implementar a aba Agenda com visualização em calendário para o usuário consultar os jobs agendados por dia, semana e mês.

### BL-030
Evoluir o sininho de mensagens para central de comunicação backend-app, sempre vinculada a job ou proposta, com push notification mesmo com aplicativo fechado.

### BL-031
Introduzir autenticação com tela de login, gerenciamento de sessão e proteção de acesso às áreas internas do app.

### BL-032
Criar onboarding de novos usuários para perfis CLT e PJ, com coleta de dados cadastrais completos e captura de foto pelo app.

### BL-033
Adicionar tela de aguardando aprovação de cadastro para usuários onboarded que dependem de liberação do backoffice.

### BL-034
Disponibilizar atualização cadastral no menu de configurações, mantendo consistência com os campos definidos no onboarding.

### BL-035
Exibir foto do usuário na Home e permitir atualização por câmera, sem upload da galeria, preparando base para validação facial futura.

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
