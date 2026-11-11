// Mouvement, chronologie et skins du dé animé (P2b) : logique pure.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/pixel_icon.dart';
import 'package:personnages/core/widgets/pixel_icons/die_result_pixel_icons.dart';
import 'package:personnages/features/characters/domain/dice3d/d20_orientation.dart';
import 'package:personnages/features/characters/domain/dice3d/die_math.dart';
import 'package:personnages/features/characters/presentation/widgets/dice/die_motion.dart';
import 'package:personnages/features/characters/presentation/widgets/dice/die_skin.dart';

void main() {
  group('chronologie', () {
    test('1 400 ms pour un dé, +120 ms pour le second', () {
      expect(DieTimeline.totalDuration(1).inMilliseconds, 1400);
      expect(DieTimeline.totalDuration(2).inMilliseconds, 1520);
    });

    test('le second plateau démarre 120 ms après le premier', () {
      // À 120 ms (0,0789 de 1 520), le premier a avancé, le second pas.
      const v = 120 / 1520;
      expect(DieTimeline.plateProgress(v, 0, 2), closeTo(120 / 1400, 1e-9));
      expect(DieTimeline.plateProgress(v, 1, 2), 0);
      expect(DieTimeline.plateProgress(1, 0, 2), 1);
      expect(DieTimeline.plateProgress(1, 1, 2), 1);
      expect(DieTimeline.plateProgress(0, 0, 2), 0);
    });

    test('fondu du résultat : derniers 200 ms', () {
      expect(DieTimeline.resultFade(0.5), 0);
      expect(DieTimeline.resultFade(1200 / 1400), 0);
      expect(DieTimeline.resultFade(1300 / 1400), closeTo(0.5, 1e-9));
      expect(DieTimeline.resultFade(1), 1);
    });

    test('tressautement du 1 naturel : +/- 4 dp, nul avant et à la fin', () {
      expect(DieTimeline.shakeOffsetDp(0.2), 0);
      expect(DieTimeline.shakeOffsetDp(1), closeTo(0, 1e-9));
      var peak = 0.0;
      for (var i = 0; i <= 200; i++) {
        final off = DieTimeline.shakeOffsetDp(0.893 + i * 0.107 / 200);
        peak = math.max(peak, off.abs());
      }
      expect(peak, greaterThan(1));
      expect(peak, lessThanOrEqualTo(4));
    });
  });

  group('mouvement', () {
    test('la pose finale est exactement l\'orientation cible, sans décalage '
        'ni rebond, échelle 1', () {
      for (var value = 1; value <= 20; value++) {
        final target = D20Orientation.forValue(value);
        final pose = DiePose();
        DieMotion.evaluate(1, target.w, target.x, target.y, target.z, pose);
        expect(pose.qw, closeTo(target.w, 1e-12));
        expect(pose.qx, closeTo(target.x, 1e-12));
        expect(pose.qy, closeTo(target.y, 1e-12));
        expect(pose.qz, closeTo(target.z, 1e-12));
      }
    });

    test('quaternion toujours unitaire pendant le lancer', () {
      final target = D20Orientation.forValue(13);
      final pose = DiePose();
      for (var i = 0; i <= 100; i++) {
        DieMotion.evaluate(
          i / 100,
          target.w,
          target.x,
          target.y,
          target.z,
          pose,
        );
        final n = math.sqrt(
          pose.qw * pose.qw +
              pose.qx * pose.qx +
              pose.qy * pose.qy +
              pose.qz * pose.qz,
        );
        expect(n, closeTo(1, 1e-9));
      }
    });

    test('~3 tours au lancer, un quart de tour restant à 70 %', () {
      expect(DieMotion.residualAngle(0), closeTo(3.25 * 2 * math.pi, 1e-9));
      expect(DieMotion.residualAngle(0.70), closeTo(math.pi / 2, 1e-9));
      expect(DieMotion.residualAngle(1), closeTo(0, 1e-12));
    });

    test('rotation résiduelle monotone décroissante', () {
      var last = double.infinity;
      for (var i = 0; i <= 200; i++) {
        final a = DieMotion.residualAngle(i / 200);
        expect(a, lessThanOrEqualTo(last + 1e-9));
        last = a;
      }
    });
  });

  group('contraste et skins', () {
    test('les deux skins livrés : chiffre/pastille >= 4,5:1 (visé 7:1)', () {
      for (final skin in [DieSkin.tavernOak, DieSkin.brassSeal]) {
        expect(
          skin.numberContrast,
          greaterThanOrEqualTo(kMinNumberContrast),
          reason: skin.name,
        );
        expect(skin.numberContrast, greaterThanOrEqualTo(7), reason: skin.name);
        expect(skin.isReadable, isTrue);
        // Aucun repli pour un skin lisible.
        expect(identical(skin.ensureReadable(), skin), isTrue);
      }
    });

    test('contrastRatio : noir/blanc = 21, identique = 1', () {
      expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 1e-9));
      expect(contrastRatio(Colors.red, Colors.red), closeTo(1, 1e-9));
    });

    test('skin au contraste insuffisant : repli textPrimary sur '
        'parchmentCard', () {
      final bad = DieSkin.tavernOak.copyWith(
        numberColor: AppColors.woodMedium,
        numberBackdropColor: AppColors.woodDark,
      );
      expect(bad.numberContrast, lessThan(kMinNumberContrast));
      expect(bad.isReadable, isFalse);

      final safe = bad.ensureReadable();
      expect(safe.numberColor, AppColors.textPrimary);
      expect(safe.numberBackdropColor, AppColors.parchmentCard);
      expect(safe.numberContrast, greaterThanOrEqualTo(kMinNumberContrast));
      expect(safe.isReadable, isTrue);
    });

    test('pastille trop transparente (< 70 %) : repli', () {
      final faint = DieSkin.tavernOak.copyWith(numberBackdropOpacity: 0.4);
      expect(faint.isReadable, isFalse);
      expect(faint.ensureReadable().numberBackdropOpacity, 1);
    });

    test('couleurs des skins livrés = tokens AppColors', () {
      const oak = DieSkin.tavernOak;
      expect(oak.baseColor, AppColors.woodLight);
      expect(oak.shadeColor, AppColors.woodMedium);
      expect(oak.edgeColor, AppColors.woodDark);
      expect(oak.numberColor, AppColors.textOnWood);
      expect(oak.numberBackdropColor, AppColors.woodDark);
      expect(oak.lightTint, AppColors.goldStart);
      expect(oak.textureId, DieTextureId.grain);
      expect(oak.textureOpacity, 0.2);
      expect(oak.edgeWidth, 2);
      const brass = DieSkin.brassSeal;
      expect(brass.baseColor, AppColors.parchmentCardAlt);
      expect(brass.shadeColor, AppColors.woodLight);
      expect(brass.shadeAmount, 0.35);
      expect(brass.edgeColor, AppColors.goldEnd);
      expect(brass.numberColor, AppColors.textPrimary);
      expect(brass.numberBackdropColor, AppColors.parchmentCard);
      expect(brass.numberBackdropOpacity, 0.8);
      expect(brass.textureId, DieTextureId.dots);
      expect(brass.textureOpacity, 0.15);
      expect(DieSkin.defaultSkin, oak);
    });

    test('paramètres bornés : paliers 3 à 5, arêtes 1 à 2 dp', () {
      for (final skin in [DieSkin.tavernOak, DieSkin.brassSeal]) {
        expect(skin.shadeSteps, inInclusiveRange(3, 5));
        expect(skin.edgeWidth, inInclusiveRange(1, 2));
      }
      expect(
        () => DieSkin.tavernOak.copyWith(shadeSteps: 2),
        throwsAssertionError,
      );
      expect(
        () => DieSkin.tavernOak.copyWith(edgeWidth: 3),
        throwsAssertionError,
      );
    });

    test('listes fermées : textures et shaders', () {
      expect(DieTextureId.values.map((e) => e.name), ['none', 'grain', 'dots']);
      expect(DieShaderId.values.map((e) => e.asset), [
        'shaders/die_texture.frag',
      ]);
    });

    test('paliers d\'ombrage : du plus sombre au plus clair, N couleurs', () {
      final skin = DieSkin.tavernOak;
      final colors = [
        for (var s = 0; s < skin.shadeSteps; s++) skin.faceColorArgb(s),
      ];
      expect(colors.toSet(), hasLength(skin.shadeSteps));
      expect(
        Color(colors.first).computeLuminance(),
        lessThan(Color(colors.last).computeLuminance()),
      );
      // Opacité globale (dé écarté).
      expect(
        Color(skin.faceColorArgb(0, opacity: 0.55)).a,
        closeTo(0.55, 0.01),
      );
    });

    test('égalité par valeur', () {
      expect(DieSkin.tavernOak.copyWith(), equals(DieSkin.tavernOak));
      expect(
        DieSkin.tavernOak.copyWith(shadeSteps: 5),
        isNot(equals(DieSkin.tavernOak)),
      );
    });
  });

  group('icônes pixel provisoires (étoile / crâne)', () {
    for (final entry in kDieResultPixelMatrices.entries) {
      test('${entry.key} : 16 lignes de 16, 20 à 150 cellules pleines', () {
        final m = entry.value;
        expect(m, hasLength(kPixelIconGrid));
        for (final row in m) {
          expect(row, hasLength(kPixelIconGrid));
          expect(RegExp(r'^[.#]+$').hasMatch(row), isTrue);
        }
        final filled = m.join().split('#').length - 1;
        expect(filled, inInclusiveRange(20, 150));
        final middle = m.sublist(2, 14).join().split('#').length - 1;
        expect(middle, greaterThanOrEqualTo(8));
      });
    }

    test('étoile et crâne bien distincts (Hamming >= 20)', () {
      final a = kDieResultPixelMatrices[kDieStarKey]!.join();
      final b = kDieResultPixelMatrices[kDieSkullKey]!.join();
      var diff = 0;
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) diff++;
      }
      expect(diff, greaterThanOrEqualTo(20));
    });
  });

  test('Vec3 / projection : valeurs usuelles', () {
    expect(const Vec3(3, 4, 0).length, 5);
    expect(const Vec3(0, 0, 0).normalized(), Vec3.zero);
  });
}
