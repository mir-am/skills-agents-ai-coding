#!/bin/bash

# Exit on any error
set -e

# Configuration
SKILLS_SOURCE_DIR="./skills"
SKILLS_TARGET_DIR="$HOME/.config/opencode/skills"
AGENTS_SOURCE_DIR="./agents"
AGENTS_TARGET_DIR="$HOME/.config/opencode/agents"
DRY_RUN=false

# Color detection - only use colors if stdout is a terminal
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  RED='\033[0;31m'
  GRAY='\033[0;90m'
  RESET='\033[0m'
else
  # No colors for pipes/redirects
  GREEN=''
  YELLOW=''
  BLUE=''
  RED=''
  GRAY=''
  RESET=''
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--dry-run]"
      exit 1
      ;;
  esac
done

# Helper function: Calculate directory hash
calculate_dir_hash() {
  local dir="$1"
  # Find all files, sort by relative path, hash contents only, create single hash
  (cd "$dir" && find . -type f -print0 | sort -z | xargs -0 md5sum) | md5sum | cut -d' ' -f1
}

# Helper function: Sync a single skill
sync_skill() {
  local skill_name="$1"
  local source_path="$SKILLS_SOURCE_DIR/$skill_name"
  local target_path="$SKILLS_TARGET_DIR/$skill_name"
  
  # Calculate source hash
  local source_hash=$(calculate_dir_hash "$source_path")
  
  # Check if target exists
  if [ ! -d "$target_path" ]; then
    echo -e "${BLUE}→${RESET} Installing: ${skill_name}"
    if [ "$DRY_RUN" = true ]; then
      rsync -a --dry-run "$source_path/" "$target_path/"
      echo -e "${GREEN}✓${RESET} Would install: ${skill_name}"
    else
      rsync -a "$source_path/" "$target_path/"
      echo -e "${GREEN}✓${RESET} Installed: ${skill_name}"
    fi
    return 0  # Signal: installed
  fi
  
  # Target exists - compare hashes
  local target_hash=$(calculate_dir_hash "$target_path")
  
  if [ "$source_hash" != "$target_hash" ]; then
    echo -e "${YELLOW}→${RESET} Updating: ${skill_name}"
    if [ "$DRY_RUN" = true ]; then
      rsync -a --delete --dry-run "$source_path/" "$target_path/"
      echo -e "${YELLOW}↻${RESET} Would update: ${skill_name}"
    else
      rsync -a --delete "$source_path/" "$target_path/"
      echo -e "${YELLOW}↻${RESET} Updated: ${skill_name}"
    fi
    return 1  # Signal: updated
  else
    echo -e "${GRAY}✓${RESET} Up-to-date: ${skill_name}"
    return 2  # Signal: unchanged
  fi
}

# Helper function: Calculate file hash
calculate_file_hash() {
  local file="$1"
  md5sum "$file" | cut -d' ' -f1
}

# Helper function: Sync a single agent (flat .md file)
sync_agent() {
  local agent_file="$1"
  local source_path="$AGENTS_SOURCE_DIR/$agent_file"
  local target_path="$AGENTS_TARGET_DIR/$agent_file"

  # Calculate source hash
  local source_hash=$(calculate_file_hash "$source_path")

  # Check if target exists
  if [ ! -f "$target_path" ]; then
    echo -e "${BLUE}→${RESET} Installing: ${agent_file}"
    if [ "$DRY_RUN" = true ]; then
      echo -e "${GREEN}✓${RESET} Would install: ${agent_file}"
    else
      cp "$source_path" "$target_path"
      echo -e "${GREEN}✓${RESET} Installed: ${agent_file}"
    fi
    return 0  # Signal: installed
  fi

  # Target exists - compare hashes
  local target_hash=$(calculate_file_hash "$target_path")

  if [ "$source_hash" != "$target_hash" ]; then
    echo -e "${YELLOW}→${RESET} Updating: ${agent_file}"
    if [ "$DRY_RUN" = true ]; then
      echo -e "${YELLOW}↻${RESET} Would update: ${agent_file}"
    else
      cp "$source_path" "$target_path"
      echo -e "${YELLOW}↻${RESET} Updated: ${agent_file}"
    fi
    return 1  # Signal: updated
  else
    echo -e "${GRAY}✓${RESET} Up-to-date: ${agent_file}"
    return 2  # Signal: unchanged
  fi
}

# Main script logic

# Print header
if [ "$DRY_RUN" = true ]; then
  echo -e "${BLUE}🔍 DRY RUN MODE - No changes will be made${RESET}"
fi
echo "Syncing skills from $SKILLS_SOURCE_DIR to $SKILLS_TARGET_DIR"
echo ""

# Validate source directory exists
if [ ! -d "$SKILLS_SOURCE_DIR" ]; then
  echo -e "${RED}ERROR: Source directory '$SKILLS_SOURCE_DIR' does not exist${RESET}"
  exit 1
fi

# Create target directory if needed
mkdir -p "$SKILLS_TARGET_DIR"

# Initialize counters
skills_installed=0
skills_updated=0
skills_unchanged=0

# Loop through each skill subdirectory
for skill_dir in "$SKILLS_SOURCE_DIR"/*; do
  # Skip if not a directory
  [ -d "$skill_dir" ] || continue
  
  skill_name=$(basename "$skill_dir")
  
  # Call sync_skill and capture return code
  # Temporarily disable exit-on-error to capture return codes
  set +e
  sync_skill "$skill_name"
  result=$?
  set -e
  
  case $result in
    0) skills_installed=$((skills_installed + 1)) ;;
    1) skills_updated=$((skills_updated + 1)) ;;
    2) skills_unchanged=$((skills_unchanged + 1)) ;;
  esac
done

# Print skills summary
echo ""
if [ "$DRY_RUN" = true ]; then
  echo -e "${GREEN}Skills:${RESET} $skills_installed would be installed, $skills_updated would be updated, $skills_unchanged up-to-date"
else
  echo -e "${GREEN}Skills:${RESET} $skills_installed installed, $skills_updated updated, $skills_unchanged up-to-date"
fi

# ── Agents sync ──────────────────────────────────────────────────────

if [ -d "$AGENTS_SOURCE_DIR" ]; then
  echo ""
  echo "Syncing agents from $AGENTS_SOURCE_DIR to $AGENTS_TARGET_DIR"
  echo ""

  # Create target directory if needed
  mkdir -p "$AGENTS_TARGET_DIR"

  # Initialize counters
  agents_installed=0
  agents_updated=0
  agents_unchanged=0

  # Loop through each agent .md file
  for agent_path in "$AGENTS_SOURCE_DIR"/*.md; do
    # Skip if no .md files found (glob didn't match)
    [ -f "$agent_path" ] || continue

    agent_file=$(basename "$agent_path")

    # Call sync_agent and capture return code
    set +e
    sync_agent "$agent_file"
    result=$?
    set -e

    case $result in
      0) agents_installed=$((agents_installed + 1)) ;;
      1) agents_updated=$((agents_updated + 1)) ;;
      2) agents_unchanged=$((agents_unchanged + 1)) ;;
    esac
  done

  # Print agents summary
  echo ""
  if [ "$DRY_RUN" = true ]; then
    echo -e "${GREEN}Agents:${RESET} $agents_installed would be installed, $agents_updated would be updated, $agents_unchanged up-to-date"
  else
    echo -e "${GREEN}Agents:${RESET} $agents_installed installed, $agents_updated updated, $agents_unchanged up-to-date"
  fi
fi
