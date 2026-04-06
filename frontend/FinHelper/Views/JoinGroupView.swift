import SwiftUI

struct JoinGroupView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    @State var code: String
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    init(viewModel: MainViewModel, initialCode: String = "") {
        self.viewModel = viewModel
        _code = State(initialValue: initialCode)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 56))
                        .foregroundColor(.blue)
                    Text("Gruba Katıl")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Davet kodunu girerek gruba katılabilirsin.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    TextField("Davet kodu", text: $code)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .font(.title3.monospaced())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button {
                        Task { await joinGroup() }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Katıl")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }

                Spacer()
            }
            .navigationTitle("Gruba Katıl")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Vazgeç") { dismiss() }
                }
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func joinGroup() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await viewModel.joinGroup(inviteCode: code.trimmingCharacters(in: .whitespaces))
            dismiss()
        } catch let error as NetworkError {
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
