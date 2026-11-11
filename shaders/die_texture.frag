// Texture procédurale du dé animé (P2b). Calculée ici, jamais de bitmap :
// grain ou points, en niveaux de gris, multipliée aux couleurs de sommets
// (ombrage plat calculé côté Dart) via BlendMode.modulate.
//
// Limite connue : drawVertices ne transmet pas de coordonnées de texture
// à un FragmentProgram, la texture est donc ancrée à l'écran et non à la
// face (elle ne tourne pas avec le dé). Acceptable pour du grain/des points
// fins ; à revoir si une texture directionnelle (veines) est ajoutée.

#version 460 core

#include <flutter/runtime_effect.glsl>

uniform float uTexture; // 0 = aucune, 1 = grain, 2 = points
uniform float uOpacity; // intensité 0..1

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  float t = 0.0;
  if (uTexture > 1.5) {
    // Points : trame de 7 dp, disque plein de rayon ~1,3 dp.
    vec2 cell = fract(p / 7.0) - 0.5;
    t = 1.0 - step(0.19, length(cell));
  } else if (uTexture > 0.5) {
    // Grain : bruit par cellule de 2 dp.
    t = hash(floor(p / 2.0));
  }
  float shade = 1.0 - uOpacity * t;
  fragColor = vec4(shade, shade, shade, 1.0);
}
