// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║           ASH DOTFILES v3.0 — AGS OSD MODULE                               ║
// ║           On-screen display for volume, brightness, and other indicators   ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import Widget   from "resource:///com/github/Aylur/ags/widget.js";
import Variable from "resource:///com/github/Aylur/ags/variable.js";
import Audio    from "resource:///com/github/Aylur/ags/service/audio.js";

// ═══════════════════════════════════════════════════════════════════════════════
// 📊 STATE
// ═══════════════════════════════════════════════════════════════════════════════

const OSD_TYPE    = Variable("volume");   // "volume" | "brightness" | "mute"
const OSD_VALUE   = Variable(0);          // 0-100
const OSD_VISIBLE = Variable(false);

let hideTimeout = null;

function showOSD(type, value) {
    if (hideTimeout) clearTimeout(hideTimeout);

    OSD_TYPE.setValue(type);
    OSD_VALUE.setValue(value);
    OSD_VISIBLE.setValue(true);

    hideTimeout = setTimeout(() => {
        OSD_VISIBLE.setValue(false);
    }, 1800);
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🔊 VOLUME MONITORING
// ═══════════════════════════════════════════════════════════════════════════════

let lastVolume = -1;
let lastMuted  = false;

Audio.connect("speaker-changed", () => {
    const speaker = Audio.speaker;
    if (!speaker) return;

    const volume = Math.round((speaker.volume ?? 0) * 100);
    const muted  = speaker.is_muted ?? false;

    if (volume !== lastVolume || muted !== lastMuted) {
        if (muted) {
            showOSD("mute", 0);
        } else {
            showOSD("volume", volume);
        }
        lastVolume = volume;
        lastMuted  = muted;
    }
});

// ═══════════════════════════════════════════════════════════════════════════════
// 🎨 OSD WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

const OSD_ICONS = {
    volume:    { 0: "󰝟", 33: "󰕿", 66: "󰖀", 100: "󰕾" },
    mute:      { 0: "󰝟" },
    brightness:{ 0: "󰃞", 33: "󰃟", 66: "󰃠", 100: "󰃠" },
};

function getIcon(type, value) {
    const icons = OSD_ICONS[type] ?? OSD_ICONS.volume;
    const thresholds = Object.keys(icons).map(Number).sort((a, b) => a - b);
    for (let i = thresholds.length - 1; i >= 0; i--) {
        if (value >= thresholds[i]) return icons[thresholds[i]];
    }
    return icons[0] ?? "?";
}

const ProgressBar = () => Widget.LevelBar({
    class_name: "osd-progress",
    value:      OSD_VALUE.bind().as(v => v / 100),
    min_value:  0,
    max_value:  1,
});

const OSDWidget = () => Widget.Box({
    class_name: OSD_TYPE.bind().as(t => `osd-container ${t}`),
    vertical:   true,
    spacing:    12,
    children: [
        Widget.Box({
            spacing: 12,
            children: [
                Widget.Label({
                    class_name: "osd-icon",
                    label:      OSD_TYPE.bind().as(t => {
                        const v = OSD_VALUE.value;
                        return getIcon(t, v);
                    }),
                }),
                Widget.Label({
                    class_name: "osd-value",
                    label:      OSD_VALUE.bind().as(v => {
                        const t = OSD_TYPE.value;
                        if (t === "mute") return "Muted";
                        return `${v}%`;
                    }),
                }),
            ],
        }),
        ProgressBar(),
    ],
});

// ═══════════════════════════════════════════════════════════════════════════════
// 🪟 OSD WINDOW
// ═══════════════════════════════════════════════════════════════════════════════

const OSD = () => Widget.Window({
    name:       "osd",
    class_name: "osd-window",
    layer:      "overlay",
    anchor:     ["bottom"],
    margins:    [0, 0, 80, 0],
    visible:    OSD_VISIBLE.bind(),
    child:      OSDWidget(),
});

// Export show function for external use
OSD.show = showOSD;

export default OSD;