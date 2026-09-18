#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                           ║
# ║  📐 ASH DOTFILES v5.0 OMEGA — THEME SCHEMA VALIDATION ENGINE                             ║
# ║                                                                                           ║
# ║  ░██████╗░█████╗░██╗  ██╗███████╗███╗░░░███╗░█████╗                                      ║
# ║  ██╔════╝██╔══██╗██║  ██║██╔════╝████╗░████║██╔══██╗                                     ║
# ║  ╚█████╗░██║░░╚═╝███████║█████╗░░██╔████╔██║███████║                                     ║
# ║  ░╚═══██╗██║░░██╗██╔══██║██╔══╝░░██║╚██╔╝██║██╔══██║                                     ║
# ║  ██████╔╝╚█████╔╝██║░░██║███████╗██║░╚═╝░██║██║░░██║                                     ║
# ║  ╚═════╝░░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚═╝╚═╝░░╚═╝                                     ║
# ║                                                                                           ║
# ║  ░█████╗░██╗  ██╗███████╗░█████╗░██╗░░██╗                                                ║
# ║  ██╔══██╗██║  ██║██╔════╝██╔══██╗██║░██╔╝                                                ║
# ║  ██║░░╚═╝███████║█████╗░░██║░░╚═╝█████═╝░                                                ║
# ║  ██║░░██╗██╔══██║██╔══╝░░██║░░██╗██╔═██╗░                                                ║
# ║  ╚█████╔╝██║░░██║███████╗╚█████╔╝██║░╚██╗                                                ║
# ║  ░╚════╝░╚═╝░░╚═╝╚══════╝░╚════╝░╚═╝░░╚═╝                                                ║
# ║                                                                                           ║
# ║  ─────────────────────────────────────────────────────────────────────────────────────── ║
# ║                                                                                           ║
# ║  🎯 SCHEMA CHECKS:                                                                        ║
# ║     📋 colors.json — ASH color palette schema (26 Catppuccin-compatible slots)           ║
# ║     📋 metadata.json — Theme metadata schema (name/version/author/etc)                   ║
# ║     📋 theme.conf — Key=value configuration schema                                       ║
# ║     📋 Custom schema — User-provided JSON Schema (Draft-7)                               ║
# ║     🔍 Type validation (string/number/boolean/array/object)                              ║
# ║     📏 Length constraints (minLength/maxLength/minItems/maxItems)                        ║
# ║     🎨 Pattern validation (hex colors / semver / kebab-case)                             ║
# ║     🔒 Required property enforcement                                                     ║
# ║     ⛔ Additional properties control                                                      ║
# ║     📊 Full JSON Schema Draft-7 support via jsonschema library                           ║
# ║                                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────────────────────────────────
# ARGUMENTS
# ─────────────────────────────────────────────────────────────────────────────
THEME_DIR="${1:?Usage: schema-check.sh <theme_dir> <work_dir> [schema_file] [strict] [verbose]}"
WORK_DIR="${2:?work_dir required}"
SCHEMA_FILE="${3:-themes/schema/theme-schema.json}"
STRICT="${4:-false}"
VERBOSE="${5:-false}"

# ─────────────────────────────────────────────────────────────────────────────
# ANSI COLORS (Catppuccin Mocha)
# ─────────────────────────────────────────────────────────────────────────────
C_R=$'\033[0m'        C_B=$'\033[1m'
C_MAUVE=$'\033[38;2;203;166;247m'  C_BLUE=$'\033[38;2;137;180;250m'
C_GREEN=$'\033[38;2;166;227;161m'  C_RED=$'\033[38;2;243;139;168m'
C_YELLOW=$'\033[38;2;249;226;175m' C_TEAL=$'\033[38;2;148;226;213m'
C_TEXT=$'\033[38;2;205;214;244m'   C_SUB=$'\033[38;2;166;173;200m'
C_OVR=$'\033[38;2;108;112;134m'    C_SAP=$'\033[38;2;116;199;236m'

_log() { local i="$1" c="$2"; shift 2; echo -e "${c}${i}${C_R} ${C_TEXT}$*${C_R}"; }
log_pass()  { _log "✅" "${C_GREEN}"   "$@"; }
log_fail()  { _log "❌" "${C_RED}"     "$@"; }
log_warn()  { _log "⚠️ " "${C_YELLOW}"  "$@"; }
log_info()  { _log "📐" "${C_BLUE}"    "$@"; }
log_debug() { [[ "${VERBOSE}" == "true" ]] && _log "🔎" "${C_OVR}" "$@" || true; }

mkdir -p "${WORK_DIR}"

# ─────────────────────────────────────────────────────────────────────────────
# BUILT-IN ASH THEME SCHEMA
# ─────────────────────────────────────────────────────────────────────────────
write_builtin_schema() {
  local schema_path="$1"
  mkdir -p "$(dirname "${schema_path}")"

  cat > "${schema_path}" << 'SCHEMA_EOF'
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://ash-dotfiles.dev/schemas/theme-v5.json",
  "title": "ASH Theme Schema v5.0",
  "description": "JSON Schema for ASH Dotfiles v5.0 OMEGA theme definitions",
  "type": "object",
  "definitions": {
    "hex_color": {
      "type": "string",
      "pattern": "^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$",
      "description": "CSS hex color (#RRGGBB or #RRGGBBAA)"
    },
    "semver": {
      "type": "string",
      "pattern": "^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$",
      "examples": ["1.0.0", "2.1.3-beta.1"]
    },
    "kebab_case": {
      "type": "string",
      "pattern": "^[a-z][a-z0-9-]*[a-z0-9]$|^[a-z]$",
      "description": "kebab-case identifier"
    },
    "category_type": {
      "type": "string",
      "enum": [
        "dark","light","neon","nature","space","pastel",
        "anime","retro","gradient","seasonal","mood","gaming","minimal","special"
      ]
    }
  },
  "properties": {
    "colors": {
      "type": "object",
      "description": "Color palette — Catppuccin-compatible 26-color scheme",
      "properties": {
        "base":      { "$ref": "#/definitions/hex_color" },
        "mantle":    { "$ref": "#/definitions/hex_color" },
        "crust":     { "$ref": "#/definitions/hex_color" },
        "surface0":  { "$ref": "#/definitions/hex_color" },
        "surface1":  { "$ref": "#/definitions/hex_color" },
        "surface2":  { "$ref": "#/definitions/hex_color" },
        "overlay0":  { "$ref": "#/definitions/hex_color" },
        "overlay1":  { "$ref": "#/definitions/hex_color" },
        "overlay2":  { "$ref": "#/definitions/hex_color" },
        "subtext0":  { "$ref": "#/definitions/hex_color" },
        "subtext1":  { "$ref": "#/definitions/hex_color" },
        "text":      { "$ref": "#/definitions/hex_color" },
        "lavender":  { "$ref": "#/definitions/hex_color" },
        "blue":      { "$ref": "#/definitions/hex_color" },
        "sapphire":  { "$ref": "#/definitions/hex_color" },
        "sky":       { "$ref": "#/definitions/hex_color" },
        "teal":      { "$ref": "#/definitions/hex_color" },
        "green":     { "$ref": "#/definitions/hex_color" },
        "yellow":    { "$ref": "#/definitions/hex_color" },
        "peach":     { "$ref": "#/definitions/hex_color" },
        "maroon":    { "$ref": "#/definitions/hex_color" },
        "red":       { "$ref": "#/definitions/hex_color" },
        "mauve":     { "$ref": "#/definitions/hex_color" },
        "pink":      { "$ref": "#/definitions/hex_color" },
        "flamingo":  { "$ref": "#/definitions/hex_color" },
        "rosewater": { "$ref": "#/definitions/hex_color" },
        "accent":    { "$ref": "#/definitions/hex_color" }
      },
      "required": ["base","text","mauve","blue","green","red","yellow","surface0","overlay0"],
      "additionalProperties": { "$ref": "#/definitions/hex_color" },
      "minProperties": 16,
      "maxProperties": 32
    },
    "name":        { "$ref": "#/definitions/kebab_case" },
    "version":     { "$ref": "#/definitions/semver" },
    "category":    { "$ref": "#/definitions/category_type" },
    "description": { "type": "string", "minLength": 5, "maxLength": 500 },
    "author":      { "type": "string", "minLength": 1, "maxLength": 100 },
    "tags": {
      "type": "array",
      "items": { "type": "string", "pattern": "^[a-z][a-z0-9-]*$" },
      "maxItems": 20,
      "uniqueItems": true
    },
    "wallpaper": { "type": "string" },
    "preview":   { "type": "string" },
    "accent":    { "$ref": "#/definitions/hex_color" },
    "generated_at": { "type": "string" },
    "wallpaper_hash": { "type": "string" }
  },
  "anyOf": [
    { "required": ["colors"] },
    { "required": ["base", "text"] }
  ]
}
SCHEMA_EOF
  log_debug "Built-in schema written to ${schema_path}"
}

# ─────────────────────────────────────────────────────────────────────────────
# METADATA SCHEMA
# ─────────────────────────────────────────────────────────────────────────────
write_metadata_schema() {
  local schema_path="$1"
  cat > "${schema_path}" << 'META_SCHEMA_EOF'
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ASH Theme Metadata Schema v5.0",
  "type": "object",
  "required": ["name", "version", "author", "category", "description"],
  "properties": {
    "name": {
      "type": "string",
      "pattern": "^[a-z][a-z0-9-]*$",
      "minLength": 2,
      "maxLength": 64,
      "description": "Theme identifier (kebab-case)"
    },
    "version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$",
      "description": "Semantic version (X.Y.Z)"
    },
    "author": {
      "type": "string",
      "minLength": 1,
      "maxLength": 128,
      "description": "Author name or GitHub username"
    },
    "category": {
      "type": "string",
      "enum": ["dark","light","neon","nature","space","pastel",
               "anime","retro","gradient","seasonal","mood","gaming","minimal","special"],
      "description": "Theme category"
    },
    "description": {
      "type": "string",
      "minLength": 10,
      "maxLength": 500,
      "description": "Human-readable theme description"
    },
    "tags": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^[a-z][a-z0-9-]*$",
        "maxLength": 32
      },
      "minItems": 1,
      "maxItems": 15,
      "uniqueItems": true
    },
    "license": {
      "type": "string",
      "enum": ["MIT","Apache-2.0","GPL-3.0","CC-BY-4.0","CC0-1.0","proprietary"]
    },
    "homepage": { "type": "string", "format": "uri" },
    "repository":{ "type": "string", "format": "uri" },
    "preview":   { "type": "string" },
    "wallpaper": { "type": "string" },
    "downloads": { "type": "integer", "minimum": 0 },
    "stars":     { "type": "integer", "minimum": 0 },
    "created_at":{ "type": "string" },
    "updated_at":{ "type": "string" }
  },
  "additionalProperties": true
}
META_SCHEMA_EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# PYTHON SCHEMA VALIDATOR
# ─────────────────────────────────────────────────────────────────────────────
run_jsonschema() {
  local json_file="$1"
  local schema_file="$2"
  local file_label="$3"
  local strict="${4:-false}"

  python3 << PYEOF
import json
import os
import sys
from pathlib import Path

JSON_FILE   = "${json_file}"
SCHEMA_FILE = "${schema_file}"
FILE_LABEL  = "${file_label}"
STRICT      = "${strict}" == "true"
WORK_DIR    = "${WORK_DIR}"
VERBOSE     = "${VERBOSE}" == "true"

# ANSI
GREEN  = $'\033[38;2;166;227;161m'
RED    = $'\033[38;2;243;139;168m'
YELLOW = $'\033[38;2;249;226;175m'
BLUE   = $'\033[38;2;137;180;250m'
MAUVE  = $'\033[38;2;203;166;247m'
TEXT   = $'\033[38;2;205;214;244m'
SUB    = $'\033[38;2;166;173;200m'
RST    = $'\033[0m'

def p(icon, color, msg):
    print(f"  {color}{icon}{RST} {TEXT}{msg}{RST}")

errors   = []
warnings = []
score    = 100

# ── Load JSON ────────────────────────────────────────────────────────────────
try:
    with open(JSON_FILE) as f:
        data = json.load(f)
    p("✅", GREEN, f"Valid JSON: {FILE_LABEL}")
except json.JSONDecodeError as e:
    errors.append(f"Invalid JSON in {FILE_LABEL}: {e}")
    p("❌", RED, f"Invalid JSON in {FILE_LABEL}: {e}")
    score = 0
    data  = None
except FileNotFoundError:
    errors.append(f"File not found: {FILE_LABEL}")
    p("❌", RED, f"File not found: {FILE_LABEL}")
    score = 0
    data  = None

if data is None:
    result = {
        "file": FILE_LABEL, "schema_passed": False,
        "score": 0, "errors": errors, "warnings": warnings,
    }
    Path(WORK_DIR).mkdir(parents=True, exist_ok=True)
    with open(f"{WORK_DIR}/schema-{FILE_LABEL.replace('.','_')}.json","w") as f:
        json.dump(result, f, indent=2)
    print(f"schema_passed__{FILE_LABEL}=false", file=open(os.environ.get("GITHUB_OUTPUT","/dev/null"),"a"))
    sys.exit(0)

# ── Load schema ───────────────────────────────────────────────────────────────
try:
    with open(SCHEMA_FILE) as f:
        schema = json.load(f)
except Exception as e:
    p("⚠️ ", YELLOW, f"Cannot load schema {SCHEMA_FILE}: {e}")
    warnings.append(f"Schema file unavailable: {e}")
    schema = None

# ── JSON Schema validation ────────────────────────────────────────────────────
schema_valid = True
validation_errors = []

if schema:
    try:
        import jsonschema
        from jsonschema import validate, Draft7Validator
        from jsonschema.exceptions import ValidationError, SchemaError

        # Determine additional_properties behavior
        if STRICT:
            validator = Draft7Validator(schema)
        else:
            # Allow additional properties in non-strict mode
            relaxed = dict(schema)
            if "additionalProperties" not in relaxed:
                relaxed["additionalProperties"] = True
            validator = Draft7Validator(relaxed)

        errs = list(validator.iter_errors(data))

        if errs:
            schema_valid = False
            for err in errs[:10]:
                path = ".".join(str(p) for p in err.path) if err.path else "root"
                msg  = f"[{path}] {err.message}"
                validation_errors.append(msg)
                p("❌", RED, f"Schema: {msg[:80]}")
                score -= 10

            if len(errs) > 10:
                warnings.append(f"... and {len(errs)-10} more schema errors")
        else:
            p("✅", GREEN, f"Schema validation passed: {FILE_LABEL}")

    except ImportError:
        p("⚠️ ", YELLOW, "jsonschema not installed — running basic checks")
        warnings.append("jsonschema not available — limited schema check")

        # Manual basic checks
        if isinstance(data, dict):
            required = schema.get("required", [])
            for req_field in required:
                if req_field not in data:
                    schema_valid = False
                    msg = f"Missing required field: {req_field}"
                    validation_errors.append(msg)
                    p("❌", RED, msg)
                    score -= 15
                else:
                    p("✅", GREEN, f"Required field present: {req_field}")

    except Exception as e:
        p("⚠️ ", YELLOW, f"Schema validation error: {e}")
        warnings.append(f"Schema validation exception: {str(e)[:100]}")

# ── Additional structural checks ──────────────────────────────────────────────
if isinstance(data, dict):
    # For colors.json — check hex values
    colors = data.get("colors", data)
    if isinstance(colors, dict):
        import re
        HEX = re.compile(r'^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$')
        invalid_hex = []
        for key, val in colors.items():
            if isinstance(val, str) and not HEX.match(val.strip()):
                invalid_hex.append(f"{key}: '{val}'")

        if invalid_hex:
            for inv in invalid_hex[:3]:
                schema_valid = False
                validation_errors.append(f"Invalid hex: {inv}")
                p("❌", RED, f"Invalid hex color: {inv}")
                score -= 8
        else:
            hex_count = sum(1 for v in colors.values() if isinstance(v,str) and HEX.match(v.strip()))
            p("✅", GREEN, f"All {hex_count} hex colors valid format")

# ── Final result ──────────────────────────────────────────────────────────────
errors.extend(validation_errors)
score = max(0, min(100, score))

result = {
    "file":          FILE_LABEL,
    "schema_passed": schema_valid and len(errors) == 0,
    "score":         score,
    "error_count":   len(errors),
    "warning_count": len(warnings),
    "errors":        errors,
    "warnings":      warnings,
}

Path(WORK_DIR).mkdir(parents=True, exist_ok=True)
safe_label = FILE_LABEL.replace(".", "_").replace("/", "_")
with open(f"{WORK_DIR}/schema-{safe_label}.json", "w") as f:
    json.dump(result, f, indent=2)

with open(os.environ.get("GITHUB_OUTPUT", "/dev/null"), "a") as out:
    passed = result["schema_passed"]
    out.write(f"schema_passed__{safe_label}={'true' if passed else 'false'}\n")

print(
    f"\n  {MAUVE}📐 Schema check [{FILE_LABEL}]: "
    f"{'✅ PASSED' if result['schema_passed'] else '❌ FAILED'} "
    f"(score={score}/100){RST}"
)
PYEOF
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN SCHEMA VALIDATION FLOW
# ─────────────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo -e "  ${C_SAP}${C_B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_R}"
  echo -e "  ${C_SAP}${C_B}  📐 ASH Theme Schema Validation Engine v5.0.0-omega${C_R}"
  echo -e "  ${C_SAP}${C_B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_R}"
  echo -e "  ${C_TEXT}📁 Theme: ${C_MAUVE}${THEME_DIR}${C_R}"
  echo -e "  ${C_TEXT}📐 Schema: ${C_BLUE}${SCHEMA_FILE}${C_R}"
  echo -e "  ${C_TEXT}🔒 Strict: ${C_YELLOW}${STRICT}${C_R}"
  echo ""

  # Resolve schema file path
  local WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
  local ABS_SCHEMA=""
  local BUILTIN_SCHEMA="${WORK_DIR}/builtin-theme-schema.json"
  local META_SCHEMA="${WORK_DIR}/metadata-schema.json"

  # Write built-in schemas
  write_builtin_schema "${BUILTIN_SCHEMA}"
  write_metadata_schema "${META_SCHEMA}"

  # Use custom schema if provided and exists
  if [[ -n "${SCHEMA_FILE}" && -f "${WORKSPACE}/${SCHEMA_FILE}" ]]; then
    ABS_SCHEMA="${WORKSPACE}/${SCHEMA_FILE}"
    log_info "Using custom schema: ${SCHEMA_FILE}"
  elif [[ -n "${SCHEMA_FILE}" && -f "${SCHEMA_FILE}" ]]; then
    ABS_SCHEMA="${SCHEMA_FILE}"
    log_info "Using schema: ${SCHEMA_FILE}"
  else
    ABS_SCHEMA="${BUILTIN_SCHEMA}"
    log_info "Using built-in ASH theme schema v5.0"
  fi

  local TOTAL_SCORE=0
  local FILES_CHECKED=0
  local FILES_PASSED=0
  local ALL_ERRORS=()
  local ALL_WARNINGS=()

  # ── Validate colors.json ────────────────────────────────────────────────────
  local COLORS_FILE="${THEME_DIR}/colors.json"
  if [[ -f "${COLORS_FILE}" ]]; then
    echo -e "\n  ${C_MAUVE}${C_B}── colors.json ─────────────────────────────────────────────────${C_R}"
    run_jsonschema "${COLORS_FILE}" "${ABS_SCHEMA}" "colors.json" "${STRICT}"
    ((FILES_CHECKED++))

    if [[ -f "${WORK_DIR}/schema-colors_json.json" ]]; then
      local c_score; c_score=$(jq '.score' "${WORK_DIR}/schema-colors_json.json" 2>/dev/null || echo 0)
      local c_passed; c_passed=$(jq -r '.schema_passed' "${WORK_DIR}/schema-colors_json.json" 2>/dev/null || echo "false")
      TOTAL_SCORE=$((TOTAL_SCORE + c_score))
      [[ "${c_passed}" == "true" ]] && ((FILES_PASSED++)) || true

      while IFS= read -r err; do [[ -n "${err}" ]] && ALL_ERRORS+=("colors.json: ${err}"); done < \
        <(jq -r '.errors[]' "${WORK_DIR}/schema-colors_json.json" 2>/dev/null || true)
    fi
  else
    log_warn "colors.json not found — skipping schema check"
  fi

  # ── Validate metadata.json ──────────────────────────────────────────────────
  local META_FILE="${THEME_DIR}/metadata.json"
  if [[ -f "${META_FILE}" ]]; then
    echo -e "\n  ${C_MAUVE}${C_B}── metadata.json ────────────────────────────────────────────────${C_R}"
    run_jsonschema "${META_FILE}" "${META_SCHEMA}" "metadata.json" "${STRICT}"
    ((FILES_CHECKED++))

    if [[ -f "${WORK_DIR}/schema-metadata_json.json" ]]; then
      local m_score; m_score=$(jq '.score' "${WORK_DIR}/schema-metadata_json.json" 2>/dev/null || echo 0)
      local m_passed; m_passed=$(jq -r '.schema_passed' "${WORK_DIR}/schema-metadata_json.json" 2>/dev/null || echo "false")
      TOTAL_SCORE=$((TOTAL_SCORE + m_score))
      [[ "${m_passed}" == "true" ]] && ((FILES_PASSED++)) || true

      while IFS= read -r err; do [[ -n "${err}" ]] && ALL_ERRORS+=("metadata.json: ${err}"); done < \
        <(jq -r '.errors[]' "${WORK_DIR}/schema-metadata_json.json" 2>/dev/null || true)
    fi
  else
    log_warn "metadata.json not found — skipping schema check"
  fi

  # ── Validate theme.conf ──────────────────────────────────────────────────────
  local CONF_FILE="${THEME_DIR}/theme.conf"
  if [[ -f "${CONF_FILE}" ]]; then
    echo -e "\n  ${C_MAUVE}${C_B}── theme.conf ──────────────────────────────────────────────────${C_R}"
    ((FILES_CHECKED++))

    local conf_score=100
    local conf_errors=()

    # Validate key=value format
    while IFS= read -r line; do
      [[ -z "${line}" || "${line}" =~ ^# ]] && continue
      if ! echo "${line}" | grep -qE '^[a-zA-Z_][a-zA-Z0-9_]*\s*=\s*.+$'; then
        conf_errors+=("Invalid line format: '${line:0:60}'")
        conf_score=$((conf_score - 10))
      fi
    done < "${CONF_FILE}"

    # Check required conf keys
    local CONF_REQUIRED=("name" "category" "version")
    for key in "${CONF_REQUIRED[@]}"; do
      if grep -qE "^${key}\s*=" "${CONF_FILE}" 2>/dev/null; then
        local val; val=$(grep -E "^${key}\s*=" "${CONF_FILE}" | head -1 | cut -d= -f2 | tr -d ' "'"'" )
        log_pass "theme.conf.${key} = ${val}"
      else
        conf_errors+=("Missing required key in theme.conf: ${key}")
        conf_score=$((conf_score - 20))
        log_fail "theme.conf missing: ${key}"
      fi
    done

    conf_score=$(( conf_score < 0 ? 0 : conf_score ))
    TOTAL_SCORE=$((TOTAL_SCORE + conf_score))
    [[ "${#conf_errors[@]}" -eq 0 ]] && ((FILES_PASSED++)) || true
    ALL_ERRORS+=("${conf_errors[@]}")

    log_info "theme.conf score: ${conf_score}/100"
  fi

  # ── Compute overall schema score ─────────────────────────────────────────────
  local OVERALL_SCORE=0
  if [[ "${FILES_CHECKED}" -gt 0 ]]; then
    OVERALL_SCORE=$(( TOTAL_SCORE / FILES_CHECKED ))
  fi

  local SCHEMA_OVERALL_PASSED="false"
  [[ "${FILES_PASSED}" -ge "${FILES_CHECKED}" && "${FILES_CHECKED}" -gt 0 ]] && \
    SCHEMA_OVERALL_PASSED="true"
  [[ "${#ALL_ERRORS[@]}" -eq 0 ]] && SCHEMA_OVERALL_PASSED="true"

  # ── Summary ──────────────────────────────────────────────────────────────────
  echo ""
  echo -e "  ${C_SAP}${C_B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_R}"
  printf  "  ${C_TEXT}📐 Schema Summary: %d/%d files passed · Score: %d/100\n${C_R}" \
    "${FILES_PASSED}" "${FILES_CHECKED}" "${OVERALL_SCORE}"
  echo -e "  ${C_SAP}${C_B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_R}"

  if [[ "${#ALL_ERRORS[@]}" -gt 0 ]]; then
    echo -e "  ${C_RED}❌ Schema errors (${#ALL_ERRORS[@]}):${C_R}"
    for err in "${ALL_ERRORS[@]:0:5}"; do
      echo -e "     ${C_RED}• ${err}${C_R}"
    done
  else
    echo -e "  ${C_GREEN}✅ All schema checks passed${C_R}"
  fi

  # Emit GitHub outputs
  {
    echo "schema_passed=${SCHEMA_OVERALL_PASSED}"
    echo "schema_score=${OVERALL_SCORE}"
    echo "schema_files_checked=${FILES_CHECKED}"
    echo "schema_files_passed=${FILES_PASSED}"
    echo "error_count=${#ALL_ERRORS[@]}"
    echo "errors_json=$(printf '%s\n' "${ALL_ERRORS[@]:-}" | jq -R . | jq -s -c . 2>/dev/null || echo '[]')"
  } >> "${GITHUB_OUTPUT:-/dev/null}"

  # Save consolidated result
  cat > "${WORK_DIR}/schema-consolidated.json" << EOF
{
  "schema_passed":   ${SCHEMA_OVERALL_PASSED},
  "overall_score":   ${OVERALL_SCORE},
  "files_checked":   ${FILES_CHECKED},
  "files_passed":    ${FILES_PASSED},
  "error_count":     ${#ALL_ERRORS[@]},
  "errors":          $(printf '%s\n' "${ALL_ERRORS[@]:-}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
  "strict_mode":     ${STRICT},
  "schema_used":     "${ABS_SCHEMA}",
  "timestamp":       "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

  echo ""
  if [[ "${SCHEMA_OVERALL_PASSED}" == "true" ]]; then
    echo -e "  ${C_GREEN}${C_B}✅ Schema validation: PASSED (${OVERALL_SCORE}/100)${C_R}"
  else
    echo -e "  ${C_RED}${C_B}❌ Schema validation: FAILED (${OVERALL_SCORE}/100)${C_R}"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# TRAP & ENTRY
# ─────────────────────────────────────────────────────────────────────────────
trap 'EXIT_CODE=$?
[[ $EXIT_CODE -ne 0 ]] && echo "❌ schema-check.sh failed (exit=${EXIT_CODE})"' EXIT

main "$@"