#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/prepare.sh"

load_context
require_context_vars "PACKAGE_ID" "NFT2_ID" "BUYER_ADDRESS" "ADMIN_ADDRESS"

echo_step "8" "Transfer demonstrations"

echo_info "Switching to admin address: $ADMIN_ADDRESS"
sui client switch --address "$ADMIN_ADDRESS"

NFT2_STATE=$(sui client object "$NFT2_ID" --json 2>/dev/null)
if ! echo "$NFT2_STATE" | jq empty >/dev/null 2>&1; then
    echo -e "${RED}NFT #002 ($NFT2_ID) not found. Re-run step 7 or update NFT2_ID in .sui_env before continuing.${NC}"
    echo "$NFT2_STATE"
    exit 1
fi

NFT2_OWNER=$(echo "$NFT2_STATE" | jq -r '.owner.AddressOwner // empty')
if [ -z "$NFT2_OWNER" ]; then
    OWNER_DESC=$(echo "$NFT2_STATE" | jq '.owner')
    echo -e "${RED}Unable to determine owner of NFT #002 ($NFT2_ID).${NC}"
    echo "$OWNER_DESC"
    exit 1
fi

if [ "$NFT2_OWNER" != "$ADMIN_ADDRESS" ]; then
    echo -e "${RED}NFT #002 ($NFT2_ID) is owned by $NFT2_OWNER, not admin ($ADMIN_ADDRESS).\nPlease transfer it back to admin (e.g., re-run step 7) before running transfer examples.${NC}"
    exit 1
fi

echo_info "8.1 Transfer NFT #002 to buyer via public_transfer_nft"
TRANSFER_OUTPUT=$(sui client call \
    --package "$PACKAGE_ID" \
    --module marketplace \
    --function public_transfer_nft \
    --args \
        "$NFT2_ID" \
        "$BUYER_ADDRESS" \
    --gas-budget 10000000 \
    --json 2>/dev/null)

if ! echo "$TRANSFER_OUTPUT" | jq '.' >/dev/null 2>&1; then
    echo -e "${RED}Transfer transaction failed. Raw output:${NC}"
    echo "$TRANSFER_OUTPUT"
    exit 1
fi

# echo "$TRANSFER_OUTPUT" | jq '.'

echo_info "Verify NFT #002 ownership:"
NFT2_STATE=$(sui client object "$NFT2_ID" --json 2>/dev/null)
if ! echo "$NFT2_STATE" | jq empty >/dev/null 2>&1; then
    echo -e "${RED}Failed to fetch NFT #002 state as JSON.${NC}"
    echo "$NFT2_STATE"
else
    echo "$NFT2_STATE" | jq '.owner'
fi

echo ""

echo_info "8.2 Mint and freeze a new NFT"
NFT3_OUTPUT=$(sui client call \
    --package "$PACKAGE_ID" \
    --module marketplace \
    --function mint_nft \
    --args \
        "Sui Punk #003" \
        "Frozen NFT" \
        "https://example.com/nft/3.png" \
        "$ADMIN_ADDRESS" \
    --gas-budget 10000000 \
    --json 2>/dev/null)

NFT3_ID=$(echo "$NFT3_OUTPUT" | jq -r '.objectChanges[] | select(.objectType? and (.objectType | contains("NFT"))) | .objectId')

if [ -z "$NFT3_ID" ]; then
    echo -e "${RED}Failed to parse NFT #003 object ID.${NC}"
    exit 1
fi

set_context_var "NFT3_ID" "$NFT3_ID"

FREEZE_OUTPUT=$(sui client call \
    --package "$PACKAGE_ID" \
    --module marketplace \
    --function freeze_nft \
    --args "$NFT3_ID" \
    --gas-budget 10000000 \
    --json 2>/dev/null)

if ! echo "$FREEZE_OUTPUT" | jq '.' >/dev/null 2>&1; then
    echo -e "${RED}Freeze transaction failed. Raw output:${NC}"
    echo "$FREEZE_OUTPUT"
    exit 1
fi

# echo "$FREEZE_OUTPUT" | jq '.'

echo_info "Verify NFT #003 ownership (should be Immutable):"
NFT3_STATE=$(sui client object "$NFT3_ID" --json 2>/dev/null)
if ! echo "$NFT3_STATE" | jq empty >/dev/null 2>&1; then
    echo -e "${RED}Failed to fetch NFT #003 state as JSON.${NC}"
    echo "$NFT3_STATE"
else
    echo "$NFT3_STATE" | jq '.owner'
fi

echo ""

echo_info "8.3 Mint and share a new NFT (single transaction)"
NFT4_OUTPUT=$(sui client call \
    --package "$PACKAGE_ID" \
    --module marketplace \
    --function mint_and_share_nft \
    --args \
        "Sui Punk #004" \
        "Shared NFT" \
        "https://example.com/nft/4.png" \
    --gas-budget 10000000 \
    --json 2>/dev/null)

if ! echo "$NFT4_OUTPUT" | jq '.' >/dev/null 2>&1; then
    echo -e "${RED}Mint-and-share transaction failed. Raw output:${NC}"
    echo "$NFT4_OUTPUT"
    exit 1
fi

NFT4_ID=$(echo "$NFT4_OUTPUT" | jq -r '.objectChanges[] | select(.type=="created") | select(.objectType | contains("NFT")) | select(.owner.Shared?) | .objectId')

if [ -z "$NFT4_ID" ]; then
    echo -e "${RED}Failed to find shared NFT object ID in transaction output.${NC}"
    exit 1
fi

set_context_var "NFT4_ID" "$NFT4_ID"

echo_info "Verify NFT #004 ownership (should be Shared):"
NFT4_STATE=$(sui client object "$NFT4_ID" --json 2>/dev/null)
if ! echo "$NFT4_STATE" | jq empty >/dev/null 2>&1; then
    echo -e "${RED}Failed to fetch NFT #004 state as JSON.${NC}"
    echo "$NFT4_STATE"
else
    echo "$NFT4_STATE" | jq '.owner'
fi

echo ""

