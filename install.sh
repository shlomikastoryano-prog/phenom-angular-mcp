#!/usr/bin/env bash
set -e

# ─────────────────────────────────────────────
#  Phenom Angular MCP — Team Install Script
# ─────────────────────────────────────────────

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Phenom Angular MCP — Installer       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── 1. Find where this script lives (the MCP server source) ────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 2. Ask for the install location ────────────────────────────────────────
DEFAULT_INSTALL="$HOME/Documents/Cursor/phenom-angular-mcp"
echo -e "${YELLOW}Where should the MCP server be installed?${NC}"
echo -e "  Press Enter for default: ${DEFAULT_INSTALL}"
read -r INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_INSTALL}"

# ── 3. Ask for the Phenom DS repo path ─────────────────────────────────────

# Try to auto-detect common locations
CANDIDATE_PATHS=(
  "$HOME/Documents/Cursor/Phenom DS/phenom-ds"
  "$HOME/phenom/angular-ds"
  "$HOME/code/phenom-ds"
  "$HOME/Documents/phenom-ds"
)

AUTO_DETECTED=""
for p in "${CANDIDATE_PATHS[@]}"; do
  if [ -d "$p" ]; then
    AUTO_DETECTED="$p"
    break
  fi
done

echo ""
echo -e "${YELLOW}Path to your local Phenom Angular DS repo?${NC}"
if [ -n "$AUTO_DETECTED" ]; then
  echo -e "  Auto-detected: ${GREEN}${AUTO_DETECTED}${NC}"
  echo -e "  Press Enter to use it, or type a different path:"
  read -r DS_PATH
  DS_PATH="${DS_PATH:-$AUTO_DETECTED}"
else
  echo -e "  Example: /Users/yourname/code/phenom-ds"
  read -r DS_PATH
  while [ ! -d "$DS_PATH" ]; do
    echo -e "${RED}  Directory not found. Try again:${NC}"
    read -r DS_PATH
  done
fi

echo ""
echo -e "  ${GREEN}✓${NC} DS repo: ${DS_PATH}"
echo -e "  ${GREEN}✓${NC} Install dir: ${INSTALL_DIR}"
echo ""

# ── 4. Copy/update the server files ────────────────────────────────────────
echo -e "${CYAN}→ Setting up MCP server...${NC}"

if [ "$SCRIPT_DIR" != "$INSTALL_DIR" ]; then
  mkdir -p "$INSTALL_DIR"
  cp -r "$SCRIPT_DIR/." "$INSTALL_DIR/"
fi

cd "$INSTALL_DIR"

# ── 5. Install & build ──────────────────────────────────────────────────────
echo -e "${CYAN}→ Installing dependencies...${NC}"
npm install --silent

echo -e "${CYAN}→ Building...${NC}"
npm run build

echo -e "${GREEN}✓ Build successful${NC}"
echo ""

# ── 6. Merge into ~/.cursor/mcp.json ───────────────────────────────────────
CURSOR_MCP="$HOME/.cursor/mcp.json"
STORYBOOK_URL="https://pds.phenom.com/angular"
SERVER_PATH="${INSTALL_DIR}/dist/index.js"

NEW_SERVERS=$(python3 - <<EOF
import json

new = {
  "phenom-angular": {
    "command": "node",
    "args": ["${SERVER_PATH}"],
    "env": {
      "REPO_PATH": "${DS_PATH}",
      "STORYBOOK_URL": "${STORYBOOK_URL}"
    }
  },
  "storybook-mcp": {
    "command": "npx",
    "args": ["-y", "@raksbisht/storybook-mcp"],
    "env": {
      "STORYBOOK_URL": "${STORYBOOK_URL}"
    }
  }
}

print(json.dumps(new, indent=2))
EOF
)

echo -e "${CYAN}→ Updating ~/.cursor/mcp.json...${NC}"

python3 - <<EOF
import json, os, sys

cursor_mcp = os.path.expanduser("~/.cursor/mcp.json")
new_servers = json.loads("""${NEW_SERVERS}""")

if os.path.exists(cursor_mcp):
    with open(cursor_mcp, "r") as f:
        config = json.load(f)
else:
    config = {}

if "mcpServers" not in config:
    config["mcpServers"] = {}

config["mcpServers"].update(new_servers)

with open(cursor_mcp, "w") as f:
    json.dump(config, f, indent=2)

print("Done")
EOF

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Installation complete! 🎉        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Restart Cursor and go to ${CYAN}Settings → MCP${NC}"
echo -e "  You should see: ${CYAN}phenom-angular${NC} and ${CYAN}storybook-mcp${NC}"
echo ""
echo -e "  Try asking Cursor:"
echo -e "  ${YELLOW}\"Show me all @Input() props for the button component\"${NC}"
echo ""
