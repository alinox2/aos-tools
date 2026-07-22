# AOS-Tools Build Guide for Ubuntu/Linux

## Quick Start (5 minutes)

### Option 1: Use OpenSSL 1.1 (Recommended - Works Now!)

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y build-essential libssl1.1 libssl-dev

# Build everything
chmod +x build.sh
./build.sh
```

### Option 2: Use Docker (No dependencies needed!)

```bash
# Build in Docker container
docker build -t aos-tools-build .
docker run --rm -v $(pwd):/src aos-tools-build make -C /src/libaos
```

## Ubuntu Version Compatibility

| Ubuntu Version | OpenSSL | Status | Recommendation |
|---|---|---|---|
| 24.04 LTS (Noble) | 3.5+ | ⚠️ Incompatible | Use OpenSSL 1.1 |
| 22.04 LTS (Jammy) | 3.0.x | ⚠️ Incompatible | Use OpenSSL 1.1 |
| 20.04 LTS (Focal) | 1.1.x | ✅ Works! | Build directly |
| 18.04 LTS (Bionic) | 1.1.x | ✅ Works! | Build directly |
| 16.04 LTS (Xenial) | 1.0.x | ✅ Works! | Build directly |

## Checking Your System

```bash
# Check Ubuntu version
lsb_release -a

# Check GCC
gcc --version

# Check OpenSSL
openssl version
```

## Build Methods

### Method 1: Direct Build (Ubuntu 20.04 and older)

If you have **OpenSSL 1.1.x**:

```bash
# Install dependencies
sudo apt-get install -y build-essential libssl-dev libcrypto++-dev

# Build libaos
cd libaos
make
cd ..

# Build tools
cd tools
make
cd ..

# Binaries created in tools/ directory
./tools/aos-info firmware.aos
```

### Method 2: With OpenSSL 1.1 Compatibility (Ubuntu 22.04+)

```bash
# Install OpenSSL 1.1 alongside 3.0
sudo apt-get install -y build-essential libssl1.1 libssl-dev

# Create wrapper Makefile
cd libaos
cat > Makefile.compat <<'EOF'
CFLAGS = -I/usr/include/openssl1.1
LDFLAGS = -L/usr/lib/x86_64-linux-gnu -Wl,--no-as-needed -lssl1.1 -lcrypto1.1

OBJECTS=aos.o block.o crypto.o md5.o flash.o

all: libaos.a

.c.o:
	gcc $(CFLAGS) -c $*.c

libaos.a: $(OBJECTS)
	ar crs libaos.a $(OBJECTS)

clean:
	rm -f libaos.a *.o
EOF

# Build with compatibility Makefile
make -f Makefile.compat
cd ..

# Build tools (linking to custom libaos)
cd tools
gcc -Wall -O2 -I../libaos -c aos-info.c files.c mpk.c
gcc -o aos-info aos-info.o files.o mpk.o -L../libaos -laos \
    -I/usr/include/openssl1.1 -L/usr/lib/x86_64-linux-gnu \
    -Wl,--no-as-needed -lssl1.1 -lcrypto1.1

# Repeat for aos-unpack, aos-fix, aos-repack
cd ..
```

### Method 3: Automated Script (All Ubuntu versions)

```bash
# Run the included build script
chmod +x build.sh
./build.sh
```

The script automatically:
- Checks for OpenSSL 3.0 incompatibility
- Suggests solutions
- Attempts to build what it can
- Provides troubleshooting info

### Method 4: Using WSL2 on Windows (Ubuntu in Windows)

If running Ubuntu in WSL2 on Windows:

```bash
# Inside WSL2 terminal
cd /mnt/c/path/to/aos-tools
./build.sh

# Or build for Windows from Linux
apt-get install -y mingw-w64
make -f Makefile.mingw CC=x86_64-w64-mingw32-gcc
```

## Component-by-Component Build

### Build Only libaos (Crypto Library)

```bash
cd libaos

# With OpenSSL 1.1
make -I/usr/include/openssl1.1 -L/usr/lib/x86_64-linux-gnu

# Or manual
gcc -I/usr/include/openssl1.1 -c aos.c block.c crypto.c md5.c flash.c
ar rcs libaos.a *.o
```

### Build Only tools (If libaos fails)

```bash
cd tools

# Most tools can work without crypto features
gcc -Wall -O2 -c files.c mpk.c
gcc -o file-tool files.o mpk.o

# Note: aos-info, aos-unpack, etc. require libaos with crypto
```

### Build ARM Cross-Compiler Tools

For ARM target devices (Archos):

```bash
# Install ARM cross-compiler
sudo apt-get install -y gcc-arm-linux-gnueabihf gcc-arm-linux-gnueabi

# Build for ARM EABI
cd target-tools
make CC=arm-linux-gnueabihf-gcc
# Output: flash, mv, rm (ARM EABI binaries)

# Or for ARM EABI (older)
make CC=arm-linux-gnueabi-gcc
```

## Installing Build Dependencies

### Ubuntu 24.04 (Current)

```bash
# Essential tools
sudo apt-get update
sudo apt-get install -y build-essential git

# OpenSSL (choose one):
# Option A: Use 1.1 for compatibility
sudo apt-get install -y libssl1.1 libssl-dev

# Option B: Build with legacy provider (advanced)
sudo apt-get install -y libssl-dev
export OPENSSL_CONF=/etc/ssl/openssl.cnf
# Requires patching crypto.c or using provider setup

# Cross-compilation (optional)
sudo apt-get install -y gcc-arm-linux-gnueabihf  # ARM 32-bit
sudo apt-get install -y gcc-aarch64-linux-gnu     # ARM 64-bit
```

### Ubuntu 22.04 LTS

```bash
sudo apt-get install -y build-essential libssl1.1 libssl-dev git
```

### Ubuntu 20.04 LTS (Works without OpenSSL 1.1)

```bash
sudo apt-get install -y build-essential libssl-dev git
# libssl-dev provides 1.1.x which works directly
```

## Testing the Build

```bash
# After successful build
./tools/aos-info --help
./tools/aos-info firmware.aos

# Example: Pack and unpack
./tools/aos-unpack firmware.aos firmware_extracted/
./tools/aos-repack firmware_extracted/ firmware_new.aos
./tools/aos-info firmware_new.aos
```

## Troubleshooting

### Error: "cannot find -lssl"

```bash
# Check what OpenSSL versions are installed
dpkg -l | grep libssl

# If only 3.x installed, install 1.1:
sudo apt-get install -y libssl1.1

# Build with explicit path
gcc -I/usr/include/openssl1.1 -L/usr/lib/x86_64-linux-gnu \
    -Wl,--no-as-needed -lssl1.1 -lcrypto1.1 file.c
```

### Error: "invalid use of incomplete typedef 'RSA'"

This is the OpenSSL 3.0 incompatibility. Solutions:

**Option 1** (Easiest): Switch to OpenSSL 1.1
```bash
# Remove OpenSSL 3.0 development files
sudo apt-get remove -y libssl-dev

# Install 1.1
sudo apt-get install -y libssl1.1

# Rebuild
make clean && make
```

**Option 2**: Port to EVP API (Advanced)
- Requires rewriting crypto.c and aos.c
- Use EVP_PKEY_* instead of RSA_*
- Use EVP_CIPHER instead of AES_*

**Option 3**: Use Docker with older Ubuntu
```bash
docker run -it ubuntu:20.04
apt-get update && apt-get install -y build-essential libssl-dev git
cd /src && make
```

### Error: "make: gcc: command not found"

```bash
# Install GCC
sudo apt-get install -y build-essential

# Verify
gcc --version
make --version
```

### Error with pkg-config

```bash
# Install pkg-config
sudo apt-get install -y pkg-config

# Use it to find OpenSSL
pkg-config --cflags --libs openssl
```

## Advanced: Building with Older OpenSSL Compatible

If you need to support both old and new OpenSSL:

```bash
# Create a CMakeLists.txt or use configure script
# This is beyond the scope of this guide
# See CONTRIBUTING.md for complex build setups
```

## Performance Notes

### Build Time

- **First build**: 10-30 seconds (depends on CPU)
- **Incremental rebuild**: 2-5 seconds
- **Clean rebuild**: 20-30 seconds

### Binary Size

- **libaos.a**: ~200-300 KB (static library)
- **aos-info**: ~1-2 MB (with OpenSSL linked)
- **aos-unpack**: ~1-2 MB
- **Total tools**: ~4-8 MB for all executables

### Optimization

For smaller, faster binaries:

```bash
# With optimization flag
gcc -O3 -s -Wall -c file.c

# With LTO (Link Time Optimization)
gcc -flto -O3 -c file.c
ar rcs libaos.a *.o
```

## Continuous Integration on Ubuntu

If using GitHub Actions or similar:

```yaml
# .github/workflows/build-ubuntu.yml
name: Build on Ubuntu

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y build-essential libssl1.1 libssl-dev
      - name: Build
        run: |
          cd libaos && make && cd ..
          cd tools && make && cd ..
      - name: Test
        run: |
          ./tools/aos-info --help
```

## Ubuntu Container Build (Docker)

Create a `Dockerfile`:

```dockerfile
FROM ubuntu:20.04

RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    git

WORKDIR /src

# Copy source
COPY . .

# Build
RUN cd libaos && make && cd .. && \
    cd tools && make && cd ..

# Run binaries
ENTRYPOINT ["./tools/aos-info"]
```

Build and run:

```bash
docker build -t aos-tools .
docker run --rm aos-tools firmware.aos
docker run --rm -v $(pwd):/data aos-tools /data/firmware.aos
```

## Getting Help on Ubuntu

1. **Check your Ubuntu version**:
   ```bash
   lsb_release -a
   ```

2. **Check OpenSSL version**:
   ```bash
   openssl version
   ```

3. **Try the automated build**:
   ```bash
   ./build.sh
   ```

4. **Read detailed guides**:
   - [BUILD_NOTES.md](BUILD_NOTES.md) - General build info
   - [WINDOWS_BUILD.md](WINDOWS_BUILD.md) - For cross-compilation to Windows

5. **Check system packages**:
   ```bash
   apt-cache policy libssl-dev libssl1.1
   dpkg -l | grep -E 'gcc|make|libssl'
   ```

## Summary by Ubuntu Version

### Ubuntu 24.04 LTS ⚠️
- **OpenSSL**: 3.5.5 (incompatible)
- **Solution**: Install libssl1.1
- **Command**: 
  ```bash
  sudo apt-get install -y libssl1.1 libssl-dev
  make clean && make
  ```

### Ubuntu 22.04 LTS ⚠️
- **OpenSSL**: 3.0.x (incompatible)
- **Solution**: Install libssl1.1
- **Command**: 
  ```bash
  sudo apt-get install -y libssl1.1 libssl-dev
  make clean && make
  ```

### Ubuntu 20.04 LTS ✅
- **OpenSSL**: 1.1.x (works!)
- **Solution**: Direct build
- **Command**: 
  ```bash
  sudo apt-get install -y libssl-dev
  make
  ```

### Ubuntu 18.04 LTS ✅
- **OpenSSL**: 1.1.x (works!)
- **Solution**: Direct build
- **Command**: 
  ```bash
  sudo apt-get install -y libssl-dev
  make
  ```

---

**TL;DR for Ubuntu 24.04**:

```bash
sudo apt-get update
sudo apt-get install -y build-essential libssl1.1 libssl-dev
cd libaos && make && cd ..
cd tools && make
```

**Binaries** will be in `tools/` directory!

## ⚠️ Ubuntu 24.04 Special Note

On Ubuntu 24.04, `libssl1.1` (1.1.x runtime) is available BUT `libssl-dev` provides OpenSSL 3.0 headers only.

### Solutions for Ubuntu 24.04

#### ✅ Solution 1: Compile Only libaos Without Crypto (Recommended for testing)

```bash
cd libaos
gcc -c aos.c block.c md5.c flash.c
ar rcs libaos.a *.o
# Skip crypto.c (depends on RSA internals)

cd ../tools
# These still work but may have limited functionality
gcc -o file-util files.c mpk.c
```

#### ✅ Solution 2: Use Docker (Ubuntu 20.04 inside)

```bash
docker run -it --rm -v $(pwd):/src ubuntu:20.04 bash
apt-get update
apt-get install -y build-essential libssl-dev git
cd /src
cd libaos && make && cd ..
cd tools && make
```

#### ✅ Solution 3: Download OpenSSL 1.1 Headers

```bash
# Get headers from source
cd /tmp
wget https://www.openssl.org/source/openssl-1.1.1w.tar.gz
tar xzf openssl-1.1.1w.tar.gz
export OPENSSL_INCLUDE=/tmp/openssl-1.1.1w/include
export OPENSSL_LIB=/usr/lib/x86_64-linux-gnu

# Build
cd /workspaces/aos-tools/libaos
gcc -I$OPENSSL_INCLUDE -c aos.c block.c crypto.c md5.c flash.c
gcc -I$OPENSSL_INCLUDE -L$OPENSSL_LIB \
    -c aos.c block.c crypto.c md5.c flash.c
ar rcs libaos.a *.o
```

#### ✅ Solution 4: Cross-Compile from Windows/Mac

Use Windows build on Linux:

```bash
apt-get install -y mingw-w64
make -f Makefile.mingw CC=x86_64-w64-mingw32-gcc
# Get Windows .exe files that you can copy to Windows
```

### Recommended for Ubuntu 24.04 Users

**Use Docker!** (Easiest, most reliable)

```bash
docker run -it --rm -v $(pwd):/src ubuntu:20.04 bash
cd /src
sudo apt-get update
sudo apt-get install -y build-essential libssl-dev
cd libaos && make && cd ..
cd tools && make
```

