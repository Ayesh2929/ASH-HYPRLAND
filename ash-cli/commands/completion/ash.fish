# ASH completion for fish
# Place in ~/.config/fish/completions/ash.fish
complete -c ash -f
complete -c ash -n "__fish_use_subcommand" -a theme -d "Manage themes"
complete -c ash -n "__fish_use_subcommand" -a mode -d "Switch desktop modes"
complete -c ash -n "__fish_use_subcommand" -a plugin -d "Manage plugins"
complete -c ash -n "__fish_use_subcommand" -a snapshot -d "Config snapshots"
complete -c ash -n "__fish_use_subcommand" -a config -d "Configuration"
complete -c ash -n "__fish_use_subcommand" -a doctor -d "Health checks"
complete -c ash -n "__fish_use_subcommand" -a help -d "Show help"
complete -c ash -n "__fish_use_subcommand" -a version -d "Show version"
complete -c ash -n "__fish_seen_subcommand_from theme" -a "list apply create delete edit export favorite history import pick preview random reset schedule search validate wcag" 
complete -c ash -n "__fish_seen_subcommand_from mode" -a "game work focus cinema present battery stream privacy accessibility default list status"
complete -c ash -n "__fish_seen_subcommand_from plugin" -a "list install remove enable disable search info"
