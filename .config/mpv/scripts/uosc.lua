-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — UOSC LOADER                                  ║
-- ║           Modern MPV UI — install full version from GitHub                 ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

--[[
    uosc.lua — Modern UI overlay for MPV

    INSTALLATION:
    The full uosc script must be downloaded separately:

        # Using MPV script installer
        git clone https://github.com/tomasklaen/uosc.git /tmp/uosc
        cp /tmp/uosc/src/uosc.lua ~/.config/mpv/scripts/
        cp /tmp/uosc/src/uosc_shared /tmp/uosc/src/uosc_shared ~/.config/mpv/scripts/

    Or via package manager (if available):
        paru -S mpv-uosc

    CONFIGURATION:
    See ~/.config/mpv/script-opts/uosc.conf for settings.

    This stub file logs a message until the real uosc is installed.
--]]

local msg = require("mp.msg")

-- Check if real uosc is loaded
local function check_uosc()
    msg.info("[uosc] Configuration file loaded: ~/.config/mpv/scripts/uosc.lua")
    msg.info("[uosc] For the full UI, install uosc from:")
    msg.info("[uosc] https://github.com/tomasklaen/uosc")
    msg.info("[uosc] or: paru -S mpv-uosc")
end

-- Only show message if this is the stub
mp.register_event("file-loaded", function()
    msg.debug("[uosc stub] File loaded — full uosc UI not installed")
end)

check_uosc()