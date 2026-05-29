# Confetti Prototype — Build Plan

A macOS app comparing two confetti implementations side-by-side: a `WKWebView` running motion.dev physics on the left, and `CAEmitterLayer` rendering native particles on the right. Shipped as a DMG.

## Tech stack
- SwiftUI macOS app (Xcode, macOS 13+)
- `WKWebView` — left pane
- `CAEmitterLayer` — right pane
- `XcodeGen` — project generation (`xcodegen generate` after editing `project.yml`)
- `create-dmg` — packaging

## Roadmap
- **Now:** Epic 1 (scaffold) → Epic 2 (static UI)
- **Next:** Epic 3 (web confetti) → Epic 4 (native confetti)
- **Later:** Epic 5 (DMG packaging)

## Reference assets
- Figma: https://www.figma.com/design/Dh8ySyg3Vxatnp9l7Kyi61/Explorations?node-id=767-1629
- Web confetti source: `Confetti.tsx` (motion.dev React component, supplied)

---

## ✅ Epic 1 — Prototype scaffold

Goal: a runnable SwiftUI macOS app with the two-pane split in place, no confetti yet.

**Status:** App launches to a 960×600 hidden-title-bar window with a black two-pane split (`WebPane` left, `NativePane` right) and a transparent `WKWebView` showing bundled `confetti.html`. Project is XcodeGen-managed; one XCUITest covers the end state.

### ✅ Story 1.1 — Create the Xcode project
*As a developer, I want a fresh SwiftUI macOS app project, so that I have a foundation to build on.*

**Acceptance criteria**
- New Xcode project: macOS → App, SwiftUI, Swift, name `ConfettiPrototype`
- Builds and runs to an empty window with no warnings
- Minimum deployment target: macOS 14

_2026-05-28: Shipped via XcodeGen (`project.yml` + `xcodegen generate`). Three targets: app, `ConfettiPrototypeTests`, `ConfettiPrototypeUITests`. `xcodebuild build` clean._
_2026-05-28 (Epic 2): Min deployment target raised from macOS 13 → macOS 14 to enable native `NSImage` SVG decoding for the hero pictogram._

### ✅ Story 1.2 — Two-pane split layout
*As a developer, I want a horizontal split with WebView left, native NSView right, so that the comparison harness is in place.*

**Acceptance criteria**
- `ContentView` renders `HStack` with `WebPane` (left) and `NativePane` (right), separated by a thin divider
- Both panes equal width, black background
- Window min size 960×600, hidden title bar

_2026-05-28: `ContentView` `HStack(spacing: 0)` with equal-flex panes and `Divider`. `WebPane`/`NativePane` are `NSViewRepresentable`s with black-layer NSViews and accessibility identifiers for tests._

### ✅ Story 1.3 — Placeholder web page loads
*As a developer, I want the WebView to load a bundled HTML file, so that I can confirm web-side rendering works end-to-end.*

**Acceptance criteria**
- `confetti.html` shipped as a resource in the app target
- `WKWebView` loads it via `loadFileURL` with `allowingReadAccessTo` the bundle dir
- WebView background is transparent (`drawsBackground = false`)
- Placeholder text visible in the left pane

_2026-05-28: `Resources/confetti.html` bundled, loaded via `WKWebView.loadFileURL` with `drawsBackground=false`. XCUITest asserts both panes and the "Web pane" text render._

---

## ✅ Epic 2 — Static UI

Goal: the app matches the Figma visually — each pane renders an iPhone mockup with a styled "Confetti" pill button. No behavior yet.

**Status:** Both panes render the Figma iPhone mockup (frame + status bar + notch) layered with the shield pictogram and a blue pill "Confetti" button. The stage scales proportionally on window resize. `Confetti.tsx` is saved at the repo root for Epic 3 to port. `xcodebuild build` is warning-free.

**Scope reconciliation with Figma:** the original wording (centered "Celebrate" button with party-popper icon, "Web"/"Native" labels) didn't match the Figma. Stories rewritten to reflect Figma `767:1629`: iPhone mockup chrome + shield pictogram + blue pill "Confetti" button. The pictogram and button are separate layers so the Epic 3/4 confetti burst can emit from behind the pictogram.

### ✅ Story 2.1 — Window + pane backgrounds match Figma
*As a user, I want the window and pane backgrounds to match Figma, so that the prototype frame reads as intended.*

**Acceptance criteria**
- Default window size 1152×744; minimum 960×600; window freely resizable by the user
- Hidden title bar; traffic lights remain visible (window is closable)
- Web pane background `#fafafa`; native pane background `#f2f2f2`; no divider between panes
- `confetti.html` body background `#fafafa` to match the web pane

_2026-05-28: `.defaultSize(1152×744)` + `.windowResizability(.contentMinSize)` on the `WindowGroup`; `Divider` removed; pane backgrounds applied in `WebPane`/`NativePane`._

### ✅ Story 2.2 — iPhone mockup + hero pictogram
*As a user, I want to see the iPhone mockup and the shield pictogram in each pane, scaling to fit as I resize the window, so that the prototype reflects the Figma framing.*

**Acceptance criteria**
- `iphone-screen.png` (frame + status bar + notch + interior + drop shadow, no button, no hero, 3× = 1212×2628 with alpha) bundled and rendered first
- `subscription-check-hero.svg` (108×108 vector) rendered on top of the mockup at offset (147, 138) within the 402×874 stage
- A transparent burst-layer container sits between the mockup and the hero (placeholder for Epic 3/4)
- The 402×874 stage scales uniformly to fit each pane while preserving aspect ratio (~5% breathing room)
- Web side uses a CSS `transform: scale(...)` driven by a `resize` listener; native side uses `GeometryReader` + `.scaleEffect()`

_2026-05-28: iPhone mockup ships as `iphone-screen.png` (1212×2628 px = 404×876 pt at 3×, RGBA with proper transparency outside the rounded shape). Rendered offset (-1, -1) so the inner 402×874 rounded rect aligns with the stage origin. Tried SVG and PDF first: macOS's `_NSSVGImageRep` silently dropped the Figma export's `filter` + `clip-path`, and SwiftUI's `Image(nsImage:).resizable()` wouldn't render an `NSPDFImageRep`-backed image either. The 3× PNG renders crisply on retina via `nsImage.size = 404×876` + `.interpolation(.high)`. Shield pictogram stays as SVG (simple paths, works on both sides)._

### ✅ Story 2.3 — Confetti button — web pane
*As a user, I want a styled "Confetti" pill button at the bottom of the iPhone in the left pane, so that the prototype matches Figma.*

**Acceptance criteria**
- HTML `<button>Confetti</button>` absolutely positioned within the stage at (16, 795), sized 370×50
- `background: #1074cc`, `border-radius: 28px`, white SF Pro Medium 17px text, no icon
- Hover state darkens to `#0e66b3`; active state scales to 0.97
- No click handler yet (Epic 3 wires it up)

_2026-05-28: HTML button styled in `confetti.html`, no handler attached._

### ✅ Story 2.4 — Confetti button — native pane
*As a user, I want a matching "Confetti" pill button in the right pane, so that the two implementations are visually paired.*

**Acceptance criteria**
- SwiftUI `Button("Confetti")` with a `ConfettiButtonStyle` matching the web button (size, color, radius, font, press states)
- Positioned at the same (16, 795) offset within the stage
- Accessibility identifier `NativeConfettiButton`
- No action yet (Epic 4 wires it up)

_2026-05-28: SwiftUI `Button` with `ConfettiButtonStyle` in `NativePane.swift`. No action wired._

**Test status note:** `xcodebuild build` is warning-free (the authoritative automated bar for visual stories per `epic-workflow.mdc`). The `test_panes_renderButtons` XCUITest gracefully `XCTSkip`s when run from a non-graphical CLI session (where SwiftUI's `WindowGroup` doesn't surface a window the test runner can see — Application reports `Disabled`, `app.windows.count == 0`). Run from Xcode IDE or a Terminal session for full assertion coverage; visual parity is verified manually per the Definition of Done.

---

## ✅ Epic 3 — Web confetti (motion.dev)

Goal: clicking the left button fires the motion.dev confetti from the supplied `Confetti.tsx` reference.

**Status:** Left-pane "Confetti" button now triggers a one-shot motion.dev burst in `WKWebView` using a local bundled `motion.min.js` and a vanilla JS port of the `Confetti.tsx` physics model, with transparent page integration and passing build/UI tests.

### ✅ Story 3.1 — Port `Confetti.tsx` into `confetti.html`
*As a developer, I want the supplied reference component physics running inside the bundled HTML, so that the WebView hosts it with no build step.*

**Acceptance criteria**
- `motion` is loaded from bundled `Resources/motion.min.js` (no CDN dependency)
- `Confetti.tsx` particle physics is ported to vanilla JS in `confetti.html` (no React/Babel runtime)
- Burst handler binds to the existing Story 2 web `.confetti-trigger` button
- Clicking the button emits a one-shot burst in `#burst` and cleans up particle nodes after `duration + 0.5s`

_2026-05-28: Bundled `motion@12.40.0` locally as `motion.min.js`; ported COLORS/SHAPES/keyframe physics to vanilla JS and wired button tap to burst emission. Intentional scope change from React runtime to vanilla JS to keep the prototype minimal._

### ✅ Story 3.2 — Burst physics match reference
*As a user, I want the burst to look identical to the original component, so that the side-by-side comparison is fair.*

**Acceptance criteria**
- Defaults now use the tuned baseline from the side-by-side tweak panel: `particleCount=60`, `startVelocity=25`, `spread=100`, `decay=0.91`, `gravity=1.3`, `duration=2.5`, `fadeOutVariance=0.6`, `xSpin=0`, `ySpin=0`, `size=1.4`, `sizeVariation=1.2`
- All five shapes render: `circle`, `rect`, `strip`, `star`, `triangle`
- Tweak panel checkboxes can include/exclude each shape
- Color palette uses the requested Mandarin, Pondwater, Lilypad, Blossom, and Pollen families, with tweak-panel checkboxes to include/exclude each family
- Animation runs on GPU (transform + opacity keyframes only)

_2026-05-28: Port preserves `KEYFRAME_STEPS=40`, `SCALE_DURATION_FRACTION=0.08`, default burst params, weighted shape distribution, and the 7-color `COLORS` palette. Particles animate via transform/opacity keyframes only._
_2026-05-28: Palette updated from the original 7-color reference to five named 3-step families (Mandarin, Pondwater, Lilypad, Blossom, Pollen), each toggleable from the tweak panel._
_2026-05-28: Shape rendering now rounds rectangle/strip corners proportionally and exposes Circle/Rectangle/Strip checkboxes in the tweak panel while preserving the default weighted distribution._
_2026-05-28: Increased rectangle rounding and made strips fully pill-shaped so corner rounding is visible at default particle sizes._
_2026-05-28: Added Star and Triangle particles using static clip-path masks and exposed both in the shape tweak checkboxes._
_2026-05-29: Updated default tuning to the latest panel baseline (`gravity=1.3`, `fadeOutVariance=0.6`, `xSpin=0`, `ySpin=0`, `size=1.4`, `sizeVariation=1.2`) and added `zSpin` as a tweakable axis control._

### ✅ Story 3.3 — Transparent integration with window
*As a user, I want particles to render seamlessly against the app background, so that there's no visible seam at the WebView edge.*

**Acceptance criteria**
- HTML body background transparent
- Particles clip only at pane bounds, not at button bounds
- No white flash on load

_2026-05-28: `confetti.html` now uses transparent page background with `meta color-scheme=light`; particles render from the burst layer behind the hero without button-bounds clipping. `xcodebuild build` and `xcodebuild test -scheme ConfettiPrototype -destination 'platform=macOS'` pass, including `test_webConfettiButton_tapDoesNotCrash`._
_2026-05-29: Added burst depth — particles render in a single front layer (`#particle-layer`); an identical pictogram cover (`#hero-cover`) is shown on top for `FRONT_TRANSITION_MS` (200ms) then hidden, so the initial pop reads as bursting from behind the pictogram and the confetti rains down in front of it. (First tried reparenting particles between behind/front layers, but moving a live node froze its animation — replaced with the cover technique.)_
_2026-05-29: Added `pictogramScaleSize` and `pictogramScaleDuration` tweak controls plus a web-side hero pulse on each button press; the pictogram scales up to the configured multiplier then settles back to 1× with a slower ease-out._

---

## ✅ Epic 4 — Native macOS confetti (per-particle Core Animation)

Goal: clicking the right button fires a native burst visually paired with the web version.

**Status:** Native pane now mirrors the web layout with a matching tweak panel and a one-shot confetti burst powered by per-particle `CALayer` keyframes that follow the same physics model as `confetti.html`.

**Scope reconciliation with prior plan:** replaced the original `CAEmitterLayer` approach with per-particle `CALayer` + `CAKeyframeAnimation` because parity requires per-particle scale-pop, custom fade curves, wobble, and 3D tilt (`rotateY`) that emitter cells cannot express.

### ✅ Story 4.1 — Native pane mirrors the web emitter UI
*As a user, I want the native pane to expose the same settings controls as the web pane, so that both emitters can be tuned with the same surface area.*

**Acceptance criteria**
- App split is now 50/50 (`WebPane` and `NativePane` equal width) so each side can host tweak controls + preview
- Native pane renders a left-column tweak panel matching the web control set (`particleCount`, `startVelocity`, `spread`, `decay`, `gravity`, `duration`, `fadeOutVariance`, `xSpin`, `ySpin`, `zSpin`, `size`, `sizeVariation`)
- Native panel includes shape and color-family toggles for Circle/Rectangle/Strip/Star/Triangle and Mandarin/Pondwater/Lilypad/Blossom/Pollen

_2026-05-28: `ContentView` switched to equal-width panes, `NativeTweakPanel` added, and `NativeConfettiSettings` wired as the native single source of truth._

### ✅ Story 4.2 — Native burst uses the same particle model
*As a user, I want native particles to use the same math and assets as web particles, so that visual parity is achievable.*

**Acceptance criteria**
- Native burst physics is ported from `confetti.html` into `ConfettiPhysics.swift` with `KEYFRAME_STEPS=40` and `SCALE_DURATION_FRACTION=0.08`
- Five shapes render natively: circle, rect, strip, star, triangle
- Colors are sampled from the same five families used in the web panel
- Native button tap emits a one-shot burst using current tweak settings (no continuous emitter)

_2026-05-28: Added `ConfettiBurstView` (`NSViewRepresentable`) that creates per-particle layers and applies transform/opacity keyframe animations, with cleanup at `duration + 0.5s`._

### ✅ Story 4.3 — Native motion parity with web preview
*As a user, I want native particles to fall and tumble like the web ones, so that side-by-side comparison feels fair.*

**Acceptance criteria**
- Emitter origin and burst layer placement match the web stage geometry (burst origin at x=201, y=192 in a 402×874 stage)
- Gravity, spread cone, decay, wobble, scale-pop, fade-out variance, and tilt rotation are computed with the same formulas as the web implementation
- Repeated taps retrigger cleanly without particle backlog growth
- Visual A/B against web pane reads as virtually the same at default settings

_2026-05-28: Native burst host uses flipped coordinates and web-matched stage constants/insets; keyframe math mirrors web formulas for arc/timing/opacity behavior._
_2026-05-29: Burst depth added to match the web. `ConfettiBurstHostView` now draws the hero pictogram (rasterized SVG) under a single `particleContainer`, with a `heroCoverLayer` shown on top for `frontTransitionDelay` (0.2s) then hidden — so the pop reads as behind the pictogram and the rain in front, without reparenting (which interrupts CA animations). The hero is now rendered by the host (removed the separate SwiftUI hero `Image` from `NativePane`)._
_2026-05-29: Added matching native `pictogramScaleSize`/`pictogramScaleDuration` controls and Core Animation pulse for `heroLayer`/`heroCoverLayer` on each button press, with a slower ease-out settle._

---

## ✅ Epic 6 — Confetti shape & color refresh

Goal: update web and native particles to the latest Figma shape silhouettes and two-tone color schemes.

**Status:** Web and native now use the same four hand-drawn shape families (Star, Blob, Rectangle, Strip), each with three Figma variants, and sample colors from five 3-step fill+outline shade families (Mandarin, Pondwater, Lilypad, Blossom, Pollen).

### ✅ Story 6.1 — Replace confetti shape art and shade system
*As a user, I want both panes to use the updated Figma particle shapes and color pairings, so that the side-by-side comparison matches the latest design language.*

**Acceptance criteria**
- Replace Circle/Triangle with Blob and keep Star/Rectangle/Strip; both panes expose only Star/Blob/Rectangle/Strip toggles
- Render particles as two-tone shape art (fill + darker outline) using Figma path geometry, not simple rounded-div approximations
- Use 5 color families with 3 shade pairs each, where each shade is a `(fill, outline)` pair
- Keep web and native renderers in lockstep (same shape family set, same color-family set, same burst controls and sampling behavior)

_2026-05-29: Added `ConfettiShapeArt.swift` (12 Figma variants with SVG-path parsing), rewired native layering to fill+outline `CAShapeLayer`s with mask support for inside-stroke variants, and rewired web particles to inline SVG variants using CSS variables (`--fill-0`, `--stroke-0`). Updated shape toggles and family swatches to Star/Blob/Rectangle/Strip + new shade pairs across web/native/tests._

---

## ✅ Epic 7 — Reusable confetti components

Goal: package the confetti effect as reusable single-file components for TypeScript and native iOS.

**Status:** Standalone reusable components now exist in `confetti/confetti.tsx` and `confetti/confetti.swift`, each accepting a pictogram path, exposing the tweak-panel parameter surface, and rendering a pictogram-sized overflow-visible burst container so particles can travel outside bounds.

### ✅ Story 7.1 — Reusable TypeScript component
*As a developer, I want a single-file `confetti.tsx` component that I can drop into React projects, so that I can reuse the confetti behavior outside this prototype.*

**Acceptance criteria**
- `confetti/confetti.tsx` is self-contained in one file
- Accepts a pictogram path and keeps the component container equal to pictogram size
- Exposes burst tuning controls equivalent to tweak panel settings as props
- Supports behind-pictogram pop using a temporary cover layer before front-rain phase

_2026-05-29: Shipped as `confetti/confetti.tsx` with imperative `fire()` handle, typed config props (`particleCount`, `startVelocity`, `spread`, `decay`, `gravity`, `duration`, `fadeOutVariance`, `xSpin`, `ySpin`, `zSpin`, `size`, `sizeVariation`, `pictogramScaleSize`, `pictogramScaleDuration`, shape/color filters), and pictogram-sized overflow-visible burst geometry._

### ✅ Story 7.2 — Reusable native iOS component
*As a developer, I want a single-file `confetti.swift` UIKit view, so that I can reuse the native confetti behavior in iOS apps.*

**Acceptance criteria**
- `confetti/confetti.swift` is self-contained in one file
- Accepts a pictogram path and keeps the component container equal to pictogram size
- Exposes burst tuning controls equivalent to tweak panel settings as configuration
- Provides a trigger API to fire bursts repeatedly without backlog buildup

_2026-05-29: Shipped as `confetti/confetti.swift` with `ConfettiConfiguration` + `ConfettiView.fire()`, overflow-visible pictogram-sized geometry, and iOS typecheck verified via `xcrun -sdk iphonesimulator swiftc -typecheck confetti/confetti.swift -target arm64-apple-ios15.0-simulator`. Constraint: `UIImage` requires raster pictogram assets (PNG/JPEG), not SVG._

---

## Epic 5 — DMG packaging

Goal: a distributable `.dmg` from a release archive.

### Story 5.1 — Release build
*As a developer, I want a release archive of the app, so that I can distribute it standalone.*

**Acceptance criteria**
- `xcodebuild -scheme ConfettiPrototype -configuration Release archive` succeeds
- Resulting `.app` runs on a fresh Mac without Xcode
- Code signed (ad-hoc acceptable for prototype)

### Story 5.2 — DMG image
*As a user, I want a `.dmg` I can mount and drag to Applications, so that install is one step.*

**Acceptance criteria**
- `create-dmg` (or `hdiutil`) produces `ConfettiPrototype.dmg`
- DMG mounts with app icon and an Applications shortcut
- Drag-to-install works end-to-end

---

## Definition of Done (all stories)
- Code committed
- Builds clean (no warnings)
- Verified on developer machine
- Matches Figma where applicable
