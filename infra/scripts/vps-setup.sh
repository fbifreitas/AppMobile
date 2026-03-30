#!/usr/bin/env bash
# Setup inicial da VPS Hostinger (Ubuntu 22.04/24.04)
# Uso: sudo bash vps-setup.sh [URL_DO_REPOSITORIO_GIT]
set -euo pipefail

REPO_URL="${1:-}"
APP_DIR="/opt/backoffice"

if [[ $EUID -ne 0 ]]; then
  echo "Execute como root: sudo bash vps-setup.sh"
  exit 1
fi

echo "==> [1/7] Atualizando pacotes..."
apt-get update -q
apt-get upgrade -y -q

echo "==> [2/7] Instalando dependencias base..."
apt-get install -y -q curl git ufw certbot

echo "==> [3/7] Instalando Docker..."
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sh
fi

echo "==> [4/7] Instalando Docker Compose plugin..."
apt-get install -y -q docker-compose-plugin

echo "==> [5/7] Configurando firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw --force enable

echo "==> [6/7] Criando estrutura de diretorios..."
mkdir -p "$APP_DIR/infra/nginx/certs"
mkdir -p "$APP_DIR/infra/data/uploads"

if [[ -n "$REPO_URL" ]]; then
  echo "==> Clonando repositorio..."
  if [[ -d "$APP_DIR/.git" ]]; then
    git -C "$APP_DIR" pull origin main
  else
    git clone "$REPO_URL" "$APP_DIR"
  fi
fi

echo "==> [7/7] Setup concluido!"
echo ""
echo "Proximos passos:"
echo ""
echo "1. Configure o arquivo de variaveis de ambiente:"
echo "   cp $APP_DIR/infra/.env.example $APP_DIR/infra/.env"
echo "   nano $APP_DIR/infra/.env"
echo ""
echo "2. (Opcional) Configure SSL gratuito com Certbot:"
echo "   certbot certonly --standalone -d seudominio.com"
echo "   cp /etc/letsencrypt/live/seudominio.com/fullchain.pem $APP_DIR/infra/nginx/certs/"
echo "   cp /etc/letsencrypt/live/seudominio.com/privkey.pem   $APP_DIR/infra/nginx/certs/"
echo "   # Depois descomente o bloco HTTPS em infra/nginx/nginx.conf"
echo ""
echo "3. Suba todos os servicos:"
echo "   cd $APP_DIR"
echo "   docker compose -f infra/docker-compose.yml up -d"
echo ""
echo "4. Verifique os logs:"
echo "   docker compose -f infra/docker-compose.yml logs -f"
