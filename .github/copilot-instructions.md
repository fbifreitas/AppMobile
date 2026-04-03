# Instrucoes Operacionais do Repositorio (AppMobile)

Estas instrucoes sao obrigatorias para qualquer agente Copilot atuando neste repositorio.

## 1) Ordem de leitura inicial (bootstrap)
1. Ler `docs/AGENTE_LICOES_APRENDIDAS.md`.
2. Ler `docs/web/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md`.
3. Ler a secao de contexto de negocio em `docs/web/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md`.
4. Ler `docs/BACKLOG_FUNCIONALIDADES.md`.
5. Ler `docs/BACKLOG_BACKOFFICE_WEB.md`.
6. Ler `docs/BACKLOG_INTEGRACAO_WEB_MOBILE.md`.

### Documentacao mestre (fonte canonica de negocio e arquitetura)
Estes documentos sao a fonte de verdade para decisoes de produto, arquitetura e engenharia.
Consultar ANTES de qualquer decisao de design, RBAC, integracao ou modelagem de dominio:
- Visao estrategica e estagios: `docs/01-executive/05_VISAO_ESTRATEGICA_E_ESTATIOS.md`
- Blueprint de arquitetura: `docs/03-architecture/01_BLUEPRINT_ARQUITETURA.md`
- Modelo canonico e dominios: `docs/03-architecture/02_MODELO_CANONICO_E_DOMINIOS.md`
- Identity, access e IAM: `docs/03-architecture/05_IDENTITY_ACCESS_E_USER_MANAGEMENT.md`
- ADRs iniciais: `docs/03-architecture/07_ADRS_INICIAIS.md`
- Personas e papeis: `docs/02-product/01_PERSONAS_E_PAPEIS.md`
- PRD da plataforma: `docs/02-product/03_PRD_PLATAFORMA.md`
- Roadmap e epicos: `docs/02-product/04_ROADMAP_EPICOS.md`
- Padroes de desenvolvimento: `docs/04-engineering/01_PADROES_DE_DESENVOLVIMENTO.md`
- Plano de implementacao 90 dias: `docs/05-operations/02_PLANO_IMPLEMENTACAO_90_DIAS.md`
- Casos de uso criticos: `docs/06-analysis-and-design/02_ESPECIFICACAO_CASOS_DE_USO_CRITICOS.md`
- Regras de negocio criticas: `docs/06-analysis-and-design/08_REGRAS_DE_NEGOCIO_CRITICAS.md`
- Indice geral: `docs/00-overview/00_INDEX_GERAL.md`

## 2) Governanca obrigatoria
- Ler contexto completo antes de alterar codigo.
- Usar `docs/BACKLOG_FUNCIONALIDADES.md` como fonte oficial de backlog macro.
- Atualizar backlog e documentacao de rastreabilidade em toda demanda.
- Registrar checkpoint operacional continuo: a cada marco importante, atualizar documentacao com "o que foi feito", "estado atual" e "proximo passo" para facilitar retomada apos reinicio.
- Nao remover codigo/arquivo fora do escopo solicitado.
- Antes de commit/push/publicacao, checar incremento de versao em `pubspec.yaml` (quando aplicavel).
- Executar testes/validacoes apos mudancas no escopo:
  - Flutter: `flutter analyze` e `flutter test`.
  - Web: `npm run lint`, `npm test`, `npm run build`.
  - Backend: `mvn -B -DskipTests package`.
- Se nao for possivel executar teste, registrar justificativa explicita.
- Padrao de commit/publicacao: `[versao] - [tipo]: [resumo curto em portugues]`.

## 3) Seguranca de segredos
- Nao persistir segredos em arquivos versionados (`infra/.env`, `infra.env`, codigo).
- Usar variaveis de ambiente de sessao, cofre (`Get-Secret`) ou prompt seguro.
- Para stack local, priorizar `infra/scripts/start_local_stack.ps1`.

## 4) Regra de release
- Apos envio para homologacao, aguardar aprovacao explicita do usuario na mesma sessao antes de promover para `main`.
- Monitorar CI/CD e considerar ciclo encerrado apenas com confirmacao de distribuicao (incluindo e-mail do Firebase App Distribution, quando aplicavel).

## 5) Continuidade
- Em retomadas de chat, usar `docs/web/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md` como ponto de restauracao.
- Registrar licoes novas em `docs/AGENTE_LICOES_APRENDIDAS.md`.
- Sempre que houver mudanca relevante de status, atualizar imediatamente o ponto de restauracao antes de encerrar o ciclo.
