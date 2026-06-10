// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║           ASH DOTFILES v3.0 — AGS BAR MODULE                               ║
// ║           Complete status bar widget                                        ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import Widget      from "resource:///com/github/Aylur/ags/widget.js";
import App         from "resource:///com/github/Aylur/ags/app.js";
import { exec, execAsync } from "resource:///com/github/Aylur/ags/utils.js";
import Variable    from "resource:///com/github/Aylur/ags/variable.js";

// Services
import Hyprland    from "resource:///com/github/Aylur/ags/service/hyprland.js";
import Audio       from "resource:///com/github/Aylur/ags/service/audio.js";
import Battery     from "resource:///com/github/Aylur/ags/service/battery.js";
import Network     from "resource:///com/github/Aylur/ags/service/network.js";
import Bluetooth   from "resource:///com/github/Aylur/ags/service/bluetooth.js";
import Mpris       from "resource:///com/github/Aylur/ags/service/mpris.js";
import SystemTray  from "resource:///com/github/Aylur/ags/service/systemtray.js";
import Notifications from "resource:///com/github/Aylur/ags/service/notifications.js";

import { Colors } from "../config.js";

// ═══════════════════════════════════════════════════════════════════════════════
// 🚀 LAUNCHER BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

const Launcher = () => Widget.Button({
    class_name: "launcher-btn",
    tooltip_text: "App Launcher",
    child: Widget.Label({
        class_name: "launcher-icon",
        label: "  ",
    }),
    on_clicked: () => {
        execAsync("~/.config/rofi/scripts/launcher.sh").catch(console.error);
    },
    on_secondary_click: () => {
        App.toggleWindow("overview");
    },
});

// ═══════════════════════════════════════════════════════════════════════════════
// 🗂️ WORKSPACES
// ═══════════════════════════════════════════════════════════════════════════════

const WORKSPACE_ICONS = {
    1:  "󰆍",  // Terminal
    2:  "󰖟",  // Browser
    3:  "󰘦",  // Code
    4:  "󰉋",  // Files
    5:  "󰝚",  // Music
    6:  "󰭹",  // Chat
    7:  "󰇮",  // Email
    8:  "󰊗",  // Gaming
    9:  "󰍹",  // System
    10: "󱃠",  // Misc
};

const WorkspaceButton = (id, monitorId) => {
    const active   = Variable(Hyprland.active.workspace.id === id);
    const occupied = Variable(false);

    Hyprland.connect("changed", () => {
        active.setValue(Hyprland.active.workspace.id === id);
        occupied.setValue(Hyprland.clients.some(c => c.workspace.id === id));
    });

    return Widget.Button({
        class_name: active.bind().as(a =>
            `workspace-btn ${a ? "active" : occupied.value ? "occupied" : "empty"}`
        ),
        child: Widget.Label({
            label: WORKSPACE_ICONS[id] || String(id),
        }),
        on_clicked: () => {
            Hyprland.messageAsync(`dispatch workspace ${id}`).catch(console.error);
        },
        tooltip_text: `Workspace ${id}`,
    });
};

const Workspaces = (monitorId) => Widget.Box({
    class_name: "workspaces",
    children:   Array.from({ length: 10 }, (_, i) =>
        WorkspaceButton(i + 1, monitorId)
    ),
});

// ═══════════════════════════════════════════════════════════════════════════════
// 🪟 ACTIVE WINDOW TITLE
// ═══════════════════════════════════════════════════════════════════════════════

const WindowTitle = () => {
    const title = Variable(Hyprland.active.client.title || "Desktop");

    Hyprland.connect("changed", () => {
        const t = Hyprland.active.client.title;
        title.setValue(t ? (t.length > 50 ? t.slice(0, 49) + "…" : t) : "Desktop");
    });

    return Widget.Label({
        class_name: "window-title",
        label:      title.bind(),
        max_width_chars: 50,
        truncate:   "end",
    });
};

// ═══════════════════════════════════════════════════════════════════════════════
// 🕐 CLOCK
// ═══════════════════════════════════════════════════════════════════════════════

const Clock = () => {
    const time = Variable("", {
        poll: [1000, "date '+%H:%M'"],
    });

    const date = Variable("", {
        poll: [60000, "date '+%A, %B %d'"],
    });

    let showDate = false;

    return Widget.Button({
        class_name: "clock",
        child:       Widget.Label({ label: time.bind().as(t => `  ${t}`) }),
        tooltip_text: date.bind().as(d => `📅 ${d}`),
        on_clicked:  () => {
            showDate = !showDate;
            // Toggle between time and date display
        },
    });
};

// ═══════════════════════════════════════════════════════════════════════════════
// 🎵 MEDIA PLAYER
// ═══════════════════════════════════════════════════════════════════════════════

const MediaPlayer = () => {
    const label = Variable("", {});

    // Update on MPRIS changes
    const updateMedia = () => {
        const player = Mpris.players[0];
        if (!player || player.play_back_status === "Stopped") {
            label.setValue("");
            return;
        }

        const icon   = player.play_back_status === "Playing" ? "󰎈" : "󰏤";
        const title  = (player.track_title || "").slice(0, 30);
        const artist = (player.track_artists?.[0] || "").slice(0, 20);

        if (artist && title) {
            label.setValue(`${icon} ${artist} — ${title}`);
        } else if (title) {
            label.setValue(`${icon} ${title}`);
        } else {
            label.setValue("");
        }
    };

    Mpris.connect("changed", updateMedia);
    updateMedia();

    return Widget.Button({
        class_name:  "media-player",
        child:        Widget.Label({
            label:      label.bind(),
            max_width_chars: 40,
            truncate:   "end",
        }),
        visible:      label.bind().as(l => l !== ""),
        on_clicked:  () => execAsync("playerctl play-pause").catch(() => {}),
        on_secondary_click: () => execAsync("playerctl next").catch(() => {}),
        on_scroll_up:    () => execAsync("playerctl next").catch(() => {}),
        on_scroll_down: () => execAsync("playerctl previous").catch(() => {}),
        tooltip_text:   "Click: Play/Pause  Scroll: Next/Prev",
    });
};

// ═══════════════════════════════════════════════════════════════════════════════
// 🔊 VOLUME
// ═══════════════════════════════════════════════════════════════════════════════

const Volume = () => {
    const getIcon = (volume, muted) => {
        if (muted || volume === 0) return "󰝟";
        if (volume < 33) return "󰕿";
        if (volume < 66) return "󰖀";
        return "󰕾";
    };

    return Widget.Button({
        class_name: "volume",
        child: Widget.Box({
            children: [
                Widget.Label({
                    label: Audio.bind("speaker").as(s => {
                        if (!s) return "󰝟";
                        const vol  = Math.round((s.volume ?? 0) * 100);
                        const mute = s.is_muted ?? false;
                        return `${getIcon(vol, mute)} ${mute ? "Muted" : vol + "%"}`;
                    }),
                }),
            ],
        }),
        on_clicked:       () => execAsync("~/.config/hypr/scripts/media/volume.sh mute"),
        on_scroll_up:     () => execAsync("~/.config/hypr/scripts/media/volume.sh up 5"),
        on_scroll_down:   () => execAsync("~/.config/hypr/scripts/media/volume.sh down 5"),
        on_secondary_click: () => execAsync("pavucontrol"),
        tooltip_text: Audio.bind("speaker").as(s => {
            const vol = Math.round(((s?.volume) ?? 0) * 100);
            return `Volume: ${vol}%\nRight-click: Mixer`;
        }),
    });
};

// ═══════════════════════════════════════════════════════════════════════════════
// 🌐 NETWORK
// ═══════════════════════════════════════════════════════════════════════════════

const NetworkWidget = () => Widget.Button({
    class_name: "network",
    child: Widget.Label({
        label: Network.bind("wifi").as(wifi => {
            if (!wifi || !wifi.enabled) return "󰖪";
            if (!wifi.internet) return "󰤭";
            const s = wifi.strength ?? 0;
            if (s >= 75) return `󰤨 ${wifi.ssid ?? ""}`;
            if (s >= 50) return `󰤥 ${wifi.ssid ?? ""}`;
            if (s >= 25) return `󰤢 ${wifi.ssid ?? ""}`;
            return `󰤟 ${wifi.ssid ?? ""}`;
        }),
    }),
    on_clicked:       () => execAsync("~/.config/hypr/scripts/network/wifi-toggle.sh toggle"),
    on_secondary_click: () => execAsync("nm-connection-editor"),
    tooltip_text: Network.bind("wifi").as(w =>
        `WiFi: ${w?.ssid ?? "N/A"}\nStrength: ${w?.strength ?? 0}%\nRight-click: Settings`
    ),
});

// ═══════════════════════════════════════════════════════════════════════════════
// 🔵 BLUETOOTH
// ═══════════════════════════════════════════════════════════════════════════════

const BluetoothWidget = () => Widget.Button({
    class_name: "bluetooth",
    child: Widget.Label({
        label: Bluetooth.bind("enabled").as(enabled => {
            if (!enabled) return "󰂲";
            const connected = Bluetooth.connected_devices?.[0];
            if (connected) return `󰂱 ${connected.alias?.slice(0, 12) ?? ""}`;
            return "󰂯";
        }),
    }),
    on_clicked:       () => execAsync("~/.config/hypr/scripts/network/bluetooth-toggle.sh toggle"),
    on_secondary_click: () => execAsync("blueman-manager"),
    tooltip_text: "Bluetooth — Right-click: Manager",
});

// ═══════════════════════════════════════════════════════════════════════════════
// 🔋 BATTERY
// ═══════════════════════════════════════════════════════════════════════════════

const BatteryWidget = () => {
    const ICONS = ["󰂎","󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"];

    return Widget.Button({
        class_name: Battery.bind("percent").as(p =>
            `battery ${p <= 15 ? "critical" : p <= 30 ? "warning" : "normal"}`
        ),
        visible: Battery.bind("available"),
        child: Widget.Label({
            label: Battery.bind("percent").as(p => {
                const charging = Battery.charging;
                if (charging) return `󰂄 ${p}%`;
                if (p === 100) return `󰁹 ${p}%`;
                const icon = ICONS[Math.floor(p / 10)] ?? ICONS[0];
                return `${icon} ${p}%`;
            }),
        }),
        tooltip_text: Battery.bind("percent").as(p =>
            `Battery: ${p}%\nStatus: ${Battery.charging ? "Charging" : "Discharging"}`
        ),
    });
};

// ═══════════════════════════════════════════════════════════════════════════════
// 📥 SYSTEM TRAY
// ═══════════════════════════════════════════════════════════════════════════════

const Tray = () => Widget.Box({
    class_name: "tray",
    children: SystemTray.bind("items").as(items =>
        items.map(item => Widget.Button({
            class_name: "tray-item",
            child:       Widget.Icon({ icon: item.bind("icon") }),
            tooltip_markup: item.bind("tooltip_markup"),
            on_clicked:  () => item.activate(0, 0),
            on_secondary_click: (_, e) => item.openMenu(e),
        }))
    ),
});

// ═══════════════════════════════════════════════════════════════════════════════
// 🔔 NOTIFICATIONS
// ═══════════════════════════════════════════════════════════════════════════════

const NotificationIcon = () => {
    const count = Variable(Notifications.notifications.length);

    Notifications.connect("changed", () => {
        count.setValue(Notifications.notifications.length);
    });

    return Widget.Button({
        class_name: count.bind().as(c => `notification-icon ${c > 0 ? "has-notifs" : ""}`),
        child: Widget.Label({
            label: count.bind().as(c => c > 0 ? `󱅫 ${c}` : "󰂚"),
        }),
        on_clicked: () => execAsync("swaync-client -t").catch(() => {}),
        tooltip_text: count.bind().as(c =>
            c > 0 ? `${c} notification${c > 1 ? "s" : ""}` : "No notifications"
        ),
    });
};

// ═══════════════════════════════════════════════════════════════════════════════
// ⏻ POWER BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

const PowerButton = () => Widget.Button({
    class_name: "power-btn",
    child:       Widget.Label({ label: "⏻" }),
    on_clicked:  () => execAsync("~/.config/rofi/scripts/powermenu.sh"),
    on_secondary_click: () => execAsync("~/.config/hypr/scripts/system/lock.sh"),
    tooltip_text: "Click: Power Menu  Right: Lock",
});

// ═══════════════════════════════════════════════════════════════════════════════
// 📊 BAR LAYOUT
// ═══════════════════════════════════════════════════════════════════════════════

const Left  = (monitorId) => Widget.Box({
    class_name: "bar-left",
    spacing:    8,
    children:   [
        Launcher(),
        Workspaces(monitorId),
        Widget.Separator({ class_name: "separator" }),
        WindowTitle(),
    ],
});

const Center = () => Widget.Box({
    class_name: "bar-center",
    children:   [ Clock() ],
});

const Right  = () => Widget.Box({
    class_name: "bar-right",
    spacing:    8,
    children:   [
        MediaPlayer(),
        Widget.Separator({ class_name: "separator" }),
        NetworkWidget(),
        BluetoothWidget(),
        Widget.Separator({ class_name: "separator" }),
        Volume(),
        Widget.Separator({ class_name: "separator" }),
        BatteryWidget(),
        Widget.Separator({ class_name: "separator" }),
        Tray(),
        NotificationIcon(),
        PowerButton(),
    ],
});

// ═══════════════════════════════════════════════════════════════════════════════
// 🏠 BAR WINDOW
// ═══════════════════════════════════════════════════════════════════════════════

const Bar = (monitorId, monitorName) => Widget.Window({
    name:    `bar-${monitorId}`,
    class_name: "bar",
    monitor: monitorId,
    anchor:  ["top", "left", "right"],
    exclusivity: "exclusive",
    layer:   "top",
    margins: [6, 12, 0, 12],
    child:   Widget.CenterBox({
        class_name: "bar-container",
        start_widget: Left(monitorId),
        center_widget: Center(),
        end_widget:    Right(),
    }),
});

export default Bar;