@echo off
chcp 65001 > nul
echo =====================================================================
echo  🏥 RETIVA - Local Development Mode (Tanpa Docker / Ringan)
echo =====================================================================
echo.

if not exist "web\.env" (
    echo [INFO] Menyalin konfigurasi .env.example ke web\.env...
    copy .env.example web\.env > nul
    echo [OK] web\.env berhasil dibuat!
)

echo [1/2] Menjalankan FastAPI AI Service di jendela baru (Port 8003)...
start "RETIVA AI Service (8003)" cmd /k "cd ai-service && (if exist .venv\Scripts\activate.bat call .venv\Scripts\activate.bat) && python -m uvicorn app.main:app --host 127.0.0.1 --port 8003 --reload"

echo [2/2] Menjalankan Next.js Web di jendela baru (Port 3000)...
start "RETIVA Web (3000)" cmd /k "cd web && npm run dev"

echo.
echo =====================================================================
echo  ✅ Seluruh server lokal RETIVA sedang aktif di jendela terpisah!
echo =====================================================================
echo  🌐 Web Application:       http://localhost:3000
echo  🤖 AI Microservice Docs: http://localhost:8003/docs
echo.
echo Anda dapat menutup jendela terminal masing-masing untuk menghentikan server.
pause
