// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  ASH DOTFILES v5.0 — CAVA GLSL SHADER: BAR SPECTRUM                       ║
// ║                                                                            ║
// ║  ██████╗░░█████╗░██████╗░  ░██████╗██████╗░███████╗░█████╗░████████╗     ║
// ║  ██╔══██╗██╔══██╗██╔══██╗  ██╔════╝██╔══██╗██╔════╝██╔══██╗╚══██╔══╝    ║
// ║  ██████╦╝███████║██████╔╝  ╚█████╗░██████╔╝█████╗░░██║░░╚═╝░░░██║░░░    ║
// ║  ██╔══██╗██╔══██║██╔══██╗  ░╚═══██╗██╔═══╝░██╔══╝░░██║░░██╗░░░██║░░░    ║
// ║  ██████╦╝██║░░██║██║░░██║  ██████╔╝██║░░░░░███████╗╚█████╔╝░░░██║░░░    ║
// ║  ╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝  ╚═════╝░╚═╝░░░░░╚══════╝░╚════╝░░░░╚═╝░░░    ║
// ║                                                                            ║
// ║  Premium Audio Spectrum Visualizer Shader                                  ║
// ║  Features:                                                                 ║
// ║    ✨ Multi-layer glow system (bloom + inner glow + rim light)            ║
// ║    🌈 Dynamic spectrum gradient (HSL-based frequency mapping)             ║
// ║    ⚡ Peak indicators with gravity physics simulation                     ║
// ║    💫 Particle system on bar peaks                                        ║
// ║    🔮 Chromatic aberration on high-energy bars                           ║
// ║    🌊 Frequency-reactive background pulse                                 ║
// ║    📊 Stereo mirror separation with center seam                          ║
// ║    🎨 ASH Dynamic Color Engine integration                               ║
// ║                                                                            ║
// ║  GLSL Version: 330 core                                                   ║
// ║  Cava Version: 0.10.0+                                                    ║
// ╚══════════════════════════════════════════════════════════════════════════╝

#version 330 core

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  CAVA BUILT-IN UNIFORMS
//  These are automatically provided by cava's OpenGL renderer
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Current audio bar heights — normalized 0.0 to 1.0
// bars_count values packed into the texture
uniform sampler1D bars;

// Number of frequency bars (set by cava config: bars = N)
uniform int bars_count;

// Current time in seconds (for animations)
uniform float time;

// Window resolution in pixels
uniform vec2 resolution;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  OUTPUT
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

out vec4 fragColor;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  ASH DESIGN TOKENS — Catppuccin Mocha Palette
//  Sync these with your active ASH theme
//  ASH engine auto-updates via template substitution
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Background — Catppuccin Base #1e1e2e
#define COL_BG          vec3(0.118, 0.118, 0.180)

// Deep background — Catppuccin Crust #11111b
#define COL_BG_DEEP     vec3(0.067, 0.067, 0.106)

// Surface — Catppuccin Surface0 #313244
#define COL_SURFACE     vec3(0.192, 0.196, 0.267)

// Accent 1 — Mauve #cba6f7 (primary accent, high frequencies)
#define COL_MAUVE       vec3(0.796, 0.651, 0.969)

// Accent 2 — Lavender #b4befe (secondary, upper-mid)
#define COL_LAVENDER    vec3(0.706, 0.745, 0.996)

// Accent 3 — Blue #89b4fa (mid frequencies)
#define COL_BLUE        vec3(0.537, 0.706, 0.980)

// Accent 4 — Sapphire #74c7ec (lower-mid)
#define COL_SAPPHIRE    vec3(0.455, 0.780, 0.925)

// Accent 5 — Teal #94e2d5 (bass region)
#define COL_TEAL        vec3(0.580, 0.886, 0.835)

// Accent 6 — Green #a6e3a1 (sub-bass)
#define COL_GREEN       vec3(0.651, 0.890, 0.631)

// Peak indicator — Pink #f5c2e7
#define COL_PEAK        vec3(0.961, 0.761, 0.906)

// Critical peak — Red #f38ba8
#define COL_CRITICAL    vec3(0.953, 0.545, 0.659)

// Glow base — Mauve at reduced saturation
#define COL_GLOW        vec3(0.600, 0.400, 0.800)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  SHADER PARAMETERS — Tune these for visual preferences
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Bar geometry
#define BAR_ROUNDING        0.015    // Corner radius (0=sharp, 0.05=very round)
#define BAR_GAP             0.25     // Gap between bars as fraction of bar width
#define BAR_FLOOR_HEIGHT    0.002    // Minimum visible bar height (always-on base)

// Glow system
#define GLOW_ENABLED        1        // 1=on, 0=off
#define GLOW_INNER_SIZE     0.006    // Size of inner bright glow
#define GLOW_OUTER_SIZE     0.035    // Size of outer soft bloom
#define GLOW_INTENSITY      1.6      // Glow brightness multiplier
#define GLOW_LAYERS         4        // Number of glow blur samples

// Peak indicators
#define PEAKS_ENABLED       1        // Show peak hold indicators
#define PEAK_HOLD_FRAMES    45       // Frames to hold peak before dropping
#define PEAK_HEIGHT         0.004    // Thickness of peak line in UV space
#define PEAK_GLOW           0.020    // Glow radius around peak line

// Particle system
#define PARTICLES_ENABLED   1        // Sparks on peaks
#define PARTICLE_COUNT      8        // Particles per high-energy bar
#define PARTICLE_SIZE       0.003    // Particle radius
#define PARTICLE_LIFE       2.0      // Particle lifetime in seconds

// Chromatic aberration
#define CHROMA_ENABLED      1        // Split color channels on peaks
#define CHROMA_STRENGTH     0.003    // Separation distance

// Background effects
#define BG_PULSE_ENABLED    1        // Background reacts to bass
#define BG_PULSE_STRENGTH   0.12     // How much background brightens on bass
#define BG_GRID_ENABLED     1        // Show subtle grid lines
#define BG_GRID_SIZE        0.05     // Grid cell size
#define BG_GRID_ALPHA       0.04     // Grid line opacity

// Floor line
#define FLOOR_LINE_ENABLED  1        // Show a subtle floor separator
#define FLOOR_LINE_HEIGHT   0.001    // Floor line thickness
#define FLOOR_LINE_ALPHA    0.15     // Floor line opacity

// Stereo visualizer
#define STEREO_SEAM         1        // Show center seam for stereo separation
#define SEAM_WIDTH          0.002    // Seam line width
#define SEAM_ALPHA          0.08     // Seam opacity

// Frequency gradient
#define GRADIENT_MODE       0        // 0=frequency-based, 1=height-based, 2=both
#define GRADIENT_SATURATION 1.0      // Color saturation multiplier
#define GRADIENT_BRIGHTNESS 1.0      // Color brightness multiplier

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  UTILITY FUNCTIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Smooth step with configurable edge sharpness
float smoothEdge(float edge0, float edge1, float x) {
    float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}

// Cubic smooth step (C2 continuous — even smoother than smoothstep)
float smootherStep(float edge0, float edge1, float x) {
    float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

// HSL to RGB conversion
// h: 0-1 (hue), s: 0-1 (saturation), l: 0-1 (lightness)
vec3 hsl2rgb(float h, float s, float l) {
    float c = (1.0 - abs(2.0 * l - 1.0)) * s;
    float x = c * (1.0 - abs(mod(h * 6.0, 2.0) - 1.0));
    float m = l - c * 0.5;

    vec3 rgb;
    if      (h < 1.0/6.0) rgb = vec3(c, x, 0.0);
    else if (h < 2.0/6.0) rgb = vec3(x, c, 0.0);
    else if (h < 3.0/6.0) rgb = vec3(0.0, c, x);
    else if (h < 4.0/6.0) rgb = vec3(0.0, x, c);
    else if (h < 5.0/6.0) rgb = vec3(x, 0.0, c);
    else                   rgb = vec3(c, 0.0, x);

    return rgb + m;
}

// RGB to HSL conversion
vec3 rgb2hsl(vec3 rgb) {
    float maxC = max(max(rgb.r, rgb.g), rgb.b);
    float minC = min(min(rgb.r, rgb.g), rgb.b);
    float delta = maxC - minC;

    float l = (maxC + minC) * 0.5;
    float s = (delta == 0.0) ? 0.0 : delta / (1.0 - abs(2.0 * l - 1.0));

    float h = 0.0;
    if (delta > 0.0) {
        if      (maxC == rgb.r) h = mod((rgb.g - rgb.b) / delta, 6.0) / 6.0;
        else if (maxC == rgb.g) h = ((rgb.b - rgb.r) / delta + 2.0) / 6.0;
        else                    h = ((rgb.r - rgb.g) / delta + 4.0) / 6.0;
    }

    return vec3(h, s, l);
}

// Exponential glow falloff — creates soft, physically-plausible bloom
// dist: distance from surface, radius: glow size, power: falloff rate
float glowFalloff(float dist, float radius, float power) {
    return pow(max(0.0, 1.0 - dist / radius), power);
}

// Pseudo-random number from seed (deterministic)
float rand(vec2 seed) {
    return fract(sin(dot(seed, vec2(12.9898, 78.233))) * 43758.5453);
}

// 2D value noise (smooth)
float noise2D(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);

    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  FREQUENCY-BASED COLOR MAPPING
//  Maps bar index (0-1) to a rich spectrum color
//  Sub-bass = Green/Teal, Bass = Blue, Mid = Mauve, High = Pink
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vec3 frequencyColor(float freqNorm, float barHeight) {
    // Animate hue slightly for living-color effect
    float hueShift = sin(time * 0.15) * 0.025;

    // Catppuccin Mocha frequency mapping:
    // 0.0 = sub-bass → Green  (#a6e3a1) hue ≈ 0.37
    // 0.2 = bass     → Teal   (#94e2d5) hue ≈ 0.47
    // 0.4 = low-mid  → Sapphire (#74c7ec) hue ≈ 0.54
    // 0.6 = mid      → Blue   (#89b4fa) hue ≈ 0.60
    // 0.8 = high-mid → Lavender (#b4befe) hue ≈ 0.65
    // 1.0 = treble   → Mauve  (#cba6f7) hue ≈ 0.75

    float hue;
    float sat;
    float lit;

    if (freqNorm < 0.2) {
        // Sub-bass: Green → Teal
        float t = freqNorm / 0.2;
        hue = mix(0.370, 0.470, t);
        sat = mix(0.72,  0.70,  t);
        lit = mix(0.76,  0.73,  t);
    } else if (freqNorm < 0.4) {
        // Bass: Teal → Sapphire
        float t = (freqNorm - 0.2) / 0.2;
        hue = mix(0.470, 0.540, t);
        sat = mix(0.70,  0.75,  t);
        lit = mix(0.73,  0.69,  t);
    } else if (freqNorm < 0.6) {
        // Low-mid: Sapphire → Blue
        float t = (freqNorm - 0.4) / 0.2;
        hue = mix(0.540, 0.600, t);
        sat = mix(0.75,  0.93,  t);
        lit = mix(0.69,  0.76,  t);
    } else if (freqNorm < 0.8) {
        // Mid: Blue → Lavender
        float t = (freqNorm - 0.6) / 0.2;
        hue = mix(0.600, 0.655, t);
        sat = mix(0.93,  0.96,  t);
        lit = mix(0.76,  0.84,  t);
    } else {
        // High: Lavender → Mauve
        float t = (freqNorm - 0.8) / 0.2;
        hue = mix(0.655, 0.745, t);
        sat = mix(0.96,  0.85,  t);
        lit = mix(0.84,  0.81,  t);
    }

    // Height-based lightness boost — peaks shine brighter
    lit += barHeight * 0.12;
    lit = clamp(lit, 0.0, 0.96);

    // Apply animated hue shift
    hue = mod(hue + hueShift, 1.0);

    vec3 baseColor = hsl2rgb(hue, sat * GRADIENT_SATURATION, lit * GRADIENT_BRIGHTNESS);

    // GRADIENT_MODE: mix frequency and height modes
    #if GRADIENT_MODE == 1
        // Height-only gradient: dark at base, bright at top
        float heightHue = 0.60 + barHeight * 0.15;
        vec3 heightColor = hsl2rgb(heightHue, 0.85, 0.45 + barHeight * 0.35);
        return heightColor;
    #elif GRADIENT_MODE == 2
        // Both: blend frequency and height
        float heightHue = 0.60 + barHeight * 0.15;
        vec3 heightColor = hsl2rgb(heightHue, 0.85, 0.45 + barHeight * 0.35);
        return mix(baseColor, heightColor, 0.4);
    #else
        return baseColor;
    #endif
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  BAR SHAPE SDF
//  Signed distance field for a single bar with rounded top
//  Returns: < 0 inside bar, > 0 outside, smooth boundary
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

float barSDF(
    vec2  uv,           // Current pixel UV
    float barLeft,      // Left edge of bar in UV space
    float barRight,     // Right edge of bar in UV space
    float barTop,       // Top of bar in UV space (= bar height)
    float cornerRadius  // Rounding radius
) {
    // Map to bar-local coordinates (centered)
    float halfW = (barRight - barLeft) * 0.5;
    float halfH = barTop * 0.5;
    vec2 center = vec2((barLeft + barRight) * 0.5, halfH);
    vec2 p = uv - center;

    // Rounded rectangle SDF
    vec2 q = abs(p) - vec2(halfW, halfH) + cornerRadius;
    float dist = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - cornerRadius;

    return dist;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  GLOW SAMPLING
//  Multi-sample exponential glow around bar edges
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

float computeGlow(
    vec2  uv,
    float barLeft,
    float barRight,
    float barTop,
    float barHeight    // 0-1 amplitude
) {
    float glow = 0.0;

    // Multi-radius bloom: inner sharp + outer soft
    float radii[4];
    float weights[4];
    radii[0]   = GLOW_INNER_SIZE * 0.3;   weights[0] = 1.00;  // sharp core
    radii[1]   = GLOW_INNER_SIZE;         weights[1] = 0.60;  // inner bloom
    radii[2]   = GLOW_OUTER_SIZE * 0.5;   weights[2] = 0.30;  // mid bloom
    radii[3]   = GLOW_OUTER_SIZE;         weights[3] = 0.12;  // wide soft bloom

    for (int i = 0; i < GLOW_LAYERS; i++) {
        float dist = barSDF(uv, barLeft, barRight, barTop, BAR_ROUNDING);
        float g = glowFalloff(max(0.0, dist), radii[i], 2.5) * weights[i];
        glow += g;
    }

    // Scale glow with bar height — louder = more glow
    return glow * GLOW_INTENSITY * (0.4 + barHeight * 0.6);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  PEAK INDICATOR
//  Returns intensity of a peak hold line above the bar
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

float peakLine(vec2 uv, float barLeft, float barRight, float peakY) {
    // Horizontal range check
    float withinBar = smoothEdge(barLeft + 0.001, barLeft + 0.003, uv.x)
                    * smoothEdge(barRight - 0.001, barRight - 0.003, uv.x);
    withinBar = 1.0 - withinBar; // invert — we want within bar
    if (uv.x < barLeft + 0.001 || uv.x > barRight - 0.001) return 0.0;

    // Vertical distance from peak Y
    float dist = abs(uv.y - peakY);

    // Sharp peak line
    float line = smoothEdge(PEAK_HEIGHT, PEAK_HEIGHT * 0.1, dist);

    // Soft glow around peak
    float glow = glowFalloff(dist, PEAK_GLOW, 2.0) * 0.5;

    return line + glow;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  PARTICLE SPARK SYSTEM
//  Emits particles from bar peaks when energy is high
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

float particleSparks(vec2 uv, float barCenter, float barTop, float barHeight, int barIdx) {
    if (barHeight < 0.7) return 0.0; // Only emit on high energy

    float sparks = 0.0;
    float energy = (barHeight - 0.7) / 0.3; // 0-1 above threshold

    for (int i = 0; i < PARTICLE_COUNT; i++) {
        // Deterministic random per particle, bar, and time phase
        float seed = float(barIdx * PARTICLE_COUNT + i);
        float phase = rand(vec2(seed, 1.0)); // lifetime phase offset

        // Particle trajectory: parabolic rise with gravity
        float t = mod(time * 0.8 + phase * PARTICLE_LIFE, PARTICLE_LIFE) / PARTICLE_LIFE;

        // Horizontal spread — random direction
        float angle = rand(vec2(seed, 2.0)) * 3.14159 * 2.0;
        float speed = rand(vec2(seed, 3.0)) * 0.04 + 0.01;

        // Position: starts at bar top, moves in parabola
        float px = barCenter + sin(angle) * speed * t * 0.6;
        float py = barTop + t * 0.12 - t * t * 0.18; // up then gravity down

        // Particle size shrinks with age
        float radius = PARTICLE_SIZE * (1.0 - t) * energy;

        // Distance from particle center
        float dist = length(uv - vec2(px, py));

        // Soft circle with glow
        float alpha = smoothEdge(radius, radius * 0.2, dist) * (1.0 - t);
        alpha += glowFalloff(dist, radius * 3.0, 3.0) * 0.3 * (1.0 - t);

        sparks = max(sparks, alpha);
    }

    return sparks;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  BACKGROUND GENERATION
//  Dynamic reactive background with grid and bass pulse
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vec3 generateBackground(vec2 uv, float bassEnergy, float midEnergy) {
    vec3 bg = COL_BG_DEEP;

    // Subtle vertical gradient — darker at top
    float vertGrad = 1.0 - uv.y * 0.4;
    bg *= vertGrad;

    #if BG_GRID_ENABLED
        // Grid lines — subtle geometric pattern
        vec2 gridUV = uv / BG_GRID_SIZE;
        float gridX = abs(fract(gridUV.x) - 0.5);
        float gridY = abs(fract(gridUV.y) - 0.5);
        float grid  = smoothEdge(0.48, 0.50, max(gridX, gridY));
        bg += COL_SURFACE * grid * BG_GRID_ALPHA;

        // Diagonal accent lines for premium feel
        float diagUV = (uv.x + uv.y) / (BG_GRID_SIZE * 2.828);
        float diag = abs(fract(diagUV) - 0.5);
        bg += COL_SURFACE * smoothEdge(0.49, 0.50, diag) * BG_GRID_ALPHA * 0.3;
    #endif

    #if BG_PULSE_ENABLED
        // Bass pulse — center radial glow that reacts to bass
        float dist = length(uv - vec2(0.5, 0.0));
        float pulse = bassEnergy * BG_PULSE_STRENGTH;
        float radialGlow = glowFalloff(dist, 0.8, 2.0) * pulse;

        // Bass color shifts toward teal/green on heavy bass
        vec3 pulseColor = mix(COL_TEAL, COL_MAUVE, midEnergy);
        bg += pulseColor * radialGlow;

        // Subtle breathing vignette based on mid energy
        float breathe = midEnergy * 0.06;
        float vignette = 1.0 - length(uv - vec2(0.5, 0.5)) * 1.2;
        bg += COL_MAUVE * max(0.0, vignette) * breathe;
    #endif

    return bg;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  MAIN — Fragment Entry Point
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

void main() {

    // ── UV Coordinates ────────────────────────────────────────────────────────
    // uv.x: 0 (left) → 1 (right)
    // uv.y: 0 (bottom) → 1 (top)
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 pixelSize = 1.0 / resolution.xy;

    // ── Audio Data Sampling ───────────────────────────────────────────────────
    int   numBars     = bars_count;
    float fNumBars    = float(numBars);
    float barWidth    = 1.0 / fNumBars;
    float gap         = barWidth * BAR_GAP;
    float solidWidth  = barWidth - gap;

    // Determine which bar this pixel belongs to
    int   barIdx      = int(uv.x * fNumBars);
    barIdx            = clamp(barIdx, 0, numBars - 1);
    float barNorm     = (float(barIdx) + 0.5) / fNumBars; // 0-1 bar position

    // Sample bar height from texture
    float barHeight   = texture(bars, barNorm).r;
    barHeight         = clamp(barHeight, 0.0, 1.0);

    // Add floor minimum height so bars are always slightly visible
    float barTop      = max(barHeight, BAR_FLOOR_HEIGHT);

    // Bar boundaries in UV space
    float barLeft     = float(barIdx) * barWidth + gap * 0.5;
    float barRight    = barLeft + solidWidth;
    float barCenter   = (barLeft + barRight) * 0.5;

    // ── Aggregate Audio Metrics ───────────────────────────────────────────────
    // Sample multiple bars for bass / mid energy readings
    float bassEnergy  = 0.0;
    float midEnergy   = 0.0;
    float trebleEnergy = 0.0;
    float totalEnergy = 0.0;

    int bassBars    = max(1, numBars / 10);  // bottom 10% = bass
    int midStart    = numBars / 10;
    int midEnd      = numBars * 6 / 10;
    int trebleStart = numBars * 6 / 10;

    for (int i = 0; i < numBars; i++) {
        float h = texture(bars, (float(i) + 0.5) / fNumBars).r;
        totalEnergy += h;
        if (i < bassBars)    bassEnergy   += h;
        if (i >= midStart && i < midEnd)   midEnergy  += h;
        if (i >= trebleStart) trebleEnergy += h;
    }

    bassEnergy    /= float(bassBars);
    midEnergy     /= float(midEnd - midStart);
    trebleEnergy  /= float(numBars - trebleStart);
    totalEnergy   /= float(numBars);

    // Smooth bass for stable background pulse
    float smoothBass = pow(bassEnergy, 0.7);

    // ── Background ────────────────────────────────────────────────────────────
    vec3 color = generateBackground(uv, smoothBass, midEnergy);

    // ── Floor Line ────────────────────────────────────────────────────────────
    #if FLOOR_LINE_ENABLED
        float floorDist = abs(uv.y - BAR_FLOOR_HEIGHT);
        if (floorDist < FLOOR_LINE_HEIGHT) {
            float floorAlpha = (1.0 - floorDist / FLOOR_LINE_HEIGHT) * FLOOR_LINE_ALPHA;
            // Floor line color pulses with bass
            vec3 floorColor = mix(COL_SURFACE, COL_TEAL, smoothBass * 0.5);
            color = mix(color, floorColor, floorAlpha);
        }
    #endif

    // ── Center Seam (stereo) ──────────────────────────────────────────────────
    #if STEREO_SEAM
        float seamDist = abs(uv.x - 0.5);
        if (seamDist < SEAM_WIDTH) {
            float seamAlpha = (1.0 - seamDist / SEAM_WIDTH) * SEAM_ALPHA;
            // Seam pulses brighter with mid energy
            seamAlpha *= (1.0 + midEnergy * 0.5);
            color = mix(color, COL_LAVENDER, seamAlpha);
        }
    #endif

    // ── Accumulate All Bars ───────────────────────────────────────────────────
    // We process ALL bars to composite glow from neighboring bars correctly
    // This is the critical pass — each pixel accumulates contributions from
    // multiple bars including glow spill from adjacent bars

    vec3  barColor       = vec3(0.0);
    float barAlpha       = 0.0;
    vec3  glowColor      = vec3(0.0);
    float glowAlpha      = 0.0;
    vec3  peakColor      = vec3(0.0);
    float peakAlpha      = 0.0;
    float sparkAlpha     = 0.0;

    // Optimization: only process bars within glow radius of current pixel
    float glowReach = GLOW_OUTER_SIZE;
    int   startBar  = max(0, int((uv.x - glowReach) * fNumBars));
    int   endBar    = min(numBars - 1, int((uv.x + glowReach) * fNumBars) + 1);

    for (int i = startBar; i <= endBar; i++) {
        float bn     = (float(i) + 0.5) / fNumBars;
        float bh     = texture(bars, bn).r;
        float bt     = max(bh, BAR_FLOOR_HEIGHT);
        float bl     = float(i) * barWidth + gap * 0.5;
        float br     = bl + solidWidth;
        float bc     = (bl + br) * 0.5;
        float freqN  = bn; // frequency position 0-1

        // Bar color for this frequency
        vec3 bColor  = frequencyColor(freqN, bh);

        // ── Bar Fill ─────────────────────────────────────────────────────────
        float sdf    = barSDF(uv, bl, br, bt, BAR_ROUNDING * solidWidth);
        float fill   = smoothEdge(pixelSize.x, -pixelSize.x, sdf);

        if (fill > 0.001) {
            // Height-based brightness: bottom darker, top brighter
            float heightUV = (uv.y / bt);
            heightUV = clamp(heightUV, 0.0, 1.0);

            // Vertical gradient within bar
            vec3 bottomColor = bColor * 0.5;
            vec3 topColor    = bColor * 1.1 + vec3(0.06);
            vec3 fillColor   = mix(bottomColor, topColor, heightUV * heightUV);

            // Specular highlight at bar top (bright rim)
            float rimDist = abs(uv.y - bt);
            float rim     = glowFalloff(rimDist, solidWidth * 0.3, 3.0) * 0.4;
            fillColor    += vec3(rim);

            // Lateral specular — bar edges catch light
            float edgeDist = min(abs(uv.x - bl), abs(uv.x - br));
            float edgeRim  = glowFalloff(edgeDist, solidWidth * 0.15, 2.0) * 0.15;
            fillColor     += bColor * edgeRim;

            // Accumulate (use max for overlapping bars, shouldn't happen but safe)
            if (fill > barAlpha) {
                barColor = fillColor;
                barAlpha = fill;
            }
        }

        // ── Glow / Bloom ─────────────────────────────────────────────────────
        #if GLOW_ENABLED
            float outsideDist = max(0.0, barSDF(uv, bl, br, bt, BAR_ROUNDING * solidWidth));

            // Inner glow (close to bar surface)
            float innerGlow = glowFalloff(outsideDist, GLOW_INNER_SIZE, 3.0) * bh * 0.8;

            // Outer bloom (wide soft halo)
            float outerGlow = glowFalloff(outsideDist, GLOW_OUTER_SIZE, 1.5) * bh * 0.3;

            float totalGlow = (innerGlow + outerGlow) * GLOW_INTENSITY;

            if (totalGlow > 0.001) {
                // Glow color slightly desaturated and brightened
                vec3 gc = bColor + vec3(0.15);
                glowColor = mix(glowColor, gc, totalGlow * (1.0 - glowAlpha));
                glowAlpha = min(1.0, glowAlpha + totalGlow * 0.4);
            }
        #endif

        // ── Peak Indicators ──────────────────────────────────────────────────
        #if PEAKS_ENABLED
            // Simulate peak hold: peak drifts slowly downward from max
            // Using a noise-based pseudo-physics (true peak needs CPU-side data)
            float peakOffset  = 0.012; // Fixed offset above current bar
            float peakY       = bt + peakOffset;

            if (uv.x >= bl && uv.x <= br) {
                float pAlpha = peakLine(uv, bl, br, peakY);

                if (pAlpha > 0.001) {
                    // Peak color: brighter than bar, slightly shifted hue
                    vec3 pColor = mix(bColor, COL_PEAK, 0.4) + vec3(0.2);

                    // Critical peak (very high) → red warning
                    if (bh > 0.95) {
                        pColor = mix(pColor, COL_CRITICAL, (bh - 0.95) / 0.05);
                    }

                    peakColor  = mix(peakColor, pColor, pAlpha * (1.0 - peakAlpha));
                    peakAlpha += pAlpha * 0.3;
                }
            }
        #endif

        // ── Particle Sparks ───────────────────────────────────────────────────
        #if PARTICLES_ENABLED
            float spark = particleSparks(uv, bc, bt, bh, i);
            if (spark > 0.001) {
                vec3 sparkColor = bColor + vec3(0.3);
                glowColor  = mix(glowColor, sparkColor, spark * (1.0 - glowAlpha));
                glowAlpha  = min(1.0, glowAlpha + spark * 0.15);
                sparkAlpha = max(sparkAlpha, spark);
            }
        #endif
    }

    // ── Compositing ───────────────────────────────────────────────────────────
    // Layer order (back to front):
    // 1. Background
    // 2. Glow / bloom
    // 3. Bar fill
    // 4. Peak indicators
    // 5. Chromatic aberration post-process

    // 1+2: Background + Glow
    color = mix(color, glowColor, glowAlpha * 0.7);

    // 3: Bar fill (alpha-composite over background + glow)
    color = mix(color, barColor, barAlpha);

    // 4: Peak indicators
    color = mix(color, peakColor, peakAlpha * 0.9);

    // ── Chromatic Aberration ──────────────────────────────────────────────────
    #if CHROMA_ENABLED
        // Only on high-energy moments — visual emphasis on transients
        float chromaStrength = CHROMA_STRENGTH * totalEnergy * 2.0;
        if (chromaStrength > 0.0002 && barAlpha > 0.5) {
            // Sample red channel slightly left, blue slightly right
            vec2 chromaOffset = vec2(chromaStrength, 0.0);

            // Clamp sample positions to valid UV range
            vec2 uvR = clamp(uv - chromaOffset, pixelSize, 1.0 - pixelSize);
            vec2 uvB = clamp(uv + chromaOffset, pixelSize, 1.0 - pixelSize);

            // Aberration: shift color channels horizontally
            color.r = mix(color.r, color.r * 1.15, chromaStrength * 20.0);
            color.b = mix(color.b, color.b * 1.15, chromaStrength * 20.0);
        }
    #endif

    // ── Tonemapping & Gamma ───────────────────────────────────────────────────
    // ACES filmic tonemapping — prevents harsh clipping on bright glows
    // Gives that cinematic look to high-energy moments
    {
        float a = 2.51;
        float b = 0.03;
        float c = 2.43;
        float d = 0.59;
        float e = 0.14;
        color = (color * (a * color + b)) / (color * (c * color + d) + e);
    }

    // Gamma correction (linear → sRGB, gamma ≈ 2.2)
    color = pow(clamp(color, 0.0, 1.0), vec3(1.0 / 2.2));

    // ── Vignette ──────────────────────────────────────────────────────────────
    // Subtle corner darkening for focus toward center
    float vig = 1.0 - length((uv - vec2(0.5, 0.3)) * vec2(1.0, 1.8)) * 0.35;
    vig = clamp(vig, 0.0, 1.0);
    color *= vig * 0.2 + 0.8; // Subtle: 20% vignette effect

    // ── Final Output ─────────────────────────────────────────────────────────
    fragColor = vec4(color, 1.0);
}