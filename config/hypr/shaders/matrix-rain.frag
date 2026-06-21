// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  ASH DOTFILES v5.0 OMEGA — Matrix Rain Screen Shader                        ║
// ║                                                                              ║
// ║  Overlays an animated digital rain effect on the compositor output.        ║
// ║  Falling columns of glowing green "characters" over the live desktop.      ║
// ║  Features: column speed variation, head glow, trail fade, density          ║
// ║  control and blending mode for underlying content visibility.              ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

precision highp float;

uniform sampler2D tex;
uniform float     time;
varying vec2      v_texcoord;

// ══════════════════════════════════════════════════════════════════════════════
// §01  CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════════

// Overlay opacity (0.0 = invisible, 0.6 = balanced, 1.0 = full rain)
const float RAIN_OPACITY    = 0.55;

// Character grid density (columns per screen width)
const float COLUMNS         = 80.0;

// Fall speed (1.0 = normal, 2.0 = fast, 0.5 = slow)
const float SPEED           = 1.2;

// Trail length (higher = longer fading tail)
const float TRAIL_LENGTH    = 0.7;

// Head glow brightness (1.0 = white head, 0.0 = no bright head)
const float HEAD_GLOW       = 1.0;

// Rain color (classic matrix green)
const vec3  RAIN_COLOR      = vec3(0.063, 0.796, 0.063);  // #10CB10

// Bright head color (near-white green)
const vec3  HEAD_COLOR      = vec3(0.78, 1.00, 0.78);

// Underlying screen content visibility through the rain
const float SCREEN_VISIBLE  = 0.70;    // 1.0 = fully visible, 0.0 = obscured

// Color tint applied to the visible screen content
const vec3  SCREEN_TINT     = vec3(0.06, 0.20, 0.06);   // Green tint

// ══════════════════════════════════════════════════════════════════════════════
// §02  HASH FUNCTIONS
// ══════════════════════════════════════════════════════════════════════════════

float hash1(float n) {
    return fract(sin(n) * 43758.5453123);
}

float hash2(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

// ══════════════════════════════════════════════════════════════════════════════
// §03  COLUMN RAIN COMPUTATION
// ══════════════════════════════════════════════════════════════════════════════

// Returns brightness of the rain effect at given UV
// x = column brightness (character intensity)
// y = is_head (0 or 1 for head pixel highlight)
vec2 matrixColumn(vec2 uv) {
    // Column coordinate
    float col   = floor(uv.x * COLUMNS);

    // Per-column randomization
    float seed  = col * 0.1234;

    // Speed variation per column (-0.3 to +0.3 of base speed)
    float spd   = SPEED * (0.7 + hash1(seed + 0.5) * 0.6);

    // Column start offset (staggered across time)
    float offset = hash1(seed) * 10.0;

    // Current fall position (0.0 to 1.0 of screen height)
    float t     = mod(time * spd * 0.25 + offset, 1.4) - 0.2;

    // Distance below the head of this column's drop
    float dist  = uv.y - t;

    // Characters appear below the head, fade over trail length
    float brightness = 0.0;
    float is_head    = 0.0;

    if (dist >= 0.0 && dist < TRAIL_LENGTH) {
        // Exponential trail fade
        brightness = exp(-dist * (4.0 / TRAIL_LENGTH));

        // Flicker: characters twinkle randomly
        float flicker = hash2(vec2(col, floor(time * 15.0)));
        brightness   *= 0.7 + 0.3 * flicker;

        // Head detection (top ~3% of trail)
        if (dist < TRAIL_LENGTH * 0.03) {
            is_head = 1.0;
        }
    }

    // Multiple overlapping drops per column (density)
    float t2    = mod(time * spd * 0.25 + offset + 0.5, 1.4) - 0.2;
    float dist2 = uv.y - t2;
    if (dist2 >= 0.0 && dist2 < TRAIL_LENGTH) {
        float b2     = exp(-dist2 * (4.0 / TRAIL_LENGTH)) * 0.6;
        brightness   = max(brightness, b2);
        if (dist2 < TRAIL_LENGTH * 0.03) is_head = max(is_head, 0.8);
    }

    return vec2(brightness, is_head);
}

// ══════════════════════════════════════════════════════════════════════════════
// §04  CHARACTER CELL SHADING
//      Simulate individual character blocks within each column
// ══════════════════════════════════════════════════════════════════════════════

float characterCell(vec2 uv) {
    // Cell boundaries based on character grid
    float rows  = COLUMNS * (9.0 / 16.0);   // Approximate character aspect
    vec2  cell  = fract(uv * vec2(COLUMNS, rows));
    vec2  dist  = abs(cell - 0.5);

    // Character body (inner area of cell)
    float mask  = step(max(dist.x, dist.y), 0.45);

    // Add random character "shape" within cell
    float col   = floor(uv.x * COLUMNS);
    float row   = floor(uv.y * rows);
    float shape = hash2(vec2(col + floor(time * 3.0), row));

    // Binary character: some cells are "lit" based on hash
    float charMask = step(0.3, shape);

    return mask * charMask;
}

// ══════════════════════════════════════════════════════════════════════════════
// §05  MAIN SHADER
// ══════════════════════════════════════════════════════════════════════════════

void main() {
    vec2  uv        = v_texcoord;
    vec4  tex_color = texture2D(tex, uv);
    vec3  screen    = tex_color.rgb;

    // ── Compute rain effect ────────────────────────────────────────────────────
    vec2  rain      = matrixColumn(uv);
    float bright    = rain.x;
    float is_head   = rain.y;

    // ── Character cell mask ────────────────────────────────────────────────────
    float cell      = characterCell(uv);
    bright         *= cell;

    // ── Compose rain color ────────────────────────────────────────────────────
    vec3  rainColor = mix(RAIN_COLOR, HEAD_COLOR, is_head * HEAD_GLOW);
    rainColor      *= bright;

    // ── Ambient matrix glow (background green wash) ───────────────────────────
    float ambient   = 0.03;
    rainColor      += RAIN_COLOR * ambient;

    // ── Screen content processing ─────────────────────────────────────────────
    // Convert screen to grayscale with green tint for matrix aesthetic
    float screenLuma = dot(screen, vec3(0.2126, 0.7152, 0.0722));
    vec3  tintedScreen = mix(
        screen,
        screenLuma * SCREEN_TINT * 3.0,
        0.7
    );

    // ── Compose rain over screen content ─────────────────────────────────────
    // Screen is visible through the rain overlay
    vec3  result = mix(tintedScreen, tintedScreen + rainColor, RAIN_OPACITY);

    // Brighten areas under rain characters
    result += rainColor * RAIN_OPACITY * 0.5;

    // ── Overall green color grade ─────────────────────────────────────────────
    float luma   = dot(result, vec3(0.2126, 0.7152, 0.0722));
    result       = mix(result, luma * vec3(0.05, 0.80, 0.05), 0.25);

    // ── Scan-line effect (subtle, matches CRT terminal feel) ──────────────────
    float scanline = sin(uv.y * 1080.0 * 3.14159) * 0.5 + 0.5;
    result        *= 0.92 + 0.08 * scanline;

    // ── Edge vignette (terminal glow center) ──────────────────────────────────
    vec2  center   = uv - 0.5;
    float vign     = 1.0 - dot(center, center) * 0.8;
    result        *= clamp(vign, 0.6, 1.0);

    gl_FragColor = vec4(clamp(result, 0.0, 1.0), tex_color.a);
}