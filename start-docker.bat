@echo off
chcp 65001 > nul
echo =====================================================================
echo  🏥 RETIVA (Retinopathy Early-detection AI) - One-Click Docker Runner
echo =====================================================================
echo.

if not exist "web\.env" (
    echo [INFO] Menyalin konfigurasi .env.example ke web\.env...
    copy .env.example web\.env > nul
    echo [OK] web\.env berhasil dibuat!
)

echo [INFO] Menjalankan seluruh layanan kontainer (PostgreSQL, MinIO, AI, Web)...
docker compose up -d

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Gagal menjalankan Docker Compose.
    echo Pastikan aplikasi Docker Desktop sudah dibuka dan statusnya "Engine running".
    echo.
    pause
    exit /b %errorlevel%
)

echo.
echo =====================================================================
echo  ✅ Semua layanan RETIVA berhasil diaktifkan!
echo =====================================================================
echo.
docker compose ps
echo.
echo  🌐 Web Application:       http://localhost:3000
echo  🤖 AI Microservice Docs: http://localhost:8003/docs
echo  🗄️ MinIO S3 Console:     http://localhost:9001 (minioadmin / minioadminpassword)
echo.
echo Tekan sembarang tombol untuk memantau log kontainer secara live (Ctrl+C untuk keluar)...
pause
docker compose logs -f
