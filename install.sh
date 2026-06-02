#!/usr/bin/env bash
#
# Code Quality Skills installer
#
# Deploys the /quality framework into Claude Code:
#   - 13 agent files into ~/.claude/agents/quality-*.md
#   - 1 orchestrator command into ~/.claude/commands/quality.md
#
# Each agent file references the canonical skill markdown in this repo;
# the installer substitutes __SKILLS_DIR__ with the absolute path of
# wherever this repo lives on the user's machine.
#
# --link wires CONSTITUTION.md into Claude Code, Codex, and Copilot from a
# single canonical source (no content copies): a Claude @import line, a
# ~/.codex/AGENTS.md symlink, and an instructions/ symlink + VS Code
# settings snippet for Copilot.
#
# --copilot (re)generates a self-contained Copilot instructions file (the
# Constitution inlined, since Copilot can't resolve @import). Re-run it
# whenever CONSTITUTION.md changes to keep Copilot in sync.
#
# Usage:
#   bash install.sh                       # install with defaults
#   bash install.sh --dry-run             # show what would happen
#   bash install.sh --force               # overwrite without backups
#   bash install.sh --link                # also link CONSTITUTION.md into Claude/Codex/Copilot
#   bash install.sh --name "Your Name"    # greeting name for the Constitution (asked if omitted, with --link)
#   bash install.sh --poem                # enable the haiku/limerick sign-off (off by default; --no-poem to disable)
#   bash install.sh --copilot             # (re)generate self-contained Copilot file [--copilot-prefix F] [--copilot-out F]
#   bash install.sh --skills-dir /path    # canonical docs live elsewhere
#   bash install.sh --claude-home /path   # non-standard ~/.claude location
#   bash install.sh --uninstall           # remove what was installed (incl. links)
#   bash install.sh --help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SKILLS_DIR="${SKILLS_DIR:-$SCRIPT_DIR}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
FORCE=0
DRY_RUN=0
UNINSTALL=0
LINK=0
USER_NAME=""
POEM=""
COPILOT=0
COPILOT_PREFIX=""
COPILOT_OUT=""

usage() {
  sed -n '2,33p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills-dir)  SKILLS_DIR="$2"; shift 2;;
    --claude-home) CLAUDE_HOME="$2"; shift 2;;
    --force|-f)    FORCE=1; shift;;
    --dry-run|-n)  DRY_RUN=1; shift;;
    --link)        LINK=1; shift;;
    --name)        USER_NAME="$2"; shift 2;;
    --poem)        POEM=1; shift;;
    --no-poem)     POEM=0; shift;;
    --copilot)         COPILOT=1; shift;;
    --copilot-prefix)  COPILOT_PREFIX="$2"; shift 2;;
    --copilot-out)     COPILOT_OUT="$2"; shift 2;;
    --uninstall)   UNINSTALL=1; shift;;
    --help|-h)     usage 0;;
    *) echo "Unknown option: $1" >&2; usage 1;;
  esac
done

SKILLS_DIR="$(cd "$SKILLS_DIR" 2>/dev/null && pwd || echo "$SKILLS_DIR")"

AGENTS_SRC="$SCRIPT_DIR/claude/agents"
COMMANDS_SRC="$SCRIPT_DIR/claude/commands"
AGENTS_DEST="$CLAUDE_HOME/agents"
COMMANDS_DEST="$CLAUDE_HOME/commands"

log()  { printf '  %s\n' "$*"; }
note() { printf '\n[%s] %s\n' "$1" "$2"; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "dry-run: $*"
  else
    "$@"
  fi
}

if [[ "$UNINSTALL" -eq 1 ]]; then
  note "UNINSTALL" "removing files from $CLAUDE_HOME"
  for src in "$AGENTS_SRC"/quality-*.md; do
    [[ -e "$src" ]] || continue
    name="$(basename "$src")"
    target="$AGENTS_DEST/$name"
    if [[ -f "$target" ]]; then
      run rm -f "$target"
      log "removed $target"
    fi
  done
  if [[ -f "$COMMANDS_DEST/quality.md" ]]; then
    run rm -f "$COMMANDS_DEST/quality.md"
    log "removed $COMMANDS_DEST/quality.md"
  fi

  # Tear down anything --link created (only our own symlinks / import line).
  const="$SKILLS_DIR/CONSTITUTION.md"
  selfcontained="${COPILOT_OUT:-$SKILLS_DIR/instructions/copilot-instructions.md}"
  codex_link="$HOME/.codex/AGENTS.md"
  if [[ -L "$codex_link" ]]; then
    codex_tgt="$(readlink "$codex_link")"
    if [[ "$codex_tgt" == "$const" || "$codex_tgt" == "$selfcontained" ]]; then
      run rm -f "$codex_link"
      log "removed $codex_link"
    fi
  fi
  inst_link="$SKILLS_DIR/instructions/CONSTITUTION.instructions.md"
  if [[ -L "$inst_link" ]]; then
    run rm -f "$inst_link"
    log "removed $inst_link"
  fi
  claude_md="$CLAUDE_HOME/CLAUDE.md"
  if [[ -f "$claude_md" ]] && grep -qF "@$const" "$claude_md"; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "dry-run: would remove import line from $claude_md"
    else
      tmp="$(mktemp)"
      grep -vF "@$const" "$claude_md" > "$tmp" && mv "$tmp" "$claude_md"
      log "removed import line from $claude_md"
    fi
  fi

  note "DONE" "uninstall complete"
  exit 0
fi

[[ -d "$AGENTS_SRC" ]]   || die "missing $AGENTS_SRC — is this a clone of the repo?"
[[ -d "$COMMANDS_SRC" ]] || die "missing $COMMANDS_SRC"
[[ -f "$SKILLS_DIR/skills/code-quality.md" ]] || die "skills dir invalid: $SKILLS_DIR (no skills/code-quality.md found)"

note "PLAN" "installing /quality framework"
log "skills dir:    $SKILLS_DIR"
log "claude home:   $CLAUDE_HOME"
log "agents dest:   $AGENTS_DEST"
log "commands dest: $COMMANDS_DEST"
[[ "$DRY_RUN" -eq 1 ]] && log "mode:          DRY RUN"
[[ "$FORCE"   -eq 1 ]] && log "mode:          FORCE (no backups)"

if [[ ! -d "$CLAUDE_HOME" ]]; then
  log "warning:       $CLAUDE_HOME does not exist — Claude Code may not be installed"
  log "               see https://docs.claude.com/claude-code (continuing anyway)"
fi

run mkdir -p "$AGENTS_DEST" "$COMMANDS_DEST"

backup_if_needed() {
  local target="$1"
  [[ -f "$target" ]] || return 0
  [[ "$FORCE" -eq 1 ]] && return 0
  local stamp; stamp="$(date +%Y%m%d-%H%M%S)"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "dry-run: would back up $(basename "$target") → $(basename "$target").bak.$stamp"
  else
    cp "$target" "$target.bak.$stamp"
    log "backed up existing → $(basename "$target").bak.$stamp"
  fi
}

install_file() {
  local src="$1" dest="$2"
  local tmp; tmp="$(mktemp)"
  sed "s|__SKILLS_DIR__|${SKILLS_DIR}|g" "$src" > "$tmp"
  if [[ -f "$dest" ]] && cmp -s "$tmp" "$dest"; then
    rm -f "$tmp"
    log "unchanged $(basename "$dest")"
    return 0
  fi
  backup_if_needed "$dest"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    rm -f "$tmp"
    log "dry-run: would install $dest"
  else
    mv "$tmp" "$dest"
    log "installed $dest"
  fi
}

# Point a symlink at a single canonical source — no content copy.
link_symlink() {
  local target="$1" linkpath="$2"
  if [[ -L "$linkpath" && "$(readlink "$linkpath")" == "$target" ]]; then
    log "unchanged $linkpath → $target"
    return 0
  fi
  if [[ -e "$linkpath" || -L "$linkpath" ]]; then
    backup_if_needed "$linkpath"   # preserves an existing real file
    run rm -f "$linkpath"
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "dry-run: would link $linkpath → $target"
  else
    ln -s "$target" "$linkpath"
    log "linked   $linkpath → $target"
  fi
}

# Read the greeting name currently baked into CONSTITUTION.md ("" if unset/placeholder).
current_comms_name() {
  local n
  n="$(sed -n 's/.*Start every answer with "Hey \(.*\)" and end.*/\1/p' "$1" | head -1)"
  [[ "$n" == "__USER_NAME__" ]] && n=""
  printf '%s' "$n"
}

# Is the haiku/limerick sign-off currently enabled in CONSTITUTION.md? (1/0)
current_comms_poem() {
  if sed -n '/BEGIN quality:communication-style/,/END quality:communication-style/p' "$1" | grep -q 'haiku or limerick'; then
    printf '1'
  else
    printf '0'
  fi
}

# Rewrite the communication-style block: greeting name always, haiku/limerick only if poem=1.
personalize_constitution() {
  local file="$1" name="$2" poem="$3"
  if ! grep -q "BEGIN quality:communication-style" "$file"; then
    log "communication-style: markers not found in $(basename "$file") — skipping"
    return 0
  fi
  local pstate="off"; [[ "$poem" == "1" ]] && pstate="on"
  local tmp; tmp="$(mktemp)"
  awk -v name="$name" -v poem="$poem" '
    /<!-- BEGIN quality:communication-style -->/ {
      print
      print "- Start every answer with \"Hey " name "\" and end with \"Cheers " name "!\""
      if (poem == "1") {
        print "- End every answer with a properly formatted haiku or limerick:"
        print "  - Haiku: 5 / 7 / 5 syllables, each on its own line"
        print "  - Limerick: 5 lines, AABBA rhyme"
      }
      skip=1; next
    }
    /<!-- END quality:communication-style -->/ { skip=0; print; next }
    skip { next }
    { print }
  ' "$file" > "$tmp"
  if cmp -s "$tmp" "$file"; then
    rm -f "$tmp"
    log "unchanged communication style (Hey $name, poem $pstate)"
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    rm -f "$tmp"
    log "dry-run: would set greeting 'Hey $name', poem $pstate in $(basename "$file")"
  else
    backup_if_needed "$file"
    mv "$tmp" "$file"
    log "set greeting → 'Hey $name', poem $pstate in $(basename "$file")"
  fi
}

# Generate a self-contained Copilot instructions file: optional personal prefix
# (HIPAA/workflow, with its @import line dropped) + the Constitution inlined.
# Re-run after CONSTITUTION.md changes to keep Copilot in sync.
generate_copilot() {
  local out="$1" prefix="$2" const="$3" have_prefix=0
  if [[ -n "$prefix" && -f "$prefix" ]]; then
    have_prefix=1
  elif [[ -n "$prefix" ]]; then
    log "warning: --copilot-prefix $prefix not found — generating Constitution-only (no HIPAA prefix)"
  fi
  local tmp; tmp="$(mktemp)"
  {
    printf '<!-- GENERATED by install.sh --copilot. Self-contained for Copilot (which cannot\n'
    printf 'resolve @import): Constitution inlined below. Company HIPAA/safety rules inline and\n'
    printf 'first. Do not hand-edit — re-run: bash install.sh --copilot --copilot-prefix <file>. -->\n\n'
    if [[ "$have_prefix" -eq 1 ]]; then
      awk 'BEGIN{c=0} /<!--/{c=1} c{if(/-->/)c=0; next} {print}' "$prefix" | grep -v '^@.*CONSTITUTION\.md$' || true
      printf '\n---\n\n'
    fi
    cat "$const"
  } > "$tmp"
  if [[ -f "$out" ]] && cmp -s "$tmp" "$out"; then
    rm -f "$tmp"
    log "unchanged $out"
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    rm -f "$tmp"
    log "dry-run: would generate $out"
  else
    backup_if_needed "$out"
    mv "$tmp" "$out"
    log "generated $out"
  fi
}

# Append an @import line to a CLAUDE.md if it isn't already there.
ensure_import_line() {
  local file="$1" line="$2"
  if [[ -f "$file" ]] && grep -qF "$line" "$file"; then
    log "unchanged $file (import present)"
    return 0
  fi
  backup_if_needed "$file"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "dry-run: would append '$line' to $file"
  else
    mkdir -p "$(dirname "$file")"
    printf '\n%s\n' "$line" >> "$file"
    log "appended import → $file"
  fi
}

note "AGENTS" "deploying 13 agents → $AGENTS_DEST"
count=0
for src in "$AGENTS_SRC"/quality-*.md; do
  [[ -e "$src" ]] || die "no agent files found in $AGENTS_SRC"
  install_file "$src" "$AGENTS_DEST/$(basename "$src")"
  count=$((count + 1))
done
log "$count agent file(s) processed"

note "ORCHESTRATOR" "deploying /quality command"
install_file "$COMMANDS_SRC/quality.md" "$COMMANDS_DEST/quality.md"

# Generate the self-contained inlined file BEFORE --link, so Codex/Copilot can point at it.
if [[ "$COPILOT" -eq 1 ]]; then
  cp_const="$SKILLS_DIR/CONSTITUTION.md"
  [[ -f "$cp_const" ]] || die "no CONSTITUTION.md at $cp_const — cannot generate Copilot file"
  cp_out="${COPILOT_OUT:-$SKILLS_DIR/instructions/copilot-instructions.md}"
  note "COPILOT" "generating self-contained instructions (vendor prefix + Constitution inlined) — used by Codex & Copilot"
  run mkdir -p "$(dirname "$cp_out")"
  generate_copilot "$cp_out" "$COPILOT_PREFIX" "$cp_const"
  log "point at it — Codex: ~/.codex/AGENTS.md symlink (via --link); IntelliJ: symlink global file; VS Code: settings file ref; github.com: paste"
fi

if [[ "$LINK" -eq 1 ]]; then
  const="$SKILLS_DIR/CONSTITUTION.md"
  [[ -f "$const" ]] || die "no CONSTITUTION.md at $const — cannot link"
  note "LINK" "wiring CONSTITUTION.md into Claude / Codex / Copilot (single source, no copies)"

  # Communication style — set the greeting name (Article IX).
  name="$USER_NAME"
  if [[ -z "$name" ]]; then
    cur="$(current_comms_name "$const")"
    if [[ -n "$cur" ]]; then
      name="$cur"                                   # already personalized — keep it (idempotent)
    elif [[ "$DRY_RUN" -eq 0 && -t 0 ]]; then
      printf '  Name for the Constitution greeting (Hey NAME / Cheers NAME!): '
      read -r name
    fi
  fi
  poem="$POEM"
  [[ -z "$poem" ]] && poem="$(current_comms_poem "$const")"   # no flag → preserve current choice
  if [[ -z "$name" ]]; then
    log "communication-style: no name set (left as __USER_NAME__) — re-run with --name \"Your Name\""
  else
    personalize_constitution "$const" "$name" "$poem"
  fi

  # Claude Code — native @import
  ensure_import_line "$CLAUDE_HOME/CLAUDE.md" "@$const"

  # Codex — point its global agents file at the self-contained inlined file (vendor HIPAA +
  # Constitution) when present, so HIPAA lives in AGENTS.md, not the Constitution. Else bare
  # Constitution. ~/.codex lives elsewhere → absolute target.
  run mkdir -p "$HOME/.codex"
  codex_sc="${COPILOT_OUT:-$SKILLS_DIR/instructions/copilot-instructions.md}"
  if [[ -f "$codex_sc" ]]; then
    link_symlink "$codex_sc" "$HOME/.codex/AGENTS.md"
  else
    link_symlink "$const" "$HOME/.codex/AGENTS.md"
    log "note: Codex AGENTS.md → Constitution only (no vendor HIPAA). Run --copilot --copilot-prefix <file> to generate the self-contained file, then re-link."
  fi

  # Copilot (VS Code) — a *.instructions.md symlink in a dedicated folder (relative target, repo-portable)
  run mkdir -p "$SKILLS_DIR/instructions"
  link_symlink "../CONSTITUTION.md" "$SKILLS_DIR/instructions/CONSTITUTION.instructions.md"

  log "Copilot (VS Code): add to settings.json —"
  log "    \"chat.instructionsFilesLocations\": { \"$SKILLS_DIR/instructions\": true }"
  log "note: github.com web Copilot can't reference external files; commit a copy in-repo if you need it there."
fi

note "DONE" "Claude Code install complete"
log "try it:  open Claude Code in any git repo and run /quality"
[[ "$FORCE" -eq 0 && "$DRY_RUN" -eq 0 ]] && log "backups: any pre-existing files were saved as *.bak.<timestamp>"

cat <<EOF

────────────────────────────────────────────────────────────────────
Copilot & Codex — write-time Constitution (single source, no copies)
────────────────────────────────────────────────────────────────────

Generate the self-contained instructions (your personal prefix + the
Constitution inlined — used by both Codex and Copilot, which can't @import):

  bash install.sh --copilot --copilot-prefix <your-prefix.md>

Then wire it up (or just run --link, which points Codex at it):

  • Codex      ~/.codex/AGENTS.md → $SKILLS_DIR/instructions/copilot-instructions.md
  • Copilot (VS Code)   settings.json:
      "github.copilot.chat.codeGeneration.instructions": [
        { "file": "$SKILLS_DIR/instructions/copilot-instructions.md" }
      ]
  • Copilot (IntelliJ)  symlink ~/.config/github-copilot/intellij/global-copilot-instructions.md → it
  • Copilot (github.com)  paste it into Settings → Copilot → personal custom instructions

Re-run --copilot whenever CONSTITUTION.md changes to keep Codex/Copilot in sync.
EOF
