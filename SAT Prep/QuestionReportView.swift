// QuestionReportView.swift – In-app question report form

import SwiftUI

struct QuestionReportView: View {

    let question: Question
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIssue: IssueType = .wrongAnswer
    @State private var notes: String = ""
    @State private var submitted = false

    enum IssueType: String, CaseIterable, Identifiable {
        case wrongAnswer    = "Wrong answer / explanation"
        case typo           = "Typo or formatting error"
        case unclearWording = "Unclear wording"
        case missingContext = "Missing context or passage"
        case other          = "Other"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    Text(question.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    LabeledContent("ID") {
                        Text(question.id.uuidString.prefix(8) + "…")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("Issue Type") {
                    Picker("Issue", selection: $selectedIssue) {
                        ForEach(IssueType.allCases) { issue in
                            Text(issue.rawValue).tag(issue)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section("Notes (optional)") {
                    TextEditor(text: $notes).frame(minHeight: 80)
                }
            }
            .navigationTitle("Report Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { submitReport() }.fontWeight(.semibold)
                }
            }
            .alert("Report Submitted", isPresented: $submitted) {
                Button("OK") { dismiss() }
            } message: {
                Text("Thank you! We'll review this question and fix it if needed.")
            }
        }
    }

    private func submitReport() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let optionLetters = ["A","B","C","D"]
        let optionsText = question.options.enumerated()
            .map { "\(optionLetters[safe: $0.offset] ?? "?"). \($0.element)" }
            .joined(separator: "\n")
        let body = """
App Version: \(appVersion) (\(build))
Question ID: \(question.id.uuidString.uppercased())
Topic: \(question.topic)
Difficulty: \(question.difficulty.rawValue)
Source: \(question.aiTopicCategory ?? "Hardcoded/OpenSAT")

Issue: \(selectedIssue.rawValue)

Question text:
\(question.text)

Options:
\(optionsText)

Correct answer: \(optionLetters[safe: question.correctIndex] ?? "?")

Notes from user:
\(notes.isEmpty ? "(none)" : notes)
"""
        let subject = "Exam Prep – Question Report"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody    = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:care@thewishboard.com?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
        submitted = true
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
