import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppFonts {
  static final TextStyle playfair = GoogleFonts.playfair(
    fontStyle: FontStyle.italic,
  );
  static final TextStyle spaceGrotesk = GoogleFonts.spaceGrotesk();
}
