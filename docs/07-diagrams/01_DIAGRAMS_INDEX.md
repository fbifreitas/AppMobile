# DIAGRAMS INDEX

## Diagramas Multi-Brand (ativos — ciclo BL-075)

### Fontes Mermaid (.mmd) — `01-sources/`

| Diagrama | Arquivo fonte | Descrição |
|---|---|---|
| Arquitetura multi-brand | `multibrand_architecture.mmd` | Fluxo manifest → resolver → config → UI |
| Build por marca | `multibrand_build_per_brand.mmd` | Android flavors + iOS targets + entrypoints |
| Criação de nova marca | `multibrand_create_brand_flow.mmd` | Fluxo `create_brand.sh` → validar → rodar |
| Consumo de config na UI | `multibrand_ui_config_consumption.mmd` | Contrato de leitura em widgets |

**Renderização dos .mmd:**
```bash
# Instalar Mermaid CLI (requer Node.js)
npm install -g @mermaid-js/mermaid-cli

# Gerar SVG
mmdc -i docs/07-diagrams/01-sources/multibrand_architecture.mmd \
     -o docs/07-diagrams/08-images/multibrand_architecture.svg

# Gerar PNG
mmdc -i docs/07-diagrams/01-sources/multibrand_architecture.mmd \
     -o docs/07-diagrams/08-images/multibrand_architecture.png \
     -b white
```

---

## Diagramas Multi-Brand (gerados — `08-images/`)

| Arquivo | Fonte | Status |
|---|---|---|
| `arquitetura_referencia_multimarca.png` | `.dot` (Graphviz) | Existente |
| `arquitetura_referencia_multimarca.svg` | `.dot` (Graphviz) | Existente |
| `estrutura_repo_alvo_multimarca.png` | `.dot` (Graphviz) | Existente |
| `estrutura_repo_alvo_multimarca.svg` | `.dot` (Graphviz) | Existente |
| `fluxo_criacao_nova_marca.png` | `.dot` (Graphviz) | Existente |
| `fluxo_criacao_nova_marca.svg` | `.dot` (Graphviz) | Existente |
| `roteiro_transicao_multimarca.png` | `.dot` (Graphviz) | Existente |
| `roteiro_transicao_multimarca.svg` | `.dot` (Graphviz) | Existente |

---

## Diagramas V2 Corporativos (imagens — `08-images/`)

- `arquitetura_referencia_v2_multidominio.png` — arquitetura corporativa V2
- `roteiro_transicao_v2.png` — roteiro de transição V2
- `estrutura_repo_alvo_v2.png` — estrutura alvo do repositório V2

---

## Como usar

- **Referência de arquitetura**: `multibrand_architecture.mmd` — fluxo completo manifest → UI
- **Onboarding de nova marca**: `multibrand_create_brand_flow.mmd` — passo a passo visual
- **Alinhamento de build**: `multibrand_build_per_brand.mmd` — Android + iOS por flavor
- **Code review de widgets**: `multibrand_ui_config_consumption.mmd` — o que é proibido/permitido
