// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  ASH DOTFILES v5.0 OMEGA — Film Grain Shader                                ║
// ║                                                                              ║
// ║  Analog film grain simulation with temporal animation (grain changes       ║
// ║  each frame), luminance-weighted grain (more grain in midtones),          ║
// ║  separate chroma/luma noise, and grain size control.                       ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

precision highp float;

uniform sampler2D tex;
uniform float     time;
varying vec2      v_texcoord;

// ══════════════════════════════════════════════════════════════════════════════
// §01  CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════════

// Overall grain intensity (0.0 = off, 0.05 = subtle, 0.12 = film-like, 0.25 = heavy)
const float INTENSITY       = 0.045;

// Luminance weighting: grain is strongest at this luminance (0.5 = midtones)
const float LUMA_PEAK       = 0.50;
const float LUMA_WIDTH      = 0.45;   // Width of grain peak (higher = more uniform)

// Grain size in pixels (1.0 = per-pixel, 2.0 = 2px grain clusters)
const float GRAIN_SIZE      = 1.0;

// Chromatic grain: adds color noise alongside luminance noise
const float CHROMA_AMOUNT   = 0.30;   // 0.0 = B&W grain, 1.0 = full color grain

// Temporal animation: grain changes between frames using time
const bool  ANIMATE         = true;
const float ANIM_SPEED      = 90.0;   // Frame-equivalent speed

// Grain distribution: 0 = uniform, 1 = gaussian approximation
const int   DISTRIBUTION    = 1;

// ══════════════════════════════════════════════════════════════════════════════
// §02  NOISE FUNCTIONS
// ══════════════════════════════════════════════════════════════════════════════

// High-quality hash function (Inigo Quilez)
float hash(vec2 p) {
    p  = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

// Box-Muller transform: uniform → Gaussian noise
vec2 gaussianNoise(vec2 seed) {
    float u1 = hash(seed);
    float u2 = hash(seed + vec2(0.1, 0.7));
    u1 = max(u1, 0.0001);    // Prevent log(0)

    float r   = sqrt(-2.0 * log(u1));
    float phi = 6.28318530718 * u2;
    return vec2(r * cos(phi), r * sin(phi));
}

// ══════════════════════════════════════════════════════════════════════════════
// §03  LUMINANCE-WEIGHTED GRAIN MASK
// ══════════════════════════════════════════════════════════════════════════════

float grainMask(float luma) {
    // Gaussian distribution centered on LUMA_PEAK
    // Grain is strongest in midtones, weaker in highlights and shadows
    float diff = luma - LUMA_PEAK;
    return exp(-(diff * diff) / (2.0 * LUMA_WIDTH * LUMA_WIDTH));
}

// ══════════════════════════════════════════════════════════════════════════════
// §04  MAIN SHADER
// ══════════════════════════════════════════════════════════════════════════════

void main() {
    vec4 tex_color = texture2D(tex, v_texcoord);
    vec3 color     = tex_color.rgb;

    // ── Compute pixel seed for noise ──────────────────────────────────────────
    vec2 pixel_uv = floor(v_texcoord * vec2(1920.0, 1080.0) / GRAIN_SIZE) / GRAIN_SIZE;

    // ── Temporal variation: different grain each "frame" ─────────────────────
    float frame_seed = 0.0;
    if (ANIMATE) {
        frame_seed = floor(time * ANIM_SPEED);
    }

    vec2 seed = pixel_uv + vec2(frame_seed * 0.6180339887);

    // ── Generate noise ────────────────────────────────────────────────────────
    float noise_luma;
    vec2  noise_chroma;

    if (DISTRIBUTION == 1) {
        // Gaussian distribution (more realistic film grain)
        vec2 g     = gaussianNoise(seed) * 0.5;  // ~[-1,1] range
        noise_luma = g.x;
        noise_chroma = vec2(
            gaussianNoise(seed + vec2(1.3, 2.1)).x,
            gaussianNoise(seed + vec2(3.7, 0.9)).x
        ) * 0.5;
    } else {
        // Uniform distribution
        noise_luma   = (hash(seed) - 0.5) * 2.0;
        noise_chroma = vec2(
            (hash(seed + vec2(0.3, 0.7)) - 0.5) * 2.0,
            (hash(seed + vec2(0.8, 0.2)) - 0.5) * 2.0
        );
    }

    // ── Luminance-weighted mask ───────────────────────────────────────────────
    float luma    = dot(color, vec3(0.2126, 0.7152, 0.0722));
    float mask    = grainMask(luma);

    // ── Apply luminance grain ─────────────────────────────────────────────────
    float grain   = noise_luma * INTENSITY * mask;
    vec3 result   = color + vec3(grain);

    // ── Apply chromatic grain ─────────────────────────────────────────────────
    float chroma  = INTENSITY * CHROMA_AMOUNT * mask;
    result.r     += noise_chroma.x * chroma;
    result.b     += noise_chroma.y * chroma;
    // Green channel gets less chroma noise (human eye more sensitive to green)
    result.g     += (noise_chroma.x + noise_chroma.y) * 0.5 * chroma * 0.4;

    gl_FragColor = vec4(clamp(result, 0.0, 1.0), tex_color.a);
}