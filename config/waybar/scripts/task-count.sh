#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar: pending task counter                      ║
# ║  Prefers taskwarrior, falls back to a plain ~/todo.txt.                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

count=""
source_name=""

if command -v task >/dev/null 2>&1; then
    count="$(task status:pending count 2>/dev/null || true)"
    source_name="taskwarrior"
fi

todo_file="${TODO_FILE:-$HOME/todo.txt}"
if [[ ! "$count" =~ ^[0-9]+$ && -f "$todo_file" ]]; then
    count="$(grep -c '^[[:space:]]*[^#[:space:]]' "$todo_file" 2>/dev/null || echo 0)"
    source_name="todo.txt"
fi

count="${count:-0}"
[[ "$count" =~ ^[0-9]+$ ]] || count=0

class="tasks"
(( count > 0 )) && class="tasks has-tasks"
[[ ! -f "$todo_file" ]] && [[ "$source_name" != "taskwarrior" ]] && class="tasks empty"

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' \
    "$count" "$class" "${count} pending task(s)${source_name:+ — source: ${source_name}}"
