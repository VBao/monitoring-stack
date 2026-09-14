@echo off
REM Start Host Monitoring Stack (Windows)
REM This script starts both the main monitoring stack and host monitoring extensions

echo ================================================
echo    Starting Host Monitoring Stack
echo ================================================

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)

REM Create monitoring network if it doesn't exist
docker network inspect monitoring >nul 2>&1
if %errorlevel% neq 0 (
    echo Creating monitoring network...
    docker network create monitoring
)

REM Start main monitoring stack
echo.
echo Starting main monitoring services...
docker-compose -f docker-compose.yml up -d

REM Wait for services to be ready
echo.
echo Waiting for core services to start...
timeout /t 5 /nobreak >nul

REM Start host monitoring extensions
echo.
echo Starting host monitoring services...
docker-compose -f docker-compose.host-monitoring.yml up -d

echo.
echo ================================================
echo    Host Monitoring Stack Started Successfully!
echo ================================================
echo.
echo Access the following services:
echo.
echo   Grafana:         http://localhost:3002
echo   Prometheus:      http://localhost:9090
echo   Alloy:           http://localhost:12345
echo   Node Exporter:   http://localhost:9100
echo   cAdvisor:        http://localhost:8080
echo   Promtail:        http://localhost:9080
echo   Pyroscope:       http://localhost:4040
echo.
echo Grafana credentials: admin / admin
echo.
echo To view logs:
echo   docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml logs -f
echo.
echo To stop all services:
echo   docker-compose -f docker-compose.yml -f docker-compose.host-monitoring.yml down
echo.
pause
