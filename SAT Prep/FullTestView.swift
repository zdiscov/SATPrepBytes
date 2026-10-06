// FullTestView.swift

import SwiftUI

import Combine

struct FullTestView: View {
    @EnvironmentObject var appState: AppState
    @State private var isTestActive = false
    @State private var completedSession: PracticeSession? = nil

    var body: some View {
        NavigationStack {
            if let session = completedSession {
                TestScoreView(session: session) { completedSession = nil }
            } else {
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 72)).foregroundStyle(.blue)
                    Text("Full Practice Test").font(.title.bold())

                    VStack(alignment: .leading, spacing: 10) {
                        TestInfoRow(icon: "timer",              label: "Timed",     value: "Approx. 20 min")
                        TestInfoRow(icon: "questionmark.circle",label: "Questions", value: "20 (Math + EBRW)")
                        TestInfoRow(icon: "chart.bar",          label: "Score",     value: "400–1600 scale")
                        TestInfoRow(icon: "wifi.slash",         label: "Offline",   value: "Fully supported")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14)
                        .fill(Color.cardBackground))
                    .padding(.horizontal)

                    Spacer()
                    Button("Start Test") { isTestActive = true }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 32)

                    let testCount = appState.sessions.filter(\.isFullTest).count
                    if testCount > 0 {
                        Text("You've taken \(testCount) test(s)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 20)
                }
                .navigationTitle("Tests")
                .fullScreenCover(isPresented: $isTestActive) {
                    TimedTestSession { session in
                        appState.recordSession(session)
                        completedSession = session
                        isTestActive = false
                    }
                    .environmentObject(appState)
                }
            }
        }
    }
}

// MARK: - Timed Test Session

private struct TimedTestSession: View {
    let onComplete: (PracticeSession) -> Void

    @EnvironmentObject var appState: AppState

    @State private var questions: [Question] = {
        let math = Array(QuestionBank.math.shuffled().prefix(10))
        let ebrw = Array(QuestionBank.ebrw.shuffled().prefix(10))
        return math + ebrw
    }()

    @State private var currentIndex = 0
    @State private var selectedAnswers: [Int: Int] = [:]
    @State private var timeRemaining: Int = 20 * 60
    @State private var showConfirmSubmit = false
    @State private var timerCancellable: AnyCancellable? = nil

    private var current: Question { questions[currentIndex] }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                TimerDisplay(seconds: timeRemaining)
                Spacer()
                Text("\(currentIndex + 1) / \(questions.count)").font(.subheadline)
                Spacer()
                Button("Submit") { showConfirmSubmit = true }
                    .font(.subheadline.bold()).foregroundStyle(.red)
            }
            .padding()
            .background(Color.cardBackground)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label(current.subject.rawValue,
                              systemImage: current.subject == .math ? "function" : "book")
                            .font(.caption).foregroundStyle(.blue)
                        Spacer()
                        DifficultyBadge(difficulty: current.difficulty)
                    }
                    Text(current.text).font(.body)
                    ForEach(current.options.indices, id: \.self) { i in
                        OptionButton(
                            label: ["A","B","C","D"][i],
                            text: current.options[i],
                            state: selectedAnswers[currentIndex] == i ? .selected : .normal,
                            isDisabled: false
                        ) { selectedAnswers[currentIndex] = i }
                    }
                }
                .padding()
            }

            // Navigation bar
            HStack(spacing: 16) {
                Button {
                    if currentIndex > 0 { currentIndex -= 1 }
                } label: {
                    HStack { Image(systemName: "chevron.left"); Text("Back") }
                }
                .disabled(currentIndex == 0)

                Spacer()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(questions.indices, id: \.self) { i in
                            Circle()
                                .fill(dotColor(for: i))
                                .frame(width: 10, height: 10)
                                .onTapGesture { currentIndex = i }
                        }

            // Navigation bar
            HStack(spacing: 16) {
                Button {
                    if currentIndex > 0 {
                        updateTimeSpent()
                        currentIndex -= 1
                    }
                } label: {
                    HStack { Image(systemName: "chevron.left"); Text("Back") }
                }
                .disabled(currentIndex == 0)

                Spacer()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(questions.indices, id: \.self) { i in
                            Circle()
                                .fill(dotColor(for: i))
                                .frame(width: 10, height: 10)
                                .onTapGesture {
                                    updateTimeSpent()
                                    currentIndex = i
                                }
                        }
                    }
                }
                Spacer()

                Button {
                    if currentIndex < questions.count - 1 {
                        updateTimeSpent()
                        currentIndex += 1
                    }
                } label: {
                    HStack { Text("Next"); Image(systemName: "chevron.right") }
                }
                .disabled(currentIndex == questions.count - 1)
            }
    private func updateTimeSpent() {
        let elapsed = Date().timeIntervalSince(currentQuestionStartTime)
        questionTimeSpent[currentIndex, default: 0] += elapsed
        currentQuestionStartTime = Date()
    }

    private func buildTestQuestions() -> [Question] {
        // Collect question IDs already attempted in previous timed full tests
        let testSessions = appState.sessions.filter(\.isFullTest)
        let attemptedIds = Set(testSessions.flatMap { $0.attempts.map(\.questionId) })
        
        // Define base pool of test-only questions
        let basePool: [Question]
        if appState.currentUser.isPremium {
            basePool = appState.allQuestions.filter(\.isTestOnly)
        } else {
            basePool = QuestionBank.all.filter(\.isTestOnly)
        }
        
        let mathPool = basePool.filter { $0.subject == .math }
        let ebrwPool = basePool.filter { $0.subject == .ebrw }
        
        // Filter for unattempted questions
        let unattemptedMath = mathPool.filter { !attemptedIds.contains($0.id) }
        let unattemptedEbrw = ebrwPool.filter { !attemptedIds.contains($0.id) }
        
        let selectedMath: [Question]
        if unattemptedMath.count >= 10 {
            selectedMath = Array(unattemptedMath.shuffled().prefix(10))
        } else {
            selectedMath = Array(mathPool.shuffled().prefix(10))
        }
        
        let selectedEbrw: [Question]
        if unattemptedEbrw.count >= 10 {
            selectedEbrw = Array(unattemptedEbrw.shuffled().prefix(10))
        } else {
            selectedEbrw = Array(ebrwPool.shuffled().prefix(10))
        }
        
        return selectedMath + selectedEbrw
    }

    var body: some View {
        VStack(spacing: 0) {
            if questions.isEmpty {
                ContentUnavailableView("Loading Test...", systemImage: "clock")
            } else {
                // Header
                HStack {
                    TimerDisplay(seconds: timeRemaining)
                }
                .padding(.horizontal)

                Button("Back to Tests", action: onDone)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
    }
}

private struct SectionScoreCard: View {
    let title: String; let score: Int; let correct: Int; let total: Int
    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Text("\(score)").font(.title.bold())
            Text("\(correct)/\(total)").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
    }
}

private struct TimerDisplay: View {
    let seconds: Int
    private var isLow: Bool { seconds < 60 }
    var body: some View {
        Label {
            Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                .font(.subheadline.monospacedDigit().bold())
                .foregroundStyle(isLow ? .red : .primary)
        } icon: {
            Image(systemName: "timer").foregroundStyle(isLow ? .red : .orange)
        }
    }
}

private struct TestInfoRow: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        HStack {
            Image(systemName: icon).frame(width: 24).foregroundStyle(.blue)
            Text(label); Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}

  quality checks automatically without any changes to the script.

▸ Credits: 0.19 • Time: 6s
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  how to run AI sectio alone ? possible?
   
  Add a --ai-only flag, same pattern as --refresh:
● Read /Users/pradeepbala/Development/iOS/SAT Prep/tests.swift (L38-45)
● Shell grep -n "=== stripping\|=== hasLatex\|=== KaTeX\|=== OpenSAT\|=== AI" "/Users/pradeepbala/Development/iOS/SAT Prep/tests.swift"
● Write /Users/pradeepbala/Development/iOS/SAT Prep/tests.swift
  added 3 lines at L78 in tests.swift
    78+  let aiOnly = CommandLine.arguments.contains("--ai-only")                                                                                          
    79+                                                                                                                                                    
    80+  if !aiOnly {                                                                                                                                      
    78   print("\n=== strippingLatex ===")

  Now find where the AI section begins and close the if !aiOnly block just before it:
● Read /Users/pradeepbala/Development/iOS/SAT Prep/tests.swift (L253-258)
● Write /Users/pradeepbala/Development/iOS/SAT Prep/tests.swift
  added 2 lines at L253 in tests.swift
   253   sema.wait()
   254   
   255+  } // end if !aiOnly                                                                                                                               
   256+                                                                                                                                                    
   255   // MARK: - AI passage/context quality check (requires Apple Intelligence)
● Shell cd "/Users/pradeepbala/Development/iOS/SAT Prep" && swift tests.swift --ai-only 2>&1 && echo "---" && swift tests.swift 2>&1 | grep -E
  "passed|failed|Skipped"

  cacheFile is defined inside the if !aiOnly block. Move it to top-level:
● Shell grep -n "cacheFile" "/Users/pradeepbala/Development/iOS/SAT Prep/tests.swift" | head -5
● Read /Users/pradeepbala/Development/iOS/SAT Prep/tests.swift (L189-194)

  cacheFile is already at top-level (inside if !aiOnly block now). I need to move just the cacheFile declaration before the if !aiOnly guard:
● Write /Users/pradeepbala/Development/iOS/SAT Prep/tests.swift
  added 2 lines at L78 in tests.swift
    78   let aiOnly = CommandLine.arguments.contains("--ai-only")
    79+  let cacheFile = FileManager.default.homeDirectoryForCurrentUser                                                                                   
    80+      .appendingPathComponent(".cache/sat-prep/opensat.json")                                                                                       
    79   
    80   if !aiOnly {

  Now remove the duplicate cacheFile declaration inside the block:
● Write /Users/pradeepbala/Development/iOS/SAT Prep/tests.swift
  removed 3 lines at L191 in tests.swift
   191   // MARK: - OpenSAT data validation (cached)
   192   
   193-  let cacheFile = FileManager.default.homeDirectoryForCurrentUser                                                                                   
   194-      .appendingPathComponent(".cache/sat-prep/opensat.json")                                                                                       
                else { finishTest() }
            }
    }

    private func dotColor(for i: Int) -> Color {
        if i == currentIndex { return .blue }
        return selectedAnswers[i] != nil ? .green : Color.cardBackground
    }

    private func finishTest() {
        timerCancellable?.cancel()
        updateTimeSpent()
        let attempts = questions.enumerated().map { i, q in
            let selected = selectedAnswers[i] ?? -1
            let time = questionTimeSpent[i] ?? 0
            return QuestionAttempt(questionId: q.id, selectedIndex: selected,
                                   isCorrect: selected == q.correctIndex, timeSpent: time,
                                   subject: q.subject)
        }
        let session = PracticeSession(id: UUID(), userId: appState.currentUser.id,
                                      date: Date(), attempts: attempts, sessionType: .fullTest)
        onComplete(session)
    }
}

// MARK: - Test Score View

private struct TestScoreView: View {
    let session: PracticeSession
    let onDone: () -> Void

  "Assistant Enabled" = 0 — Siri/Apple Intelligence is turned off. That's why isAvailable returns false.
  
  Go to System Settings → Apple Intelligence & Siri → toggle Apple Intelligence on. Once enabled (may require a model download of ~1-2GB), swift
  tests.swift --ai-only will run the passage quality checks.
 
▸ Credits: 0.62 • Time: 15s
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  or can we run it on my phone? iphone 17 pro max? but how to run tests there on the devive?
   
  You can't run a Swift script directly on iPhone. The options to get it running on device:
  
  1. Enable Apple Intelligence on your Mac — easiest, same device you're already on. System Settings → Apple Intelligence & Siri → On. One toggle, done.
  2. Add the AI check as a hidden debug button in the app — runs on the iPhone using the same FoundationModels already in the app, shows results on screen.
  But this mixes test code into the app.
  3. Xcode Test target — proper iOS unit test that runs on device via ⌘U. More setup but the right long-term approach.
  
  Option 1 is by far the least effort. Just enable Apple Intelligence on this Mac — the hardware supports it, it's just a toggle off.

▸ Credits: 0.21 • Time: 7s
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  how to set up xcode test target?
   
  Let me check the current project structure first:
● Read /Users/pradeepbala/Development/iOS/SAT Prep/SAT Prep.xcodeproj/project.pbxproj

  The project uses PBXFileSystemSynchronizedRootGroup (modern Xcode format) with no existing test target. Adding one via pbxproj manually is complex and
  error-prone.
  
                }
                .padding(.horizontal)

                Button("Back to Tests", action: onDone)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
    }
}

private struct SectionScoreCard: View {
    let title: String; let score: Int; let correct: Int; let total: Int
    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Text("\(score)").font(.title.bold())
            Text("\(correct)/\(total)").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
    }
}

private struct TimerDisplay: View {
    let seconds: Int
    private var isLow: Bool { seconds < 60 }
    var body: some View {
        Label {
            Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                .font(.subheadline.monospacedDigit().bold())
                .foregroundStyle(isLow ? .red : .primary)
        } icon: {
            Image(systemName: "timer").foregroundStyle(isLow ? .red : .orange)
        }
    }
}

private struct TestInfoRow: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        HStack {
            Image(systemName: icon).frame(width: 24).foregroundStyle(.blue)
            Text(label); Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}

  ─────────────────────────────                                                               
    0 passed, 1 failed                                                                        
    ❌ 1 test(s) failed                                                                       
   
  Apple Intelligence is working. Now let's understand what we're seeing — 9/20 flagged. Let me check if these are real data problems or the AI being too
  strict:
● Shell python3 - /tmp/opensat.json << 'EOF'
  import json, sys
  data = json.load(open(sys.argv[1]))
  
  # Find questions matching the flagged patterns
  patterns = [
      "punctuation error",
      "primary purpose",
      "best combines the sentences",
      "conforms to the conventions",
      "social media",
      "main idea of the passage",
      "best transition",
      "most clearly and concisely"
  ]
  
  for pat in patterns:
      for q in data['english']:
          qc = q['question']
          if pat.lower() in qc['question'].lower() and qc.get('paragraph') and qc['paragraph'] != 'null':
              print(f"PATTERN: {pat}")
              print(f"PASSAGE: {repr(qc['paragraph'][:150])}")
              print(f"QUESTION: {repr(qc['question'])}")
              print()
              break
  EOF
  

  These are real data quality problems in OpenSAT — two categories:
  
  1. The passage IS the answer — e.g. "The author's main purpose is to present a comprehensive argument..." — the passage literally tells you the answer
  instead of being actual source text. The AI correctly flags this as unanswerable.
  
  2. Question refers to something not in the truncated passage — e.g. "Which choice best combines the sentences at the underlined portion" — there's no
  underlined portion, it's a formatting artifact from the original SAT PDF.
  
  The AI check is working correctly. These are genuinely bad questions that should be filtered. Let me add these patterns to the badPatterns filter in
  OpenSATService:
● Read /Users/pradeepbala/Development/iOS/SAT Prep/SAT Prep/OpenSATService.swift (L84-91)
● Write /Users/pradeepbala/Development/iOS/SAT Prep/SAT Prep/OpenSATService.swift
  added 4 lines, removed 1 line at L84 in OpenSATService.swift
    84           let badPatterns = ["shown below","shown above","figure below","figure above",
    85                              "graph below","graph above","table below","table above",
    86-                             "align*","\\begin{","\\array"]                                                                                         
    86+                             "align*","\\begin{","\\array",                                                                                         
    87+                             "underlined portion","underlined sentence","blank line",                                                               
    88+                             "most clearly and concisely","punctuation error in the",                                                               
    89+                             "author's main purpose is to present","author's primary goal is to explain"]                                           
    87           if badPatterns.contains(where: { stemLower.contains($0) }) { return nil }

  Also update the test's badPatterns to match, and bump the cache:
● Write /Users/pradeepbala/Development/iOS/SAT Prep/tests.swift
  added 4 lines, removed 1 line at L221 in tests.swift
   221       let badPatterns = ["shown below","shown above","figure below","figure above",
   222-                         "graph below","graph above","align*","\\begin{","\\array"]                                                                 
   222+                         "graph below","graph above","align*","\\begin{","\\array",                                                                 
   223+                         "underlined portion","underlined sentence","blank line",                                                                   
   224+                         "most clearly and concisely","punctuation error in the",                                                                   
   225+                         "author's main purpose is to present","author's primary goal is to explain"]                                               
● Shell sed -i '' 's/opensat_v17/opensat_v18/' "/Users/pradeepbala/Development/iOS/SAT Prep/SAT Prep/OpenSATService.swift" && cd
  "/Users/pradeepbala/Development/iOS/SAT Prep" && xcodebuild -project "SAT Prep.xcodeproj" -scheme "SAT Prep" -sdk iphonesimulator26.5 ONLY_ACTIVE_ARCH=NO
  build 2>&1 | grep -E "error:|SUCCEEDED|FAILED" | head -3

  Now run the AI check again to see how many remain:
● Shell cd "/Users/pradeepbala/Development/iOS/SAT Prep" && swift tests.swift --ai-only 2>&1

  Still many issues. The AI is sampling randomly each run — it's hitting different questions. The root problem is broader than individual patterns: OpenSAT
  has a large category of English questions where the "passage" is either meta-commentary about what the passage says, or the question references something
  that can't be answered without the actual SAT source material (e.g. "underlined sentence", "word as used in the text" without the word appearing).
  
  Rather than playing whack-a-mole with patterns, the better fix is to filter all English passage questions where the passage is self-referential (talks
  about itself) or the question references formatting artifacts:
● Shell python3 - /tmp/opensat.json << 'EOF'
  import json, sys, re
  data = json.load(open(sys.argv[1]))
  
  self_ref = ["the author's main purpose is","the author's primary goal is",
              "the passage suggests that","the central theme of the passage is",
              "the author begins by","the author argues that"]
  formatting = ["underlined portion","underlined sentence","underlined section",
                "blank line","[blank]","as used in the text","as used in line",
                "most nearly mean","most clearly and concisely","combine the sentences",
                "complete the text so that","best transition","function of the underlined",
                "revise the underlined","first two sentences","following sentences"]
  
  para_qs = [q for q in data['english']
             if q['question'].get('paragraph') and q['question']['paragraph'] != 'null']
  
  selfref_count = sum(1 for q in para_qs
      if any(p in q['question']['paragraph'].lower() for p in self_ref))
  fmt_count = sum(1 for q in para_qs
      if any(p in q['question']['question'].lower() for p in formatting))
  both = sum(1 for q in para_qs
      if any(p in q['question']['paragraph'].lower() for p in self_ref)
      or any(p in q['question']['question'].lower() for p in formatting))
  
  print(f"English passage questions: {len(para_qs)}")
  print(f"Self-referential passage: {selfref_count}")
  print(f"Formatting artifact question: {fmt_count}")
  print(f"Either (would filter): {both}")
  print(f"Would keep: {len(para_qs) - both}")
  EOF
  

  304 bad English passage questions out of 1,394. Filtering them leaves 1,090 good ones — still plenty. Update OpenSATService with these broader patterns:
● Write /Users/pradeepbala/Development/iOS/SAT Prep/SAT Prep/OpenSATService.swift
  added 9 lines, removed 2 lines at L84 in OpenSATService.swift
    84           let badPatterns = ["shown below","shown above","figure below","figure above",
    85                              "graph below","graph above","table below","table above",
    86                              "align*","\\begin{","\\array",
    87-                             "underlined portion","underlined sentence","blank line",                                                               
    87+                             // Formatting artifacts (no visual context available)                                                                  
    88+                             "underlined portion","underlined sentence","underlined section",                                                       
    89+                             "blank line","[blank]","as used in line",                                                                              
    88                              "most clearly and concisely","punctuation error in the",
    89-                             "author's main purpose is to present","author's primary goal is to explain"]                                           
    91+                             "combine the sentences","complete the text so that",                                                                   
    92+                             "revise the underlined","function of the underlined",                                                                  
    93+                             // Self-referential passages (passage describes itself)                                                                
    94+                             "the author's main purpose is to","the author's primary goal is to",                                                   
    95+                             "the central theme of the passage is","the author begins by describing",                                               
    96+                             "the author argues that","the author's argument is"]                                                                   
● Write /Users/pradeepbala/Development/iOS/SAT Prep/tests.swift
  added 7 lines, removed 2 lines at L221 in tests.swift
   221       let badPatterns = ["shown below","shown above","figure below","figure above",
   222                          "graph below","graph above","align*","\\begin{","\\array",
   223-                         "underlined portion","underlined sentence","blank line",                                                                   
   223+                         "underlined portion","underlined sentence","underlined section",                                                           
   224+                         "blank line","[blank]","as used in line",                                                                                  
   224                          "most clearly and concisely","punctuation error in the",
   225-                         "author's main purpose is to present","author's primary goal is to explain"]                                               
   226+                         "combine the sentences","complete the text so that",                                                                       
   227+                         "revise the underlined","function of the underlined",                                                                      
   228+                         "the author's main purpose is to","the author's primary goal is to",                                                       
   229+                         "the central theme of the passage is","the author begins by describing",                                                   
   230+                         "the author argues that","the author's argument is"]                                                                       
● Shell sed -i '' 's/opensat_v18/opensat_v19/' "/Users/pradeepbala/Development/iOS/SAT Prep/SAT Prep/OpenSATService.swift" && cd
  "/Users/pradeepbala/Development/iOS/SAT Prep" && xcodebuild -project "SAT Prep.xcodeproj" -scheme "SAT Prep" -sdk iphonesimulator26.5 ONLY_ACTIVE_ARCH=NO
  build 2>&1 | grep -E "error:|SUCCEEDED|FAILED" | head -2 && swift tests.swift --ai-only 2>&1

  Still hitting variants not caught. The pattern is clear — "combines the sentences at the underlined portion" has many phrasings. Rather than enumerating
  all variants, use broader substring matches:
● Shell python3 - /tmp/opensat.json << 'EOF'
  import json, sys
  data = json.load(open(sys.argv[1]))
  para_qs = [q for q in data['english']
             if q['question'].get('paragraph') and q['question']['paragraph'] != 'null']
  underlined = [q for q in para_qs if 'underlined' in q['question']['question'].lower()]
  combines = [q for q in para_qs if 'combines the sentences' in q['question']['question'].lower()]
  completes = [q for q in para_qs if 'completes the' in q['question']['question'].lower()]
  print(f"'underlined' in question: {len(underlined)}")
  print(f"'combines the sentences': {len(combines)}")
  pri