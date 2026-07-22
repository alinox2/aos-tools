# aos-tools

This is a suite of tools to deal with firmware update files for the Archos 5/7 and 
Archos 5 IT family of product. It will allow you to verify, decrypt, unpack and then 
put back together .aos containers. Additionally, it will deal with (verify and parse) 
various files often found inside these .aos containers, like segments of flash memory 
and cramfs files.

You can find more information on our wiki at http://archos.g3nius.org/

## Quick Build

### Linux / Ubuntu
```bash
# Ubuntu 20.04 and older (works directly)
sudo apt-get install -y build-essential libssl-dev
cd libaos && make && cd ..
cd tools && make

# Ubuntu 22.04+ (use OpenSSL 1.1)
sudo apt-get install -y build-essential libssl1.1
# See UBUNTU_BUILD.md for detailed instructions

# Or use Docker (any Ubuntu)
docker build -t aos-tools .
docker run --rm aos-tools aos-info --help
```

### Windows
```powershell
# With MinGW and OpenSSL installed
.\build-windows.ps1

# Or using Make
make -f Makefile.mingw
```

## Documentation

- **[UBUNTU_BUILD.md](UBUNTU_BUILD.md)** - Complete Ubuntu/Linux build guide (4 methods)
- **[WINDOWS_BUILD.md](WINDOWS_BUILD.md)** - Complete Windows build guide
- **[BUILD_NOTES.md](BUILD_NOTES.md)** - General build issues and solutions
- **[RELEASE.md](RELEASE.md)** - Release notes and version info

## Components

| Component | Type | Status |
|-----------|------|--------|
| **libaos** | Library | Cryptographic library for AOS manipulation |
| **aos-info** | Tool | Display AOS file information |
| **aos-unpack** | Tool | Extract AOS file contents |
| **aos-fix** | Tool | Repair AOS files |
| **aos-repack** | Tool | Create AOS files |
| **target-tools** | Tools | ARM utilities (flash, mv, rm) |

## Build Support

| Platform | Status | Methods |
|----------|--------|---------|
| Ubuntu 24.04 LTS | ✅ | Docker, OpenSSL 1.1 headers |
| Ubuntu 22.04 LTS | ✅ | Docker, OpenSSL 1.1 headers |
| Ubuntu 20.04 LTS | ✅ | Direct build |
| Ubuntu 18.04 LTS | ✅ | Direct build |
| Windows 11/10 | ✅ | PowerShell, Batch, MinGW Make |
| macOS | ✅ | Clang/GCC with Homebrew |
| Raspberry Pi | ✅ | Native ARM build |
| Docker | ✅ | Ubuntu 20.04 container |

## Getting Started

1. **Choose your platform**:
   - [Linux/Ubuntu](UBUNTU_BUILD.md)
   - [Windows](WINDOWS_BUILD.md)

2. **Install dependencies** (usually 5 minutes)

3. **Run build command** (usually 30 seconds)

4. **Use the tools**:
   ```bash
   ./tools/aos-info firmware.aos
   ./tools/aos-unpack firmware.aos extract/
   ./tools/aos-repack extract/ new-firmware.aos
   ```

## Troubleshooting

### OpenSSL 3.0 Incompatibility
The code uses internal RSA/AES APIs not exposed in OpenSSL 3.0. Solutions:
- Use **Docker** with Ubuntu 20.04 (has OpenSSL 1.1)
- Download **OpenSSL 1.1 headers** from source
- See [UBUNTU_BUILD.md](UBUNTU_BUILD.md#ubuntu-2404-special-note)

### Missing Tools
- **gcc not found**: Install `build-essential`
- **make not found**: Install `make` or `mingw-w64-tools`
- **libssl not found**: Install `libssl-dev` or use Docker

See full [BUILD_NOTES.md](BUILD_NOTES.md) for detailed troubleshooting.

## Contributing

To contribute improvements:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on multiple platforms
5. Submit a pull request

## License

See the LICENSE file for details.

## Resources

- **Original Project**: http://archos.g3nius.org/
- **Archived Code**: https://code.google.com/p/aos-tools/
- **GitHub**: https://github.com/EiNSTeiN-/aos-tools

----
Imported from https://code.google.com/p/aos-tools/
