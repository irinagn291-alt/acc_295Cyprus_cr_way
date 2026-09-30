# Rampin

Tap a waiting canvas, then the nameplate that names it. Rampin is for people who already saved Philadelphia Museum of Art paintings and want to seat each face under its maker or title on a hook rail, on this device.

## Why the fold

Rampin is a closed algebraic fold (`Bare | Spread | Settled`). The rail is a fold over Works, not a list of records. Spread plants three Waiting canvases and three Rampins that share one Cartel field, artist or title. Lift raises one canvas. Hook writes a HookMark when that canvas matches the nameplate and seats it as Hooked. A miss writes a DropMark and the canvas waits again. The third HookMark Settles the trio. Fewer than three Waiting works write Bare.

The fold fits this product because the job is an assignment on one rail: three visible canvases must sit under three visible cartels. A second rail enum in the views would split that truth.

## Spread, then hook

Home is hook-the-rampin. Quiz never leaves. Explore, Saved, and Settings arrive as sheets. A dedicated Spread-then-hook page explains the same mechanic that already lives on the rail.

## Build

```bash
cd Rampin
xcodegen generate
xcodebuild -scheme Rampin -destination 'generic/platform=iOS Simulator' build-for-testing
```

No packages. SF Pro is the system face. Persistence is UserDefaults plus Codable. Launch arguments `-ReviewScreen today|log|goals|explore` open Quiz, Saved, Settings, or Explore after onboarding.
