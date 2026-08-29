import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// One Ameren Illinois hosting-capacity grid segment — how much new solar (MW)
/// the local distribution grid can accept at that spot, and whether the circuit
/// is constrained. Sourced from Ameren's public ArcGIS hosting-capacity map
/// (free, no key). Rendered as colored zones on Sales Ranch.
class HcCell {
  final List<LatLng> ring;
  final double maxGenMw; // max generation the grid can host here
  final bool wscr; // WSCR violation — hard/expensive to interconnect
  final String feederId;
  final String voltage;
  final String limiter; // limiting factor (e.g. DeltaVlt)

  const HcCell({
    required this.ring,
    this.maxGenMw = 0,
    this.wscr = false,
    this.feederId = '',
    this.voltage = '',
    this.limiter = '',
  });

  /// Sales-facing tier — how easily this area can take a new solar system.
  /// 2 = open (green), 1 = limited (amber), 0 = constrained (red).
  int get tier {
    if (wscr || maxGenMw < 0.5) return 0;
    if (maxGenMw < 2) return 1;
    return 2;
  }

  Color get color {
    switch (tier) {
      case 2:
        return const Color(0xff22C55E); // open — grid can take solar
      case 1:
        return const Color(0xffF59E0B); // limited
      default:
        return const Color(0xffEF4444); // constrained
    }
  }

  static const Color openColor = Color(0xff22C55E);
  static const Color limitedColor = Color(0xffF59E0B);
  static const Color constrainedColor = Color(0xffEF4444);
}
