#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/prepare.sh"

load_context
require_context_vars "PACKAGE_ID" "MARKETPLACE_ID" "ADMIN_CAP_ID" "ADMIN_ADDRESS" "BUYER_ADDRESS"

echo_step "11" "Summary"

echo "==========================================="
echo "Test flow completed."
echo "==========================================="
echo ""
echo "Key object IDs:"
echo "  Package ID:     $PACKAGE_ID"
echo "  Marketplace ID: $MARKETPLACE_ID"
echo "  AdminCap ID:    $ADMIN_CAP_ID"
echo "  Admin address:  $ADMIN_ADDRESS"
echo "  Buyer address:  $BUYER_ADDRESS"
echo "  NFT ID:         ${NFT_ID:-N/A}"
echo "  Listing ID:     ${LISTING_ID:-N/A}"
echo "  NFT #2 ID:      ${NFT2_ID:-N/A}"
echo "  Listing #2 ID:  ${LISTING2_ID:-N/A}"
echo "  NFT #3 ID:      ${NFT3_ID:-N/A}"
echo "  NFT #4 ID:      ${NFT4_ID:-N/A}"
echo ""

echo "Covered functionality:"
echo "  ✓ Deploy contract"
echo "  ✓ Mint NFT"
echo "  ✓ List NFT"
echo "  ✓ Buy NFT"
echo "  ✓ Cancel listing"
echo "  ✓ Transfer, freeze, share"
echo "  ✓ Update fee"
echo "  ✓ Withdraw fees"
echo "  ✓ View events"
echo ""

OUTPUT_FILE="sui_commands_reference.txt"

cat > "$OUTPUT_FILE" <<EOF
# ==========================================
# Sui CLI quick reference
# ==========================================

# Environment variables
export PACKAGE_ID=$PACKAGE_ID
export MARKETPLACE_ID=$MARKETPLACE_ID
export ADMIN_CAP_ID=$ADMIN_CAP_ID
export ADMIN_ADDRESS=$ADMIN_ADDRESS
export BUYER_ADDRESS=$BUYER_ADDRESS
export NFT_ID=${NFT_ID:-}
export LISTING_ID=${LISTING_ID:-}
export NFT2_ID=${NFT2_ID:-}
export LISTING2_ID=${LISTING2_ID:-}
export NFT3_ID=${NFT3_ID:-}
export NFT4_ID=${NFT4_ID:-}

# 1. Mint NFT
sui client call \
    --package \$PACKAGE_ID \
    --module marketplace \
    --function mint_nft \
    --args "NFT Name" "Description" "https://url.com" \$ADMIN_ADDRESS \
    --gas-budget 10000000

# 2. List NFT
sui client call \
    --package \$PACKAGE_ID \
    --module marketplace \
    --function list_nft \
    --args \$NFT_ID 1000000000 \
    --gas-budget 10000000

# 3. Buy NFT
sui client call \
    --package \$PACKAGE_ID \
    --module marketplace \
    --function buy_nft \
    --args \$MARKETPLACE_ID {LISTING_ID} {NFT_ID} {COIN_ID} \
    --gas-budget 10000000

# 4. Cancel listing
sui client call \
    --package \$PACKAGE_ID \
    --module marketplace \
    --function cancel_listing \
    --args {LISTING_ID} {NFT_ID} \
    --gas-budget 10000000

# 5. Transfer NFT
sui client call \
    --package \$PACKAGE_ID \
    --module marketplace \
    --function public_transfer_nft \
    --args {NFT_ID} {RECIPIENT_ADDRESS} \
    --gas-budget 10000000

# 6. Freeze NFT
sui client call \
    --package \$PACKAGE_ID \
    --module marketplace \
    --function freeze_nft \
    --args {NFT_ID} \
    --gas-budget 10000000

# 7. Update fee (requires AdminCap)
sui client call \
    --package \$PACKAGE_ID \
    --module marketplace \
    --function update_fee \
    --args \$ADMIN_CAP_ID \$MARKETPLACE_ID 5 \
    --gas-budget 10000000

# 8. Withdraw fees (requires AdminCap)
sui client call \
    --package \$PACKAGE_ID \
    --module marketplace \
    --function withdraw_fees \
    --args \$ADMIN_CAP_ID \$MARKETPLACE_ID 1000000 \$ADMIN_ADDRESS \
    --gas-budget 10000000

# Query commands
sui client object {OBJECT_ID}
sui client object {OBJECT_ID} --json
sui client gas
sui client events --package \$PACKAGE_ID
sui client active-address
sui client addresses
EOF

echo_info "Command reference saved to $OUTPUT_FILE"

echo ""

