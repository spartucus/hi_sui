#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/prepare.sh"

# ==========================================
# Environment Setup
# ==========================================

echo_step "0" "Prepare environment"

# Set network to testnet
export SUI_NETWORK=testnet

# Set admin address
ADMIN_ADDRESS=0xf80e84025c0c4f4a434da779322ef4ed634422151ca1c5a7cf95323687381e15
echo_info "Admin address: $ADMIN_ADDRESS"

# Set second test address (buyer)
BUYER_ADDRESS=0x3a56a1453d328c5afceba56e55562eb3ddeceaa5084cf9fbb90010273ba1eb45
echo_info "Buyer address: $BUYER_ADDRESS"

set_context_var "SUI_NETWORK" "$SUI_NETWORK"
set_context_var "ADMIN_ADDRESS" "$ADMIN_ADDRESS"
set_context_var "BUYER_ADDRESS" "$BUYER_ADDRESS"
echo_info "Context saved to: $CONTEXT_FILE"

echo ""