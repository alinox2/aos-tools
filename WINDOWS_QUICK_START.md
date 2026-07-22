# Windows Build Quick Start

## Pre-Built Binaries (Easiest)

Download pre-built Windows binaries from the [Releases](https://github.com/EiNSTeiN-/aos-tools/releases) page (when available).

## Build from Source on Windows

### Step 1: Install Tools (5 minutes)

#### Option A: Using Chocolatey (Recommended)

```powershell
# Install Chocolatey first if you don't have it
# Then run in PowerShell as Administrator:

choco install mingw make
```

#### Option B: Manual Installation

1. **MinGW-w64** (C compiler)
   - Download: https://www.mingw-w64.org/downloads/
   - Run installer, choose x86_64 architecture
   - Add to PATH: `C:\mingw64\bin`

2. **Make** (Build tool)
   - Download: http://gnuwin32.sourceforge.net/packages/make.htm
   - Or via Chocolatey: `choco install make`

3. **OpenSSL** (Cryptography library)
   - **Option 1**: Pre-built binaries https://slproweb.com/products/Win32OpenSSL.html
     - Download: `Win64 OpenSSL v1.1.1` or `Win64 OpenSSL v3.x`
     - Install to: `C:\OpenSSL`
   - **Option 2**: Visual C++ Build Tools required
     ```powershell
     choco install vcbuildtools
     ```

### Step 2: Build (2 minutes)

#### Using PowerShell (Modern, Recommended)

```powershell
# Open PowerShell, navigate to project folder

cd C:\path\to\aos-tools

# Run build script
.\build-windows.ps1
```

**With custom OpenSSL path:**
```powershell
.\build-windows.ps1 -OpenSSLPath "C:\path\to\OpenSSL"
```

#### Using Command Prompt (Batch)

```cmd
cd C:\path\to\aos-tools

# Run batch script
build-windows.bat
```

**With custom OpenSSL path:**
```cmd
build-windows.bat "C:\path\to\OpenSSL"
```

#### Using Make (Advanced)

```powershell
# If you have MinGW and OpenSSL from Linux
make -f Makefile.mingw
```

### Step 3: Use the Binaries (Done!)

Compiled binaries are in `build\tools\`:

```powershell
# Show help
.\build\tools\aos-info.exe --help

# Example: Get info from AOS file
.\build\tools\aos-info.exe firmware.aos

# Unpack AOS file
.\build\tools\aos-unpack.exe firmware.aos output_dir\

# Repack AOS file
.\build\tools\aos-repack.exe input_dir\ firmware.aos
```

## Troubleshooting

### "gcc: command not found"
- **Fix**: Install MinGW-w64 and add to PATH
- **Verify**: Run `gcc --version` in PowerShell/CMD

### "make: command not found"
- **Fix**: Install GNU Make
- **Verify**: Run `make --version`

### "openssl/ssl.h: No such file or directory"
- **Fix**: Install OpenSSL development files
- **Verify**: Check if `C:\OpenSSL\include\openssl\ssl.h` exists
- **Alternative**: `.\build-windows.ps1 -OpenSSLPath "C:\correct\path"`

### Compilation errors about SSL or crypto
- **Fix**: Ensure OpenSSL is correctly installed
- **Troubleshoot**: 
  ```powershell
  dir "C:\OpenSSL\lib"  # Should contain libssl.a, libcrypto.a (or .lib files for MSVC)
  dir "C:\OpenSSL\include\openssl"  # Should contain ssl.h, crypto.h, etc
  ```

### "Permission denied" when running .exe
- **Fix**: Right-click file → Properties → Security → Unblock
- **Or**: Just run it from PowerShell/CMD

## Build from Linux for Windows

Cross-compile for Windows on Linux:

```bash
# Install MinGW cross-compiler
apt-get install mingw-w64

# Build
make -f Makefile.mingw CC=x86_64-w64-mingw32-gcc

# Binaries in: build/windows/release/
```

## Distributing Built Binaries

### Option 1: Static Build (Recommended)

Binaries are already statically linked, so you can distribute the `.exe` files directly:
- No additional dependencies needed
- Works on any Windows system
- File size: ~1-2 MB per tool

### Option 2: With DLLs (if built dynamically)

If you built with dynamic linking, include these files:
- `libssl-1_1.dll` or `libssl-*.dll` (OpenSSL)
- `libcrypto-1_1.dll` or `libcrypto-*.dll` (OpenSSL)

## Performance Tips

### Optimize Build Size
```powershell
# Remove debug symbols for smaller binaries
# In build script, change:
# $cflags = "-Wall -O2 -I$OpenSSLPath\include" to:
# $cflags = "-Wall -O3 -s -I$OpenSSLPath\include"  # -s removes symbols
```

### Build Speed
- Use pre-built OpenSSL instead of building from source
- Close other applications to free resources
- First build takes longer; subsequent builds are faster

## What Can Be Built for Windows

| Component | Status | Notes |
|-----------|--------|-------|
| libaos | ✅ | Fully portable, works on Windows |
| aos-info | ✅ | Works on Windows |
| aos-unpack | ✅ | Works on Windows |
| aos-fix | ✅ | Works on Windows |
| aos-repack | ✅ | Works on Windows |
| flash, mv, rm | ⚠️ | ARM target tools (for embedded devices) |
| insmod, rmmod | ❌ | Linux kernel only, can't build on Windows |

## WSL2 Alternative

If you have WSL2 on Windows, you can use the Linux build:

```bash
# In WSL2 terminal
cd /mnt/c/path/to/aos-tools
./build.sh
```

This gives you Linux binaries, but you can't run them directly in Windows CMD.

## Docker Alternative

Use Docker to build without installing dependencies:

```bash
# Build Docker image with build environment
docker build -t aos-tools-builder .

# Run build
docker run --rm -v %cd%:/src aos-tools-builder make -C /src -f Makefile.mingw
```

## Getting Help

1. Check [WINDOWS_BUILD.md](WINDOWS_BUILD.md) for detailed information
2. See [BUILD_NOTES.md](BUILD_NOTES.md) for general build issues
3. Check error messages carefully - they usually indicate what's missing
4. Verify all tools are installed: `gcc --version`, `make --version`

## Next Steps

- [x] Install tools
- [x] Run build script
- [ ] Test binaries: `.\build\tools\aos-info.exe --help`
- [ ] Use the tools to manipulate AOS files!

---

Need help? Read the detailed [WINDOWS_BUILD.md](WINDOWS_BUILD.md) guide for more information.
