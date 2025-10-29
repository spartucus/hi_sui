#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/prepare.sh"

load_context
require_context_vars "PACKAGE_ID" "MARKETPLACE_ID" "ADMIN_CAP_ID" "ADMIN_ADDRESS"

echo_step "9" "Admin functions"

echo_info "9.1 Update marketplace fee to 5%"
sui client call \
    --package "$PACKAGE_ID" \
    --module marketplace \
    --function update_fee \
    --args \
        "$ADMIN_CAP_ID" \
        "$MARKETPLACE_ID" \
        5 \
    --gas-budget 10000000 \
    --json 2>/dev/null | jq '.'

echo_info "Verify updated fee percent:"
MARKETPLACE_STATE=$(sui client object "$MARKETPLACE_ID" --json 2>/dev/null)
if ! echo "$MARKETPLACE_STATE" | jq empty >/dev/null 2>&1; then
    echo -e "${RED}Failed to fetch marketplace state as JSON.${NC}"
    echo "$MARKETPLACE_STATE"
else
    echo "$MARKETPLACE_STATE" | jq '.content.fields.fee_percent'
fi

echo ""

echo_info "9.2 Withdraw marketplace fees"
MARKETPLACE_STATE=$(sui client object "$MARKETPLACE_ID" --json 2>/dev/null)
if ! echo "$MARKETPLACE_STATE" | jq empty >/dev/null 2>&1; then
    echo -e "${RED}Failed to fetch marketplace state as JSON.${NC}"
    echo "$MARKETPLACE_STATE"
    exit 1
fi

PLATFORM_BALANCE=$(echo "$MARKETPLACE_STATE" | jq -r '.content.fields.balance')
echo_info "Current platform balance: $PLATFORM_BALANCE"

if [ "$PLATFORM_BALANCE" != "0" ]; then
    WITHDRAW_AMOUNT=$((PLATFORM_BALANCE / 2))

    sui client call \
        --package "$PACKAGE_ID" \
        --module marketplace \
        --function withdraw_fees \
        --args \
            "$ADMIN_CAP_ID" \
            "$MARKETPLACE_ID" \
            "$WITHDRAW_AMOUNT" \
            "$ADMIN_ADDRESS" \
        --gas-budget 10000000 \
        --json 2>/dev/null | jq '.'

    POST_WITHDRAW_STATE=$(sui client object "$MARKETPLACE_ID" --json 2>/dev/null)
    if ! echo "$POST_WITHDRAW_STATE" | jq empty >/dev/null 2>&1; then
        echo -e "${RED}Failed to fetch marketplace state after withdrawal.${NC}"
        echo "$POST_WITHDRAW_STATE"
    else
        echo_info "Platform balance after withdrawal:"
        echo "$POST_WITHDRAW_STATE" | jq '.content.fields.balance'
    fi
else
    echo_info "Platform balance is zero, skipping withdrawal."
fi

echo ""

