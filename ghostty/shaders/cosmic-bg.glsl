const vec4 BG_COLOR = vec4(0.0, 0.0, 0.0, 1.0);
const float BLINK_FREQ = 0.05;
const float OPACITY = 0.04;
const float STAR_FUZZ = 0.4;
const int BIG_STAR_COUNT = 4;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = rot * p * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    vec4 terminalBg = texture(iChannel0, uv);

    vec2 nuv = uv * 3.0;
    nuv.x += iTime * 0.01;
    float n = fbm(nuv);
    float n2 = fbm(nuv * 1.4 + vec2(5.2, 1.3) + iTime * 0.005);
    float n3 = fbm(nuv * 2.1 - vec2(3.7, 8.1) - iTime * 0.008);

    vec3 nebula1 = mix(BG_COLOR.rgb * 2.5, mix(BG_COLOR.rgb, vec3(0.1, 0.05, 0.4), 0.5), n);
    vec3 nebula2 = mix(BG_COLOR.rgb, mix(BG_COLOR.rgb, vec3(0.3, 0.05, 0.2), 0.5), n2);
    vec3 nebula3 = mix(BG_COLOR.rgb * 0.5, mix(BG_COLOR.rgb, vec3(0.05, 0.15, 0.35), 0.5), n3);

    vec3 bg = nebula1 * 0.6 + nebula2 * 0.4 + nebula3 * 0.3;
    bg = mix(bg, BG_COLOR.rgb, 0.5);
    vec4 frag = vec4(bg, 1.0);

    const int starCount = 80;
    for (int i = 0; i < starCount; i++) {
        float fi = float(i);
        vec2 starPos = vec2(
            hash(vec2(fi, 0.1)) * 0.98 + 0.01,
            hash(vec2(fi, 0.2)) * 0.98 + 0.01
        );
        float starSize = hash(vec2(fi, 0.3)) * 0.003 + 0.0005;
        float dist = length(uv - starPos);
        float twinkle = sin(iTime * (2.0 + hash(vec2(fi, 0.4)) * 5.0) * BLINK_FREQ + fi * 10.0) * 0.5 + 0.5;
        twinkle = 0.5 + twinkle * 0.5;
        float starAlpha = smoothstep(starSize * (1.0 + STAR_FUZZ), 0.0, dist) * twinkle;
        float colorShift = hash(vec2(fi, 0.5));
        vec3 starColor = mix(vec3(1.0), vec3(1.0, 0.95, 0.85), colorShift * 0.15);
        frag.rgb += starColor * starAlpha * 0.8;
    }

    for (int i = 0; i < BIG_STAR_COUNT; i++) {
        float fi = float(i) + 10.0;
        vec2 starPos = vec2(
            hash(vec2(fi, 1.1)) * 0.9 + 0.05,
            hash(vec2(fi, 1.2)) * 0.9 + 0.05
        );
        float dist = length(uv - starPos);
        float glow = exp(-dist * 30.0 / STAR_FUZZ) * 0.4;
        float core = smoothstep(0.004 * STAR_FUZZ, 0.0, dist);
        float twinkle = sin(iTime * (1.5 + fi * 0.7) * BLINK_FREQ + fi * 4.0) * 0.3 + 0.7;
        frag.rgb += vec3(1.0, 1.0, 1.0) * (glow + core) * twinkle * 0.6;
    }

    fragColor = mix(terminalBg, frag, OPACITY);
}

