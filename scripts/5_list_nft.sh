#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/prepare.sh"

load_context
require_context_vars "PACKAGE_ID" "NFT_ID" "ADMIN_ADDRESS"

echo_step "5" "List NFT (list_nft)"

echo_info "Switching to admin address: $ADMIN_ADDRESS"
sui client switch --address "$ADMIN_ADDRESS"

NFT_DETAILS=$(sui client object "$NFT_ID" --json 2>/dev/null)
if ! echo "$NFT_DETAILS" | jq empty >/dev/null 2>&1; then
    echo -e "${RED}NFT $NFT_ID not available. Please run step 2 to mint a fresh NFT before listing.${NC}"
    echo "$NFT_DETAILS"
    exit 1
fi

NFT_OWNER=$(echo "$NFT_DETAILS" | jq -r '.owner.AddressOwner // empty')
if [ -z "$NFT_OWNER" ] || [ "$NFT_OWNER" != "$ADMIN_ADDRESS" ]; then
    echo -e "${RED}NFT $NFT_ID is not owned by admin ($ADMIN_ADDRESS). Re-mint via step 2 or transfer it back before listing.${NC}"
    echo "$NFT_DETAILS" | jq '.owner'
    exit 1
fi

PRICE=${LIST_PRICE:-10000000}

LIST_OUTPUT=$(sui client call \
    --package "$PACKAGE_ID" \
    --module marketplace \
    --function list_nft \
    --args \
        "$NFT_ID" \
        "$PRICE" \
    --gas-budget 10000000 \
    --json 2>/dev/null)

if ! echo "$LIST_OUTPUT" | jq '.' >/dev/null 2>&1; then
    echo -e "${RED}Listing transaction failed. Raw output:${NC}"
    echo "$LIST_OUTPUT"
    exit 1
fi

# echo "$LIST_OUTPUT" | jq '.'

LISTING_ID=$(echo "$LIST_OUTPUT" | jq -r '.objectChanges[] | select(.objectType? and (.objectType | contains("Listing"))) | .objectId')

if [ -z "$LISTING_ID" ]; then
    echo -e "${RED}Failed to parse listing object ID.${NC}"
    exit 1
fi

set_context_var "LISTING_ID" "$LISTING_ID"
set_context_var "LIST_PRICE" "$PRICE"

echo_info "Listing ID: $LISTING_ID"
echo_info "Listing details:"
LISTING_DETAILS=$(sui client object "$LISTING_ID" --json 2>/dev/null)
if ! echo "$LISTING_DETAILS" | jq empty >/dev/null 2>&1; then
    echo -e "${RED}Failed to fetch listing details as JSON.${NC}"
    echo "$LISTING_DETAILS"
else
    echo "$LISTING_DETAILS" | jq '.content.fields'
fi

echo ""

