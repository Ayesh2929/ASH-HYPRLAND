#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  🔢 ASH SEMVER ENGINE — Semantic Versioning 2.0.0 (spec-exact)               ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Implements the complete SemVer 2.0.0 specification:                          ║
# ║    • Parsing with optional leading `v` and build metadata                     ║
# ║    • Precedence rules §11 (major, minor, patch, pre-release, build)           ║
# ║    • Pre-release ordering: numeric identifiers compare numerically,            ║
# ║      alphanumeric compare ASCII, numeric < alphanumeric, fewer fields wins    ║
# ║    • Range/satisfies expressions  (^ ~ >= <= > < = != || /*)                  ║
# ║    • Increment / bump / sort / max / min                                      ║
# ║                                                                               ║
# ║  Reference: https://semver.org/spec/v2.0.0.html                              ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_SEMVER_LOADED:-}" ]] && return 0
readonly _ASH_SEMVER_LOADED=1
readonly ASH_SEMVER_VERSION="5.0.0"

# Regex from the official spec (with optional leading v and build metadata)
readonly _ASH_SEMVER_RE='^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-([0-9A-Za-z.-]+))?(\+([0-9A-Za-z.-]+))?$'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 1  PARSING & VALIDATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ash_semver_parse <version>  →  "MAJOR|MINOR|PATCH|PRERELEASE|BUILD"
# Returns 1 when the input is not a valid semantic version.
#
# The `|` delimiter is deliberate: empty pre-release / build fields must not
# collapse, otherwise `read` would silently shift a build id into the
# pre-release slot and every comparison involving build metadata would fail.
ash_semver_parse() {
    local v="${1:-}"
    [[ "$v" =~ $_ASH_SEMVER_RE ]] || return 1
    printf '%s|%s|%s|%s|%s\n' \
        "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
        "${BASH_REMATCH[5]}" "${BASH_REMATCH[7]}"
}

ash_semver_valid() { ash_semver_parse "${1:-}" >/dev/null 2>&1; }

_ash_semver_part() {
    local v="$1" idx="$2"
    [[ "$v" =~ $_ASH_SEMVER_RE ]] || return 1
    printf '%s' "${BASH_REMATCH[$idx]}"
}

ash_semver_major() { _ash_semver_part "${1:-}" 1; }
ash_semver_minor() { _ash_semver_part "${1:-}" 2; }
ash_semver_patch() { _ash_semver_part "${1:-}" 3; }
ash_semver_prerelease() { _ash_semver_part "${1:-}" 5; }
ash_semver_build() { _ash_semver_part "${1:-}" 7; }

# Strip pre-release + build → canonical MAJOR.MINOR.PATCH
ash_semver_canonical() {
    local v="${1:-}"
    [[ "$v" =~ $_ASH_SEMVER_RE ]] || return 1
    printf '%s.%s.%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
}

# § 2  PRECEDENCE (§11)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Compares two dot-separated identifier lists per spec.
# Echoes -1 | 0 | 1
_ash_semver_cmp_ids() {
    local a="$1" b="$2"

    # "no pre-release" outranks "has pre-release"
    if [[ -z "$a" && -z "$b" ]]; then printf '0'; return 0; fi
    if [[ -z "$a" ]]; then printf '1';  return 0; fi
    if [[ -z "$b" ]]; then printf '%s' '-1'; return 0; fi

    local -a aa bb
    local _saved_ifs="${IFS-}"
    IFS='.' read -r -a aa <<< "$a"
    IFS='.' read -r -a bb <<< "$b"
    IFS="$_saved_ifs"

    local n=${#aa[@]}; (( ${#bb[@]} < n )) && n=${#bb[@]}

    local i x y
    for (( i = 0; i < n; i++ )); do
        x="${aa[i]}"; y="${bb[i]}"
        [[ "$x" == "$y" ]] && continue

        local x_num=0 y_num=0
        [[ "$x" =~ ^[0-9]+$ ]] && x_num=1
        [[ "$y" =~ ^[0-9]+$ ]] && y_num=1

        if [[ $x_num -eq 1 && $y_num -eq 1 ]]; then
            (( x < y )) && { printf '%s' '-1'; return 0; } || { printf '1'; return 0; }
        elif [[ $x_num -eq 1 ]]; then
            printf '%s' '-1'; return 0     # numeric < alphanumeric
        elif [[ $y_num -eq 1 ]]; then
            printf '1'; return 0
        else
            # ASCII lexical order (LC_ALL=C keeps it locale-independent)
            if [[ "$x" < "$y" ]]; then printf '%s' '-1'; else printf '1'; fi
            return 0
        fi
    done

    # All shared fields equal → fewer fields has lower precedence
    if (( ${#aa[@]} < ${#bb[@]} )); then printf '%s' '-1'
    elif (( ${#aa[@]} > ${#bb[@]} )); then printf '1'
    else printf '0'; fi
}

# ash_semver_compare <a> <b> [--include-build]
# Echoes: -1 (a<b) | 0 (a==b) | 1 (a>b)
ash_semver_compare() {
    local a="$1" b="$2"; shift 2 || true
    local include_build=0
    [[ "${1:-}" == "--include-build" ]] && include_build=1

    local pa pb
    pa="$(ash_semver_parse "$a")" || return 2
    pb="$(ash_semver_parse "$b")" || return 2

    local a_maj a_min a_pat a_pre a_bld
    local b_maj b_min b_pat b_pre b_bld
    IFS='|' read -r a_maj a_min a_pat a_pre a_bld <<< "$pa"
    IFS='|' read -r b_maj b_min b_pat b_pre b_bld <<< "$pb"

    (( a_maj > b_maj )) && { printf '1';  return 0; }
    (( a_maj < b_maj )) && { printf '%s' '-1'; return 0; }
    (( a_min > b_min )) && { printf '1';  return 0; }
    (( a_min < b_min )) && { printf '%s' '-1'; return 0; }
    (( a_pat > b_pat )) && { printf '1';  return 0; }
    (( a_pat < b_pat )) && { printf '%s' '-1'; return 0; }

    local pcmp; pcmp="$(_ash_semver_cmp_ids "$a_pre" "$b_pre")"
    [[ "$pcmp" != "0" ]] && { printf '%s' "$pcmp"; return 0; }

    if [[ $include_build -eq 1 ]]; then
        local bcmp; bcmp="$(_ash_semver_cmp_ids "$a_bld" "$b_bld")"
        printf '%s' "$bcmp"; return 0
    fi

    printf '0'
}

ash_semver_lt() { [[ "$(ash_semver_compare "$1" "$2")" == "-1" ]]; }
ash_semver_gt() { [[ "$(ash_semver_compare "$1" "$2")" == "1"  ]]; }
ash_semver_eq() { [[ "$(ash_semver_compare "$1" "$2")" == "0"  ]]; }
ash_semver_lte() { local r; r="$(ash_semver_compare "$1" "$2")"; [[ "$r" == "-1" || "$r" == "0" ]]; }
ash_semver_gte() { local r; r="$(ash_semver_compare "$1" "$2")"; [[ "$r" == "1"  || "$r" == "0" ]]; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 3  SORTING / AGGREGATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Reads versions on stdin, writes them sorted ascending.
ash_semver_sort() {
    local -a lines=()
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -n "${line//[[:space:]]/}" ]] && lines+=("$line")
    done

    # Insertion sort — n is tiny (theme/plugin versions) and this keeps
    # the comparison logic in-process rather than shelling out per pair.
    local i j key
    for (( i = 1; i < ${#lines[@]}; i++ )); do
        key="${lines[i]}"
        j=$(( i - 1 ))
        while (( j >= 0 )) && ash_semver_gt "${lines[j]}" "$key"; do
            lines[j+1]="${lines[j]}"
            (( j -= 1 ))
        done
        lines[j+1]="$key"
    done

    (( ${#lines[@]} )) && printf '%s\n' "${lines[@]}"
}

ash_semver_max() {
    local a="$1" b="$2"
    ash_semver_gte "$a" "$b" && printf '%s' "$a" || printf '%s' "$b"
}

ash_semver_min() {
    local a="$1" b="$2"
    ash_semver_lte "$a" "$b" && printf '%s' "$a" || printf '%s' "$b"
}

# Reads versions on stdin → highest
ash_semver_max_from_stdin() {
    local best="" v
    while IFS= read -r v || [[ -n "$v" ]]; do
        [[ -z "${v//[[:space:]]/}" ]] && continue
        if [[ -z "$best" ]] || ash_semver_gt "$v" "$best"; then best="$v"; fi
    done
    printf '%s' "$best"
}

# ── Diff: what kind of change happened between a and b ──────────────────────
# Echoes: none | patch | minor | major | prerelease
ash_semver_diff() {
    local from="$1" to="$2"
    ash_semver_valid "$from" && ash_semver_valid "$to" || return 1

    local f_maj f_min f_pat t_maj t_min t_pat
    f_maj="$(ash_semver_major "$from")"; f_min="$(ash_semver_minor "$from")"; f_pat="$(ash_semver_patch "$from")"
    t_maj="$(ash_semver_major "$to")";   t_min="$(ash_semver_minor "$to")";   t_pat="$(ash_semver_patch "$to")"

    if (( t_maj != f_maj )); then printf 'major'
    elif (( t_min != f_min )); then printf 'minor'
    elif (( t_pat != f_pat )); then printf 'patch'
    elif [[ "$(ash_semver_prerelease "$from")" != "$(ash_semver_prerelease "$to")" ]]; then printf 'prerelease'
    else printf 'none'; fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 4  INCREMENTING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ash_semver_bump <version> <major|minor|patch|premajor|preminor|prepatch|prerelease|release> [--pre ID]
ash_semver_bump() {
    local v="$1" kind="$2"; shift 2 || true
    local pre_id="alpha"
    while [[ $# -gt 0 ]]; do
        case "$1" in --pre) pre_id="$2"; shift 2 ;; *) shift ;; esac
    done

    ash_semver_valid "$v" || { printf '%s' "$v"; return 1; }

    local maj min pat pre
    maj="$(ash_semver_major "$v")"
    min="$(ash_semver_minor "$v")"
    pat="$(ash_semver_patch "$v")"
    pre="$(ash_semver_prerelease "$v")"

    local base_pre="$pre_id"
    if [[ -n "$pre" ]]; then
        # keep the existing pre-release identifier ("beta" stays "beta")
        local id="${pre%%.[0-9]*}"
        [[ -n "$id" ]] && base_pre="$id"
    fi

    case "$kind" in
        major)      printf '%d.0.0' "$(( maj + 1 ))" ;;
        minor)      printf '%d.%d.0' "$maj" "$(( min + 1 ))" ;;
        patch)      printf '%d.%d.%d' "$maj" "$min" "$(( pat + 1 ))" ;;

        premajor)   printf '%d.0.0-%s.0' "$(( maj + 1 ))" "$base_pre" ;;
        preminor)   printf '%d.%d.0-%s.0' "$maj" "$(( min + 1 ))" "$base_pre" ;;
        prepatch)   printf '%d.%d.%d-%s.0' "$maj" "$min" "$(( pat + 1 ))" "$base_pre" ;;

        prerelease)
            if [[ -z "$pre" ]]; then
                printf '%d.%d.%d-%s.0' "$maj" "$min" "$(( pat + 1 ))" "$base_pre"
            else
                # If the last identifier is numeric, increment it.
                local prefix="${pre%.*}" last="${pre##*.}"
                if [[ "$last" =~ ^[0-9]+$ ]]; then
                    [[ "$prefix" == "$pre" ]] && prefix="$base_pre"
                    printf '%d.%d.%d-%s.%d' "$maj" "$min" "$pat" "$prefix" "$(( last + 1 ))"
                else
                    printf '%d.%d.%d-%s.0' "$maj" "$min" "$pat" "$pre"
                fi
            fi
            ;;

        release|final)
            printf '%d.%d.%d' "$maj" "$min" "$pat" ;;

        *) printf '%s' "$v"; return 1 ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 5  RANGES & SATISFIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Single comparator: ">=" ">=" "1.2.3"
_ash_semver_cmp_op() {
    local version="$1" op="$2" ref="$3"

    # Pre-release handling: a pre-release only satisfies a comparator if
    # the comparator's own tuple shares the same major.minor.patch.
    local v_pre; v_pre="$(ash_semver_prerelease "$version")"
    if [[ -n "$v_pre" ]]; then
        local v_can r_can
        v_can="$(ash_semver_canonical "$version")"
        r_can="$(ash_semver_canonical "$ref")"
        case "$op" in
            '^'|'~')
                # ^ and ~ are handled by the caller (already tuple-checked)
                ;;
        esac
        if [[ "$v_can" != "$r_can" && "$op" != "!=" && "$op" != "<" && "$op" != "<=" ]]; then
            return 1
        fi
    fi

    local cmp; cmp="$(ash_semver_compare "$version" "$ref")" || return 1

    case "$op" in
        '='|'=='|'') [[ "$cmp" == "0"  ]] ;;
        '!=')        [[ "$cmp" != "0"  ]] ;;
        '>')         [[ "$cmp" == "1"  ]] ;;
        '>=')        [[ "$cmp" == "1" || "$cmp" == "0" ]] ;;
        '<')         [[ "$cmp" == "-1" ]] ;;
        '<=')        [[ "$cmp" == "-1" || "$cmp" == "0" ]] ;;
        '^')
            # Compatible-with: allows changes that do not modify the leftmost
            # non-zero element.  ^0.2.3 := >=0.2.3 <0.3.0 ; ^1.2.3 := >=1.2.3 <2.0.0
            local maj min
            maj="$(ash_semver_major "$ref")"; min="$(ash_semver_minor "$ref")"
            if (( maj == 0 )); then
                ash_semver_gte "$version" "$ref" && \
                [[ "$(ash_semver_major "$version")" == "0" ]] && \
                [[ "$(ash_semver_minor "$version")" == "$min" ]]
            else
                ash_semver_gte "$version" "$ref" && \
                [[ "$(ash_semver_major "$version")" == "$maj" ]]
            fi
            ;;
        '~')
            # ~1.2.3 := >=1.2.3 <1.3.0 ; ~1.2 := >=1.2.0 <1.3.0 ; ~1 := >=1.0.0 <2.0.0
            ash_semver_gte "$version" "$ref" && \
            [[ "$(ash_semver_major "$version")" == "$(ash_semver_major "$ref")" ]] && \
            [[ "$(ash_semver_minor "$version")" == "$(ash_semver_minor "$ref")" ]]
            ;;
        *) return 1 ;;
    esac
}

# ash_semver_satisfies <version> <range>
# Range forms: ">=1.0.0 <2.0.0", "^1.2.3", "~1.2", "1.x", "*", "1.2.3 - 2.0.0",
#              "1.0.0 || 2.0.0"
ash_semver_satisfies() {
    local version="$1" range="$2"

    ash_semver_valid "$version" || return 1
    [[ -z "$range" || "$range" == "*" || "$range" == "x" || "$range" == "latest" ]] && return 0

    # OR groups
    local IFS_SAVE="$IFS"
    local -a or_groups
    IFS='|' read -ra or_groups <<< "${range//||/|}"

    local group
    for group in "${or_groups[@]}"; do
        group="${group#"${group%%[![:space:]]*}"}"
        group="${group%"${group##*[![:space:]]}"}"
        [[ -z "$group" ]] && continue

        # Hyphen range: 1.2.3 - 2.3.4
        if [[ "$group" =~ ^[[:space:]]*([v]?[0-9][^[:space:]]*)[[:space:]]+-[[:space:]]+([v]?[0-9][^[:space:]]*)[[:space:]]*$ ]]; then
            local lo="${BASH_REMATCH[1]}" hi="${BASH_REMATCH[2]}"
            ash_semver_gte "$version" "$lo" && ash_semver_lte "$version" "$hi" && \
                { IFS="$IFS_SAVE"; return 0; }
            continue
        fi

        local -a comparators
        IFS=$' \t' read -ra comparators <<< "$group"

        local ok=1 comp op ref
        for comp in "${comparators[@]}"; do
            [[ -z "$comp" ]] && continue

            if [[ "$comp" =~ ^(\^|~|>=|<=|!=|==|=|>|<)?(.*)$ ]]; then
                op="${BASH_REMATCH[1]:-}"
                ref="${BASH_REMATCH[2]}"
            fi
            op="${op:-=}"

            # Wildcards: 1.x, 1.2.x, 1.* , 1.2.*
            if [[ "$ref" == *x || "$ref" == *X || "$ref" == *'*' ]]; then
                local w_maj w_min
                w_maj="$(printf '%s' "$ref" | cut -d. -f1)"
                w_min="$(printf '%s' "$ref" | cut -d. -f2)"
                if [[ "$w_maj" =~ ^[0-9]+$ ]]; then
                    [[ "$(ash_semver_major "$version")" != "$w_maj" ]] && { ok=0; break; }
                fi
                if [[ "${w_min:-}" =~ ^[0-9]+$ ]]; then
                    [[ "$(ash_semver_minor "$version")" != "$w_min" ]] && { ok=0; break; }
                fi
                continue
            fi

            # Bare partial versions: "1.2" → "~1.2.0" ; "1" → "^1.0.0"
            if [[ "$op" == "=" && "$ref" =~ ^[0-9]+\.[0-9]+$ ]]; then op="~"; ref="${ref}.0"; fi
            if [[ "$op" == "=" && "$ref" =~ ^[0-9]+$ ]]; then op="^"; ref="${ref}.0.0"; fi
            [[ "$ref" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+ ]] || ref="$(ash_semver_canonical "$ref" 2>/dev/null || printf '%s' "$ref")"

            if ! _ash_semver_cmp_op "$version" "$op" "$ref"; then ok=0; break; fi
        done

        if [[ $ok -eq 1 ]]; then IFS="$IFS_SAVE"; return 0; fi
    done

    IFS="$IFS_SAVE"
    return 1
}

# Highest version from stdin that satisfies <range>
ash_semver_resolve() {
    local range="$1"
    local v best=""
    while IFS= read -r v || [[ -n "$v" ]]; do
        [[ -z "${v//[[:space:]]/}" ]] && continue
        if ash_semver_satisfies "$v" "$range"; then
            if [[ -z "$best" ]] || ash_semver_gt "$v" "$best"; then best="$v"; fi
        fi
    done < <(ash_semver_sort)
    printf '%s' "$best"
}
