import SwiftUI

struct SplashView: View {
    @Binding var pendingInviteCode: String?
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5

    init(pendingInviteCode: Binding<String?> = .constant(nil)) {
        _pendingInviteCode = pendingInviteCode
    }

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if isActive {
            if hasSeenOnboarding {
                LoginView(pendingInviteCode: $pendingInviteCode)
            } else {
                OnboardingView()
            }
        } else {
            VStack {
                VStack {
                    Image("finhelper_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                    
                    Text("FinHelper")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 0.9
                        self.opacity = 1.0
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
