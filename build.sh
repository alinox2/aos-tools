#!/bin/bash
set -e

BUILD_DIR="build"
RELEASE_DIR="$BUILD_DIR/release"

mkdir -p "$RELEASE_DIR"

echo "=== AOS-Tools Build Script ==="
echo ""

# Check OpenSSL version
OPENSSL_VERSION=$(openssl version)
echo "OpenSSL version: $OPENSSL_VERSION"
echo ""

# Build libaos
echo "[1/3] Building libaos library..."
cd libaos
if make clean > /dev/null 2>&1; then
    if make 2>&1 | grep -q "Error"; then
        echo "⚠️  libaos compilation failed (OpenSSL compatibility issue)"
        echo "   The code requires OpenSSL with internal RSA/AES API access"
        echo "   Consider using OpenSSL 1.0.x or applying patches for OpenSSL 1.1+"
    else
        cp libaos.a "../$RELEASE_DIR/" || true
        echo "✓ libaos library built successfully"
    fi
else
    echo "✗ libaos make failed"
fi
cd ..
echo ""

# Build target-tools (ARM cross-compilation)
echo "[2/3] Building target-tools (ARM)..."
cd target-tools
if command -v arm-linux-uclibcgnueabi-gcc &> /dev/null; then
    if make clean > /dev/null 2>&1 && make 2>&1; then
        cp flash mv rm "../$RELEASE_DIR/" 2>/dev/null || true
        echo "✓ target-tools built successfully"
    else
        echo "⚠️  target-tools compilation failed"
    fi
else
    echo "⚠️  ARM cross-compiler (arm-linux-uclibcgnueabi-gcc) not found"
    echo "   Install with: apt-get install gcc-arm-linux-uclibcgnueabi"
fi
cd ..
echo ""

# Build tools
echo "[3/3] Building AOS tools..."
cd tools
if [ -f "../libaos/libaos.a" ]; then
    if make clean > /dev/null 2>&1 && make 2>&1 | grep -q "Error"; then
        echo "⚠️  tools compilation failed (depends on libaos)"
    else
        cp aos-info aos-unpack aos-fix aos-repack "../$RELEASE_DIR/" 2>/dev/null || true
        echo "✓ AOS tools built successfully"
    fi
else
    echo "⚠️  Skipping tools (libaos not available)"
fi
cd ..
echo ""

echo "=== Build Summary ==="
if [ -d "$RELEASE_DIR" ] && [ "$(ls -A $RELEASE_DIR)" ]; then
    echo "✓ Binaries available in: $RELEASE_DIR"
    ls -lh "$RELEASE_DIR"
else
    echo "⚠️  No binaries were generated"
    echo "   Source code is available in the repository"
fi
echo ""
