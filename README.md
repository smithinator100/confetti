# Confetti Prototype

A macOS prototype for comparing two confetti implementations side by side:

- a web implementation running in `WKWebView`
- a native implementation built with Core Animation layers

The repo also includes reusable single-file components for React and UIKit in `confetti/`.

## What Is Included

- `ConfettiPrototype/` - SwiftUI macOS comparison app.
- `ConfettiPrototype/Resources/confetti.html` - bundled web preview used by the left pane.
- `ConfettiPrototype/ConfettiBurstView.swift` - native macOS preview used by the right pane.
- `confetti/confetti.tsx` - reusable React component.
- `confetti/confetti.swift` - reusable UIKit component for iOS.
- `BUILD.md` - story plan and implementation notes.
- `TAXONOMY.md` - naming, file, and implementation conventions.

## Requirements

- macOS 14+
- Xcode
- XcodeGen

Install XcodeGen if needed:

```sh
brew install xcodegen
```

## Run The Prototype

Generate the Xcode project after changing `project.yml`:

```sh
xcodegen generate
```

Build the app:

```sh
xcodebuild build -scheme ConfettiPrototype -destination 'platform=macOS'
```

Run tests:

```sh
xcodebuild test -scheme ConfettiPrototype -destination 'platform=macOS'
```

The app opens a two-pane window. The left pane renders the web confetti in a `WKWebView`; the right pane renders native particles with Core Animation.

## How The Confetti Works

Both implementations use the same core model:

- each burst creates a fixed number of individual particles
- particles are sampled from shape families: Star, Blob, Rectangle, and Strip
- colors are sampled from Mandarin, Pondwater, Lilypad, Blossom, and Pollen shade families
- each particle computes keyframes for velocity, gravity, decay, wobble, scale, opacity, and 3D rotation
- particles render in front of the pictogram, while a temporary pictogram cover creates the illusion that the burst starts from behind it
- particle nodes/layers are removed after the animation completes

Keep `confetti.html`, `ConfettiPhysics.swift`, `ConfettiShapeArt.swift`, `confetti/confetti.tsx`, and `confetti/confetti.swift` in lockstep when changing the effect.

## Implement On Web Or React

Use `confetti/confetti.tsx` for React apps. It is a client component and depends on `react` and `motion`.

Install Motion:

```sh
npm install motion
```

Copy `confetti/confetti.tsx` into your app, then render it near the pictogram or button that should trigger the burst.

```tsx
"use client"

import { useRef } from "react"
import { Confetti } from "./confetti"

interface ConfettiHandle {
  fire: () => void
}

export function CelebrationButton() {
  const confettiRef = useRef<ConfettiHandle>(null)

  return (
    <div className="relative">
      <Confetti
        ref={confettiRef}
        pictogramPath="/subscription-check-hero.svg"
      />
      <button onClick={() => confettiRef.current?.fire()}>
        Confetti
      </button>
    </div>
  )
}
```

Notes:

- The component keeps its own box equal to the pictogram size and lets particles overflow.
- `fire()` is imperative so callers can trigger a burst from any UI event.
- Tune the effect with props such as `particleCount`, `startVelocity`, `spread`, `gravity`, `duration`, `enabledShapes`, and `enabledColorFamilies`.
- In Next.js App Router, keep this component behind a small `"use client"` boundary.

## Implement On iOS

Use `confetti/confetti.swift` for native iOS apps. Add the file to your app target and provide a raster pictogram asset path.

`UIImage` does not decode SVG, so use PNG or JPEG for the pictogram.

```swift
import UIKit

final class CelebrationViewController: UIViewController {
    private lazy var confettiView: ConfettiView = {
        let pictogramPath = Bundle.main.path(
            forResource: "subscription-check-hero",
            ofType: "png"
        ) ?? ""

        let view = ConfettiView(
            configuration: ConfettiConfiguration(pictogramPath: pictogramPath)
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.clipsToBounds = false
        view.addSubview(confettiView)

        NSLayoutConstraint.activate([
            confettiView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            confettiView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            confettiView.widthAnchor.constraint(equalToConstant: 108),
            confettiView.heightAnchor.constraint(equalToConstant: 108),
        ])
    }

    @objc private func didTapConfettiButton() {
        confettiView.fire()
    }
}
```

Notes:

- `ConfettiView` is a `UIView` with `clipsToBounds = false`, so parent views must not clip if particles should escape the pictogram bounds.
- Repeated calls to `fire()` are supported; particles clean themselves up after `duration + 0.5s`.
- Tune the effect by passing custom values to `ConfettiConfiguration`.
- For SwiftUI on iOS, wrap `ConfettiView` in `UIViewRepresentable` and expose a binding or action that calls `fire()`.

## Implement In The macOS Prototype

The prototype shows both platform strategies in one app.

Web pane:

1. `WebPane.swift` creates a transparent `WKWebView`.
2. It loads `ConfettiPrototype/Resources/confetti.html` from the app bundle.
3. The HTML builds particles as DOM nodes and animates them with Motion using `transform` and `opacity` keyframes.

Native pane:

1. `NativePane.swift` owns the tweak settings and increments `burstID` when the button is tapped.
2. `ConfettiBurstView.swift` reacts to `burstID` and creates per-particle `CALayer` trees.
3. Each particle receives matching `CAKeyframeAnimation` values for transform and opacity.
4. Layers are removed after the burst finishes.

This app is intentionally a proof of concept. Prefer changing the reusable components in `confetti/` for production integration work, then mirror any physics or art changes back into the macOS comparison app.
