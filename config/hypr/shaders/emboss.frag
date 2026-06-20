// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  ASH DOTFILES v5.0 OMEGA — Emboss / Relief Shader                           ║
// ║                                                                              ║
// ║  3D relief emboss effect using directional convolution kernel.             ║
// ║  Supports colored emboss, controllable light direction, blend mode         ║
// ║  with original image, and edge-detection preview.                          ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

precision highp float;

uniform sampler2D tex;
uniform float     time;
varying vec2      v_texcoord;

// ══════════════════════════════════════════════════════════════════════════════
// §01  CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════════

// Screen resolution
const vec2  RESOLUTION      = vec2(1920.0, 1080.0);

// Light direction angle in degrees (0 = top-left, 45 = top, 90 = top-right)
const float LIGHT_ANGLE     = 45.0;

// Emboss depth/strength (1.0 = standard, 2.0 = exaggerated depth)
const float DEPTH           = 1.5;

// Blend with original image (0.0 = full emboss, 1.0 = full original)
const float BLEND_ORIGINAL  = 0.0;

// Emboss mode:
// 0 = grayscale emboss (classic)
// 1 = colored emboss (preserves original hues)
// 2 = edge detection only (Sobel filter preview)
const int   MODE            = 0;

// Grayscale bias (middle gray for flat areas)
const float GRAY_BIAS       = 0.5;

// Color tint for grayscale emboss (vec3(1) = neutral gray)
const vec3  EMBOSS_TINT     = vec3(1.0, 0.97, 0.90);  // Warm stone

// ══════════════════════════════════════════════════════════════════════════════
// §02  DIRECTIONAL EMBOSS KERNEL
// ══════════════════════════════════════════════════════════════════════════════

vec3 emboss(sampler2D sampler, vec2 uv, vec2 pixel, float angleDeg) {
    float angle = radians(angleDeg);
    vec2  dir   = vec2(cos(angle), -sin(angle));

    // Sample neighbors in light direction
    vec3  s0 = texture2D(sampler, uv - pixel * dir * 2.0).rgb;
    vec3  s1 = texture2D(sampler, uv - pixel * dir).rgb;
    vec3  s2 = texture2D(sampler, uv).rgb;
    vec3  s3 = texture2D(sampler, uv + pixel * dir).rgb;
    vec3  s4 = texture2D(sampler, uv + pixel * dir * 2.0).rgb;

    // Directional derivative (highlight toward light, shadow away)
    vec3  edge = (s4 - s0) * 0.25 + (s3 - s1) * 0.50;

    return edge;
}

// ══════════════════════════════════════════════════════════════════════════════
// §03  SOBEL EDGE DETECTION (for MODE == 2)
// ══════════════════════════════════════════════════════════════════════════════

float sobel(sampler2D sampler, vec2 uv, vec2 pixel) {
    float tl = dot(texture2D(sampler, uv + vec2(-1.0, -1.0) * pixel).rgb, vec3(0.2126, 0.7152, 0.0722));
    float tc = dot(texture2D(sampler, uv + vec2( 0.0, -1.0) * pixel).rgb, vec3(0.2126, 0.7152, 0.0722));
    float tr = dot(texture2D(sampler, uv + vec2( 1.0, -1.0) * pixel).rgb, vec3(0.2126, 0.7152, 0.0722));
    float ml = dot(texture2D(sampler, uv + vec2(-1.0,  0.0) * pixel).rgb, vec3(0.2126, 0.7152, 0.0722));
    float mr = dot(texture2D(sampler, uv + vec2( 1.0,  0.0) * pixel).rgb, vec3(0.2126, 0.7152, 0.0722));
    float bl = dot(texture2D(sampler, uv + vec2(-1.0,  1.0) * pixel).rgb, vec3(0.2126, 0.7152, 0.0722));
    float bc = dot(texture2D(sampler, uv + vec2( 0.0,  1.0) * pixel).rgb, vec3(0.2126, 0.7152, 0.0722));
    float br = dot(texture2D(sampler, uv + vec2( 1.0,  1.0) * pixel).rgb, vec3(0.2126, 0.7152, 0.0722));

    float gx = -tl - 2.0*ml - bl + tr + 2.0*mr + br;
    float gy = -tl - 2.0*tc - tr + bl + 2.0*bc + br;

    return sqrt(gx*gx + gy*gy);
}

// ══════════════════════════════════════════════════════════════════════════════
// §04  MAIN SHADER
// ══════════════════════════════════════════════════════════════════════════════

void main() {
    vec2  pixel     = 1.0 / RESOLUTION;
    vec4  tex_color = texture2D(tex, v_texcoord);
    vec3  original  = tex_color.rgb;
    vec3  result;

    if (MODE == 2) {
        // ── Sobel edge detection ───────────────────────────────────────────────
        float edge = sobel(tex, v_texcoord, pixel) * DEPTH;
        result     = vec3(clamp(edge, 0.0, 1.0));

    } else {
        // ── Emboss convolution ─────────────────────────────────────────────────
        vec3 edge   = emboss(tex, v_texcoord, pixel, LIGHT_ANGLE) * DEPTH;

        if (MODE == 1) {
            // ── Colored emboss ─────────────────────────────────────────────────
            float luma  = dot(original, vec3(0.2126, 0.7152, 0.0722));
            float bump  = dot(edge, vec3(0.2126, 0.7152, 0.0722));
            result      = original * (1.0 + bump);

        } else {
            // ── Grayscale emboss ───────────────────────────────────────────────
            float bump  = dot(edge, vec3(0.333));
            result      = vec3(clamp(GRAY_BIAS + bump, 0.0, 1.0)) * EMBOSS_TINT;
        }
    }

    // ── Blend with original image ─────────────────────────────────────────────
    result = mix(result, original, BLEND_ORIGINAL);

    gl_FragColor = vec4(clamp(result, 0.0, 1.0), tex_color.a);
}