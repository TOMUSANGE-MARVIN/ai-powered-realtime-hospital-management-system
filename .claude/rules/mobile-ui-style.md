---
paths:
  - "mobile/lib/**/*.dart"
---

# Ask Musawo mobile UI style

These rules apply to every Flutter screen and widget. They override generic UI defaults such as large rounded cards, pill buttons and pastel tints.

## Corners: nearly sharp

- Use `kCardRadius` (4px, in `lib/core/theme/app_colors.dart`) for every card, button, input, chip, badge, tile, sheet, banner, chat bubble and skeleton.
- Never hard-code a radius above 4, for example `BorderRadius.circular(16)` or `borderRadius: 20`. Reference `kCardRadius` so one constant controls the whole app.
- Never use `StadiumBorder()`, `BorderRadius.circular(999)` or other pill shapes. `kPillRadius` is an alias of `kCardRadius`.
- Only avatars, status dots and round icon badges stay circular (`BoxShape.circle`, `ClipOval`, `CircleAvatar`).

## Color: vivid, not pastel

- Teal `seedTeal` (`#128A8B`) is the only primary color. It is used for primary buttons, active navigation, links and focus states. Never add a competing primary color such as blue, indigo or purple.
- Action tiles and status badges use a solid palette foreground color as the fill, not the pastel background. Text on those fills is:
  - white on teal, blue, pink, purple, red and deep teal
  - dark ink `#2B1A00` on orange (`#FF9800`) and amber (`#FFA000`)
- Status fills:
  - requested: orange
  - confirmed / scheduled: `seedTeal`
  - in progress: amber
  - completed: `#0B5F60`
  - cancelled: `#D32F2F`
- Pastel backgrounds (the pastel half of the accent pairs in `app_colors.dart`) are only for specialty/category cards and small icon circles. Don't use them for buttons, actions or status.
- Destructive secondary actions (e.g. Cancel) may use a light red tint with red text and a border, so they stay less prominent than the primary action.
- The page background is `tealBackground` (`#F2FAFA`). Cards are white.
- Only use colors from `app_colors.dart`. Never invent new hex values when a palette color fits.

## General

- Keep shadows subtle: at most the `SoftCard` shadow. No gradients except the brand `heroGradient` on hero/promo surfaces.
- Keep the text hierarchy clear: titles in `darkTealBackground` (`#102828`), secondary text in muted grey-teal (`#6B7A7A`).
- Make touch targets at least 48px tall.
- Use real content. Never use lorem ipsum or "John Doe".

## Before finishing UI work

- Run `grep -rnE "circular\((1[0-9]|[5-9]|[2-9][0-9]+)(\.[0-9]+)?\)|StadiumBorder|circular\(999\)" mobile/lib`. It should return nothing.
- Run `flutter analyze` on the changed files, and format only those files. Never run `dart format lib`.
