#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  🔍 ASH VALIDATOR ENGINE — Validation utilities for the ASH ecosystem          ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

readonly ASH_VALIDATOR_VERSION="5.0.0"

# Validation functions
ash_validate_string() {
    local string="${1}"
    local min_length="${2:-0}"
    local max_length="${3:-}"
    local pattern="${4:-}"

    if [[ -z "${string}" ]]; then
        echo "String cannot be empty"
        return 1
    fi

    if (( min_length > 0 )); then
        if (( ${#string} < min_length )); then
            echo "String must be at least ${min_length} characters long"
            return 1
        fi
    fi

    if (( max_length > 0 )); then
        if (( ${#string} > max_length )); then
            echo "String must not exceed ${max_length} characters"
            return 1
        fi
    fi

    if [[ -n "${pattern}" ]]; then
        if [[ ! "${string}" =~ ${pattern} ]]; then
            echo "String does not match pattern: ${pattern}"
            return 1
        fi
    fi

    return 0
}

ash_validate_number() {
    local number="${1}"
    local min="${2:-}"
    local max="${3:-}"
    local allow_decimal="${4:-false}"

    if ! [[ "${number}" =~ ^[0-9]+$ ]]; then
        if [[ "${allow_decimal}" == "true" ]] && [[ "${number}" =~ ^[0-9]*\.[0-9]+$ ]]; then
            :
        else
            echo "Number must be a positive integer"
            return 1
        fi
    fi

    if [[ -n "${min}" ]] && (( number < min )); then
        echo "Number must be at least ${min}"
        return 1
    fi

    if [[ -n "${max}" ]] && (( number > max )); then
        echo "Number must not exceed ${max}"
        return 1
    fi

    return 0
}

ash_validate_email() {
    local email="${1}"
    if [[ ! "${email}" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; then
        echo "Invalid email address"
        return 1
    fi
    return 0
}

ash_validate_url() {
    local url="${1}"
    if [[ ! "${url}" =~ ^(https?|ftp)://[^\s/$.?#].[^\s]*$ ]]; then
        echo "Invalid URL"
        return 1
    fi
    return 0
}

ash_validate_ip() {
    local ip="${1}"
    if [[ ! "${ip}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "Invalid IP address"
        return 1
    fi
    # Validate each octet
    local IFS='.'
    read -ra octets <<< "${ip}"
    for octet in "${octets[@]}"; do
        if (( octet < 0 || octet > 255 )); then
            echo "Invalid IP octet: ${octet}"
            return 1
        fi
    done
    return 0
}

ash_validate_path() {
    local path="${1}"
    if [[ ! -e "${path}" ]]; then
        echo "Path does not exist: ${path}"
        return 1
    fi
    return 0
}

ash_validate_file() {
    local path="${1}"
    if [[ ! -f "${path}" ]]; then
        echo "Not a file: ${path}"
        return 1
    fi
    return 0
}

ash_validate_directory() {
    local path="${1}"
    if [[ ! -d "${path}" ]]; then
        echo "Not a directory: ${path}"
        return 1
    fi
    return 0
}

ash_validate_executable() {
    local path="${1}"
    if [[ ! -x "${path}" ]]; then
        echo "Not executable: ${path}"
        return 1
    fi
    return 0
}

ash_validate_readable() {
    local path="${1}"
    if [[ ! -r "${path}" ]]; then
        echo "Not readable: ${path}"
        return 1
    fi
    return 0
}

ash_validate_writable() {
    local path="${1}"
    if [[ ! -w "${path}" ]]; then
        echo "Not writable: ${path}"
        return 1
    fi
    return 0
}

ash_validate_option() {
    local value="${1}"
    shift
    local valid_options=("$@")

    for option in "${valid_options[@]}"; do
        if [[ "${value}" == "${option}" ]]; then
            return 0
        fi
    done

    echo "Invalid option: ${value}. Valid options: ${valid_options[*]}"
    return 1
}

ash_validate_length() {
    local value="${1}"
    local min="${2:-}"
    local max="${3:-}"

    if [[ -n "${min}" ]] && (( ${#value} < min )); then
        echo "Value must be at least ${min} characters"
        return 1
    fi

    if [[ -n "${max}" ]] && (( ${#value} > max )); then
        echo "Value must not exceed ${max} characters"
        return 1
    fi

    return 0
}

ash_validate_format() {
    local value="${1}"
    local format="${2}"

    case "${format}" in
        timestamp|ts)
            if [[ ! "${value}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
                echo "Invalid timestamp format (expected YYYY-MM-DDTHH:MM:SSZ)"
                return 1
            fi
            ;;
        duration)
            if [[ ! "${value}" =~ ^[0-9]+[smhd]$ ]]; then
                echo "Invalid duration format (expected number + unit: s,m,h,d)"
                return 1
            fi
            ;;
        boolean)
            if [[ ! "${value}" =~ ^(true|false)$ ]]; then
                echo "Invalid boolean value (expected true or false)"
                return 1
            fi
            ;;
        *)
            echo "Unknown format: ${format}"
            return 1
            ;;
    esac

    return 0
}

ash_validate_range() {
    local value="${1}"
    local min="${2}"
    local max="${3}"

    if ! [[ "${value}" =~ ^[0-9]+$ ]]; then
        echo "Value must be a number"
        return 1
    fi

    if (( value < min )); then
        echo "Value must be at least ${min}"
        return 1
    fi

    if (( value > max )); then
        echo "Value must not exceed ${max}"
        return 1
    fi

    return 0
}

ash_validate_confirmation() {
    local prompt="${1:-Are you sure? [y/N]}"
    local default="${2:-no}"

    echo -n "${prompt} "
    read -r answer

    if [[ -z "${answer}" ]]; then
        answer="${default}"
    fi

    if [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]; then
        return 0
    else
        return 1
    fi
}

# Main entry point for validator library
ash_validator_main() {
    case "${1:-}" in
        init)
            echo "ASH Validator Engine v${ASH_VALIDATOR_VERSION} initialized"
            ;;
        status)
            echo "ASH Validator Engine v${ASH_VALIDATOR_VERSION}"
            echo "Validation functions: string, number, email, url, ip, path, file, directory, executable, readable, writable, option, length, format, range, confirmation"
            ;;
        *)
            echo "Usage: ash_validator <command>"
            echo "Commands: init, status"
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ash_validator_main "$@"
fi
