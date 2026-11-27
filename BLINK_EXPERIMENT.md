# Blink experiment — implementation progress

## Engine backend boundary added

The app target's synchronized `Reynard` source directory now contains `BrowserEngineContract.swift`. It defines an engine-neutral session/page-state/capability contract and a Blink factory that reports an explicit unavailable error.

This is deliberately not a fake webview: it does not substitute WebKit or Gecko, and it cannot render pages yet. The existing Gecko-specific UI and session plumbing still needs to be migrated to this contract before a Blink adapter can be plugged in.

## Real Blink source direction

The practical starting point for a BrowserEngineKit-free Blink runtime on iOS is the experimental **Blinker Fluid** Chromium overlay, which pins Chromium and builds `content_shell` for iOS without WebKit. Its source overlay is GPL-3.0; review licensing and compatibility before copying or integrating source into this branch.

- Project: https://github.com/Nodesclock/Blinker-fluid
- README build flow: sync a pinned Chromium revision with `depot_tools`, apply the overlay, run hooks, GN and Ninja.
- This approach is experimental, primarily intended for TrollStore/jailbreak/sideload scenarios, and uses `content_shell`; it is not a ready-made drop-in framework for Reynard.
- The project requires a large Chromium checkout (roughly 120 GB of disk space) and a Mac/Xcode/depot_tools toolchain.

## Next steps

1. Decouple `ContentView` and `WebContentView` from Gecko concrete types through adapter interfaces.
2. Build a Chromium overlay reproducibly and verify the produced content_shell binary.
3. Investigate wrapping content_shell in a reusable UIKit view/session API, including lifecycle, input, navigation, and process management.
4. Add an isolated proof-of-concept tab that can render and navigate, without modifying the default Gecko branch.
5. Port feature integration gradually and keep unsupported capabilities explicitly disabled.

## Platform and security caveat

A non-BrowserEngineKit Blink build does not inherit Apple's alternative-engine sandbox, extension, entitlement, or distribution infrastructure. This experiment must independently validate process isolation, runtime memory/JIT behavior, code signing, and the applicable distribution constraints. No claim is made that a generic, safe, distributable Blink browser is achievable by simply embedding the Chromium executable.
