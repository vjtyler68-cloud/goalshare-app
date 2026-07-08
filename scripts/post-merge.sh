#!/bin/bash
set -e

# Post-merge setup for the Spanx Flutter app.
# Fetches Dart/Flutter dependencies after a task is merged.
# Flutter may not be installed in every environment (e.g. the Replit
# container), so we skip gracefully rather than failing the merge.

if command -v flutter >/dev/null 2>&1; then
  echo "Flutter found — running 'flutter pub get'…"
  flutter pub get
elif command -v dart >/dev/null 2>&1; then
  echo "Dart found (no Flutter) — running 'dart pub get'…"
  dart pub get
else
  echo "Flutter/Dart not installed in this environment — skipping pub get."
  echo "Run 'flutter pub get' on a machine with the Flutter SDK before building."
fi

echo "Post-merge setup complete."
