# Incremento de Arquitetura — OCR Documental e Tipos de Documento

## Objetivo

Especializar a capability horizontal de `Document OCR` para o programa atual, mantendo o desenho reutilizavel e registrando os requisitos do recorte atual.

## Tipos documentais elegiveis na fase atual

- IPTU
- matricula / registro de imovel
- certidoes correlatas
- outros documentos parametrizaveis futuramente por tenant/contrato

## Pipeline incremental

1. documento chega ao case
2. artefato e armazenado no storage historico
3. servico classifica o tipo documental
4. OCR e executado
5. campos sao extraidos e normalizados
6. fatos documentais sao reconciliados com facts de pesquisa e do case
7. backend decide se o `Execution Plan` pode ser publicado automaticamente
8. em caso negativo, cria pendencia de manual resolution

## Exemplos de campos relevantes por tipo

### IPTU
- inscricao municipal/SQL quando aplicavel
- area territorial
- area construida
- endereco fiscal
- valor venal
- exercicio do documento

### Matricula / registro de imovel
- matricula
- cartorio
- proprietario
- area
- fracao ideal
- onus/restricoes quando legiveis e dentro do escopo

## Regras de precedencia sugeridas

Ordem sugerida por padrao:
1. documento/OCR validado
2. dado integrado no case
3. research/IA
4. hipotese operacional
5. decisao manual do backoffice

Essa ordem deve poder evoluir para configuracao futura por tenant/contrato.

## Criterios de manual resolution

Criar pendencia quando:
- classificacao documental falhar
- OCR retornar baixa confianca nos campos minimos
- documento conflitar com o case em campos criticos
- documento conflitar com a pesquisa em campos criticos
- o `Execution Plan` depender de campo documental ainda nao resolvido
