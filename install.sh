#!/bin/bash

# AI Chief of Staff — Installer
# Sets up your personal AI operating system in ~/.claude/

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo ""
echo -e "${BOLD}============================================${NC}"
echo -e "${BOLD}   AI Chief of Staff — Setup${NC}"
echo -e "${BOLD}============================================${NC}"
echo ""
echo "This will set up your personal AI operating system"
echo "by installing template files to ~/.claude/"
echo ""

# Check for Claude Code
if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}Warning: Claude Code CLI not found.${NC}"
    echo "Install it from: https://docs.anthropic.com/en/docs/claude-code"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Gather user info
echo -e "${BLUE}Let's personalize your setup.${NC}"
echo ""

read -p "Your full name: " USER_NAME
read -p "Your first name (for email sign-offs): " FIRST_NAME
read -p "Your role/title: " USER_ROLE
read -p "Your company: " USER_COMPANY
read -p "Work email: " WORK_EMAIL
read -p "Personal email: " PERSONAL_EMAIL
read -p "Company website (e.g., example.com): " COMPANY_URL

echo ""
echo -e "${BLUE}Time constraints (leave blank to skip):${NC}"
read -p "Home by what time? (e.g., 6:00 PM): " DINNER_TIME
read -p "Earliest meeting time? (e.g., 9:00 AM): " EARLIEST_MEETING

echo ""
echo -e "${BLUE}Preferences:${NC}"
read -p "Currency (USD/CAD/EUR/GBP): " CURRENCY
CURRENCY=${CURRENCY:-USD}
read -p "Timezone (e.g., America/New_York): " TIMEZONE
TIMEZONE=${TIMEZONE:-America/New_York}

# Escape special characters for safe sed replacement
# Handles: \ / & newlines and other sed metacharacters
escape_for_sed() {
    printf '%s' "$1" | sed -e 's/[\/&\\]/\\&/g'
}

# Create directory structure
echo ""
echo -e "${GREEN}Creating directory structure...${NC}"

CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/contacts"
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/objectives"
mkdir -p "$CLAUDE_DIR/task-outputs"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Copy and customize CLAUDE.md (protect existing config)
echo -e "${GREEN}Customizing CLAUDE.md...${NC}"

if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    echo -e "${YELLOW}Existing CLAUDE.md found. Backing up to CLAUDE.md.backup${NC}"
    cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.backup"
    read -p "Overwrite with fresh template? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "  Keeping existing CLAUDE.md"
        SKIP_CLAUDE_MD=true
    fi
fi

if [ "${SKIP_CLAUDE_MD}" != "true" ]; then
    cp "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

    # Sanitize all user inputs before sed replacement
    S_USER_NAME=$(escape_for_sed "$USER_NAME")
    S_FIRST_NAME=$(escape_for_sed "$FIRST_NAME")
    S_USER_ROLE=$(escape_for_sed "$USER_ROLE")
    S_USER_COMPANY=$(escape_for_sed "$USER_COMPANY")
    S_WORK_EMAIL=$(escape_for_sed "$WORK_EMAIL")
    S_PERSONAL_EMAIL=$(escape_for_sed "$PERSONAL_EMAIL")
    S_COMPANY_URL=$(escape_for_sed "$COMPANY_URL")
    S_CURRENCY=$(escape_for_sed "$CURRENCY")
    S_TIMEZONE=$(escape_for_sed "$TIMEZONE")

    # Replace placeholders with sanitized values
    sed -i.bak "s/{{YOUR_NAME}}/$S_USER_NAME/g" "$CLAUDE_DIR/CLAUDE.md"
    sed -i.bak "s/{{YOUR_FIRST_NAME}}/$S_FIRST_NAME/g" "$CLAUDE_DIR/CLAUDE.md"
    sed -i.bak "s/{{YOUR_ROLE}}/$S_USER_ROLE/g" "$CLAUDE_DIR/CLAUDE.md"
    sed -i.bak "s/{{YOUR_COMPANY}}/$S_USER_COMPANY/g" "$CLAUDE_DIR/CLAUDE.md"
    sed -i.bak "s/{{WORK_EMAIL}}/$S_WORK_EMAIL/g" "$CLAUDE_DIR/CLAUDE.md"
    sed -i.bak "s/{{PERSONAL_EMAIL}}/$S_PERSONAL_EMAIL/g" "$CLAUDE_DIR/CLAUDE.md"
    sed -i.bak "s/{{COMPANY_URL}}/$S_COMPANY_URL/g" "$CLAUDE_DIR/CLAUDE.md"
    sed -i.bak "s/{{CURRENCY}}/$S_CURRENCY/g" "$CLAUDE_DIR/CLAUDE.md"
    sed -i.bak "s/{{TIMEZONE}}/$S_TIMEZONE/g" "$CLAUDE_DIR/CLAUDE.md"

    if [ -n "$DINNER_TIME" ]; then
        S_DINNER_TIME=$(escape_for_sed "$DINNER_TIME")
        sed -i.bak "s/{{DINNER_TIME}}/$S_DINNER_TIME/g" "$CLAUDE_DIR/CLAUDE.md"
    fi
    if [ -n "$EARLIEST_MEETING" ]; then
        S_EARLIEST_MEETING=$(escape_for_sed "$EARLIEST_MEETING")
        sed -i.bak "s/{{EARLIEST_MEETING_TIME}}/$S_EARLIEST_MEETING/g" "$CLAUDE_DIR/CLAUDE.md"
    fi

    # Clean up sed backup files
    rm -f "$CLAUDE_DIR/CLAUDE.md.bak"
fi

# Copy template files (don't overwrite existing)
echo -e "${GREEN}Installing template files...${NC}"

copy_if_missing() {
    local src="$1"
    local dest="$2"
    if [ ! -f "$dest" ]; then
        cp "$src" "$dest"
        echo "  Created: $dest"
    else
        echo -e "  ${YELLOW}Skipped (already exists):${NC} $dest"
    fi
}

copy_if_missing "$SCRIPT_DIR/goals.yaml" "$CLAUDE_DIR/goals.yaml"
copy_if_missing "$SCRIPT_DIR/my-tasks.yaml" "$CLAUDE_DIR/my-tasks.yaml"
copy_if_missing "$SCRIPT_DIR/schedules.yaml" "$CLAUDE_DIR/schedules.yaml"
copy_if_missing "$SCRIPT_DIR/contacts/example-contact.md" "$CLAUDE_DIR/contacts/example-contact.md"

# Copy commands
for cmd in "$SCRIPT_DIR/commands/"*.md; do
    if [ -f "$cmd" ]; then
        filename=$(basename "$cmd")
        copy_if_missing "$cmd" "$CLAUDE_DIR/commands/$filename"
    fi
done

# Summary
echo ""
echo -e "${BOLD}============================================${NC}"
echo -e "${GREEN}${BOLD}   Setup Complete!${NC}"
echo -e "${BOLD}============================================${NC}"
echo ""
echo "Files installed to: $CLAUDE_DIR/"
echo ""
echo -e "${BOLD}Installed:${NC}"
echo "  CLAUDE.md          — Your AI operating system config"
echo "  goals.yaml         — Quarterly objectives (edit these!)"
echo "  my-tasks.yaml      — Task tracking"
echo "  schedules.yaml     — Automation schedules"
echo "  contacts/          — Contact files"
echo "  commands/          — Skill definitions (gm, triage, my-tasks, enrich)"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo ""
echo -e "  ${BLUE}1.${NC} Connect MCP servers (at minimum: Gmail + Google Calendar)"
echo "     See docs/mcp-servers.md for installation instructions"
echo ""
echo -e "  ${BLUE}2.${NC} Edit your goals:"
echo "     Open $CLAUDE_DIR/goals.yaml and define your real objectives"
echo ""
echo -e "  ${BLUE}3.${NC} Customize your CLAUDE.md:"
echo "     Open $CLAUDE_DIR/CLAUDE.md and fill in the remaining placeholders"
echo "     (writing style, team members, hard constraints)"
echo ""
echo -e "  ${BLUE}4.${NC} Try it out:"
echo "     $ claude"
echo "     > /gm            # Morning briefing"
echo "     > /triage         # Inbox triage"
echo "     > /my-tasks list  # See your tasks"
echo ""
echo -e "${YELLOW}Tip:${NC} The more you customize CLAUDE.md, the better Claude performs."
echo "     Spend 30 minutes filling in your writing style examples and team info."
echo ""
