// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║           ASH DOTFILES v3.0 — AGS OVERVIEW MODULE                          ║
// ║           Workspace overview with window previews                          ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import Widget   from "resource:///com/github/Aylur/ags/widget.js";
import App      from "resource:///com/github/Aylur/ags/app.js";
import Hyprland from "resource:///com/github/Aylur/ags/service/hyprland.js";
import { execAsync, exec } from "resource:///com/github/Aylur/ags/utils.js";
import Variable from "resource:///com/github/Aylur/ags/variable.js";

// ═══════════════════════════════════════════════════════════════════════════════
// 🗂️ WORKSPACE ITEM
// ═══════════════════════════════════════════════════════════════════════════════

const WorkspaceItem = (workspace_id) => {
    const is_active = Variable(Hyprland.active.workspace.id === workspace_id);
    const windows   = Variable([]);

    const update = () => {
        is_active.setValue(Hyprland.active.workspace.id === workspace_id);
        windows.setValue(
            Hyprland.clients.filter(c => c.workspace.id === workspace_id)
        );
    };

    Hyprland.connect("changed", update);
    update();

    // Window preview item
    const WindowPreview = (client) => Widget.Button({
        class_name: "overview-window",
        tooltip_text: `${client.class}: ${client.title}`,
        on_clicked: () => {
            Hyprland.messageAsync(
                `dispatch focuswindow address:${client.address}`
            ).catch(() => {});
            App.closeWindow("overview");
        },
        child: Widget.Box({
            class_name: "overview-window-content",
            vertical:   true,
            children: [
                Widget.Icon({
                    class_name: "overview-window-icon",
                    icon:        client.class?.toLowerCase() || "application-x-executable",
                    size:        32,
                }),
                Widget.Label({
                    class_name:  "overview-window-title",
                    label:        client.title?.slice(0, 20) || client.class || "Window",
                    truncate:     "end",
                    max_width_chars: 12,
                }),
            ],
        }),
    });

    return Widget.Button({
        class_name: is_active.bind().as(a =>
            `overview-workspace ${a ? "active" : ""}`
        ),
        on_clicked: () => {
            Hyprland.messageAsync(`dispatch workspace ${workspace_id}`).catch(() => {});
            App.closeWindow("overview");
        },
        child: Widget.Box({
            class_name: "overview-workspace-content",
            vertical:   true,
            spacing:    4,
            children: [
                Widget.Label({
                    class_name: "overview-workspace-label",
                    label:      `${workspace_id}`,
                }),
                Widget.Box({
                    class_name: "overview-windows",
                    spacing:    4,
                    wrap:       true,
                    children:   windows.bind().as(wins =>
                        wins.map(WindowPreview)
                    ),
                }),
            ],
        }),
    });
};

// ═══════════════════════════════════════════════════════════════════════════════
// 📐 OVERVIEW GRID
// ═══════════════════════════════════════════════════════════════════════════════

const OverviewGrid = () => Widget.Box({
    class_name: "overview-grid",
    spacing:    12,
    children:   Array.from({ length: 10 }, (_, i) =>
        WorkspaceItem(i + 1)
    ),
});

// ═══════════════════════════════════════════════════════════════════════════════
// 🔍 SEARCH BAR
// ═══════════════════════════════════════════════════════════════════════════════

const SearchBar = () => {
    const query = Variable("");

    const entry = Widget.Entry({
        class_name:  "overview-search",
        placeholder_text: "Search windows...",
        on_change:   ({ text }) => query.setValue(text || ""),
        on_accept:   () => {
            // Launch app if no match
            execAsync(["bash", "-c",
                `hyprctl dispatch exec $(echo '${query.value}' | rofi -dmenu)`
            ]).catch(() => {});
            App.closeWindow("overview");
        },
    });

    return Widget.Box({
        class_name: "overview-search-container",
        children: [
            Widget.Icon({ icon: "system-search-symbolic", size: 16 }),
            entry,
        ],
    });
};

// ═══════════════════════════════════════════════════════════════════════════════
// 🪟 OVERVIEW WINDOW
// ═══════════════════════════════════════════════════════════════════════════════

const Overview = () => Widget.Window({
    name:       "overview",
    class_name: "overview-window",
    layer:      "overlay",
    anchor:     [],  // Centered
    visible:    false,
    keymode:    "on-demand",
    child: Widget.EventBox({
        on_secondary_click: () => App.closeWindow("overview"),
        child: Widget.Box({
            class_name: "overview-container",
            vertical:   true,
            spacing:    16,
            children: [
                Widget.Label({
                    class_name: "overview-title",
                    label:      "  Workspace Overview",
                }),
                SearchBar(),
                OverviewGrid(),
                Widget.Label({
                    class_name: "overview-hint",
                    label:      "Click workspace to switch  •  Right-click to close  •  ESC to dismiss",
                }),
            ],
        }),
    }),
    setup: (self) => {
        // Close on Escape
        self.keybind("Escape", () => App.closeWindow("overview"));
    },
});

export default Overview;