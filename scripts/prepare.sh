#!/bin/bash

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ -z "${SCRIPT_DIR:-}" ]; then
    echo "SCRIPT_DIR is not set before sourcing prepare.sh"
    exit 1
fi

CONTEXT_FILE="$SCRIPT_DIR/.sui_env"

echo_step() {
    echo -e "${GREEN}[步骤 $1]${NC} $2"
}

echo_info() {
    echo -e "${YELLOW}ℹ ${NC} $1"
}

ensure_context_file() {
    if [ ! -f "$CONTEXT_FILE" ]; then
        touch "$CONTEXT_FILE"
    fi
}

set_context_var() {
    local key="$1"
    local value="$2"
    ensure_context_file

    local tmp_file
    tmp_file=$(mktemp "$CONTEXT_FILE.XXXXXX")

    if [ -s "$CONTEXT_FILE" ]; then
        awk -v k="$key" -v v="$value" '
            BEGIN {found=0}
            $0 ~ "^"k"=" {print k"="v; found=1; next}
            NF==0 {next}
            {print}
            END {if(found==0) print k"="v}
        ' "$CONTEXT_FILE" > "$tmp_file"
    else
        printf '%s=%s\n' "$key" "$value" > "$tmp_file"
    fi

    mv "$tmp_file" "$CONTEXT_FILE"
}

load_context() {
    ensure_context_file
    if [ -s "$CONTEXT_FILE" ]; then
        set -a
        # shellcheck disable=SC1090
        source "$CONTEXT_FILE"
        set +a
    fi
}

require_context_vars() {
    local -a missing=()
    for var in "$@"; do
        if [ -z "${!var:-}" ]; then
            missing+=("$var")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}Missing context variables: ${missing[*]}${NC}"
        exit 1
    fi
}

# Helper: run sui command and ignore warnings
sui_call_json() {
    "$@" 2>/dev/null
}