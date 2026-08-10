import SwiftUI

struct LifeTreeView: View {
    let stage: TreeStage

    @State private var appeared = false
    @State private var swaying = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Ellipse()
                    .fill(Theme.treeCanopy.opacity(0.12))
                    .frame(width: geo.size.width * 0.72, height: geo.size.height * 0.08)
                    .offset(y: geo.size.height * 0.42)

                Image(stage.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: geo.size.width * 0.88, maxHeight: geo.size.height * 0.92)
                    .shadow(
                        color: Color.primary.opacity(0.08),
                        radius: 10,
                        y: 5
                    )
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .scaleEffect(appeared ? 1 : 0.82)
            .opacity(appeared ? 1 : 0)
            .rotationEffect(.degrees(swaying ? 0.8 : -0.8), anchor: .bottom)
            .animation(.spring(response: 0.7, dampingFraction: 0.65), value: appeared)
            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: swaying)
            .onAppear {
                appeared = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    swaying = true
                }
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: stage)
    }
}
