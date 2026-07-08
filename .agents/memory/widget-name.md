---
name: Network Image Widget
description: The correct widget to use for network images — avoid the wrong class name.
---

# Network Image Widget

## The rule
The custom network image wrapper is `ResponsiveNetworkImage` in `lib/core/global_widgets/app_network_image.dart`. There is **no** `AppNetworkImage` class anywhere in the codebase.

**Why:** The file is named `app_network_image.dart` which suggests `AppNetworkImage`, but the actual class inside is `ResponsiveNetworkImage`. Using the wrong name is a hard compile error.

## How to apply
- For new screens that need a simple network image: use `CachedNetworkImage` directly (already a dependency via `cached_network_image` package). This avoids the naming confusion.
- For percentage-based sizing (relative to screen): use `ResponsiveNetworkImage` from `lib/core/global_widgets/app_network_image.dart`.
