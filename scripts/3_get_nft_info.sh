#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/prepare.sh"

load_context
require_context_vars "PACKAGE_ID" "NFT_ID"

echo_step "3" "Query NFT info (get_nft_info)"

sui client call --package $PACKAGE_ID --module marketplace --function get_nft_info --args $NFT_ID --dev-inspect --json

echo ""

