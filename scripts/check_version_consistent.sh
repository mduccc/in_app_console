#!/usr/bin/env bash

# Script to check version consistency across in_app_console and all extension packages.
#
# Checks:
#   in_app_console  : pubspec.yaml version == README.md dependency reference
#   Each extension  : pubspec.yaml version == CHANGELOG.md latest entry
#                                          == String get version in Dart source

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PACKAGES_DIR="$ROOT_DIR/packages"

PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { echo -e "  ${GREEN}✅  $1${RESET}"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}❌  $1${RESET}"; FAIL=$((FAIL + 1)); }

echo ""
echo -e "${BOLD}========================================"
echo -e " Version Consistency Check"
echo -e "========================================${RESET}"

# ─────────────────────────────────────────
# 1. Main package: in_app_console
# ─────────────────────────────────────────
echo ""
echo -e "${BOLD}[in_app_console]${RESET}"

MAIN_PUBSPEC="$ROOT_DIR/pubspec.yaml"
MAIN_README="$ROOT_DIR/README.md"

MAIN_VERSION=$(grep -E '^version:' "$MAIN_PUBSPEC" | sed -E 's/version:[[:space:]]*//')

if [ -z "$MAIN_VERSION" ]; then
  fail "Could not extract version from pubspec.yaml"
else
  echo "  pubspec.yaml  → $MAIN_VERSION"

  # README must contain `in_app_console: ^X.Y.Z` where X.Y.Z == MAIN_VERSION
  README_VERSION=$(grep -oE 'in_app_console: \^[0-9]+\.[0-9]+\.[0-9]+' "$MAIN_README" \
    | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

  if [ -z "$README_VERSION" ]; then
    fail "Could not find 'in_app_console: ^X.Y.Z' dependency reference in README.md"
  elif [ "$README_VERSION" != "$MAIN_VERSION" ]; then
    fail "README.md shows ^${README_VERSION} but pubspec.yaml is ${MAIN_VERSION}"
  else
    ok "README.md (^${README_VERSION}) matches pubspec.yaml (${MAIN_VERSION})"
  fi
fi

# ─────────────────────────────────────────
# 2. Extension packages
# ─────────────────────────────────────────
for EXT_DIR in "$PACKAGES_DIR"/*/; do
  EXT_NAME=$(basename "$EXT_DIR")
  EXT_PUBSPEC="${EXT_DIR}pubspec.yaml"
  EXT_CHANGELOG="${EXT_DIR}CHANGELOG.md"

  echo ""
  echo -e "${BOLD}[$EXT_NAME]${RESET}"

  # --- pubspec.yaml version (source of truth) ---
  PKG_VERSION=$(grep -E '^version:' "$EXT_PUBSPEC" | sed -E 's/version:[[:space:]]*//')
  if [ -z "$PKG_VERSION" ]; then
    fail "Could not extract version from pubspec.yaml"
    continue
  fi
  echo "  pubspec.yaml          → $PKG_VERSION"

  # --- CHANGELOG.md: first ## heading ---
  if [ ! -f "$EXT_CHANGELOG" ]; then
    fail "CHANGELOG.md not found"
  else
    CHANGELOG_VERSION=$(grep -oE '^## [0-9]+\.[0-9]+\.[0-9]+' "$EXT_CHANGELOG" \
      | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    if [ -z "$CHANGELOG_VERSION" ]; then
      fail "No version heading (## X.Y.Z) found in CHANGELOG.md"
    elif [ "$CHANGELOG_VERSION" != "$PKG_VERSION" ]; then
      fail "CHANGELOG.md latest entry is ${CHANGELOG_VERSION} but pubspec.yaml is ${PKG_VERSION}"
    else
      ok "CHANGELOG.md (${CHANGELOG_VERSION}) matches pubspec.yaml (${PKG_VERSION})"
    fi
  fi

  # --- Dart source: String get version ---
  DART_FILE=$(grep -rl "String get version" "${EXT_DIR}lib/" 2>/dev/null | head -1)
  if [ -z "$DART_FILE" ]; then
    fail "No Dart file with 'String get version' found under lib/"
  else
    DART_VERSION=$(grep -oE "String get version => '[0-9]+\.[0-9]+\.[0-9]+'" "$DART_FILE" \
      | grep -oE "'[0-9]+\.[0-9]+\.[0-9]+'" | tr -d "'")
    DART_BASENAME=$(basename "$DART_FILE")
    if [ -z "$DART_VERSION" ]; then
      fail "${DART_BASENAME}: could not parse version from 'String get version'"
    elif [ "$DART_VERSION" != "$PKG_VERSION" ]; then
      fail "${DART_BASENAME}: String get version = '${DART_VERSION}' but pubspec.yaml is ${PKG_VERSION}"
    else
      ok "${DART_BASENAME}: String get version ('${DART_VERSION}') matches pubspec.yaml (${PKG_VERSION})"
    fi
  fi
done

# ─────────────────────────────────────────
# Summary
# ─────────────────────────────────────────
echo ""
echo -e "${BOLD}========================================"
TOTAL=$((PASS + FAIL))
if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}${BOLD}✅  All consistent! ($PASS/$TOTAL checks passed)"
else
  echo -e "${RED}${BOLD}❌  Inconsistencies found — $FAIL of $TOTAL checks failed"
fi
echo -e "${RESET}${BOLD}========================================${RESET}"
echo ""

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
