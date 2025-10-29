#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/prepare.sh"

load_context
require_context_vars "PACKAGE_ID" "SUI_NETWORK"

echo_step "10" "View events"

echo_info "Fetching RPC endpoint for network: $SUI_NETWORK"
ENV_INFO=$(sui client envs --json 2>/dev/null)
RPC_ENDPOINT=$(echo "$ENV_INFO" | jq -r '.[0][] | select(.alias=="'"$SUI_NETWORK"'") | .rpc' 2>/dev/null)

if [ -z "$RPC_ENDPOINT" ] || [ "$RPC_ENDPOINT" = "null" ]; then
    RPC_ENDPOINT="https://fullnode.$SUI_NETWORK.sui.io:443"
    echo_info "Using default RPC endpoint: $RPC_ENDPOINT"
else
    echo_info "RPC endpoint: $RPC_ENDPOINT"
fi

REQUEST_PAYLOAD=$(cat <<EOF
{"jsonrpc":"2.0","id":1,"method":"suix_queryEvents","params":[{"MoveModule":{"module":"marketplace","package":"$PACKAGE_ID"}},null,20,false]}
EOF
)

echo_info "Querying events via suix_queryEvents..."
EVENT_RESPONSE=$(curl -s -X POST "$RPC_ENDPOINT" -H 'Content-Type: application/json' -d "$REQUEST_PAYLOAD" 2>/dev/null)

if [ -z "$EVENT_RESPONSE" ]; then
    echo -e "${RED}Failed to contact RPC endpoint.${NC}"
    exit 1
fi

if echo "$EVENT_RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
    echo -e "${RED}RPC returned an error:${NC}"
    echo "$EVENT_RESPONSE" | jq '.'
    exit 1
fi

EVENT_COUNT=$(echo "$EVENT_RESPONSE" | jq '.result.data | length')

if [ "$EVENT_COUNT" -eq 0 ]; then
    echo_info "No events found for package $PACKAGE_ID."
else
    echo "$EVENT_RESPONSE" | jq '.result.data[] | {event: .type, sender: .sender, parsed: .parsedJson, timestampMs: .timestampMs}'
fi

echo ""

