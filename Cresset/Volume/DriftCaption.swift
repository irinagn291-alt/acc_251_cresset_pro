import Foundation

/// Role: Volume. Genre names for mooring. Raw drift keys stay off the chrome.
extension Drift {
    var mooringName: String {
        switch self {
        case .fable: "Fable"
        case .lyric: "Lyric"
        case .chronicle: "Chronicle"
        case .tract: "Tract"
        case .scene: "Scene"
        case .inquiry: "Inquiry"
        case .voyage: "Voyage"
        case .hearth: "Hearth"
        }
    }
}
