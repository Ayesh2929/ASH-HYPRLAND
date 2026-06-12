#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — ROFI EMOJI PICKER                            ║
# ║           Searchable emoji picker with clipboard copy                      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly EMOJI_DB="${CACHE_DIR}/emoji-db.txt"
readonly EMOJI_HISTORY="${CACHE_DIR}/emoji-history.txt"
readonly LOG_FILE="${CACHE_DIR}/logs/rofi.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 EMOJI DATABASE
# ═══════════════════════════════════════════════════════════════════════════════

build_emoji_db() {
    if [[ -f "${EMOJI_DB}" ]] && [[ -s "${EMOJI_DB}" ]]; then
        return 0
    fi

    mkdir -p "${CACHE_DIR}"

    # Build comprehensive emoji database
    cat > "${EMOJI_DB}" << 'EMOJIDB'
😀 grinning face happy smile
😁 beaming face with smiling eyes
😂 face with tears of joy laughing
🤣 rolling on the floor laughing
😃 grinning face with big eyes happy
😄 grinning face with smiling eyes happy
😅 grinning face with sweat nervous
😆 grinning squinting face laughing
😉 winking face
😊 smiling face with smiling eyes
😋 face savoring food yum delicious
😎 smiling face with sunglasses cool
😍 smiling face with heart-eyes love
🥰 smiling face with hearts love
😘 face blowing a kiss love
😗 kissing face
😙 kissing face with smiling eyes
😚 kissing face with closed eyes
🙂 slightly smiling face
🤗 hugging face hug
🤩 star-struck excited
🤔 thinking face ponder
🤨 face with raised eyebrow skeptical
😐 neutral face meh
😑 expressionless face
😶 face without mouth silent
🙄 face with rolling eyes annoyed
😏 smirking face smug
😒 unamused face
😞 disappointed face sad
😔 pensive face sad
😟 worried face
😕 confused face
🙁 slightly frowning face
☹️ frowning face sad
😣 persevering face
😖 confounded face
😫 tired face exhausted
😩 weary face
🥺 pleading face sad puppy eyes
😢 crying face sad tears
😭 loudly crying face sobbing
😤 face with steam from nose angry
😠 angry face mad
😡 pouting face red angry
🤬 face with symbols on mouth cursing
😈 smiling face with horns devil
👿 angry face with horns devil
💀 skull dead
☠️ skull and crossbones danger
💩 pile of poo
🤡 clown face
👹 ogre
👺 goblin
👻 ghost spooky halloween
👽 alien
👾 alien monster
🤖 robot
😺 grinning cat
❤️ red heart love
🧡 orange heart
💛 yellow heart
💚 green heart
💙 blue heart
💜 purple heart
🖤 black heart
🤍 white heart
🤎 brown heart
💔 broken heart
❣️ heart exclamation
💕 two hearts love
💞 revolving hearts
💓 beating heart
💗 growing heart
💖 sparkling heart
💘 heart with arrow
💝 heart with ribbon
💟 heart decoration
👍 thumbs up like approve
👎 thumbs down dislike
👋 waving hand hello goodbye
🤚 raised back of hand
🖐️ hand with fingers splayed
✋ raised hand stop
🖖 vulcan salute spock
👌 ok hand perfect
🤌 pinched fingers
🤏 pinching hand small
✌️ victory hand peace
🤞 crossed fingers luck
🤟 love you gesture
🤘 sign of the horns rock metal
🤙 call me hand
💪 flexed biceps strong
🦾 mechanical arm
🖕 middle finger
☝️ index pointing up
👆 backhand index pointing up
👇 backhand index pointing down
👈 backhand index pointing left
👉 backhand index pointing right
🙌 raising hands celebrate
👐 open hands
🤲 palms up together
🙏 folded hands pray please
✍️ writing hand
🎉 party popper celebrate
🎊 confetti ball party
🎈 balloon party
🎂 birthday cake
🍕 pizza
🍔 hamburger
🍟 french fries
🌮 taco
🌯 burrito
🍜 steaming bowl ramen noodles
🍣 sushi
🍱 bento box
🍙 rice ball
🍚 cooked rice
🍛 curry rice
🍝 spaghetti pasta
🍞 bread
🥐 croissant
🥨 pretzel
🥯 bagel
🧀 cheese wedge
🥚 egg
🍳 cooking breakfast
🥞 pancakes
🧇 waffle
🥓 bacon
🍗 poultry leg chicken
🍖 meat on bone
🌭 hot dog
🥪 sandwich
🥗 green salad
🍿 popcorn movie
🧂 salt
🧈 butter
🍦 soft ice cream
🍧 shaved ice
🍨 ice cream
🍩 doughnut donut
🍪 cookie
🎂 birthday cake
🍰 shortcake
🧁 cupcake
🥧 pie
🍫 chocolate bar
🍬 candy
🍭 lollipop
🍮 custard
🍯 honey pot
🍺 beer mug cheers
🍻 clinking beer mugs
🥂 clinking glasses toast
🍷 wine glass
🥃 tumbler glass whiskey
🍸 cocktail glass martini
🍹 tropical drink
🧋 bubble tea boba
☕ hot beverage coffee tea
🍵 teacup green tea
🧃 beverage box juice
🥤 cup with straw soda
💻 laptop computer
🖥️ desktop computer
🖨️ printer
⌨️ keyboard
🖱️ computer mouse
🖲️ trackball
💽 computer disk
💾 floppy disk save
💿 optical disk cd
📀 dvd
📱 mobile phone
☎️ telephone
📞 telephone receiver
📟 pager
📠 fax machine
📺 television tv
📻 radio
🎙️ studio microphone
🎚️ level slider
🎛️ control knobs
⏱️ stopwatch
⏲️ timer clock
⏰ alarm clock
🕰️ mantelpiece clock
🔋 battery
🔌 electric plug
💡 light bulb idea
🔦 flashlight
🕯️ candle
🧯 fire extinguisher
🛢️ oil drum
🔧 wrench tool
🪛 screwdriver
🔨 hammer
⚒️ hammer and pick
🛠️ hammer and wrench tools
⛏️ pick
🪚 carpentry saw
🔩 nut and bolt
🪤 mouse trap
🧲 magnet
🔫 pistol gun
🧨 firecracker
🪓 axe
🗡️ dagger
⚔️ crossed swords
🛡️ shield
📦 package box
EMOJIDB
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    mkdir -p "${CACHE_DIR}/logs"
    build_emoji_db

    # Build display list (emoji + name)
    local emoji_input=""

    # Add recent emojis first
    if [[ -f "${EMOJI_HISTORY}" ]]; then
        local recent
        recent=$(tail -10 "${EMOJI_HISTORY}" | sort -u)
        if [[ -n "${recent}" ]]; then
            while IFS= read -r emoji; do
                emoji_input+="⭐ ${emoji} (recent)\n"
            done <<< "${recent}"
        fi
    fi

    # Add all emojis
    while IFS= read -r line; do
        local emoji="${line%% *}"
        local name="${line#* }"
        emoji_input+="${emoji} ${name}\n"
    done < "${EMOJI_DB}"

    # Show picker
    local selected
    selected=$(echo -e "${emoji_input}" | rofi \
        -dmenu \
        -i \
        -p "😀 Emoji" \
        -theme-str '
            window { width: 550px; }
            listview { columns: 1; lines: 12; }
            element { padding: 6px 12px; font: "Noto Color Emoji 14"; }
        ' \
        2>/dev/null) || {
        log "INFO" "Emoji picker cancelled"
        exit 0
    }

    # Extract just the emoji character
    local emoji
    emoji=$(echo "${selected}" | awk '{print $1}' | tr -d '⭐')
    emoji=$(echo "${emoji}" | grep -oP '[^\x00-\x7F]+' | head -1 || echo "${selected%% *}")

    if [[ -n "${emoji}" ]]; then
        # Copy to clipboard
        echo -n "${emoji}" | wl-copy 2>/dev/null

        # Type emoji into focused window
        # wtype "${emoji}" 2>/dev/null || true

        # Save to history
        echo "${emoji}" >> "${EMOJI_HISTORY}"
        tail -50 "${EMOJI_HISTORY}" > "${EMOJI_HISTORY}.tmp" && \
            mv "${EMOJI_HISTORY}.tmp" "${EMOJI_HISTORY}" || true

        notify-send "😀 Emoji Copied" \
            "${emoji} copied to clipboard" \
            --app-name="ASH Emoji" \
            --expire-time=2000 \
            2>/dev/null || true

        log "INFO" "Emoji selected: ${emoji}"
    fi
}

main "$@"