# Reynard Blink experiment (without BrowserEngineKit)

This branch explores replacing Reynard's GeckoView-backed browsing layer with a bundled Chromium/Blink engine while keeping the app's browser UI and core browser features.

## Goal

- Experiment with Blink/Chromium rather than Gecko.
- Do **not** use Apple's BrowserEngineKit APIs or BrowserEngineKit extension targets.
- Keep Reynard's existing app-level browser UX, tab model, navigation, bookmarks, privacy controls, and settings where practical.
- Keep the engine isolated from the UI and behind an adapter so the main browser UI can remain engine-agnostic.

## Status: exploration scaffold, not a functional Blink port

This branch currently documents the proposed architecture. It does not yet contain or embed a Blink build, and it does not replace Gecko in the app. A real Blink integration requires a compatible Chromium/Blink iOS build, an iOS-specific embedding layer, process/sandbox integration, and substantial API parity work. It cannot be achieved by changing the GeckoView import or swapping a framework name.

## Proposed design

1. Define an engine adapter boundary (tab/web-view operations, navigation, script execution, history, downloads, permissions, media, and storage).
2. Build or obtain a Blink/Chromium engine for arm64 iOS with a supported embedding API. This must be a real engine build, not WKWebView, UIWebView, or Chromium's iOS WebKit wrapper.
3. Implement an adapter backed by Blink and keep engine-specific code out of browser UI and feature controllers.
4. Replace Gecko-specific extensions and services only where necessary; document features that cannot be ported.
5. Validate process isolation, code-signing, sandboxing, memory/JIT restrictions, update/security servicing, and distribution entitlement requirements.

## Important iOS platform constraints

Apple's alternative-engine APIs and entitlement model are designed around BrowserEngineKit. This experiment deliberately avoids BrowserEngineKit, so it must not assume that merely embedding Blink grants the platform capabilities or distribution permissions associated with Apple's supported alternative-engine framework. A BrowserEngineKit-free Blink engine still needs a technically viable and policy-compliant process, sandbox, signing, and runtime design. This is an engineering investigation, not a claim that such a design is currently ready for general iOS distribution.

## Next engineering milestones

- Inventory and decouple GeckoView-specific APIs behind an engine interface.
- Prototype the adapter with a mock implementation to keep the app compiling while engine work proceeds.
- Investigate a viable Blink build and embedding API for iOS without BrowserEngineKit.
- Prototype one isolated tab displaying and navigating web content before attempting full browser features.
- Only then port tabs, storage, cookies, content blocking, downloads, media, and browser privacy behavior.

