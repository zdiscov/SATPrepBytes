// ReminderOptInSheet.swift – Sheet asking user to enable study reminders

import SwiftUI

struct ReminderOptInSheet: View {

    @Environment(\.dismiss) private var dismiss
    @State private var isRequesting = false

    var onOptIn: (() -> Void)?
    var onSkip: (() -> Void)?

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            VStack(spacing: 10) {
                Text("Never Miss a Study Session")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Get a quick daily reminder to keep your streak alive and your score climbing.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("One short notification per day")
                        .font(.subheadline)
                    Spacer()
                }
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Turn off anytime in Settings")
                        .font(.subheadline)
                    Spacer()
                }
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("No spam, ever")
                        .font(.subheadline)
                    Spacer()
                }
            }
            .padding(.horizontal, 36)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    isRequesting = true
                    Task {
                        let granted = await ReminderService.shared.requestPermission()
                        if granted {
                            await ReminderService.shared.scheduleIfNeeded()
                            UserDefaults.standard.set(true, forKey: "reminderOptInShown")
                            onOptIn?()
                        }
                        isRequesting = false
                        dismiss()
                    }
                } label: {
                    Group {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Turn On Reminders")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRequesting)
                .padding(.horizontal, 24)

                Button("Maybe Later") {
                    UserDefaults.standard.set(true, forKey: "reminderOptInShown")
                    onSkip?()
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    ReminderOptInSheet()
}
