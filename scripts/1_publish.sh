#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/prepare.sh"

load_context
require_context_vars "ADMIN_ADDRESS" "BUYER_ADDRESS" "SUI_NETWORK"

# ==========================================
# Step 1: Publish package
# ==========================================

echo_step "1" "Publish package to testnet"

# Publish package (2>/dev/null ignores warnings)
DEPLOY_OUTPUT=$(sui client publish --gas-budget 100000000 --json 2>/dev/null)
# echo "$DEPLOY_OUTPUT" | jq '.'

# Extract important information
PACKAGE_ID=$(echo "$DEPLOY_OUTPUT" | jq -r '.objectChanges[] | select(.type=="published") | .packageId')
MARKETPLACE_ID=$(echo "$DEPLOY_OUTPUT" | jq -r '.objectChanges[] | select(.objectType? and (.objectType | contains("Marketplace"))) | .objectId')
ADMIN_CAP_ID=$(echo "$DEPLOY_OUTPUT" | jq -r '.objectChanges[] | select(.objectType? and (.objectType | contains("AdminCap"))) | .objectId')

if [ -z "$PACKAGE_ID" ] || [ -z "$MARKETPLACE_ID" ] || [ -z "$ADMIN_CAP_ID" ]; then
    echo -e "${RED}Failed to parse deployment output. Please check sui client publish result.${NC}"
    exit 1
fi

set_context_var "PACKAGE_ID" "$PACKAGE_ID"
set_context_var "MARKETPLACE_ID" "$MARKETPLACE_ID"
set_context_var "ADMIN_CAP_ID" "$ADMIN_CAP_ID"
set_context_var "ADMIN_ADDRESS" "$ADMIN_ADDRESS"
set_context_var "BUYER_ADDRESS" "$BUYER_ADDRESS"
set_context_var "SUI_NETWORK" "$SUI_NETWORK"
echo_info "Context updated: $CONTEXT_FILE"

echo_info "Package ID: $PACKAGE_ID"
echo_info "Marketplace ID: $MARKETPLACE_ID"
echo_info "AdminCap ID: $ADMIN_CAP_ID"

echo ""