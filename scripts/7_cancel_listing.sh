#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/prepare.sh"

load_context
require_context_vars "PACKAGE_ID" "MARKETPLACE_ID" "ADMIN_ADDRESS"

echo_step "7" "Cancel listing (cancel_listing)"

PRICE=${LIST_PRICE:-1000000000}

sui client switch --address "$ADMIN_ADDRESS"

echo_info "Minting a new NFT for cancellation demo..."
NFT2_OUTPUT=$(sui client call \
    --package "$PACKAGE_ID" \
    --module marketplace \
    --function mint_nft \
    --args \
        "Sui Punk #002" \
        "Second NFT in the collection" \
        "https://example.com/nft/2.png" \
        "$ADMIN_ADDRESS" \
    --gas-budget 10000000 \
    --json 2>/dev/null)

NFT2_ID=$(echo "$NFT2_OUTPUT" | jq -r '.objectChanges[] | select(.objectType? and (.objectType | contains("NFT"))) | .objectId')

if [ -z "$NFT2_ID" ]; then
    echo -e "${RED}Failed to parse second NFT object ID.${NC}"
    exit 1
fi

set_context_var "NFT2_ID" "$NFT2_ID"
echo_info "Second NFT ID: $NFT2_ID"

echo_info "Listing the second NFT..."
LIST2_OUTPUT=$(sui client call \
    --package "$PACKAGE_ID" \
    --module marketplace \
    --function list_nft \
    --args \
        "$NFT2_ID" \
        "$PRICE" \
    --gas-budget 10000000 \
    --json 2>/dev/null)

if ! echo "$LIST2_OUTPUT" | jq '.' >/dev/null 2>&1; then
    echo -e "${RED}Listing transaction failed. Raw output:${NC}"
    echo "$LIST2_OUTPUT"
    exit 1
fi

LISTING2_ID=$(echo "$LIST2_OUTPUT" | jq -r '.objectChanges[] | select(.objectType? and (.objectType | contains("Listing"))) | .objectId')

if [ -z "$LISTING2_ID" ]; then
    echo -e "${RED}Failed to parse second listing object ID.${NC}"
    exit 1
fi

set_context_var "LISTING2_ID" "$LISTING2_ID"
echo_info "Second listing ID: $LISTING2_ID"

echo_info "Cancelling the listing..."
CANCEL_OUTPUT=$(sui client call \
    --package "$PACKAGE_ID" \
    --module marketplace \
    --function cancel_listing \
    --args \
        "$LISTING2_ID" \
    --gas-budget 10000000 \
    --json 2>/dev/null)

if ! echo "$CANCEL_OUTPUT" | jq '.' >/dev/null 2>&1; then
    echo -e "${RED}Cancel transaction failed. Raw output:${NC}"
    echo "$CANCEL_OUTPUT"
    exit 1
fi

# echo "$CANCEL_OUTPUT" | jq '.'

echo_info "Verify NFT ownership after cancellation:"
NFT2_STATE=$(sui client object "$NFT2_ID" --json 2>/dev/null)
if ! echo "$NFT2_STATE" | jq empty >/dev/null 2>&1; then
    echo -e "${RED}Failed to fetch NFT #002 state as JSON.${NC}"
    echo "$NFT2_STATE"
else
    echo "$NFT2_STATE" | jq '.owner'
fi

echo ""

