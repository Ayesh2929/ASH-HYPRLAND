#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  backup verify                                            ║
# ║  Verify backup integrity: SHA256 • tar test • manifest comparison • health score ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_BK_VERIFY_LOADED:-}" == "1" ]] && return 0
readonly _ASH_BK_VERIFY_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HEALTH SCORE RENDERER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_verify_health_display() {
    local score="$1"
    local bar_w=30
    local filled=$(( score * bar_w / 100 ))
    local empty=$(( bar_w - filled ))

    local grade color
    if   (( score >= 95 )); then grade="A+"; color="$(_bkgreen)"
    elif (( score >= 80 )); then grade="A";  color="$(_bkgreen)"
    elif (( score >= 60 )); then grade="B";  color="$(_bkyellow)"
    elif (( score >= 40 )); then grade="C";  color="$(_bkpeach)"
    else                         grade="F";  color="$(_bkred)"
    fi

    printf '\n  %sHealth Score:%s  %s%s%s%s%s  %s%s%d%%%s  %sGrade: %s%s%s\n\n' \
        "$(_bkdim)" "$(_bkr)" \
        "$color" "$(printf '█%.0s' $(seq 1 $filled))" \
        "$(_bkdim)" "$(printf '░%.0s' $(seq 1 $empty))" "$(_bkr)" \
        "$(_bkbold)$color" "" "$score" "$(_bkr)" \
        "$(_bkdim)" "$(_bkbold)$color" "$grade" "$(_bkr)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_backup_verify() {
    local bk_id=""  verify_all=0

    for arg in "${@:-}"; do
        case "$arg" in
            --all|-a) verify_all=1  ;;
            ash-*)    bk_id="$arg"  ;;
        esac
    done

    bk_section "🔍" "Verify Backup" "$(_bkgreen)"

    # Get backup list to verify
    local -a verify_ids=()

    if [[ $verify_all -eq 1 ]]; then
        if [[ -f "$_BK_INDEX_FILE" ]]; then
            mapfile -t verify_ids < <(
                python3 -c "
import json
data = json.load(open('${_BK_INDEX_FILE}'))
for k in data: print(k)
" 2>/dev/null || true
            )
        fi
    elif [[ -n "$bk_id" ]]; then
        verify_ids=("$bk_id")
    else
        # Pick most recent
        local recent_id
        recent_id="$(python3 -c "
import json
data = json.load(open('${_BK_INDEX_FILE}'))
if data:
    last = max(data.items(), key=lambda x: x[1].get('created_at',''))
    print(last[0])
" 2>/dev/null || echo '')"
        [[ -n "$recent_id" ]] && verify_ids=("$recent_id")
    fi

    if [[ ${#verify_ids[@]} -eq 0 ]]; then
        bk_fail "No backup ID specified"
        bk_info "Usage: ash bk verify ash-full-20240101-120000-abc123"
        bk_info "Or use: ash bk verify --all"
        printf '\n'; return 1
    fi

    local total_pass=0  total_fail=0  total_warn=0

    for bk_id in "${verify_ids[@]}"; do
        printf '\n  %s%s%s\n' "$(_bkbold)$(_bksky)" "$bk_id" "$(_bkr)"
        printf '  %s%s%s\n' "$(_bkdim)" "$(printf '─%.0s' $(seq 1 55))" "$(_bkr)"

        local bk_path
        bk_path="$(bk_index_get "$bk_id" path)"

        if [[ -z "$bk_path" ]] || [[ ! -f "$bk_path" ]]; then
            bk_fail "Archive file not found: ${bk_path:-?}"
            (( total_fail++ )) || true
            continue
        fi

        local score=100  checks_passed=0  checks_total=0

        # ── Check 1: File exists ──────────────────────────────────────────────────
        (( checks_total++ )) || true
        bk_ok "Archive file exists"
        (( checks_passed++ )) || true

        # ── Check 2: File size > 0 ────────────────────────────────────────────────
        (( checks_total++ )) || true
        local file_size
        file_size="$(stat -c '%s' "$bk_path" 2>/dev/null || echo 0)"
        if (( file_size > 0 )); then
            bk_ok "File size: $(bk_human_size "$file_size")"
            (( checks_passed++ )) || true
        else
            bk_fail "Empty archive file!"
            (( score -= 40 )) || true
            (( total_fail++ )) || true
        fi

        # ── Check 3: SHA256 hash ──────────────────────────────────────────────────
        (( checks_total++ )) || true
        local manifest_file="${_BK_MANIFEST_DIR}/${bk_id}.json"
        if [[ -f "$manifest_file" ]]; then
            local stored_hash current_hash
            stored_hash="$(python3 -c "
import json
d = json.load(open('${manifest_file}'))
print(d.get('sha256',''))
" 2>/dev/null || echo '')"

            if [[ -n "$stored_hash" ]] && [[ "$stored_hash" != unavailable* ]]; then
                bk_spin_start "Computing SHA256..."
                current_hash="$(sha256sum "$bk_path" 2>/dev/null | awk '{print $1}')"
                bk_spin_stop 1 ""

                if [[ "$current_hash" == "$stored_hash" ]]; then
                    bk_ok "SHA256 checksum verified"
                    (( checks_passed++ )) || true
                else
                    bk_fail "SHA256 MISMATCH — archive may be corrupted!"
                    bk_kv "  Expected" "${stored_hash:0:20}..."
                    bk_kv "  Got"      "${current_hash:0:20}..."
                    (( score -= 50 )) || true
                    (( total_fail++ )) || true
                fi
            else
                bk_warn "No stored hash in manifest"
                (( score -= 10 )) || true
                (( total_warn++ )) || true
            fi
        else
            bk_warn "No manifest file found"
            (( score -= 10 )) || true
            (( total_warn++ )) || true
        fi

        # ── Check 4: Tar listing (structural integrity) ────────────────────────────
        (( checks_total++ )) || true
        local encrypted_flag
        encrypted_flag="$(bk_index_get "$bk_id" encrypted)"

        if [[ "$encrypted_flag" != "true" ]] && [[ ! "$bk_path" =~ \.gpg$ ]]; then
            bk_spin_start "Testing archive structure..."
            local tar_test_exit=0
            tar --test-label --file="$bk_path" &>/dev/null 2>&1 || \
                tar -t --file="$bk_path" &>/dev/null 2>&1 | \
                head -5 &>/dev/null || tar_test_exit=$?

            if [[ $tar_test_exit -eq 0 ]]; then
                local file_count
                file_count="$(tar -t --file="$bk_path" 2>/dev/null | wc -l || echo '?')"
                bk_spin_stop 1 "Archive structure OK  (${file_count} entries)"
                (( checks_passed++ )) || true
            else
                bk_spin_stop 0 "Archive structure DAMAGED"
                (( score -= 30 )) || true
                (( total_fail++ )) || true
            fi
        else
            bk_info "Skipping tar test for encrypted archive"
            (( checks_passed++ )) || true
        fi

        # ── Check 5: Age check ────────────────────────────────────────────────────
        (( checks_total++ )) || true
        local created_at
        created_at="$(bk_index_get "$bk_id" created_at)"
        if [[ -n "$created_at" ]]; then
            local age_days
            age_days="$(python3 -c "
from datetime import datetime, timezone
now = datetime.now(timezone.utc)
try:
    created = datetime.fromisoformat('${created_at}'.replace('Z','+00:00'))
    diff = (now - created).days
    print(diff)
except:
    print(0)
" 2>/dev/null || echo 0)"

            if (( age_days > 90 )); then
                bk_warn "Backup is ${age_days} days old — consider refreshing"
                (( score -= 5 )) || true
                (( total_warn++ )) || true
            else
                bk_ok "Backup age: ${age_days} day(s)"
                (( checks_passed++ )) || true
            fi
        fi

        # Clamp score
        (( score < 0 )) && score=0

        _verify_health_display "$score"
        bk_kv "Checks"  "${checks_passed}/${checks_total} passed"
        (( total_pass += checks_passed )) || true
    done

    # Final summary
    if [[ ${#verify_ids[@]} -gt 1 ]]; then
        bk_section "📊" "Verification Summary" "$(_bkdim)"
        bk_kv "Backups verified" "${#verify_ids[@]}"
        bk_kv "Total failures"   "$total_fail"
        bk_kv "Total warnings"   "$total_warn"
    fi

    bk_log_info "verify: ${#verify_ids[@]} backups checked  failures=${total_fail}"

    [[ $total_fail -eq 0 ]] && \
        bk_notify "🔍 Verified" "All ${#verify_ids[@]} backup(s) OK" "normal" || \
        bk_notify "⚠️ Verify Failed" "${total_fail} backup(s) failed" "critical"

    printf '\n'
    [[ $total_fail -eq 0 ]]
}
