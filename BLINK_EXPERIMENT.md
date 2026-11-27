# Blink experiment — build and integration status

## Build bootstrap

The branch now includes `scripts/build-blink-prototype.sh`, which prepares an isolated Chromium iOS `content_shell` build using a pinned Blinker Fluid overlay and Chromium revision.

### Requirements

- macOS, Xcode toolchain and iOS SDK
- Chromium `depot_tools` (`gclient`, `gn`, `autoninja`) on PATH
- curl, tar, rsync
- roughly 110–120 GB free disk space
- first build may take several hours

Run:

```bash
BLINK_BUILD_ROOT="$HOME/reynard-blink-build" BLINK_JOBS=2 ./scripts/build-blink-prototype.sh
```

Optional variables: `BLINK_OUT`, `BLINK_BUNDLE_ID`, `BLINK_BUILD_ROOT`, `BLINK_JOBS`.

The script pins Chromium revision `4d790f9eb4c8abe65b8aaa3feba664e7c734ba56` and overlay commit `1924b4d67c994c26b4d52505f24f0ee4e9a50e89`. It overlays upstream files without deleting the Chromium checkout, runs hooks, generates GN and builds `content_shell`.

## What this achieves and what it does not

This provides a reproducible build path for an isolated standalone shell. It is **not yet an embedded Reynard tab**. Upstream iOS `content_shell` is an app shell with its own UIKit application/window lifecycle, not a documented reusable framework or stable public embedding API. Embedding its content into Reynard requires substantial native Chromium changes: lifecycle and scene ownership, navigation API, delegate plumbing, input/keyboard, process model, accessibility, downloads, permissions, persistent profile/data management, and Chromium's multiprocess launch strategy. `BrowserEngineContract.swift` is a future adapter interface and is not connected to a rendering implementation.

## License and distribution

Blinker Fluid's overlay is GPL-3.0. Assess GPL obligations and licensing compatibility before integrating or distributing overlay-derived code or binaries. This script downloads the overlay into a local build workspace rather than vendoring it into Reynard. Chromium also has third-party licensing and notices requirements.

## Roadmap

1. Build the isolated shell on macOS and validate it on a device.
2. Map shell lifecycle and rendering/view ownership.
3. Prototype a bridge in a separate Chromium fork/overlay exposing a UIKit view/session API.
4. Test navigation, JavaScript, renderer lifecycle, touch/keyboard, and multiprocess behavior.
5. Adapt Reynard's Gecko-bound UI/session plumbing only once a usable bridge exists.
6. Evaluate sandbox/process isolation, signing, JIT constraints, entitlements and distribution rules.

## Constraints

Blink-on-iOS via this experimental route is not a supported Apple alternative-engine entitlement path and has substantial security and distribution limitations. This is not a release-ready engine at this stage.
