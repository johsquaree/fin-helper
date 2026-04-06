import SwiftUI

struct InviteGroupView: View {
    let group: Group
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    private var inviteCode: String { group.inviteCode ?? "------" }
    private var inviteLink: String { "finhelper://join/\(inviteCode)" }
    private var shareText: String { "\(group.icon) \(group.name) grubuna katılmak için FinHelper uygulamasını indir ve bu kodu gir: \(inviteCode)\n\nVeya linke tıkla: \(inviteLink)" }

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Text(group.icon)
                        .font(.system(size: 56))
                    Text(group.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Arkadaşlarını bu grup için davet et")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 16) {
                    Text("Davet Kodu")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)

                    Text(inviteCode)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .tracking(6)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    Button {
                        UIPasteboard.general.string = inviteCode
                        withAnimation { copied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { copied = false }
                        }
                    } label: {
                        Label(copied ? "Kopyalandı!" : "Kodu Kopyala",
                              systemImage: copied ? "checkmark" : "doc.on.doc")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(copied ? Color.green : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .animation(.easeInOut(duration: 0.2), value: copied)

                    ShareLink(item: shareText) {
                        Label("Paylaş", systemImage: "square.and.arrow.up")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Davet Et")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
