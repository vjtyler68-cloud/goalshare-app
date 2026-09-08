import 'package:flutter/material.dart';

/// Solar Cowboys door-status workflow — the SINGLE source of truth for every
/// status code, its label, colour, and which of the 3 swipeable pages it lives
/// on. Never hardcode status strings in the UI; read them from here.
class CanvassStatus {
  final String code;
  final String label;
  final Color color;
  final int page; // 1 = Contact, 2 = Deal progress, 3 = Dead-end
  const CanvassStatus(this.code, this.label, this.color, this.page);

  static const List<CanvassStatus> all = [
    // Neutral — a pre-loaded home nobody has knocked yet (page 0 = not shown in
    // the manual disposition grid).
    CanvassStatus('NV', 'Not Visited', Color(0xff64748B), 0),
    // Page 1 — Contact outcomes
    CanvassStatus('APPT', 'Appointment Set', Color(0xff8B5CF6), 1),
    // Solar interest — surfaced on the FIRST disposition page so a door can be
    // marked solar in one tap (green ☀️ on the map). Code stays 'SLR' so every
    // funnel / colour / backend rule keeps working.
    CanvassStatus('SLR', 'Solar', Color(0xff22C55E), 1),
    CanvassStatus('NH', 'Not Home', Color(0xffF97316), 1),
    CanvassStatus('NI', 'Not Interested', Color(0xffEF4444), 1),
    CanvassStatus('RNTR', 'Renter', Color(0xff991B1B), 1),
    CanvassStatus('NQ', 'Not Qualified', Color(0xffFB7185), 1),
    CanvassStatus('GB', 'Go Back', Color(0xff3B82F6), 1),
    // Page 2 — Deal progress
    CanvassStatus('CB', 'Callback', Color(0xff38BDF8), 2),
    CanvassStatus('CS', 'Contract Signed', Color(0xffF59E0B), 2),
    CanvassStatus('RS', 'Ready / Reschedule', Color(0xff7C3AED), 2),
    CanvassStatus('SALE', 'Sale Closed', Color(0xff2563EB), 2),
    CanvassStatus('WON', 'Deal Won', Color(0xff16A34A), 2),
    // Page 3 — Dead-end / Do not contact
    CanvassStatus('CF', 'Confirmed No', Color(0xff991B1B), 3),
    CanvassStatus('MISS', 'Missed', Color(0xffF97316), 3),
    CanvassStatus('CA', 'Cancelled Appt', Color(0xffEF4444), 3),
    CanvassStatus('NN', 'No Notice', Color(0xffDC2626), 3),
    CanvassStatus('NOGO', 'Do Not Contact', Color(0xff111827), 3),
    CanvassStatus('SI', 'Storm / Sign Interest', Color(0xff38BDF8), 3),
  ];

  static const List<String> pageTitles = [
    'Contact',
    'Deal Progress',
    'Dead-End',
  ];

  static CanvassStatus byCode(String? code) => all.firstWhere(
        (s) => s.code == code,
        orElse: () => all.first, // default "Not Visited" (neutral gray)
      );

  /// Short visual cue shown above a marked home on the ranch map.
  static String emojiFor(String? code) {
    switch (code) {
      case 'APPT':
        return '📅';
      case 'NH':
        return '🏠';
      case 'NI':
        return '👎';
      case 'RNTR':
        return '🔑';
      case 'NQ':
        return '🚫';
      case 'GB':
        return '🔄';
      case 'CB':
        return '📞';
      case 'SLR':
        return '☀️';
      case 'CS':
        return '📝';
      case 'RS':
        return '🔁';
      case 'SALE':
        return '💰';
      case 'WON':
        return '🏆';
      case 'CF':
        return '❌';
      case 'MISS':
        return '⏰';
      case 'CA':
        return '❌';
      case 'NN':
        return '🔕';
      case 'NOGO':
        return '🚫';
      case 'SI':
        return '⛈️';
      default:
        return '';
    }
  }

  static List<CanvassStatus> forPage(int page) =>
      all.where((s) => s.page == page).toList();

  /// A status that counts as a booked appointment (for funnels).
  static bool isAppt(String code) => code == 'APPT';

  /// A status that counts as a closed sale (for funnels / leaderboards).
  static bool isSale(String code) =>
      code == 'SALE' || code == 'WON' || code == 'CS';

  /// A door that has been "converted into something" — worth KEEPING when its
  /// area is unassigned. Appointments, any deal-progress status (solar, callback,
  /// contract, sale, won…), sign-interest leads, and do-not-contact records (so
  /// nobody re-knocks them). Everything else is just an un-worked knock and gets
  /// cleared out with the area.
  static bool isConverted(String code) => const {
        'APPT', // appointment set
        'SLR', 'CB', 'CS', 'RS', 'SALE', 'WON', // deal progress / sale
        'SI', // sign interest (a lead)
        'NOGO', 'CF', // do-not-contact / confirmed no — never re-knock
      }.contains(code);
}
