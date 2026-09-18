#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ██████╗  ██████╗██╗                                                            ║
# ║  ██╔══██╗██╔════╝██║                                                            ║
# ║  ██████╔╝██║     ██║                                                            ║
# ║  ██╔═══╝ ██║     ██║                                                            ║
# ║  ██║     ╚██████╗██║                                                            ║
# ║  ╚═╝      ╚═════╝╚═╝                                                            ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  hw pci                                                   ║
# ║  PCI device tree • class filtering • driver binding • bandwidth                 ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_HW_PCI_LOADED:-}" == "1" ]] && return 0
readonly _ASH_HW_PCI_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PCI CLASS DEFINITIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gA _PCI_CLASS_ICON=(
    ["00"]="🔧"  ["01"]="💿"  ["02"]="🌐"  ["03"]="🎮"
    ["04"]="🔊"  ["05"]="🧠"  ["06"]="🌉"  ["07"]="📡"
    ["08"]="⚙️ " ["09"]="💾"  ["0a"]="🔌"  ["0b"]="🔬"
    ["0c"]="🔗"  ["0d"]="📻"  ["0e"]="🔲"  ["ff"]="🔧"
)

declare -gA _PCI_CLASS_NAME=(
    ["00"]="Unclassified"       ["01"]="Storage"
    ["02"]="Network"            ["03"]="Display"
    ["04"]="Multimedia"         ["05"]="Memory"
    ["06"]="Bridge"             ["07"]="Communication"
    ["08"]="Generic System"     ["09"]="Input Device"
    ["0a"]="Docking Station"    ["0b"]="Processor"
    ["0c"]="Serial Bus"         ["0d"]="Wireless"
    ["0e"]="Intelligent I/O"    ["ff"]="Unknown"
)

_pci_class_icon() {
    local class="${1:0:2}"
    printf '%s' "${_PCI_CLASS_ICON[$class]:-🔧}"
}

_pci_class_name() {
    local class="${1:0:2}"
    printf '%s' "${_PCI_CLASS_NAME[$class]:-Unknown}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SYSFS PCI READER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_pci_sysfs_read() {
    local dev_dir="$1" field="$2"
    cat "${dev_dir}/${field}" 2>/dev/null | tr -d '\n' || printf ''
}

_pci_driver() {
    local dev_dir="$1"
    local drv_link="${dev_dir}/driver"
    [[ -L "$drv_link" ]] && basename "$(readlink -f "$drv_link")" || echo 'none'
}

_pci_link_speed() {
    local dev_dir="$1"
    cat "${dev_dir}/current_link_speed" 2>/dev/null | tr -d '\n' || echo '?'
}

_pci_link_width() {
    local dev_dir="$1"
    cat "${dev_dir}/current_link_width" 2>/dev/null | tr -d '\n' || echo '?'
}

_pci_max_link_speed() {
    cat "${1}/max_link_speed" 2>/dev/null | tr -d '\n' || echo '?'
}

_pci_max_link_width() {
    cat "${1}/max_link_width" 2>/dev/null | tr -d '\n' || echo '?'
}

_pci_numa_node() {
    cat "${1}/numa_node" 2>/dev/null | tr -d '\n' || echo '-1'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  LSPCI ENRICHED OUTPUT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_pci_lspci_grouped() {
    command -v lspci &>/dev/null || {
        printf '  \033[38;2;249;226;175m⚠  lspci not found (install pciutils)\033[0m\n'
        return 1
    }

    local current_class="" current_icon="" current_name=""
    local dev_count=0

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        local pci_id dev_class dev_desc
        pci_id="$(  printf '%s' "$line" | awk '{print $1}')"
        dev_class="$(lspci -n -s "$pci_id" 2>/dev/null | awk '{print $2}' | cut -d: -f1 | head -1)"
        dev_desc="$( printf '%s' "$line" | cut -d' ' -f2-)"

        # Remove the class prefix from description
        dev_desc="$(printf '%s' "$dev_desc" | sed 's/^[^:]*: //')"

        # Group by class
        local class_prefix="${dev_class:0:2}"
        local new_icon new_name
        new_icon="$(_pci_class_icon "$class_prefix")"
        new_name="$(_pci_class_name "$class_prefix")"

        if [[ "$class_prefix" != "$current_class" ]]; then
            current_class="$class_prefix"
            printf '\n  %s  \033[1;38;2;203;166;247m%s\033[0m\n' \
                "$new_icon" "$new_name"
        fi

        # Driver
        local sysfs_path="/sys/bus/pci/devices/0000:${pci_id}"
        local drv
        drv="$(_pci_driver "$sysfs_path")"
        local lspd
        lspd="$(_pci_link_speed "$sysfs_path")"

        local drv_color
        [[ "$drv" == "none" ]] && \
            drv_color=$'\033[38;2;249;226;175m' || \
            drv_color=$'\033[38;2;148;226;213m'

        printf '  \033[38;2;108;112;134m  [%s]\033[0m  \033[38;2;205;214;244m%-55s\033[0m  %s%s\033[0m\n' \
            "$pci_id" \
            "${dev_desc:0:54}" \
            "$drv_color" \
            "$drv"

        [[ "$lspd" != "?" ]] && \
            printf '  \033[38;2;88;91;112m        Link: %s  x%s\033[0m\n' \
                "$lspd" "$(_pci_link_width "$sysfs_path")"

        (( dev_count++ )) || true

    done < <(lspci 2>/dev/null | sort -k2)

    printf '\n  \033[38;2;108;112;134m%d PCI device(s)\033[0m\n' "$dev_count"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_hw_pci() {
    local filter=""
    local show_verbose=0
    local short=0

    for arg in "${@:-}"; do
        case "$arg" in
            --verbose|-v) show_verbose=1 ;;
            --short)      short=1        ;;
            --gpu|--display) filter="display" ;;
            --network)    filter="network" ;;
            --storage)    filter="storage" ;;
            *)            filter="$arg"   ;;
        esac
    done

    hw_section "🚌" "PCI Devices" $'\033[38;2;250;179;135m'

    if [[ -n "$filter" ]]; then
        printf '\n  \033[38;2;108;112;134mFilter: %s\033[0m\n' "$filter"
        if command -v lspci &>/dev/null; then
            lspci 2>/dev/null | grep -i "$filter" | while IFS= read -r line; do
                local pci_id desc
                pci_id="$(printf '%s' "$line" | awk '{print $1}')"
                desc="$(  printf '%s' "$line" | cut -d' ' -f2-)"
                printf '  \033[38;2;108;112;134m[%s]\033[0m  \033[38;2;205;214;244m%s\033[0m\n' \
                    "$pci_id" "$desc"
            done
        fi
    else
        _pci_lspci_grouped
    fi

    if [[ $show_verbose -eq 1 ]] && command -v lspci &>/dev/null; then
        hw_section "🔬" "Verbose PCI Detail" $'\033[38;2;137;180;250m'
        lspci -v 2>/dev/null | head -80 | while IFS= read -r line; do
            printf '  \033[38;2;108;112;134m%s\033[0m\n' "$line"
        done
    fi

    hw_divider
}
