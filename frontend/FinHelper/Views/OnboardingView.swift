import SwiftUI

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "💰",
            title: "Harcamalarını Takip Et",
            description: "Günlük harcamalarını kategorilere göre kaydet, bütçeni kontrol altında tut.",
            color: Color.blue
        ),
        OnboardingPage(
            icon: "👥",
            title: "Grupla Harcama Yap",
            description: "Arkadaşlarınla grup oluştur, ortak harcamaları birlikte kaydedin.",
            color: Color.purple
        ),
        OnboardingPage(
            icon: "⚖️",
            title: "Kim Ne Kadar Borçlu?",
            description: "Kim kime ne kadar borçlu, FinHelper her şeyi otomatik hesaplar.",
            color: Color.green
        ),
        OnboardingPage(
            icon: "📊",
            title: "Finansal Farkındalık",
            description: "Aylık raporlar ve grafiklerle harcama alışkanlıklarını keşfet.",
            color: Color.orange
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            bottomBar
        }
        .ignoresSafeArea(edges: .top)
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            ZStack {
                page.color.opacity(0.1)
                    .ignoresSafeArea()
                VStack(spacing: 24) {
                    Text(page.icon)
                        .font(.system(size: 90))
                        .padding(.top, 80)
                    Text(page.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Text(page.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                    Spacer()
                }
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: currentPage == index ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }

            if currentPage < pages.count - 1 {
                HStack {
                    Button("Atla") {
                        hasSeenOnboarding = true
                    }
                    .foregroundColor(.secondary)
                    .font(.subheadline)

                    Spacer()

                    Button {
                        withAnimation { currentPage += 1 }
                    } label: {
                        HStack(spacing: 6) {
                            Text("İleri")
                            Image(systemName: "arrow.right")
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(50)
                    }
                }
                .padding(.horizontal, 32)
            } else {
                Button {
                    withAnimation { hasSeenOnboarding = true }
                } label: {
                    Text("Başla")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 32)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 40)
        .background(Color(.systemBackground))
    }
}
