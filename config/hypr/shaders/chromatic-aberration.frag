// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  ASH DOTFILES v5.0 OMEGA — Chromatic Aberration Shader                      ║
// ║                                                                              ║
// ║  Simulates lens chromatic aberration: RGB channels split toward edges,     ║
// ║  center is clean. Radial fringe pattern with controllable intensity,       ║
// ║  direction and channel-specific offset for realistic lens simulation.       ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

precision highp float;

uniform sampler2D tex;
uniform float     time;
varying vec2      v_texcoord;

// ══════════════════════════════════════════════════════════════════════════════
// §01  CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════════

// Maximum aberration at screen edges (in UV units)
// 0.002 = subtle  │  0.006 = visible  │  0.012 = dramatic
const float MAX_OFFSET      = 0.004;

// Power curve: higher = aberration concentrated at edges, 1.0 = linear
const float EDGE_POWER      = 2.5;

// Per-channel offset multiplier (asymmetric for realism)
const vec2  R_OFFSET        = vec2( 1.0,  0.8);   // Red channel
const vec2  G_OFFSET        = vec2( 0.0,  0.0);   // Green (reference)
const vec2  B_OFFSET        = vec2(-1.0, -0.8);   // Blue channel

// Angle of aberration axis (degrees, 0 = horizontal, 45 = diagonal)
const float ANGLE           = 0.0;

// Enable animated time-based subtle shimmer
const bool  ANIMATE         = false;
const float ANIMATE_SPEED   = 0.3;
const float ANIMATE_AMOUNT  = 0.15;

// ══════════════════════════════════════════════════════════════════════════════
// §02  RADIAL OFFSET COMPUTATION
// ══════════════════════════════════════════════════════════════════════════════

vec2 radialOffset(vec2 uv, float radius, float power) {
    // Distance from center (0.0 at center, ~0.707 at corner)
    vec2 dir   = uv - 0.5;
    float dist = length(dir);

    // Apply power curve (aberration grows faster toward edges)
    float strength = pow(dist * 2.0, power);

    return normalize(dir + 0.0001) * strength * radius;
}

// ══════════════════════════════════════════════════════════════════════════════
// §03  ANGLE ROTATION
// ══════════════════════════════════════════════════════════════════════════════

vec2 rotate2D(vec2 v, float angleDeg) {
    float a = radians(angleDeg);
    float s = sin(a), c = cos(a);
    return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

// ══════════════════════════════════════════════════════════════════════════════
// §04  MAIN SHADER
// ══════════════════════════════════════════════════════════════════════════════

void main() {
    vec2 uv = v_texcoord;

    // ── Compute radial offset vector ──────────────────────────────────────────
    vec2 offset = radialOffset(uv, MAX_OFFSET, EDGE_POWER);

    // ── Apply angle rotation ──────────────────────────────────────────────────
    if (abs(ANGLE) > 0.1) {
        offset = rotate2D(offset, ANGLE);
    }

    // ── Animated shimmer ──────────────────────────────────────────────────────
    float anim = 1.0;
    if (ANIMATE) {
        anim = 1.0 + sin(time * ANIMATE_SPEED * 6.28318) * ANIMATE_AMOUNT;
    }

    // ── Per-channel UV coordinates ────────────────────────────────────────────
    vec2 uvR = uv + offset * R_OFFSET * anim;
    vec2 uvG = uv + offset * G_OFFSET;           // Green = center reference
    vec2 uvB = uv + offset * B_OFFSET * anim;

    // ── Sample each channel from offset UV ────────────────────────────────────
    float r  = texture2D(tex, clamp(uvR, 0.0, 1.0)).r;
    float g  = texture2D(tex, clamp(uvG, 0.0, 1.0)).g;
    float b  = texture2D(tex, clamp(uvB, 0.0, 1.0)).b;
    float a  = texture2D(tex, uv).a;

    gl_FragColor = vec4(r, g, b, a);
}