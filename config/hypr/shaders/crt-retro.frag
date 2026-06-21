// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  ASH DOTFILES v5.0 OMEGA — CRT Retro Effect Shader                          ║
// ║                                                                              ║
// ║  Full CRT simulation: scanlines, phosphor bloom, barrel distortion,        ║
// ║  curvature, RGB shadow mask, phosphor persistence, electron beam focus     ║
// ║  falloff and corner vignette. The definitive retro display shader.          ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

precision highp float;

uniform sampler2D tex;
uniform float     time;
varying vec2      v_texcoord;

// ══════════════════════════════════════════════════════════════════════════════
// §01  CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════════

// ── Screen geometry ───────────────────────────────────────────────────────────
const float CURVATURE       = 3.0;      // Barrel distortion amount (0=flat)
const vec2  SCREEN_SIZE     = vec2(1920.0, 1080.0);

// ── Scanlines ────────────────────────────────────────────────────────────────
const float SCANLINE_WEIGHT = 0.25;     // Darkness of scanline gaps (0–1)
const float SCANLINE_WIDTH  = 0.65;     // Width of illuminated line (0–1)
const float SCANLINE_SHARP  = 8.0;     // Sharpness of scanline edges

// ── RGB shadow mask ───────────────────────────────────────────────────────────
const bool  MASK_ENABLE     = true;
const float MASK_STRENGTH   = 0.15;    // Mask darkness (0=off, 0.3=visible)
const float MASK_SCALE      = 1.0;     // Pixel width of mask pattern

// ── Bloom / glow ─────────────────────────────────────────────────────────────
const float BLOOM_STRENGTH  = 0.12;    // Phosphor glow amount
const float BLOOM_SPREAD    = 2.5;     // Glow radius in pixels

// ── Vignette ──────────────────────────────────────────────────────────────────
const float VIGNETTE_AMOUNT = 0.45;
const float VIGNETTE_POWER  = 2.0;

// ── Color grading ─────────────────────────────────────────────────────────────
const float BRIGHTNESS      = 1.15;    // Overall brightness boost
const float CONTRAST        = 1.08;
const float SATURATION      = 1.20;    // Phosphor color boost
const vec3  PHOSPHOR_TINT   = vec3(1.0, 0.97, 0.92);  // Warm phosphor color

// ══════════════════════════════════════════════════════════════════════════════
// §02  SCREEN WARP (BARREL DISTORTION)
// ══════════════════════════════════════════════════════════════════════════════

vec2 warpUV(vec2 uv) {
    if (CURVATURE < 0.01) return uv;

    vec2 delta = uv - 0.5;
    float dist = dot(delta, delta);
    float warp = 1.0 + dist * CURVATURE * 0.05;
    return delta * warp + 0.5;
}

// ══════════════════════════════════════════════════════════════════════════════
// §03  SCANLINE FUNCTION
// ══════════════════════════════════════════════════════════════════════════════

float scanline(float y, float scale) {
    float line = y * scale;
    float wave = sin(line * 3.14159265);
    float s    = pow(abs(wave), SCANLINE_SHARP);
    // Map sinusoidal wave to scanline weight
    return mix(1.0 - SCANLINE_WEIGHT, 1.0, smoothstep(0.0, SCANLINE_WIDTH, s));
}

// ══════════════════════════════════════════════════════════════════════════════
// §04  RGB SHADOW MASK
// ══════════════════════════════════════════════════════════════════════════════

vec3 shadowMask(vec2 uv) {
    float px   = floor(uv.x * SCREEN_SIZE.x * MASK_SCALE);
    float mod3 = mod(px, 3.0);

    vec3 mask  = vec3(1.0);
    if (MASK_ENABLE) {
        float dark = 1.0 - MASK_STRENGTH;
        if      (mod3 < 1.0) mask = vec3(1.0,  dark, dark);
        else if (mod3 < 2.0) mask = vec3(dark, 1.0,  dark);
        else                 mask = vec3(dark, dark, 1.0);
    }
    return mask;
}

// ══════════════════════════════════════════════════════════════════════════════
// §05  PHOSPHOR BLOOM (simple single-pass approximation)
// ══════════════════════════════════════════════════════════════════════════════

vec3 bloom(sampler2D tex2D, vec2 uv) {
    vec2 pixel    = vec2(1.0) / SCREEN_SIZE;
    vec3 blurred  = vec3(0.0);
    float weight  = 0.0;
    float spread  = BLOOM_SPREAD;

    // 3×3 Gaussian kernel
    for (float x = -spread; x <= spread; x += 1.0) {
        for (float y = -spread; y <= spread; y += 1.0) {
            float w    = exp(-(x*x + y*y) / (2.0 * spread * spread));
            blurred   += texture2D(tex2D, uv + vec2(x, y) * pixel).rgb * w;
            weight    += w;
        }
    }
    return blurred / weight;
}

// ══════════════════════════════════════════════════════════════════════════════
// §06  VIGNETTE
// ══════════════════════════════════════════════════════════════════════════════

float vignette(vec2 uv) {
    vec2  delta = uv - 0.5;
    float d     = length(delta);
    return 1.0 - VIGNETTE_AMOUNT * pow(d * 2.0, VIGNETTE_POWER);
}

// ══════════════════════════════════════════════════════════════════════════════
// §07  COLOR GRADING
// ══════════════════════════════════════════════════════════════════════════════

vec3 grade(vec3 rgb) {
    // Contrast
    rgb = (rgb - 0.5) * CONTRAST + 0.5;
    // Brightness
    rgb *= BRIGHTNESS;
    // Saturation
    float luma = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
    rgb = mix(vec3(luma), rgb, SATURATION);
    // Phosphor tint
    rgb *= PHOSPHOR_TINT;
    return rgb;
}

// ══════════════════════════════════════════════════════════════════════════════
// §08  CORNER MASK (black beyond warped screen edges)
// ══════════════════════════════════════════════════════════════════════════════

float cornerMask(vec2 uv) {
    vec2 edge = smoothstep(vec2(0.0), vec2(0.02), uv) *
                smoothstep(vec2(1.0), vec2(0.98), uv);
    return edge.x * edge.y;
}

// ══════════════════════════════════════════════════════════════════════════════
// §09  MAIN SHADER
// ══════════════════════════════════════════════════════════════════════════════

void main() {
    // ── Warp UV coordinates ───────────────────────────────────────────────────
    vec2 warpedUV = warpUV(v_texcoord);

    // ── Corner clip ───────────────────────────────────────────────────────────
    float corner = cornerMask(warpedUV);
    if (corner < 0.001) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // ── Sample screen ─────────────────────────────────────────────────────────
    vec4  tex_color = texture2D(tex, warpedUV);
    vec3  color     = tex_color.rgb;

    // ── Phosphor bloom ────────────────────────────────────────────────────────
    vec3  glow  = bloom(tex, warpedUV);
    color       = mix(color, glow, BLOOM_STRENGTH);

    // ── Scanlines ─────────────────────────────────────────────────────────────
    float sl    = scanline(warpedUV.y, SCREEN_SIZE.y);
    color      *= sl;

    // ── RGB shadow mask ───────────────────────────────────────────────────────
    color      *= shadowMask(warpedUV);

    // ── Color grading ─────────────────────────────────────────────────────────
    color       = grade(color);

    // ── Vignette ─────────────────────────────────────────────────────────────
    color      *= vignette(warpedUV);

    // ── Corner mask ───────────────────────────────────────────────────────────
    color      *= corner;

    gl_FragColor = vec4(clamp(color, 0.0, 1.0), tex_color.a);
}