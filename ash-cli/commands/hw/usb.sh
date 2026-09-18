#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██╗   ██╗███████╗██████╗                                                        ║
# ║  ██║   ██║██╔════╝██╔══██╗                                                       ║
# ║  ██║   ██║███████╗██████╔╝                                                       ║
# ║  ██║   ██║╚════██║██╔══██╗                                                       ║
# ║  ╚██████╔╝███████║██████╔╝                                                       ║
# ║   ╚═════╝ ╚══════╝╚═════╝                                                        ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  hw usb                                                   ║
# ║  USB device tree • speeds • power draw • hub topology • driver binding           ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_HW_USB_LOADED:-}" == "1" ]] && return 0
readonly _ASH_HW_USB_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  USB SPEED CLASSIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gA _USB_SPEED_LABEL=(
    ["1.5"]="USB 1.0  (Low Speed  1.5 Mb/s)"
    ["12"]="USB 1.1  (Full Speed  12 Mb/s)"
    ["480"]="USB 2.0  (Hi-Speed  480 Mb/s)"
    ["5000"]="USB 3.0  (SuperSpeed  5 Gb/s)"
    ["10000"]="USB 3.1  (SuperSpeed+  10 Gb/s)"
    ["20000"]="USB 3.2  (SuperSpeed+  20 Gb/s)"
    ["40000"]="USB 4.0  (40 Gb/s)"
)

declare -gA _USB_SPEED_COLOR=(
    ["1.5"]=$'\033[38;2;108;112;134m'
    ["12"]=$'\033[38;2;108;112;134m'
    ["480"]=$'\033[38;2;249;226;175m'
    ["5000"]=$'\033[38;2;166;227;161m'
    ["10000"]=$'\033[38;2;137;220;235m'
    ["20000"]=$'\033[38;2;137;180;250m'
    ["40000"]=$'\033[38;2;203;166;247m'
)

_usb_speed_label() {
    local spd="$1"
    printf '%s' "${_USB_SPEED_LABEL[$spd]:-USB (${spd} Mb/s)}"
}

_usb_speed_color() {
    local spd="$1"
    local nc="${ASH_FLAG_NO_COLOR:-0}"
    [[ "$nc" -eq 1 ]] && return 0

    case "$spd" in
        1.5|12)   printf '\033[38;2;108;112;134m' ;;
        480)      printf '\033[38;2;249;226;175m'  ;;
        5000)     printf '\033[38;2;166;227;161m'  ;;
        10000)    printf '\033[38;2;137;220;235m'  ;;
        20000)    printf '\033[38;2;137;180;250m'  ;;
        40000)    printf '\033[38;2;203;166;247m'  ;;
        *)        printf '\033[38;2;205;214;244m'  ;;
    esac
}

_usb_speed_icon() {
    case "$1" in
        1.5|12)  printf '🔌' ;;
        480)     printf '🟡' ;;
        5000)    printf '🔵' ;;
        10000)   printf '🟢' ;;
        20000)   printf '⚡' ;;
        40000)   printf '🚀' ;;
        *)       printf '🔌' ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SYSFS USB DEVICE READER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_usb_read() {
    local dir="$1" file="$2"
    cat "${dir}/${file}" 2>/dev/null | tr -d '\n' || printf ''
}

_usb_read_int() {
    local val
    val="$(_usb_read "$1" "$2")"
    printf '%d' "${val:-0}" 2>/dev/null || printf '0'
}

_usb_product_string() {
    local dir="$1"
    local manufacturer product
    manufacturer="$(_usb_read "$dir" "manufacturer")"
    product="$(     _usb_read "$dir" "product")"

    if [[ -n "$manufacturer" ]] && [[ -n "$product" ]]; then
        # Deduplicate (some devices repeat manufacturer in product)
        if printf '%s' "$product" | grep -qi "$manufacturer"; then
            printf '%s' "$product"
        else
            printf '%s %s' "$manufacturer" "$product"
        fi
    elif [[ -n "$product" ]]; then
        printf '%s' "$product"
    elif [[ -n "$manufacturer" ]]; then
        printf '%s' "$manufacturer"
    else
        printf 'Unknown Device'
    fi
}

_usb_class_name() {
    local class="$1"
    case "$class" in
        00) printf 'Composite'      ;;
        01) printf 'Audio'          ;;
        02) printf 'CDC/Comm'       ;;
        03) printf 'HID (Input)'    ;;
        05) printf 'Physical'       ;;
        06) printf 'Still Image'    ;;
        07) printf 'Printer'        ;;
        08) printf 'Mass Storage'   ;;
        09) printf 'Hub'            ;;
        0a) printf 'CDC Data'       ;;
        0b) printf 'Smart Card'     ;;
        0d) printf 'Content Sec'    ;;
        0e) printf 'Video'          ;;
        0f) printf 'Healthcare'     ;;
        10) printf 'AV'             ;;
        11) printf 'Billboard'      ;;
        12) printf 'Type-C Bridge'  ;;
        dc) printf 'Diagnostic'     ;;
        e0) printf 'Wireless'       ;;
        ef) printf 'Miscellaneous'  ;;
        fe) printf 'App-Specific'   ;;
        ff) printf 'Vendor-Specific';;
        *)  printf "Class 0x${class}" ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  USB TREE BUILDER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g _USB_TOTAL_DEVS=0
declare -g _USB_TOTAL_HUB=0
declare -gA _USB_POWER_MAP=()

_usb_render_device() {
    local dir="$1"
    local depth="${2:-0}"
    local is_last="${3:-0}"

    local indent=""
    for (( i=0; i<depth; i++ )); do
        indent+="   "
    done

    local connector
    if (( is_last )); then
        connector="└─"
    else
        connector="├─"
    fi

    # Device fields
    local vid pid speed dev_class
    vid="$(       _usb_read     "$dir" "idVendor")"
    pid="$(       _usb_read     "$dir" "idProduct")"
    speed="$(     _usb_read     "$dir" "speed")"
    dev_class="$( _usb_read     "$dir" "bDeviceClass")"

    local product
    product="$(_usb_product_string "$dir")"

    # Power
    local ma
    ma="$(_usb_read_int "$dir" "bMaxPower")"
    # bMaxPower in 2mA units for USB 2, 8mA units for USB 3
    # sysfs reports in mA directly for most modern kernels
    local ma_label=""
    if (( ma > 0 )); then
        ma_label="${ma}mA"
        _USB_POWER_MAP["$product"]="${ma}mA"
    fi

    # Speed icon and color
    local spd_icon spd_color spd_reset
    spd_icon="$(_usb_speed_icon "$speed")"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        spd_color="$(_usb_speed_color "$speed")"
        spd_reset=$'\033[0m'
    else
        spd_color=""
        spd_reset=""
    fi

    # Class decoration
    local class_name
    class_name="$(_usb_class_name "$dev_class")"
    local class_badge=""
    if [[ "$dev_class" == "09" ]]; then
        class_badge="  [HUB]"
        (( _USB_TOTAL_HUB++ )) || true
    fi

    (( _USB_TOTAL_DEVS++ )) || true

    # Print line
    printf '  %s%s%s %s%s[%s:%s]%s  %s%s%s%s\n' \
        $'\033[38;2;108;112;134m' \
        "${indent}${connector}" \
        "${spd_color}" \
        "$spd_icon" \
        $'\033[0m\033[38;2;205;214;244m' \
        "${vid:-????}" \
        "${pid:-????}" \
        $'\033[0m' \
        $'\033[38;2;137;220;235m' \
        "${product}" \
        $'\033[0m' \
        "${class_badge}"

    # Details row
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '  %s     %s  %s%-18s%s  %s%s%s  %s%s%s\n' \
            "\033[38;2;108;112;134m${indent}" \
            $'\033[38;2;108;112;134m' \
            $'\033[38;2;249;226;175m' \
            "$(_usb_speed_label "$speed")" \
            $'\033[0m' \
            $'\033[38;2;108;112;134m' \
            "$class_name" \
            $'\033[0m' \
            $'\033[38;2;250;179;135m' \
            "$ma_label" \
            $'\033[0m'
    fi
}

_usb_walk_tree() {
    local parent_dir="$1"
    local depth="${2:-0}"

    # Find child USB devices (ports N-M pattern under parent bus)
    local parent_name
    parent_name="$(basename "$parent_dir")"

    local -a children=()
    mapfile -t children < <(
        find "$parent_dir" -maxdepth 1 -name "${parent_name}-[0-9]*" \
             -type d 2>/dev/null | \
        grep -v ':' | sort -V
    )

    local total="${#children[@]}"
    local idx=0

    for child in "${children[@]}"; do
        (( idx++ )) || true
        local is_last=$(( idx == total ? 1 : 0 ))

        _usb_render_device "$child" "$depth" "$is_last"

        # Recurse if hub
        local child_class
        child_class="$(_usb_read "$child" "bDeviceClass")"
        if [[ "$child_class" == "09" ]]; then
            _usb_walk_tree "$child" "$(( depth + 1 ))"
        fi
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  STATISTICS TABLE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_usb_stats() {
    printf '\n'
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '\033[1;38;2;203;166;247m  ┌──────────────────────────────────┐\033[0m\n'
        printf '\033[1;38;2;203;166;247m  │  📊  USB Summary                   │\033[0m\n'
        printf '\033[1;38;2;203;166;247m  ├──────────────────────────────────┤\033[0m\n'
        printf '  │  \033[38;2;166;227;161m%-8s devices total\033[0m          │\n' "$_USB_TOTAL_DEVS"
        printf '  │  \033[38;2;137;220;235m%-8s hubs\033[0m                   │\n' "$_USB_TOTAL_HUB"
        printf '\033[1;38;2;203;166;247m  └──────────────────────────────────┘\033[0m\n'
    else
        printf '  USB Summary: %d devices  •  %d hubs\n' \
            "$_USB_TOTAL_DEVS" "$_USB_TOTAL_HUB"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  LSUSB FALLBACK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_usb_lsusb_display() {
    if ! command -v lsusb &>/dev/null; then
        printf '\n  \033[38;2;249;226;175m⚠  lsusb not found — install usbutils\033[0m\n'
        return 1
    fi

    hw_section "🔌" "USB Devices  (lsusb)" "$(_hw_teal 2>/dev/null || printf '\033[38;2;148;226;213m')"

    local count=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local bus device id desc
        bus="$(    printf '%s' "$line" | grep -oP 'Bus \K\d+')"
        device="$( printf '%s' "$line" | grep -oP 'Device \K\d+')"
        id="$(     printf '%s' "$line" | grep -oP 'ID \K[\w:.]+')"
        desc="$(   printf '%s' "$line" | sed 's/.*ID [^ ]* //')"

        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
            printf '  \033[38;2;108;112;134mBus%-3s Dev%-3s\033[0m  \033[38;2;250;179;135m[%s]\033[0m  \033[38;2;137;220;235m%s\033[0m\n' \
                "$bus" "$device" "$id" "$desc"
        else
            printf '  Bus%-3s Dev%-3s  [%s]  %s\n' "$bus" "$device" "$id" "$desc"
        fi
        (( count++ )) || true
    done < <(lsusb 2>/dev/null | sort)

    printf '\n  \033[38;2;108;112;134m%d USB device(s) found\033[0m\n' "$count"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_hw_usb() {
    local use_tree=1
    local show_power=0
    local short=0

    for arg in "${@:-}"; do
        case "$arg" in
            --flat|--lsusb) use_tree=0  ;;
            --power)        show_power=1 ;;
            --short)        short=1      ;;
        esac
    done

    hw_section "🔌" "USB Devices" $'\033[38;2;137;220;235m'

    # Legend
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ $short -eq 0 ]]; then
        printf '  \033[38;2;108;112;134m'
        printf '  Legend:  '
        printf '🔌 USB 1.x  '
        printf '🟡 USB 2.0  '
        printf '🔵 USB 3.0  '
        printf '🟢 USB 3.1  '
        printf '⚡ USB 3.2  '
        printf '🚀 USB 4.0\033[0m\n'
    fi

    if [[ "$use_tree" -eq 1 ]]; then
        # Walk sysfs USB bus tree
        local bus_found=0

        for bus_dir in /sys/bus/usb/devices/usb*/; do
            [[ -d "$bus_dir" ]] || continue

            local bus_name
            bus_name="$(basename "$bus_dir")"
            local bus_speed
            bus_speed="$(_usb_read "$bus_dir" "speed")"
            local bus_product
            bus_product="$(_usb_product_string "$bus_dir")"

            printf '\n'
            if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
                printf '  \033[1;38;2;203;166;247m⊕ %s\033[0m  \033[38;2;108;112;134m%s  %s\033[0m\n' \
                    "$bus_name" "$bus_product" "$(_usb_speed_label "$bus_speed")"
            else
                printf '  ⊕ %s  %s  %s\n' \
                    "$bus_name" "$bus_product" "$(_usb_speed_label "$bus_speed")"
            fi

            _usb_walk_tree "$bus_dir" 0
            (( bus_found++ )) || true
        done

        if (( bus_found == 0 )); then
            _usb_lsusb_display
        fi
    else
        _usb_lsusb_display
    fi

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        printf '{"usb_devices":%d,"hubs":%d}\n' \
            "$_USB_TOTAL_DEVS" "$_USB_TOTAL_HUB"
        return 0
    fi

    _usb_stats
    hw_divider
}
