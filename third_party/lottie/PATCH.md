# Vendored `lottie` 3.3.3 + upstream trim-path fix

This is an unmodified copy of `lottie` 3.3.3 from pub.dev with a single upstream
patch applied. It exists only to work around a crash on Flutter web.

## The bug

`images/1.json` (the first slide of the landing-page step carousel in
`lib/Constant/Splash.dart`) has an animated Trim Path:

```json
{"ty": "tm", "s": {"a": 0, "k": 50}, "e": {"a": 0, "k": 100},
 "o": {"a": 1, "k": [{"t": 0, "s": [113]}, {"t": 136, "s": [833]}]}}
```

Because start is 50 and end is 100, neither of lottie's early-outs
(`start < 0.01 && end > 0.99`, or `|end - start - 1| < 0.01`) applies, so
rendering reaches `Utils.applyTrimPathIfNeeded`, which ended with:

```dart
var tempPath = pathMeasure.extractPath(newStart, newEnd);
path.set(tempPath);   // == path.reset(); path.addPath(tempPath);
```

On CanvasKit, `Path` is `LazyPath`: `extractPath` does not materialise anything,
it returns a path whose initializer still points at the `LazyPath` it was
extracted from — which is the very path `set()` just assigned it into. Building
it then cycles forever:

```
LazyPath.builtPath -> AddPathCommand.apply -> tempPath.builtPath
  -> buildExtractedPath -> builtMetricAtIndex -> buildIterator -> builtPath -> ...
```

The JS stack blows and Flutter reports a bare `Stack Overflow` with frames in
`lib/_engine/engine/lazy_path.dart`. Nothing on the landing page renders after that.

The engine half of this is real too: `LazyPath.shifted`, `.transformed` and
`.combined` all snapshot their source with `LazyPath.fromLazyPath`, but
`LazyPath.extracted` keeps a live reference. Still present in Flutter 3.44.8.

## The patch

Upstream commit
[`6814740`](https://github.com/xvrh/lottie-flutter/commit/681474017af53223f796f18fd4b3a94fd160afe3)
("fix: avoid CanvasKit stack overflow on animated trim paths #411", PR #428).

`applyTrimPathIfNeeded` / `applyTrimPathContentIfNeeded` now **return** the
trimmed path instead of assigning it back into the source, so no path ever
references itself. Callers were updated to use the returned value:

- `lib/src/utils/utils.dart` — both functions return `Path`
- `lib/src/animation/content/compound_trim_path_content.dart` — `apply` returns `Path`
- `lib/src/animation/content/base_stroke_content.dart` — draws the returned path
- `lib/src/animation/content/{ellipse,polystar,rectangle,shape}_content.dart` —
  cache the trimmed result in `_trimmedPath` and return that from `getPath()`

The patch was applied by hand onto 3.3.3 rather than taken as a git dependency,
because cloning `xvrh/lottie-flutter` was not reliable from this network. It is
otherwise identical to upstream.

## Removing this

The fix ships in lottie **3.5.2**. Once that is on pub.dev:

1. Delete `third_party/lottie/`.
2. Delete the `dependency_overrides:` block in the root `pubspec.yaml`.
3. Set `lottie: ^3.5.2` and run `flutter pub get`.
