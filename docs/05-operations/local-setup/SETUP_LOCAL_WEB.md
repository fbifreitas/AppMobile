> [NOTA DE ESCOPO - OPERACIONAL ATIVO]
> Este e um documento operacional ativo.
> Este documento nao substitui a direcao arquitetural V2 corporativa do repositorio.
> Deve ser lido em conjunto com README.md, GEMINI.md, .github/copilot-instructions.md e os documentos ativos da V2 em docs/.

# Setup Local - Web Backoffice

Atualizado em: 2026-03-29

## Escopo rapido

- Documento operacional ativo de setup web/backoffice.
- Nao substitui arquitetura V2.
- Para troubleshooting de retomada, ler: `docs/05-operations/runbooks/PONTO_RESTAURACAO_AMBIENTE_LOCAL.md`.

## Comandos oficiais

```powershell
cd apps/web-backoffice
npm install
npm run dev
```

## Verificacao de sucesso

1. App acessivel em `http://localhost:3000`.
2. Lint, teste e build executam sem erro:

```powershell
npm run lint
npm run test
npm run build
```

## Troubleshooting curto

1. Porta ocupada: `npm run dev -- -p 3001`
2. Dependencias quebradas: remover `node_modules`, remover `package-lock.json`, executar `npm install`
3. Build sem memoria: `setx NODE_OPTIONS "--max-old-space-size=2048"`

## Requisitos minimos recomendados
Para sua maquina (i5-3230M, 8 GB RAM, SSD 240 GB), o projeto roda bem para desenvolvimento inicial com:
1. Windows 10/11 64 bits.
2. Node.js 20 LTS (x64).
3. npm 10 (vem com Node 20).
4. Git instalado e configurado.
5. VS Code com extensoes de TypeScript/ESLint.

## Requisitos opcionais (melhoram produtividade)
1. pnpm (mais rapido que npm em installs repetidos).
2. NVM for Windows para trocar versao do Node sem dor.
3. Docker Desktop (somente quando precisar simular servicos externos).

## Limites praticos para seu hardware
1. Evite abrir Flutter + Next build pesado ao mesmo tempo.
2. Rode apenas 1 app principal por vez (mobile ou web) durante desenvolvimento.
3. Mantenha navegador com poucas abas para reduzir consumo de RAM.
4. Feche processos de indexacao durante build (OneDrive/antivirus em full scan).

## Passo a passo de primeira execucao
Na raiz do repositorio:

```powershell
cd apps/web-backoffice
npm install
npm run dev
```

Acesse:
1. http://localhost:3000
2. Health check: http://localhost:3000/health

## Scripts disponiveis
1. `npm run dev`: sobe o servidor local.
2. `npm run lint`: valida padrao de codigo.
3. `npm run test`: executa smoke test.
4. `npm run build`: gera build de producao.
5. `npm run start`: sobe app em modo producao local.

## Variaveis de ambiente (quando integrar backend)
Crie `apps/web-backoffice/.env.local` com:

```env
NEXT_PUBLIC_API_BASE_URL=http://localhost:8080
NEXT_PUBLIC_TENANT_DEFAULT=default
```

## Troubleshooting rapido
1. Erro de ExecutionPolicy ao usar npm no PowerShell:
```powershell
npm.cmd install
npm.cmd run dev
```

1. Erro de memoria no build:
```powershell
setx NODE_OPTIONS "--max-old-space-size=2048"
```
Abra novo terminal e rode build novamente.

2. Porta 3000 ocupada:
```powershell
npm run dev -- -p 3001
```

3. Dependencias quebradas apos troca de branch:
```powershell
Remove-Item -Recurse -Force node_modules
Remove-Item -Force package-lock.json
npm install
```
