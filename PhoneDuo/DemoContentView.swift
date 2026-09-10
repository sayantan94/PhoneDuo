import SwiftUI

/// Pure SwiftUI content: the complete surface can be composited into a shader layer.
struct DemoContentView: View {
    private let ink = Color(red: 0.14, green: 0.23, blue: 0.23)
    private let mint = Color(red: 0.73, green: 0.88, blue: 0.79)

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("A LITTLE CHANGE IN PERSPECTIVE").font(.system(size: 8, weight: .semibold)).tracking(1.5).foregroundStyle(ink.opacity(0.55))
                    Text("PhoneDuo").font(.system(size: 34, weight: .semibold, design: .rounded)).tracking(-1.4)
                }
                Spacer()
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 23, weight: .light)).frame(width: 48, height: 48)
                    .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 16))
            }
            HStack(spacing: 7) {
                Circle().fill(Color.teal).frame(width: 5, height: 5)
                Text("MADE TO MOVE").font(.system(size: 9, weight: .semibold)).tracking(1.2)
                Spacer()
                Text("01 / THE FOLD").font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundStyle(ink.opacity(0.5))
            }
            hero
            HStack(spacing: 12) {
                tile(icon: "water.waves", title: "A softer focus", detail: "A little blur. A lot of depth.", color: Color(red: 0.89, green: 0.87, blue: 0.97))
                tile(icon: "sun.max", title: "Light, in motion", detail: "A new angle on the ordinary.", color: Color(red: 0.97, green: 0.88, blue: 0.70))
            }
            VStack(alignment: .leading, spacing: 14) {
                Text("TAKE IT FOR A SPIN").font(.system(size: 9, weight: .semibold)).tracking(1.4).foregroundStyle(ink.opacity(0.5))
                instruction("01", "Hold it comfortably.", "The first pose is your starting point.")
                instruction("02", "Turn it gently.", "Move left and right. Watch the surface fold.")
                instruction("03", "Find a new perspective.", "Recalibrate any time from the controls.")
            }.padding(.top, 3)
            Spacer(minLength: 0)
        }
        .foregroundStyle(ink)
        .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 82)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(red: 0.95, green: 0.95, blue: 0.91))
    }
    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text("Turn a little.\nFeel the fold.").font(.system(size: 34, weight: .medium, design: .rounded)).tracking(-1.4).lineSpacing(-2)
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 22, weight: .light))
            }
            HStack(alignment: .bottom) {
                Text("Your screen, with\na different point of view.").font(.system(size: 12)).lineSpacing(3).foregroundStyle(ink.opacity(0.7))
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 9).fill(ink.opacity(0.12)).frame(width: 66, height: 90).rotationEffect(.degrees(-18)).offset(x: -22, y: 0)
                    RoundedRectangle(cornerRadius: 9).fill(ink.opacity(0.25)).frame(width: 66, height: 90).rotationEffect(.degrees(4))
                    RoundedRectangle(cornerRadius: 9).fill(.white.opacity(0.62)).frame(width: 66, height: 90).rotationEffect(.degrees(26)).offset(x: 22, y: -1)
                }.frame(width: 125, height: 90)
            }
        }.padding(22).frame(maxWidth: .infinity, alignment: .leading)
            .background(mint, in: RoundedRectangle(cornerRadius: 26))
    }
    private func tile(icon: String, title: String, detail: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).font(.system(size: 23, weight: .light))
            Text(title).font(.system(size: 13, weight: .semibold))
            Text(detail).font(.system(size: 10)).foregroundStyle(ink.opacity(0.65)).lineLimit(2)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
            .background(color, in: RoundedRectangle(cornerRadius: 20))
    }
    private func instruction(_ number: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(ink.opacity(0.35)).padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 12, weight: .medium))
                Text(detail).font(.system(size: 10)).foregroundStyle(ink.opacity(0.55))
            }
        }
    }
}
