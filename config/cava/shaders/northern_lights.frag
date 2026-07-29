// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  ASH DOTFILES v5.0 — CAVA GLSL SHADER: NORTHERN LIGHTS                    ║
// ║                                                                            ║
// ║  ███╗░░██╗░█████╗░██████╗░████████╗██╗░░██╗███████╗██████╗░███╗░░██╗     ║
// ║  ████╗░██║██╔══██╗██╔══██╗╚══██╔══╝██║░░██║██╔════╝██╔══██╗████╗░██║    ║
// ║  ██╔██╗██║██║░░██║██████╔╝░░░██║░░░███████║█████╗░░██████╔╝██╔██╗██║    ║
// ║  ██║╚████║██║░░██║██╔══██╗░░░██║░░░██╔══██║██╔══╝░░██╔══██╗██║╚████║    ║
// ║  ██║░╚███║╚█████╔╝██║░░██║░░░██║░░░██║░░██║███████╗██║░░██║██║░╚███║    ║
// ║  ╚═╝░░╚══╝░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝   ║
// ║  ██╗░░░░░██╗░██████╗░██╗░░██╗████████╗░██████╗                           ║
// ║  ██║░░░░░██║██╔════╝░██║░░██║╚══██╔══╝██╔════╝                           ║
// ║  ██║░░░░░██║██║░░██╗░███████║░░░██║░░░╚█████╗░                           ║
// ║  ██║░░░░░██║██║░░╚██╗██╔══██║░░░██║░░░░╚═══██╗                           ║
// ║  ███████╗██║╚██████╔╝██║░░██║░░░██║░░░██████╔╝                           ║
// ║  ╚══════╝╚═╝░╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═════╝░                           ║
// ║                                                                            ║
// ║  Flowing Aurora Borealis Audio Visualizer                                  ║
// ║  Features:                                                                 ║
// ║    🌌 Multi-layer aurora curtains with fluid simulation                   ║
// ║    🎵 Audio-reactive aurora intensity and frequency mapping               ║
// ║    ⭐ Procedural starfield with twinkling animation                       ║
// ║    🌊 Domain-warped flow fields for organic movement                      ║
// ║    🎨 HSL aurora color shift (green → cyan → magenta spectrum)            ║
// ║    💫 Volumetric light ray simulation                                      ║
// ║    🌠 Shooting star system on peak transients                             ║
// ║    🔮 Frequency-mapped aurora band positioning                            ║
// ║    ❄️  Subtle snow/dust particle layer                                     ║
// ║                                                                            ║
// ║  GLSL Version: 330 core                                                   ║
// ║  Cava Version: 0.10.0+                                                    ║
// ╚══════════════════════════════════════════════════════════════════════════╝

#version 330 core

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  CAVA UNIFORMS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

uniform sampler1D bars;
uniform int       bars_count;
uniform float     time;
uniform vec2      resolution;

out vec4 fragColor;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  ASH AURORA COLOR PALETTE
//  Inspired by actual aurora phenomena + Catppuccin Mocha accent colors
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Deep space background
#define SKY_TOP        vec3(0.020, 0.015, 0.045)   // Near black with blue tint
#define SKY_MID        vec3(0.035, 0.025, 0.075)   // Deep indigo
#define SKY_HORIZON    vec3(0.055, 0.040, 0.095)   // Slightly lighter horizon

// Aurora primary colors — scientifically accurate + Catppuccin mapped
// Green aurora (oxygen @100km): #a6e3a1 → mapped to aurora-green
#define AURORA_GREEN   vec3(0.400, 0.900, 0.550)   // O2 emission — most common
// Cyan aurora (oxygen @200km): #94e2d5
#define AURORA_TEAL    vec3(0.350, 0.850, 0.780)   // Higher altitude O2
// Blue aurora (nitrogen): #89b4fa
#define AURORA_BLUE    vec3(0.380, 0.650, 0.980)   // N2+ emission
// Magenta/red aurora (oxygen @300km+): #f38ba8
#define AURORA_MAGENTA vec3(0.950, 0.380, 0.650)   // High-altitude O2 red
// Purple (mixed): #cba6f7
#define AURORA_PURPLE  vec3(0.750, 0.550, 0.960)   // Mixed aurora top
// White core (maximum intensity)
#define AURORA_WHITE   vec3(0.920, 0.950, 1.000)   // Core hot spots

// Star colors
#define STAR_COLD      vec3(0.700, 0.800, 1.000)   // Blue-white (hot stars)
#define STAR_WARM      vec3(1.000, 0.900, 0.700)   // Yellow-white (sun-like)
#define STAR_RED       vec3(1.000, 0.500, 0.300)   // Red giant

// Ground / horizon
#define GROUND_COLOR   vec3(0.010, 0.025, 0.040)   // Arctic darkness
#define SNOW_COLOR     vec3(0.080, 0.120, 0.180)   // Snow with aurora tint

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  VISUAL PARAMETERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Aurora layers
#define AURORA_LAYERS       5        // Number of overlapping aurora curtains
#define AURORA_BASE_HEIGHT  0.35     // UV height where aurora starts (above horizon)
#define AURORA_TOP_HEIGHT   0.95     // UV height at aurora ceiling
#define AURORA_SPEED        0.18     // Base animation speed
#define AURORA_WARP         0.85     // Domain warp strength (organic movement)
#define AURORA_BRIGHTNESS   1.4      // Overall brightness multiplier
#define AURORA_THICKNESS    0.18     // Vertical extent of each curtain

// Starfield
#define STAR_LAYERS         3        // Parallax star layers
#define STAR_DENSITY        0.994    // 1.0 = no stars, 0.0 = all pixels are stars
#define STAR_TWINKLE_SPEED  2.5      // Twinkle animation speed
#define STAR_BRIGHTNESS     1.2      // Star brightness multiplier
#define STAR_SIZE_MAX       0.0025   // Maximum star radius

// Shooting stars
#define SHOOTING_STARS      3        // Number of shooting stars
#define SHOOT_TRAIL_LENGTH  0.18     // Length of shooting star trail
#define SHOOT_TRIGGER       0.75     // Energy threshold to trigger shooting star

// Ground
#define GROUND_HEIGHT       0.18     // UV height of ground horizon
#define GROUND_REFLECTION   0.15     // Aurora reflection intensity on snow
#define SNOW_PARTICLES      1        // Show snow particles

// Light rays
#define RAYS_ENABLED        1        // Volumetric light rays from aurora
#define RAY_COUNT           8        // Rays per aurora layer
#define RAY_BRIGHTNESS      0.06     // Ray brightness

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  NOISE & MATH UTILITIES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Fast hash (GPU-friendly)
float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// Smooth value noise — for organic aurora ripples
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);   // Smoothstep interpolation

    float a = hash12(i);
    float b = hash12(i + vec2(1, 0));
    float c = hash12(i + vec2(0, 1));
    float d = hash12(i + vec2(1, 1));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Fractal Brownian Motion — layered noise for aurora detail
// octaves: detail levels, lacunarity: frequency increase per octave
// gain: amplitude reduction per octave
float fbm(vec2 p, int octaves, float lacunarity, float gain) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise(p * frequency);
        frequency *= lacunarity;
        amplitude *= gain;
    }

    return value;
}

// Domain-warped FBM — warp the input coordinates with another FBM
// Creates the characteristic "folded curtain" aurora look
float warpedFBM(vec2 p, float warpStrength, float t) {
    // First warp pass — initial fold
    vec2 q = vec2(
        fbm(p + vec2(0.0, 0.0) + vec2(t * 0.12, t * 0.08), 4, 2.1, 0.5),
        fbm(p + vec2(5.2, 1.3) + vec2(t * 0.09, t * 0.11), 4, 2.1, 0.5)
    );

    // Second warp pass — deeper complexity
    vec2 r = vec2(
        fbm(p + warpStrength * q + vec2(1.7, 9.2) + vec2(t * 0.06, 0.0), 5, 2.0, 0.5),
        fbm(p + warpStrength * q + vec2(8.3, 2.8) + vec2(0.0, t * 0.07), 5, 2.0, 0.5)
    );

    return fbm(p + warpStrength * r, 6, 1.9, 0.55);
}

// HSL to RGB (same as bar_spectrum)
vec3 hsl(float h, float s, float l) {
    float c = (1.0 - abs(2.0 * l - 1.0)) * s;
    float x = c * (1.0 - abs(mod(h * 6.0, 2.0) - 1.0));
    float m = l - c * 0.5;
    vec3  rgb;
    if      (h < 1.0/6.0) rgb = vec3(c, x, 0.0);
    else if (h < 2.0/6.0) rgb = vec3(x, c, 0.0);
    else if (h < 3.0/6.0) rgb = vec3(0.0, c, x);
    else if (h < 4.0/6.0) rgb = vec3(0.0, x, c);
    else if (h < 5.0/6.0) rgb = vec3(x, 0.0, c);
    else                   rgb = vec3(c, 0.0, x);
    return rgb + m;
}

// Soft maximum (smooth analog of max)
float softMax(float a, float b, float k) {
    return log(exp(k * a) + exp(k * b)) / k;
}

// Exponential falloff
float falloff(float x, float width, float power) {
    return pow(max(0.0, 1.0 - abs(x) / width), power);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  AURORA COLOR — frequency + energy mapped to aurora spectrum
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vec3 auroraColor(
    float freqNorm,      // 0-1: which frequency range (bass=0, treble=1)
    float height,        // 0-1: vertical position in aurora band
    float intensity,     // 0-1: audio energy
    float layerIdx       // which aurora layer (for color variation)
) {
    // Animated hue drift — aurora colors slowly shift over time
    float hueTime = time * 0.05;

    // Base hue from frequency — creates horizontal color banding
    // Bass → green aurora, Treble → magenta/purple aurora
    float freqHue;
    if (freqNorm < 0.3) {
        // Bass: green (0.35-0.47 hue) — most common aurora color
        freqHue = mix(0.350, 0.470, freqNorm / 0.3);
    } else if (freqNorm < 0.6) {
        // Mid: teal → blue (0.47-0.62)
        freqHue = mix(0.470, 0.620, (freqNorm - 0.3) / 0.3);
    } else if (freqNorm < 0.85) {
        // High-mid: blue → purple (0.62-0.75)
        freqHue = mix(0.620, 0.750, (freqNorm - 0.6) / 0.25);
    } else {
        // Treble: purple → magenta (0.75-0.90) — rare high-altitude aurora
        freqHue = mix(0.750, 0.900, (freqNorm - 0.85) / 0.15);
    }

    // Layer offset — each curtain layer has slightly different hue
    float layerHueOffset = layerIdx * 0.04;

    // Height-based hue shift (higher = more blue/purple — altitude effect)
    float heightHue = height * 0.08;

    float finalHue = mod(freqHue + layerHueOffset + heightHue + hueTime, 1.0);

    // Saturation: max at edge, white at core
    float sat = mix(1.0, 0.4, pow(height, 0.7));
    sat = mix(sat, 0.85, intensity * 0.3);

    // Lightness: bright at center band, dark at edges
    float lit = mix(0.15, 0.65, intensity);
    lit += height * 0.15; // higher = slightly brighter

    return hsl(finalHue, sat, lit);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  SINGLE AURORA LAYER
//  One flowing curtain of northern lights
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vec4 auroraLayer(
    vec2  uv,            // Screen UV
    float layerIndex,    // 0 to AURORA_LAYERS-1
    float audioEnergy,   // Average audio amplitude
    float bassEnergy,    // Low-frequency energy
    float trebleEnergy,  // High-frequency energy
    float barSample      // Audio bar at this horizontal position
) {
    // Each layer has unique timing, scale, and position
    float li       = layerIndex / float(AURORA_LAYERS);
    float speed    = AURORA_SPEED * (0.7 + li * 0.6);
    float scale    = 1.5 + li * 1.2;
    float yOffset  = AURORA_BASE_HEIGHT + li * 0.10; // Stack layers vertically
    float thickness = AURORA_THICKNESS * (0.6 + li * 0.4);

    // Horizontal scroll (each layer moves at different speed)
    float scrollX = time * speed * (0.5 + li * 0.3);
    float scrollY = time * speed * 0.15 * (1.0 - li * 0.4);

    // Compute domain-warped noise for this layer
    // This is the key to the flowing, organic curtain look
    vec2 noiseUV = vec2(
        uv.x * scale * 2.0 + scrollX,
        uv.y * scale * 0.4 + scrollY + li * 3.7
    );

    float noiseVal = warpedFBM(noiseUV, AURORA_WARP, time * speed);

    // Map noise to aurora band: curtain hangs at yOffset, extends upward
    // The noise modulates the vertical position of the curtain
    float curtainY  = yOffset + noiseVal * 0.15 * (1.0 + audioEnergy * 0.5);
    float curtainDist = abs(uv.y - curtainY);

    // Vertical shape: Gaussian-like distribution
    // Rays hang down below the arc, taper at top
    float belowShape = exp(-curtainDist * curtainDist / (thickness * thickness * 0.5));
    float aboveShape = exp(-max(0.0, uv.y - curtainY) * 8.0 / thickness); // sharp top

    float shape = belowShape * (1.0 + aboveShape * 0.3);

    // Audio modulation: frequency bars drive local brightness
    // Bass bars affect lower aurora, treble bars affect upper aurora
    float audioMod = 0.3 + barSample * 0.7;

    // Layer-specific frequency mapping
    // Lower layers = bass (horizontal), Upper layers = treble
    float freqMap  = li; // layer 0 = bass, layer 4 = treble
    float energy   = mix(bassEnergy, trebleEnergy, freqMap);

    // Final intensity = shape × audio × energy
    float intensity = shape * audioMod * (0.4 + energy * 0.6) * AURORA_BRIGHTNESS;

    // Add subtle pulsing rhythm
    float pulse = 1.0 + 0.15 * sin(time * 1.8 + li * 2.1 + noiseVal * 6.28);
    intensity *= pulse;

    // Fade out at sky top
    float topFade = smoothstep(AURORA_TOP_HEIGHT, AURORA_TOP_HEIGHT - 0.1, uv.y);
    intensity *= topFade;

    // Fade near ground
    float groundFade = smoothstep(AURORA_BASE_HEIGHT - 0.05, AURORA_BASE_HEIGHT + 0.05, uv.y);
    intensity *= groundFade;

    // Horizontal position in audio spectrum
    float freqNorm = uv.x; // Left = bass, Right = treble (mirrors cava stereo)

    // Aurora color
    float heightInBand = clamp((uv.y - curtainY + thickness) / (thickness * 2.0), 0.0, 1.0);
    vec3 color = auroraColor(freqNorm, heightInBand, energy, layerIndex);

    return vec4(color, clamp(intensity, 0.0, 1.0));
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  STARFIELD
//  Procedural twinkling stars with parallax layers
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vec3 starfield(vec2 uv, float auroraIntensity) {
    vec3 stars = vec3(0.0);

    // Only show stars in sky area (above ground)
    if (uv.y < GROUND_HEIGHT + 0.02) return stars;

    // Fade stars where aurora is bright (aurora drowns out faint stars)
    float auroraOcclusion = 1.0 - clamp(auroraIntensity * 2.5, 0.0, 0.9);

    for (int layer = 0; layer < STAR_LAYERS; layer++) {
        float fl = float(layer);

        // Each layer has different scale and parallax
        float scale     = 40.0 + fl * 25.0;
        float parallax  = 0.0001 * (fl + 1.0); // Very subtle drift

        // Parallax movement based on time
        vec2 layerUV = uv * scale + vec2(time * parallax, 0.0);
        vec2 cellUV  = fract(layerUV);
        vec2 cellIdx = floor(layerUV);

        // Hash to determine star properties per cell
        float h = hash12(cellIdx + fl * 100.0);

        // Only create a star if hash exceeds density threshold
        if (h > STAR_DENSITY) {
            // Star position within cell (jittered from center)
            vec2 starPos = vec2(
                hash12(cellIdx + vec2(fl * 7.3, 1.0)),
                hash12(cellIdx + vec2(1.0, fl * 4.1))
            );

            float dist = length(cellUV - starPos);

            // Star size varies by brightness
            float brightness = (h - STAR_DENSITY) / (1.0 - STAR_DENSITY);
            float starRadius = STAR_SIZE_MAX * (0.3 + brightness * 0.7) * scale * 0.008;

            // Twinkle: phase-randomized sine oscillation
            float twinklePhase = hash12(cellIdx + fl * 13.7) * 6.28;
            float twinkle = 0.65 + 0.35 * sin(time * STAR_TWINKLE_SPEED + twinklePhase);

            // Distance-based intensity with soft glow
            float core = exp(-dist * dist / (starRadius * starRadius * 0.3));
            float glow = exp(-dist * dist / (starRadius * starRadius * 4.0)) * 0.25;
            float alpha = (core + glow) * twinkle * brightness * STAR_BRIGHTNESS;

            // Star color varies: hot blue-white to cool red-orange
            float colorHash = hash12(cellIdx + vec2(fl * 2.1, 3.7));
            vec3 starColor;
            if (colorHash < 0.6)       starColor = STAR_COLD;   // Most stars blue-white
            else if (colorHash < 0.85) starColor = STAR_WARM;   // Some yellow-white
            else                       starColor = STAR_RED;     // Rare red giants

            // Diffraction spikes for bright stars (cross pattern)
            if (brightness > 0.7) {
                float spikeX = exp(-abs(cellUV.x - starPos.x) / (starRadius * 3.0)) *
                               exp(-abs(cellUV.y - starPos.y) * scale * 1.5) * 0.15;
                float spikeY = exp(-abs(cellUV.y - starPos.y) / (starRadius * 3.0)) *
                               exp(-abs(cellUV.x - starPos.x) * scale * 1.5) * 0.15;
                alpha += (spikeX + spikeY) * brightness * twinkle;
            }

            stars += starColor * alpha * auroraOcclusion;
        }
    }

    return clamp(stars, 0.0, 1.0);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  SHOOTING STARS
//  Triggered by audio transients — streak across the sky
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vec3 shootingStars(vec2 uv, float peakEnergy) {
    vec3 result = vec3(0.0);

    for (int i = 0; i < SHOOTING_STARS; i++) {
        float fi = float(i);

        // Each shooting star has a random period and phase
        float period    = 8.0 + fi * 5.3;
        float phase     = fi * 3.7;
        float t         = mod(time + phase, period) / period; // 0-1 in period

        // Only active during first 15% of period
        if (t > 0.15) continue;

        float active = t / 0.15; // 0 = just appeared, 1 = end of streak

        // Random direction and starting position
        float seed    = fi * 100.0 + floor((time + phase) / period);
        float startX  = hash11(seed);
        float startY  = 0.5 + hash11(seed + 1.0) * 0.45; // Upper half of sky
        float angle   = -0.4 + hash11(seed + 2.0) * 0.5; // Shallow downward angle

        // Streak position and direction
        vec2 dir   = normalize(vec2(cos(angle), sin(angle)));
        vec2 start = vec2(startX, startY);
        vec2 head  = start + dir * active * SHOOT_TRAIL_LENGTH;

        // Distance from this pixel to the streak line
        vec2 toPixel = uv - start;
        float proj   = dot(toPixel, dir);
        vec2  perp   = toPixel - dir * proj;
        float perpDist = length(perp);

        // Only on the active portion of the trail
        float trailT = proj / (active * SHOOT_TRAIL_LENGTH);
        if (trailT < 0.0 || trailT > 1.0) continue;

        // Fade along trail: bright head, fading tail
        float trailFade = pow(1.0 - trailT, 2.0);

        // Cross-sectional width (thin streak)
        float width = 0.0015;
        float streak = exp(-perpDist * perpDist / (width * width)) * trailFade;

        // Glow halo around streak
        float glow = exp(-perpDist * perpDist / (width * width * 25.0)) * trailFade * 0.3;

        float alpha = (streak + glow) * (1.0 - active * 0.5);

        // Color: white-cyan streak
        vec3 headColor = vec3(0.9, 0.95, 1.0);
        vec3 tailColor = vec3(0.4, 0.6, 0.9) * 0.3;
        vec3 color     = mix(headColor, tailColor, trailT);

        result += color * alpha;
    }

    return clamp(result, 0.0, 1.0);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  GROUND & SNOW
//  Arctic ground with aurora reflection
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vec3 groundLayer(vec2 uv, vec3 auroraColor, float auroraIntensity) {
    if (uv.y > GROUND_HEIGHT) return vec3(0.0); // Not in ground

    // Ground base color
    vec3 ground = GROUND_COLOR;

    // Snow surface variation (subtle noise)
    float snowNoise = fbm(vec2(uv.x * 8.0, 0.5), 3, 2.0, 0.5) * 0.015;
    ground += SNOW_COLOR * (0.2 + snowNoise);

    // Horizon fog — brighter near horizon line
    float horizonDist = GROUND_HEIGHT - uv.y;
    float horizonFog  = exp(-horizonDist * 15.0);
    ground = mix(ground, SNOW_COLOR * 0.5, horizonFog * 0.4);

    // Aurora reflection on snow
    // Mirror the aurora colors down into the ground
    float reflectY = GROUND_HEIGHT - (GROUND_HEIGHT - uv.y); // Mirrored Y
    float reflectFade = exp(-horizonDist * 8.0); // Fades quickly below horizon
    ground += auroraColor * auroraIntensity * GROUND_REFLECTION * reflectFade;

    // Silhouetted tree line — irregular black profile at horizon
    float treeNoise = fbm(vec2(uv.x * 5.0, 0.0), 3, 2.5, 0.5);
    float treeHeight = GROUND_HEIGHT * (0.8 + treeNoise * 0.25);
    float trees = smoothstep(treeHeight - 0.005, treeHeight + 0.005, uv.y);
    // Trees darken the ground at horizon
    ground = mix(GROUND_COLOR * 0.3, ground, trees);

    return ground;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  SNOW PARTICLES
//  Gently falling snow for atmosphere
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

float snowParticles(vec2 uv) {
    float snow = 0.0;
    float scale = 25.0;

    // Two snow layers at different speeds and densities
    for (int layer = 0; layer < 2; layer++) {
        float fl = float(layer);
        float speed = 0.04 + fl * 0.02;
        float drift = 0.008 * sin(time * 0.5 + fl * 2.0); // Gentle wind

        vec2 snowUV = fract(uv * (scale + fl * 10.0) + vec2(time * drift, -time * speed));
        vec2 cellIdx = floor(uv * (scale + fl * 10.0) + vec2(time * drift, -time * speed));

        float h = hash12(cellIdx + fl * 50.0);
        if (h > 0.965) { // ~3.5% of cells have snow
            vec2 snowPos = vec2(
                0.3 + hash12(cellIdx + vec2(fl * 3.1, 0.0)) * 0.4,
                0.3 + hash12(cellIdx + vec2(0.0, fl * 2.9)) * 0.4
            );

            float dist = length(snowUV - snowPos);
            float radius = 0.015 + fl * 0.008;
            float flake = exp(-dist * dist / (radius * radius * 0.3));
            snow += flake * (0.4 + fl * 0.2);
        }
    }

    return clamp(snow, 0.0, 0.8);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  VOLUMETRIC LIGHT RAYS
//  Vertical rays streaming down from aurora bands
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vec3 lightRays(vec2 uv, float audioEnergy, float bassEnergy) {
    if (uv.y < GROUND_HEIGHT) return vec3(0.0);

    vec3 rays = vec3(0.0);

    for (int r = 0; r < RAY_COUNT; r++) {
        float fr = float(r) / float(RAY_COUNT);

        // Ray x-position — spread across screen with slight audio movement
        float rayX = fr + sin(time * 0.3 + fr * 6.28) * 0.03;

        // Ray width — narrows with distance from source
        float rayWidth = 0.006 + bassEnergy * 0.008;

        // Distance from ray center
        float dist = abs(uv.x - rayX);
        float rayAlpha = exp(-dist * dist / (rayWidth * rayWidth)) * RAY_BRIGHTNESS;

        // Rays are brighter near top (aurora source), fade toward ground
        float vertFade = smoothstep(AURORA_BASE_HEIGHT, AURORA_TOP_HEIGHT, uv.y);
        rayAlpha *= vertFade;

        // Ray color matches aurora hue at that x-position
        vec3 rayColor = auroraColor(fr, 0.5, audioEnergy, float(r % 3));

        rays += rayColor * rayAlpha * audioEnergy;
    }

    return rays;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  MAIN — Fragment Entry Point
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    int   numBars  = bars_count;
    float fNumBars = float(numBars);

    // ── Audio Data ────────────────────────────────────────────────────────────
    float totalEnergy  = 0.0;
    float bassEnergy   = 0.0;
    float midEnergy    = 0.0;
    float trebleEnergy = 0.0;
    float peakEnergy   = 0.0;

    int bassCutoff   = numBars / 8;
    int midCutoff    = numBars * 5 / 8;

    for (int i = 0; i < numBars; i++) {
        float h = texture(bars, (float(i) + 0.5) / fNumBars).r;
        totalEnergy += h;
        if (i < bassCutoff) bassEnergy += h;
        else if (i < midCutoff) midEnergy  += h;
        else trebleEnergy += h;
        peakEnergy = max(peakEnergy, h);
    }

    totalEnergy  /= fNumBars;
    bassEnergy   /= float(bassCutoff);
    midEnergy    /= float(midCutoff - bassCutoff);
    trebleEnergy /= float(numBars - midCutoff);

    // Sample audio bar at current pixel's horizontal position
    float barSampleNorm = uv.x;
    float localBar      = texture(bars, barSampleNorm).r;

    // ── Sky Background ────────────────────────────────────────────────────────
    float skyT   = smoothstep(GROUND_HEIGHT, GROUND_HEIGHT + 0.15, uv.y);
    vec3  sky    = mix(SKY_HORIZON, mix(SKY_MID, SKY_TOP, uv.y), skyT);

    // Add very subtle Milky Way band — diagonal noise stripe across sky
    float mwAngle = 0.35;
    float mwDist  = abs((uv.x * sin(mwAngle) + uv.y * cos(mwAngle)) - 0.55);
    float mwBand  = exp(-mwDist * mwDist * 80.0) * 0.03;
    sky += vec3(0.4, 0.5, 0.8) * mwBand;

    vec3 color = sky;

    // ── Starfield ─────────────────────────────────────────────────────────────
    float starAuroraOcclusion = totalEnergy;
    vec3 stars = starfield(uv, starAuroraOcclusion);
    color += stars;

    // ── Aurora Layers ─────────────────────────────────────────────────────────
    // Accumulate all aurora curtain layers
    vec3  auroraAccum      = vec3(0.0);
    float auroraAlphaAccum = 0.0;

    for (int layer = 0; layer < AURORA_LAYERS; layer++) {
        float fl = float(layer);

        vec4 aurora = auroraLayer(
            uv,
            fl,
            totalEnergy,
            bassEnergy,
            trebleEnergy,
            localBar
        );

        // Additive blending with opacity accumulation
        // Each layer adds on top, maintaining color fidelity
        float layerWeight  = aurora.a * (1.0 - auroraAlphaAccum * 0.6);
        auroraAccum       += aurora.rgb * layerWeight;
        auroraAlphaAccum   = min(1.0, auroraAlphaAccum + aurora.a * 0.4);
    }

    // Composite aurora onto sky
    color = mix(color, color + auroraAccum, min(auroraAlphaAccum, 0.98));

    // ── Volumetric Light Rays ─────────────────────────────────────────────────
    #if RAYS_ENABLED
        vec3 rays = lightRays(uv, totalEnergy, bassEnergy);
        color += rays * (1.0 - auroraAlphaAccum * 0.5);
    #endif

    // ── Shooting Stars ────────────────────────────────────────────────────────
    if (peakEnergy > SHOOT_TRIGGER && uv.y > GROUND_HEIGHT) {
        vec3 shoot = shootingStars(uv, peakEnergy);
        color += shoot;
    }

    // ── Ground ────────────────────────────────────────────────────────────────
    if (uv.y < GROUND_HEIGHT) {
        vec3 ground = groundLayer(uv, auroraAccum, auroraAlphaAccum);
        color = mix(color, ground, smoothstep(GROUND_HEIGHT + 0.005, GROUND_HEIGHT, uv.y));
    }

    // ── Horizon Atmospheric Glow ──────────────────────────────────────────────
    float horizonDist = abs(uv.y - GROUND_HEIGHT);
    float horizonGlow = exp(-horizonDist * horizonDist * 300.0) * 0.12;
    // Color of horizon glow is average aurora color
    vec3 horizonColor = mix(AURORA_TEAL, AURORA_GREEN, bassEnergy);
    color += horizonColor * horizonGlow * (0.5 + totalEnergy * 0.5);

    // ── Snow Particles ────────────────────────────────────────────────────────
    #if SNOW_PARTICLES
        float snow = snowParticles(uv);
        color = mix(color, vec3(0.8, 0.9, 1.0), snow * 0.5);
    #endif

    // ── Post Processing ───────────────────────────────────────────────────────

    // Filmic tonemapping (ACES) — natural highlight rolloff
    {
        float a = 2.51;
        float b = 0.03;
        float c = 2.43;
        float d = 0.59;
        float e = 0.14;
        color = (color * (a * color + b)) / (color * (c * color + d) + e);
    }

    // Subtle color grade — boost blues/greens slightly for night atmosphere
    color.b = mix(color.b, color.b * 1.08, 0.4);
    color.g = mix(color.g, color.g * 1.03, 0.3);

    // Gamma correction
    color = pow(clamp(color, 0.0, 1.0), vec3(1.0 / 2.2));

    // Vignette — round frame, darkness toward corners
    float vig = 1.0 - length((uv - 0.5) * vec2(1.1, 1.3)) * 0.45;
    color *= clamp(vig * 0.3 + 0.7, 0.0, 1.0);

    // Subtle film grain for cinematic texture
    float grain = (hash12(uv + vec2(time * 0.1)) - 0.5) * 0.015;
    color += grain;

    // Final clamp
    color = clamp(color, 0.0, 1.0);

    fragColor = vec4(color, 1.0);
}