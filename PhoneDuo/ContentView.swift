import SwiftUI

struct ContentView: View {
    @State private var motion = FoldMotionModel()
    @State private var showsControls = false
    @State private var paused = false
    @AppStorage("effectStyle") private var style = "Silk"
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var parameters: FoldParameters {
        var result = FoldParameters()
        if style == "Frost" { result.blurSpread = 0.20; result.darkening = 0.012 }
        if style == "Clear" { result.blurSpread = 0; result.darkening = 0 }
        return result
    }

    var body: some View {
        FoldSurface(motion: motion, isFlat: paused || reduceMotion, parameters: parameters)
        .background(.black)
        .overlay(alignment: .bottom) { controls }
        .onAppear {
            if !reduceMotion { motion.start() }
            showsControls = ProcessInfo.processInfo.arguments.contains("--show-controls")
        }
        .onDisappear { motion.stop() }
        .onChange(of: phase) { _, state in
            if state == .active { resumeMotion() } else { motion.stop() }
        }
        .onChange(of: motion.usesManualTilt) { _, manual in
            if manual { motion.stop() } else { resumeMotion() }
        }
        .onChange(of: paused) { _, value in
            if value { motion.stop() } else { resumeMotion() }
        }
        .onChange(of: reduceMotion) { _, value in
            if value { motion.stop() } else { resumeMotion() }
        }
    }

    private func resumeMotion() {
        guard !paused, !reduceMotion, phase == .active else { return }
        motion.recalibrate()
        motion.start()
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if showsControls {
                panel.transition(.move(edge: .bottom).combined(with: .opacity))
            }
            HStack(spacing: 14) {
                Circle().fill(paused || reduceMotion ? Color.secondary : Color.teal).frame(width: 7, height: 7)
                Text(reduceMotion ? "Reduce Motion is on" : paused ? "Paused" : motion.usesManualTilt ? "Manual preview" : "Tilt your phone")
                    .font(.system(size: 12, weight: .medium)).accessibilityIdentifier("motionStatus")
                Spacer()
                Button {
                    paused.toggle()
                } label: {
                    Image(systemName: paused ? "play.fill" : "pause.fill").frame(width: 32, height: 32)
                }.accessibilityLabel(paused ? "Resume effect" : "Pause effect")
                    .accessibilityIdentifier("pauseEffect").disabled(reduceMotion)
                Button {
                    withAnimation(reduceMotion ? nil : .snappy) { showsControls.toggle() }
                } label: {
                    Image(systemName: showsControls ? "xmark" : "slider.horizontal.3").frame(width: 32, height: 32)
                }.accessibilityLabel(showsControls ? "Close controls" : "Open controls")
                    .accessibilityIdentifier("toggleControls")
            }.buttonStyle(.plain).padding(.horizontal, 18).padding(.vertical, 9)
                .background(Color.white.opacity(0.96), in: Capsule())
        }.padding(.horizontal, 20).padding(.bottom, 8)
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Make it move.").font(.headline)
                Spacer()
                TiltReadout(motion: motion, isFlat: paused || reduceMotion)
            }
            Picker("Finish", selection: $style) {
                ForEach(["Silk", "Frost", "Clear"], id: \.self) { Text($0) }
            }.pickerStyle(.segmented).accessibilityIdentifier("finishPicker")
            Toggle("Manual tilt", isOn: $motion.usesManualTilt)
                .disabled(!motion.isMotionAvailable).accessibilityIdentifier("manualToggle")
            if motion.usesManualTilt {
                Slider(value: $motion.manualDegrees, in: -45...45)
                    .accessibilityLabel("Tilt angle").accessibilityIdentifier("tiltSlider")
                HStack {
                    Text("−45°")
                    Spacer()
                    Button("Reset angle") { motion.manualDegrees = 0 }.accessibilityIdentifier("resetAngle")
                    Spacer()
                    Text("45°")
                }.font(.caption)
            } else {
                Button {
                    motion.recalibrate()
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } label: {
                    Label("Set this angle as neutral", systemImage: "scope").frame(maxWidth: .infinity)
                }.buttonStyle(.bordered).accessibilityIdentifier("calibrate")
            }
            Text(motion.isMotionAvailable
                 ? "Hold the phone comfortably, then turn it gently left and right. Keep your head roughly still."
                 : "Motion is unavailable here. Use the slider to preview; a real iPhone follows your hand automatically.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if let error = motion.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
                Button("Retry motion") { resumeMotion() }
            }
        }.padding(20).background(Color.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 24))
    }
}

#Preview { ContentView() }

// Only the surface and numeric readout observe per-frame angle changes. The controls
// and their layout do not need to be rebuilt for every sensor sample.
private struct FoldSurface: View {
    let motion: FoldMotionModel
    let isFlat: Bool
    let parameters: FoldParameters

    var body: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            DemoContentView()
                .safeAreaPadding(insets)
                .frame(width: proxy.size.width + insets.leading + insets.trailing,
                       height: proxy.size.height + insets.top + insets.bottom)
                .clipped()
                .foldEffect(angle: isFlat ? 0 : motion.tiltAngle, parameters: parameters)
                .ignoresSafeArea()
        }
    }
}

private struct TiltReadout: View {
    let motion: FoldMotionModel
    let isFlat: Bool
    var body: some View {
        Text("\((isFlat ? 0 : motion.tiltAngle) * 180 / .pi, specifier: "%.1f")°")
            .font(.system(.subheadline, design: .monospaced))
            .accessibilityIdentifier("tiltReadout")
    }
}
