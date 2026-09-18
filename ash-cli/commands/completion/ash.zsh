#compdef ash
# ASH completion for zsh — place in $fpath
_ash() {
    local -a completions
    local -a commands
    commands=(
        'theme:Manage themes'
        'mode:Switch desktop modes'
        'plugin:Manage plugins'
        'snapshot:Config snapshots'
        'config:Configuration'
        'doctor:Health checks'
        'help:Show help'
        'version:Show version'
    )
    _arguments -C \
        "1: :{_describe 'command' commands}" \
        "*::arg:->args"
    case $state in
        args)
            case $words[1] in
                theme) _values 'subcommand' list apply create delete edit export favorite history import pick preview random reset schedule search validate wcag ;;
                mode) _values 'subcommand' game work focus cinema present battery stream privacy accessibility default list status ;;
                plugin) _values 'subcommand' list install remove enable disable search info browse create ;;
            esac
            ;;
    esac
}
_ash "$@"
