# AOS-Tools v1.0.0 Release

**Release Date**: 2026-07-22  
**Status**: Source Release with Build Documentation

## What's Included

### Components
- **libaos/**: Cryptographic library for AOS file manipulation
  - RSA signature verification/generation
  - AES encryption/decryption
  - Block management
  - MD5 hashing

- **target-tools/**: ARM-EABI utilities for embedded systems
  - `flash`: Flash device utilities
  - `mv`, `rm`: File manipulation tools

- **tools/**: Desktop utilities for AOS file handling
  - `aos-info`: Information extractor
  - `aos-unpack`: Archive unpacker
  - `aos-fix`: Repair utility
  - `aos-repack`: Archive repacker

### Documentation
- `BUILD_NOTES.md`: Comprehensive build guide with OpenSSL compatibility solutions
- `build.sh`: Automated build script
- This release document

## Build Status

### Current Status ⚠️
The codebase has OpenSSL 3.0 incompatibility issues related to internal struct access in the RSA and AES implementations. Full compilation requires:

**Option A (Recommended for immediate use):**
```bash
# Use OpenSSL 1.1 with legacy compatibility
apt-get install libssl1.1 libssl-dev
./build.sh
```

**Option B (Modern OpenSSL):**
- Requires porting to EVP API (see BUILD_NOTES.md)

## Repository

- **GitHub**: https://github.com/EiNSTeiN-/aos-tools
- **Branch**: master
- **Latest Commit**: f95e056

## Changes in v1.0.0

### Added
- Initial source release
- `BUILD_NOTES.md` with detailed build instructions
- `build.sh` automated build script
- OpenSSL compatibility guide

### Known Issues
- OpenSSL 3.0 compatibility: See BUILD_NOTES.md for solutions
- ARM cross-compiler not included (install separately)
- No pre-built binaries in this release

## Installation

### From Source

1. **Clone the repository:**
   ```bash
   git clone https://github.com/EiNSTeiN-/aos-tools.git
   cd aos-tools
   ```

2. **Install dependencies:**
   ```bash
   apt-get update
   apt-get install -y build-essential libssl1.1 libssl-dev
   ```

3. **Build:**
   ```bash
   chmod +x build.sh
   ./build.sh
   ```

4. **Install (optional):**
   ```bash
   cd tools && make install  # Requires libssl-dev
   cd ../target-tools && make install  # Requires ARM cross-compiler
   ```

## System Requirements

| Package | Version | Required | Status |
|---------|---------|----------|--------|
| GCC | 7.0+ | Yes | ✓ Tested |
| Make | 4.0+ | Yes | ✓ Tested |
| libssl-dev | 1.1.x | Yes | ⚠️ 3.0 has issues |
| libssl1.1 | 1.1.x | Conditional | ✓ Recommended |
| arm-*-gcc | Any | Optional | For ARM targets |

## License

See LICENSE file in repository for details.

## Support

For issues and questions:
- Open an issue on GitHub
- Check BUILD_NOTES.md for common problems
- See individual component README files

## Versioning

This project uses semantic versioning:
- **v1.0.0**: Initial release, source code only
- Future releases will include pre-built binaries and API stability guarantees

---

**Generated**: 2026-07-22  
**By**: Build System  
**For**: AOS-Tools Project
