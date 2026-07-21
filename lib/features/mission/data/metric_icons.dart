import 'package:flutter/material.dart';

/// Fixed icon registry for user-added custom stat cards.
///
/// Kept `const` (and keyed by a short String that is what actually gets
/// persisted) so the icons tree-shake correctly and old saved metrics — which
/// have no icon at all — can fall back without crashing.
const Map<String, IconData> kMetricIcons = <String, IconData>{
  'home': Icons.home,
  'phone': Icons.phone,
  'dollar': Icons.attach_money,
  'chart': Icons.bar_chart,
  'briefcase': Icons.work,
  'handshake': Icons.handshake,
  'calendar': Icons.calendar_today,
  'email': Icons.email,
  'people': Icons.people,
  'target': Icons.track_changes,
  'star': Icons.star,
  'trophy': Icons.emoji_events,
  'book': Icons.menu_book,
  'pencil': Icons.edit,
  'laptop': Icons.laptop,
  'dumbbell': Icons.fitness_center,
  'run': Icons.directions_run,
  'heart': Icons.favorite,
  'food': Icons.restaurant,
  'water': Icons.water_drop,
  'sleep': Icons.bedtime,
  'paint': Icons.palette,
  'camera': Icons.camera_alt,
  'music': Icons.music_note,
  'car': Icons.directions_car,
  'truck': Icons.local_shipping,
  'tools': Icons.build,
  'medical': Icons.medical_services,
  'school': Icons.school,
  'cart': Icons.shopping_cart,
};

/// Used for metrics saved before icons existed, and for anything unknown.
const String kDefaultMetricIconKey = 'target';

/// Ordered keys for the picker grid (insertion order of [kMetricIcons]).
List<String> get kMetricIconKeys => kMetricIcons.keys.toList(growable: false);

/// Never returns null — unknown/legacy keys degrade to the default icon.
IconData metricIconFor(String? key) =>
    kMetricIcons[key] ?? kMetricIcons[kDefaultMetricIconKey]!;
