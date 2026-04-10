# White Label Onboarding Strategy

> Fonte funcional para evolucao/substituicao do onboarding mobile atual em apps separados por marca.
> Escopo inicial: Kaptur marketplace e Compass corporate/SaaS.

## 1. Diagnostico De Substituicao

O onboarding atual nao deve ser tratado como inexistente. Ele ja entrega tres bases reutilizaveis: estado de autenticacao/onboarding em `AuthState`, tela de aguardando aprovacao e onboarding de permissoes separado da Home. O problema e que a jornada principal (`OnboardingScreen`) hoje esta acoplada a um cadastro PJ curto, com CNPJ e dados bancarios como centro do fluxo. Isso atende parte do caso Kaptur, mas gera confusao para Compass, onde o usuario normalmente ja existe no backoffice e precisa apenas ativar primeiro acesso.

Problemas de um fluxo unico para produtos diferentes:

1. Friccao indevida: Compass nao deve pedir dados bancarios ou cadastro de prestador para usuario ja provisionado.
2. Segurança fraca: CPF/data de nascimento podem localizar cadastro, mas nao podem autenticar sem OTP e criacao de credencial.
3. Copy inadequada: Kaptur fala com prestador/marketplace; Compass fala com operador corporativo de uma empresa.
4. Estados ambíguos: "onboarding" mistura cadastro novo, primeiro acesso, aguardando aprovacao e permissao nativa.
5. Evolucao cara: cada nova marca adicionaria condicionais na mesma tela em vez de compor modulos.

O que manter:

1. `AuthState` como orquestrador de status: `unauthenticated`, `onboarding`, `awaitingApproval`, `active`.
2. Tela/estado de aguardando aprovacao.
3. Tela explicativa de permissoes, mas com solicitacao por permissao e por momento de uso.
4. Login backend-first ja implantado para Compass.
5. Separacao por flavor/brand manifest e `ProductMode`.

O que adaptar:

1. Boas-vindas/login deve ter copy e links por marca.
2. Onboarding deve virar uma composicao de etapas por app, nao uma tela unica PJ.
3. Permissoes devem ser pedidas com justificativa e fallback para Ajustes.
4. Tutorial deve ser modulo reutilizavel, mas com conteudo por marca/produto.

O que remover/substituir:

1. Uso do mesmo cadastro PJ como onboarding padrao para Compass.
2. Obrigatoriedade de dados bancarios para apps corporate sem repasse direto ao operador.
3. Solicitar microfone por padrao quando voz nao estiver habilitada.
4. Qualquer fluxo que trate CPF + data de nascimento como autenticacao final.

## 2. Visao De Produto E Arquitetura White Label

A estrategia correta e single-codebase com apps separados por marca. Kaptur e Compass sao apps distintos, com identidade, distribuicao e jornada proprias. O reuso deve ocorrer em modulos funcionais, servicos e componentes, nao em uma jornada unica que tenta servir todos.

Compartilhar quando:

1. A funcao e universal: login, OTP, selfie, aceite de termos, permissoes, tutorial, aguardando aprovacao.
2. A regra e parametrizavel: quais campos pedir, quais permissoes, quais termos, qual tutorial.
3. A seguranca e comum: token, refresh, lockout, OTP, anti-enumeracao, rate limit.

Separar completamente quando:

1. A intencao do usuario muda: criar conta nova Kaptur versus ativar acesso Compass.
2. A linguagem muda: "Vistoriador parceiro" versus "Operador Compass".
3. Os dados obrigatorios mudam: bancarios/fiscais para Kaptur, dados minimos para Compass.
4. O status final muda: Kaptur pode ir para aguardando aprovacao; Compass tende a ir para Home se o backoffice ja aprovou.

Compartilhavel entre apps:

1. `OnboardingModule`: contrato de etapa.
2. `OnboardingFlowResolver`: escolhe sequencia por brand/productMode.
3. `LoginGate`: tela base com slots de copy e links.
4. `OtpChallenge`: envio, validacao, expiracao e reenvio.
5. `SelfieCapture`: captura e upload.
6. `TermsAcceptance`: termos e consentimentos versionados.
7. `PermissionEducation`: explicacao antes do prompt nativo.
8. `PocketTraining`: cards de tutorial por produto.
9. `AwaitingApproval`: status e refresh.

Especifico por marca:

1. Ordem das etapas.
2. Campos obrigatorios.
3. Copy, tom, exemplos e termos.
4. Politica de aprovacao.
5. Permissoes habilitadas.
6. Regras de dados bancarios, fiscais e titularidade.
7. Politica de primeiro acesso.

## 3. Arquitetura Do Fluxo

Fluxo macro do ecossistema:

```text
Abrir app -> BrandManifest -> OnboardingFlowResolver
  -> usuario com sessao valida?
    -> sim: status active + permissoes ok -> Home
    -> sim: active + permissoes pendentes -> Permissoes
    -> sim: awaitingApproval -> Aguardando aprovacao
    -> sim: onboarding incompleto -> Retomar etapa pendente
    -> nao: Gate de entrada por marca
```

Kaptur:

```text
Boas-vindas/Login -> Criar conta de Vistoriador -> Identificacao inicial
-> OTP -> Selfie -> Tipo de prestador -> Dados fiscais/cadastrais
-> Area de atuacao/disponibilidade -> Segurança/equipamentos
-> Dados bancarios/PIX -> Termos -> Pocket training
-> Permissoes no momento adequado -> Aguardando aprovacao ou Home
```

Compass:

```text
Boas-vindas/Login -> Primeiro acesso -> Localizar cadastro existente
-> OTP para contato cadastrado -> Criar senha -> Selfie
-> Complemento minimo -> Termos -> Pocket training
-> Permissoes no momento adequado -> Home ou Aguardando aprovacao
```

Futuros apps:

```text
BrandManifest + OnboardingProfile
-> combina modulos: login, primeiro acesso, cadastro novo, OTP, selfie,
   termos, tutorial, permissoes, aprovacao, complementos por marca.
```

Pontos de decisao e fallback:

1. Usuario ja autenticado: nunca mostrar cadastro; rotear por status.
2. Onboarding incompleto: retomar etapa pendente, nao reiniciar.
3. Aguardando aprovacao: bloquear Home operacional, permitir verificar status.
4. Permissao negada: explicar impacto, permitir tentar de novo; se negada permanentemente, abrir Ajustes.
5. OTP expirado: permitir reenvio com cooldown e limite de tentativas.
6. Cadastro previo nao encontrado Compass: mensagem neutra, sem confirmar se CPF existe; orientar contatar administrador.
7. CPF/data nascimento divergentes: nao autenticar; registrar tentativa e aplicar rate limit.
8. Contato cadastrado indisponivel: fluxo de excecao via backoffice, nao troca livre de telefone no app.

## 4. Especificacao Tela A Tela

### 4.1 Gate De Entrada Kaptur

- Objetivo: login ou inicio de cadastro de novo vistoriador.
- Quando aparece: usuario sem sessao.
- App: Kaptur.
- Evolucao: adapta login atual e substitui entrada generica.
- Campos: e-mail ou CPF, senha.
- Validacoes: campo obrigatorio, senha obrigatoria, lockout por tentativa.
- CTA principal: Entrar.
- CTA secundario: Criar minha conta de Vistoriador; Esqueci minha senha.
- Erros: "Dados invalidos. Confira e tente novamente."; "Muitas tentativas. Aguarde alguns minutos."
- Navegacao: login valido -> roteador de status; criar conta -> identificacao inicial.
- Backend: `POST /auth/login`, futuramente recuperacao de senha.
- UX: copy marketplace, reforcar autonomia do prestador.

### 4.2 Gate De Entrada Compass

- Objetivo: login ou primeiro acesso de usuario ja provisionado.
- Quando aparece: usuario sem sessao.
- App: Compass.
- Evolucao: adapta login atual; remove CTA de cadastro aberto.
- Campos: e-mail ou CPF, senha.
- Validacoes: campo obrigatorio, senha obrigatoria, lockout.
- CTA principal: Entrar.
- CTA secundario: Primeiro acesso; Esqueci minha senha.
- Erros: neutros, sem enumerar cadastro.
- Navegacao: login valido -> status; primeiro acesso -> localizar cadastro.
- Backend: `POST /auth/login`, `POST /auth/first-access/start`.
- UX: copy corporativa: "Acesse com os dados fornecidos pela sua empresa".

### 4.3 Identificacao Inicial Kaptur

- Objetivo: iniciar cadastro aberto com dados minimos.
- Quando aparece: CTA criar conta.
- App: Kaptur.
- Evolucao: substitui o passo PJ unico atual.
- Campos: nome, CPF, e-mail, celular, data de nascimento.
- Validacoes: CPF valido, idade minima, e-mail/celular formato valido.
- CTA principal: Continuar.
- CTA secundario: Ja tenho conta.
- Erros: CPF invalido, contato invalido, cadastro ja existente.
- Backend: `POST /onboarding/kaptur/start`.
- UX: pedir pouco no inicio para reduzir abandono.

### 4.4 Primeiro Acesso Compass

- Objetivo: localizar cadastro preexistente sem autenticar ainda.
- Quando aparece: CTA Primeiro acesso.
- App: Compass.
- Evolucao: novo modulo; substitui auto-cadastro.
- Campos: CPF, data de nascimento, identificador adicional configuravel (e-mail corporativo, matricula ou codigo convite).
- Validacoes: campos obrigatorios, formato, rate limit.
- CTA principal: Localizar cadastro.
- CTA secundario: Voltar para login.
- Erros: "Nao foi possivel validar os dados. Confira ou contate o administrador."
- Backend: `POST /auth/first-access/lookup`.
- UX: nao informar se CPF existe; usar texto neutro.

### 4.5 OTP

- Objetivo: validar posse de contato ja cadastrado.
- Quando aparece: Kaptur apos identificacao; Compass apos lookup.
- App: ambos.
- Evolucao: novo modulo compartilhado.
- Campos: codigo de 6 digitos.
- Validacoes: expiracao, tentativas, cooldown, reenvio limitado.
- CTA principal: Validar codigo.
- CTA secundario: Reenviar codigo.
- Erros: codigo invalido, expirado, limite excedido.
- Backend: `POST /auth/otp/send`, `POST /auth/otp/verify`.
- UX: mostrar canal mascarado: "Enviamos para WhatsApp terminado em 1234".

### 4.6 Criacao De Senha Compass

- Objetivo: criar credencial no primeiro acesso.
- Quando aparece: OTP validado.
- App: Compass.
- Evolucao: novo modulo.
- Campos: senha, confirmar senha.
- Validacoes: minimo 8-12 chars, complexidade, blacklist, igualdade.
- CTA principal: Criar senha.
- CTA secundario: voltar.
- Erros: senha fraca, senhas diferentes, token expirado.
- Backend: `POST /auth/first-access/complete`.
- UX: explicar que CPF/data nascimento nao substituem senha.

### 4.7 Selfie

- Objetivo: identificacao visual do vistoriador/operador.
- Quando aparece: apos OTP ou senha, conforme app.
- App: ambos.
- Evolucao: novo modulo; atende BL-032 pendente de foto.
- Campos: captura de imagem; opcionalmente consentimento.
- Validacoes: imagem capturada, qualidade minima, upload.
- CTA principal: Tirar selfie.
- CTA secundario: Tirar novamente.
- Erros: camera indisponivel, upload falhou.
- Backend: upload seguro associado ao usuario.
- UX: explicar uso: "Ajuda morador/cliente a reconhecer quem chegou para a vistoria."

### 4.8 Tipo De Prestador Kaptur

- Objetivo: definir PF/MEI/PJ e campos condicionais.
- Quando aparece: cadastro Kaptur.
- App: Kaptur.
- Evolucao: substitui CNPJ obrigatorio atual.
- Campos: Prestador individual CPF/MEI ou Represento empresa CNPJ; CNPJ, razao social, inscricao municipal, endereco base.
- Validacoes: CNPJ quando PJ, endereco base, consistencia CPF/CNPJ.
- CTA principal: Continuar.
- CTA secundario: voltar.
- Backend: `PATCH /onboarding/kaptur/provider-profile`.
- UX: evitar forcar PJ para todos.

### 4.9 Dados Fiscais/Cadastrais Kaptur

- Objetivo: completar requisitos de contratacao/repasse.
- App: Kaptur.
- Campos: CPF/MEI/CNPJ, razao social, endereco, inscricao municipal quando aplicavel.
- Validacoes: titularidade e documentos.
- Backend: onboarding cadastral.
- UX: pode ser faseado se nao for necessario antes da primeira aprovacao.

### 4.10 Area De Atuacao E Disponibilidade Kaptur

- Objetivo: configurar matching de jobs.
- Campos: raio, cidades/bairros, horarios, sabados.
- App: Kaptur.
- Backend: disponibilidade/cobertura.
- UX: permitir editar depois.

### 4.11 Segurança E Equipamentos Kaptur

- Objetivo: validar requisitos operacionais.
- Campos: antecedentes, checklist smartphone/camera, trena manual/laser.
- App: Kaptur.
- Backend: documentos e checklist.
- UX: separar comprovantes obrigatorios de declaracoes simples.

### 4.12 Dados Bancarios/PIX Kaptur

- Objetivo: repasse financeiro.
- Campos: banco, tipo de conta, agencia, conta, PIX.
- App: Kaptur.
- Evolucao: reaproveita parte do passo atual, mas fica especifico de Kaptur.
- Validacoes: titularidade compativel com CPF/CNPJ.
- Backend: tokenizacao/armazenamento seguro ou provedor financeiro.
- UX: nao pedir para Compass na fase atual.

### 4.13 Complemento Minimo Compass

- Objetivo: preencher apenas lacunas do cadastro vindo do backoffice.
- Campos: telefone secundario, aceite de perfil, eventualmente selfie se faltante.
- App: Compass.
- Validacoes: somente campos marcados como faltantes.
- Backend: `GET /auth/me` ou endpoint de pendencias.
- UX: "Encontramos seu cadastro. Complete apenas o que falta."

### 4.14 Termos E Conduta

- Objetivo: registrar aceite versionado.
- App: ambos.
- Campos: checkboxes LGPD, confidencialidade, conduta, termos por marca.
- Validacoes: todos obrigatorios conforme app.
- Backend: `POST /terms/acceptances`.
- UX: termos curtos na tela, link para documento completo.

### 4.15 Pocket Training

- Objetivo: preparar usuario para operar sem friccao.
- App: ambos, conteudo diferente.
- Conteudos Kaptur: como aceitar proposta, fotos, danos, precisao, conduta.
- Conteudos Compass: fluxo corporativo, ordens do dia, configuracao por empresa, padroes tecnicos quando aplicavel.
- Backend: opcional para registrar conclusao.
- UX: cards curtos, pulavel apenas se politica permitir.

### 4.16 Permissoes Do Sistema

- Objetivo: explicar e solicitar permissao no momento certo.
- App: ambos.
- Evolucao: adapta tela existente.
- Permissoes: camera antes de selfie/foto; localizacao antes de job/geofence/check-in; microfone apenas se voz habilitada.
- Validacoes: status granted/denied/denied forever.
- CTA principal: Permitir agora.
- CTA secundario: Agora nao, quando a permissao nao bloquear etapa.
- Backend: nenhum obrigatorio, mas telemetria recomendada.
- UX: se negada permanentemente, abrir Ajustes do aparelho.

### 4.17 Aguardando Aprovacao

- Objetivo: bloquear operacao enquanto o cadastro nao foi aprovado.
- App: ambos, mais comum Kaptur.
- Evolucao: reaproveita tela atual.
- Campos: nenhum.
- CTA principal: Verificar status.
- CTA secundario: Sair.
- Backend: `GET /auth/me` ou lifecycle.
- UX: explicar proximo passo e prazo esperado.

## 5. Regras De Negocio

1. Usuario so entra na Home se estiver autenticado, com status `APPROVED/active`, termos obrigatorios aceitos e permissoes bloqueantes concedidas no momento de uso.
2. Compass nao deve exibir cadastro aberto; deve exibir primeiro acesso para usuario pre-cadastrado.
3. Kaptur deve permitir criar conta nova de vistoriador/prestador.
4. CPF/data nascimento/localizador adicional servem apenas para lookup, nunca para login final.
5. OTP e obrigatorio para ativar primeiro acesso ou novo cadastro antes de criar senha/credencial.
6. Compass deve usar contato ja cadastrado; alteracao de contato exige backoffice.
7. Selfie e obrigatoria quando a politica da marca exigir identificacao visual.
8. Dados bancarios sao obrigatorios para Kaptur antes de repasse, mas podem ser fase 2 se a aprovacao inicial permitir.
9. Dados bancarios nao sao obrigatorios para Compass na fase SaaS sem billing automatico/repasse ao operador.
10. PF/MEI/PJ define campos fiscais, titularidade e aprovacao.
11. Dados vindos do backoffice devem aparecer como bloqueados/confirmaveis, nao como campos livres.
12. Aguardando aprovacao bloqueia jobs operacionais.

## 6. Seguranca E Autenticacao

Login:

1. Campo e-mail ou CPF + senha.
2. Backend com rate limit, lockout e mensagens neutras.
3. Refresh token persistido e revogado no logout.

Primeiro acesso Compass:

1. Lookup por CPF + data de nascimento + identificador adicional.
2. Se localizar, enviar OTP para contato ja cadastrado e mascarado.
3. Validar OTP.
4. Criar senha.
5. Autenticar e seguir pendencias.

Cadastro Kaptur:

1. Identificacao inicial.
2. OTP para contato informado.
3. Criacao de senha.
4. Etapas cadastrais e aprovacao.

Riscos e mitigacoes:

1. Enumeracao de CPF: respostas neutras e rate limit.
2. Apropriacao de conta Compass: OTP para contato pre-cadastrado, nao para telefone informado livremente.
3. Senha fraca: politica minima e blacklist.
4. Sessao roubada: refresh token revogavel, expiracao curta de access token.
5. Reenvio abusivo de OTP: cooldown, limite diario e auditoria.
6. Dispositivo compartilhado: biometria opcional apos senha, nunca substituindo primeiro fator inicial.

## 7. Permissoes Do Sistema

Camera:

1. Pedir antes de selfie ou primeira foto.
2. Explicar valor: identificacao visual e captura tecnica.
3. Se negar: permitir tentar novamente; se permanente, abrir Ajustes.

Localizacao:

1. Pedir antes de check-in, geofence ou rota.
2. Explicar valor: validar presenca em campo e proteger operacao.
3. Se negar: bloquear apenas funcionalidades dependentes.

Microfone:

1. Nao pedir por padrao.
2. Pedir apenas se comando de voz estiver habilitado por marca/config.
3. Explicar que e opcional se houver alternativa manual.

Notificacoes:

1. Recomendado para fase 2.
2. Pedir depois que o usuario entender valor: agenda, jobs e mensagens.

## 8. Plano De Transicao

MVP:

1. Criar `OnboardingFlowResolver` por brand/productMode.
2. Separar Gate Kaptur e Gate Compass.
3. Compass: primeiro acesso com lookup + OTP + criar senha + termos + permissoes.
4. Kaptur: manter base do cadastro atual, mas mover dados bancarios para modulo Kaptur e permitir PF/MEI/PJ.
5. Permissoes: manter tela atual, mas mudar para etapas explicativas por permissao.
6. Aguardando aprovacao reaproveitada.

Fase 2:

1. Selfie com upload e avaliacao de qualidade.
2. Dados fiscais completos Kaptur.
3. Disponibilidade/area de atuacao.
4. Bancarios/PIX com titularidade.
5. Tutorial versionado e medicao de conclusao.
6. Notificacoes push.
7. Configuracao remota de onboarding por marca.

Rollout:

1. Feature flag por brand: `onboardingProfile=v1|white_label_v2`.
2. Compass primeiro, por depender menos de cadastro aberto.
3. Kaptur em rollout gradual para novos usuarios.
4. Usuarios antigos mantem status atual; so entram em novo fluxo se tiverem pendencia obrigatoria.
5. Telemetria de abandono por etapa antes de desligar o fluxo legado.

## 9. Recomendacao Final

A solucao final deve separar a jornada por app e compartilhar blocos funcionais. Kaptur fica com onboarding marketplace completo de prestador; Compass fica com primeiro acesso corporativo para usuario provisionado. O core comum deve cuidar de autenticacao, OTP, selfie, termos, permissoes, tutorial e aguardando aprovacao. A marca define ordem, copy, obrigatoriedade e politica de aprovacao.

MVP recomendado: resolver Gate por marca, implementar primeiro acesso Compass com OTP, adaptar permissao por momento de uso e transformar cadastro PJ atual em modulo Kaptur. Fase 2 completa dados fiscais, disponibilidade, bancarios/PIX, selfie robusta e tutorial versionado.

Trade-off: separar jornadas aumenta trabalho inicial, mas reduz friccao, melhora seguranca e evita divida de condicionais por marca. Compartilhar componentes preserva velocidade e consistencia sem forcar Kaptur e Compass a parecerem o mesmo produto.

## 10.A Tabela-Resumo Por Tela

| Ordem | Tela | App/Marca | Objetivo | Substitui o que no fluxo atual | Campos principais | Obrigatoria? | Dependencias |
|---|---|---|---|---|---|---|---|
| 1 | Gate Kaptur | Kaptur | Login ou criar conta | Login generico | e-mail/CPF, senha | Sim | Auth backend |
| 1 | Gate Compass | Compass | Login ou primeiro acesso | Login generico | e-mail/CPF, senha | Sim | Auth backend |
| 2 | Identificacao inicial | Kaptur | Iniciar cadastro | Cadastro PJ direto | nome, CPF, e-mail, celular, nascimento | Sim | OTP |
| 2 | Primeiro acesso | Compass | Localizar cadastro | Auto-cadastro indevido | CPF, nascimento, identificador | Sim | Lookup backend |
| 3 | OTP | Ambos | Validar contato | Novo | codigo | Sim | OTP backend |
| 4 | Criar senha | Compass | Ativar credencial | Novo | senha, confirmar | Sim | First access backend |
| 5 | Selfie | Ambos | Identificacao visual | Novo/parcial BL-032 | imagem | Por politica | Camera/upload |
| 6 | Tipo prestador | Kaptur | PF/MEI/PJ | CNPJ fixo | tipo, CNPJ, razao, endereco | Sim | Onboarding backend |
| 7 | Fiscais/cadastrais | Kaptur | Qualificacao | Parte do PJ atual | docs fiscais | Sim/faseada | Backoffice aprovacao |
| 8 | Area/disponibilidade | Kaptur | Matching | Novo | raio, cidades, horarios | Sim/faseada | Backoffice/mobile |
| 9 | Equipamentos | Kaptur | Requisitos operacionais | Novo | checklist, antecedentes | Sim/faseada | Upload |
| 10 | Bancarios/PIX | Kaptur | Repasse | Dados bancarios atuais | banco, conta, PIX | Antes de repasse | Financeiro |
| 11 | Complemento minimo | Compass | Completar lacunas | Novo | campos faltantes | Condicional | Backoffice |
| 12 | Termos | Ambos | Aceite versionado | Novo/parcial | checkboxes | Sim | Terms backend |
| 13 | Pocket training | Ambos | Preparar uso | Novo | cards | Por politica | Conteudo |
| 14 | Permissoes | Ambos | Liberar recursos | Tela atual adaptada | camera, localizacao, microfone condicional | Por recurso | APIs nativas |
| 15 | Aguardando aprovacao | Ambos | Bloquear ate aprovacao | Tela atual | nenhum | Condicional | User lifecycle |

## 10.B Componentes Reutilizaveis

1. Gate de login com slots de copy/links por marca.
2. OTP challenge.
3. Selfie capture.
4. Terms acceptance.
5. Permission education.
6. Pocket training.
7. Awaiting approval.
8. Onboarding progress/resume.
9. Field validation library para CPF/CNPJ/e-mail/celular.
10. Secure credential creation.

## 10.C Arquitetura Configuravel

Modulos compartilhaveis:

1. `LoginGateModule`
2. `FirstAccessLookupModule`
3. `OpenRegistrationModule`
4. `OtpModule`
5. `PasswordCreationModule`
6. `SelfieModule`
7. `ProviderProfileModule`
8. `FiscalDataModule`
9. `CoverageAvailabilityModule`
10. `BankingPixModule`
11. `TermsModule`
12. `TrainingModule`
13. `PermissionsModule`
14. `ApprovalStatusModule`

Parametros por app:

1. `onboardingProfile`: `marketplace_provider` ou `corporate_first_access`.
2. `allowedEntryActions`: login, createAccount, firstAccess, forgotPassword.
3. `requiredIdentityFactors`: CPF, nascimento, email, matricula, inviteCode.
4. `otpChannelPolicy`: sms, whatsapp, email, contato_pre_cadastrado.
5. `requiredPermissions`: camera, location, microphone, notifications.
6. `termsSetId`: termos versionados por marca.
7. `approvalPolicy`: autoActive, backofficeApproval, conditionalApproval.
8. `bankingRequiredBefore`: approval, firstPayment, never.
9. `selfieRequired`: true/false/conditional.
10. `trainingRequired`: true/false/skipAllowed.

Feature flags:

1. `firstAccessEnabled`
2. `openRegistrationEnabled`
3. `otpRequired`
4. `selfieRequired`
5. `bankingPixEnabled`
6. `microphonePermissionEnabled`
7. `biometricOptInEnabled`
8. `trainingRequired`
9. `legacyOnboardingFallbackEnabled`

Pontos de extensao:

1. Novo app adiciona `BrandManifest` e `OnboardingProfile`.
2. Cada modulo declara entradas, saidas, dependencias e status de conclusao.
3. Backend retorna pendencias de onboarding por usuario.
4. Mobile persiste progresso local e sincroniza conclusao no backend.
5. Backoffice define politica por tenant/app quando aplicavel, sem mudar bundle id/app de loja.

## Recomendacao Executiva

1. Substituir o onboarding unico por arquitetura modular white label.
2. Tratar Kaptur e Compass como apps distintos, nao como tenants em uma mesma jornada.
3. Manter core compartilhado para reduzir custo: login, OTP, selfie, termos, permissoes, tutorial e aguardando aprovacao.
4. Implementar Compass primeiro com primeiro acesso seguro para usuario provisionado.
5. Usar CPF/data nascimento apenas para lookup, nunca como autenticacao final.
6. Exigir OTP para ativacao e criacao de senha.
7. Adaptar Kaptur para cadastro marketplace completo com PF/MEI/PJ.
8. Remover dados bancarios do caminho Compass inicial.
9. Pedir permissoes no momento de valor, nao todas no inicio.
10. Tornar microfone condicional a recurso de voz habilitado.
11. Criar `OnboardingFlowResolver` por brand/productMode.
12. Preservar usuarios antigos e migrar novos por feature flag.
13. Medir abandono por etapa antes de desligar fluxo legado.
14. Usar backoffice para aprovar Kaptur e para resolver excecoes de primeiro acesso Compass.
15. Preparar o mesmo modelo para novos apps white label sem multiplicar telas hardcoded.
