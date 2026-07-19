# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Fish Abbreviations: ASH CLI                        ║
# ║  Ultra-optimized ASH command abbreviations with intelligent expansion       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_abbr_loaded && exit 0
set --global _ash_abbr_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 THEME COMMANDS                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Core theme operations
abbr --add at      'ash theme'
abbr --add ata     'ash theme apply'
abbr --add atp     'ash theme pick'
abbr --add atr     'ash theme random'
abbr --add atl     'ash theme list'
abbr --add ats     'ash theme search'
abbr --add atc     'ash theme create'
abbr --add ate     'ash theme edit'
abbr --add atcl    'ash theme clone'
abbr --add atex    'ash theme export'
abbr --add atim    'ash theme import'
abbr --add atpv    'ash theme preview'
abbr --add atd     'ash theme delete'
abbr --add atrst   'ash theme reset'
abbr --add atsch   'ash theme schedule'
abbr --add atv     'ash theme validate'
abbr --add atb     'ash theme benchmark'
abbr --add ath     'ash theme history'
abbr --add atfav   'ash theme favorite'
abbr --add atsync  'ash theme sync'

# AI-powered theme commands
abbr --add atai    'ash theme ai-generate'
abbr --add atam    'ash theme ai-mood'
abbr --add ataw    'ash theme ai-weather'
abbr --add atat    'ash theme ai-time'

# Theme store
abbr --add atsb    'ash theme store-browse'
abbr --add atsd    'ash theme store-download'
abbr --add atsu    'ash theme store-upload'

# Theme color operations
abbr --add atcol   'ash theme colors'
abbr --add atwall  'ash theme wallpaper'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎭 MODE COMMANDS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add am      'ash mode'
abbr --add amg     'ash mode game'
abbr --add amw     'ash mode work'
abbr --add amf     'ash mode focus'
abbr --add amc     'ash mode cinema'
abbr --add amp     'ash mode present'
abbr --add amb     'ash mode battery'
abbr --add ams     'ash mode stream'
abbr --add ampr    'ash mode privacy'
abbr --add ama     'ash mode accessibility'
abbr --add amd     'ash mode default'
abbr --add amcr    'ash mode create'
abbr --add aml     'ash mode list'
abbr --add amst    'ash mode status'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔌 PLUGIN COMMANDS                                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add ap      'ash plugin'
abbr --add api     'ash plugin install'
abbr --add apr     'ash plugin remove'
abbr --add apu     'ash plugin update'
abbr --add apua    'ash plugin update-all'
abbr --add apl     'ash plugin list'
abbr --add apb     'ash plugin browse'
abbr --add aps     'ash plugin search'
abbr --add apc     'ash plugin create'
abbr --add ape     'ash plugin enable'
abbr --add apd     'ash plugin disable'
abbr --add apinf   'ash plugin info'
abbr --add apv     'ash plugin validate'
abbr --add appu    'ash plugin publish'
abbr --add apbk    'ash plugin backup'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📸 SNAPSHOT COMMANDS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add asn     'ash snapshot'
abbr --add asnc    'ash snapshot create'
abbr --add asnr    'ash snapshot restore'
abbr --add asnl    'ash snapshot list'
abbr --add asnd    'ash snapshot delete'
abbr --add asndf   'ash snapshot diff'
abbr --add asnex   'ash snapshot export'
abbr --add asnim   'ash snapshot import'
abbr --add asna    'ash snapshot auto'
abbr --add asnk    'ash snapshot clean'
abbr --add asnp    'ash snapshot pin'
abbr --add asnt    'ash snapshot tag'
abbr --add asnh    'ash snapshot history'
abbr --add asnv    'ash snapshot verify'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  CONFIG COMMANDS                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add acf     'ash config'
abbr --add acfg    'ash config get'
abbr --add acfs    'ash config set'
abbr --add acfu    'ash config unset'
abbr --add acfl    'ash config list'
abbr --add acfr    'ash config reset'
abbr --add acfex   'ash config export'
abbr --add acfim   'ash config import'
abbr --add acfe    'ash config edit'
abbr --add acfv    'ash config validate'
abbr --add acfm    'ash config migrate'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🏥 DOCTOR COMMANDS                                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add adr     'ash doctor'
abbr --add adrq    'ash doctor quick'
abbr --add adrf    'ash doctor full'
abbr --add adrfx   'ash doctor fix'
abbr --add adrrp   'ash doctor report'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  💻 HARDWARE COMMANDS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add ahw     'ash hw'
abbr --add ahwr    'ash hw full-report'
abbr --add ahwc    'ash hw cpu'
abbr --add ahwg    'ash hw gpu'
abbr --add ahwm    'ash hw memory'
abbr --add ahwd    'ash hw disk'
abbr --add ahwmo   'ash hw monitor'
abbr --add ahwb    'ash hw battery'
abbr --add ahwu    'ash hw usb'
abbr --add ahwbt   'ash hw bluetooth'
abbr --add ahwa    'ash hw audio'
abbr --add ahwn    'ash hw network'
abbr --add ahwp    'ash hw pci'
abbr --add ahws    'ash hw sensors'
abbr --add ahwbk   'ash hw benchmark'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🌐 NETWORK COMMANDS                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add an      'ash net'
abbr --add anst    'ash net status'
abbr --add ansp    'ash net speed'
abbr --add anw     'ash net wifi'
abbr --add anws    'ash net wifi-scan'
abbr --add anwc    'ash net wifi-connect'
abbr --add anwh    'ash net wifi-hotspot'
abbr --add anv     'ash net vpn'
abbr --add and     'ash net dns'
abbr --add anf     'ash net firewall'
abbr --add anp     'ash net ports'
abbr --add anm     'ash net monitor'
abbr --add anpr    'ash net proxy'
abbr --add antor   'ash net tor'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔄 UPDATE COMMANDS                                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add aup     'ash update'
abbr --add aups    'ash update system'
abbr --add aupd    'ash update dotfiles'
abbr --add aupp    'ash update plugins'
abbr --add aupt    'ash update themes'
abbr --add aupn    'ash update nvim'
abbr --add aupf    'ash update fish'
abbr --add aupfp   'ash update flatpak'
abbr --add aupa    'ash update all'
abbr --add aupc    'ash update check'
abbr --add aupr    'ash update rollback'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📷 SCREENSHOT COMMANDS                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add ash     'ash shot'
abbr --add ashf    'ash shot full'
abbr --add asha    'ash shot area'
abbr --add ashw    'ash shot window'
abbr --add ashm    'ash shot monitor'
abbr --add asho    'ash shot ocr'
abbr --add ashc    'ash shot color'
abbr --add ashr    'ash shot record'
abbr --add ashg    'ash shot gif'
abbr --add ashn    'ash shot annotate'
abbr --add asht    'ash shot timer'
abbr --add ashu    'ash shot upload'
abbr --add ashh    'ash shot history'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🖼️  WALLPAPER COMMANDS                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add aw      'ash wallpaper'
abbr --add aws     'ash wallpaper set'
abbr --add awr     'ash wallpaper random'
abbr --add awp     'ash wallpaper pick'
abbr --add awd     'ash wallpaper download'
abbr --add awg     'ash wallpaper generate'
abbr --add awga    'ash wallpaper generate-ai'
abbr --add awsl    'ash wallpaper slideshow'
abbr --add awb     'ash wallpaper blur'
abbr --add awi     'ash wallpaper info'
abbr --add awh     'ash wallpaper history'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📊 BAR COMMANDS                                                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add ab      'ash bar'
abbr --add abl     'ash bar layout'
abbr --add abt     'ash bar toggle'
abbr --add abr     'ash bar reload'
abbr --add abs     'ash bar switch'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ POWER COMMANDS                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add apw     'ash power'
abbr --add apwm    'ash power menu'
abbr --add apwl    'ash power lock'
abbr --add apws    'ash power suspend'
abbr --add apwh    'ash power hibernate'
abbr --add apwsd   'ash power shutdown'
abbr --add apwrb   'ash power reboot'
abbr --add apwlo   'ash power logout'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🖥️  MONITOR COMMANDS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add amn     'ash monitor'
abbr --add amnl    'ash monitor list'
abbr --add amnla   'ash monitor layout'
abbr --add amnm    'ash monitor mirror'
abbr --add amne    'ash monitor extend'
abbr --add amnr    'ash monitor resolution'
abbr --add amnrf   'ash monitor refresh-rate'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔊 AUDIO COMMANDS                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add aau     'ash audio'
abbr --add aauv    'ash audio volume'
abbr --add aaum    'ash audio mute'
abbr --add aaud    'ash audio device'
abbr --add aaue    'ash audio eq'
abbr --add aauvi   'ash audio visualizer'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📶 BLUETOOTH COMMANDS                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add abl     'ash bluetooth'
abbr --add abls    'ash bluetooth scan'
abbr --add ablc    'ash bluetooth connect'
abbr --add abld    'ash bluetooth disconnect'
abbr --add ablp    'ash bluetooth pair'
abbr --add abll    'ash bluetooth list'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🪟 WINDOW COMMANDS                                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add awi     'ash window'
abbr --add awil    'ash window list'
abbr --add awif    'ash window focus'
abbr --add awim    'ash window move'
abbr --add awir    'ash window resize'
abbr --add awic    'ash window close'
abbr --add awip    'ash window pin'
abbr --add awift   'ash window float'
abbr --add awifs   'ash window fullscreen'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🗂️  WORKSPACE COMMANDS                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add aws     'ash workspace'
abbr --add awsl    'ash workspace list'
abbr --add awss    'ash workspace switch'
abbr --add awsmw   'ash workspace move-window'
abbr --add awso    'ash workspace overview'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎮 GAMING COMMANDS                                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add agm     'ash gaming'
abbr --add agmo    'ash gaming optimize'
abbr --add agmm    'ash gaming mangohud'
abbr --add agmp    'ash gaming proton'
abbr --add agmg    'ash gaming gamemode'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  💾 BACKUP COMMANDS                                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add abk     'ash backup'
abbr --add abkc    'ash backup create'
abbr --add abkr    'ash backup restore'
abbr --add abkl    'ash backup list'
abbr --add abks    'ash backup schedule'
abbr --add abkv    'ash backup verify'
abbr --add abke    'ash backup encrypt'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📈 ANALYTICS COMMANDS                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add aan     'ash analytics'
abbr --add aandb   'ash analytics dashboard'
abbr --add aants   'ash analytics theme-stats'
abbr --add aancs   'ash analytics command-stats'
abbr --add aanps   'ash analytics performance-stats'
abbr --add aanex   'ash analytics export-report'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  👤 PROFILE COMMANDS                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add apr     'ash profile'
abbr --add aprc    'ash profile create'
abbr --add aprs    'ash profile switch'
abbr --add aprd    'ash profile delete'
abbr --add aprex   'ash profile export'
abbr --add aprim   'ash profile import'
abbr --add aprl    'ash profile list'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ☁️  CLOUD COMMANDS                                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add acl     'ash cloud'
abbr --add aclu    'ash cloud sync-up'
abbr --add acld    'ash cloud sync-down'
abbr --add aclst   'ash cloud status'
abbr --add aclcf   'ash cloud configure'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🏪 STORE COMMANDS                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add ast     'ash store'
abbr --add astb    'ash store browse'
abbr --add asts    'ash store search'
abbr --add astd    'ash store download'
abbr --add astu    'ash store upload'
abbr --add astr    'ash store rate'
abbr --add astt    'ash store trending'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  💬 SESSION COMMANDS                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add ase     'ash session'
abbr --add ases    'ash session save'
abbr --add aser    'ash session restore'
abbr --add asel    'ash session list'
abbr --add ased    'ash session delete'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🤖 AI COMMANDS                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add aai     'ash ai'
abbr --add aaic    'ash ai chat'
abbr --add aais    'ash ai suggest-theme'
abbr --add aaio    'ash ai optimize-config'
abbr --add aaif    'ash ai fix-issue'
abbr --add aaie    'ash ai explain'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📼 MACRO COMMANDS                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add amac    'ash macro'
abbr --add amacr   'ash macro record'
abbr --add amacp   'ash macro play'
abbr --add amace   'ash macro edit'
abbr --add amacl   'ash macro list'
abbr --add amacd   'ash macro delete'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🌍 REMOTE COMMANDS                                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add arm     'ash remote'
abbr --add armc    'ash remote connect'
abbr --add arms    'ash remote sync-config'
abbr --add arma    'ash remote apply-theme'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📊 BENCHMARK COMMANDS                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add abch    'ash benchmark'
abbr --add abchs   'ash benchmark startup'
abbr --add abcht   'ash benchmark theme-apply'
abbr --add abchm   'ash benchmark memory'
abbr --add abchr   'ash benchmark report'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔀 MIGRATE COMMANDS                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add amig    'ash migrate'
abbr --add amigh   'ash migrate from-hyde'
abbr --add amighd  'ash migrate from-hyprdots'
abbr --add amigm   'ash migrate from-ml4w'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 ULTRA-SHORTHAND COMBOS (Most-used workflows)                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Theme quick-picks by category
abbr --add atcat   'ash theme apply catppuccin-mocha'
abbr --add attky   'ash theme apply tokyo-night'
abbr --add atgrv   'ash theme apply gruvbox-dark'
abbr --add atnrd   'ash theme apply nord'
abbr --add atdrc   'ash theme apply dracula'
abbr --add atrsp   'ash theme apply rose-pine'
abbr --add atevf   'ash theme apply everforest-dark'
abbr --add atknw   'ash theme apply kanagawa-wave'
abbr --add atcyb   'ash theme apply cyberpunk-2077'
abbr --add atsyn   'ash theme apply synthwave-84'

# Quick mode combos
abbr --add agame   'ash mode game'
abbr --add awork   'ash mode work'
abbr --add afocus  'ash mode focus'
abbr --add areset  'ash mode default'

# One-shot system actions
abbr --add afix    'ash doctor fix'
abbr --add acheck  'ash doctor quick'
abbr --add areload 'ash bar reload && ash theme apply (cat ~/.local/share/ash/state/current-theme.json | jq -r .name)'
abbr --add astatus 'ash mode status && ash theme list --current'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔧 HELPER FUNCTION: Show all ASH abbreviations                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_abbr_help
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l yellow (set_color yellow)
    set -l green  (set_color green)
    set -l purple (set_color magenta)

    echo ""
    echo $bold$cyan"  ╔══════════════════════════════════════════════════╗"$reset
    echo $bold$cyan"  ║     🐟 ASH CLI Abbreviations Reference           ║"$reset
    echo $bold$cyan"  ╚══════════════════════════════════════════════════╝"$reset
    echo ""

    set -l sections \
        "🎨 Theme"       "at"   "ata atp atr atl ats atc ate atai atam" \
        "🎭 Mode"        "am"   "amg amw amf amc ampr ams amb amd" \
        "🔌 Plugin"      "ap"   "api apr apu apua apl apb aps apc ape apd" \
        "📸 Snapshot"    "asn"  "asnc asnr asnl asnd asndf asnex asnp asnt" \
        "⚙️ Config"      "acf"  "acfg acfs acfu acfl acfr acfe acfv acfm" \
        "🏥 Doctor"      "adr"  "adrq adrf adrfx adrrp" \
        "💻 Hardware"    "ahw"  "ahwr ahwc ahwg ahwm ahwd ahwb ahwa ahwn" \
        "🌐 Network"     "an"   "anst ansp anw anws anwc anv and anf anp" \
        "🔄 Update"      "aup"  "aups aupd aupp aupt aupn aupa aupc aupr" \
        "📷 Screenshot"  "ash"  "ashf asha ashw ashm asho ashc ashr ashg" \
        "🖼️ Wallpaper"   "aw"   "aws awr awp awd awg awga awsl awb" \
        "📊 Bar"         "ab"   "abl abt abr abs" \
        "⚡ Power"       "apw"  "apwl apws apwh apwsd apwrb apwlo" \
        "🎮 Gaming"      "agm"  "agmo agmm agmp agmg" \
        "💾 Backup"      "abk"  "abkc abkr abkl abks abkv abke" \
        "🤖 AI"          "aai"  "aaic aais aaio aaif aaie" \
        "☁️ Cloud"       "acl"  "aclu acld aclst aclcf" \
        "👤 Profile"     "apr"  "aprc aprs aprd aprex aprl"

    echo $bold$yellow"  Quick Combos:"$reset
    echo "  "$green"agame"$reset"   → ash mode game      | "$green"awork"$reset"   → ash mode work"
    echo "  "$green"afocus"$reset"  → ash mode focus     | "$green"areset"$reset"  → ash mode default"
    echo "  "$green"afix"$reset"    → ash doctor fix     | "$green"acheck"$reset"  → ash doctor quick"
    echo ""
    echo "  "$purple"Tip: Type any prefix + Tab to see completions"$reset
    echo ""
end

abbr --add aabbr '__ash_abbr_help'
abbr --add ahelp '__ash_abbr_help'