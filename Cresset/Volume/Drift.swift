import Foundation

/// Role: Volume. Genre current a volume rides onto its isle. One drift, one isle.
enum Drift: String, Codable, CaseIterable, Sendable, Identifiable {
    case fable
    case lyric
    case chronicle
    case tract
    case scene
    case inquiry
    case voyage
    case hearth

    var id: String { rawValue }
}
