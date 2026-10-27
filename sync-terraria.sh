#!/usr/bin/env bash
# sync-terraria.sh — keep Terraria progress synced between the game and this repo.
#
# The same file lives in both Terraria repos; run it from either one:
#   ~/"Terraria Progress"/sync-terraria.sh   flat repo: the save tree is the root
#   ~/My-Configs/sync-terraria.sh            mirror repo: .local/share/Terraria/
#
# Default (backup): pull the last version from GitHub, copy this machine's live
# save into the repo, commit, push. The world rollovers (*.wld.bak/.bak2), the
# ResourcePacks directory and the game install are never copied.
#
#   --restore  the inverse: pull, back up the live save, then put the repo's
#              save into ~/.local/share/Terraria (use this on a second device)
#   --force    continue past the safety checks below
#
# Quit Terraria first: the game rewrites the world when it exits, so a running
# game would save over anything this script writes.

set -euo pipefail

GAME_SAVE="${TERRARIA_SAVE:-$HOME/.local/share/Terraria}"
GAME_RE='Terraria(\.bin\.x86_64)?$'

MODE=backup
FORCE=0

usage() { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; }
die()   { printf 'error: %s\n' "$*" >&2; exit 1; }
info()  { printf '%s\n' "$*"; }
warn()  { printf 'warning: %s\n' "$*" >&2; }

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --restore) MODE=restore ;;
    --force)   FORCE=1 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

# --- locate the repo and the path that holds its copy of the save ------------
SELF="$(readlink -f "${BASH_SOURCE[0]}")"
ROOT="$(dirname "$SELF")"
cd "$ROOT"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "$ROOT is not a git repository"

if [ -d "$ROOT/.local/share/Terraria" ] || [ -f "$ROOT/sync-from-live.sh" ]; then
  REPO_TREE="$ROOT/.local/share/Terraria"   # My-Configs: mirrors the live path
  ADD_PATH=".local/share/Terraria"
else
  REPO_TREE="$ROOT"                          # Terraria Progress: flat layout
  ADD_PATH="."
fi

# --- helpers ----------------------------------------------------------------
# Every file that is part of the playthrough, as paths relative to a save root.
progress_files() {
  local base="$1" f
  (
    cd "$base" 2>/dev/null || exit 0
    find Worlds Players -type f \
      \( -name '*.wld' -o -name '*.plr' -o -name '*.plr.bak' -o -name '*.map' \) \
      2>/dev/null | sort
    for f in achievements.dat config.json favorites.json "input profiles.json"; do
      [ -f "$f" ] && printf '%s\n' "$f"
    done
  ) || true
}

# "sha256  relpath" per file, used to see whether the two trees already match.
progress_hashes() {
  local base="$1" f
  while IFS= read -r f; do
    printf '%s  %s\n' "$(sha256sum "$base/$f" | cut -d' ' -f1)" "$f"
  done < <(progress_files "$base")
}

# Newest mtime (epoch) of the files the game rewrites on every save — the world
# and the characters. Config/map files are ignored: they can be stale for days
# and would hide a genuinely older playthrough.
newest_save_mtime() {
  local base="$1" f t max=0
  (
    cd "$base" 2>/dev/null || exit 0
    find Worlds -type f -name '*.wld' 2>/dev/null
    find Players -maxdepth 1 -type f -name '*.plr' 2>/dev/null
  ) | while IFS= read -r f; do
        stat -c '%Y' "$base/$f" 2>/dev/null || echo 0
      done | sort -n | tail -1
}

game_running() { pgrep -f "$GAME_RE" >/dev/null 2>&1; }

copy_tree() { # copy_tree <src> <dst> — progress files only
  local src="$1" dst="$2" f
  while IFS= read -r f; do
    mkdir -p "$dst/$(dirname "$f")"
    cp -a "$src/$f" "$dst/$f"
  done < <(progress_files "$src")
}

# --- pre-flight -------------------------------------------------------------
[ -d "$GAME_SAVE" ] || die "no Terraria save directory at $GAME_SAVE (set TERRARIA_SAVE)"

if game_running && [ "$FORCE" -eq 0 ]; then
  die "Terraria is running — quit the game first (or pass --force, e.g. to test)"
fi

# --- update from the last version -------------------------------------------
if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  info "pulling the last version from GitHub ..."
  git pull --rebase --autostash --quiet \
    || die "pull failed — fix it with 'git status' and re-run"
else
  info "no upstream yet — the first push will create it"
fi

# --- restore: repo -> game --------------------------------------------------
if [ "$MODE" = restore ]; then
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup="${GAME_SAVE%/}.before-restore-$stamp"
  mkdir -p "$backup"
  cp -a "$GAME_SAVE/." "$backup/" 2>/dev/null || true
  info "live save backed up to $backup"

  copy_tree "$REPO_TREE" "$GAME_SAVE"
  info "restored $(progress_files "$REPO_TREE" | wc -l) files into $GAME_SAVE"
  info "launch Terraria and check the world + character are there."
  exit 0
fi

# --- backup: game -> repo ---------------------------------------------------
live_hash="$(progress_hashes "$GAME_SAVE")"
repo_hash="$(progress_hashes "$REPO_TREE")"

if [ "$live_hash" = "$repo_hash" ]; then
  info "repo already matches the live save — nothing to copy"
else
  repo_epoch="$(git log -1 --format=%ct -- "$ADD_PATH" 2>/dev/null || true)"
  repo_epoch="${repo_epoch:-0}"
  live_epoch="$(newest_save_mtime "$GAME_SAVE")"
  live_epoch="${live_epoch:-0}"

  if [ "$repo_epoch" -gt $((live_epoch + 60)) ] && [ "$FORCE" -eq 0 ]; then
    warn "the copy in git was committed $(date -d "@$repo_epoch" '+%F %H:%M'),"
    warn "later than your live save ($(date -d "@$live_epoch" '+%F %H:%M'))."
    warn "That usually means another device pushed newer progress."
    warn "  --restore  load the repo's progress here (live save is backed up)"
    warn "  --force    overwrite the repo with this machine's save"
    exit 3
  fi

  copy_tree "$GAME_SAVE" "$REPO_TREE"
  info "copied $(progress_files "$GAME_SAVE" | wc -l) files from $GAME_SAVE"
fi

# --- add, commit, push ------------------------------------------------------
git add -A -- "$ADD_PATH"

if git diff --cached --quiet; then
  info "no change to commit"
else
  git -c core.quotepath=false commit --quiet \
    -m "Terraria progress $(date '+%F %H:%M') ($(hostname))"
  info "committed: $(git log -1 --format='%h %s' --no-decorate)"
fi

if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  git push --quiet
else
  git push --quiet -u origin HEAD
fi
info "pushed to $(git remote get-url origin)"
