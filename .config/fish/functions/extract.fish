# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — EXTRACT FUNCTION                             ║
# ║           Universal archive extractor (30+ formats)                        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function extract -d "Extract any archive format" -a archive
    if test -z "$archive"
        echo "Usage: extract <archive> [destination]"
        echo ""
        echo "Supported formats:"
        echo "  .tar.gz .tgz .tar.bz2 .tbz .tar.xz .txz"
        echo "  .tar.zst .zip .rar .7z .gz .bz2 .xz .zst"
        echo "  .lz .lzma .z .lzh .ar .deb .rpm .iso .img"
        return 1
    end

    set -l dest (test -n "$argv[2]" && echo "$argv[2]" || echo ".")

    if not test -f "$archive"
        echo "❌ File not found: $archive"
        return 1
    end

    # Create destination if needed
    mkdir -p "$dest"

    echo "📦 Extracting: $archive → $dest"
    set -l start_time (date +%s)

    switch $archive
        case '*.tar.gz' '*.tgz'
            tar -xzf "$archive" -C "$dest"
        case '*.tar.bz2' '*.tbz' '*.tbz2'
            tar -xjf "$archive" -C "$dest"
        case '*.tar.xz' '*.txz'
            tar -xJf "$archive" -C "$dest"
        case '*.tar.zst'
            tar --zstd -xf "$archive" -C "$dest"
        case '*.tar.lz' '*.tlz'
            tar --lzip -xf "$archive" -C "$dest"
        case '*.tar'
            tar -xf "$archive" -C "$dest"
        case '*.zip'
            if command -q unzip
                unzip -q "$archive" -d "$dest"
            else
                echo "❌ unzip not installed"
                return 1
            end
        case '*.rar'
            if command -q unrar
                unrar x -y "$archive" "$dest/"
            else if command -q 7z
                7z x "$archive" -o"$dest"
            else
                echo "❌ unrar or 7z required"
                return 1
            end
        case '*.7z'
            if command -q 7z
                7z x "$archive" -o"$dest"
            else
                echo "❌ 7z (p7zip) not installed"
                return 1
            end
        case '*.gz'
            if command -q pigz
                pigz -dk "$archive"
            else
                gzip -dk "$archive"
            end
        case '*.bz2'
            bzip2 -dk "$archive"
        case '*.xz'
            xz -dk "$archive"
        case '*.zst'
            zstd -dk "$archive"
        case '*.lz4'
            lz4 -dk "$archive"
        case '*.lzma'
            lzma -dk "$archive"
        case '*.z'
            uncompress "$archive"
        case '*.lzh'
            lha x "$archive"
        case '*.ar' '*.deb'
            ar x "$archive"
        case '*.rpm'
            if command -q rpm2cpio
                rpm2cpio "$archive" | cpio -idmv --quiet
            else
                echo "❌ rpm2cpio not installed"
                return 1
            end
        case '*.iso' '*.img'
            if command -q 7z
                7z x "$archive" -o"$dest"
            else
                echo "Mount ISO: sudo mount -o loop '$archive' /mnt"
                return 1
            end
        case '*.AppImage'
            chmod +x "$archive"
            echo "AppImage — run directly: ./$archive"
            return 0
        case '*'
            echo "❌ Unsupported format: $archive"
            echo "Try: file $archive"
            return 1
    end

    set -l exit_code $status
    set -l end_time (date +%s)
    set -l elapsed (math $end_time - $start_time)

    if test $exit_code -eq 0
        set -l size (du -sh "$dest" 2>/dev/null | cut -f1)
        echo "✅ Extracted in $elapsed"s" → $dest ($size)"
    else
        echo "❌ Extraction failed (exit code: $exit_code)"
        return $exit_code
    end
end

# Completion
complete -c extract -s h -l help -d "Show help"
complete -c extract -F