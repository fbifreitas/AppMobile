# GitHub Projects - Gestao Visual de Backlog (AppMobile)

Atualizado em: 2026-03-30

## Objetivo
Organizar visualmente os 3 backlogs com rastreabilidade unica:
1. Mobile (BL-xxx)
2. Integracao Web-Mobile (INT-xxx)
3. Backoffice Web (BOW-xxx)

## Estrategia recomendada
Usar 1 projeto unico no GitHub Projects para consolidar priorizacao e dependencia cruzada.

Nome sugerido do projeto:
AppMobile - Backlog Unificado (Mobile + Integracao + Web)

## Estrutura do Project
Template: Board

Colunas (Status):
1. Triagem
2. Pronto para Desenvolvimento
3. Em desenvolvimento
4. Em validacao
5. Pronto para release
6. Concluido
7. Bloqueado

## Campos customizados obrigatorios
Criar os seguintes campos no Project:

1. Backlog ID (Text)
- Ex: BL-016, INT-021, BOW-049

2. Dominio (Single select)
- Mobile
- Integracao
- Web

3. Tipo de Demanda (Single select)
- Fix
- Debito Tecnico
- Evolutivo

4. Prioridade (Single select)
- Critica
- Alta
- Media
- Baixa

5. Risco de implantacao (Single select)
- Baixo
- Moderado
- Alto

6. Pacote alvo (Text)
- Ex: Pacote BL-016, Pacote Integracao Financeira v1

7. Dependencias (Text)
- Ex: BL-012 depende de INT-002

8. Criterio de pronto (Text)
- Copiar do backlog oficial

9. Release alvo (Text)
- Ex: v1.2.10

10. Owner (People) - opcional na fase inicial

11. Data alvo (Date) - opcional na fase inicial
12. Situacao de Execucao (Single select)
- Livre
- Impedido por dependencia
- Impedido externo

13. Semaforo (Single select)
- Em andamento
- Impedido
- Done

14. Termometro Backlog (Single select)
- Alta (Vermelho)
- Media (Laranja)
- Baixa (Azul)

## Labels recomendadas no repositorio
Criar labels no repositorio para facilitar filtros:

1. domain:mobile
2. domain:integracao
3. domain:web
4. prio:critica
5. prio:alta
6. prio:media
7. risco:baixo
8. risco:moderado
9. risco:alto
10. backlog:bl
11. backlog:int
12. backlog:bow

## Views recomendadas
Criar as views abaixo no Project:

1. Visao Executiva
- Agrupar por Prioridade
- Filtrar status != Concluido
- Ordenar por Prioridade e Release alvo

2. Pacote Atual
- Filtro: Pacote alvo = pacote em execucao
- Layout Board por Status

3. Mobile
- Filtro: Dominio = Mobile
- Agrupar por Prioridade

4. Integracao
- Filtro: Dominio = Integracao
- Agrupar por Prioridade

5. Web Backoffice
- Filtro: Dominio = Web
- Agrupar por Prioridade

6. Bloqueados
- Filtro: Status = Bloqueado
- Mostrar Dependencias e Owner

7. Prontos para release
- Filtro: Status = Pronto para release
- Ordenar por Risco de implantacao (Baixo > Moderado > Alto)

## Automacoes recomendadas no Projects
1. Ao criar item: Status = Triagem
2. Ao associar PR e abrir review: Status = Em validacao
3. Ao mergear PR: Status = Pronto para release
4. Ao publicar tag de release: Status = Concluido
5. Se label bloqueador for adicionada: Status = Bloqueado

## Automacao visual implementada
Existe um workflow no repositório para recalcular o estado visual do board:
1. `.github/workflows/project_board_visual_sync.yml`
2. Execucao manual via `workflow_dispatch`
3. Execucao agendada a cada 30 minutos

Regras aplicadas:
1. `Semaforo = Done` quando `Status = Done`
2. `Semaforo = Impedido` quando `Situacao de Execucao` comeca com `Impedido`
3. `Semaforo = Em andamento` quando `Status = In Progress` e item nao esta impedido
4. `Termometro Backlog = Alta (Vermelho)` para backlog com prioridade `Critica` ou `Alta`
5. `Termometro Backlog = Media (Laranja)` para backlog com prioridade `Media`
6. `Termometro Backlog = Baixa (Azul)` para backlog com prioridade `Baixa`

Script base:
1. `infra/scripts/sync_project_visuals.ps1`

## Mapeamento inicial sugerido
Registrar imediatamente os itens atuais:

1. BL-012 (Em andamento)
2. BL-001 (Em andamento)
3. BL-016 (Concluido)
4. BL-037 (Em andamento)
5. BL-038 (Em andamento)
6. BL-039 (Em andamento)
7. INT-021, INT-022, INT-023, INT-024 (Triagem)
8. BOW-049, BOW-050, BOW-051, BOW-052 (Triagem)

## Regra de governanca
1. Todo item de backlog precisa ter card no Projects.
2. Todo card precisa ter Backlog ID e Dominio.
3. Todo card precisa ter Tipo de Demanda classificado como Fix, Debito Tecnico ou Evolutivo.
4. Nenhum card entra em desenvolvimento sem Criterio de pronto preenchido.
5. Nenhum card vai para Concluido sem release tag associada.

## Fluxo operacional minimo por entrega
1. Definir pacote alvo
2. Selecionar cards com risco moderado
3. Executar desenvolvimento + testes
4. Mover para Pronto para release
5. Publicar versao/tag
6. Mover cards para Concluido
