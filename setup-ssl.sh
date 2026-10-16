#!/bin/bash
# ==============================================================================
# RETIVA - Automated Free Let's Encrypt SSL HTTPS Setup
# Domain: hackathon.mataceria.my.id
# ==============================================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DOMAIN="hackathon.mataceria.my.id"

echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}   🔐 RETIVA - SETUP SSL HTTPS (Let's Encrypt)                 ${NC}"
echo -e "${CYAN}   Domain: https://${DOMAIN}                                   ${NC}"
echo -e "${CYAN}================================================================${NC}"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Jalankan script ini sebagai root: sudo bash setup-ssl.sh${NC}"
  exit 1
fi

# 1. Install certbot if not present
echo -e "\n${YELLOW}[1/4] Memeriksa instalasi Certbot di VPS...${NC}"
if ! command -v certbot &> /dev/null; then
  echo -e "${YELLOW}Menginstal Certbot...${NC}"
  apt-get update -y && apt-get install -y certbot
else
  echo -e "${GREEN}✅ Certbot sudah terpasang.${NC}"
fi

# 2. Stop Nginx container temporarily for standalone ACME verification
echo -e "\n${YELLOW}[2/4] Menghentikan Nginx sementara untuk verifikasi port 80...${NC}"
docker compose -f docker-compose.prod.yml stop nginx || true

# 3. Generate Let's Encrypt certificate
echo -e "\n${YELLOW}[3/4] Menerbitkan sertifikat SSL resmi untuk ${DOMAIN}...${NC}"
certbot certonly --standalone \
  -d "${DOMAIN}" \
  --agree-tos \
  --register-unsafely-without-email \
  --non-interactive \
  --preferred-challenges http

# 4. Activate Nginx SSL configuration
echo -e "\n${YELLOW}[4/4] Mengaktifkan konfigurasi HTTPS Nginx...${NC}"
cp nginx/conf.d/ssl.conf.template nginx/conf.d/ssl.conf

# Update APP_URL, NEXTAUTH_URL, and NEXT_PUBLIC_APP_URL in .env.production if it exists
if [ -f ".env.production" ]; then
  sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env.production
  if grep -q "NEXTAUTH_URL" .env.production; then
    sed -i "s|NEXTAUTH_URL=.*|NEXTAUTH_URL=https://${DOMAIN}|g" .env.production
  else
    echo "NEXTAUTH_URL=https://${DOMAIN}" >> .env.production
  fi
  if grep -q "NEXT_PUBLIC_APP_URL" .env.production; then
    sed -i "s|NEXT_PUBLIC_APP_URL=.*|NEXT_PUBLIC_APP_URL=https://${DOMAIN}|g" .env.production
  else
    echo "NEXT_PUBLIC_APP_URL=https://${DOMAIN}" >> .env.production
  fi
fi

# Recreate web and nginx with updated domain and SSL certificates
docker compose -f docker-compose.prod.yml up -d web nginx

echo -e "\n${CYAN}================================================================${NC}"
echo -e "${GREEN}🎉 SSL HTTPS BERHASIL DIAKTIFKAN DENGAN SEMPURNA!               ${NC}"
echo -e "${CYAN}================================================================${NC}"
echo -e "🌐 URL Web Dashboard & API : https://${DOMAIN}"
echo -e "🩺 Healthcheck Endpoint    : https://${DOMAIN}/api/v1/health"
echo -e "🖼️ S3 Media Storage       : https://${DOMAIN}/storage/"
echo -e "${CYAN}================================================================${NC}"
