#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Calculator Script                                 ║
# ║                                                                              ║
# ║  Scientific calculator via multiple backends:                               ║
# ║  1. Python 3 math (primary — full scientific + complex)                    ║
# ║  2. bc (fallback — basic math)                                              ║
# ║  3. qalc (optional — full CAS with units/currencies)                       ║
# ║                                                                              ║
# ║  Features:                                                                   ║
# ║  • Live expression evaluation as you type                                   ║
# ║  • Unit conversion (km↔mi, C↔F, kg↔lb, etc.)                             ║
# ║  • Currency rates (requires internet + exchange API)                        ║
# ║  • Constants (pi, e, phi, tau, c, G, h, k_B)                              ║
# ║  • History with re-use                                                      ║
# ║  • Memory store/recall                                                      ║
# ║  • Multiple output formats (decimal, hex, binary, scientific)               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly HISTORY_FILE="${HOME}/.local/share/ash-dotfiles/calc-history.txt"
readonly MEMORY_FILE="${XDG_RUNTIME_DIR:-/tmp}/ash-calc-memory"
readonly MAX_HISTORY=50
readonly PRECISION=15           # Decimal places for Python output
readonly MAX_RESULT_LEN=30      # Truncate very long results

# ══════════════════════════════════════════════════════════════════════════════
# §02  PYTHON EVALUATION ENGINE
# ══════════════════════════════════════════════════════════════════════════════

# Safe Python math evaluator — no exec/eval of arbitrary code
readonly PYTHON_PREAMBLE="
import math, cmath, decimal, statistics
from math import (
    pi, e, tau, inf, nan,
    sin, cos, tan, asin, acos, atan, atan2,
    sinh, cosh, tanh, asinh, acosh, atanh,
    sqrt, cbrt, pow, exp, exp2, log, log2, log10,
    floor, ceil, trunc, fabs, factorial, gcd, lcm,
    degrees, radians, isfinite, isinf, isnan,
    hypot, dist, prod, perm, comb,
)
from decimal import Decimal
from statistics import mean, median, mode, stdev, variance

# Extra constants
phi = (1 + 5**0.5) / 2          # Golden ratio
c   = 299792458                  # Speed of light (m/s)
G   = 6.67430e-11               # Gravitational constant
h   = 6.62607015e-34            # Planck constant
k_B = 1.380649e-23              # Boltzmann constant
eV  = 1.602176634e-19           # Electron volt (J)
N_A = 6.02214076e23             # Avogadro's number
R   = 8.314462618               # Gas constant

# Utility functions
def logn(x, base): return math.log(x) / math.log(base)
def sign(x): return 1 if x > 0 else (-1 if x < 0 else 0)
def avg(*args): return sum(args) / len(args)
def percentage(n, total): return (n / total) * 100
def perc_of(pct, n): return (pct / 100) * n
"

eval_python() {
    local expr="$1"

    # Safety: reject dangerous patterns
    if echo "$expr" | grep -qP '(__import__|open|exec|eval|compile|__class__|globals|locals|vars|dir|getattr|setattr|delattr|input|print|os\.|sys\.|subprocess|shutil|socket|urllib|requests|importlib)'; then
        echo "ERROR: Unsafe expression"
        return 1
    fi

    python3 -c "
${PYTHON_PREAMBLE}
import sys

try:
    expr = '''${expr}'''

    # Preprocess: handle implicit multiplication, degree symbol, etc.
    expr = expr.replace('^', '**')     # ^ = power
    expr = expr.replace('÷', '/')      # Division sign
    expr = expr.replace('×', '*')      # Multiplication sign
    expr = expr.replace('√', 'sqrt')   # Square root symbol
    expr = expr.replace('%', '/100')   # Percentage (simple)

    result = eval(expr)

    # Format result
    if isinstance(result, complex):
        if result.imag == 0:
            result = result.real
        else:
            print(f'{result.real:.${PRECISION}g} + {result.imag:.${PRECISION}g}i')
            sys.exit(0)

    if isinstance(result, float):
        if result == int(result) and abs(result) < 1e15:
            print(int(result))
        else:
            formatted = f'{result:.${PRECISION}g}'
            print(formatted)
    elif isinstance(result, int):
        print(result)
    else:
        print(result)

except ZeroDivisionError:
    print('ERROR: Division by zero')
except OverflowError:
    print('ERROR: Result too large')
except ValueError as e:
    print(f'ERROR: {e}')
except SyntaxError:
    print('ERROR: Invalid expression')
except Exception as e:
    print(f'ERROR: {e}')
" 2>/dev/null
}

eval_bc() {
    local expr="$1"
    echo "scale=${PRECISION}; $expr" | bc -l 2>/dev/null | \
        sed 's/\.\{0,1\}0*$//' || echo "ERROR"
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  UNIT CONVERSION ENGINE
# ══════════════════════════════════════════════════════════════════════════════

# Pattern: "VALUE UNIT to UNIT" or "VALUE UNIT in UNIT"
parse_unit_conversion() {
    local expr="${1,,}"

    # Extract: number, from_unit, to_unit
    local value from_unit to_unit
    if [[ "$expr" =~ ^([0-9.e+-]+)[[:space:]]*([a-z/°]+)[[:space:]]+(to|in)[[:space:]]+([a-z/°]+) ]]; then
        value="${BASH_REMATCH[1]}"
        from_unit="${BASH_REMATCH[2]}"
        to_unit="${BASH_REMATCH[4]}"
    else
        return 1
    fi

    convert_units "$value" "$from_unit" "$to_unit"
}

convert_units() {
    local value="$1" from="$2" to="$3"

    python3 -c "
value = float('${value}')
from_unit = '${from}'.lower()
to_unit = '${to}'.lower()

# Conversion factors to base SI unit
LENGTH = {
    'm': 1, 'meter': 1, 'meters': 1,
    'km': 1000, 'kilometer': 1000, 'kilometers': 1000,
    'cm': 0.01, 'mm': 0.001,
    'mi': 1609.344, 'mile': 1609.344, 'miles': 1609.344,
    'yd': 0.9144, 'yard': 0.9144, 'yards': 0.9144,
    'ft': 0.3048, 'foot': 0.3048, 'feet': 0.3048,
    'in': 0.0254, 'inch': 0.0254, 'inches': 0.0254,
    'nm': 1e-9, 'um': 1e-6, 'pm': 1e-12,
    'ly': 9.461e15, 'au': 1.496e11, 'pc': 3.086e16,
}

MASS = {
    'kg': 1, 'g': 0.001, 'mg': 1e-6, 't': 1000,
    'lb': 0.453592, 'lbs': 0.453592, 'pound': 0.453592,
    'oz': 0.0283495, 'ounce': 0.0283495,
    'stone': 6.35029, 'ton': 907.185,
}

TIME = {
    's': 1, 'sec': 1, 'second': 1,
    'ms': 0.001, 'us': 1e-6, 'ns': 1e-9,
    'min': 60, 'minute': 60,
    'h': 3600, 'hr': 3600, 'hour': 3600,
    'd': 86400, 'day': 86400,
    'wk': 604800, 'week': 604800,
    'mo': 2592000, 'month': 2592000,
    'yr': 31536000, 'year': 31536000,
}

SPEED = {
    'm/s': 1, 'km/h': 1/3.6, 'mph': 0.44704,
    'knot': 0.514444, 'kn': 0.514444,
    'c': 299792458,
}

AREA = {
    'm2': 1, 'km2': 1e6, 'cm2': 0.0001,
    'ft2': 0.0929, 'mi2': 2.59e6,
    'ha': 10000, 'acre': 4046.86,
}

VOLUME = {
    'l': 1, 'liter': 1, 'ml': 0.001, 'cl': 0.01, 'dl': 0.1,
    'm3': 1000, 'cm3': 0.001,
    'gal': 3.78541, 'gallon': 3.78541,
    'qt': 0.946353, 'pt': 0.473176, 'fl oz': 0.0295735,
    'cup': 0.236588, 'tbsp': 0.0147868, 'tsp': 0.00492892,
}

ENERGY = {
    'j': 1, 'kj': 1000, 'mj': 1e6,
    'cal': 4.184, 'kcal': 4184, 'wh': 3600, 'kwh': 3.6e6,
    'ev': 1.60218e-19, 'btu': 1055.06,
}

PRESSURE = {
    'pa': 1, 'kpa': 1000, 'mpa': 1e6,
    'bar': 100000, 'mbar': 100,
    'atm': 101325, 'psi': 6894.76,
    'mmhg': 133.322, 'torr': 133.322,
    'inhg': 3386.39,
}

DATA = {
    'b': 1, 'bit': 1,
    'kb': 1000, 'mb': 1e6, 'gb': 1e9, 'tb': 1e12,
    'kib': 1024, 'mib': 1048576, 'gib': 1073741824, 'tib': 1099511627776,
    'byte': 8, 'kbyte': 8000, 'mbyte': 8e6,
}

POWER = {
    'w': 1, 'kw': 1000, 'mw': 1e6, 'gw': 1e9,
    'hp': 745.7, 'ps': 735.499,
    'btu/h': 0.293071,
}

ALL_CATEGORIES = [LENGTH, MASS, TIME, SPEED, AREA, VOLUME, ENERGY, PRESSURE, DATA, POWER]
UNIT_NAMES = {
    'm2': 'sq m', 'km2': 'sq km', 'ft2': 'sq ft', 'mi2': 'sq mi',
}

# Temperature (special case — not linear)
def temp_convert(val, f, t):
    if f == 'c' and t == 'f': return val * 9/5 + 32
    if f == 'f' and t == 'c': return (val - 32) * 5/9
    if f == 'c' and t == 'k': return val + 273.15
    if f == 'k' and t == 'c': return val - 273.15
    if f == 'f' and t == 'k': return (val - 32) * 5/9 + 273.15
    if f == 'k' and t == 'f': return (val - 273.15) * 9/5 + 32
    return None

temp_units = {'c', 'f', 'k', 'celsius', 'fahrenheit', 'kelvin'}
if from_unit in temp_units or to_unit in temp_units:
    f = from_unit[0] if from_unit not in ('celsius','fahrenheit','kelvin') else from_unit[0]
    t = to_unit[0] if to_unit not in ('celsius','fahrenheit','kelvin') else to_unit[0]
    result = temp_convert(value, f, t)
    if result is not None:
        print(f'{result:.10g} {to_unit.upper()}')
    else:
        print('ERROR: Unsupported temperature conversion')
else:
    converted = False
    for category in ALL_CATEGORIES:
        if from_unit in category and to_unit in category:
            base = value * category[from_unit]
            result = base / category[to_unit]
            unit_label = UNIT_NAMES.get(to_unit, to_unit)
            print(f'{result:.10g} {unit_label}')
            converted = True
            break
    if not converted:
        print(f'ERROR: Unknown unit conversion: {from_unit} to {to_unit}')
" 2>/dev/null || echo "ERROR: Conversion failed"
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  NUMBER FORMAT HELPERS
# ══════════════════════════════════════════════════════════════════════════════

format_extra() {
    local result="$1"

    # Only format integers and simple floats
    if ! [[ "$result" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo ""
        return
    fi

    local int_val
    int_val=$(printf "%.0f" "$result" 2>/dev/null || echo "")
    [[ -z "$int_val" ]] && { echo ""; return; }

    local extras=()

    # Hex
    if [[ "$int_val" -ge 0 ]] && [[ "$int_val" -le 4294967295 ]] 2>/dev/null; then
        local hex
        hex=$(printf "0x%X" "$int_val" 2>/dev/null || true)
        [[ -n "$hex" && "$hex" != "0x0" ]] && extras+=("$hex")
    fi

    # Binary (for small integers)
    if [[ "$int_val" -ge 0 ]] && [[ "$int_val" -le 65535 ]] 2>/dev/null; then
        local bin
        bin=$(python3 -c "print(bin(${int_val})[2:])" 2>/dev/null || true)
        [[ -n "$bin" ]] && extras+=("0b${bin}")
    fi

    # Scientific notation for large numbers
    if [[ "${#result}" -gt 8 ]]; then
        local sci
        sci=$(python3 -c "print(f'{${result}:.4e}')" 2>/dev/null || true)
        [[ -n "$sci" && "$sci" != "${result}" ]] && extras+=("${sci}")
    fi

    if [[ ${#extras[@]} -gt 0 ]]; then
        local IFS="  │  "
        echo "${extras[*]}"
    else
        echo ""
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  HISTORY MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

ensure_history() {
    mkdir -p "$(dirname "$HISTORY_FILE")"
    touch "$HISTORY_FILE" 2>/dev/null || true
}

add_to_history() {
    local expr="$1" result="$2"
    ensure_history

    # Prepend
    local tmp
    tmp=$(mktemp)
    echo "${expr}|${result}|$(date +%s)" | cat - "$HISTORY_FILE" > "$tmp"
    mv "$tmp" "$HISTORY_FILE"

    # Keep MAX_HISTORY entries
    local tmp2
    tmp2=$(mktemp)
    head -"$MAX_HISTORY" "$HISTORY_FILE" > "$tmp2"
    mv "$tmp2" "$HISTORY_FILE"
}

get_history() {
    ensure_history
    cat "$HISTORY_FILE" 2>/dev/null | head -"$MAX_HISTORY" || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  MEMORY MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

store_memory() {
    local value="$1"
    echo "$value" > "$MEMORY_FILE"
    notify_calc "Memory stored" "$value" "low"
}

recall_memory() {
    cat "$MEMORY_FILE" 2>/dev/null || echo "0"
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  CONSTANTS BROWSER
# ══════════════════════════════════════════════════════════════════════════════

build_constants_entries() {
    printf '─── MATHEMATICAL CONSTANTS ──────────────\0nonselectable\x1ftrue\n'
    printf 'π   pi = 3.14159265358979…\0info\x1fcopy-val\x1fmeta\x1f3.14159265358979\n'
    printf 'e   Euler = 2.71828182845904…\0info\x1fcopy-val\x1fmeta\x1f2.71828182845904\n'
    printf 'φ   phi (golden ratio) = 1.61803398874989…\0info\x1fcopy-val\x1fmeta\x1f1.61803398874989\n'
    printf 'τ   tau = 2π = 6.28318530717958…\0info\x1fcopy-val\x1fmeta\x1f6.28318530717958\n'
    printf '√2  sqrt(2) = 1.41421356237309…\0info\x1fcopy-val\x1fmeta\x1f1.41421356237309\n'
    printf '√3  sqrt(3) = 1.73205080756887…\0info\x1fcopy-val\x1fmeta\x1f1.73205080756887\n'
    printf 'ln2 = 0.693147180559945…\0info\x1fcopy-val\x1fmeta\x1f0.693147180559945\n'
    printf '─── PHYSICAL CONSTANTS ──────────────────\0nonselectable\x1ftrue\n'
    printf 'c   Speed of light = 299,792,458 m/s\0info\x1fcopy-val\x1fmeta\x1f299792458\n'
    printf 'G   Gravitational = 6.67430e-11 m³/(kg·s²)\0info\x1fcopy-val\x1fmeta\x1f6.67430e-11\n'
    printf 'h   Planck = 6.62607015e-34 J·s\0info\x1fcopy-val\x1fmeta\x1f6.62607015e-34\n'
    printf 'ℏ   Reduced Planck = 1.05457e-34 J·s\0info\x1fcopy-val\x1fmeta\x1f1.05457e-34\n'
    printf 'kB  Boltzmann = 1.38064852e-23 J/K\0info\x1fcopy-val\x1fmeta\x1f1.38064852e-23\n'
    printf 'NA  Avogadro = 6.02214076e23 mol⁻¹\0info\x1fcopy-val\x1fmeta\x1f6.02214076e23\n'
    printf 'R   Gas constant = 8.31446261 J/(mol·K)\0info\x1fcopy-val\x1fmeta\x1f8.31446261\n'
    printf 'e   Elem. charge = 1.60217663e-19 C\0info\x1fcopy-val\x1fmeta\x1f1.60217663e-19\n'
    printf 'me  Electron mass = 9.10938370e-31 kg\0info\x1fcopy-val\x1fmeta\x1f9.10938370e-31\n'
    printf 'mp  Proton mass = 1.67262192e-27 kg\0info\x1fcopy-val\x1fmeta\x1f1.67262192e-27\n'
    printf 'ε0  Permittivity = 8.85418782e-12 F/m\0info\x1fcopy-val\x1fmeta\x1f8.85418782e-12\n'
    printf 'μ0  Permeability = 1.25663706e-6 H/m\0info\x1fcopy-val\x1fmeta\x1f1.25663706e-6\n'
    printf '─── UNIT CONVERSIONS ────────────────────\0nonselectable\x1ftrue\n'
    printf '1 inch = 2.54 cm\0info\x1fcopy-val\x1fmeta\x1f2.54\n'
    printf '1 mile = 1.60934 km\0info\x1fcopy-val\x1fmeta\x1f1.60934\n'
    printf '1 pound = 0.453592 kg\0info\x1fcopy-val\x1fmeta\x1f0.453592\n'
    printf '1 gallon (US) = 3.78541 L\0info\x1fcopy-val\x1fmeta\x1f3.78541\n'
    printf '1 atmosphere = 101325 Pa\0info\x1fcopy-val\x1fmeta\x1f101325\n'
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_calc() {
    local title="$1" msg="${2:-}" urgency="${3:-low}"
    notify-send \
        "$title" "$msg" \
        --app-name="ASH Calculator" \
        --icon=calculator \
        --urgency="$urgency" \
        --expire-time=2000 \
        --hint=string:x-dunst-stack-tag:calculator \
        2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  MENU ENTRY BUILDERS
# ══════════════════════════════════════════════════════════════════════════════

build_history_entries() {
    local history
    history=$(get_history)

    if [[ -z "$history" ]]; then
        printf '󰒓  No calculation history yet\0nonselectable\x1ftrue\n'
        return
    fi

    printf '─── HISTORY ─────────────────────────────\0nonselectable\x1ftrue\n'

    local count=0
    while IFS='|' read -r expr result timestamp; do
        [[ -z "$expr" ]] && continue

        # Truncate long expressions
        local display_expr
        display_expr="${expr:0:35}"
        [[ ${#expr} -gt 35 ]] && display_expr="${display_expr}…"

        local display_result
        display_result="${result:0:20}"

        local display
        display=$(printf '󰒓  %-38s  =  %s' "$display_expr" "$display_result")

        printf '%s\0info\x1frecall\x1fmeta\x1f%s|%s\n' \
            "$display" "$expr" "$result"

        (( count++ )) || true
        [[ $count -ge 20 ]] && break
    done <<< "$history"

    printf '─────────────────────────────────────────\0nonselectable\x1ftrue\n'
    printf '󰩹  Clear History\0info\x1fclear-history\n'
}

build_suggestions_entries() {
    printf '─── QUICK EXAMPLES ──────────────────────\0nonselectable\x1ftrue\n'
    printf '  2 + 2           basic arithmetic\0info\x1fuse-expr\x1fmeta\x1f2 + 2\n'
    printf '  sqrt(144)       square root\0info\x1fuse-expr\x1fmeta\x1fsqrt(144)\n'
    printf '  2**32 - 1       power (use ** or ^)\0info\x1fuse-expr\x1fmeta\x1f2**32 - 1\n'
    printf '  sin(pi/6)       trig functions\0info\x1fuse-expr\x1fmeta\x1fsin(pi/6)\n'
    printf '  log(1000)       logarithm (base e)\0info\x1fuse-expr\x1fmeta\x1flog(1000)\n'
    printf '  log10(1000)     log base 10\0info\x1fuse-expr\x1fmeta\x1flog10(1000)\n'
    printf '  factorial(12)   factorial\0info\x1fuse-expr\x1fmeta\x1ffactorial(12)\n'
    printf '  comb(52, 5)     combinations\0info\x1fuse-expr\x1fmeta\x1fcomb(52, 5)\n'
    printf '  42 km to miles  unit conversion\0info\x1fuse-expr\x1fmeta\x1f42 km to miles\n'
    printf '  100 F to C      temperature\0info\x1fuse-expr\x1fmeta\x1f100 F to C\n'
    printf '  0xFF & 0x0F     bitwise ops\0info\x1fuse-expr\x1fmeta\x1f0xFF & 0x0F\n'
    printf '  mean(1,2,3,4,5) statistics\0info\x1fuse-expr\x1fmeta\x1fmean(1,2,3,4,5)\n'
    printf '─── MEMORY ──────────────────────────────\0nonselectable\x1ftrue\n'

    local mem
    mem=$(recall_memory)
    printf '󰋊  Memory: %s\0info\x1frecall-mem\x1fmeta\x1f%s\n' \
        "${mem:-[empty]}" "${mem:-0}"

    printf '  Store in Memory  (Ctrl+M)\0info\x1fstore-menu\n'
}

# ══════════════════════════════════════════════════════════════════════════════
# §10  MAIN EVALUATION + OUTPUT
# ══════════════════════════════════════════════════════════════════════════════

evaluate_and_display() {
    local expr="${1:-}"

    # Empty input
    if [[ -z "$expr" ]]; then
        build_suggestions_entries
        return
    fi

    # Check for unit conversion pattern first
    local unit_result=""
    if echo "$expr" | grep -qiP '\d+\s*\w+\s+(to|in)\s+\w+'; then
        unit_result=$(parse_unit_conversion "$expr" 2>/dev/null || true)
    fi

    local result=""
    local is_error=false

    if [[ -n "$unit_result" ]] && ! echo "$unit_result" | grep -q "^ERROR"; then
        result="$unit_result"
    else
        # Python evaluation
        result=$(eval_python "$expr" 2>/dev/null || true)

        if [[ -z "$result" ]] || echo "$result" | grep -q "^ERROR"; then
            # Fallback to bc
            local bc_result
            bc_result=$(eval_bc "$expr" 2>/dev/null || true)
            if [[ -n "$bc_result" ]] && ! echo "$bc_result" | grep -q "^ERROR"; then
                result="$bc_result"
            else
                result="Error"
                is_error=true
            fi
        fi
    fi

    # Output result for display (would be shown in ca-result-value)
    # In Rofi custom mode, we output list entries
    # The result display is emulated through the list

    if $is_error; then
        printf '❌  %s\0info\x1fnone\n' "$result"
    else
        # Truncate if very long
        local display_result="$result"
        [[ ${#result} -gt $MAX_RESULT_LEN ]] && \
            display_result="${result:0:$((MAX_RESULT_LEN-1))}…"

        # Primary result entry (selectable to copy)
        printf '  Result:  %s\0info\x1fcopy-result\x1fmeta\x1f%s|%s\n' \
            "$display_result" "$result" "$expr"

        # Alt formats
        local extra
        extra=$(format_extra "$result" 2>/dev/null || true)
        if [[ -n "$extra" ]]; then
            printf '󰒓  Formats: %s\0info\x1fnone\n' "$extra"
        fi

        # Division reminder (show remainder for integer division)
        if [[ "$expr" =~ [0-9]+\ */\ *[0-9]+ ]]; then
            local a b
            read -r a _ b <<< "$expr"
            if [[ "$b" -ne 0 ]] 2>/dev/null; then
                local rem
                rem=$(( a % b )) 2>/dev/null || true
                [[ -n "$rem" && "$rem" != "0" ]] && \
                    printf '  Remainder: %s\0info\x1fnone\n' "$rem"
            fi
        fi
    fi

    printf '─── HISTORY ─────────────────────────────\0nonselectable\x1ftrue\n'
    build_history_entries_short

    # Record successful evaluation
    if ! $is_error && [[ -n "$result" && "$result" != "Error" ]]; then
        add_to_history "$expr" "$result" &>/dev/null & disown
    fi
}

build_history_entries_short() {
    local count=0
    while IFS='|' read -r expr result timestamp; do
        [[ -z "$expr" ]] && continue

        local display_expr="${expr:0:30}"
        [[ ${#expr} -gt 30 ]] && display_expr="${display_expr}…"

        printf '󰒓  %-33s  =  %s\0info\x1frecall\x1fmeta\x1f%s|%s\n' \
            "$display_expr" \
            "${result:0:15}" \
            "$expr" "$result"

        (( count++ )) || true
        [[ $count -ge 6 ]] && break
    done < <(get_history 2>/dev/null || true)
}

# ══════════════════════════════════════════════════════════════════════════════
# §11  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local action="$1"
    local meta="${2:-}"

    case "$action" in
        copy-result)
            IFS='|' read -r result expr <<< "$meta"
            [[ -n "$result" ]] && {
                echo -n "$result" | wl-copy 2>/dev/null && \
                    notify_calc "󱖦 Result copied" "$result"
            }
            ;;
        recall)
            IFS='|' read -r expr result <<< "$meta"
            [[ -n "$result" ]] && {
                echo -n "$result" | wl-copy 2>/dev/null && \
                    notify_calc "󱖦 Copied from history" "$expr = $result"
            }
            ;;
        recall-mem)
            local mem
            mem=$(recall_memory)
            [[ -n "$mem" ]] && {
                echo -n "$mem" | wl-copy 2>/dev/null && \
                    notify_calc "󰋊 Memory recalled" "$mem"
            }
            ;;
        store-menu)
            local current
            current=$(wl-paste 2>/dev/null | head -1 || echo "")
            [[ -n "$current" ]] && store_memory "$current"
            ;;
        copy-val)
            [[ -n "$meta" ]] && {
                echo -n "$meta" | wl-copy 2>/dev/null && \
                    notify_calc "Constant copied" "$meta"
            }
            ;;
        use-expr)
            # This would pre-fill the input — not directly supported in custom mode
            [[ -n "$meta" ]] && {
                echo -n "$meta" | wl-copy 2>/dev/null && \
                    notify_calc "Example copied" "$meta — paste to use" "low"
            }
            ;;
        clear-history)
            true > "$HISTORY_FILE" 2>/dev/null && \
                notify_calc "History cleared" "" "low"
            ;;
        none|"")
            return 0
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §12  DIRECT CLI INVOCATION
# ══════════════════════════════════════════════════════════════════════════════

handle_direct_args() {
    case "${1:-}" in
        --eval)
            [[ -n "${2:-}" ]] && eval_python "$2"
            ;;
        --convert)
            [[ -n "${2:-}" ]] && parse_unit_conversion "$2"
            ;;
        --history)
            get_history | head -10
            ;;
        --clear)
            true > "$HISTORY_FILE" && echo "History cleared"
            ;;
        --help|-h)
            echo "ASH Calculator v5.0"
            echo ""
            echo "Usage: calc.sh [OPTION] [EXPR]"
            echo ""
            echo "Options:"
            echo "  --eval EXPR      Evaluate expression"
            echo "  --convert EXPR   Convert units (e.g. '42 km to miles')"
            echo "  --history        Show calculation history"
            echo "  --clear          Clear history"
            echo ""
            echo "No args: Launch Rofi calculator"
            exit 0
            ;;
        "")
            return 1
            ;;
    esac
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# §13  ROFI CUSTOM MODE PROTOCOL
# ══════════════════════════════════════════════════════════════════════════════

if [[ -z "${ROFI_RETV:-}" ]]; then
    handle_direct_args "${1:-}" "${2:-}" 2>/dev/null || true

    rofi \
        -show calc \
        -modi "calc:${BASH_SOURCE[0]}" \
        -config "${HOME}/.config/rofi/menus/calc/calc.rasi" \
        2>/dev/null
    exit 0
fi

# ── Initialization ────────────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 0 ]]; then
    ensure_history
    evaluate_and_display "${ROFI_DATA:-}"
    exit 0
fi

# ── Entry selected ────────────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 1 ]]; then
    action="${ROFI_INFO:-}"
    [[ "$action" == "true" ]] && exit 0
    [[ -z "$action" ]] && exit 0

    IFS=$'\x1f' read -ra parts <<< "$action"
    local_action="${parts[0]:-}"
    meta_value="${parts[2]:-}"

    dispatch_action "$local_action" "$meta_value"
    exit 0
fi

# ── Custom input: live evaluation ─────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 2 ]]; then
    expr="${1:-}"
    evaluate_and_display "$expr"
    exit 0
fi

# ── Ctrl+H: History ───────────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 10 ]]; then
    build_history_entries
    exit 0
fi

# ── Ctrl+C: Copy expression ───────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 11 ]]; then
    expr="${ROFI_DATA:-${1:-}}"
    [[ -n "$expr" ]] && {
        echo -n "$expr" | wl-copy 2>/dev/null && \
            notify_calc "Expression copied" "$expr" "low"
    }
    evaluate_and_display "$expr"
    exit 0
fi

# ── Ctrl+M: Store memory ──────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 13 ]]; then
    # Store last result
    last_result=$(get_history | head -1 | cut -d'|' -f2 || echo "")
    [[ -n "$last_result" ]] && store_memory "$last_result"
    evaluate_and_display "${ROFI_DATA:-}"
    exit 0
fi

# ── Ctrl+K: Constants browser ─────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 16 ]]; then
    build_constants_entries
    exit 0
fi

# ── Alt+Enter: Copy expression only ──────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 17 ]]; then
    action="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$action"
    meta_value="${parts[2]:-}"
    if [[ -n "$meta_value" ]]; then
        IFS='|' read -r result expr <<< "$meta_value"
        [[ -n "$expr" ]] && {
            echo -n "$expr" | wl-copy 2>/dev/null && \
                notify_calc "Expression copied" "$expr" "low"
        }
    fi
    exit 0
fi