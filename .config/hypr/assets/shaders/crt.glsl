// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║           ASH DOTFILES v3.0 — CRT EFFECT SHADER                            ║
// ║           Retro CRT monitor simulation for nostalgic aesthetics            ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝
//
// CRT monitor effect GLSL shader for Hyprland
// Adds scanlines, barrel distortion, and RGB phosphor glow

precision mediump float;

varying vec2 v_texcoord;
uniform sampler2D tex;

// Get screen resolution (approximate — adjust for your display)
const vec2 RESOLUTION = vec2(1920.0, 1080.0);

// ── Effect Toggles ────────────────────────────────────────────────────────────
const bool  SCANLINES     = true;
const bool  BARREL_DIST   = true;
const bool  VIGNETTE      = true;
const bool  RGB_SPLIT     = true;
const bool  PHOSPHOR_GLOW = true;
const bool  NOISE         = false;  // Performance intensive

// ── Effect Intensity ──────────────────────────────────────────────────────────
const float SCANLINE_INTENSITY  = 0.15;  // 0 = off, 0.5 = strong
const float SCANLINE_SPEED      = 0.0;   // 0 = static scanlines
const float BARREL_AMOUNT       = 0.08;  // Barrel distortion strength
const float VIGNETTE_AMOUNT     = 0.25;  // Vignette darkness at edges
const float RGB_SPLIT_AMOUNT    = 0.001; // Chromatic aberration
const float GLOW_AMOUNT         = 0.08;  // Phosphor glow
const float NOISE_AMOUNT        = 0.02;  // Static noise

// ── Barrel distortion ─────────────────────────────────────────────────────────
vec2 barrel_distortion(vec2 uv) {
    if (!BARREL_DIST) return uv;

    vec2 cc = uv - 0.5;
    float dist = dot(cc, cc);
    return uv + cc * dist * BARREL_AMOUNT;
}

// ── Vignette effect ───────────────────────────────────────────────────────────
float vignette(vec2 uv) {
    if (!VIGNETTE) return 1.0;

    vec2 pos = uv - 0.5;
    float vig = 1.0 - dot(pos, pos) * VIGNETTE_AMOUNT * 4.0;
    return clamp(vig, 0.0, 1.0);
}

// ── Scanlines ─────────────────────────────────────────────────────────────────
float scanlines(vec2 uv) {
    if (!SCANLINES) return 1.0;

    float scan = sin(uv.y * RESOLUTION.y * 3.14159) * 0.5 + 0.5;
    scan = pow(scan, 0.8);
    return mix(1.0, scan, SCANLINE_INTENSITY);
}

// ── Pseudo-random noise ───────────────────────────────────────────────────────
float noise_fn(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// ── Main ──────────────────────────────────────────────────────────────────────
void main() {
    vec2 uv = v_texcoord;

    // Apply barrel distortion
    vec2 dist_uv = barrel_distortion(uv);

    // Check if we're outside the distorted screen area
    if (dist_uv.x < 0.0 || dist_uv.x > 1.0 ||
        dist_uv.y < 0.0 || dist_uv.y > 1.0) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // RGB chromatic aberration split
    vec3 color;
    if (RGB_SPLIT) {
        float split = RGB_SPLIT_AMOUNT;
        color.r = texture2D(tex, dist_uv + vec2(split, 0.0)).r;
        color.g = texture2D(tex, dist_uv).g;
        color.b = texture2D(tex, dist_uv - vec2(split, 0.0)).b;
    } else {
        color = texture2D(tex, dist_uv).rgb;
    }

    // Phosphor glow (simple blur approximation)
    if (PHOSPHOR_GLOW) {
        vec2 pixel = 1.0 / RESOLUTION;
        vec3 glow  = vec3(0.0);
        for (int x = -1; x <= 1; x++) {
            for (int y = -1; y <= 1; y++) {
                glow += texture2D(tex, dist_uv + vec2(float(x), float(y)) * pixel * 2.0).rgb;
            }
        }
        glow /= 9.0;
        color = mix(color, glow, GLOW_AMOUNT);
    }

    // Apply scanlines
    float scan = scanlines(uv);
    color *= scan;

    // Apply vignette
    float vig = vignette(uv);
    color *= vig;

    // Add noise
    if (NOISE) {
        float n = noise_fn(uv) * NOISE_AMOUNT;
        color += vec3(n);
    }

    // Boost contrast slightly for CRT feel
    color = pow(clamp(color, 0.0, 1.0), vec3(0.95));

    // Add slight warm tint (CRT phosphor warmth)
    color.r *= 1.02;
    color.b *= 0.98;

    gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}