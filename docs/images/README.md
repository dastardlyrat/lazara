# Lazara captures

This directory contains approved, user-supplied Lazara comparison screenshots.

Current README comparison, in display order:

- `lazara-lead-split-comparison.png`: exact 50/50 lead composite with the
  unenhanced source on the left and enhanced source on the right;
- `lazara-lead-unenhanced.png`: the user identified image 1 as unenhanced;
- `lazara-lead-enhanced.png`: the user identified image 2 as enhanced;
- `lazara-split-comparison.png`: exact 50/50 composite with the no-effect
  source on the left and effects-enabled source on the right;
- `lazara-no-effect.png`: the user identified the second attachment as no
  effect;
- `lazara-effects-enabled.png`: the user identified the first attachment as
  effects enabled.
- `lazara-field-split-comparison.png`: exact 50/50 composite with the second
  scene's original source on the left and enhanced source on the right;
- `lazara-field-original.png`: user-corrected original source;
- `lazara-field-enhanced.png`: user-corrected enhanced source.

The composite preserves source pixels exactly: columns 0-1279 come from the
left half of `lazara-no-effect.png`, and columns 1280-2559 come from the right
half of `lazara-effects-enabled.png`. The lead composite uses
`lazara-lead-unenhanced.png` on the left and `lazara-lead-enhanced.png` on the
right. The field composite follows the same rule using
`lazara-field-original.png` on the left and
`lazara-field-enhanced.png` on the right. All files are 2560 x 1440 PNG images.
No generated placeholder image is treated as a real effect result.
