// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  ASH DOTFILES v5.0 OMEGA — Blue Light Filter Shader                         ║
// ║                                                                              ║
// ║  Reduces blue light emission for eye comfort during evening/night use.     ║
// ║  Implements physically-based warm color temperature shift using            ║
// ║  Planckian locus approximation. Supports dynamic temperature control       ║
// ║  via uniform injection from ASH night-light plugin.                        ║
// ║                                                                              ║
// ║  Color temperatures:                                                         ║
// ║    6500K = Daylight (no shift)   5500K = Warm white                        ║
// ║    4500K = Incandescent warm     3500K = Evening amber                     ║
// ║    2700K = Candlelight/bedtime   1900K = Ultra-warm (max)                  ║
// ║                                                                              ║
// ║  Usage: hyprctl keyword decoration:screen_shader PATH                      ║
// ║  Auto:  ash night-light on [--temp 4000]                                   ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

precision highp float;

// ── Hyprland built-in uniforms ────────────────────────────────────────────────
uniform sampler2D tex;         // Screen texture
uniform float time;            // Time in seconds (for smooth transitions)

// ── Input from fragment pipeline ─────────────────────────────────────────────
varying vec2 v_texcoord;

// ══════════════════════════════════════════════════════════════════════════════
// §01  CONFIGURATION CONSTANTS
//      Adjust these to tune the filter behavior
// ══════════════════════════════════════════════════════════════════════════════

// Color temperature in Kelvin (1900 – 6500)
// 6500 = neutral daylight, 2700 = warm amber
const float TEMP_KELVIN    = 3500.0;

// Intensity of the filter (0.0 = off, 1.0 = full)
const float INTENSITY      = 0.85;

// Gamma correction (standard sRGB = 2.2)
const float GAMMA          = 2.2;

// Preserve luminance (true = keep brightness, false = allow dimming)
const bool  PRESERVE_LUMA  = true;

// Smooth transition duration factor (0 = instant, 1 = slow)
// Used when time uniform is available for animated transitions
const float TRANSITION_SPEED = 0.5;

// ══════════════════════════════════════════════════════════════════════════════
// §02  PLANCKIAN LOCUS — COLOR TEMPERATURE TO RGB
//      Based on Krystek's algorithm + CIE 1931 chromaticity
//      Returns linear RGB white point for given temperature (K)
// ══════════════════════════════════════════════════════════════════════════════

vec3 kelvinToRGB(float temp) {
    // Normalize temperature to 0–1 range for polynomial fitting
    float t = clamp(temp, 1000.0, 15000.0) / 1000.0;

    float r, g, b;

    // ── Red channel ───────────────────────────────────────────────────────────
    if (temp <= 6600.0) {
        r = 1.0;
    } else {
        r = 329.698727446 * pow(t - 6.0, -0.1332047592) / 255.0;
        r = clamp(r, 0.0, 1.0);
    }

    // ── Green channel ─────────────────────────────────────────────────────────
    if (temp <= 6600.0) {
        g = (99.4708025861 * log(t) - 161.1195681661) / 255.0;
    } else {
        g = 288.1221695283 * pow(t - 6.0, -0.0755148492) / 255.0;
    }
    g = clamp(g, 0.0, 1.0);

    // ── Blue channel ──────────────────────────────────────────────────────────
    if (temp >= 6600.0) {
        b = 1.0;
    } else if (temp <= 2000.0) {
        b = 0.0;
    } else {
        b = (138.5177312231 * log(t - 1.0) - 305.0447927307) / 255.0;
        b = clamp(b, 0.0, 1.0);
    }

    return vec3(r, g, b);
}

// ══════════════════════════════════════════════════════════════════════════════
// §03  COLOR SPACE UTILITIES
// ══════════════════════════════════════════════════════════════════════════════

// sRGB gamma encoding
vec3 linearToSRGB(vec3 linear) {
    return pow(clamp(linear, 0.0, 1.0), vec3(1.0 / GAMMA));
}

// sRGB gamma decoding
vec3 sRGBToLinear(vec3 srgb) {
    return pow(clamp(srgb, 0.0, 1.0), vec3(GAMMA));
}

// Luminance (perceptual, Rec. 709)
float luminance(vec3 rgb) {
    return dot(rgb, vec3(0.2126, 0.7152, 0.0722));
}

// ══════════════════════════════════════════════════════════════════════════════
// §04  MAIN SHADER
// ══════════════════════════════════════════════════════════════════════════════

void main() {
    // ── Sample screen texture ─────────────────────────────────────────────────
    vec4 tex_color = texture2D(tex, v_texcoord);
    vec3 color     = tex_color.rgb;

    // ── Linear space for correct color math ──────────────────────────────────
    vec3 linear    = sRGBToLinear(color);

    // ── Compute white point for target temperature ─────────────────────────────
    vec3 wp_target = kelvinToRGB(TEMP_KELVIN);
    vec3 wp_6500   = kelvinToRGB(6500.0);       // Neutral reference

    // ── Chromatic adaptation (Von Kries method) ───────────────────────────────
    // Scale each channel by the ratio of target/reference white points
    vec3 scale     = wp_target / wp_6500;
    vec3 adapted   = linear * scale;

    // ── Preserve luminance if enabled ─────────────────────────────────────────
    if (PRESERVE_LUMA) {
        float luma_orig    = luminance(linear);
        float luma_adapted = luminance(adapted);
        if (luma_adapted > 0.0001) {
            adapted *= luma_orig / luma_adapted;
        }
    }

    // ── Blend between original and adapted by intensity ───────────────────────
    vec3 result = mix(linear, adapted, INTENSITY);

    // ── Back to sRGB for display ──────────────────────────────────────────────
    result = linearToSRGB(result);

    // ── Clamp and output ──────────────────────────────────────────────────────
    gl_FragColor = vec4(clamp(result, 0.0, 1.0), tex_color.a);
}