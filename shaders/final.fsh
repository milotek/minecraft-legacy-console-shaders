#version 120

varying vec4 texcoord;
uniform sampler2D gcolor;

uniform float gamma       = 1.1;       // Higher values brighten, lower values darken
uniform float contrast    = 1.0;        // >1.0 increases contrast, <1.0 decreases it
uniform float vibrance    = 1.1;       // >1.0 boosts vibrance, <1.0 softens it
uniform float whitewash   = 0.05;       // 0.0 = no whitewash, higher values add more white
uniform float greenShift  = 0.02;       // Boost green channel for livelier foliage
uniform float warmShift   = 0.075;       // Boost red channel for warmth
uniform float bloomFactor = -0.25;       // Factor for slight bloom boost
uniform float bloomThreshold = 0.8;     // Threshold for bloom to kick in
uniform float desaturation = 0.15;       // Amount to desaturate (blend toward grayscale)
uniform float hueShiftAmt = 0.05;       // Amount (in radians) to shift hue for final color grading

// function to shift hue using the RGB -> YIQ conversion
vec3 hueShift(vec3 color, float hue) {
    // Convert RGB to YIQ
    const mat3 rgb2yiq = mat3(
        0.299,     0.587,     0.114,
        0.595716, -0.274453, -0.321263,
        0.211456, -0.522591,  0.311135
    );
    // convert YIQ back to RGB
    const mat3 yiq2rgb = mat3(
        1.0,  0.9563,  0.6210,
        1.0, -0.2721, -0.6474,
        1.0, -1.1070,  1.7046
    );
    vec3 yiq = rgb2yiq * color;
    float cosAngle = cos(hue);
    float sinAngle = sin(hue);
    // rotate the chrominance components (I and Q)
    vec2 iqRot;
    iqRot.x = yiq.g * cosAngle - yiq.b * sinAngle;
    iqRot.y = yiq.g * sinAngle + yiq.b * cosAngle;
    yiq.g = iqRot.x;
    yiq.b = iqRot.y;
    return clamp(yiq2rgb * yiq, 0.0, 1.0);
}

void main() {
    vec2 point = texcoord.st;
    vec3 color = texture2D(gcolor, point).rgb;
    
    // gamma correction
    color = pow(color, vec3(1.0 / gamma));
    
    // contrast adjustment
    color = (color - 0.5) * contrast + 0.5;
    
    // vibrance adjustment
    float avg = (color.r + color.g + color.b) / 3.0;
    color = mix(vec3(avg), color, vibrance);
    
    // whitewash effect
    color = mix(color, vec3(1.0), whitewash);
    
    // color shifts
    color.g += greenShift;
    color.r += warmShift;
    
    // shitty fake bloom / source engine HDR like thing
    float intensity = max(color.r, max(color.g, color.b));
    if (intensity > bloomThreshold) {
        color += bloomFactor * (intensity - bloomThreshold);
    }
    
    // slight desaturation
    float gray = (color.r + color.g + color.b) / 3.0;
    color = mix(color, vec3(gray), desaturation);
    
    // final hue shift
    color = hueShift(color, hueShiftAmt);
    
    gl_FragColor = vec4(color, 1.0);
}
