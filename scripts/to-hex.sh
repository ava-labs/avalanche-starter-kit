#!/bin/bash

# Script to convert Avalanche blockchain IDs from Base58 to hex
# Usage: ./scripts/to-hex.sh <base58_string>

if [ $# -eq 0 ]; then
    echo "Usage: ./scripts/to-hex.sh <base58_blockchain_id>"
    echo ""
    echo "Example:"
    echo "  ./scripts/to-hex.sh yH8D7ThNJkxmtkuv2jgBa4P1Rn3Qpr4pPr7QYNfcdoS6k6HWp"
    echo "  Output: 0x7fc93d85c6d62c5b2ac0b519c87010ea5294012d1e407030d6acd0021cac10d5"
    exit 1
fi

INPUT="$1"

# Check if it's already hex
if [[ "$INPUT" =~ ^0x[0-9a-fA-F]+$ ]]; then
    echo "$INPUT"
    exit 0
fi

# Try using Python with base58 library
if command -v python3 &> /dev/null; then
    # Check if base58 is available
    python3 -c "import base58" 2>/dev/null
    if [ $? -eq 0 ]; then
        HEX=$(python3 -c "
import base58
import sys
try:
    decoded = base58.b58decode('$INPUT')
    # Avalanche blockchain IDs are 32 bytes, the rest is checksum
    blockchain_id = decoded[:32]
    hex_str = '0x' + blockchain_id.hex()
    print(hex_str)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>&1)
        if [ $? -eq 0 ]; then
            echo "$HEX"
            exit 0
        fi
    fi
fi

# Fallback: Install base58 if pip is available
if command -v pip3 &> /dev/null; then
    echo "Installing base58 library..." >&2
    pip3 install --user --break-system-packages base58 >/dev/null 2>&1 || pip3 install --user base58 >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        HEX=$(python3 -c "
import base58
import sys
try:
    decoded = base58.b58decode('$INPUT')
    # Avalanche blockchain IDs are 32 bytes, the rest is checksum
    blockchain_id = decoded[:32]
    hex_str = '0x' + blockchain_id.hex()
    print(hex_str)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>&1)
        if [ $? -eq 0 ]; then
            echo "$HEX"
            exit 0
        fi
    fi
fi

# Alternative: Use Node.js if available
if command -v node &> /dev/null; then
    HEX=$(node -e "
const bs58 = require('bs58');
try {
    const decoded = bs58.decode('$INPUT');
    // Avalanche blockchain IDs are 32 bytes, the rest is checksum
    const blockchainId = decoded.slice(0, 32);
    const hex = '0x' + Buffer.from(blockchainId).toString('hex');
    console.log(hex);
} catch(e) {
    console.error('Error:', e.message);
    process.exit(1);
}
" 2>&1)
    if [ $? -eq 0 ] && [[ "$HEX" =~ ^0x ]]; then
        echo "$HEX"
        exit 0
    fi
fi

# Last resort: Manual Base58 decoding (simplified)
echo "Error: Could not convert Base58 string to hex." >&2
echo "" >&2
echo "Please install one of the following:" >&2
echo "  - Python with base58: pip3 install base58" >&2
echo "  - Node.js with bs58: npm install bs58" >&2
echo "" >&2
echo "Or use an online converter:" >&2
echo "  https://www.avax.network/tools/blockchain-id-converter" >&2
exit 1
