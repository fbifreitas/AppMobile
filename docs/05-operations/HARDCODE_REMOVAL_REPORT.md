# Hardcode Removal Report — Multi-Brand BL-075

> Gerado em: 2026-04-09
> Ciclo: BL-075 — Fechamento da arquitetura multi-brand

---

## Arquivos alterados

### `lib/widgets/home/proposals_section.dart`

| String removida | Localização anterior | Substituição adotada |
|---|---|---|
| `'DESLIZE PARA ACEITAR'` | `_SwipeToAccept.build()` via `marketplaceCopyEnabled` | `config.copyText('proposal_swipe_label', defaultValue: 'DESLIZE PARA ACEITAR')` |
| `'ACEITAR PROPOSTA'` | `_SwipeToAccept.build()` via `marketplaceCopyEnabled` | `config.copyText('proposal_accept_label', defaultValue: 'ACEITAR PROPOSTA')` |
| `'ACEITAR'` | `_SwipeToAccept.build()` e `_AcceptButton.build()` via `marketplaceCopyEnabled` | Substituído pela chave `proposal_accept_label` resolvida |
| `'ACEITAR PROPOSTA'` (botão) | `_AcceptButton.build()` via `marketplaceCopyEnabled` | `config.copyText('proposal_accept_label', ...)` passado como param `label` |
| `'Proposta ${proposta.id} aceita! Job adicionado aos seus jobs de hoje.'` | `_ProposalsSectionState._acceptProposal()` | `config.copyText('proposal_snackbar_accept_success', defaultValue: 'Proposta aceita! Job adicionado ao seu dia.')` |
| `'Nenhuma proposta disponível no momento.'` | `ProposalsSection.build()` bloco vazio | `config.copyText('proposal_empty_title', defaultValue: '...')` |
| Parâmetro `marketplaceCopyEnabled` como decision de copy | `_SwipeToAccept`, `_AcceptButton` | Removido do caminho de copy; mantido em `BrandFeatureFlags` para decisão estrutural |

### `lib/widgets/home/jobs_section.dart`

| String removida | Localização anterior | Substituição adotada |
|---|---|---|
| `'MEUS JOBS DE HOJE'` (fallback no widget) | `JobsSection.build()` | `config.copyText('jobs_section_title', defaultValue: 'MEUS JOBS DE HOJE')` |
| `'RETOMAR VISTORIA'` (fallback interno) | `_RichJobCard.build()` | `resumeLabel ?? 'RETOMAR'` (canonical neutro; valor real vem do caller via config) |
| `'INICIAR VISTORIA'` (fallback interno) | `_RichJobCard.build()` | `startLabel ?? 'INICIAR'` (canonical neutro; valor real vem do caller via config) |

### `lib/widgets/home/home_header.dart`

| String removida | Localização anterior | Substituição adotada |
|---|---|---|
| `'Seu painel operacional de hoje'` (fallback hardcoded) | `HomeHeader.build()` | `config.copyText('home_header_subtitle', defaultValue: 'Seu painel operacional de hoje')` lido do `BrandProvider` |

### `lib/screens/home_screen.dart`

| String removida | Localização anterior | Substituição adotada |
|---|---|---|
| Chave `'home_subtitle'` | `HomeHeader` subtitle prop | Renomeada para `'home_header_subtitle'` (alinhada com spec e brand manifests) |
| Parâmetro `marketplaceCopyEnabled` em `ProposalsSection` | `home_screen.dart` | Removido — ProposalsSection resolve copy internamente via config |

### `lib/screens/operational_snapshot_export_screen.dart`

| String removida | Localização anterior | Substituição adotada |
|---|---|---|
| `config.manifest.appName` (leitura direta do manifest) | `buildPlainText(appName: ...)` | `config.appName` (helper canonical do `ResolvedBrandConfig`) |

### `lib/theme/app_colors.dart`

| Alteração | Detalhe |
|---|---|
| Header de legado reforçado | Adicionado comentário explícito proibindo uso em código novo e indicando a rota correta (`BrandTokens` via `ResolvedBrandConfig`) |

---

## Chaves de copy adicionadas aos manifestos

### `lib/branding/kaptur_brand.dart` — chaves novas

| Chave | Valor |
|---|---|
| `home_header_subtitle` | `'Seu painel operacional de hoje'` |
| `job_start_label` | `'INICIAR VISTORIA'` |
| `job_resume_label` | `'RETOMAR VISTORIA'` |
| `job_start_blocked_label` | `'Fora do raio de vistoria.'` |
| `proposal_swipe_label` | `'DESLIZE PARA ACEITAR'` |
| `proposal_accept_label` | `'ACEITAR PROPOSTA'` |
| `proposal_snackbar_accept_success` | `'Proposta aceita! Job adicionado ao seu dia.'` |
| `proposal_empty_title` | `'Nenhuma proposta disponível no momento.'` |

### `lib/branding/compass_brand.dart` — chaves novas e modificadas

| Chave | Valor |
|---|---|
| `home_header_subtitle` | `'Seu painel de avaliações'` (renomeada de `home_subtitle`) |
| `job_start_label` | `'INICIAR AVALIAÇÃO'` (capitalizado) |
| `job_resume_label` | `'RETOMAR AVALIAÇÃO'` (capitalizado) |
| `job_start_blocked_label` | `'Fora da área de atendimento.'` (expandido) |
| `proposal_snackbar_accept_success` | `'Demanda aceita! Adicionada ao seu painel.'` (novo) |
| `proposal_empty_title` | `'Nenhuma demanda disponível no momento.'` (novo) |

---

## Critérios de aceite verificados

- [x] Nenhum widget das áreas alteradas lê manifest ou override diretamente
- [x] Toda UI tocada lê apenas `ResolvedBrandConfig`
- [x] `proposals_section.dart` não contém CTA principal hardcoded
- [x] Kaptur e Compass exibem textos diferentes (configurados nos manifestos)
- [x] O widget não decide copy por marca usando `if` textual
- [x] A lógica operacional de jobs permanece intacta
- [x] `jobs_section.dart` não contém copy de ação hardcoded
- [x] `home_header.dart` não contém copy institucional fixa
- [x] Não há nome do app hardcoded nas áreas tocadas
- [x] `AppColors` não é usado nas telas alteradas
- [x] O tema vem da marca ativa via `AppTheme.fromConfig(config)`
