@echo off
REM Prepara el proyecto en Windows: genera android/ e ios/, aplica permisos
REM y descarga dependencias. Uso: doble clic o ejecutar setup.bat
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter no esta en el PATH. Instalalo desde https://docs.flutter.dev/get-started/install
  exit /b 1
)

set "BACKUP=%TEMP%\bitacora_backup"
if exist "%BACKUP%" rmdir /s /q "%BACKUP%"
mkdir "%BACKUP%"
xcopy lib "%BACKUP%\lib" /e /i /q >nul
xcopy test "%BACKUP%\test" /e /i /q >nul
copy pubspec.yaml "%BACKUP%\pubspec.yaml" >nul

call flutter create --project-name bitacora_campo --org com.example --platforms android,ios .

rmdir /s /q lib
rmdir /s /q test
xcopy "%BACKUP%\lib" lib /e /i /q >nul
xcopy "%BACKUP%\test" test /e /i /q >nul
copy /y "%BACKUP%\pubspec.yaml" pubspec.yaml >nul
rmdir /s /q "%BACKUP%"

call dart tool\configure_platforms.dart
call flutter pub get

echo.
echo Listo. Conecta un dispositivo y ejecuta:  flutter run
