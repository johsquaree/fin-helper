import SwiftUI

struct NotificationView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        List {
            if viewModel.notifications.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Bildirim yok")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.notifications) { notif in
                    NotificationRow(notification: notif)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !notif.isRead {
                                viewModel.markNotificationRead(notif)
                            }
                        }
                }
                .onDelete { indexSet in
                    indexSet.forEach { viewModel.deleteNotification(viewModel.notifications[$0]) }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Bildirimler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.notifications.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tümünü Oku") {
                        viewModel.markAllNotificationsRead()
                    }
                    .disabled(viewModel.unreadNotificationCount == 0)
                }
            }
        }
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: notification.date, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(notification.isRead ? Color.clear : Color.blue)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.body)
                    .fontWeight(notification.isRead ? .regular : .semibold)
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text(timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(notification.isRead ? 0.7 : 1.0)
    }
}
