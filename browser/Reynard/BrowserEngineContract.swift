//
//  BrowserEngineContract.swift
//  Reynard
//
//  Engine-neutral contracts for the Blink experiment. This file intentionally
//  does not provide a rendering implementation yet.
//

import Foundation
import UIKit

/// Capability flags used to avoid assuming feature parity between engine backends.
enum BrowserEngineCapability: Hashable {
    case javascriptEvaluation
    case backForwardNavigation
    case findInPage
    case downloads
    case fileUpload
    case mediaPlayback
    case contentBlocking
    case privateBrowsing
    case pageCapture
}

/// A minimal engine-neutral snapshot. The eventual Blink bridge will emit this
/// instead of leaking engine-specific types into the browser UI.
struct BrowserEnginePageState {
    var url: URL?
    var title: String?
    var isLoading: Bool
    var progress: Double
    var canGoBack: Bool
    var canGoForward: Bool
}

/// Common command surface for a browser engine adapter. This is a seam for
/// incremental migration, not a rendering engine or a replacement for Gecko yet.
protocol BrowserEngineSession: AnyObject {
    var pageState: BrowserEnginePageState { get }
    var capabilities: Set<BrowserEngineCapability> { get }
    var engineView: UIView { get }

    func load(_ url: URL)
    func reload()
    func stop()
    func goBack()
    func goForward()
    func evaluateJavaScript(_ script: String, completion: ((Result<Any?, Error>) -> Void)?)
}

/// Factory boundary for engine-specific session implementations.
protocol BrowserEngineFactory {
    var engineName: String { get }
    func makeSession() throws -> BrowserEngineSession
}

/// Explicit error type used while a real Blink runtime has not yet been linked.
enum BlinkEngineUnavailable: LocalizedError {
    case runtimeNotBuilt
    case embeddingLayerMissing

    var errorDescription: String? {
        switch self {
        case .runtimeNotBuilt:
            return "The Chromium/Blink runtime has not been built for this project."
        case .embeddingLayerMissing:
            return "The Blink runtime is present, but Reynard's iOS embedding adapter is not implemented."
        }
    }
}

/// Placeholder factory. It deliberately fails rather than silently substituting
/// WKWebView/WebKit or pretending Gecko is Blink.
final class BlinkEngineFactory: BrowserEngineFactory {
    let engineName = "Blink (experimental)"

    func makeSession() throws -> BrowserEngineSession {
        throw BlinkEngineUnavailable.runtimeNotBuilt
    }
}
