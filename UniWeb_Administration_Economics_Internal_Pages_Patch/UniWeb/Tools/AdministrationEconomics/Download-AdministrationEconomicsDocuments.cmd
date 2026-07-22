@echo off
setlocal
chcp 65001 >nul

echo =============================================================
echo  UniWeb - تنزيل وثائق كلية الإدارة والاقتصاد
 echo =============================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Download-AdministrationEconomicsDocuments.ps1"
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if not "%EXIT_CODE%"=="0" (
    echo حدث خطأ أثناء تشغيل أداة التنزيل. راجع الرسائل أعلاه.
) else (
    echo انتهى تشغيل أداة التنزيل.
)
echo.
pause
exit /b %EXIT_CODE%
