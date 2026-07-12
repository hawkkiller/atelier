#include <flutter/runtime_effect.glsl>

uniform float uDevicePixelRatio;

out vec4 fragColor;

float random(vec2 point) {
  return fract(sin(dot(point, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
  vec2 pixel = FlutterFragCoord().xy * uDevicePixelRatio;
  float noise = random(pixel);
  fragColor = vec4(vec3(noise), 0.08);
}
