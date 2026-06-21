// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  ASH DOTFILES v5.0 OMEGA — Scanlines Shader                                 ║
// ║                                                                              ║
// ║  High-quality horizontal scanline overlay with controllable gap size,      ║
// ║  brightness compensation, optional interlacing simulation and              ║
// ║  subtle pixel brightness variation per-column (aperture grille effect).    ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

precision highp float;

uniform sampler2D tex;
uniform float     time;
varying vec2      v_texcoord;

// ══════════════════════════════════════════════════════════════════════════════
// §01  CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════════

// Lines per screen height (240 = classic CRT, 480 = HD-CRT, 1080 = dense)
const float LINE_COUNT      = 270.0;

// Gap darkness (0.0 = no gap, 1.0 = full black between lines)
const float GAP_DARKNESS    = 0.28;

// Scanline sharpness (1.0 = soft sine, 8.0 = sharp square-ish)
const float SHARPNESS       = 5.0;

// Brightness compensation (counteract overall darkening from gaps)
const float BRIGHTNESS_COMP = 1.18;

// Aperture grille simulation (vertical brightness variation, like Trinitron)
const bool  APERTURE_GRILLE = true;
const float GRILLE_STRENGTH = 0.08;

// Interlacing simulation (alternating field offset)
const bool  INTERLACE       = false;
const float INTERLACE_SPEED = 60.0;

// Horizontal scanline offset (for diamond/dot triad mask feel)
const float H_OFFSET        = 0.0;

// ══════════════════════════════════════════════════════════════════════════════
// §02  SCANLINE COMPUTATION
// ══════════════════════════════════════════════════════════════════════════════

float computeScanline(float y) {
    // Position within a single scanline (0.0 to 1.0 per line)
    float pos  = fract(y * LINE_COUNT);

    // Interlacing: alternate field on each frame
    if (INTERLACE) {
        float field = mod(floor(time * INTERLACE_SPEED), 2.0);
        pos = fract(y * LINE_COUNT + field * 0.5);
    }

    // Sine-based scanline with sharpness power
    float wave = sin(pos * 3.14159265);
    float line = pow(wave, SHARPNESS);

    // Map to [1-GAP_DARKNESS, 1.0] range
    return mix(1.0 - GAP_DARKNESS, 1.0, line);
}

// ══════════════════════════════════════════════════════════════════════════════
// §03  APERTURE GRILLE (vertical pixel columns)
// ══════════════════════════════════════════════════════════════════════════════

float apertureGrille(float x) {
    if (!APERTURE_GRILLE) return 1.0;

    // Trinitron-like vertical stripe pattern (3 colors per triad)
    float pos   = fract(x * 1920.0 / 3.0);
    float phase = sin(pos * 6.28318);

    return 1.0 + phase * GRILLE_STRENGTH;
}

// ══════════════════════════════════════════════════════════════════════════════
// §04  MAIN SHADER
// ══════════════════════════════════════════════════════════════════════════════

void main() {
    vec2  uv        = v_texcoord;
    vec4  tex_color = texture2D(tex, uv);
    vec3  color     = tex_color.rgb;

    // ── Compute scanline factor ────────────────────────────────────────────────
    float sl        = computeScanline(uv.y + H_OFFSET);

    // ── Aperture grille ────────────────────────────────────────────────────────
    float grille    = apertureGrille(uv.x);

    // ── Apply scanline effect ─────────────────────────────────────────────────
    color          *= sl * grille * BRIGHTNESS_COMP;

    gl_FragColor = vec4(clamp(color, 0.0, 1.0), tex_color.a);
}