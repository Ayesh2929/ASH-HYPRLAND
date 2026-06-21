// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  ASH DOTFILES v5.0 OMEGA — Color Inversion Shader                           ║
// ║                                                                              ║
// ║  Full color inversion with selective channel control, partial invert,      ║
// ║  smart inversion (preserve skin tones), and accessibility hue-rotate.      ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

precision highp float;

uniform sampler2D tex;
uniform float     time;
varying vec2      v_texcoord;

// ══════════════════════════════════════════════════════════════════════════════
// §01  CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════════

// Inversion amount (0.0 = original, 1.0 = fully inverted)
const float AMOUNT      = 1.0;

// Invert individual channels (1.0 = invert, 0.0 = keep)
const vec3  INVERT_MASK = vec3(1.0, 1.0, 1.0);  // RGB mask

// Smart mode: attempt to preserve hue while inverting lightness only
// (HSL inversion — less disorienting than full RGB inversion)
const bool  SMART_MODE  = false;

// Hue rotate after inversion (degrees, 0 = no rotation, 180 = complement)
const float HUE_ROTATE  = 0.0;

// ══════════════════════════════════════════════════════════════════════════════
// §02  HSL INVERSION
// ══════════════════════════════════════════════════════════════════════════════

vec3 rgbToHSL(vec3 rgb) {
    float maxC = max(rgb.r, max(rgb.g, rgb.b));
    float minC = min(rgb.r, min(rgb.g, rgb.b));
    float l    = (maxC + minC) * 0.5;
    float s    = 0.0;
    float h    = 0.0;
    float d    = maxC - minC;

    if (d > 0.0001) {
        s = d / (1.0 - abs(2.0 * l - 1.0));
        if      (maxC == rgb.r) h = (rgb.g - rgb.b) / d + (rgb.g < rgb.b ? 6.0 : 0.0);
        else if (maxC == rgb.g) h = (rgb.b - rgb.r) / d + 2.0;
        else                    h = (rgb.r - rgb.g) / d + 4.0;
        h /= 6.0;
    }
    return vec3(h, s, l);
}

float h2r(float p, float q, float t) {
    if (t < 0.0) t += 1.0;
    if (t > 1.0) t -= 1.0;
    if (t < 1.0/6.0) return p + (q-p)*6.0*t;
    if (t < 0.5)     return q;
    if (t < 2.0/3.0) return p + (q-p)*(2.0/3.0-t)*6.0;
    return p;
}

vec3 hslToRGB(vec3 hsl) {
    if (hsl.y < 0.0001) return vec3(hsl.z);
    float q = (hsl.z < 0.5) ? hsl.z*(1.0+hsl.y) : hsl.z+hsl.y-hsl.z*hsl.y;
    float p = 2.0*hsl.z - q;
    return vec3(
        h2r(p, q, hsl.x + 1.0/3.0),
        h2r(p, q, hsl.x),
        h2r(p, q, hsl.x - 1.0/3.0)
    );
}

// ══════════════════════════════════════════════════════════════════════════════
// §03  MAIN SHADER
// ══════════════════════════════════════════════════════════════════════════════

void main() {
    vec4 tex_color = texture2D(tex, v_texcoord);
    vec3 color     = tex_color.rgb;

    vec3 inverted;

    if (SMART_MODE) {
        // ── HSL inversion: keep hue & saturation, flip lightness ──────────────
        vec3 hsl = rgbToHSL(color);

        // Rotate hue if requested
        hsl.x = fract(hsl.x + HUE_ROTATE / 360.0);

        // Invert lightness
        hsl.z = 1.0 - hsl.z;

        inverted = hslToRGB(hsl);
    } else {
        // ── Full RGB inversion with channel mask ───────────────────────────────
        inverted = mix(color, (1.0 - color) * INVERT_MASK + color * (1.0 - INVERT_MASK), 1.0);

        // Optional hue rotation post-invert
        if (abs(HUE_ROTATE) > 0.1) {
            vec3 hsl = rgbToHSL(inverted);
            hsl.x    = fract(hsl.x + HUE_ROTATE / 360.0);
            inverted = hslToRGB(hsl);
        }
    }

    // ── Blend by amount ───────────────────────────────────────────────────────
    vec3 result = mix(color, inverted, AMOUNT);

    gl_FragColor = vec4(clamp(result, 0.0, 1.0), tex_color.a);
}