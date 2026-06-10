// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║           ASH DOTFILES v3.0 — AGS AUDIO SERVICE                            ║
// ║           Extended audio service with OSD integration                      ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import Audio    from "resource:///com/github/Aylur/ags/service/audio.js";
import { execAsync } from "resource:///com/github/Aylur/ags/utils.js";
import Variable from "resource:///com/github/Aylur/ags/variable.js";

// ═══════════════════════════════════════════════════════════════════════════════
// 🔊 AUDIO HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

export const AudioHelpers = {

    // Get volume as 0-100 integer
    getVolume() {
        const speaker = Audio.speaker;
        if (!speaker) return 0;
        return Math.round((speaker.volume ?? 0) * 100);
    },

    // Get mute state
    isMuted() {
        return Audio.speaker?.is_muted ?? false;
    },

    // Set volume (0-150)
    async setVolume(pct) {
        const clamped = Math.max(0, Math.min(150, pct));
        return execAsync([
            "bash", "-c",
            `~/.config/hypr/scripts/media/volume.sh set ${clamped}`
        ]).catch(() => {});
    },

    // Volume up
    async volumeUp(amount = 5) {
        return execAsync([
            "bash", "-c",
            `~/.config/hypr/scripts/media/volume.sh up ${amount}`
        ]).catch(() => {});
    },

    // Volume down
    async volumeDown(amount = 5) {
        return execAsync([
            "bash", "-c",
            `~/.config/hypr/scripts/media/volume.sh down ${amount}`
        ]).catch(() => {});
    },

    // Toggle mute
    async toggleMute() {
        return execAsync([
            "bash", "-c",
            "~/.config/hypr/scripts/media/volume.sh mute"
        ]).catch(() => {});
    },

    // Get microphone volume
    getMicVolume() {
        const source = Audio.microphone;
        if (!source) return 0;
        return Math.round((source.volume ?? 0) * 100);
    },

    // Get microphone mute state
    isMicMuted() {
        return Audio.microphone?.is_muted ?? false;
    },

    // Toggle microphone mute
    async toggleMicMute() {
        return execAsync([
            "bash", "-c",
            "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ]).catch(() => {});
    },

    // Get all available sinks
    getSinks() {
        return Audio.speakers || [];
    },

    // Get all available sources
    getSources() {
        return Audio.microphones || [];
    },

    // Get current sink description
    getCurrentSinkDesc() {
        return Audio.speaker?.description || "No audio device";
    },

    // Open pavucontrol
    async openMixer() {
        return execAsync("pavucontrol").catch(() => {});
    },
};

// ── Volume change tracker for OSD ─────────────────────────────────────────────
let _last_volume = -1;
let _last_muted  = false;

Audio.connect("speaker-changed", () => {
    const vol   = AudioHelpers.getVolume();
    const muted = AudioHelpers.isMuted();

    if (vol !== _last_volume || muted !== _last_muted) {
        _last_volume = vol;
        _last_muted  = muted;

        // Trigger OSD via global function
        if (typeof globalThis.showOSD === "function") {
            globalThis.showOSD(muted ? "mute" : "volume", vol);
        }
    }
});

export default Audio;