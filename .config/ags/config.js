// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║           ASH DOTFILES v3.0 — AGS WIDGET SYSTEM CONFIG                     ║
// ║           Aylur's GTK Shell — Dynamic widgets with theme integration       ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import App from "resource:///com/github/Aylur/ags/app.js";
import { exec, execAsync, readFile, writeFile, monitorFile } from "resource:///com/github/Aylur/ags/utils.js";
import Variable from "resource:///com/github/Aylur/ags/variable.js";

// ── Import modules ────────────────────────────────────────────────────────────
import Bar           from "./modules/bar.js";
import Notifications from "./modules/notifications.js";
import OSD           from "./modules/osd.js";
import Overview      from "./modules/overview.js";

// ── Import services ───────────────────────────────────────────────────────────
import HyprlandService from "./services/hyprland.js";
import AudioService    from "./services/audio.js";
import SystemService   from "./services/system.js";

// ═══════════════════════════════════════════════════════════════════════════════
// 🎨 THEME INTEGRATION
// ═══════════════════════════════════════════════════════════════════════════════

const HOME       = exec("echo $HOME").trim();
const CACHE_DIR  = `${HOME}/.cache/ash-dots`;
const COLOR_FILE = `${CACHE_DIR}/colors/current.json`;

// Load ASH color palette
function loadAshColors() {
    const defaults = {
        base:      "#1e1e2e",
        mantle:    "#181825",
        surface0:  "#313244",
        surface1:  "#45475a",
        surface2:  "#585b70",
        overlay0:  "#6c7086",
        overlay1:  "#7f849c",
        primary:   "#cba6f7",
        secondary: "#89b4fa",
        tertiary:  "#94e2d5",
        text:      "#cdd6f4",
        subtext1:  "#bac2de",
        subtext0:  "#a6adc8",
        muted:     "#7f849c",
        success:   "#a6e3a1",
        warning:   "#f9e2af",
        error:     "#f38ba8",
        info:      "#89b4fa",
    };

    try {
        const content = readFile(COLOR_FILE);
        const parsed  = JSON.parse(content);

        // Flatten nested structure from theme engine
        const colors = {};
        for (const [section, values] of Object.entries(parsed)) {
            if (typeof values === "object" && !Array.isArray(values)) {
                for (const [key, val] of Object.entries(values)) {
                    if (typeof val === "string" && val.startsWith("#")) {
                        colors[key] = val;
                    }
                }
            }
        }

        return { ...defaults, ...colors };
    } catch (e) {
        return defaults;
    }
}

// Reactive color variable
export const Colors = Variable(loadAshColors(), {});

// Watch for theme changes
try {
    monitorFile(COLOR_FILE, () => {
        Colors.setValue(loadAshColors());
        console.log("[AGS] Theme colors updated");
    });
} catch (e) {
    console.warn("[AGS] Could not monitor color file:", e);
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🖥️ MONITOR DETECTION
// ═══════════════════════════════════════════════════════════════════════════════

function getMonitors() {
    try {
        const output = exec("hyprctl monitors -j");
        return JSON.parse(output);
    } catch (e) {
        console.error("[AGS] Failed to get monitors:", e);
        return [];
    }
}

const monitors = getMonitors();

// ═══════════════════════════════════════════════════════════════════════════════
// 🚀 APPLICATION CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════════

App.config({
    // ── Style ─────────────────────────────────────────────────────────────────
    style: `${App.configDir}/styles/main.scss`,

    // ── Windows ───────────────────────────────────────────────────────────────
    windows: [
        // Bar on each monitor
        ...monitors.map(monitor => Bar(monitor.id, monitor.name)),

        // Notification overlay (all monitors)
        Notifications(),

        // OSD overlay (volume, brightness)
        OSD(),

        // Overview/workspace switcher
        Overview(),
    ],

    // ── Closeable ─────────────────────────────────────────────────────────────
    closeWindowDelay: {
        "overview":       250,
        "notifications":  250,
        "osd":            1500,
    },
});

// ═══════════════════════════════════════════════════════════════════════════════
// 🌐 GLOBAL HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

// Toggle overview with SUPER
globalThis.toggleOverview = () => {
    App.toggleWindow("overview");
};

// Show OSD
globalThis.showOSD = (type, value) => {
    const osd = App.getWindow("osd");
    if (osd) {
        OSD.show(type, value);
    }
};

// Theme reload handler
globalThis.reloadTheme = () => {
    Colors.setValue(loadAshColors());
    App.resetCss();
    App.applyCss(`${App.configDir}/styles/main.scss`);
    console.log("[AGS] Theme reloaded");
};

// ═══════════════════════════════════════════════════════════════════════════════
// 📡 IPC COMMANDS (accessible via `ags -r "command"`)
// ═══════════════════════════════════════════════════════════════════════════════

globalThis.ags = {
    theme: {
        reload:  () => globalThis.reloadTheme(),
        colors:  () => Colors.value,
    },
    windows: {
        toggle:  (name) => App.toggleWindow(name),
        open:    (name) => App.openWindow(name),
        close:   (name) => App.closeWindow(name),
        list:    () => App.windows.map(w => w.name),
    },
    overview: {
        toggle:  () => App.toggleWindow("overview"),
        open:    () => App.openWindow("overview"),
        close:   () => App.closeWindow("overview"),
    },
    system: {
        info:    () => SystemService.getInfo(),
    },
};

console.log("[AGS] ASH Widget System started ✓");