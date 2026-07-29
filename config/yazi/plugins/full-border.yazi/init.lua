--- ╔══════════════════════════════════════════════════════════════════════════╗
--- ║  ASH DOTFILES v5.0 — YAZI PLUGIN: FULL BORDER                         ║
--- ║                                                                        ║
--- ║  Draws a premium full outer border around the Yazi UI panels          ║
--- ║  with corner pieces, section labels, and status indicators.            ║
--- ║                                                                        ║
--- ║  Border Style:                                                         ║
--- ║  ╭─────────────────────────────────────────────╮                      ║
--- ║  │ 󰉋 ~/Projects    │  src/       │ preview      │                      ║
--- ║  ╰─────────────────────────────────────────────╯                      ║
--- ╚══════════════════════════════════════════════════════════════════════╝

local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  CONFIGURATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Border character sets
local borders = {
    -- Rounded corners (premium default)
    rounded = {
        top_left     = "╭",
        top_right    = "╮",
        bottom_left  = "╰",
        bottom_right = "╯",
        horizontal   = "─",
        vertical     = "│",
        top_tee      = "┬",
        bottom_tee   = "┴",
        left_tee     = "├",
        right_tee    = "┤",
        cross        = "┼",
    },
    -- Sharp corners (alternative)
    sharp = {
        top_left     = "┌",
        top_right    = "┐",
        bottom_left  = "└",
        bottom_right = "┘",
        horizontal   = "─",
        vertical     = "│",
        top_tee      = "┬",
        bottom_tee   = "┴",
        left_tee     = "├",
        right_tee    = "┤",
        cross        = "┼",
    },
    -- Double line
    double = {
        top_left     = "╔",
        top_right    = "╗",
        bottom_left  = "╚",
        bottom_right = "╝",
        horizontal   = "═",
        vertical     = "║",
        top_tee      = "╦",
        bottom_tee   = "╩",
        left_tee     = "╠",
        right_tee    = "╣",
        cross        = "╬",
    },
    -- Minimal (single line)
    minimal = {
        top_left     = "┌",
        top_right    = "┐",
        bottom_left  = "└",
        bottom_right = "┘",
        horizontal   = "─",
        vertical     = "│",
        top_tee      = "┬",
        bottom_tee   = "┴",
        left_tee     = "├",
        right_tee    = "┤",
        cross        = "┼",
    },
}

-- Current border style (configurable via setup)
local current_border = borders.rounded

-- Catppuccin Mocha border colors
local color_border   = ui.Color.from_rgb(49,  50,  68)   -- Surface0
local color_title    = ui.Color.from_rgb(203, 166, 247)  -- Mauve
local color_icon     = ui.Color.from_rgb(137, 180, 250)  -- Blue
local color_dim      = ui.Color.from_rgb(108, 112, 134)  -- Overlay0
local color_active   = ui.Color.from_rgb(203, 166, 247)  -- Mauve (active panel)

-- Panel icons
local panel_icons = {
    parent  = "󰉖 ",   -- Parent directory icon
    current = "󰉋 ",   -- Current directory icon
    preview = "󰛢 ",   -- Preview panel icon
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  ENTRY — Main render hook
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- @param job table  Yazi render job
function M:entry(job)
    local b = current_border

    -- Get terminal dimensions
    local area = job.area

    -- ── Outer border ──────────────────────────────────────────────────────
    -- Top border line with rounded corners
    job:push({
        -- Top-left corner
        ui.Paragraph({
            ui.Line({
                ui.Span(b.top_left):fg(color_border),

                -- Top border (full width minus corners)
                ui.Span(b.horizontal:rep(area.w - 2)):fg(color_border),

                -- Top-right corner
                ui.Span(b.top_right):fg(color_border),
            })
        })
        :area(ui.Rect({ x = 0, y = 0, w = area.w, h = 1 })),

        -- Left border (full height)
        ui.Paragraph({
            ui.Line({ ui.Span(b.vertical):fg(color_border) })
        })
        :area(ui.Rect({ x = 0, y = 1, w = 1, h = area.h - 2 })),

        -- Right border (full height)
        ui.Paragraph({
            ui.Line({ ui.Span(b.vertical):fg(color_border) })
        })
        :area(ui.Rect({ x = area.w - 1, y = 1, w = 1, h = area.h - 2 })),

        -- Bottom border
        ui.Paragraph({
            ui.Line({
                ui.Span(b.bottom_left):fg(color_border),
                ui.Span(b.horizontal:rep(area.w - 2)):fg(color_border),
                ui.Span(b.bottom_right):fg(color_border),
            })
        })
        :area(ui.Rect({ x = 0, y = area.h - 1, w = area.w, h = 1 })),
    })

    -- ── Panel dividers ────────────────────────────────────────────────────
    -- Get panel positions from manager layout
    -- (approximated — full layout access requires yazi 0.3.3+)
    local w = area.w - 2  -- Inner width (minus borders)
    local h = area.h - 2  -- Inner height (minus borders)

    -- Calculate panel widths based on ratio [1, 2, 2]
    -- Default ratio: parent=20%, current=40%, preview=40%
    local ratio_total = 5  -- 1 + 2 + 2
    local parent_w  = math.floor(w * 1 / ratio_total)
    local current_w = math.floor(w * 2 / ratio_total)
    -- preview_w = remaining

    local divider1_x = 1 + parent_w   -- After parent panel
    local divider2_x = divider1_x + current_w  -- After current panel

    -- Draw vertical panel dividers
    for _, div_x in ipairs({ divider1_x, divider2_x }) do
        if div_x > 1 and div_x < area.w - 1 then
            -- Top tee junction
            job:push({
                ui.Paragraph({
                    ui.Line({ ui.Span(b.top_tee):fg(color_border) })
                })
                :area(ui.Rect({ x = div_x, y = 0, w = 1, h = 1 })),

                -- Vertical divider line
                ui.Paragraph(
                    (function()
                        local lines = {}
                        for _ = 1, h do
                            table.insert(lines, ui.Line({
                                ui.Span(b.vertical):fg(color_border)
                            }))
                        end
                        return lines
                    end)()
                )
                :area(ui.Rect({ x = div_x, y = 1, w = 1, h = h })),

                -- Bottom tee junction
                ui.Paragraph({
                    ui.Line({ ui.Span(b.bottom_tee):fg(color_border) })
                })
                :area(ui.Rect({ x = div_x, y = area.h - 1, w = 1, h = 1 })),
            })
        end
    end

    -- ── Panel labels in top border ─────────────────────────────────────────

    -- Get current directory name (truncated)
    local cwd      = tostring(cx.active.current.url)
    local cwd_name = cwd:match("([^/]+)$") or cwd
    if #cwd_name > 20 then
        cwd_name = "…" .. cwd_name:sub(-18)
    end

    -- Parent label
    local parent_label = string.format(" %s Parent ", panel_icons.parent)
    local cur_label    = string.format(" %s %s ", panel_icons.current, cwd_name)
    local prev_label   = string.format(" %s Preview ", panel_icons.preview)

    -- Render panel labels into the top border line
    local parent_label_x  = 2  -- After top-left corner + 1 space
    local current_label_x = divider1_x + 1
    local preview_label_x = divider2_x + 1

    -- Parent label
    job:push({
        ui.Paragraph({
            ui.Line({
                ui.Span(parent_label)
                    :fg(color_dim)
                    :dim()
            })
        })
        :area(ui.Rect({
            x = parent_label_x,
            y = 0,
            w = math.min(#parent_label, parent_w - 2),
            h = 1
        })),

        -- Current directory label (highlighted — active panel)
        ui.Paragraph({
            ui.Line({
                ui.Span(cur_label)
                    :fg(color_title)
                    :bold()
            })
        })
        :area(ui.Rect({
            x = current_label_x,
            y = 0,
            w = math.min(#cur_label, current_w - 2),
            h = 1
        })),

        -- Preview label
        ui.Paragraph({
            ui.Line({
                ui.Span(prev_label)
                    :fg(color_dim)
                    :dim()
            })
        })
        :area(ui.Rect({
            x = preview_label_x,
            y = 0,
            w = math.min(#prev_label, area.w - divider2_x - 4),
            h = 1
        })),
    })

    -- ── Bottom status decorations ─────────────────────────────────────────

    -- Tab bar labels in bottom border
    local tab_count = #cx.tabs
    if tab_count > 1 then
        local tabs_str = string.format(" 󰓩 %d tabs ", tab_count)
        job:push({
            ui.Paragraph({
                ui.Line({
                    ui.Span(tabs_str):fg(color_icon)
                })
            })
            :area(ui.Rect({
                x = area.w - #tabs_str - 3,
                y = area.h - 1,
                w = #tabs_str,
                h = 1
            }))
        })
    end

    -- ASH mode indicator
    local ash_mode = os.getenv("ASH_MODE") or ""
    if ash_mode ~= "" and ash_mode ~= "default" then
        local mode_str = string.format(" ✦ %s ", ash_mode)
        job:push({
            ui.Paragraph({
                ui.Line({
                    ui.Span(mode_str):fg(color_title)
                })
            })
            :area(ui.Rect({
                x = 2,
                y = area.h - 1,
                w = #mode_str,
                h = 1
            }))
        })
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  SETUP — Initialize plugin
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

--- @param opts table  Plugin options
function M:setup(opts)
    opts = opts or {}

    -- Override border style
    if opts.style and borders[opts.style] then
        current_border = borders[opts.style]
    end

    -- Override colors from ASH theme engine
    if opts.border_color then
        color_border = ui.Color.from_hex(opts.border_color)
    end
    if opts.title_color then
        color_title = ui.Color.from_hex(opts.title_color)
    end

    -- Register as a render plugin for the manager
    ps.sub_remote("cd", function()
        ya.app_emit("plugin", { name = "full-border", args = {} })
    end)
end

return M