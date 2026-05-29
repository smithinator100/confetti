import Foundation
import SwiftUI

enum ConfettiShape: String, CaseIterable, Hashable {
    case circle
    case rect
    case strip
    case star
    case triangle
}

enum ConfettiColorFamily: String, CaseIterable, Hashable {
    case mandarin
    case pondwater
    case lilypad
    case blossom
    case pollen

    var title: String {
        switch self {
        case .mandarin: return "Mandarin"
        case .pondwater: return "Pondwater"
        case .lilypad: return "Lilypad"
        case .blossom: return "Blossom"
        case .pollen: return "Pollen"
        }
    }
}

struct NativeConfettiSettingsSnapshot {
    let particleCount: Int
    let startVelocity: Double
    let spread: Double
    let decay: Double
    let gravity: Double
    let duration: Double
    let fadeOutVariance: Double
    let xSpin: Double
    let ySpin: Double
    let size: Double
    let sizeVariation: Double
    let enabledShapes: Set<ConfettiShape>
    let enabledColorFamilies: Set<ConfettiColorFamily>
}

final class NativeConfettiSettings: ObservableObject {
    @Published var particleCount: Double = 60
    @Published var startVelocity: Double = 25
    @Published var spread: Double = 100
    @Published var decay: Double = 0.91
    @Published var gravity: Double = 1
    @Published var duration: Double = 2.5
    @Published var fadeOutVariance: Double = 0.3
    @Published var xSpin: Double = 0
    @Published var ySpin: Double = 1
    @Published var size: Double = 1
    @Published var sizeVariation: Double = 1
    @Published var enabledShapes: Set<ConfettiShape> = Set(ConfettiShape.allCases)
    @Published var enabledColorFamilies: Set<ConfettiColorFamily> = Set(ConfettiColorFamily.allCases)

    static let weightedShapes: [ConfettiShape] = [
        .circle, .rect, .rect, .strip, .strip, .star, .triangle
    ]

    static let colorFamilies: [ConfettiColorFamily: [Color]] = [
        .mandarin: [Color(hex: 0xF05F2B), Color(hex: 0xCC3B0A), Color(hex: 0x9E2B08)],
        .pondwater: [Color(hex: 0x4397E0), Color(hex: 0x1074CC), Color(hex: 0x045EB2)],
        .lilypad: [Color(hex: 0x589D88), Color(hex: 0x247A64), Color(hex: 0x11604D)],
        .blossom: [Color(hex: 0x9F6EB8), Color(hex: 0x7D4794), Color(hex: 0x682A7A)],
        .pollen: [Color(hex: 0xFAB341), Color(hex: 0xF5A031), Color(hex: 0xB66A1F)],
    ]

    static let shapeTitles: [ConfettiShape: String] = [
        .circle: "Circle",
        .rect: "Rectangle",
        .strip: "Strip",
        .star: "Star",
        .triangle: "Triangle",
    ]

    var snapshot: NativeConfettiSettingsSnapshot {
        NativeConfettiSettingsSnapshot(
            particleCount: Int(particleCount.rounded()),
            startVelocity: startVelocity,
            spread: spread,
            decay: decay,
            gravity: gravity,
            duration: duration,
            fadeOutVariance: fadeOutVariance,
            xSpin: xSpin,
            ySpin: ySpin,
            size: size,
            sizeVariation: sizeVariation,
            enabledShapes: enabledShapes,
            enabledColorFamilies: enabledColorFamilies
        )
    }

    func toggleShape(_ shape: ConfettiShape, isEnabled: Bool) {
        if isEnabled {
            enabledShapes.insert(shape)
            return
        }
        enabledShapes.remove(shape)
    }

    func toggleColorFamily(_ family: ConfettiColorFamily, isEnabled: Bool) {
        if isEnabled {
            enabledColorFamilies.insert(family)
            return
        }
        enabledColorFamilies.remove(family)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}
