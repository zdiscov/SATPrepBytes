










































  The data has paragraphs. They're being combined into Question.text as paragraph\n\nquestion. Now let me check how FullTestView renders the question text
  — if it's just a single Text() or LaTeXView, a long paragraph + question in one block should display fine. Let me check if the issue is the badPatterns
  filter eating paragraph questions:
● Shell python3 - /tmp/opensat.json << 'EOF'
  import json, sys, re
  data = json.load(open(sys.argv[1]))
  badPatterns = ["shown below","shown above","figure below","figure above",
                 "graph below","graph above","table below","table above",
                 "align*","\\begin{","\\array"]
  
  para_qs = [q for q in data['english'] + data['math'] 
             if q['question'].get('paragraph') and q['question']['paragraph'] != 'null']
  
  # Simulate stem construction and filtering
  kept = 0
  filtered = 0
  for q in para_qs:
      p = q['question']['paragraph']
      qtext = q['question']['question']
      stem = f"{p}\n\n{qtext}"
      lower = stem.lower()
      if any(pat in lower for pat in badPatterns):
          filtered += 1
      else:
          kept += 1

        // Finally, fetch from API with proper error handling
        do {
            let questions = try await fetchFromAPI()
            saveCache(questions)
            
            // Process with AI in background (non-blocking)
            Task.detached(priority: .background) {
                await self.processQuestionsWithAI(questions)
            }
            
            logger.debug("Successfully fetched and cached \(questions.count, privacy: .public) questions")
            return questions
        } catch {
            logger.error("Failed to fetch questions: \(error.localizedDescription)")
            // Return empty array and let UI handle the error
            return []
        }
    }
    
    /// Fetches questions from API with proper error handling and timeouts
                           "align*","\\begin{","\\array",
                           // Formatting artifacts
                           "underlined","blank line","[blank]","as used in line",
                           "combines the sentences","completes the text",
                           "conforms to the conventions",
                           "corrects the error in the",
                           "use of metaphors","use of imagery","use of simile",
                           "semicolon in the passage","purpose of the semi",
                           // Self-referential passages
                           "the author's main purpose is to","the author's primary goal is to",
                           "the central theme of the passage is","the author begins by describing",
                           // Math requiring diagrams
                           "chord of the circle","chord of length","chord is"]
        if badPatterns.contains(where: { stemLower.contains($0) }) { return nil }

        return Question(
            id: UUID(),
            text: stem.strippingLatex,
            options: [c.choices.A, c.choices.B, c.choices.C, c.choices.D].map { $0.strippingLatex },
            correctIndex: correctIndex,
            explanation: c.explanation,
            subject: subject,
            topic: mapTopic(q.domain, subject: subject),
            difficulty: mapDifficulty(q.difficulty),
            isAIGenerated: false,
            aiTopicCategory: "opensat"
        )
    }

    private func mapTopic(_ domain: String, subject: Subject) -> String {
        if subject == .math {
            switch domain {
            case "Algebra":                            return MathTopic.algebra.rawValue
            case "Advanced Math":                      return MathTopic.advancedMath.rawValue
            case "Problem-Solving and Data Analysis":  return MathTopic.problemSolving.rawValue
            default:                                   return MathTopic.geometry.rawValue
            throw AppError.decodingError("Failed to parse API response")
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw AppError.timeout
            case .networkConnectionLost, .notConnectedToInternet:
                throw AppError.networkError("Network unavailable")
            default:
                throw AppError.networkError(error.localizedDescription)
            }
        }
    }

    /// Public entry point for synchronous bundle load (used by AppState.init).
    func loadBundledQuestions() -> [Question]? {
        loadLocalPreCleanedQuestions()
    }

    private func loadLocalPreCleanedQuestions() -> [Question]? {
        guard let fileURL = Bundle.main.url(forResource: "opensat_cleaned", withExtension: "json"),
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return try? JSONDecoder().decode([Question].self, from: data)
    }

    func deduplicated(_ questions: [Question], against hardcoded: [Question]) -> [Question] {
        let existing = Set(hardcoded.map { normalize($0.text) })
        return questions.filter { !existing.contains(normalize($0.text)) }
    }

    private func normalize(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
            .prefix(80).description
    }

    // MARK: - Mapping

    private func map(_ q: OpenSATQuestion, subject: Subject) -> Question? {
        let c = q.question
        guard c.correct_answer.count == 1,
              let correctIndex = ["A","B","C","D"].firstIndex(of: c.correct_answer) else { return nil }

        let stem = c.paragraph.map { p in
            p != "null" ? "\(p)\n\n\(c.question)" : c.question
        } ?? c.question

        let stemLower = stem.lowercased()
        let badPatterns = ["shown below","shown above","figure below","figure above",
                           "graph below","graph above","table below","table above",
                           "align*","\\begin{","\\array",
                           // Formatting artifacts
                           "underlined","blank line","[blank]","as used in line",
                           "combines the sentences","completes the text",
                           "conforms to the conventions",
  
            if q.text.contains("$") {
                if let response = try? await session.respond(to: promptText) {
                    textCleaned = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            if q.explanation.contains("$") {
                if let response = try? await session.respond(to: promptExpl) {
                    explCleaned = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }

            if textCleaned != q.text || explCleaned != q.explanation {
                questions[i] = Question(
                    id: q.id,
                    text: textCleaned,
                    options: q.options,
                    correctIndex: q.correctIndex,
                    explanation: explCleaned,
                    subject: q.subject,
                    topic: q.topic,
                    difficulty: q.difficulty,
                    isAIGenerated: q.isAIGenerated,
                    aiTopicCategory: q.aiTopicCategory
                )
                updated = true
            }

            // Periodically save cache in background
            if updated && i % 20 == 0 {
            default:                                   return MathTopic.geometry.rawValue
            }
        } else {
            switch domain {
            case "Information and Ideas":              return EBRWTopic.informationIdeas.rawValue
            case "Craft and Structure":                return EBRWTopic.craftStructure.rawValue
            case "Expression of Ideas":                return EBRWTopic.expressionIdeas.rawValue
            default:                                   return EBRWTopic.standardEnglish.rawValue
            }
        }
    }

    private func mapDifficulty(_ d: String) -> Difficulty {
        switch d { case "Easy": return .easy; case "Hard": return .hard; default: return .medium }
    }

    // MARK: - Cache

    private var cacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(cacheFile)
    }

    private func saveCache(_ questions: [Question]) {
        do {
            let data = try JSONEncoder().encode(questions)
            try data.write(to: cacheURL, options: .atomic)
            logger.debug("Cache saved successfully")
        } catch {
            logger.error("Failed to save cache: \(error.localizedDescription)")
            // Non-fatal: continue without cache
        }
    }

    private func loadCache() -> [Question]? {
        do {
            let data = try Data(contentsOf: cacheURL)
            let questions = try JSONDecoder().decode([Question].self, from: data)
            logger.debug("Loaded \(questions.count, privacy: .public) questions from cache")
            return questions
        } catch {
            logger.warning("Failed to load cache: \(error.localizedDescription)")
            return nil
        }
    }

    private func processQuestionsWithAI(_ questions: [Question]) async {
        // Use AIQuestionService's shared LanguageModelSession wrapper so all
        // Foundation Models calls are gated behind the correct iOS 26.0 check.
        guard AIQuestionService.shared.isAvailable else { return }

        var updated = false
        var updatedQuestions = questions

        for i in 0..<updatedQuestions.count {
            let q = updatedQuestions[i]

            // Only clean questions that still contain raw LaTeX dollar signs
            guard q.text.contains("$") || q.explanation.contains("$") else { continue }

            var textCleaned = q.text
            var explCleaned = q.explanation

            if q.text.contains("$") {
                let prompt = "Clean up the LaTeX dollar signs and formatting from this SAT question. Output ONLY the cleaned plain text: \(q.text)"
                if let cleaned = await AIQuestionService.shared.cleanText(prompt) {
                    textCleaned = cleaned
                }
            }
            if q.explanation.contains("$") {
                let prompt = "Clean up the LaTeX dollar signs, formatting, and correct any obvious math typos in this SAT explanation. Output ONLY the cleaned plain text: \(q.explanation)"
                if let cleaned = await AIQuestionService.shared.cleanText(prompt) {
                    explCleaned = cleaned
                }
            }

            if textCleaned != q.text || explCleaned != q.explanation {
                updatedQuestions[i] = Question(
                    id: q.id,
                    text: textCleaned,
                    options: q.options,
                    correctIndex: q.correctIndex,
                    explanation: explCleaned,
                    subject: q.subject,
                    topic: q.topic,
                    difficulty: q.difficulty,
                    isAIGenerated: q.isAIGenerated,
                    aiTopicCategory: q.aiTopicCategory
                )
                updated = true
            }

            if updated && i % 20 == 0 { saveCache(updatedQuestions) }
        }

        if updated { saveCache(updatedQuestions) }
    }
}








































































































































































































































































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