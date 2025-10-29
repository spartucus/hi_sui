#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/prepare.sh"

load_context
require_context_vars "MARKETPLACE_ID"

echo_step "4" "Inspect marketplace"

echo_info "Marketplace object details:"
MARKETPLACE_DETAILS=$(sui client object "$MARKETPLACE_ID" --json 2>/dev/null)
if ! echo "$MARKETPLACE_DETAILS" | jq empty >/dev/null 2>&1; then
    echo -e "${RED}Failed to fetch marketplace details as JSON.${NC}"
    echo "$MARKETPLACE_DETAILS"
else
    echo "$MARKETPLACE_DETAILS" | jq '.content.fields'
fi

echo ""

