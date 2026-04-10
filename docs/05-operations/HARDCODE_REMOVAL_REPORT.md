# Hardcode Removal Report — Multi-Brand BL-075 + BL-076

> Gerado em: 2026-04-09 (BL-075) · Atualizado: 2026-04-10 (BL-076)
> Ciclo: BL-075 — Fechamento da arquitetura multi-brand
> Ciclo: BL-076 — Fechamento dos gaps remanescentes (InfoRow, nav, range labels, AppColors.primary)

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

## BL-076 — Gaps remanescentes (2026-04-10)

### `lib/widgets/home/proposals_section.dart` — BL-076

| String removida | Localização anterior | Substituição adotada |
|---|---|---|
| `'Expira em'` | `_ProposalCard.build()` container de expiração | `config.copyText('proposal_expiration_prefix', defaultValue: 'Expira em')` |
| `'Endereço'` | `_InfoRow` label hardcoded | `config.copyText('proposal_address_label', defaultValue: 'Endereço')` |
| `'Proprietário'` | `_InfoRow` label hardcoded | `config.copyText('proposal_owner_label', defaultValue: 'Proprietário')` |
| `'Agendamento'` | `_InfoRow` label hardcoded | `config.copyText('proposal_schedule_label', defaultValue: 'Agendamento')` |

### `lib/widgets/home/jobs_section.dart` — BL-076

| String removida | Localização anterior | Substituição adotada |
|---|---|---|
| `'COMO CHEGAR'` | `_RichJobCard` OutlinedButton | `navigateLabel ?? 'COMO CHEGAR'` (resolvido via `config.copyTextOrNull('job_navigate_label')`) |
| `'Dentro do raio'` | `_buildDistanceInfo()` hardcoded | `withinRangeLabel ?? 'Dentro do raio'` (resolvido via `config.copyTextOrNull('job_within_range_label')`) |
| `'Fora do raio'` | `_buildDistanceInfo()` hardcoded | `outOfRangeLabel ?? 'Fora do raio'` (resolvido via `config.copyTextOrNull('job_out_of_range_label')`) |

### `lib/screens/home_screen.dart` — BL-076

| String removida | Localização anterior | Substituição adotada |
|---|---|---|
| `'Painel'` | `BottomNavigationBarItem label` hardcoded | `config.copyText('nav_home_label', defaultValue: 'Painel')` |
| `'Vistorias'` | `BottomNavigationBarItem label` hardcoded | `config.copyText('nav_jobs_label', defaultValue: 'Vistorias')` |
| `'Agenda'` | `BottomNavigationBarItem label` hardcoded | `config.copyText('nav_agenda_label', defaultValue: 'Agenda')` |

### `lib/widgets/home/location_status_card.dart` — BL-076

| Cor removida | Localização anterior | Substituição adotada |
|---|---|---|
| `AppColors.primary` | `Icon` de localização | `tokens.primary` via `BrandProvider.configOf(context).tokens` |

### `lib/widgets/home/operational_hub_card.dart` — BL-076

| Cor removida | Localização anterior | Substituição adotada |
|---|---|---|
| `AppColors.primaryLight` | Container de ícone (background) | `tokens.primaryLight` via `BrandProvider.configOf(context).tokens` |
| `AppColors.primary` | `Icon` do hub | `tokens.primary` via `BrandProvider.configOf(context).tokens` |

### `README.md` — BL-076

| Alteração | Detalhe |
|---|---|
| Título `(V2)` removido | `# AppMobile Ecosystem Platform (V2)` → `# AppMobile — Plataforma Multi-Brand` |
| Corpo alinhado ao modelo multi-brand | Removed domain-pack / white-label framing; entrypoints por marca adicionados |

---

## Chaves de copy adicionadas aos manifestos

### `lib/branding/kaptur_brand.dart` — chaves adicionadas (BL-075 + BL-076)

| Chave | Valor | Ciclo |
|---|---|---|
| `home_header_subtitle` | `'Seu painel operacional de hoje'` | BL-075 |
| `job_start_label` | `'INICIAR VISTORIA'` | BL-075 |
| `job_resume_label` | `'RETOMAR VISTORIA'` | BL-075 |
| `job_start_blocked_label` | `'Fora do raio de vistoria.'` | BL-075 |
| `proposal_swipe_label` | `'DESLIZE PARA ACEITAR'` | BL-075 |
| `proposal_accept_label` | `'ACEITAR PROPOSTA'` | BL-075 |
| `proposal_snackbar_accept_success` | `'Proposta aceita! Job adicionado ao seu dia.'` | BL-075 |
| `proposal_empty_title` | `'Nenhuma proposta disponível no momento.'` | BL-075 |
| `proposal_expiration_prefix` | `'Expira em'` | BL-076 |
| `proposal_address_label` | `'Endereço'` | BL-076 |
| `proposal_owner_label` | `'Proprietário'` | BL-076 |
| `proposal_schedule_label` | `'Agendamento'` | BL-076 |
| `job_navigate_label` | `'COMO CHEGAR'` | BL-076 |
| `job_within_range_label` | `'Dentro do raio'` | BL-076 |
| `job_out_of_range_label` | `'Fora do raio'` | BL-076 |
| `nav_home_label` | `'Painel'` | BL-076 |
| `nav_jobs_label` | `'Vistorias'` | BL-076 |
| `nav_agenda_label` | `'Agenda'` | BL-076 |

### `lib/branding/compass_brand.dart` — chaves adicionadas (BL-075 + BL-076)

| Chave | Valor | Ciclo |
|---|---|---|
| `home_header_subtitle` | `'Seu painel de avaliações'` | BL-075 |
| `job_start_label` | `'INICIAR AVALIAÇÃO'` | BL-075 |
| `job_resume_label` | `'RETOMAR AVALIAÇÃO'` | BL-075 |
| `job_start_blocked_label` | `'Fora da área de atendimento.'` | BL-075 |
| `proposal_snackbar_accept_success` | `'Demanda aceita! Adicionada ao seu painel.'` | BL-075 |
| `proposal_empty_title` | `'Nenhuma demanda disponível no momento.'` | BL-075 |
| `proposal_expiration_prefix` | `'Expira em'` | BL-076 |
| `proposal_address_label` | `'Endereço'` | BL-076 |
| `proposal_owner_label` | `'Responsável'` *(diferença de marca)* | BL-076 |
| `proposal_schedule_label` | `'Data da avaliação'` *(diferença de marca)* | BL-076 |
| `job_navigate_label` | `'COMO CHEGAR'` | BL-076 |
| `job_within_range_label` | `'Dentro da área'` *(diferença de marca)* | BL-076 |
| `job_out_of_range_label` | `'Fora da área'` *(diferença de marca)* | BL-076 |
| `nav_home_label` | `'Painel'` | BL-076 |
| `nav_jobs_label` | `'Avaliações'` *(diferença de marca)* | BL-076 |
| `nav_agenda_label` | `'Agenda'` | BL-076 |

---

## Critérios de aceite verificados

- [x] Nenhum widget das áreas alteradas lê manifest ou override diretamente
- [x] Toda UI tocada lê apenas `ResolvedBrandConfig`
- [x] `proposals_section.dart` não contém CTA principal hardcoded
- [x] `proposals_section.dart` não contém labels de campos hardcoded (InfoRow)
- [x] Kaptur e Compass exibem textos diferentes (configurados nos manifestos)
- [x] O widget não decide copy por marca usando `if` textual
- [x] A lógica operacional de jobs permanece intacta
- [x] `jobs_section.dart` não contém copy de ação hardcoded
- [x] `jobs_section.dart` não contém navigate label hardcoded
- [x] `jobs_section.dart` não contém range labels hardcoded
- [x] `home_header.dart` não contém copy institucional fixa
- [x] Bottom nav labels vêm de config (Compass mostra 'Avaliações', não 'Vistorias')
- [x] Não há nome do app hardcoded nas áreas tocadas
- [x] `AppColors.primary/primaryLight` substituídos por `tokens.primary/primaryLight` nos widgets da Home
- [x] O tema vem da marca ativa via `AppTheme.fromConfig(config)`
- [x] README sem referência ativa a `(V2)` nem ao modelo anterior
