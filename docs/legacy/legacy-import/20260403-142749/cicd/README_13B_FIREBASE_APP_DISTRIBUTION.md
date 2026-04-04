# PACOTE 13B — Firebase App Distribution base

## Objetivo
Preparar o AppMobile para distribuir APKs de teste sem cabo USB usando Firebase App Distribution.

## Estratégia deste pacote
Este pacote **não altera** o workflow principal `Android CI`.
Ele adiciona um **workflow separado**, manual, para distribuição:
- mais seguro
- não interfere no CI que já está verde
- permite ativar a distribuição só quando o Firebase estiver configurado

## O que você ganha
- build debug na nuvem
- envio automático para testers internos
- instalação OTA por e-mail / app do Firebase App Tester
- base pronta sem depender de loja

## Fluxo que você vai usar
1. fazer push no Git
2. validar no workflow `Android CI`
3. abrir o workflow `Android Distribution`
4. clicar em **Run workflow**
5. informar notas da release, se quiser
6. o GitHub gera o APK e envia para o Firebase App Distribution

## O que ainda falta antes de usar
Você precisa:
- criar um projeto no Firebase
- cadastrar o app Android no Firebase
- criar um grupo de testers
- gerar `FIREBASE_APP_ID_ANDROID`
- gerar `FIREBASE_TOKEN`
- cadastrar os dois secrets no GitHub

## Resultado esperado
Depois da configuração, o build vai para o Firebase e os testers recebem acesso ao APK.
