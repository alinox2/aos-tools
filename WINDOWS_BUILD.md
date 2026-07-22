# Windows Build Guide for AOS-Tools

## Platform Compatibility Analysis

### Component Status

| Component | Windows Support | Notes |
|-----------|-----------------|-------|
| **libaos** | ✅ Fully Portable | Pure crypto library, works on Windows |
| **tools** (aos-info, etc) | ✅ Mostly Portable | File I/O compatible, minimal changes needed |
| **target-tools** | ⚠️ Partial | `flash`, `mv`, `rm` can compile; `insmod`, `rmmod` are Linux-only |

### Component Details

#### libaos/ ✅
**Portability**: Fully portable
- Pure C with OpenSSL dependencies
- No platform-specific syscalls
- Requires: libssl-dev (Windows version)

#### tools/ ✅
**Portability**: Mostly portable
- `aos-info`, `aos-unpack`, `aos-fix`, `aos-repack`
- Uses standard C library + file I/O
- Minor changes needed: path separators (`\` vs `/`)

#### target-tools/ ⚠️
**Problematic tools**:
- ❌ `insmod.c`: Uses `asm/unistd.h` and `init_module()` syscall (Linux kernel only)
- ❌ `rmmod.c`: Uses `asm/unistd.h` and `delete_module()` syscall (Linux kernel only)
- ✅ `flash.c`, `mv.c`, `rm.c`: Can be compiled (designed as generic utilities)

**Note**: These target-tools are designed for Archos devices with ARM Linux. The kernel module tools (`insmod`/`rmmod`) have no Windows equivalent.

## Building on Windows

### Option 1: MinGW64 (Recommended)

#### Install Dependencies
1. **MinGW-w64**: https://www.mingw-w64.org/
   - Download: `mingw-w64-install.exe`
   - Installation path: `C:\mingw64`

2. **OpenSSL for Windows**: 
   ```powershell
   # Option A: Pre-built binaries
   # Download from: https://slproweb.com/products/Win32OpenSSL.html
   
   # Option B: Build from source
   cd C:\
   git clone https://github.com/openssl/openssl.git
   cd openssl
   perl Configure VC-WIN64A
   nmake
   nmake install
   ```

3. **GNU Make for Windows**
   ```powershell
   # Via Chocolatey
   choco install make
   
   # Or download: http://gnuwin32.sourceforge.net/packages/make.htm
   ```

#### Building libaos

```powershell
cd libaos

# Set environment
$env:CFLAGS = "-I'C:\OpenSSL\include' -static"
$env:LDFLAGS = "-L'C:\OpenSSL\lib' -lssl -lcrypto -lws2_32"

# Compile
gcc -c aos.c
gcc -c block.c
gcc -c crypto.c
gcc -c md5.c
gcc -c flash.c

# Create static library
ar rcs libaos.a aos.o block.o crypto.o md5.o flash.o
# Or using ranlib
# ranlib libaos.a
```

#### Building tools

```powershell
cd ..\tools

# Compile
gcc -c aos-info.c -I../libaos -c
gcc -c files.c
gcc -c mpk.c

# Link
gcc -o aos-info.exe aos-info.o files.o mpk.o -L../libaos -laos -lssl -lcrypto

gcc -c aos-unpack.c
gcc -o aos-unpack.exe aos-unpack.o files.o mpk.o -L../libaos -laos -lssl -lcrypto

gcc -c aos-fix.c
gcc -o aos-fix.exe aos-fix.o files.o mpk.o -L../libaos -laos -lssl -lcrypto

gcc -c aos-repack.c
gcc -o aos-repack.exe aos-repack.o files.o mpk.o -L../libaos -laos -lssl -lcrypto
```

### Option 2: Visual Studio Build

#### Setup MSVC Environment

1. **Install Visual Studio 2019+** with C/C++ workload
2. **Install OpenSSL via vcpkg**:
   ```powershell
   git clone https://github.com/Microsoft/vcpkg.git
   cd vcpkg
   .\bootstrap-vcpkg.bat
   .\vcpkg install openssl:x64-windows-static
   ```

3. **Create Visual Studio Project**
   - See `windows/aos-tools.vcxproj` (generated below)

### Option 3: Compile Directly on Windows (Manual)

**Manual Steps**:
```powershell
# 1. Navigate to libaos
cd libaos

# 2. Compile each file
cl /c aos.c /I "C:\OpenSSL\include"
cl /c block.c
cl /c crypto.c
cl /c md5.c
cl /c flash.c

# 3. Create library
lib /OUT:libaos.lib aos.obj block.obj crypto.obj md5.obj flash.obj

# 4. Repeat for tools/
cd ..\tools
cl /c aos-info.c /I ..\libaos /I "C:\OpenSSL\include"
cl /c files.c
cl /c mpk.c

# 5. Link
link /OUT:aos-info.exe aos-info.obj files.obj mpk.obj ..\libaos\libaos.lib ^
      "C:\OpenSSL\lib\ssl.lib" "C:\OpenSSL\lib\crypto.lib" ws2_32.lib
```

## Cross-Compilation from Linux

### Using MinGW Cross-Compiler

```bash
# On Linux: Install MinGW
apt-get install mingw-w64 mingw-w64-tools

# Build for Windows 64-bit
cd libaos
make -f Makefile.mingw CC=x86_64-w64-mingw32-gcc

cd ../tools
make -f Makefile.mingw CC=x86_64-w64-mingw32-gcc
```

### Makefile.mingw Template

Create `Makefile.mingw`:
```makefile
CC ?= x86_64-w64-mingw32-gcc
CFLAGS = -I/usr/x86_64-w64-mingw32/include
LDFLAGS = -L/usr/x86_64-w64-mingw32/lib -lssl -lcrypto -lws2_32

# Rest of your Makefile...
```

## Windows-Specific Notes

### 1. DLL vs Static Linking

**Static (Recommended for distribution)**:
```bash
gcc -c file.c -DOPENSSL_STATIC
gcc -o app.exe *.o -static -lssl -lcrypto
```

**Dynamic (Requires DLLs)**:
```bash
gcc -c file.c
gcc -o app.exe *.o -lssl -lcrypto
# Requires: libeay32.dll, ssleay32.dll (or libssl-*.dll, libcrypto-*.dll for newer versions)
```

### 2. Path Separators

Windows uses `\` but the code works with `/`:
- Safe because Windows API accepts both
- C code using standard `fopen()` works fine
- Command-line arguments need shell-specific handling

### 3. File I/O Differences

If issues occur with binary files:
```c
/* Add to code before fopen: */
#ifdef _WIN32
    #include <fcntl.h>
    #include <io.h>
    _setmode(_fileno(stdout), O_BINARY);  /* For binary output */
    _setmode(_fileno(stdin), O_BINARY);   /* For binary input */
#endif
```

### 4. Networking (if needed)

```c
#ifdef _WIN32
    #include <winsock2.h>
    #pragma comment(lib, "ws2_32.lib")
#else
    #include <sys/socket.h>
#endif
```

## Pre-built Binaries for Windows

Currently not included in this release. To use:

1. **Compile yourself** using instructions above
2. **Use WSL2 on Windows** running Linux environment
3. **Use Docker** Windows container

## Troubleshooting

### "undefined reference to `__imp_SSL_*`"
- Link against OpenSSL libraries: `-lssl -lcrypto`
- Or use static linking: `-static -lssl -lcrypto`

### "cannot find -lssl"
- Set correct library path: `-L/path/to/openssl/lib`
- Or use pkg-config: `` -`pkg-config --cflags --libs openssl` ``

### "permission denied" when running .exe
- Mark as executable in Windows properties
- Or run from PowerShell: `.\program.exe`

## Performance Notes

- **32-bit vs 64-bit**: Use 64-bit for better performance on modern Windows
- **Optimization**: Add `-O3` flag for faster builds
- **Debug symbols**: Remove `-g` flag to reduce binary size

## Windows Runtime Requirements

For end-users who want to run the compiled binaries:

**Option 1: Static Build** (Recommended)
- No additional files needed
- Binary is self-contained
- Larger file size (~1-5MB for aos-tools)

**Option 2: Dynamic Build**
- Requires: `libssl-1_1.dll` and `libcrypto-1_1.dll` (OpenSSL 1.1) or newer versions
- Can be distributed alongside .exe files
- Smaller binary size (~200-500KB for aos-tools)

## Example Complete Build

### Windows (PowerShell)

```powershell
# 1. Set up environment
$OPENSSL = "C:\OpenSSL"
$CC = "gcc"
$CFLAGS = "-Wall -O2 -I$OPENSSL\include"
$LDFLAGS = "-L$OPENSSL\lib -lssl -lcrypto -lws2_32 -static"

# 2. Build libaos
cd libaos
& $CC $CFLAGS -c aos.c, block.c, crypto.c, md5.c, flash.c
ar rcs libaos.a aos.o block.o crypto.o md5.o flash.o

# 3. Build tools
cd ..\tools
& $CC $CFLAGS -c aos-info.c, files.c, mpk.c
& $CC -o aos-info.exe aos-info.o files.o mpk.o $LDFLAGS -L..\libaos -laos

# Repeat for aos-unpack, aos-fix, aos-repack
```

### Linux (for Windows targets)

```bash
#!/bin/bash

MINGW_PREFIX=x86_64-w64-mingw32
OPENSSL_PATH=/usr/x86_64-w64-mingw32

# Build libaos
cd libaos
$MINGW_PREFIX-gcc -Wall -O2 -I$OPENSSL_PATH/include -c *.c
$MINGW_PREFIX-ar rcs libaos.a *.o

# Build tools
cd ../tools
$MINGW_PREFIX-gcc -Wall -O2 -I../libaos -c *.c
for tool in aos-info aos-unpack aos-fix aos-repack; do
    $MINGW_PREFIX-gcc -o $tool.exe ${tool}.o files.o mpk.o \
        -L../libaos -laos -L$OPENSSL_PATH/lib -lssl -lcrypto
done
```

## Support for Linux Kernel Tools

**insmod** and **rmmod** cannot be compiled for Windows as they depend on:
- `asm/unistd.h` (Linux kernel headers)
- `init_module()` and `delete_module()` syscalls (Linux kernel)
- Memory-mapped files via `mmap()` (different on Windows)

These tools require:
1. **Linux environment** (native or WSL)
2. **ARM cross-compiler** for target devices
3. **Linux kernel headers**

## Next Steps

1. Install required tools (MinGW, Make, OpenSSL)
2. Choose build method (MinGW, MSVC, or cross-compile from Linux)
3. Follow compilation steps above
4. Test binaries: `aos-info.exe --help`

## Resources

- **MinGW-w64**: https://www.mingw-w64.org/downloads/
- **OpenSSL Binary**: https://slproweb.com/products/Win32OpenSSL.html
- **GnuWin32 Make**: http://gnuwin32.sourceforge.net/
- **WSL2**: https://docs.microsoft.com/en-us/windows/wsl/
- **Docker**: https://www.docker.com/products/docker-desktop

---

**Note**: This guide focuses on compiling the portable components (libaos, tools). For ARM target-tools, see main BUILD_NOTES.md.
