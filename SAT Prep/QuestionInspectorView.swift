// QuestionInspectorView.swift – Debug inspector for question data (DEBUG only)

import SwiftUI

struct QuestionInspectorView: View {
    let question: Question
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Identity") {
                    LabeledContent("ID", value: question.id.uuidString)
                    LabeledContent("Subject", value: question.subject.rawValue)
                    LabeledContent("Topic", value: question.topic)
                    LabeledContent("Difficulty", value: question.difficulty.rawValue)
                    LabeledContent("Source", value: question.aiTopicCategory ?? "hardcoded")
                    LabeledContent("AI Generated", value: question.isAIGenerated ? "Yes" : "No")
                    LabeledContent("Test Only", value: question.isTestOnly ? "Yes" : "No")
                }
                Section("Question") {
                    Text(question.text).font(.caption).textSelection(.enabled)
                }
                Section("Options") {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, opt in
                        HStack {
                            Text(opt).font(.caption)
                            Spacer()
                            if index == question.correctIndex {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                        }
                    }
                }
                Section("Explanation") {
                    Text(question.explanation).font(.caption).textSelection(.enabled)
                }
            }
            .navigationTitle("Question Inspector")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
