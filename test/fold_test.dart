import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/ui/core/widgets.dart';

void main() {
  Future<({FoldPosture posture, double at})?> foldWith(
    WidgetTester tester,
    List<DisplayFeature> features,
  ) async {
    ({FoldPosture posture, double at})? fold;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(displayFeatures: features),
        child: Builder(
          builder: (context) {
            fold = foldOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return fold;
  }

  testWidgets('a fold down the middle opens like a book', (tester) async {
    final fold = await foldWith(tester, const [
      DisplayFeature(
        bounds: Rect.fromLTWH(353, 0, 0, 823),
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureFlat,
      ),
    ]);
    expect(fold, (posture: FoldPosture.book, at: 353.0));
  });

  testWidgets('a half-open fold across stands on a table', (tester) async {
    final fold = await foldWith(tester, const [
      DisplayFeature(
        bounds: Rect.fromLTWH(0, 353, 823, 0),
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureHalfOpened,
      ),
    ]);
    expect(fold, (posture: FoldPosture.tabletop, at: 353.0));
  });

  testWidgets('a flat fold across and a cutout are one screen', (tester) async {
    final fold = await foldWith(tester, const [
      DisplayFeature(
        bounds: Rect.fromLTWH(0, 353, 823, 0),
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureFlat,
      ),
      DisplayFeature(
        bounds: Rect.fromLTWH(380, 0, 40, 30),
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
    ]);
    expect(fold, isNull);
  });

  testWidgets('an iPhone Duo open flat in landscape splits across', (
    tester,
  ) async {
    isPhoneDevice = true;
    addTearDown(() => isPhoneDevice = false);
    final fold = await foldWith(tester, const [
      DisplayFeature(
        bounds: Rect.fromLTWH(0, 334.5, 951, 0),
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureFlat,
      ),
    ]);
    expect(fold, (posture: FoldPosture.across, at: 334.5));
  });
}
