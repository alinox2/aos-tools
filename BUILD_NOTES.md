# AOS-Tools Build Notes

## Build Issues

### OpenSSL 3.0 Incompatibility
The codebase requires direct access to OpenSSL internal RSA and AES structures, which are no longer exposed in OpenSSL 3.0. The relevant structs are now opaque types.

**Error Example:**
```
crypto.c:42:18: error: invalid use of incomplete typedef 'RSA' {aka 'struct rsa_st'}
   42 |         sign->rsa->e = BN_new();
```

### Solutions

#### Option 1: Use OpenSSL 1.1 (Recommended for legacy code)
```bash
# Install OpenSSL 1.1 dev files
apt-get install libssl1.1 libssl-dev

# Compile with explicit include path
export CFLAGS="-I/usr/include/openssl1.1"
export LDFLAGS="-L/usr/lib/x86_64-linux-gnu -lssl1.1 -lcrypto1.1"
make
```

#### Option 2: Port to OpenSSL 3.0 API
The code needs to be refactored to use EVP API instead of direct struct access. This requires:
- Replacing RSA_* functions with EVP_PKEY_* functions
- Using EVP_CIPHER interface instead of direct AES_* calls
- Updating error handling

#### Option 3: Use Docker
```bash
docker run -v $(pwd):/src ubuntu:16.04
apt-get update && apt-get install -y build-essential libssl-dev libcrypto-dev
cd /src && make
```

## Building Individual Components

### libaos (Crypto Library)
```bash
cd libaos
make  # Requires working crypto.c
```

### target-tools (ARM Binaries)
```bash
apt-get install gcc-arm-linux-uclibcgnueabi
cd target-tools
make
```

### tools (AOS Utilities)
```bash
cd tools
make  # Depends on libaos
```

## Build Script

A `build.sh` script is included that attempts to build all components:
```bash
chmod +x build.sh
./build.sh
```

## Requirements

- GCC 7.0+ or Clang 6.0+
- Make 4.0+
- OpenSSL 1.1 development files (`libssl-dev`, `libssl1.1`)
- (Optional) ARM cross-compiler for target-tools
- (Optional) libuClibc for ARM targets

## Architecture Support

| Component | Architecture | Status |
|-----------|--------------|--------|
| libaos | x86/x86_64 | ⚠️ OpenSSL incompatible |
| target-tools | ARM (EABI) | ✓ Compiles (needs cross-compiler) |
| tools | x86/x86_64 | ⚠️ Depends on libaos |
