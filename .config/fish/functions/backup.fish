# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — BACKUP FISH FUNCTION                         ║
# ║           Quick backup wrapper for ASH dotfiles                            ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function backup -d "Backup ASH dotfiles configuration"
    set -l c_ok    (set_color a6e3a1)
    set -l c_err   (set_color f38ba8)
    set -l c_info  (set_color 89b4fa)
    set -l c_warn  (set_color f9e2af)
    set -l c_reset (set_color normal)

    set -l backup_dir "$HOME/.local/share/ash-dots/backups"
    set -l cache_dir  "$HOME/.cache/ash-dots"

    # Parse arguments
    set -l mode "create"
    if test (count $argv) -gt 0
        set mode $argv[1]
    end

    switch $mode
        case create "" -c --create
            echo -e "  $c_info→$c_reset Creating backup..."

            # Use ash CLI if available
            if command -q ash
                ash backup
                and echo -e "  $c_ok✓$c_reset Backup created"
                or echo -e "  $c_err✗$c_reset Backup failed"
            else
                # Fallback: manual backup
                set -l timestamp (date '+%Y%m%d_%H%M%S')
                set -l backup_path "$backup_dir/backup-manual-$timestamp"
                mkdir -p $backup_path

                # Copy key files
                for item in \
                    "$HOME/.config/hypr/UserOverrides/user.conf" \
                    "$HOME/.config/hypr/themes" \
                    "$HOME/.config/starship.toml" \
                    "$cache_dir/colors/current.json"
                    if test -e $item
                        cp -r $item $backup_path/ 2>/dev/null
                    end
                end

                echo -e "  $c_ok✓$c_reset Backup saved: $backup_path"
            end

        case list -l --list
            echo ""
            echo -e "  $c_info📦 Available Backups:$c_reset"
            echo ""
            if test -d $backup_dir
                find $backup_dir -name "backup-*.tar.gz" 2>/dev/null \
                    | sort -r \
                    | while read -l backup
                    set -l name (basename $backup .tar.gz)
                    set -l size (du -sh $backup 2>/dev/null | cut -f1)
                    printf "  %s  %s\n" $size $name
                end
            else
                echo "  No backups found"
            end
            echo ""

        case restore -r --restore
            if command -q ash
                ash restore
            else
                echo -e "  $c_warn⚠$c_reset ash CLI not found — use: bash ~/.dotfiles/scripts/core/restore.sh"
            end

        case clean --clean
            echo -e "  $c_warn⚠$c_reset This will remove ALL backups!"
            read -P "  Confirm (type 'yes'): " confirm
            if test "$confirm" = "yes"
                rm -f $backup_dir/backup-*.tar.gz 2>/dev/null
                echo -e "  $c_ok✓$c_reset All backups removed"
            else
                echo -e "  $c_info→$c_reset Cancelled"
            end

        case help -h --help
            echo ""
            echo -e "  $c_info backup$c_reset — ASH configuration backup"
            echo ""
            echo "  backup              Create backup"
            echo "  backup list         List all backups"
            echo "  backup restore      Restore from backup"
            echo "  backup clean        Remove all backups"
            echo ""
    end
end

complete -c backup -f
complete -c backup -n "__fish_use_subcommand" -a create  -d "Create backup"
complete -c backup -n "__fish_use_subcommand" -a list    -d "List backups"
complete -c backup -n "__fish_use_subcommand" -a restore -d "Restore backup"
complete -c backup -n "__fish_use_subcommand" -a clean   -d "Remove all backups"