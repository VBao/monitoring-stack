@echo off
REM Slack Alerts Setup Script for Windows
REM Interactive setup for Slack webhook integration

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "SERVER_DIR=%SCRIPT_DIR%.."
set "TEMPLATES_DIR=%SCRIPT_DIR%alerting-templates"
set "PROVISIONING_DIR=%SERVER_DIR%\stack\grafana\provisioning\alerting"

echo ================================================
echo    Slack Alerts Setup for Monitoring Stack
echo ================================================
echo.

REM Verify templates exist
if not exist "%TEMPLATES_DIR%\slack-contact-point.yaml" (
    echo Error: Template files not found in %TEMPLATES_DIR%
    echo Expected: slack-contact-point.yaml and notification-policies.yaml
    exit /b 1
)

REM Work from server directory
cd /d "%SERVER_DIR%"

REM Check if .env exists
if exist .env (
    echo Warning: .env file already exists
    set /p OVERWRITE="Do you want to update it? (y/N): "
    if /i not "!OVERWRITE!"=="y" (
        echo Setup cancelled.
        exit /b 0
    )
    copy .env ".env.backup.%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%" >nul
    echo [OK] Backed up existing .env file
)

REM Create .env from template
if exist .env.example (
    copy .env.example .env >nul
    echo [OK] Created .env file from template
) else (
    echo Warning: .env.example not found, creating new .env
    type nul > .env
)

echo.
echo Step 1: Slack Webhook Setup
echo -----------------------------------
echo.
echo To get your Slack webhook URL:
echo   1. Go to https://api.slack.com/apps
echo   2. Click 'Create New App' -^> 'From scratch'
echo   3. Name it 'Monitoring Alerts' and select your workspace
echo   4. Click 'Incoming Webhooks' and toggle it ON
echo   5. Click 'Add New Webhook to Workspace'
echo   6. Select your alert channel (e.g., #monitoring-alerts)
echo   7. Copy the webhook URL
echo.

pause

echo.
set /p WEBHOOK_URL="Paste your Slack webhook URL for error alerts: "

if "!WEBHOOK_URL!"=="" (
    echo Error: Webhook URL is required for Slack alerting.
    echo Set SLACK_WEBHOOK_URL manually in .env and re-run this script.
    exit /b 1
)

REM Update SLACK_WEBHOOK_URL in .env
findstr /v "^SLACK_WEBHOOK_URL=" .env > .env.tmp 2>nul
echo SLACK_WEBHOOK_URL=!WEBHOOK_URL!>> .env.tmp
move /y .env.tmp .env >nul
echo [OK] Webhook URL configured

echo.
set /p CRITICAL="Do you want a separate webhook for CRITICAL alerts? (y/N): "
if /i "!CRITICAL!"=="y" (
    set /p CRITICAL_WEBHOOK_URL="Paste your Slack webhook URL for critical alerts: "
    if not "!CRITICAL_WEBHOOK_URL!"=="" (
        findstr /v "^SLACK_WEBHOOK_URL_CRITICAL=" .env > .env.tmp 2>nul
        echo SLACK_WEBHOOK_URL_CRITICAL=!CRITICAL_WEBHOOK_URL!>> .env.tmp
        move /y .env.tmp .env >nul
        echo [OK] Critical webhook URL configured
    )
) else (
    REM Use same webhook for critical
    if not "!WEBHOOK_URL!"=="" (
        findstr /v "^SLACK_WEBHOOK_URL_CRITICAL=" .env > .env.tmp 2>nul
        echo SLACK_WEBHOOK_URL_CRITICAL=!WEBHOOK_URL!>> .env.tmp
        move /y .env.tmp .env >nul
    )
)

echo.
echo Step 2: Optional Configuration
echo -----------------------------------
echo.

set /p ADMIN_PASS="Set Grafana admin password (default: admin): "
if not "!ADMIN_PASS!"=="" (
    findstr /v "^GF_SECURITY_ADMIN_PASSWORD=" .env > .env.tmp 2>nul
    echo GF_SECURITY_ADMIN_PASSWORD=!ADMIN_PASS!>> .env.tmp
    move /y .env.tmp .env >nul
)

set /p SERVER_URL="Set Grafana server URL (default: http://localhost:3002): "
if not "!SERVER_URL!"=="" (
    findstr /v "^GF_SERVER_ROOT_URL=" .env > .env.tmp 2>nul
    echo GF_SERVER_ROOT_URL=!SERVER_URL!>> .env.tmp
    move /y .env.tmp .env >nul
)

echo.
echo Step 3: Install Slack Alerting Config
echo -----------------------------------
echo.

REM Copy templates to provisioning directory
copy /y "%TEMPLATES_DIR%\slack-contact-point.yaml" "%PROVISIONING_DIR%\slack-contact-point.yaml" >nul
copy /y "%TEMPLATES_DIR%\notification-policies.yaml" "%PROVISIONING_DIR%\notification-policies.yaml" >nul
echo [OK] Copied Slack contact point config to provisioning
echo [OK] Copied notification policies to provisioning

echo.
echo Step 4: Verify Configuration
echo -----------------------------------
echo.
echo Your .env file contains:
findstr /b "SLACK_WEBHOOK_URL GF_" .env 2>nul

echo.
echo Step 5: Restart Grafana
echo -----------------------------------
echo.

set /p RESTART="Do you want to restart Grafana now? (Y/n): "
if /i not "!RESTART!"=="n" (
    echo Restarting Grafana...
    docker-compose restart grafana

    echo.
    echo Waiting for Grafana to start...
    timeout /t 5 /nobreak >nul

    docker ps | findstr grafana >nul
    if !errorlevel! equ 0 (
        echo [OK] Grafana restarted successfully
    ) else (
        echo Warning: Grafana may not be running. Check with: docker-compose logs grafana
    )
)

echo.
echo ================================================
echo    Setup Complete!
echo ================================================
echo.
echo [OK] Slack webhook configured
echo [OK] Alerting config provisioned
echo [OK] Notification policies provisioned
echo.
echo Next steps:
echo   1. Open Grafana: http://localhost:3002
echo   2. Go to Alerting -^> Contact points
echo   3. Find 'slack-errors' and click 'Test' to verify
echo   4. Check your Slack channel for the test message
echo.
echo To disable Slack alerting later, re-run or see:
echo   quick-start\SLACK-ALERTS-README.md
echo.
pause
