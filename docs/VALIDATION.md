# Lazara Source-Derived Color-Theory Recovery

- **Date:** 2026-07-23
- **Updated:** 2026-10-27
- **Artifact:** `effects/OCCULT_lazara.fx`
**State:** Implemented in the published shader source; static checks passed; live
ReShade compile and visual validation pending

## Requested behavior

Color recovery must not liven an image by preferring a fixed hue family such as
green. It should decide recovery strength from the colors already present and
their color-theory relationship to the nearby image palette.

## Previous behavior

The previous implementation explicitly:

- favored fixed green, cyan, blue, and violet hue sectors;
- reduced recovery for red and brown families;
- exposed `Live Scheme Boost`, `Scheme Pull`, and `Scheme Hue Width` controls
  around that fixed palette.

That behavior was present in the earlier implementation used as the comparison
baseline. The retained baseline copies were not modified. Private working-copy
identifiers and historical source hashes are omitted from this public report.

## Current behavior

The effect now:

1. samples the four immediate color neighbors;
2. reduces cross-boundary influence using luma agreement;
3. weights useful palette evidence by existing chroma;
4. selects the strongest luma-compatible chromatic neighbor as the local
   reference, avoiding a blended hue that is not actually present;
5. compares the source hue to that palette;
6. recognizes analogous, complementary, triadic, and split-complement
   relationships;
7. uses that relationship only to vary recovery strength;
8. preserves the source hue instead of rotating it toward a preferred family;
9. guards neutral surfaces from receiving a hue;
10. gives the main and chromatic-split branches the same source-derived harmony
    decision.

No automatic green, cyan, blue, violet, red, brown, warm, or cool family is
preferred.

## 2026-07-25 vibrancy revision

The recovery is now deliberately stronger while retaining the source-evidence
boundary:

1. source and accepted local palette colors receive hue-evidence scores;
2. the stronger observed hue family supplies the vibrancy authority;
3. a strong source hue remains unchanged and is intensified in place;
4. a weak but non-neutral source hue may migrate slightly toward a stronger
   accepted neighboring hue;
5. hue migration follows the shortest circular hue path;
6. fully neutral pixels receive zero hue migration;
7. saturation moves toward a higher target derived from dominant hue evidence
   and harmony support;
8. the recovered RGB result is pulled back toward the pre-recovery luma;
9. muddy regions retain recovery when real source or local chromatic authority
   exists;
10. the chromatic-split branch receives only thirty-five percent of the main
    vibrancy drive and cannot choose the winning hue.

Green is therefore favored only when green is the strongest observed source or
accepted local hue. The same rule applies symmetrically to red, amber, blue,
violet, cyan, and other hue families.

## 2026-10-27 inverted degradation mode

The effect now exposes `Invert Color Recovery` as a production control.
This is separate from the existing diagnostic-only `Invert` visibility mode.

- `Recover Color` is the default and preserves the existing reconstruction;
- `Degrade Color` bypasses the revival reconstruction rather than merely
  suppressing its final blend;
- degradation moves RGB toward source luma, removing chroma without changing
  the intended luma;
- admitted recovery, harmony, and vibrancy evidence increase the degradation
  amount, while a nonzero baseline makes the switch visibly effective across
  colored regions;
- highlight protection is retained as a partial guard, not a full bypass;
- the chromatic-split branch is not entered in degradation mode, so it cannot
  reintroduce colored fringes or its two offset texture reads;
- the former `Revived Color` view is now labeled `Color Result` and displays
  the historical pre-split revival candidate in recovery mode or the degradation
  candidate in degradation mode.

The switch defaults to recovery so existing presets retain their prior output.
This section records the implementation present in the published source; live
ReShade compile and visual acceptance remain pending.

## Control changes

Preset-facing shader symbols remain unchanged for compatibility, but their UI
purpose is corrected:

- `Live Scheme Boost` → `Harmony Boost`
- `Scheme Pull` → `Harmony Guidance`
- `Scheme Hue Width` → `Harmony Tolerance`
- `Warmth` → `Manual Temperature Bias`

New controls:

- `Invert Color Recovery`
  - selects normal source-derived recovery or intentional luma-preserving color
    degradation;
- `Dominant Hue Vibrancy`
  - controls movement toward the stronger luma-preserving saturation target;
- `Muted Hue Migration`
  - bounds how far weak but non-neutral color may move toward the strongest
    accepted local hue.

`Manual Temperature Bias` remains an explicit artistic override and defaults to
zero. At zero, automatic recovery is entirely source- and harmony-derived.

## Debug additions

The `View` selector adds:

- `Local Palette`
  - displays the strongest chromatic, luma-compatible nearby source color used
    for the decision;
- `Harmony Support`
  - grayscale evidence showing where a recognized color relationship is
    strengthening recovery;
- `Vibrancy Drive`
  - grayscale evidence showing the dominance-aware saturation drive;
- `Hue Migration`
  - grayscale evidence showing where a weak source hue is allowed to move
    toward the accepted local hue.

## Static validation

Passed:

- fixed hue-sector promotion functions and constants removed;
- red/brown penalty and earth-bias functions removed;
- source hue remains the recovered HSV hue;
- local palette and harmony helpers have resolved call sites;
- absolute-hue rotation checks return identical support for the same analogous,
  triadic, split-complement, and complementary offsets across the hue wheel;
- dominance checks preserve green, red, and blue source families independently;
- neutral gray receives zero hue migration even beside a chromatic neighbor;
- weak non-neutral color migrates only partially toward stronger local evidence;
- `Invert Color Recovery` exists once, defaults to recovery, and controls the
  production path rather than the diagnostic post-process;
- degradation mode bypasses both `OCCULT_RM_67_Revive` calls and the
  chromatic-split texture reads;
- the degradation helper performs no texture reads;
- the source still contains eight physical `OCCULT_RM_LoadColor` call sites,
  so the feature adds no sampling site;
- a representative red, green, blue, cyan, skin/earth, and neutral model test
  reduces or preserves chroma for both zero and full evidence;
- that model test preserves weighted source luma to numerical tolerance;
- the complete include tree preprocesses without an error through DXC using
  the supplied ReShade header and a ReShade 6.0 version define;
- opening and closing brace counts match;
- opening and closing parenthesis counts match;
- retained baseline source copies remain unchanged.

Published effect SHA-256:

`4FE2A7052AD4CBFB3DE94BA179803A94AAAF0C4D0EE4AE12944BA6E9F8FB4DD9`

## Validation boundary

The reviewed build environment contained a usable ReShade header kit and the
effect's full include tree preprocessed successfully. No ReShade runtime/compiler
executable was available in that review environment. Microsoft FXC cannot substitute for that compiler:
it stops on ReShade's untyped `source` uniform annotation before reaching the
effect body. This pass therefore does not claim a ReShade compile or visual
acceptance. Live compilation must begin from the first hard error or warning in
the actual ReShade log.

## Tight live test order

1. Compile `OCCULT_lazara.fx`.
   - Stop and record the first hard error or warning cluster.
2. Set `Manual Temperature Bias = 0`.
3. View `Local Palette`.
   - It should follow nearby scene colors rather than settling on one global
     hue.
4. View `Harmony Support`.
   - It should be selective and grayscale.
   - A full white frame means the tolerance or palette evidence is too broad.
   - A full black frame means nearby chroma evidence is absent or too weak.
5. View `Vibrancy Drive`.
   - colored objects and accepted muted-color regions should be visibly active;
   - neutral surfaces may remain dark.
6. View `Hue Migration`.
   - should be sparse;
   - strong existing hues and neutral surfaces should remain dark;
   - only weak non-neutral colors beside stronger accepted palette evidence
     should become visible.
7. Leave `Invert Color Recovery = Recover Color` and view `Color Result`.
   - Existing colored objects should retain their hue identity.
   - Neutral walls, fog, metal, and gray UI surfaces must not become green or
     any other assigned hue.
8. View `Mud Mask`.
   - It should continue to identify muted, locally flat midtones.
9. View `Chromatic Split Only`.
   - It should remain an edge/channel accent and must not change the harmony
     decision.
10. Return to `Final Composite`.
   - Compare red, green, blue, yellow, cyan, magenta, skin/earth, and neutral
     surfaces.
   - No hue family should receive a systematic advantage unrelated to the local
     palette.
11. Set `Invert Color Recovery = Degrade Color` and compare `Color Result` with
    `Final Composite`.
    - Both views should show the same intentional chroma loss.
    - Scene brightness structure should remain stable.
    - Colored fringes from `Chromatic Split Only` should disappear.
    - Switching back to `Recover Color` should restore the prior Lazara result.

## Stop conditions

Stop and log before tuning if:

- the effect does not compile;
- warning `X4000` appears on a changed helper;
- neutral surfaces acquire a consistent hue;
- `Local Palette` becomes globally uniform without matching the scene;
- `Harmony Support` is full-frame white;
- an existing source hue visibly rotates;
- the chromatic-split branch changes which colors are promoted;
- degradation mode increases chroma, changes scene brightness structure, or
  leaves colored split fringes active.
