// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║           ASH DOTFILES v3.0 — AGS SYSTEM SERVICE                           ║
// ║           System info polling service (CPU, RAM, battery, network)         ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import { exec, execAsync, readFile } from "resource:///com/github/Aylur/ags/utils.js";
import Variable from "resource:///com/github/Aylur/ags/variable.js";

// ═══════════════════════════════════════════════════════════════════════════════
// 📊 REACTIVE SYSTEM VARIABLES
// ═══════════════════════════════════════════════════════════════════════════════

// CPU usage (updated every 2 seconds)
export const CpuUsage = Variable(0, {
    poll: [2000, "bash -c \"top -bn1 | grep 'Cpu(s)' | awk '{print $2}'\" 2>/dev/null || echo 0"],
    transform: (out) => Math.round(parseFloat(out) || 0),
});

// RAM usage percentage (updated every 3 seconds)
export const RamUsage = Variable(0, {
    poll: [3000, "bash -c \"awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \\\"%.0f\\\", (t-a)*100/t}' /proc/meminfo\""],
    transform: (out) => parseInt(out) || 0,
});

// RAM used in GB
export const RamUsedGB = Variable("0.0", {
    poll: [3000, "bash -c \"awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \\\"%.1f\\\", (t-a)/1024/1024}' /proc/meminfo\""],
    transform: (out) => out.trim() || "0.0",
});

// CPU temperature
export const CpuTemp = Variable(0, {
    poll: [5000, "bash -c \"cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{printf \\\"%.0f\\\", $1/1000}'\" || echo 0"],
    transform: (out) => parseInt(out) || 0,
});

// Battery percentage
export const BatteryPct = Variable(100, {
    poll: [30000, "bash -c \"cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 100\""],
    transform: (out) => parseInt(out) || 100,
});

// Battery charging state
export const BatteryCharging = Variable(false, {
    poll: [15000, "bash -c \"cat /sys/class/power_supply/BAT0/status 2>/dev/null | grep -q 'Charging' && echo true || echo false\""],
    transform: (out) => out.trim() === "true",
});

// Network SSID
export const WifiSSID = Variable("", {
    poll: [10000, "bash -c \"nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 || echo ''\""],
    transform: (out) => out.trim(),
});

// Network signal strength
export const WifiSignal = Variable(0, {
    poll: [10000, "bash -c \"nmcli -t -f active,signal dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 || echo 0\""],
    transform: (out) => parseInt(out) || 0,
});

// Uptime
export const Uptime = Variable("", {
    poll: [60000, "uptime -p 2>/dev/null | sed 's/up //'"],
    transform: (out) => out.trim(),
});

// ═══════════════════════════════════════════════════════════════════════════════
// 🔧 SYSTEM HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

export const SystemHelpers = {

    // Get full system info object
    getInfo() {
        return {
            cpu:      CpuUsage.value,
            cpuTemp:  CpuTemp.value,
            ram:      RamUsage.value,
            ramGB:    RamUsedGB.value,
            battery:  BatteryPct.value,
            charging: BatteryCharging.value,
            wifi:     WifiSSID.value,
            signal:   WifiSignal.value,
            uptime:   Uptime.value,
        };
    },

    // Check if system is low on resources
    isUnderPressure() {
        return CpuUsage.value > 85 || RamUsage.value > 85;
    },

    // Get battery status
    getBatteryStatus() {
        const pct      = BatteryPct.value;
        const charging = BatteryCharging.value;
        if (charging)    return { status: "charging", icon: "󰂄", class: "charging" };
        if (pct <= 10)   return { status: "critical", icon: "󰂎", class: "critical" };
        if (pct <= 25)   return { status: "low",      icon: "󰁺", class: "warning" };
        if (pct <= 50)   return { status: "medium",   icon: "󰁼", class: "medium" };
        if (pct <= 75)   return { status: "good",     icon: "󰁾", class: "good" };
        return           { status: "full",     icon: "󰁹", class: "full" };
    },

    // Get wifi status
    getWifiStatus() {
        const ssid   = WifiSSID.value;
        const signal = WifiSignal.value;

        if (!ssid) return { connected: false, icon: "󰖪", class: "disconnected" };

        let icon = "󰤨";
        let quality = "excellent";
        if (signal < 25)  { icon = "󰤟"; quality = "poor"; }
        else if (signal < 50) { icon = "󰤢"; quality = "fair"; }
        else if (signal < 75) { icon = "󰤥"; quality = "good"; }

        return { connected: true, icon, quality, ssid, signal, class: quality };
    },
};

export default { CpuUsage, RamUsage, RamUsedGB, CpuTemp,
                 BatteryPct, BatteryCharging, WifiSSID, WifiSignal,
                 Uptime, SystemHelpers };