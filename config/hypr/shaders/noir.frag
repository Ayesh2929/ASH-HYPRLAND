// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  ASH DOTFILES v5.0 OMEGA — Noir / High-Contrast B&W Shader                  ║
// ║                                                                              ║
// ║  Film noir aesthetic: extreme contrast, deep shadows, bright highlights,   ║
// ║  silver halide grain, dramatic vignette, and selective tone mapping        ║
// ║  for a cinematic black-and-white look.                                      ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

precision highp float;

uniform sampler2D tex;
uniform float     time;
varying vec2      v_texcoord;

// ══════════════════════════════════════════════════════════════════════════════
// §01  CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════════

// Contrast boost (1.0 = standard, 1.5 = high contrast, 2.5 = extreme noir)
const float CONTRAST        = 1.80;

// Shadow crush: values below this threshold go to pure black
// (0.0 = no crush, 0.15 = noticeable, 0.30 = heavy)
const float SHADOW_CRUSH    = 0.12;

// Highlight boost: whites are expanded toward pure white
const float HIGHLIGHT_BOOST = 0.08;

// Film grain intensity
const float GRAIN           = 0.035;

// Vignette strength
const float VIGNETTE        = 0.65;

// Tone curve midpoint shift (negative = darker, positive = lighter)
const float MIDTONE_SHIFT   = -0.05;

// Silver halide blue-tint in shadows (classic film B&W look)
const float SILVER_TINT     = 0.08;

// Blend with original (0.0 = pure B&W, 1.0 = original color)
const float COLOR_BLEND     = 0.0;

// ══════════════════════════════════════════════════════════════════════════════
// §02  TONE CURVE (S-CURVE FOR CONTRAST)
// ══════════════════════════════════════════════════════════════════════════════

float sCurve(float t, float contrast) {
    // Parameterized S-curve using smoothstep
    t = clamp(t, 0.0, 1.0);
    float a = 0.5 - 0.5 / contrast;
    float b = 0.5 + 0.5 / contrast;
    return smoothstep(a, b, t);
}

// ══════════════════════════════════════════════════════════════════════════════
// §03  GRAIN
// ══════════════════════════════════════════════════════════════════════════════

float noirGrain(vec2 uv) {
    vec2 p = fract(uv * vec2(543.21, 876.54));
    p *= p + 32.1;
    return (fract(p.x * p.y * 78.9) - 0.5) * 2.0;
}

// ══════════════════════════════════════════════════════════════════════════════
// §04  VIGNETTE
// ══════════════════════════════════════════════════════════════════════════════

float noirVignette(vec2 uv) {
    vec2 d  = (uv - 0.5) * vec2(1.6, 1.0);  // Aspect correction
    float r = length(d);
    return 1.0 - VIGNETTE * pow(r * 1.4, 2.5);
}

// ══════════════════════════════════════════════════════════════════════════════
// §05  MAIN SHADER
// ══════════════════════════════════════════════════════════════════════════════

void main() {
    vec4 tex_color = texture2D(tex, v_texcoord);
    vec3 color     = tex_color.rgb;

    // ── Compute luminance (Rec. 709) ──────────────────────────────────────────
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));

    // ── Apply S-curve contrast ────────────────────────────────────────────────
    float curved = sCurve(luma + MIDTONE_SHIFT, CONTRAST);

    // ── Shadow crush: deep blacks ─────────────────────────────────────────────
    curved = smoothstep(SHADOW_CRUSH, 1.0, curved);

    // ── Highlight expansion ────────────────────────────────────────────────────
    curved = min(curved + curved * HIGHLIGHT_BOOST, 1.0);

    // ── Silver tint in shadows (blue-bias in dark areas) ─────────────────────
    vec3 noirColor = vec3(curved);
    float shadowMask = 1.0 - smoothstep(0.0, 0.35, curved);
    noirColor.b += shadowMask * SILVER_TINT;
    noirColor   = clamp(noirColor, 0.0, 1.0);

    // ── Film grain ────────────────────────────────────────────────────────────
    // More grain in midtones (Gaussian weighting)
    float grainMask = 4.0 * curved * (1.0 - curved);
    float grain     = noirGrain(v_texcoord + vec2(floor(time * 60.0))) * GRAIN * grainMask;
    noirColor      += vec3(grain);

    // ── Vignette ──────────────────────────────────────────────────────────────
    noirColor      *= noirVignette(v_texcoord);

    // ── Blend with original color ─────────────────────────────────────────────
    vec3 result     = mix(noirColor, color, COLOR_BLEND);

    gl_FragColor = vec4(clamp(result, 0.0, 1.0), tex_color.a);
}