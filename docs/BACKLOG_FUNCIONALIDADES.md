# Backlog de Funcionalidades Nao Implementadas

Atualizado em: 2026-03-29

## Objetivo
Registrar funcionalidades pendentes para evolucao do AppMobile, com foco em priorizacao de produto e previsibilidade tecnica.

## 🎯 Roadmap de Priorização

A sequência de implementação foi definida considerando:
- **Dependências técnicas**: itens que desbloqueiam outros
- **Crítica para NBR**: conformidade regulatória não é negociável
- **Impacto no fluxo**: validação em checkin/revisão

**Fluxo de implementação recomendado:**

```
Step 1️⃣ (CRÍTICA) → BL-012 + BL-001
    ↓
Step 2️⃣ (ALTA) → BL-002 + BL-008
    ↓
Step 3️⃣ (ALTA) → BL-003 + BL-006
    ↓
Step 4️⃣ (ALTA) → BL-010
    ↓
Step 5️⃣ (MÉDIA) → BL-004, BL-005, BL-007, BL-009
  ↓
Step 6️⃣ (DÉBITO TÉCNICO) → BL-013
```

---

## Itens Priorizados

| Seq | ID | Funcionalidade | Status | Prioridade | Criterio de pronto |
|---|---|---|---|---|---|
| **1️⃣ AGORA** | **BL-012** | **Menus de checkin etapa 1 e 2 dinamicos via backend (sessoes NBR)** | Pendente | 🔴 **CRÍTICA** | Sessoes de captura (fachada, ambiente, elemento) com requisitos obrigatorio/desejavel configuravel via API, sem hardcoding |
| **2️⃣ AGORA** | **BL-001** | **Integracao de envio do JSON final da vistoria para sistema web (API real)** | Pendente | 🔴 **CRÍTICA** | JSON de encerramento enviado para endpoint autenticado com retentativa e log de sucesso/erro |
| 3️⃣ | BL-002 | Fila offline para exportacao/sincronizacao de vistorias finalizadas | Concluido | 🟠 Alta | Se sem internet, arquivo entra em fila local e sincroniza automaticamente ao reconectar |
| 4️⃣ | BL-008 | Auditoria de fallback por etapa (checkin, step2, camera, review) | Concluido | 🟠 Alta | Relatorio interno mostra consistencia de payload e retomada por etapa |
| 5️⃣ | BL-003 | Tela de detalhes da vistoria concluida (somente leitura) | Pendente | 🟠 Alta | Aba Vistorias permite abrir detalhes completos sem edicao |
| 6️⃣ | BL-006 | Modo desenvolvedor: editor completo de mocks para menus dinamicos da camera | Pendente | 🟠 Alta | Painel dev permite editar cenarios e menus dinamicos sem alterar codigo |
| 7️⃣ | BL-010 | Endurecimento de bloqueio de recursos dev em release final | Pendente | 🟠 Alta | Recursos dev nao aparecem para usuario final sem desbloqueio autorizado |
| 8️⃣ | BL-004 | Exibir protocolo/ID externo no card e no historico de vistorias | Pendente | 🟡 Media | Card mostra ID do job e protocolo externo quando existir |
| 9️⃣ | BL-005 | Regras de retencao e limpeza de arquivos JSON exportados | Pendente | 🟡 Media | Politica configuravel (ex.: manter ultimos N dias) com limpeza segura |
| 🔟 | BL-007 | Seed de cenarios de QA por perfil (1, 3, 10 vistorias; ativas/concluidas) | Pendente | 🟡 Media | Um toque aplica cenarios pre-definidos para homologacao |
| 1️⃣1️⃣ | BL-009 | Telemetria de fluxo (inicio, retomada, conclusao, falhas de integracao) | Pendente | 🟡 Media | Eventos minimos registrados para diagnostico operacional |
| ⏸️  | BL-011 | Flavors de distribuicao (prod, internal, dev) | Adiado | 🟡 Media | Entrypoints e pipeline separados para builds internos e producao |
| 🔧 | BL-013 | Auditoria de Clean Code e SOLID (débito técnico) | Planejado | 🔵 Baixa (pos-funcional) | Relatorio técnico com achados, plano de refatoracao e aplicacao incremental por modulo sem regressao funcional |

---

## Descricoes dos Itens

### BL-012
Tornar os menus de checkin etapa 1 e etapa 2 dinamicos via backend, permitindo adicionar/remover sessoes e definir obrigatoriedade (NBR) sem novo deploy do app.

### BL-001
Enviar o JSON final da vistoria para a API web oficial com autenticacao, registro de sucesso/erro e rastreabilidade por job.

### BL-002
Criar fila offline para armazenar vistorias finalizadas quando nao houver conectividade e sincronizar automaticamente quando a rede retornar.

### BL-008
Implementar auditoria de fallback por etapa (checkin, step2, camera e review) para identificar inconsistencias de payload e problemas de retomada.

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

### BL-007
Criar seeds de QA pre-definidos (ex.: 1, 3 e 10 vistorias, ativas e concluidas) para acelerar homologacao e testes de apresentacao.

### BL-009
Registrar telemetria minima do fluxo de vistoria (inicio, retomada, conclusao e falhas de integracao) para diagnostico operacional.

### BL-011
Estruturar flavors de distribuicao (prod, internal e dev) para separar pacotes e pipelines quando estiver proximo ao go-live.

### BL-013
Realizar auditoria arquitetural e de qualidade de codigo (Clean Code e SOLID), consolidando debitos tecnicos e plano de refatoracao para execucao quando o backlog funcional estiver menor.

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

---

## 📝 Notas para Colaboradores

Ao pegar um item para implementar:
1. ✅ Verifique se as dependências já foram satisfeitas
2. ✅ Atualize o status de `Pendente` para `Em Progresso`
3. ✅ Crie branch com padrão: `feature/BL-XXX-descricao-curto`
4. ✅ Commit com prefixo: `feat/BL-XXX: descrição`
5. ✅ Atualize este arquivo ao terminar (marque como `Concluído`)
