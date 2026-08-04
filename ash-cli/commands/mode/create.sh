#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — MODE CREATE                                      ║
# ║  /ash-cli/commands/mode/create.sh                                            ║
# ║                                                                              ║
# ║  Interactive custom mode creator:                                            ║
# ║  • Template-based with full validation                                       ║
# ║  • Interactive questionnaire for non-expert users                            ║
# ║  • Generates init.sh, config.json, README.md                                 ║
# ║  • Validates name, conflicts, schema                                         ║
# ║  • Optionally inherits from existing mode                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

__create_name=""
__create_inherit=""
__create_interactive=true
__create_description=""
__create_icon=""

__create_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --name|-n)
                __create_name="${2:?--name requires a value}"
                shift 2
                ;;
            --inherit|-i)
                __create_inherit="${2:?--inherit requires a base mode name}"
                shift 2
                ;;
            --description|-d)
                __create_description="${2:?}"
                shift 2
                ;;
            --icon)
                __create_icon="${2:?}"
                shift 2
                ;;
            --no-interactive)   __create_interactive=false  ; shift ;;
            --dry-run)          ASH_DRY_RUN=true            ; shift ;;
            --verbose)          ASH_VERBOSE=true            ; shift ;;
            *)                  shift ;;
        esac
    done
}

# Interactive name prompt with validation
__create_prompt_name() {
    while true; do
        printf "  ${COLOR_ASH_PRIMARY}${MODE_COLOR_BOLD}Mode name${MODE_COLOR_RESET} "
        printf "${COLOR_ASH_MUTED}(letters, digits, hyphens only)${MODE_COLOR_RESET}: "
        read -r __create_name

        # Validate
        if [[ ! "${__create_name}" =~ ^[a-z][a-z0-9-]{2,29}$ ]]; then
            printf "  ${COLOR_ASH_ERROR}✗${MODE_COLOR_RESET} "
            printf "Name must be 3–30 chars, lowercase, no spaces.\n"
            continue
        fi

        # Check conflicts with built-in modes
        local m
        for m in "${ASH_BUILTIN_MODES[@]}"; do
            if [[ "${m}" == "${__create_name}" ]]; then
                printf "  ${COLOR_ASH_ERROR}✗${MODE_COLOR_RESET} "
                printf "'%s' conflicts with a built-in mode.\n" "${__create_name}"
                __create_name=""
                break
            fi
        done

        # Check conflicts with existing custom modes
        if [[ -d "${ASH_MODE_CUSTOM_DIR}/${__create_name}" ]]; then
            printf "  ${COLOR_ASH_WARNING}⚠${MODE_COLOR_RESET} "
            printf "Custom mode '%s' already exists. Overwrite? [y/N] " "${__create_name}"
            read -r confirm
            [[ "${confirm,,}" == "y" ]] && break
            __create_name=""
            continue
        fi

        [[ -n "${__create_name}" ]] && break
    done
}

# Interactive description prompt
__create_prompt_description() {
    printf "  ${COLOR_ASH_PRIMARY}${MODE_COLOR_BOLD}Description${MODE_COLOR_RESET} "
    printf "${COLOR_ASH_MUTED}(one line)${MODE_COLOR_RESET}: "
    read -r __create_description
    __create_description="${__create_description:-Custom ASH mode}"
}

# Interactive icon prompt
__create_prompt_icon() {
    printf "  ${COLOR_ASH_PRIMARY}${MODE_COLOR_BOLD}Icon${MODE_COLOR_RESET} "
    printf "${COLOR_ASH_MUTED}(Nerd Font glyph or emoji, Enter to skip)${MODE_COLOR_RESET}: "
    read -r __create_icon
    __create_icon="${__create_icon:- }"
}

# Generate the custom mode files
__create_generate_mode() {
    local mode_dir="${ASH_MODE_CUSTOM_DIR}/${__create_name}"

    if [[ "${ASH_DRY_RUN}" == "true" ]]; then
        printf "\n  ${COLOR_ASH_WARNING}${MODE_COLOR_BOLD}[DRY RUN]${MODE_COLOR_RESET} "
        printf "Would create mode at: ${COLOR_ASH_INFO}%s${MODE_COLOR_RESET}\n\n" \
            "${mode_dir}"
        return 0
    fi

    mkdir -p "${mode_dir}"

    # ── Generate init.sh ────────────────────────────────────────────────────
    # Determine base settings source
    local inherit_settings=""
    if [[ -n "${__create_inherit}" ]] && \
       [[ -f "${__ASH_MODE_DIR}/${__create_inherit}.sh" ]]; then
        inherit_settings="# Inheriting from: ${__create_inherit}"
    fi

    cat > "${mode_dir}/init.sh" <<-EOF
	#!/usr/bin/env bash
	# ═══════════════════════════════════════════════════════════
	# ASH Custom Mode: ${__create_name}
	# Created: $(date -u +%Y-%m-%d)
	# Description: ${__create_description}
	# ═══════════════════════════════════════════════════════════
	# ${inherit_settings}
	#
	# EDIT THIS FILE to customize your mode settings.
	# See docs/guides/theming-deep-dive.md for all available keys.

	set -euo pipefail

	__${__create_name//-/_}_build_settings() {
	    declare -gA __CUSTOM_SETTINGS=(
	        # ── Hyprland Compositor ──────────────────────────────────────
	        [hypr_animations]="true"
	        [hypr_blur]="true"
	        [hypr_shadow]="true"
	        [hypr_rounding]="12"
	        [hypr_gaps_in]="5"
	        [hypr_gaps_out]="10"
	        [hypr_border_size]="2"
	        [hypr_vfr]="true"

	        # ── Power ────────────────────────────────────────────────────
	        [cpu_governor]="schedutil"
	        [power_profile]="balanced"

	        # ── Display ──────────────────────────────────────────────────
	        [screen_brightness]="80"
	        [idle_timeout]="300"

	        # ── Notifications ─────────────────────────────────────────────
	        [do_not_disturb]="false"

	        # ── Audio ─────────────────────────────────────────────────────
	        [audio_volume]="50"

	        # ── Bar ───────────────────────────────────────────────────────
	        [waybar_visible]="true"
	        [waybar_layout]="top-bar"

	        # ── Metadata ──────────────────────────────────────────────────
	        [no_notify]="false"
	        [duration]="null"
	        [description]="${__create_description}"
	    )
	}

	ash_custom_mode_main() {
	    __${__create_name//-/_}_build_settings
	    ash_mode_activate "${__create_name}" "__CUSTOM_SETTINGS"
	}

	ash_custom_mode_main "\$@"
	EOF
    chmod +x "${mode_dir}/init.sh"

    # ── Generate config.json ────────────────────────────────────────────────
    cat > "${mode_dir}/config.json" <<-EOF
	{
	  "name": "${__create_name}",
	  "version": "1.0.0",
	  "description": "${__create_description}",
	  "icon": "${__create_icon}",
	  "author": "${USER}",
	  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
	  "inherits": "${__create_inherit:-null}",
	  "tags": ["custom"],
	  "compatibility": {
	    "ash_version": ">=5.0.0",
	    "compositor": ["hyprland"]
	  }
	}
	EOF

    # ── Generate README.md ─────────────────────────────────────────────────
    cat > "${mode_dir}/README.md" <<-EOF
	# ${__create_icon} ${__create_name^} Mode

	> ${__create_description}

	## Usage

	\`\`\`bash
	ash mode ${__create_name}
	ash mode ${__create_name} --duration 2h
	\`\`\`

	## Customization

	Edit \`init.sh\` to configure mode settings.
	See the [ASH documentation](https://ash-dotfiles.dev/guides/plugin-development.md)
	for all available configuration keys.

	## Settings Reference

	| Key | Default | Description |
	|-----|---------|-------------|
	| \`hypr_animations\` | true | Enable compositor animations |
	| \`hypr_blur\` | true | Enable background blur |
	| \`do_not_disturb\` | false | Silence notifications |
	| \`cpu_governor\` | schedutil | CPU frequency governor |

	---
	*Generated by ASH Mode Engine v${ASH_MODE_VERSION}*
	EOF

    # Success
    printf "\n"
    printf "  ${COLOR_ASH_SUCCESS}${MODE_COLOR_BOLD}✓${MODE_COLOR_RESET} "
    printf "Mode ${COLOR_ASH_PRIMARY}${MODE_COLOR_BOLD}%s${MODE_COLOR_RESET} created!\n" \
        "${__create_name}"
    printf "\n"
    printf "  ${COLOR_ASH_MUTED}Location:${MODE_COLOR_RESET} %s\n" "${mode_dir}"
    printf "  ${COLOR_ASH_MUTED}Edit:${MODE_COLOR_RESET}     ${COLOR_ASH_INFO}%s/init.sh${MODE_COLOR_RESET}\n" \
        "${mode_dir}"
    printf "  ${COLOR_ASH_MUTED}Activate:${MODE_COLOR_RESET} ${COLOR_ASH_INFO}ash mode %s${MODE_COLOR_RESET}\n\n" \
        "${__create_name}"
}

ash_create_mode_main() {
    __create_parse_args "$@"

    # ── Interactive prompts if name not provided ──────────────────────────────
    if [[ -z "${__create_name}" ]] && [[ "${__create_interactive}" == "true" ]]; then
        printf "\n"
        printf "${COLOR_ASH_PRIMARY}${MODE_COLOR_BOLD}  ✦ ASH Custom Mode Creator${MODE_COLOR_RESET}\n\n"
        __create_prompt_name
        __create_prompt_description
        __create_prompt_icon
    elif [[ -z "${__create_name}" ]]; then
        ash_die "Mode name required. Use --name <name> or run without --no-interactive"
    fi

    __create_generate_mode
}

ash_create_mode_main "$@"