# Taxonomy

Naming conventions for the Confetti Prototype. Update this file whenever a new convention is introduced.

## App

- **App name:** `ConfettiPrototype` (PascalCase, no spaces)
- **Minimum deployment target:** macOS 14 (required for native `NSImage` SVG decoding)

## Swift code

- **Types** (`struct`, `class`, `enum`, `protocol`): `PascalCase` — e.g. `ContentView`, `WebPane`, `NativePane`
- **Properties, methods, locals:** `camelCase`
- **File names:** match the primary type — `WebPane.swift`, `NativePane.swift`
- **SwiftUI view suffixes:** top-level screens end with `View` (e.g. `ContentView`); split-view children end with `Pane` (e.g. `WebPane`, `NativePane`)
- **Settings models:** shared tweak state lives in an `ObservableObject` named `<Domain>Settings` — e.g. `NativeConfettiSettings`
- **Physics module naming:** deterministic particle math lives in a standalone `PascalCase` namespace file (`<Domain>Physics.swift`) with pure/static functions — e.g. `ConfettiPhysics.computeKeyframes(...)`

## Resources

- **Bundled web assets:** lowercase, dot-separated — `confetti.html`
- **Vendored web libraries:** lowercase, dot-separated in `Resources/` with a pinned upstream version noted in docs/commit context — e.g. `motion.min.js` (`motion@12.40.0`)
- **Images:** `kebab-case` — e.g. `celebrate-button.png`
- **Placeholder images** for interactive UI not yet wired up: suffix `-placeholder` — e.g. `celebrate-button-placeholder.png`
- **Resource images** live in `ConfettiPrototype/Resources/` directly. Loaded via `<img>` on web and `NSImage(contentsOf:)` on native.
  - **Simple SVG** (paths + basic shapes only) works on both sides — e.g. `subscription-check-hero.svg`.
  - **PNG @ 3×** for Figma exports that include `filter` (drop shadows) or referenced `clip-path` — macOS's built-in `_NSSVGImageRep` silently drops them, and SwiftUI's `Image(nsImage:).resizable()` doesn't reliably render `NSPDFImageRep` either. Bundle a 3× PNG with alpha and set `nsImage.size` to the logical size at load time so retina downscaling stays crisp. Example: `iphone-screen.png` (1212×2628 px → 404×876 pt).

## Reference assets

- **`Confetti.tsx`** at repo root — source-of-truth React component for Epic 3 web confetti physics. Treat as read-only reference; port into `confetti.html` rather than importing.
- **Reusable component deliverables:** ship standalone single-file components in `confetti/` as lowercase `confetti.tsx` (React) and `confetti.swift` (UIKit). Folder is required because case-insensitive filesystems cannot hold both `Confetti.tsx` and root `confetti.tsx`.
- **Static web deploy:** `web/index.html` is the standalone Vercel-ready web page. Keep it dependency-free and self-contained when possible.
- **Reusable pictogram path rule (iOS):** `confetti/confetti.swift` loads pictograms with `UIImage`, so caller-provided paths must point to raster assets (PNG/JPEG), not SVG.
- **Particle tweak controls:** numeric sliders and filters exposed in `confetti.html` tweak panel — e.g. `fadeOutVariance`, `xSpin`, `ySpin`, `zSpin`, `pictogramScaleSize`, `pictogramScaleDuration`, Mandarin/Pondwater/Lilypad/Blossom/Pollen, and Star/Blob/Rectangle/Strip.
- **Shape art source:** hand-drawn particle silhouettes live as shared Figma path data in `ConfettiShapeArt.swift` (native) and mirrored `SHAPE_VARIANTS` path data in `confetti.html` (web). Each variant is two-tone (`fillPath` + `strokePath`) and may clip stroke to fill for inside-stroke art.
- **Physics lockstep rule:** keep confetti constants and formulas aligned between web `confetti.html` and native `ConfettiPhysics.swift` (at minimum `KEYFRAME_STEPS`, `SCALE_DURATION_FRACTION`, fade-out segmentation, and trajectory update equations).
- **Burst depth layering:** particles always render in a single layer *in front* of the hero pictogram. To make the initial pop read as bursting from *behind* it, an identical pictogram "cover" is shown on top for a short delay, then hidden so the rain falls in front. (Reparenting live particles between layers interrupts their animation — don't.) Web: persistent `.hero` + front `#particle-layer` + toggled `#hero-cover`, timed by `FRONT_TRANSITION_MS`. Native: host draws `heroLayer` (persistent) under `particleContainer` with `heroCoverLayer` on top, timed by `frontTransitionDelay`. Keep the delay aligned across web/native (currently ~200ms).

## Documentation

- **Build plan:** `BUILD.md` at repo root
- **Epics:** heading `Epic N — Title`
- **Stories:** heading `Story N.M — Title`, body written as a user story (`As a …, I want …, so that …`)
- **Completion marker:** prepend `✅` to a story or epic heading once done; append a one-line note with date and what shipped

## Tests

- **Unit test target:** `ConfettiPrototypeTests`
- **UI test target:** `ConfettiPrototypeUITests`
- **Test method names:** `test_<subjectUnderTest>_<expectedBehavior>` — e.g. `test_contentView_rendersTwoPanes`

## Build tooling

- **Project generator:** `XcodeGen` — edit `project.yml` at repo root, then run `xcodegen generate` to regenerate `ConfettiPrototype.xcodeproj`
- **Install:** `brew install xcodegen`

## Performance tooling

- **In-page FPS probe:** `confetti.html` renders a corner `#fps-meter` overlay and runs a `requestAnimationFrame` sampler (`runFpsProbe`) per burst, reporting avg/min FPS and dropped frames (frames >33ms). It also logs a `[confetti fps]` console line.
- **Chunked spawn:** particles are built + started in chunks of 20, one chunk per frame, so no single frame absorbs the whole spawn cost (keeps burst-start min-FPS up at high particle counts). Kept in lockstep across web and native: web `handleBurst` uses `SPAWN_CHUNK` + `requestAnimationFrame` (tracked by `spawnHandle`); native `ConfettiBurstHostView` uses `spawnChunkSize` + per-frame `DispatchQueue.main.asyncAfter` (tracked by `spawnWorkItem`). A re-fire cancels the in-flight spawn on both sides.
- **Bitmap prewarm:** the full shape×variant×color matrix is rasterized once at load so the rasterize cost never lands on a burst frame. Web: `prewarmParticleBitmaps()` (`canvas.toDataURL`). Native: `prewarmParticleBitmaps()` in `ConfettiBurstHostView.init` (`CGContext` path fill).
- **Benchmark hook:** `window.__confettiBench(count, durationMs)` (in `confetti.html`) fires a burst at a given particle count and resolves with the probe metrics — the automation entry point. Don't call it from app UI; it mutates `settings`.
- **Benchmark harness:** `tools/confetti-bench.swift` — standalone script run via `swift tools/confetti-bench.swift [count ...]` (override window with env `CONFETTI_BENCH_MS`). Drives `confetti.html` in a real on-screen `WKWebView` and prints a markdown FPS table. Must run from a logged-in GUI session — offscreen WebKit views throttle rAF and report false numbers.

## Packaging

- **DMG output:** `ConfettiPrototype.dmg`
