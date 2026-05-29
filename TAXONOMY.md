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
- **Particle tweak controls:** numeric sliders and filters exposed in `confetti.html` tweak panel — e.g. `fadeOutVariance`, `xSpin`, `ySpin`, Mandarin/Pondwater/Lilypad/Blossom/Pollen, and Circle/Rectangle/Strip/Star/Triangle.
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

## Packaging

- **DMG output:** `ConfettiPrototype.dmg`
