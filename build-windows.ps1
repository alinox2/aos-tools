#!/usr/bin/env pwsh

# AOS-Tools Windows Build Script
# Usage: .\build-windows.ps1 [-OpenSSLPath "C:\OpenSSL"] [-BuildDir "build"]

param(
    [string]$OpenSSLPath = "C:\OpenSSL",
    [string]$BuildDir = "build",
    [string]$Configuration = "Release",
    [ValidateSet("MinGW", "MSVC")][string]$Compiler = "MinGW"
)

$ErrorActionPreference = "Stop"

Write-Host "=== AOS-Tools Windows Build Script ===" -ForegroundColor Green
Write-Host ""

# Check environment
Write-Host "[1/4] Checking environment..." -ForegroundColor Cyan
$missing = @()

if (!(Get-Command gcc -ErrorAction SilentlyContinue)) {
    $missing += "gcc (MinGW)"
}
if (!(Get-Command make -ErrorAction SilentlyContinue)) {
    $missing += "make"
}
if (!(Get-Command ar -ErrorAction SilentlyContinue)) {
    $missing += "ar (from binutils)"
}

if ($missing.Count -gt 0) {
    Write-Host "❌ Missing tools: $($missing -join ', ')" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install MinGW-w64:" -ForegroundColor Yellow
    Write-Host "  https://www.mingw-w64.org/"
    Write-Host ""
    exit 1
}

Write-Host "✓ All required tools found" -ForegroundColor Green

# Check OpenSSL
Write-Host ""
Write-Host "[2/4] Checking OpenSSL..." -ForegroundColor Cyan
if (!(Test-Path "$OpenSSLPath\include\openssl\ssl.h")) {
    Write-Host "❌ OpenSSL not found at: $OpenSSLPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install OpenSSL:" -ForegroundColor Yellow
    Write-Host "  1. Download: https://slproweb.com/products/Win32OpenSSL.html"
    Write-Host "  2. Or use vcpkg: vcpkg install openssl:x64-windows-static"
    Write-Host "  3. Set path: .\build-windows.ps1 -OpenSSLPath 'C:\OpenSSL'"
    Write-Host ""
    exit 1
}

Write-Host "✓ OpenSSL found at: $OpenSSLPath" -ForegroundColor Green

# Create build directory
Write-Host ""
Write-Host "[3/4] Building libaos..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "$BuildDir\libaos" | Out-Null
New-Item -ItemType Directory -Force -Path "$BuildDir\tools" | Out-Null

# Build libaos
Push-Location libaos
try {
    $cflags = "-Wall -O2 -I$OpenSSLPath\include"
    $ldflags = "-L$OpenSSLPath\lib -lssl -lcrypto -lws2_32 -static"
    
    # Compile
    Write-Host "  Compiling source files..."
    $files = @("aos.c", "block.c", "crypto.c", "md5.c", "flash.c")
    foreach ($file in $files) {
        Write-Host "    $file..." -NoNewline
        & gcc $cflags -c $file 2>&1 | Where-Object { $_ -match "error" } | ForEach-Object {
            Write-Host ""
            Write-Host "    ❌ Error: $_" -ForegroundColor Red
        }
        if ($?) {
            Write-Host " ✓" -ForegroundColor Green
        }
    }
    
    # Create library
    Write-Host "  Creating static library..."
    & ar rcs libaos.a aos.o block.o crypto.o md5.o flash.o 2>&1
    if ($?) {
        Copy-Item libaos.a "..\$BuildDir\libaos\" -Force
        Write-Host "✓ libaos built successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create library" -ForegroundColor Red
    }
    
} finally {
    Pop-Location
}

# Build tools
Write-Host ""
Write-Host "[4/4] Building tools..." -ForegroundColor Cyan
Push-Location tools
try {
    $cflags = "-Wall -O2 -I../libaos -I$OpenSSLPath\include"
    $ldflags = "-L../libaos -laos -L$OpenSSLPath\lib -lssl -lcrypto -lws2_32 -static"
    
    # Build each tool
    $tools = @("aos-info", "aos-unpack", "aos-fix", "aos-repack")
    $common_sources = @("files.c", "mpk.c")
    
    foreach ($tool in $tools) {
        Write-Host "  Building $tool..." -NoNewline
        
        # Compile sources
        & gcc $cflags -c "${tool}.c" $common_sources 2>&1 | Where-Object { $_ -match "error" } | ForEach-Object {
            Write-Host ""
            Write-Host "    ❌ $_" -ForegroundColor Red
        }
        
        if ($?) {
            # Link
            & gcc -o "${tool}.exe" "${tool}.o" files.o mpk.o $ldflags 2>&1 | Where-Object { $_ -match "error" } | ForEach-Object {
                Write-Host ""
                Write-Host "    ❌ $_" -ForegroundColor Red
            }
            
            if ($?) {
                Copy-Item "${tool}.exe" "..\$BuildDir\tools\" -Force
                Write-Host " ✓" -ForegroundColor Green
            } else {
                Write-Host " ❌" -ForegroundColor Red
            }
        } else {
            Write-Host " ❌" -ForegroundColor Red
        }
    }
    
} finally {
    Pop-Location
}

# Summary
Write-Host ""
Write-Host "=== Build Summary ===" -ForegroundColor Green
if (Test-Path "$BuildDir\tools" -PathType Container) {
    $files = Get-ChildItem "$BuildDir\tools" -Filter "*.exe" 2>/dev/null
    if ($files.Count -gt 0) {
        Write-Host "✓ Build completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Binaries:" -ForegroundColor Cyan
        $files | ForEach-Object {
            $size = (Get-Item $_.FullName).Length
            Write-Host "  $($_.Name) ($([math]::Round($size/1KB, 2)) KB)"
        }
        Write-Host ""
        Write-Host "Location: .\$BuildDir\" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "To use:" -ForegroundColor Yellow
        Write-Host "  .\$BuildDir\tools\aos-info.exe --help"
    } else {
        Write-Host "⚠️  No binaries generated" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Build directory not found" -ForegroundColor Red
}
