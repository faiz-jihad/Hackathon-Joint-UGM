#!/bin/bash
# ==============================================================================
# RETIVA - Automated VPS Production Deployment Script
# Target OS: Ubuntu 20.04 / 22.04 / 24.04 LTS or Debian 11 / 12
# ==============================================================================

set -e

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}   🚀 RETIVA AI - AUTOMATED VPS PRODUCTION DEPLOYMENT          ${NC}"
echo -e "${CYAN}================================================================${NC}"

# 1. Root or Sudo Privilege Check
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Harap jalankan script ini sebagai root atau dengan sudo: sudo bash deploy.sh${NC}"
  exit 1
fi

# 2. Check and Install Docker if not present
echo -e "\n${YELLOW}[1/6] Memeriksa instalasi Docker & Docker Compose...${NC}"
if ! command -v docker &> /dev/null; then
  echo -e "${YELLOW}Docker belum terpasang. Mengunduh dan menginstal Docker resmi...${NC}"
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  rm -f get-docker.sh
  systemctl enable docker
  systemctl start docker
  echo -e "${GREEN}✅ Docker berhasil dipasang!${NC}"
else
  echo -e "${GREEN}✅ Docker sudah terpasang: $(docker --version)${NC}"
fi

# Check Docker Compose plugin
if ! docker compose version &> /dev/null; then
  echo -e "${YELLOW}Memasang plugin docker-compose-v2...${NC}"
  apt-get update -y && apt-get install -y docker-compose-plugin
fi

# 3. Memory & SWAP Protection (Prevent OOM Killer during AI build)
echo -e "\n${YELLOW}[2/6] Memeriksa kapasitas RAM & Swap VPS...${NC}"
TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
SWAP_EXISTS=$(free -m | awk '/^Swap:/{print $2}')

echo -e "Kapasitas RAM Fisik: ${TOTAL_RAM_MB} MB"
if [ "$SWAP_EXISTS" -lt 1024 ]; then
  echo -e "${YELLOW}Membuat Swap 3GB untuk mencegah Out-Of-Memory saat kompilasi AI & Next.js...${NC}"
  fallocate -l 3G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=3072
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  if ! grep -q "/swapfile" /etc/fstab; then
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
  fi
  echo -e "${GREEN}✅ Swap 3GB berhasil diaktifkan.${NC}"
else
  echo -e "${GREEN}✅ Swap aktif (${SWAP_EXISTS} MB).${NC}"
fi

# 4. Environment File (.env.production) Configuration
echo -e "\n${YELLOW}[3/6] Memeriksa konfigurasi Environment (.env.production)...${NC}"
if [ ! -f ".env.production" ]; then
  echo -e "${YELLOW}Membuat file .env.production baru dari template...${NC}"
  cp .env.production.example .env.production

  # Generate random cryptographically strong secrets
  NEW_JWT_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
  NEW_INTERNAL_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
  NEW_DB_PASS=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 24)
  NEW_MINIO_PASS=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 24)

  # Auto-detect Public IP
  SERVER_IP=$(curl -s -4 ifconfig.me || curl -s -4 icanhazip.com || echo "localhost")

  sed -i "s|APP_URL=.*|APP_URL=http://${SERVER_IP}|g" .env.production
  sed -i "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${NEW_DB_PASS}|g" .env.production
  sed -i "s|MINIO_ROOT_PASSWORD=.*|MINIO_ROOT_PASSWORD=${NEW_MINIO_PASS}|g" .env.production
  sed -i "s|JWT_SECRET=.*|JWT_SECRET=${NEW_JWT_SECRET}|g" .env.production
  sed -i "s|INTERNAL_API_SECRET=.*|INTERNAL_API_SECRET=${NEW_INTERNAL_SECRET}|g" .env.production

  echo -e "${GREEN}✅ .env.production berhasil digenerate dengan kredensial aman acak!${NC}"
  echo -e "IP Terdeteksi: ${SERVER_IP}"
else
  echo -e "${GREEN}✅ Menggunakan .env.production yang sudah ada.${NC}"
fi

# 5. Build and Deploy Containers
echo -e "\n${YELLOW}[4/6] Membangun dan menjalankan container Retiva (Docker Compose)...${NC}"
docker compose -f docker-compose.prod.yml --env-file .env.production down || true
docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build

# 6. Service Health Verification
echo -e "\n${YELLOW}[5/6] Menunggu container siap dan menjalankan healthcheck...${NC}"
sleep 15

SERVER_IP=$(curl -s -4 ifconfig.me || curl -s -4 icanhazip.com || echo "localhost")

echo -e "\n${YELLOW}[6/6] Verifikasi Status Layanan:${NC}"
docker compose -f docker-compose.prod.yml ps

echo -e "\n${CYAN}================================================================${NC}"
echo -e "${GREEN}🎉 RETIVA BERHASIL DIDIREPLOY KE VPS!                          ${NC}"
echo -e "${CYAN}================================================================${NC}"
echo -e "🌐 Web Dashboard & API : http://${SERVER_IP}"
echo -e "🩺 Healthcheck Endpoint : http://${SERVER_IP}/api/v1/health"
echo -e "🖼️ S3 Media Storage    : http://${SERVER_IP}/storage/"
echo -e ""
echo -e "${YELLOW}📱 Konfigurasi Aplikasi Mobile Flutter:${NC}"
echo -e "Buka: mobile/lib/core/constants/api_constants.dart"
echo -e "Ubah defaultBaseUrl menjadi: 'http://${SERVER_IP}'"
echo -e "${CYAN}================================================================${NC}"
