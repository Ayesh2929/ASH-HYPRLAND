; ╔══════════════════════════════════════════════════════════════════════════════════╗
; ║       🎨 RASI (ROFI STYLESHEET) — TREESITTER HIGHLIGHTS v5.0 OMEGA             ║
; ║   Complete semantic highlighting · selectors · properties · values             ║
; ║   Colours · distances · orientations · states · media queries · transitions    ║
; ╚══════════════════════════════════════════════════════════════════════════════════╝

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📝 COMMENTS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

(comment) @comment @spell

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📋 CONFIGURATION ENTRIES — @keyword statements
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; @import — file inclusion
(configuration
  "@import" @keyword.import)

; @theme — theme reference
(configuration
  "@theme" @keyword.import)

; @plugin — plugin loading
(configuration
  "@plugin" @keyword.modifier)

; All @ directives (catch-all)
(configuration
  (selector) @keyword
  (#match? @keyword "^@"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🗂️  SELECTORS — element / widget identifiers
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Selector: top-level rule block name
(ruleset
  selector: (selector) @tag)

; Known Rofi widget selectors
((selector) @tag.builtin
  (#any-of? @tag.builtin
    ; Root window
    "window"
    ; Mainbox layout
    "mainbox"
    ; Input bar section
    "inputbar"
    "prompt"
    "entry"
    "case-indicator"
    "num-rows"
    "num-filtered-rows"
    "textbox-current-element-content"
    "input-bar-overlay"
    ; Listview section
    "listview"
    "listview-overlay"
    "scrollbar"
    "element"
    "element-icon"
    "element-text"
    "element-overlay"
    ; Mode switcher
    "mode-switcher"
    "mode-switcher-overlay"
    "button"
    "button-overlay"
    ; Message section
    "message"
    "textbox"
    "message-overlay"
    ; Error section
    "error-message"
    "inputbar-overlay"
    ; Overlay / cursor
    "overlay"
    "cursor"
    ; Shared
    "dummy"
    ; Global settings
    "*"))

; Pseudo-class selectors (state modifiers)
((selector) @type.qualifier
  (#match? @type.qualifier "\\."))

; Known pseudo-classes / states
((selector) @attribute
  (#match? @attribute
    "\\.(normal|urgent|active|selected|hovered|pressed|focused|alternate|visible|hidden|disabled|enabled|toggled|animating|first|last)"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🏷️  PROPERTIES — CSS-like property names
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Property identifier on the left-hand side
(property
  name: (identifier) @property)

; Known layout properties
((identifier) @property.definition
  (#any-of? @property.definition
    ; Geometry
    "width"
    "height"
    "max-width"
    "max-height"
    "min-width"
    "min-height"
    "x-offset"
    "y-offset"
    "margin"
    "padding"
    "border"
    "border-radius"
    "spacing"
    "columns"
    "fixed-height"
    "fixed-num-lines"
    "lines"
    "line-padding"
    ; Position & anchor
    "location"
    "anchor"
    "x"
    "y"
    ; Appearance
    "background-color"
    "background-image"
    "foreground-color"
    "text-color"
    "border-color"
    "alternate-background"
    "alternate-foreground"
    "selected-background"
    "selected-foreground"
    "selected-normal-background"
    "selected-normal-foreground"
    "selected-active-background"
    "selected-active-foreground"
    "selected-urgent-background"
    "selected-urgent-foreground"
    "normal-background"
    "normal-foreground"
    "active-background"
    "active-foreground"
    "urgent-background"
    "urgent-foreground"
    "alternate-normal-background"
    "alternate-normal-foreground"
    "alternate-active-background"
    "alternate-active-foreground"
    "alternate-urgent-background"
    "alternate-urgent-foreground"
    "inputbar-background"
    "inputbar-foreground"
    "hover-background"
    "hover-foreground"
    ; Shadow
    "shadow"
    "shadow-offset-x"
    "shadow-offset-y"
    "shadow-radius"
    "shadow-color"
    ; Typography
    "font"
    ; Image / icon
    "icon-size"
    "background-size"
    ; Scroll / cycle
    "scrollbar"
    "scrollbar-width"
    "cycle"
    "dynamic"
    "flow"
    "wrap"
    ; Orientation
    "orientation"
    "horizontal"
    "vertical"
    ; Visibility & behaviour
    "enabled"
    "hidden"
    "visible"
    "expand"
    "markup"
    ; Cursor
    "cursor"
    ; Animation
    "animation"
    "animation-type"
    "animation-duration"
    "animation-function"
    ; Transition
    "transition"
    "transition-duration"
    "transition-type"
    ; Filter / overlay
    "blur-radius"
    "opacity"
    ; Misc
    "override-redirect"
    "recolor"
    "recolor-true-color"
    "recolor-darkvalue"
    "recolor-lightvalue"
    "recolor-base-color"
    "recolor-highlight-color"
    "recolor-accent-color"
    "transparency"
    "side"
    "zoom"
    "zoom-horizontal"
    "zoom-vertical"
    "cursor-mode"
    "parse-hosts"
    "parse-known-hosts"
    ; List view
    "reverse"
    "require-input"
    "auto-select"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🎨 COLOUR VALUES — rgba(), rgb(), #hex, @var colours
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Hex colour literals (#RRGGBB, #RRGGBBAA, #RGB, #RGBA)
(color_value) @string.special

; rgba() function call
(function_call
  function: (identifier) @function.builtin
  (#any-of? @function.builtin
    "rgba"
    "rgb"
    "hsl"
    "hsla"
    "argb"
    "hwb"
    "lab"
    "lch"
    "oklch"
    "oklab"
    "color-mix"
    "linear-gradient"
    "radial-gradient"
    "conic-gradient"
    "image"
    "url"))

; Colour function arguments
(function_call
  (argument) @number)

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📏 DISTANCE / SIZE VALUES — px, em, %, ch, etc.
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Numeric value with optional unit
(distance_value) @number

; Integer literals in property values
(integer_value) @number

; Float literals in property values
(float_value) @number.float

; Percentage values
((unit) @type.builtin
  (#any-of? @type.builtin
    "px"
    "em"
    "ch"
    "ex"
    "%"
    "mm"
    "cm"
    "in"
    "pt"
    "pc"
    "vw"
    "vh"
    "vmin"
    "vmax"
    "fr"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔤 STRING LITERALS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Double-quoted strings (font names, file paths, etc.)
(string_value) @string

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; ✅ BOOLEAN & KEYWORD VALUES
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Boolean keyword values
((identifier) @boolean
  (#any-of? @boolean
    "true"
    "false"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🧭 ORIENTATION / POSITION CONSTANTS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Position and orientation values
((identifier) @constant.builtin
  (#any-of? @constant.builtin
    ; Orientation
    "horizontal"
    "vertical"
    ; Anchor / location positions (clock positions)
    "north"
    "north-west"
    "north-east"
    "south"
    "south-west"
    "south-east"
    "east"
    "west"
    "center"
    ; Named positions
    "top"
    "top-left"
    "top-right"
    "bottom"
    "bottom-left"
    "bottom-right"
    "left"
    "right"
    "middle"
    ; Flow directions
    "row"
    "column"
    ; Alignment
    "start"
    "end"
    "stretch"
    "baseline"
    "auto"
    ; Line style for border
    "none"
    "solid"
    "dashed"
    "dotted"
    "double"
    "groove"
    "ridge"
    "inset"
    "outset"
    ; Cursor types
    "default"
    "pointer"
    "text"
    "crosshair"
    "move"
    "grab"
    "grabbing"
    "not-allowed"
    "zoom-in"
    "zoom-out"
    ; Transparency types
    "real"
    "background"
    "screenshot"
    "Path"
    ; Misc
    "inherit"
    "initial"
    "unset"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🌈 COLOUR NAME CONSTANTS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; CSS named colours
((identifier) @string.special
  (#any-of? @string.special
    "black"
    "white"
    "red"
    "green"
    "blue"
    "yellow"
    "cyan"
    "magenta"
    "orange"
    "purple"
    "pink"
    "gray"
    "grey"
    "silver"
    "transparent"
    "currentColor"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔗 VARIABLE REFERENCES — @variable-name
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; @variable reference in property values
(variable) @variable

; Variable definition in @-rules
(variable_definition
  name: (identifier) @variable.definition)

; Rofi built-in theme variables
((variable) @variable.builtin
  (#match? @variable.builtin
    "^@(background|foreground|background-color|foreground-color|selected-background|selected-foreground|border-color|separatorcolor|spacer|inputbar-background|inputbar-foreground|normal-background|normal-foreground|urgent-background|urgent-foreground|active-background|active-foreground|alternate-normal-background|alternate-normal-foreground|alternate-active-background|alternate-active-foreground|alternate-urgent-background|alternate-urgent-foreground|selected-normal-background|selected-normal-foreground|selected-active-background|selected-active-foreground|selected-urgent-background|selected-urgent-foreground|shadow|font)$"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔣 OPERATORS & PUNCTUATION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Block delimiters
"{" @punctuation.bracket
"}" @punctuation.bracket

; Value list / tuple
"(" @punctuation.bracket
")" @punctuation.bracket

; Separators
"," @punctuation.delimiter
";" @punctuation.delimiter

; Property assignment colon
":" @punctuation.delimiter

; Media / pseudo-class dot
"." @punctuation.special

; Star (global selector)
"*" @keyword.operator

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔢 NUMERICAL OPERATIONS in calc() / expressions
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; calc() function
(function_call
  function: (identifier) @function.builtin
  (#any-of? @function.builtin "calc" "min" "max" "clamp" "env" "var"))

; Arithmetic operators inside calc()
(binary_expression
  operator: _ @operator)

; Unary minus / plus
(unary_expression
  operator: _ @operator)

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🎬 ANIMATION / TRANSITION VALUES
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Animation type values
((identifier) @constant
  (#any-of? @constant
    ; Animation types
    "none"
    "fade"
    "slide"
    "slide-in"
    "slide-out"
    "slide-up"
    "slide-down"
    "bounce"
    ; Easing functions
    "linear"
    "ease"
    "ease-in"
    "ease-out"
    "ease-in-out"
    "ease-in-sine"
    "ease-out-sine"
    "ease-in-out-sine"
    "ease-in-quad"
    "ease-out-quad"
    "ease-in-out-quad"
    "ease-in-cubic"
    "ease-out-cubic"
    "ease-in-out-cubic"
    "ease-in-quart"
    "ease-out-quart"
    "ease-in-out-quart"
    "ease-in-quint"
    "ease-out-quint"
    "ease-in-out-quint"
    "ease-in-expo"
    "ease-out-expo"
    "ease-in-out-expo"
    "ease-in-circ"
    "ease-out-circ"
    "ease-in-out-circ"
    "ease-in-back"
    "ease-out-back"
    "ease-in-out-back"
    "step-start"
    "step-end"
    "steps"
    "cubic-bezier"))

; Duration values (time units)
((unit) @type.builtin
  (#any-of? @type.builtin "s" "ms"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📐 BORDER SHORTHAND — border: width style color
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Line-style keyword values used in border shorthand
((identifier) @keyword.modifier
  (#any-of? @keyword.modifier
    "solid"
    "dashed"
    "dotted"
    "double"
    "none"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🎯 PSEUDO-STATE SUFFIXES — .normal, .active, etc.
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Pseudo-class state identifiers
((identifier) @attribute.builtin
  (#any-of? @attribute.builtin
    "normal"
    "urgent"
    "active"
    "selected"
    "hovered"
    "pressed"
    "focused"
    "alternate"
    "visible"
    "hidden"
    "disabled"
    "enabled"
    "toggled"
    "current"
    "default"
    "first"
    "last"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🌟 MEDIA QUERY KEYWORDS — @media
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; @media keyword
((at_keyword) @keyword.directive
  (#any-of? @keyword.directive
    "@media"
    "@supports"
    "@keyframes"
    "@import"
    "@theme"
    "@plugin"
    "@charset"
    "@layer"
    "@namespace"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📁 FILE PATH STRINGS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; url() and file paths
(function_call
  function: (identifier) @function.builtin
  (#any-of? @function.builtin "url" "image" "url-prefix")
  (argument) @string.special.path)

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔤 IDENTIFIERS (FALLBACK)
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Catch-all for unmatched identifiers used as property values
(property
  value: (identifier) @string)

; All remaining identifiers
(identifier) @variable