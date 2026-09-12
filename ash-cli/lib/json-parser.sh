#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  🧬 ASH JSON ENGINE — RFC 8259 manipulation with graceful degradation         ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Two backends behind one API:                                                 ║
# ║    1. jq        — full JSONPath-lite, fast, preferred                         ║
# ║    2. python3   — fallback when jq is unavailable                             ║
# ║    3. awk       — emergency key/value extraction (no deps at all)             ║
# ║                                                                               ║
# ║  All writes are atomic (mktemp + mv) so a killed process can never leave a    ║
# ║  half-written JSON file on disk.                                              ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_JSON_PARSER_LOADED:-}" ]] && return 0
readonly _ASH_JSON_PARSER_LOADED=1
readonly ASH_JSON_VERSION="5.0.0"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 1  BACKEND DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ash_json_backend() {
    if command -v jq >/dev/null 2>&1;       then printf 'jq'
    elif command -v python3 >/dev/null 2>&1; then printf 'python'
    else printf 'awk'; fi
}

# Probe every available backend and report which ones work.
ash_json_backend_info() {
    printf 'jq     : %s\n' "$(command -v jq 2>/dev/null || echo 'not found')"
    printf 'python3: %s\n' "$(command -v python3 2>/dev/null || echo 'not found')"
    printf 'active : %s\n' "$(_ash_json_backend)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 2  CORE OPERATIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ash_json_get <file|-> <query> [default]
# query: a jq path like ".theme.colors.accent" or ".plugins[] | select(...)"
# Pass "-" as file to read JSON from stdin.
ash_json_get() {
    local src="$1" query="${2:-.}" default="${3-}"
    local backend; backend="$(_ash_json_backend)"
    local payload=""

    if [[ "$src" == "-" ]]; then
        payload="$(cat)"
    else
        [[ -f "$src" ]] || { printf '%s' "$default"; return 1; }
        payload="$(cat "$src" 2>/dev/null)" || { printf '%s' "$default"; return 1; }
    fi

    [[ -z "${payload//[[:space:]]/}" ]] && { printf '%s' "$default"; return 1; }

    local out=""
    case "$backend" in
        jq)
            out="$(printf '%s' "$payload" | jq -r "$query // empty" 2>/dev/null)" || out=""
            ;;
        python)
            out="$(printf '%s' "$payload" | python3 -c '
import json,sys,re
try: data=json.load(sys.stdin)
except Exception: sys.exit(1)
q=sys.argv[1]
# Convert jq-ish ".a.b" / ".a[]" into a traversal
def walk(node, path):
    if not path: yield node; return
    head=path[0]
    if head.endswith("[]"):
        key=head[:-2]
        if key:
            if not isinstance(node,dict) or key not in node: return
            node=node[key]
        if isinstance(node,list):
            for it in node: yield from walk(it, path[1:])
    else:
        if isinstance(node,dict) and head in node:
            yield from walk(node[head], path[1:])
        elif isinstance(node,list) and head.isdigit() and int(head)<len(node):
            yield from walk(node[int(head)], path[1:])
parts=[p for p in re.split(r"\.(?![^\[]*\])", q.strip().lstrip(".")) if p]
res=list(walk(data,parts)) if q.strip()!="." else [data]
if not res: sys.exit(1)
v=res[0] if len(res)==1 else res
if isinstance(v,(dict,list)): print(json.dumps(v))
elif v is True: print("true")
elif v is False: print("false")
elif v is None: print("null")
else: print(v)
' "$query" 2>/dev/null)" || out=""
            ;;
        awk)
            # Flatten "a.b.c" → find the leaf key, print its scalar value.
            local leaf="${query##*.}"
            leaf="${leaf%%[*}"; leaf="${leaf//\"/}"
            out="$(printf '%s' "$payload" | awk -v k="$leaf" '
                {
                    line=$0
                    if (match(line, "\"" k "\"[[:space:]]*:[[:space:]]*")) {
                        rest=substr(line, RSTART+RLENGTH)
                        if (match(rest, /^"[^"]*"/)) { v=substr(rest,2,RLENGTH-2) }
                        else if (match(rest, /^[^,}\]]+/)) { v=substr(rest,1,RLENGTH) }
                        gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
                        if (v != "") { print v; exit }
                    }
                }' 2>/dev/null)" || out=""
            ;;
    esac

    if [[ -z "$out" || "$out" == "null" ]]; then
        printf '%s' "$default"
        [[ -n "$default" ]] && return 0
        return 1
    fi
    printf '%s' "$out"
}

# ash_json_get_raw — keeps the JSON encoding (arrays/objects/true/false intact)
ash_json_get_raw() {
    local src="$1" query="$2" default="${3-}"
    local payload
    if [[ "$src" == "-" ]]; then payload="$(cat)"; else payload="$(cat "$src" 2>/dev/null)"; fi
    [[ -z "$payload" ]] && { printf '%s' "$default"; return 1; }

    local out=""
    if command -v jq >/dev/null 2>&1; then
        out="$(printf '%s' "$payload" | jq -c "$query" 2>/dev/null)" || out=""
    elif command -v python3 >/dev/null 2>&1; then
        out="$(printf '%s' "$payload" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps(eval("d"+sys.argv[1])))' "$query" 2>/dev/null)" || out=""
    fi
    [[ -z "$out" || "$out" == "null" ]] && { printf '%s' "$default"; return 1; }
    printf '%s' "$out"
}

# ash_json_set <file> <query> <value> [--type json|string|number|bool]
ash_json_set() {
    local file="$1" query="$2" value="$3"; shift 3
    local vtype="auto"
    while [[ $# -gt 0 ]]; do
        case "$1" in --type) vtype="$2"; shift 2 ;; *) shift ;; esac
    done

    command -v jq >/dev/null 2>&1 || {
        ash_log_error "ash_json_set requires jq" 2>/dev/null || printf 'ash: jq required\n' >&2
        return 1
    }

    [[ -f "$file" ]] || { mkdir -p "$(dirname "$file")"; printf '{}' > "$file"; }

    local typed
    case "$vtype" in
        json|raw)   typed="$value" ;;
        string)     typed="$(jq -Rn --arg v "$value" '$v')" ;;
        number)     typed="$value" ;;
        bool)       case "${value,,}" in true|1|yes|on) typed="true" ;; *) typed="false" ;; esac ;;
        auto)
            if [[ "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then typed="$value"
            elif [[ "$value" =~ ^(true|false|null)$ ]];      then typed="$value"
            elif [[ "$value" == '['* || "$value" == '{'* ]];  then typed="$value"
            else typed="$(jq -Rn --arg v "$value" '$v')"; fi
            ;;
        *) typed="$value" ;;
    esac

    local tmp; tmp="$(mktemp "${file}.tmp.XXXXXX")" || return 1
    if jq --argjson val "$typed" "$query = \$val" "$file" > "$tmp" 2>/dev/null; then
        chmod --reference="$file" "$tmp" 2>/dev/null || true
        mv -f "$tmp" "$file"
        ash_event_emit "json.changed" "file=${file}" "path=${query}" 2>/dev/null || true
        return 0
    fi
    rm -f "$tmp"
    ash_log_error "invalid jq path or JSON value: ${query}" 2>/dev/null || true
    return 1
}

# ash_json_delete <file> <query>
ash_json_delete() {
    local file="$1" query="$2"
    command -v jq >/dev/null 2>&1 || return 1
    [[ -f "$file" ]] || return 1

    local tmp; tmp="$(mktemp "${file}.tmp.XXXXXX")" || return 1
    if jq "del(${query})" "$file" > "$tmp" 2>/dev/null; then
        mv -f "$tmp" "$file"; return 0
    fi
    rm -f "$tmp"; return 1
}

# ash_json_merge <base> <overlay> [--deep]
ash_json_merge() {
    local base="$1" overlay="$2"; shift 2 || true
    local deep=1
    [[ "${1:-}" == "--shallow" ]] && deep=0

    command -v jq >/dev/null 2>&1 || return 1

    if [[ $deep -eq 1 ]]; then
        jq -s '.[0] * .[1]' "$base" "$overlay" 2>/dev/null
    else
        jq -s '.[0] + .[1]' "$base" "$overlay" 2>/dev/null
    fi
}

# ash_json_keys <file|-> [query]
ash_json_keys() {
    local src="$1" query="${2:-.}"
    if command -v jq >/dev/null 2>&1; then
        if [[ "$src" == "-" ]]; then cat | jq -r "${query} | keys[]" 2>/dev/null
        else jq -r "${query} | keys[]" "$src" 2>/dev/null; fi
    else
        ash_json_get "$src" "${query}" | grep -oP '"\K[^"]+(?="\s*:)' 2>/dev/null
    fi
}

ash_json_length() {
    local src="$1" query="${2:-.}"
    if [[ "$src" == "-" ]]; then cat | jq -r "${query} | length" 2>/dev/null
    else jq -r "${query} | length" "$src" 2>/dev/null; fi
}

# ── Validation ───────────────────────────────────────────────────────────────
ash_json_valid() {
    local src="$1"
    if [[ "$src" == "-" ]]; then
        if command -v jq >/dev/null 2>&1; then cat | jq empty >/dev/null 2>&1
        else cat | python3 -c 'import json,sys; json.load(sys.stdin)' >/dev/null 2>&1; fi
    else
        [[ -f "$src" ]] || return 1
        if command -v jq >/dev/null 2>&1; then jq empty "$src" >/dev/null 2>&1
        else python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$src" >/dev/null 2>&1; fi
    fi
}

# Prints a human-readable diagnostic (JSON pointer + message) on failure.
ash_json_validate_report() {
    local file="$1"
    if ash_json_valid "$file"; then
        printf '  ✓ %s — valid JSON\n' "$file"
        return 0
    fi
    printf '  ✗ %s — INVALID JSON\n' "$file"
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$file" <<'PY' 2>&1 | sed 's/^/      /'
import json, sys
p = sys.argv[1]
try:
    json.load(open(p))
except json.JSONDecodeError as e:
    print(f"line {e.lineno}, column {e.colno}: {e.msg}")
    try:
        line = open(p).read().splitlines()[e.lineno - 1]
        print(line)
        print(" " * (e.colno - 1) + "^")
    except Exception:
        pass
PY
    fi
    return 1
}

# ── Pretty / minify ──────────────────────────────────────────────────────────
ash_json_pretty() {
    local src="$1" indent="${2:-2}"
    if [[ "$src" == "-" ]]; then cat | jq --indent "$indent" . 2>/dev/null
    else jq --indent "$indent" . "$src" 2>/dev/null; fi
}

ash_json_minify() {
    local src="$1"
    if [[ "$src" == "-" ]]; then cat | jq -c . 2>/dev/null
    else jq -c . "$src" 2>/dev/null; fi
}

# ── Construction helpers (used by theme/plugin generators) ───────────────────
ash_json_build() {
    # ash_json_build key1 value1 key2 value2 ...
    local -a args=("$@")
    if (( ${#args[@]} % 2 != 0 )); then return 1; fi
    local jq_args=() filter="{}" i=0
    while (( i < ${#args[@]} )); do
        local k="${args[i]}" v="${args[i+1]}"
        jq_args+=(--arg "k$i" "$k" --arg "v$i" "$v")
        filter="${filter} + {(\$k$i): \$v$i}"
        (( i += 2 ))
    done
    jq -n "${jq_args[@]}" "$filter" 2>/dev/null
}

ash_json_escape() {
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$1" | jq -Rs .
    else
        printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
    fi
}

# ── Streaming NDJSON helpers ─────────────────────────────────────────────────
ash_json_ndjson_to_array() {
    # Read newline-delimited JSON from stdin → single JSON array
    if command -v jq >/dev/null 2>&1; then jq -s . 2>/dev/null
    else printf '['; local first=1 line; while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        [[ $first -eq 1 ]] && first=0 || printf ','
        printf '%s' "$line"
    done; printf ']'; fi
}

ash_json_array_to_ndjson() {
    local src="$1" query="${2:-.[]}"
    if [[ "$src" == "-" ]]; then cat | jq -c "$query" 2>/dev/null
    else jq -c "$query" "$src" 2>/dev/null; fi
}

# ── Diff two JSON documents (used by snapshot diff) ──────────────────────────
ash_json_diff() {
    local a="$1" b="$2"
    command -v jq >/dev/null 2>&1 || return 1
    jq -n --slurpfile a "$a" --slurpfile b "$b" '
        def walk($x; $y; $p):
            if ($x|type) != ($y|type) then
                {path:$p, old:$x, new:$y, kind:"type-change"}
            elif ($x|type) == "object" then
                (($x|keys_unsorted) + ($y|keys_unsorted) | unique)[] as $k
                | walk($x[$k]; $y[$k]; ($p + [$k]))
            elif ($x|type) == "array" then
                range(0; ([($x|length),($y|length)]|max)) as $i
                | walk($x[$i]; $y[$i]; ($p + [$i]))
            elif $x != $y then
                {path:$p, old:$x, new:$y, kind:"changed"}
            else empty end;
        walk($a[0]; $b[0]; []) | select(. != null)
    ' 2>/dev/null
}
