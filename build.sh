#!/bin/bash

set -e

echo "🔧 Building Photonic Ring Plugin..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    echo "❌ Error: Rust is not installed. Please install Rust from https://rustup.rs/"
    exit 1
fi

echo -e "${BLUE}Step 1/3: Building Rust library...${NC}"
cd rust
cargo build --release

echo ""
echo -e "${BLUE}Step 2/3: Creating output directory...${NC}"
mkdir -p ../addons/photonic_ring/bin

echo ""
echo -e "${BLUE}Step 3/3: Copying library to plugin directory...${NC}"

# Detect OS and copy appropriate library
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    cp target/release/libphotonic_ring.so ../addons/photonic_ring/bin/
    echo "✓ Copied Linux library (libphotonic_ring.so)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    cp target/release/libphotonic_ring.dylib ../addons/photonic_ring/bin/
    echo "✓ Copied macOS library (libphotonic_ring.dylib)"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    cp target/release/photonic_ring.dll ../addons/photonic_ring/bin/
    echo "✓ Copied Windows library (photonic_ring.dll)"
else
    echo "❌ Unknown OS type: $OSTYPE"
    exit 1
fi

cd ..

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo "📝 Next steps:"
echo "  1. Open your Godot project"
echo "  2. Copy the 'addons/photonic_ring' folder to your project's addons directory"
echo "  3. Enable the plugin in Project → Project Settings → Plugins"
echo "  4. Look for the 'Photonic Ring' panel in the editor dock"
echo ""
echo "🎉 Happy texture generating!"
