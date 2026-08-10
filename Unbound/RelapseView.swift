import SwiftUI

struct RelapseView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var reason: RelapseReason?

    var body: some View {
        NavigationStack {
            Group {
                if step == 0 {
                    ScrollView{
                        whatHappened
                    }
                } else {
                    ScrollView{
                        restart
                    }
                    
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(.spring(response: 0.55, dampingFraction: 0.85), value: step)
            .navigationTitle(step == 0 ? L("relapse.one_setback") : L("relapse.start_again_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.close")) { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var whatHappened: some View {
        VStack(spacing: 18) {
            Text(L("relapse.its_okay"))
                .font(.largeTitle.bold())
                .padding(.top, 12)
            Text(L("relapse.progress_safe"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(L("relapse.what_happened"))
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

            VStack(spacing: 10) {
                ForEach(Array(RelapseReason.allCases.enumerated()), id: \.element.id) { index, option in
                    OptionCard(
                        title: option.title,
                        icon: option.icon,
                        isSelected: reason == option,
                        action: { reason = option }
                    )
                    .stagger(index)
                }
            }

            Spacer()

            PrimaryButton(title: L("common.continue")) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                    step = 1
                }
            }
            .opacity(reason == nil ? 0.5 : 1)
            .allowsHitTesting(reason != nil)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private var restart: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("🌱")
                .font(.system(size: 72))
            Text(L("relapse.lets_start"))
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text(L("relapse.next_goal"))
                .font(.title3)
                .multilineTextAlignment(.center)
            Text(L("relapse.you_got_this"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            PrimaryButton(title: L("relapse.start_again_button"), systemImage: "arrow.counterclockwise") {
                guard let reason else { return }
                store.logRelapse(reason: reason)
                dismiss()
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
}
