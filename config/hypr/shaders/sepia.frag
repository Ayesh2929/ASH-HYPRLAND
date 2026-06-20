// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  ASH DOTFILES v5.0 OMEGA — Sepia Tone Shader                                ║
// ║                                                                              ║
// ║  Warm antique sepia tone with chemically-accurate color matrix,           ║
// ║  controllable warmth, partial application, optional vignette and           ║
// ║  aging effects including subtle noise and desaturation.                    ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

precision highp float;

uniform sampler2D tex;
uniform float     time;
varying vec2      v_texcoord;

// ══════════════════════════════════════════════════════════════════════════════
// §01  CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════════

// Sepia intensity (0.0 = original, 1.0 = full sepia)
const float AMOUNT          = 0.90;

// Warmth of the sepia tone (higher = more orange/amber)
const float WARMTH          = 1.0;   // 0.5 = cool sepia, 1.5 = warm amber

// Contrast adjustment
const float CONTRAST        = 1.05;

// Brightness adjustment
const float BRIGHTNESS      = 1.02;

// Sepia saturation (0.0 = pure grayscale, 1.0 = full sepia hue)
const float SEPIA_SAT       = 1.0;

// Add aging: subtle noise + slight edge darkening
const bool  AGING_EFFECT    = false;
const float AGING_STRENGTH  = 0.15;

// ══════════════════════════════════════════════════════════════════════════════
// §02  SEPIA COLOR MATRIX
//      Based on the chemical silver-sepia toning process color response
// ══════════════════════════════════════════════════════════════════════════════

vec3 applySepia(vec3 rgb, float warmth) {
    // Sepia matrix — approximates silver sulfide chemical toning
    // Warmth parameter shifts toward more amber tones
    float w = warmth;
    mat3 sepia = mat3(
        0.393 * w, 0.349,     0.272,      // Red output
        0.769 * w, 0.686,     0.534,      // Green output
        0.189 * w, 0.168,     0.131       // Blue output
    );

    // Convert to grayscale first, then apply sepia matrix
    float luma  = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3  gray  = vec3(luma);

    // Apply sepia matrix
    vec3 sepiaColor;
    sepiaColor.r = dot(gray, sepia[0]);
    sepiaColor.g = dot(gray, sepia[1]);
    sepiaColor.b = dot(gray, sepia[2]);

    // Blend between pure sepia and sepia-colored original
    return mix(sepiaColor, rgb * sepiaColor * 2.0, (1.0 - SEPIA_SAT) * 0.3);
}

// ══════════════════════════════════════════════════════════════════════════════
// §03  AGING NOISE
// ══════════════════════════════════════════════════════════════════════════════

float ageNoise(vec2 uv) {
    vec2 p = fract(uv * vec2(234.56, 567.89));
    p *= p + 45.23;
    return fract(p.x * p.y * 12.3456) * 2.0 - 1.0;
}

// ══════════════════════════════════════════════════════════════════════════════
// §04  MAIN SHADER
// ══════════════════════════════════════════════════════════════════════════════

void main() {
    vec4 tex_color = texture2D(tex, v_texcoord);
    vec3 color     = tex_color.rgb;

    // ── Apply contrast and brightness ─────────────────────────────────────────
    vec3 graded    = (color - 0.5) * CONTRAST + 0.5;
    graded        *= BRIGHTNESS;

    // ── Apply sepia tone ──────────────────────────────────────────────────────
    vec3 sepiaized = applySepia(graded, WARMTH);

    // ── Blend between original and sepia ──────────────────────────────────────
    vec3 result    = mix(graded, sepiaized, AMOUNT);

    // ── Optional aging effect ─────────────────────────────────────────────────
    if (AGING_EFFECT) {
        float noise  = ageNoise(v_texcoord) * AGING_STRENGTH * 0.05;
        result      += vec3(noise);

        // Slight edge darkening (old photo vignette)
        vec2  delta  = v_texcoord - 0.5;
        float vign   = 1.0 - dot(delta, delta) * AGING_STRENGTH * 2.0;
        result      *= vign;
    }

    gl_FragColor = vec4(clamp(result, 0.0, 1.0), tex_color.a);
}