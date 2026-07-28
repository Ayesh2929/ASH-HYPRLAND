; ╔══════════════════════════════════════════════════════════════════════════════════╗
; ║       🐠 FISH SHELL — TREESITTER HIGHLIGHTS v5.0 OMEGA                         ║
; ║   Complete semantic highlighting · functions · variables · builtins            ║
; ║   Operators · string interpolation · redirects · pipes · conditionals          ║
; ╚══════════════════════════════════════════════════════════════════════════════════╝

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📝 COMMENTS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

(comment) @comment @spell

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔑 KEYWORDS — control flow
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[
  "if"
  "else"
  "else if"
  "end"
] @keyword.conditional

[
  "for"
  "while"
  "in"
] @keyword.repeat

[
  "break"
  "continue"
] @keyword.repeat

[
  "return"
] @keyword.return

[
  "function"
] @keyword.function

[
  "switch"
  "case"
] @keyword.conditional

[
  "begin"
] @keyword

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; ⚙️  FUNCTION DEFINITION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Function name in definition
(function_definition
  name: (word) @function)

; Function flags (--description, --argument-names, etc.)
(function_definition
  option: (word) @keyword.modifier
  (#match? @keyword.modifier "^--"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📞 COMMAND (FUNCTION) CALLS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; First word of a command (the command name)
(command
  name: (word) @function.call)

; Built-in fish commands
(command
  name: (word) @function.builtin
  (#any-of? @function.builtin
    ; Core builtins
    "abbr"
    "alias"
    "and"
    "argparse"
    "begin"
    "bg"
    "bind"
    "block"
    "breakpoint"
    "builtin"
    "cd"
    "command"
    "commandline"
    "complete"
    "contains"
    "count"
    "dirh"
    "dirs"
    "disown"
    "echo"
    "emit"
    "eval"
    "exec"
    "exit"
    "false"
    "fg"
    "fish"
    "fish_add_path"
    "fish_breakpoint_prompt"
    "fish_command_not_found"
    "fish_config"
    "fish_greeting"
    "fish_indent"
    "fish_is_root_user"
    "fish_key_reader"
    "fish_mode_prompt"
    "fish_opt"
    "fish_prompt"
    "fish_right_prompt"
    "fish_status_to_signal"
    "fish_title"
    "fish_update_completions"
    "fish_user_key_bindings"
    "funced"
    "funcsave"
    "functions"
    "help"
    "history"
    "isatty"
    "jobs"
    "kill"
    "math"
    "nextd"
    "not"
    "open"
    "or"
    "popd"
    "prevd"
    "printf"
    "pushd"
    "pwd"
    "random"
    "read"
    "realpath"
    "return"
    "set"
    "set_color"
    "source"
    "status"
    "string"
    "suspend"
    "test"
    "time"
    "trap"
    "true"
    "type"
    "ulimit"
    "umask"
    "vared"
    "wait"))

; External commands that are commonly used (highlight differently)
(command
  name: (word) @function.macro
  (#any-of? @function.macro
    ; Package managers
    "paru"
    "yay"
    "pacman"
    "brew"
    "apt"
    "apt-get"
    "dnf"
    "nix"
    ; Version control
    "git"
    "hg"
    "svn"
    ; System tools
    "sudo"
    "doas"
    "systemctl"
    "journalctl"
    "ssh"
    "rsync"
    "curl"
    "wget"
    ; Modern replacements
    "eza"
    "exa"
    "bat"
    "fd"
    "rg"
    "ripgrep"
    "fzf"
    "zoxide"
    "atuin"
    "starship"
    ; ASH dotfiles tools
    "ash"
    "hyprctl"
    "waybar"
    "dunstify"
    "notify-send"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📦 VARIABLES
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Variable expansion $VAR
(variable_expansion) @variable

; Variable name inside expansion
(variable_expansion
  (word) @variable)

; Special fish variables
((variable_expansion
  (word) @variable.builtin)
  (#any-of? @variable.builtin
    ; Status variables
    "status"
    "pipestatus"
    "fish_status_generation"
    ; Path variables
    "PATH"
    "MANPATH"
    "CDPATH"
    "fish_user_paths"
    "fish_function_path"
    "fish_complete_path"
    ; Fish config
    "fish_greeting"
    "fish_prompt_pwd_dir_length"
    "fish_prompt_pwd_full_dirs"
    "fish_color_autosuggestion"
    "fish_color_command"
    "fish_color_comment"
    "fish_color_cwd"
    "fish_color_cwd_root"
    "fish_color_end"
    "fish_color_error"
    "fish_color_escape"
    "fish_color_keyword"
    "fish_color_match"
    "fish_color_normal"
    "fish_color_operator"
    "fish_color_param"
    "fish_color_quote"
    "fish_color_redirection"
    "fish_color_search_match"
    "fish_color_selection"
    "fish_color_valid_path"
    "fish_pager_color_background"
    "fish_pager_color_completion"
    "fish_pager_color_description"
    "fish_pager_color_prefix"
    "fish_pager_color_progress"
    "fish_pager_color_selected_background"
    "fish_pager_color_selected_completion"
    "fish_pager_color_selected_description"
    "fish_pager_color_selected_prefix"
    "fish_pager_color_secondary"
    "fish_pager_color_secondary_background"
    "fish_pager_color_secondary_completion"
    "fish_pager_color_secondary_description"
    "fish_pager_color_secondary_prefix"
    ; Shell variables
    "HOME"
    "USER"
    "LOGNAME"
    "SHELL"
    "TERM"
    "TERM_PROGRAM"
    "LANG"
    "LANGUAGE"
    "LC_ALL"
    "LC_MESSAGES"
    "LC_CTYPE"
    "TMPDIR"
    "EDITOR"
    "VISUAL"
    "PAGER"
    "BROWSER"
    ; Process variables
    "argv"
    "argc"
    "fish_pid"
    "last_pid"
    "hostname"
    "version"
    "fish_version"
    "fish_major_version"
    "fish_minor_version"
    "fish_patch_version"
    ; XDG
    "XDG_CONFIG_HOME"
    "XDG_DATA_HOME"
    "XDG_CACHE_HOME"
    "XDG_STATE_HOME"
    "XDG_RUNTIME_DIR"
    "XDG_CONFIG_DIRS"
    "XDG_DATA_DIRS"
    ; Display / Wayland / X11
    "DISPLAY"
    "WAYLAND_DISPLAY"
    "XDG_SESSION_TYPE"
    "XDG_CURRENT_DESKTOP"
    "HYPRLAND_INSTANCE_SIGNATURE"
    ; Numeric special vars
    "0" "1" "2" "3" "4" "5" "6" "7" "8" "9"
    "_"))

; set command: variable being defined
(command
  name: (word) @_set
  (#eq? @_set "set")
  argument: (word) @variable.parameter)

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔤 STRINGS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Double-quoted string (allows variable expansion)
(double_quote_string) @string

; Single-quoted string (literal, no expansion)
(single_quote_string) @string

; String escape sequences inside double-quoted strings
(double_quote_string
  (escape_sequence) @string.escape)

; Variable expansion inside double-quoted strings
(double_quote_string
  (variable_expansion) @variable)

; Command substitution inside double-quoted strings
(double_quote_string
  (command_substitution) @string.special)

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔣 ESCAPE SEQUENCES
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

(escape_sequence) @string.escape

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; ⚡ COMMAND SUBSTITUTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; (command substitution) delimiters
(command_substitution
  "(" @punctuation.bracket
  ")" @punctuation.bracket)

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📋 FLAGS / OPTIONS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Long flags (--flag)
(command
  argument: (word) @keyword.modifier
  (#match? @keyword.modifier "^--[a-zA-Z]"))

; Short flags (-f)
(command
  argument: (word) @keyword.modifier
  (#match? @keyword.modifier "^-[a-zA-Z]"))

; End-of-options marker
(command
  argument: (word) @keyword.operator
  (#eq? @keyword.operator "--"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔀 OPERATORS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Pipe
"|" @operator

; Background operator
"&" @operator

; Logical operators
(command_sequence
  "&;" @operator)

(command_sequence
  ";;" @punctuation.delimiter)

; Concatenation in brace expansion
(brace_expansion
  "," @punctuation.delimiter)

; Sequence operator
";" @punctuation.delimiter

; Negation (not)
"!" @keyword.operator

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔁 REDIRECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Redirect operators
(redirect) @punctuation.special

(redirect
  "<"  @operator)

(redirect
  ">"  @operator)

(redirect
  ">>" @operator)

(redirect
  "^"  @operator)

(redirect
  "2>"  @operator)

(redirect
  "2>>" @operator)

(redirect
  "&>"  @operator)

; /dev/null and special file targets
(redirect
  target: (word) @string.special
  (#any-of? @string.special
    "/dev/null"
    "/dev/stdin"
    "/dev/stdout"
    "/dev/stderr"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔢 NUMBERS — in math / test contexts
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Numeric arguments to commands
(command
  argument: (word) @number
  (#match? @number "^-?[0-9]+\\.?[0-9]*$"))

; Hex numbers
(command
  argument: (word) @number
  (#match? @number "^0[xX][0-9a-fA-F]+$"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🎯 TEST / CONDITION OPERATORS — [ ] and [[ ]]
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Test command operators
(command
  argument: (word) @keyword.operator
  (#any-of? @keyword.operator
    ; File tests
    "-f" "-d" "-e" "-r" "-w" "-x" "-s" "-L" "-S" "-p" "-b" "-c"
    ; String tests
    "-z" "-n"
    ; Integer comparison
    "-eq" "-ne" "-lt" "-le" "-gt" "-ge"
    ; Extended
    "-nt" "-ot" "-ef"))

; String comparison operators in test
(command
  argument: (word) @operator
  (#any-of? @operator "=" "!=" "<" ">" "==" "=~"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🧮 MATH OPERATIONS — math command context
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; math built-in function arguments (treated as math expressions)
(command
  name: (word) @_math
  (#eq? @_math "math")
  argument: (word) @number
  (#match? @number "^[0-9]+"))

; Math operators inside math command
(command
  name: (word) @_math2
  (#eq? @_math2 "math")
  argument: (word) @operator
  (#match? @operator "^[+\\-*/%%^()]+$"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🌐 GLOB PATTERNS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Glob wildcard patterns
(word) @string.special.path
  (#match? @string.special.path "[*?\\[\\]]")

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔗 SPECIAL BUILT-IN ARGUMENTS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; set scopes
(command
  name: (word) @_set_scope
  (#eq? @_set_scope "set")
  argument: (word) @type.qualifier
  (#any-of? @type.qualifier
    "-l" "--local"
    "-g" "--global"
    "-U" "--universal"
    "-x" "--export"
    "-u" "--unexport"
    "-e" "--erase"
    "-q" "--query"
    "-S" "--show"
    "-a" "--append"
    "-p" "--prepend"
    "-f" "--function"
    "--path"))

; status subcommands
(command
  name: (word) @_status
  (#eq? @_status "status")
  argument: (word) @constant.builtin
  (#any-of? @constant.builtin
    "current-command"
    "current-filename"
    "current-line-number"
    "fish-path"
    "features"
    "is-block"
    "is-breakpoint"
    "is-command-substitution"
    "is-full-job-control"
    "is-interactive"
    "is-job-control-enabled"
    "is-login"
    "is-no-job-control"
    "job-control"
    "print-stack-trace"
    "set-job-control"
    "test-feature"))

; string subcommands
(command
  name: (word) @_string
  (#eq? @_string "string")
  argument: (word) @constant.builtin
  (#any-of? @constant.builtin
    "collect"
    "escape"
    "join"
    "join0"
    "length"
    "lower"
    "match"
    "pad"
    "repeat"
    "replace"
    "shorten"
    "split"
    "split0"
    "sub"
    "trim"
    "unescape"
    "upper"))

; complete subcommands
(command
  name: (word) @_complete
  (#eq? @_complete "complete")
  argument: (word) @attribute
  (#any-of? @attribute
    "-c" "--command"
    "-s" "--short-option"
    "-l" "--long-option"
    "-a" "--arguments"
    "-d" "--description"
    "-f" "--no-files"
    "-F" "--force-files"
    "-r" "--require-parameter"
    "-n" "--condition"
    "-x" "--exclusive"
    "-k" "--keep-order"
    "-A" "--authoritative"
    "-u" "--unauthoritative"))

; abbr subcommands and options
(command
  name: (word) @_abbr
  (#eq? @_abbr "abbr")
  argument: (word) @attribute
  (#any-of? @attribute
    "-a" "--add"
    "-e" "--erase"
    "-l" "--list"
    "-s" "--show"
    "-r" "--rename"
    "-q" "--query"
    "--function"
    "--position"
    "--regex"
    "--set-cursor"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🎨 SET_COLOR VALUES — colour names and options
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; set_color colour names
(command
  name: (word) @_set_color
  (#eq? @_set_color "set_color")
  argument: (word) @string.special
  (#any-of? @string.special
    "black"
    "red"
    "green"
    "yellow"
    "blue"
    "magenta"
    "cyan"
    "white"
    "brblack"
    "brred"
    "brgreen"
    "bryellow"
    "brblue"
    "brmagenta"
    "brcyan"
    "brwhite"
    "normal"))

; set_color hex colours
(command
  name: (word) @_set_color_hex
  (#eq? @_set_color_hex "set_color")
  argument: (word) @string.special
  (#match? @string.special "^[0-9a-fA-F]{3,8}$"))

; set_color options
(command
  name: (word) @_set_color_opt
  (#eq? @_set_color_opt "set_color")
  argument: (word) @keyword.modifier
  (#any-of? @keyword.modifier
    "-b" "--background"
    "-c" "--print-colors"
    "-o" "--bold"
    "-d" "--dim"
    "-i" "--italics"
    "-r" "--reverse"
    "-u" "--underline"
    "-s" "--underline-style"
    "-U" "--url"
    "normal"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📊 BRACE EXPANSION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

(brace_expansion
  "{" @punctuation.bracket
  "}" @punctuation.bracket)

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🏷️  INDEX NOTATION — $var[index]
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

(index
  "[" @punctuation.bracket
  "]" @punctuation.bracket)

(index) @number

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🌟 SHEBANG — file header
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; #!/usr/bin/env fish or similar
(program
  (comment) @preproc
  (#match? @preproc "^#!"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔤 WORD (FALLBACK)
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Generic word — lowest priority fallback
(word) @variable

; Path-like words
(word) @string.special.path
  (#match? @string.special.path "^[~/.]")

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔗 ASH DOTFILES SPECIFICS — common ASH CLI patterns
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; ASH subcommands
(command
  name: (word) @_ash_cmd
  (#eq? @_ash_cmd "ash")
  argument: (word) @constant.builtin
  (#any-of? @constant.builtin
    "theme"
    "mode"
    "plugin"
    "snapshot"
    "config"
    "doctor"
    "update"
    "shot"
    "wallpaper"
    "bar"
    "power"
    "monitor"
    "audio"
    "bluetooth"
    "window"
    "workspace"
    "gaming"
    "backup"
    "analytics"
    "profile"
    "cloud"
    "store"
    "session"
    "ai"
    "macro"
    "remote"
    "benchmark"
    "migrate"
    "hw"
    "net"))

; ASH theme subcommands
(command
  name: (word) @_ash_theme
  (#any-of? @_ash_theme "ash")
  argument: (word) @_ash_theme_sub
  (#eq? @_ash_theme_sub "theme")
  argument: (word) @constant
  (#any-of? @constant
    "apply"
    "pick"
    "list"
    "create"
    "edit"
    "clone"
    "export"
    "import"
    "preview"
    "random"
    "delete"
    "reset"
    "schedule"
    "ai-generate"
    "ai-mood"
    "wallpaper"
    "colors"
    "validate"
    "benchmark"
    "history"
    "favorite"
    "sync"))

; Fish path abbreviations (common in ASH config)
((variable_expansion
  (word) @constant.builtin)
  (#any-of? @constant.builtin
    "XDG_CONFIG_HOME"
    "XDG_DATA_HOME"
    "XDG_CACHE_HOME"
    "HYPRLAND_INSTANCE_SIGNATURE"
    "WAYLAND_DISPLAY"
    "DISPLAY"))