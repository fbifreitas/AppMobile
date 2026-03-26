@echo off
setlocal
set PACKAGE_DIR=%~dp0
set TARGET_DIR=%CD%

echo.
echo ================================
echo Instalador do pacote de camera overlay
echo ================================
echo Origem: %PACKAGE_DIR%
echo Destino: %TARGET_DIR%
echo.

if not exist "%TARGET_DIR%\pubspec.yaml" (
  echo ERRO: execute este .bat dentro da raiz do projeto Flutter.
  pause
  exit /b 1
)

if not exist "%TARGET_DIR%\backup_oai" mkdir "%TARGET_DIR%\backup_oai"

if exist "%TARGET_DIR%\lib\screens\checkin_screen.dart" copy /Y "%TARGET_DIR%\lib\screens\checkin_screen.dart" "%TARGET_DIR%\backup_oai\checkin_screen.dart.bak" >nul
if exist "%TARGET_DIR%\lib\screens\checkin_step2_screen.dart" copy /Y "%TARGET_DIR%\lib\screens\checkin_step2_screen.dart" "%TARGET_DIR%\backup_oai\checkin_step2_screen.dart.bak" >nul

xcopy /Y /I "%PACKAGE_DIR%lib\screens\overlay_camera_screen.dart" "%TARGET_DIR%\lib\screens\overlay_camera_screen.dart"
xcopy /Y /I "%PACKAGE_DIR%lib\screens\checkin_screen.dart" "%TARGET_DIR%\lib\screens\checkin_screen.dart"
xcopy /Y /I "%PACKAGE_DIR%lib\screens\checkin_step2_screen.dart" "%TARGET_DIR%\lib\screens\checkin_step2_screen.dart"

echo.
echo Arquivos copiados.
echo.
echo PASSOS MANUAIS AINDA NECESSARIOS:
echo 1. Adicionar camera:^0.11.3+1 no pubspec.yaml
echo 2. Rodar flutter pub get
echo 3. Rodar flutter analyze
echo 4. Rodar flutter run
echo.
pause