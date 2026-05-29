import SwiftUI

struct NativeTweakPanel: View {
    @ObservedObject var settings: NativeConfettiSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    sliderRow(title: "particleCount", valueText: "\(Int(settings.particleCount.rounded()))") {
                        Slider(value: $settings.particleCount, in: 10...120, step: 1)
                            .accessibilityIdentifier("NativeTweakParticleCount")
                    }
                    sliderRow(title: "startVelocity", valueText: "\(Int(settings.startVelocity.rounded()))") {
                        Slider(value: $settings.startVelocity, in: 5...60, step: 1)
                    }
                    sliderRow(title: "spread", valueText: "\(Int(settings.spread.rounded()))") {
                        Slider(value: $settings.spread, in: 10...180, step: 1)
                    }
                    sliderRow(title: "decay", valueText: String(format: "%.2f", settings.decay)) {
                        Slider(value: $settings.decay, in: 0.8...1.0, step: 0.01)
                    }
                    sliderRow(title: "gravity", valueText: valueWithSingleDecimal(settings.gravity)) {
                        Slider(value: $settings.gravity, in: 0...3, step: 0.1)
                    }
                    sliderRow(title: "duration", valueText: valueWithSingleDecimal(settings.duration)) {
                        Slider(value: $settings.duration, in: 1...5, step: 0.1)
                    }
                    sliderRow(title: "fadeOutVariance", valueText: valueWithSingleDecimal(settings.fadeOutVariance)) {
                        Slider(value: $settings.fadeOutVariance, in: 0...0.6, step: 0.1)
                    }
                    sliderRow(title: "xSpin", valueText: valueWithSingleDecimal(settings.xSpin)) {
                        Slider(value: $settings.xSpin, in: 0...1, step: 0.1)
                    }
                    sliderRow(title: "ySpin", valueText: valueWithSingleDecimal(settings.ySpin)) {
                        Slider(value: $settings.ySpin, in: 0...1, step: 0.1)
                    }
                    sliderRow(title: "zSpin", valueText: valueWithSingleDecimal(settings.zSpin)) {
                        Slider(value: $settings.zSpin, in: 0...1, step: 0.1)
                    }
                    sliderRow(title: "size", valueText: valueWithSingleDecimal(settings.size)) {
                        Slider(value: $settings.size, in: 0.5...3, step: 0.1)
                    }
                    sliderRow(title: "sizeVariation", valueText: valueWithSingleDecimal(settings.sizeVariation)) {
                        Slider(value: $settings.sizeVariation, in: 0...2, step: 0.1)
                    }
                    sliderRow(title: "pictogramScaleSize", valueText: valueWithSingleDecimal(settings.pictogramScaleSize)) {
                        Slider(value: $settings.pictogramScaleSize, in: 1...1.5, step: 0.05)
                            .accessibilityIdentifier("NativeTweakPictogramScaleSize")
                    }
                    sliderRow(title: "pictogramScaleDuration", valueText: valueWithSingleDecimal(settings.pictogramScaleDuration)) {
                        Slider(value: $settings.pictogramScaleDuration, in: 0.1...1.2, step: 0.05)
                            .accessibilityIdentifier("NativeTweakPictogramScaleDuration")
                    }

                    sectionTitle("shapes")
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(ConfettiShape.allCases, id: \.self) { shape in
                            Toggle(isOn: shapeBinding(for: shape)) {
                                Text(NativeConfettiSettings.shapeTitles[shape] ?? shape.rawValue.capitalized)
                            }
                            .toggleStyle(CheckboxToggleStyle())
                            .font(monoFont(size: 9))
                            .foregroundStyle(Color(hex: 0x273646))
                        }
                    }
                    .padding(.bottom, 10)

                    sectionTitle("colors")
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(ConfettiColorFamily.allCases, id: \.self) { family in
                            colorFamilyRow(family)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.top, 36)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color(hex: 0xD8E0E8))
                .frame(width: 1)
        }
        .accessibilityIdentifier("NativeTweakPanel")
    }

    private var header: some View {
        HStack {
            Text("TWEAK")
            Spacer()
            Text("-")
        }
        .font(monoFont(size: 10))
        .kerning(0.8)
        .foregroundStyle(Color(hex: 0x4B5F73))
        .padding(.bottom, 8)
    }

    private func sliderRow<Content: View>(title: String, valueText: String, @ViewBuilder control: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                Spacer()
                Text(valueText)
                    .frame(minWidth: 36, alignment: .trailing)
            }
            .font(monoFont(size: 9))
            .foregroundStyle(Color(hex: 0x66798B))

            control()
                .tint(Color(hex: 0x1074CC))
        }
        .padding(.bottom, 10)
    }

    private func sectionTitle(_ text: String) -> some View {
        HStack {
            Text(text)
            Spacer()
        }
        .font(monoFont(size: 9))
        .foregroundStyle(Color(hex: 0x66798B))
        .padding(.bottom, 4)
    }

    private func colorFamilyRow(_ family: ConfettiColorFamily) -> some View {
        HStack(spacing: 6) {
            Toggle(isOn: colorFamilyBinding(for: family)) {
                Text(family.title)
                    .font(monoFont(size: 9))
                    .foregroundStyle(Color(hex: 0x273646))
            }
            .toggleStyle(CheckboxToggleStyle())

            Spacer(minLength: 0)

            HStack(spacing: 3) {
                ForEach(NativeConfettiSettings.colorFamilies[family] ?? [], id: \.self) { shade in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(shade.fill)
                        .frame(width: 10, height: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.black.opacity(0.12), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.bottom, 5)
    }

    private func shapeBinding(for shape: ConfettiShape) -> Binding<Bool> {
        Binding(
            get: { settings.enabledShapes.contains(shape) },
            set: { settings.toggleShape(shape, isEnabled: $0) }
        )
    }

    private func colorFamilyBinding(for family: ConfettiColorFamily) -> Binding<Bool> {
        Binding(
            get: { settings.enabledColorFamilies.contains(family) },
            set: { settings.toggleColorFamily(family, isEnabled: $0) }
        )
    }

    private func valueWithSingleDecimal(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded.rounded() == rounded {
            return "\(Int(rounded))"
        }
        return String(format: "%.1f", rounded)
    }

    private func monoFont(size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }
}

private struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack(spacing: 6) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: 0x1074CC))
                configuration.label
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
