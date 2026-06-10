// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║           ASH DOTFILES v3.0 — AGS HYPRLAND SERVICE                         ║
// ║           Extended Hyprland service with helper methods                    ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import Hyprland from "resource:///com/github/Aylur/ags/service/hyprland.js";
import { exec, execAsync } from "resource:///com/github/Aylur/ags/utils.js";

// ═══════════════════════════════════════════════════════════════════════════════
// 🔧 HYPRLAND HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

export const HyprlandHelpers = {

    // Get active monitor info
    getActiveMonitor() {
        return Hyprland.monitors.find(m => m.focused) || Hyprland.monitors[0];
    },

    // Get all clients on a workspace
    getClientsOnWorkspace(ws_id) {
        return Hyprland.clients.filter(c => c.workspace.id === ws_id);
    },

    // Get workspace client count
    getWorkspaceClientCount(ws_id) {
        return this.getClientsOnWorkspace(ws_id).length;
    },

    // Check if workspace is occupied
    isWorkspaceOccupied(ws_id) {
        return this.getWorkspaceClientCount(ws_id) > 0;
    },

    // Focus window by address
    async focusWindow(address) {
        return Hyprland.messageAsync(`dispatch focuswindow address:${address}`);
    },

    // Move window to workspace
    async moveWindowToWorkspace(address, ws_id) {
        return Hyprland.messageAsync(
            `dispatch movetoworkspace ${ws_id},address:${address}`
        );
    },

    // Switch to workspace
    async switchWorkspace(ws_id) {
        return Hyprland.messageAsync(`dispatch workspace ${ws_id}`);
    },

    // Toggle floating for active window
    async toggleFloat() {
        return Hyprland.messageAsync("dispatch togglefloating");
    },

    // Close active window
    async closeWindow() {
        return Hyprland.messageAsync("dispatch killactive");
    },

    // Get workspace list with client info
    getWorkspaceList() {
        return Array.from({ length: 10 }, (_, i) => ({
            id:      i + 1,
            active:  Hyprland.active.workspace.id === (i + 1),
            clients: this.getClientsOnWorkspace(i + 1),
        }));
    },

    // Dispatch any command
    async dispatch(cmd, ...args) {
        const full_cmd = args.length > 0
            ? `dispatch ${cmd} ${args.join(" ")}`
            : `dispatch ${cmd}`;
        return Hyprland.messageAsync(full_cmd);
    },

    // Get keyword value
    async getKeyword(keyword) {
        return Hyprland.messageAsync(`getoption ${keyword}`);
    },

    // Set keyword value
    async setKeyword(keyword, value) {
        return Hyprland.messageAsync(`keyword ${keyword} ${value}`);
    },

    // Reload config
    async reload() {
        return Hyprland.messageAsync("reload");
    },
};

export default Hyprland;