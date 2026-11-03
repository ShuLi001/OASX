import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Geometry shared by the overview and task catalog card layouts.
const double kHomeOverviewTaskCardExtent = 68;
const double kHomeCatalogTaskCardExtent = 76;
const double kHomeTaskCardGap = 8;
const double kHomeTaskGroupGap = 8;

/// Reserve three separate 48px touch targets plus readable task metadata.
bool homeOverviewActionsBelow(double cardWidth, double textScale, bool touch) =>
    touch && cardWidth < 208 + 80 * math.max(1, textScale);

double homeOverviewCardExtent(double cardWidth, double textScale, bool touch) =>
    kHomeOverviewTaskCardExtent +
    math.max(0, textScale - 1) * 40 +
    (homeOverviewActionsBelow(cardWidth, textScale, touch) ? 52 : 0);

bool homeUsesTouchTargets(BuildContext context) =>
    switch (Theme.of(context).platform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => true,
      _ => false,
    };

/// Count columns from the available pane width, preserving readable card text.
int homeTaskColumns(double width, double textScale) => math.max(
  1,
  math.min(
    2,
    ((width + kHomeTaskCardGap) /
            (300 * math.max(1, textScale) + kHomeTaskCardGap))
        .floor(),
  ),
);
