#!/usr/bin/env bash
# SessionStart hook for superpowers plugin

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Build warning for duplicate skill names discovered in both Codex skill roots.
build_codex_duplicate_skill_warning() {
    local agents_root codex_root tmp_file duplicate_names warning
    agents_root="${HOME}/.agents/skills"
    codex_root="${HOME}/.codex/skills"

    if [ ! -d "$agents_root" ] || [ ! -d "$codex_root" ]; then
        return 0
    fi

    tmp_file="$(mktemp)"
    trap 'rm -f "$tmp_file"' RETURN

    # Collect: skill-name <tab> root <tab> skill-file-path
    while IFS= read -r -d '' skill_file; do
        printf '%s\t%s\t%s\n' "$(basename "$(dirname "$skill_file")")" "$agents_root" "$skill_file" >>"$tmp_file"
    done < <(find "$agents_root" -type f -name 'SKILL.md' -print0 2>/dev/null)

    while IFS= read -r -d '' skill_file; do
        printf '%s\t%s\t%s\n' "$(basename "$(dirname "$skill_file")")" "$codex_root" "$skill_file" >>"$tmp_file"
    done < <(find "$codex_root" -type f -name 'SKILL.md' -print0 2>/dev/null)

    duplicate_names="$(cut -f1 "$tmp_file" | sort | uniq -d)"
    if [ -z "$duplicate_names" ]; then
        return 0
    fi

    warning="\n\n<important-reminder>IN YOUR FIRST REPLY AFTER SEEING THIS MESSAGE YOU MUST TELL THE USER:⚠️ **WARNING:** Duplicate skill names were detected across Codex discovery roots. Codex should prefer ~/.agents/skills for duplicates. Duplicate details:"

    while IFS= read -r skill_name; do
        [ -z "$skill_name" ] && continue

        preferred_path="$(awk -F '\t' -v name="$skill_name" -v agents="$agents_root" '$1==name && $2==agents { print $3; exit }' "$tmp_file")"
        if [ -z "$preferred_path" ]; then
            preferred_path="$(awk -F '\t' -v name="$skill_name" '$1==name { print $3; exit }' "$tmp_file")"
        fi

        warning="${warning}\n- ${skill_name}"
        while IFS=$'\t' read -r _root path; do
            display_path="${path/#$HOME/~}"
            if [ "$path" = "$preferred_path" ]; then
                warning="${warning}\n  - ${display_path} (preferred)"
            else
                warning="${warning}\n  - ${display_path} (duplicate)"
            fi
        done < <(awk -F '\t' -v name="$skill_name" '$1==name { print $2 "\t" $3 }' "$tmp_file")
    done <<<"$duplicate_names"

    warning="${warning}\nRemove deprecated duplicates (typically under ~/.codex/skills) to avoid ambiguity.</important-reminder>"
    printf '%s' "$warning"
}

# Check if legacy skills directory exists and build warning
warning_message=""
legacy_skills_dir="${HOME}/.config/superpowers/skills"
if [ -d "$legacy_skills_dir" ]; then
    warning_message="\n\n<important-reminder>IN YOUR FIRST REPLY AFTER SEEING THIS MESSAGE YOU MUST TELL THE USER:⚠️ **WARNING:** Superpowers now uses Claude Code's skills system. Custom skills in ~/.config/superpowers/skills will not be read. Move custom skills to ~/.claude/skills instead. To make this message go away, remove ~/.config/superpowers/skills</important-reminder>"
fi

duplicate_warning="$(build_codex_duplicate_skill_warning || true)"
if [ -n "$duplicate_warning" ]; then
    warning_message="${warning_message}${duplicate_warning}"
fi

# Read using-superpowers content
using_superpowers_content=$(cat "${PLUGIN_ROOT}/skills/using-superpowers/SKILL.md" 2>&1 || echo "Error reading using-superpowers skill")

# Escape string for JSON embedding using bash parameter substitution.
# Each ${s//old/new} is a single C-level pass - orders of magnitude
# faster than the character-by-character loop this replaces.
escape_for_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

using_superpowers_escaped=$(escape_for_json "$using_superpowers_content")
warning_escaped=$(escape_for_json "$warning_message")

# Output context injection as JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>\nYou have superpowers.\n\n**Below is the full content of your 'superpowers:using-superpowers' skill - your introduction to using skills. For all other skills, use the 'Skill' tool:**\n\n${using_superpowers_escaped}\n\n${warning_escaped}\n</EXTREMELY_IMPORTANT>"
  }
}
EOF

exit 0
