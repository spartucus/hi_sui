#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/prepare.sh"

load_context
require_context_vars "PACKAGE_ID" "MARKETPLACE_ID" "LISTING_ID" "NFT_ID" "BUYER_ADDRESS"

echo_step "6" "Buy NFT (buy_nft)"

LISTING_STATE=$(sui client object "$LISTING_ID" --json 2>/dev/null)
if ! echo "$LISTING_STATE" | jq -e '.content' >/dev/null 2>&1; then
    echo -e "${RED}Listing $LISTING_ID is no longer available. Please re-run step 5 to create a fresh listing.${NC}"
    echo "$LISTING_STATE"
    exit 1
fi

sui client switch --address "$BUYER_ADDRESS"

BUYER_COINS=$(sui client gas --json 2>/dev/null | jq -r '.[0].gasCoinId')

if [ -z "$BUYER_COINS" ]; then
    echo -e "${RED}Buyer has no available gas coin.${NC}"
    exit 1
fi

set_context_var "BUYER_COIN_ID" "$BUYER_COINS"

BUY_OUTPUT=$(sui client call \
    --package "$PACKAGE_ID" \
    --module marketplace \
    --function buy_nft \
    --args \
        "$MARKETPLACE_ID" \
        "$LISTING_ID" \
        "$BUYER_COINS" \
    --gas-budget 10000000 \
    --json 2>/dev/null)

if ! echo "$BUY_OUTPUT" | jq '.' >/dev/null 2>&1; then
    echo -e "${RED}Buy transaction failed. Raw output:${NC}"
    echo "$BUY_OUTPUT"
    exit 1
fi

# echo "$BUY_OUTPUT" | jq '.'

NEW_NFT_ID=$(echo "$BUY_OUTPUT" | jq -r '.objectChanges[] | select(.objectType? and (.objectType | contains("NFT"))) | select((.owner.AddressOwner? // "") == "'$BUYER_ADDRESS'") | .objectId' | head -n 1)

CURRENT_NFT_ID="$NFT_ID"
if [ -n "$NEW_NFT_ID" ] && [ "$NEW_NFT_ID" != "null" ]; then
    CURRENT_NFT_ID="$NEW_NFT_ID"
    set_context_var "NFT_ID" "$CURRENT_NFT_ID"
    echo_info "Updated NFT ID (buyer ownership): $CURRENT_NFT_ID"
fi

echo_info "Verifying NFT ownership:"
NFT_STATE=$(sui client object "$CURRENT_NFT_ID" --json 2>/dev/null)
if ! echo "$NFT_STATE" | jq empty >/dev/null 2>&1; then
    echo -e "${RED}Failed to fetch NFT state as JSON.${NC}"
    echo "$NFT_STATE"
else
    echo "$NFT_STATE" | jq '.owner'
fi

echo_info "Marketplace balance:"
MARKETPLACE_STATE=$(sui client object "$MARKETPLACE_ID" --json 2>/dev/null)
if ! echo "$MARKETPLACE_STATE" | jq empty >/dev/null 2>&1; then
    echo -e "${RED}Failed to fetch marketplace state as JSON.${NC}"
    echo "$MARKETPLACE_STATE"
else
    echo "$MARKETPLACE_STATE" | jq '.content.fields.balance'
fi

echo ""

