#!/bin/bash

# Exit on any error
set -e

# Configuration
SOURCE_DIR="./skills"
TARGET_DIR="$HOME/.config/opencode/skills"
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
  local source_path="$SOURCE_DIR/$skill_name"
  local target_path="$TARGET_DIR/$skill_name"
  
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

# Main script logic

# Print header
if [ "$DRY_RUN" = true ]; then
  echo -e "${BLUE}🔍 DRY RUN MODE - No changes will be made${RESET}"
fi
echo "Syncing skills from $SOURCE_DIR to $TARGET_DIR"
echo ""

# Validate source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
  echo -e "${RED}ERROR: Source directory '$SOURCE_DIR' does not exist${RESET}"
  exit 1
fi

# Create target directory if needed
mkdir -p "$TARGET_DIR"

# Initialize counters
installed=0
updated=0
unchanged=0

# Loop through each skill subdirectory
for skill_dir in "$SOURCE_DIR"/*; do
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
    0) installed=$((installed + 1)) ;;
    1) updated=$((updated + 1)) ;;
    2) unchanged=$((unchanged + 1)) ;;
  esac
done

# Print summary
echo ""
if [ "$DRY_RUN" = true ]; then
  echo -e "${GREEN}Summary:${RESET} $installed would be installed, $updated would be updated, $unchanged up-to-date"
else
  echo -e "${GREEN}Summary:${RESET} $installed installed, $updated updated, $unchanged up-to-date"
fi
