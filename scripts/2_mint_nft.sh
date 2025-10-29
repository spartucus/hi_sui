#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/prepare.sh"

load_context
require_context_vars "PACKAGE_ID" "ADMIN_ADDRESS"

echo_step "2" "Mint NFT (mint_nft)"

NFT_OUTPUT=$(sui client call \
    --package "$PACKAGE_ID" \
    --module marketplace \
    --function mint_nft \
    --args \
        "Sui Punk #001" \
        "First NFT in the collection" \
        "https://example.com/nft/1.png" \
        "$ADMIN_ADDRESS" \
    --gas-budget 10000000 \
    --json 2>/dev/null)

# echo "$NFT_OUTPUT" | jq '.'

NFT_ID=$(echo "$NFT_OUTPUT" | jq -r '.objectChanges[] | select(.objectType? and (.objectType | contains("NFT"))) | .objectId')

if [ -z "$NFT_ID" ]; then
    echo -e "${RED}Failed to parse NFT object ID.${NC}"
    exit 1
fi

set_context_var "NFT_ID" "$NFT_ID"

echo_info "NFT ID: $NFT_ID"
echo_info "NFT details:"
NFT_DETAILS=$(sui client object "$NFT_ID" --json 2>/dev/null)
if ! echo "$NFT_DETAILS" | jq empty >/dev/null 2>&1; then
    echo -e "${RED}Failed to fetch NFT details as JSON.${NC}"
    echo "$NFT_DETAILS"
else
    echo "$NFT_DETAILS" | jq '.content.fields'
fi

echo ""