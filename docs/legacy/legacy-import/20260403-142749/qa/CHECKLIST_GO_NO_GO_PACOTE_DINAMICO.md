# Checklist Go/No-Go - Pacote Dinamico (Check-in + Camera + Revisao + Menu)

Atualizado em: 2026-03-30

## Objetivo
Validar se o pacote de configuracao dinamica esta consistente antes de implantar em producao, com foco em:
- Contexto operacional (Check-in Etapa 1)
- Norma (Check-in Etapa 2)
- Execucao em campo (Camera)
- Validacao de cumprimento (Revisao e Menu)

## Regra de aprovacao
- GO: todos os itens criticos aprovados.
- NO-GO: qualquer item critico reprovado.

## Escopo critico
1. Estrutura de niveis
2. Dominio da informacao por nivel
3. Regras normativas (obrigatoriedade, min/max fotos)
4. Integracao entre telas
5. Mock do Hub Operacional

## 1) Estrutura de niveis (Contexto + Captura)
| ID | Verificacao | Criticidade | Resultado |
|---|---|---|---|
| N-01 | Check-in Etapa 1 aceita niveis configuraveis (nao fixos) | Critico | [ ] |
| N-02 | Dependencias entre niveis do Check-in Etapa 1 funcionam (ex.: Tipo -> Subtipo -> Area -> Piso) | Critico | [ ] |
| N-03 | Camera aceita niveis configuraveis por Tipo + Subtipo | Critico | [ ] |
| N-04 | Estrutura suporta casos com mais niveis (ex.: Duplex com Piso) | Critico | [ ] |
| N-05 | Estrutura suporta casos com menos niveis (sem quebra de fluxo) | Critico | [ ] |

## 2) Dominio da informacao por nivel
| ID | Verificacao | Criticidade | Resultado |
|---|---|---|---|
| D-01 | Cada nivel possui lista de opcoes valida para o contexto | Critico | [ ] |
| D-02 | Nao existe opcao orfa (valor sem pai valido) | Critico | [ ] |
| D-03 | Nao existe ciclo de dependencia entre niveis | Critico | [ ] |
| D-04 | Mudanca de opcao no nivel pai recalcula corretamente niveis filhos | Critico | [ ] |
| D-05 | Casos de dominio real foram validados (Apartamento, Duplex, Sala comercial, Rural) | Critico | [ ] |

## 3) Regras normativas (Check-in Etapa 2)
| ID | Verificacao | Criticidade | Resultado |
|---|---|---|---|
| R-01 | Obrigatoriedade e definida na Etapa 2 (fonte normativa unica) | Critico | [ ] |
| R-02 | minFotos e maxFotos estao consistentes (max >= min quando definido) | Critico | [ ] |
| R-03 | Cada regra obrigatoria aponta para um caminho valido na arvore (contexto + camera) | Critico | [ ] |
| R-04 | Regras obrigatorias por Subtipo funcionam sem vazamento para outros subtipos | Critico | [ ] |
| R-05 | Regra para Estado/material como opcional/obrigatorio respeita configuracao | Critico | [ ] |

## 4) Integracao entre telas
| ID | Verificacao | Criticidade | Resultado |
|---|---|---|---|
| I-01 | Check-in Etapa 1 persiste contexto completo para consumo posterior | Critico | [ ] |
| I-02 | Camera usa contexto da Etapa 1 para simplificar menus em campo | Critico | [ ] |
| I-03 | Revisao valida cumprimento com base na norma da Etapa 2 (nao por regra local) | Critico | [ ] |
| I-04 | Menu de Vistoria mostra o mesmo status da Revisao para obrigatorios | Critico | [ ] |
| I-05 | Retomada de rascunho preserva niveis selecionados e pendencias | Critico | [ ] |

## 5) Mock do Hub Operacional
| ID | Verificacao | Criticidade | Resultado |
|---|---|---|---|
| M-01 | Mock unificado contem step1, step2 e camera no mesmo documento | Critico | [ ] |
| M-02 | Mock permite simular configuracoes por Tipo + Subtipo | Critico | [ ] |
| M-03 | Mock permite simular niveis extras (ex.: Piso) | Critico | [ ] |
| M-04 | Mock permite simular obrigatorio vs opcional por nivel | Critico | [ ] |
| M-05 | Mock reflete comportamento real no app sem divergencia funcional | Critico | [ ] |

## 6) Casos praticos obrigatorios (execucao em campo)
| Caso | Cenário | Esperado | Resultado |
|---|---|---|---|
| C-01 | Usuario inicia na rua | Menus externos priorizados e regras corretas | [ ] |
| C-02 | Usuario inicia na area externa do condominio | Menus recalculados sem ruído | [ ] |
| C-03 | Usuario inicia dentro do imovel | Menus internos diretos | [ ] |
| C-04 | Cobertura Duplex no piso superior | Nivel Piso afeta Local/Elemento corretamente | [ ] |
| C-05 | Sala comercial com recepcao | Arvore especifica do subtipo sem heranca indevida | [ ] |

## Gate final de implantacao
| Gate | Regra | Resultado |
|---|---|---|
| G-01 | Todos os itens Criticos aprovados | [ ] |
| G-02 | Nenhuma divergencia entre Revisao e Menu em obrigatoriedade | [ ] |
| G-03 | Mock do Hub validado com no minimo 4 subtipos reais | [ ] |
| G-04 | Aprovacao conjunta Produto + Operacao + Tecnologia | [ ] |

## Assinaturas
- Produto: __________________
- Operacao: ________________
- Tecnologia: ______________
- Data: ____________________
