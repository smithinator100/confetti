import Foundation
import SwiftUI

enum ConfettiShape: String, CaseIterable, Hashable {
    case star
    case blob
    case rect
    case strip
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
    let zSpin: Double
    let size: Double
    let sizeVariation: Double
    let pictogramScaleSize: Double
    let pictogramScaleDuration: Double
    let enabledShapes: Set<ConfettiShape>
    let enabledColorFamilies: Set<ConfettiColorFamily>
}

struct ConfettiShade: Hashable {
    let fill: Color
    let stroke: Color
}

final class NativeConfettiSettings: ObservableObject {
    @Published var particleCount: Double = 60
    @Published var startVelocity: Double = 33
    @Published var spread: Double = 96
    @Published var decay: Double = 0.92
    @Published var gravity: Double = 1.4
    @Published var duration: Double = 5
    @Published var fadeOutVariance: Double = 0.6
    @Published var xSpin: Double = 0
    @Published var ySpin: Double = 0
    @Published var zSpin: Double = 0.2
    @Published var size: Double = 3
    @Published var sizeVariation: Double = 1.6
    @Published var pictogramScaleSize: Double = 1.1
    @Published var pictogramScaleDuration: Double = 0.6
    @Published var enabledShapes: Set<ConfettiShape> = [.star, .blob, .rect]
    @Published var enabledColorFamilies: Set<ConfettiColorFamily> = [.mandarin, .blossom, .pollen]

    static let weightedShapes: [ConfettiShape] = [
        .star, .blob, .rect, .rect, .strip, .strip
    ]

    static let colorFamilies: [ConfettiColorFamily: [ConfettiShade]] = [
        .mandarin: [
            ConfettiShade(fill: Color(hex: 0xF05F2B), stroke: Color(hex: 0x9E2B08)),
            ConfettiShade(fill: Color(hex: 0xFF8D5C), stroke: Color(hex: 0xCC3B0A)),
            ConfettiShade(fill: Color(hex: 0xFFB294), stroke: Color(hex: 0xF05F2B)),
        ],
        .pondwater: [
            ConfettiShade(fill: Color(hex: 0x4397E0), stroke: Color(hex: 0x045EB2)),
            ConfettiShade(fill: Color(hex: 0x75B6EB), stroke: Color(hex: 0x1074CC)),
            ConfettiShade(fill: Color(hex: 0xA1D0F7), stroke: Color(hex: 0x4397E0)),
        ],
        .lilypad: [
            ConfettiShade(fill: Color(hex: 0x589D88), stroke: Color(hex: 0x11604D)),
            ConfettiShade(fill: Color(hex: 0x84BBA8), stroke: Color(hex: 0x247A64)),
            ConfettiShade(fill: Color(hex: 0xAED5C2), stroke: Color(hex: 0x589D88)),
        ],
        .blossom: [
            ConfettiShade(fill: Color(hex: 0x9F6EB8), stroke: Color(hex: 0x682A7A)),
            ConfettiShade(fill: Color(hex: 0xC19EDB), stroke: Color(hex: 0x7D4794)),
            ConfettiShade(fill: Color(hex: 0xD3B9EB), stroke: Color(hex: 0x9F6EB8)),
        ],
        .pollen: [
            ConfettiShade(fill: Color(hex: 0xFAB341), stroke: Color(hex: 0xB66A1F)),
            ConfettiShade(fill: Color(hex: 0xFFC95C), stroke: Color(hex: 0xF5A031)),
            ConfettiShade(fill: Color(hex: 0xFFD885), stroke: Color(hex: 0xFAB341)),
        ],
    ]

    static let shapeTitles: [ConfettiShape: String] = [
        .star: "Star",
        .blob: "Blob",
        .rect: "Rectangle",
        .strip: "Strip",
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
            zSpin: zSpin,
            size: size,
            sizeVariation: sizeVariation,
            pictogramScaleSize: pictogramScaleSize,
            pictogramScaleDuration: pictogramScaleDuration,
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
