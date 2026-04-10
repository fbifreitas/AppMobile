# Brand Validation Checklist

> Use este checklist para validar que Kaptur e Compass funcionam corretamente
> com o mesmo core Flutter, diferenciados apenas pela configuração de marca.

---

## Como usar

1. Rode o app com o flavor desejado.
2. Percorra cada tela listada abaixo.
3. Marque o comportamento esperado e confirme a chave/config de origem.

---

## Kaptur — Validação

**Entrypoint:** `flutter run --flavor kaptur -t lib/main_kaptur.dart`

| Tela / Componente | Comportamento esperado | Chave / Config de origem | OK? |
|---|---|---|---|
| **Login** | Exibe "Bem-vindo ao Kaptur" | `login_welcome` em `kapturManifest` | ☐ |
| **Login** | Cor do ícone principal é azul (#0D3B92) | `primaryColor` em `kapturManifest` | ☐ |
| **Home — cabeçalho** | Subtítulo: "Seu painel operacional de hoje" | `home_header_subtitle` em `kapturManifest` | ☐ |
| **Home — Jobs** | Título da seção: "MEUS JOBS DE HOJE" | `jobs_section_title` em `kapturManifest` | ☐ |
| **Home — Jobs** | Botão iniciar: "INICIAR VISTORIA" | `job_start_label` em `kapturManifest` | ☐ |
| **Home — Jobs** | Botão retomar: "RETOMAR VISTORIA" | `job_resume_label` em `kapturManifest` | ☐ |
| **Home — Jobs** | Label bloqueio: "Fora do raio de vistoria." | `job_start_blocked_label` em `kapturManifest` | ☐ |
| **Home — Propostas** | Bloco de propostas visível | `featureFlags.proposalsBlockEnabled == true` | ☐ |
| **Home — Propostas** | Título: "NOVAS PROPOSTAS" | `proposals_section_title` em `kapturManifest` | ☐ |
| **Home — Propostas** | Interação de swipe habilitada | `featureFlags.swipeRequired == true` | ☐ |
| **Home — Propostas** | Texto swipe: "DESLIZE PARA ACEITAR" | `proposal_swipe_label` em `kapturManifest` | ☐ |
| **Home — Propostas** | Background do swipe: "ACEITAR PROPOSTA" | `proposal_accept_label` em `kapturManifest` | ☐ |
| **Home — Propostas** | Snackbar após aceite: "Proposta aceita! Job adicionado ao seu dia." | `proposal_snackbar_accept_success` em `kapturManifest` | ☐ |
| **Home — Propostas** | Valor monetário visível no card | `featureFlags.financialSummaryEnabled == true` | ☐ |
| **Home — Propostas** | Label expiração: "Expira em XX:XX" | `proposal_expiration_prefix` em `kapturManifest` | ☐ |
| **Home — Propostas** | Label campo endereço: "Endereço" | `proposal_address_label` em `kapturManifest` | ☐ |
| **Home — Propostas** | Label campo proprietário: "Proprietário" | `proposal_owner_label` em `kapturManifest` | ☐ |
| **Home — Propostas** | Label campo data: "Agendamento" | `proposal_schedule_label` em `kapturManifest` | ☐ |
| **Home — Jobs** | Botão navegação: "COMO CHEGAR" | `job_navigate_label` em `kapturManifest` | ☐ |
| **Home — Jobs** | Tag de raio quando dentro: "Dentro do raio" | `job_within_range_label` em `kapturManifest` | ☐ |
| **Home — Jobs** | Tag de raio quando fora: "Fora do raio" | `job_out_of_range_label` em `kapturManifest` | ☐ |
| **Home — Jobs** | Tag de raio: "Raio: 500m" (prefixo configurável) | `job_geofence_radius_prefix` em `kapturManifest` | ☐ |
| **Home — Jobs** | Indicador de status em andamento: "EM ANDAMENTO" | `job_status_active_label` em `kapturManifest` | ☐ |
| **Home — Jobs** | Indicador de status recuperável: "EM RECUPERAÇÃO" | `job_status_recoverable_label` em `kapturManifest` | ☐ |
| **Home — Jobs** | Banner de recuperação: "Vistoria em andamento interrompida. Última etapa salva: ..." | `job_recovery_warning_prefix` em `kapturManifest` | ☐ |
| **Bottom Nav** | Tab Home: "Painel" | `nav_home_label` em `kapturManifest` | ☐ |
| **Bottom Nav** | Tab Jobs: "Vistorias" | `nav_jobs_label` em `kapturManifest` | ☐ |
| **Bottom Nav** | Tab Agenda: "Agenda" | `nav_agenda_label` em `kapturManifest` | ☐ |
| **LocationStatusCard** | Ícone de localização em azul da marca | `tokens.primary` via `BrandProvider.configOf(context)` | ☐ |
| **OperationalHubCard** | Ícone e fundo do hub em azul da marca | `tokens.primary/primaryLight` via `BrandProvider.configOf(context)` | ☐ |
| **Tema** | Cor primária azul (#0D3B92) em botões e ícones | `tokens.primary` via `BrandTokens.fromManifest` | ☐ |
| **App title** | Title do MaterialApp: "Kaptur" | `config.appName` de `kapturManifest` | ☐ |

---

## Compass — Validação

**Entrypoint:** `flutter run --flavor compass -t lib/main_compass.dart`

| Tela / Componente | Comportamento esperado | Chave / Config de origem | OK? |
|---|---|---|---|
| **Login** | Exibe "Bem-vindo à Compass Avaliações" | `login_welcome` em `compassManifest` | ☐ |
| **Login** | Cor do ícone principal é verde (#1B6B3A) | `primaryColor` em `compassManifest` | ☐ |
| **Home — cabeçalho** | Subtítulo: "Seu painel de avaliações" | `home_header_subtitle` em `compassManifest` | ☐ |
| **Home — Jobs** | Título da seção: "ORDENS DO DIA" | `jobs_section_title` em `compassManifest` | ☐ |
| **Home — Jobs** | Botão iniciar: "INICIAR AVALIAÇÃO" | `job_start_label` em `compassManifest` | ☐ |
| **Home — Jobs** | Botão retomar: "RETOMAR AVALIAÇÃO" | `job_resume_label` em `compassManifest` | ☐ |
| **Home — Jobs** | Label bloqueio: "Fora da área de atendimento." | `job_start_blocked_label` em `compassManifest` | ☐ |
| **Home — Propostas** | Bloco de propostas visível | `featureFlags.proposalsBlockEnabled` (verificar flag Compass) | ☐ |
| **Home — Propostas** | Título: "DEMANDAS DISPONÍVEIS" | `proposals_section_title` em `compassManifest` | ☐ |
| **Home — Propostas** | Botão (sem swipe) para aceitar | `featureFlags.swipeRequired == false` → `_AcceptButton` | ☐ |
| **Home — Propostas** | Label botão: "ACEITAR DEMANDA" | `proposal_accept_label` em `compassManifest` | ☐ |
| **Home — Propostas** | Snackbar após aceite: "Demanda aceita! Adicionada ao seu painel." | `proposal_snackbar_accept_success` em `compassManifest` | ☐ |
| **Home — Propostas** | Label campo proprietário: "Responsável" *(≠ Kaptur)* | `proposal_owner_label` em `compassManifest` | ☐ |
| **Home — Propostas** | Label campo data: "Data da avaliação" *(≠ Kaptur)* | `proposal_schedule_label` em `compassManifest` | ☐ |
| **Home — Jobs** | Tag de raio quando dentro: "Dentro da área" *(≠ Kaptur)* | `job_within_range_label` em `compassManifest` | ☐ |
| **Home — Jobs** | Tag de raio quando fora: "Fora da área" *(≠ Kaptur)* | `job_out_of_range_label` em `compassManifest` | ☐ |
| **Home — Jobs** | Tag de raio: "Área: 500m" *(prefixo ≠ Kaptur)* | `job_geofence_radius_prefix` em `compassManifest` | ☐ |
| **Home — Jobs** | Indicador de status em andamento: "EM ANDAMENTO" | `job_status_active_label` em `compassManifest` | ☐ |
| **Home — Jobs** | Indicador de status recuperável: "EM RECUPERAÇÃO" | `job_status_recoverable_label` em `compassManifest` | ☐ |
| **Home — Jobs** | Banner de recuperação: "Avaliação interrompida. Última etapa salva: ..." *(≠ Kaptur)* | `job_recovery_warning_prefix` em `compassManifest` | ☐ |
| **Bottom Nav** | Tab Jobs: "Avaliações" *(≠ Kaptur)* | `nav_jobs_label` em `compassManifest` | ☐ |
| **LocationStatusCard** | Ícone de localização em verde da marca | `tokens.primary` via `BrandProvider.configOf(context)` | ☐ |
| **OperationalHubCard** | Ícone e fundo do hub em verde da marca | `tokens.primary/primaryLight` via `BrandProvider.configOf(context)` | ☐ |
| **Tema** | Cor primária verde (#1B6B3A) em botões e ícones | `tokens.primary` via `BrandTokens.fromManifest` | ☐ |
| **App title** | Title do MaterialApp: "Compass Avaliações" | `config.appName` de `compassManifest` | ☐ |

---

## Invariantes do Core (ambas as marcas)

| Verificação | Detalhe | OK? |
|---|---|---|
| Lógica de geofence intacta | Jobs fora do raio bloqueiam início em Kaptur (geofenceRequired=true) | ☐ |
| Geofence desligado no Compass | Jobs iniciam sem restrição de raio (geofenceRequired=false, a confirmar pela flag) | ☐ |
| Aceitar proposta adiciona job | Job aparece na seção de jobs após aceite | ☐ |
| `BrandProvider` na árvore | Nenhum widget faz fallback por ausência de config | ☐ |
| `AppColors` não usado nas telas alteradas | Confirmar com `flutter analyze` sem warnings de deprecated | ☐ |
| Tema derivado da marca ativa | `AppTheme.fromConfig(config)` aplicado em ambas as marcas | ☐ |

---

## Diferença entre marcas — Origem da config

| Aspecto | Kaptur | Compass | Chave |
|---|---|---|---|
| Título dos jobs | MEUS JOBS DE HOJE | ORDENS DO DIA | `jobs_section_title` |
| Subtítulo da home | Seu painel operacional de hoje | Seu painel de avaliações | `home_header_subtitle` |
| Welcome login | Bem-vindo ao Kaptur | Bem-vindo à Compass Avaliações | `login_welcome` |
| Label iniciar | INICIAR VISTORIA | INICIAR AVALIAÇÃO | `job_start_label` |
| Label retomar | RETOMAR VISTORIA | RETOMAR AVALIAÇÃO | `job_resume_label` |
| Aceite de proposta | Swipe + label "DESLIZE PARA ACEITAR" | Botão "ACEITAR DEMANDA" | `swipeRequired` + `proposal_*` |
| Campo proprietário | "Proprietário" | "Responsável" | `proposal_owner_label` |
| Campo data | "Agendamento" | "Data da avaliação" | `proposal_schedule_label` |
| Tab jobs | "Vistorias" | "Avaliações" | `nav_jobs_label` |
| Range label (dentro) | "Dentro do raio" | "Dentro da área" | `job_within_range_label` |
| Range label (fora) | "Fora do raio" | "Fora da área" | `job_out_of_range_label` |
| Cor primária | Azul #0D3B92 | Verde #1B6B3A | `primaryColor` |
| Modo de produto | marketplace | corporate | `productMode` |

**Regra:** toda diferença acima vem da config, não de `if (brand == ...)` no widget.

---

## Validação via script

```bash
./scripts/validate_brand_setup.sh --brand-id kaptur
./scripts/validate_brand_setup.sh --brand-id compass
```
