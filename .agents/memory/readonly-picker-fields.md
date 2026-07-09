---
name: Read-only date/picker fields must be fully tappable
description: Why picker fields need GestureDetector+AbsorbPointer, not icon-only onTap
---

# Read-only picker fields

Any `readOnly: true` text field that opens a picker (date, etc.) must be wrapped so the **whole field** opens the picker:

```dart
GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: () => controller.pickDate(context),
  child: AbsorbPointer(child: CustomTextFormWidget(readOnly: true, ...)),
)
```

**Why:** The original pattern put the picker only on a small prefix calendar `IconButton`. Tapping the field body did nothing, so users often never set the value. For the Create Mission form this meant the required due date stayed empty and **every save silently failed** the "select a due date" validation — reported by the user as "won't save." Same latent bug existed on the Vision Board date field.

**How to apply:** When adding or reviewing any readOnly picker field, verify the entire field area triggers the picker, not just the icon. AbsorbPointer keeps the inner field from stealing/absorbing the tap ambiguously and prevents double-trigger with the icon button.
