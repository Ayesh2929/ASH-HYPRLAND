// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  ASH DOTFILES v5.0 OMEGA — Vignette Shader                                  ║
// ║                                                                              ║
// ║  Darkens screen edges with configurable shape, color, softness and         ║
// ║  aspect-ratio correction. Supports elliptical, radial and rectangular      ║
// ║  vignette modes with optional animated breathing effect.                    ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

precision highp float;

uniform sampler2D tex;
uniform float     time;
varying vec2      v_texcoord;

// ══════════════════════════════════════════════════════════════════════════════
// §01  CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════════

// Overall vignette strength (0.0 = off, 1.0 = full black edges)
const float STRENGTH        = 0.55;

// How far from center vignette starts (0.0 = center, 1.0 = very edge)
const float INNER_RADIUS    = 0.45;

// Outer radius (where vignette reaches full darkness)
const float OUTER_RADIUS    = 1.20;

// Vignette color (vec3(0) = black, vec3(1) = white, other = tinted)
const vec3  VIGNETTE_COLOR  = vec3(0.0, 0.0, 0.0);

// Mode: 0 = circular/elliptical, 1 = rectangular (softer on sides)
const int   MODE            = 0;

// Aspect ratio compensation (match monitor aspect for circular vignette)
const float ASPECT          = 1.777;   // 16:9 = 1.777, 16:10 = 1.6

// Roundness for rectangular mode (0.0 = sharp corners, 1.0 = circular)
const float ROUNDNESS       = 0.5;

// Animated breathing (subtle pulsing effect)
const bool  BREATHE         = false;
const float BREATHE_SPEED   = 0.4;
const float BREATHE_AMOUNT  = 0.04;

// ══════════════════════════════════════════════════════════════════════════════
// §02  DISTANCE FUNCTIONS
// ══════════════════════════════════════════════════════════════════════════════

// Circular/elliptical distance from center
float circularDist(vec2 uv) {
    vec2 centered = (uv - 0.5) * vec2(ASPECT, 1.0);
    return length(centered);
}

// Rounded rectangle distance from center
float rectDist(vec2 uv, float r) {
    vec2 p   = abs(uv - 0.5) * vec2(ASPECT, 1.0);
    vec2 q   = p - vec2(INNER_RADIUS * 0.5) + r;
    return length(max(q, 0.0)) - r;
}

// ══════════════════════════════════════════════════════════════════════════════
// §03  MAIN SHADER
// ══════════════════════════════════════════════════════════════════════════════

void main() {
    vec4 tex_color = texture2D(tex, v_texcoord);
    vec3 color     = tex_color.rgb;

    // ── Compute distance from center ──────────────────────────────────────────
    float dist;
    if (MODE == 0) {
        dist = circularDist(v_texcoord);
    } else {
        dist = rectDist(v_texcoord, ROUNDNESS * 0.3) + INNER_RADIUS * 0.5;
    }

    // ── Animated breathing ─────────────────────────────────────────────────────
    float radius_inner = INNER_RADIUS;
    if (BREATHE) {
        float pulse = sin(time * BREATHE_SPEED * 6.28318) * BREATHE_AMOUNT;
        radius_inner += pulse;
    }

    // ── Compute vignette factor ────────────────────────────────────────────────
    // 0.0 = center (no vignette), 1.0 = full darkness
    float vig = smoothstep(radius_inner, OUTER_RADIUS, dist);
    vig       = pow(vig, 1.5);    // Slight power curve for softer falloff

    // ── Apply vignette ────────────────────────────────────────────────────────
    vec3 result = mix(color, VIGNETTE_COLOR, vig * STRENGTH);

    gl_FragColor = vec4(clamp(result, 0.0, 1.0), tex_color.a);
}