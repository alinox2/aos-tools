@echo off
REM AOS-Tools Windows Build Script (Batch)
REM Usage: build-windows.bat [OpenSSL_PATH]

setlocal enabledelayedexpansion

echo === AOS-Tools Windows Build Script ===
echo.

REM Get OpenSSL path from argument or use default
if "%~1"=="" (
    set OPENSSL_PATH=C:\OpenSSL
) else (
    set OPENSSL_PATH=%~1
)

REM Verify tools
echo [1/4] Checking environment...
where gcc >nul 2>&1
if errorlevel 1 (
    echo Error: gcc not found. Install MinGW-w64 from https://www.mingw-w64.org/
    exit /b 1
)

where make >nul 2>&1
if errorlevel 1 (
    echo Error: make not found. Install from http://gnuwin32.sourceforge.net/
    exit /b 1
)

where ar >nul 2>&1
if errorlevel 1 (
    echo Error: ar not found. Ensure MinGW-w64 binutils is installed
    exit /b 1
)

echo - gcc: OK
echo - make: OK
echo - ar: OK
echo.

REM Check OpenSSL
echo [2/4] Checking OpenSSL...
if not exist "%OPENSSL_PATH%\include\openssl\ssl.h" (
    echo Error: OpenSSL not found at "%OPENSSL_PATH%"
    echo Install OpenSSL: https://slproweb.com/products/Win32OpenSSL.html
    echo Or use: build-windows.bat "C:\path\to\OpenSSL"
    exit /b 1
)
echo - Found at: %OPENSSL_PATH%
echo.

REM Create build directory
if not exist build\libaos mkdir build\libaos
if not exist build\tools mkdir build\tools

REM Build libaos
echo [3/4] Building libaos...
cd libaos
echo   Compiling...

set CFLAGS=-Wall -O2 -I%OPENSSL_PATH%\include
set LDFLAGS=-L%OPENSSL_PATH%\lib -lssl -lcrypto -lws2_32 -static

for %%f in (aos.c block.c crypto.c md5.c flash.c) do (
    echo   %%f...
    gcc %CFLAGS% -c %%f
    if errorlevel 1 (
        echo Error compiling %%f
        cd ..
        exit /b 1
    )
)

echo   Creating library...
ar rcs libaos.a aos.o block.o crypto.o md5.o flash.o
if errorlevel 1 (
    echo Error creating libaos.a
    cd ..
    exit /b 1
)

copy libaos.a ..\build\libaos\ >nul 2>&1
echo - OK
cd ..
echo.

REM Build tools
echo [4/4] Building tools...
cd tools

for %%t in (aos-info aos-unpack aos-fix aos-repack) do (
    echo   Building %%t...
    
    gcc %CFLAGS% -I../libaos -c %%t.c
    if errorlevel 1 (
        echo Error compiling %%t.c
        cd ..
        exit /b 1
    )
    
    gcc %CFLAGS% -I../libaos -c files.c
    gcc %CFLAGS% -I../libaos -c mpk.c
    
    gcc -o %%t.exe %%t.o files.o mpk.o %LDFLAGS% -L../build/libaos -laos
    if errorlevel 1 (
        echo Error linking %%t.exe
        cd ..
        exit /b 1
    )
    
    copy %%t.exe ..\build\tools\ >nul 2>&1
    echo   - OK
)

cd ..

REM Summary
echo.
echo === Build Summary ===
if exist build\tools\aos-info.exe (
    echo Build completed successfully!
    echo.
    echo Binaries in: build\tools\
    dir /b build\tools\*.exe
    echo.
    echo To use:
    echo   build\tools\aos-info.exe --help
) else (
    echo Build failed - no binaries generated
    exit /b 1
)

echo.
endlocal
