// QuestionBank.swift – Sample SAT question bank (Math + EBRW)

import Foundation

struct QuestionBank {
    static let all: [Question] = math + ebrw

    // MARK: - Math Questions

    static let math: [Question] = [
        // Algebra
        Question(id: UUID(), text: "If 3x + 7 = 22, what is the value of x?",
                 options: ["3", "5", "7", "9"], correctIndex: 1,
                 explanation: "Subtract 7 from both sides: 3x = 15, then divide by 3: x = 5.",
                 subject: .math, topic: MathTopic.algebra.rawValue, difficulty: .easy),

        Question(id: UUID(), text: "Which of the following is equivalent to 2(x + 3) - (x - 1)?",
                 options: ["x + 5", "x + 7", "3x + 7", "x - 5"], correctIndex: 1,
                 explanation: "Expand: 2x + 6 - x + 1 = x + 7.",
                 subject: .math, topic: MathTopic.algebra.rawValue, difficulty: .easy),

        Question(id: UUID(), text: "A line passes through (0, 4) and (2, 0). What is its slope?",
                 options: ["-2", "-½", "2", "½"], correctIndex: 0,
                 explanation: "Slope = (0-4)/(2-0) = -4/2 = -2.",
                 subject: .math, topic: MathTopic.algebra.rawValue, difficulty: .medium),

        Question(id: UUID(), text: "If y = 2x² - 8x + 6, for what value of x is y at its minimum?",
                 options: ["2", "-2", "4", "1"], correctIndex: 0,
                 explanation: "For ax²+bx+c, the vertex x = -b/2a = 8/4 = 2.",
                 subject: .math, topic: MathTopic.algebra.rawValue, difficulty: .medium),

        Question(id: UUID(), text: "Solve the system: x + y = 10, x - y = 4. What is x?",
                 options: ["3", "7", "6", "4"], correctIndex: 1,
                 explanation: "Add the equations: 2x = 14, so x = 7.",
                 subject: .math, topic: MathTopic.algebra.rawValue, difficulty: .easy),

        // Advanced Math
        Question(id: UUID(), text: "Which expression is equivalent to (x² - 9) / (x - 3)?",
                 options: ["x - 3", "x + 3", "x² + 3", "x - 9"], correctIndex: 1,
                 explanation: "Factor: (x-3)(x+3)/(x-3) = x+3 (x ≠ 3).",
                 subject: .math, topic: MathTopic.advancedMath.rawValue, difficulty: .medium),

        Question(id: UUID(), text: "If f(x) = x² + 2x - 3, what are the roots?",
                 options: ["x = 1, x = -3", "x = -1, x = 3", "x = 1, x = 3", "x = -1, x = -3"],
                 correctIndex: 0,
                 explanation: "Factor: (x+3)(x-1) = 0, so x = -3 or x = 1.",
                 subject: .math, topic: MathTopic.advancedMath.rawValue, difficulty: .medium),

        Question(id: UUID(), text: "What is the value of 4^(3/2)?",
                 options: ["6", "8", "12", "16"], correctIndex: 1,
                 explanation: "4^(3/2) = (√4)³ = 2³ = 8.",
                 subject: .math, topic: MathTopic.advancedMath.rawValue, difficulty: .medium),

        Question(id: UUID(),
                 text: "The function g(x) = 2(x - 1)² + 3. What is the minimum value of g(x)?",
                 options: ["1", "2", "3", "5"], correctIndex: 2,
                 explanation: "The vertex form shows vertex at (1, 3), so minimum is 3.",
                 subject: .math, topic: MathTopic.advancedMath.rawValue, difficulty: .medium),

        // Problem Solving & Data Analysis
        Question(id: UUID(), text: "A store sells 60 items. 40% are on sale. How many items are NOT on sale?",
                 options: ["24", "36", "40", "16"], correctIndex: 1,
                 explanation: "60% are not on sale: 0.60 × 60 = 36.",
                 subject: .math, topic: MathTopic.problemSolving.rawValue, difficulty: .easy),

        Question(id: UUID(), text: "The mean of five numbers is 12. If four of the numbers are 10, 11, 13, and 14, what is the fifth?",
                 options: ["10", "11", "12", "13"], correctIndex: 2,
                 explanation: "Sum = 12 × 5 = 60. Known sum = 48. Fifth = 60 - 48 = 12.",
                 subject: .math, topic: MathTopic.problemSolving.rawValue, difficulty: .easy),

        Question(id: UUID(), text: "A car travels 150 miles in 3 hours, then 200 miles in 4 hours. What is the average speed for the whole trip?",
                 options: ["50 mph", "56.25 mph", "50.7 mph", "57 mph"], correctIndex: 0,
                 explanation: "Total: 350 miles / 7 hours = 50 mph.",
                 subject: .math, topic: MathTopic.problemSolving.rawValue, difficulty: .medium),

        Question(id: UUID(), text: "A scatter plot shows a strong positive correlation. Which r-value best describes it?",
                 options: ["-0.9", "0.1", "0.85", "-0.1"], correctIndex: 2,
                 explanation: "Strong positive correlation → r close to +1, so 0.85.",
                 subject: .math, topic: MathTopic.problemSolving.rawValue, difficulty: .medium),

        // Geometry & Trigonometry
        Question(id: UUID(), text: "A circle has a radius of 5. What is its circumference? (Use π ≈ 3.14)",
                 options: ["15.7", "31.4", "78.5", "25"], correctIndex: 1,
                 explanation: "C = 2πr = 2 × 3.14 × 5 = 31.4.",
                 subject: .math, topic: MathTopic.geometry.rawValue, difficulty: .easy),

        Question(id: UUID(), text: "In a right triangle, the two legs are 3 and 4. What is the hypotenuse?",
                 options: ["5", "6", "7", "8"], correctIndex: 0,
                 explanation: "Pythagorean theorem: 3² + 4² = 9 + 16 = 25, √25 = 5.",
                 subject: .math, topic: MathTopic.geometry.rawValue, difficulty: .easy),

        Question(id: UUID(), text: "What is sin(30°)?",
                 options: ["√3/2", "1/2", "√2/2", "1"], correctIndex: 1,
                 explanation: "sin(30°) = 1/2 (from the 30-60-90 special triangle).",
                 subject: .math, topic: MathTopic.geometry.rawValue, difficulty: .medium),

        Question(id: UUID(), text: "The volume of a cylinder with radius 3 and height 4 is:",
                 options: ["12π", "36π", "48π", "72π"], correctIndex: 1,
                 explanation: "V = πr²h = π × 9 × 4 = 36π.",
                 subject: .math, topic: MathTopic.geometry.rawValue, difficulty: .medium),

        Question(id: UUID(),
                 text: "Two parallel lines are cut by a transversal. If one interior angle is 65°, what is the co-interior (same-side) angle?",
                 options: ["65°", "115°", "25°", "90°"], correctIndex: 1,
                 explanation: "Co-interior angles are supplementary: 180° - 65° = 115°.",
                 subject: .math, topic: MathTopic.geometry.rawValue, difficulty: .medium),

        Question(id: UUID(), text: "A line has equation y = -3x + 2. What is the y-intercept?",
                 options: ["-3", "3", "2", "-2"], correctIndex: 2,
                 explanation: "In y = mx + b form, b = 2 is the y-intercept.",
                 subject: .math, topic: MathTopic.algebra.rawValue, difficulty: .easy),

        Question(id: UUID(), text: "If 5x - 3 > 12, which of the following must be true?",
                 options: ["x > 1", "x > 2", "x > 3", "x > 4"], correctIndex: 2,
                 explanation: "5x > 15, so x > 3.",
                 subject: .math, topic: MathTopic.algebra.rawValue, difficulty: .medium),
    ]

    // MARK: - EBRW Questions

    static let ebrw: [Question] = [
        // Craft and Structure
        Question(id: UUID(),
                 text: "In the sentence 'The scientist's hypothesis was corroborated by the data,' the word 'corroborated' most nearly means:",
                 options: ["contradicted", "confirmed", "suggested", "doubted"], correctIndex: 1,
                 explanation: "'Corroborated' means confirmed or supported, especially with evidence.",
                 subject: .ebrw, topic: EBRWTopic.craftStructure.rawValue, difficulty: .medium),

        Question(id: UUID(),
                 text: "The author uses the phrase 'a tempest in a teapot' most likely to suggest that the conflict is:",
                 options: ["dangerous and widespread", "trivial and exaggerated", "boiling and intense", "quiet and hidden"],
                 correctIndex: 1,
                 explanation: "'A tempest in a teapot' is an idiom meaning a great fuss about something trivial.",
                 subject: .ebrw, topic: EBRWTopic.craftStructure.rawValue, difficulty: .medium),

        Question(id: UUID(),
                 text: "A student wants to introduce an essay arguing that social media has both benefits and drawbacks for teenagers. Which opening sentence best introduces that argument?",
                 options: ["Millions of teenagers use social media every day.",
                           "Social media platforms were founded in the early 2000s.",
                           "While social media connects teens and fosters creativity, it also raises concerns about mental health and privacy.",
                           "Parents often worry about their children's screen time."],
                 correctIndex: 2,
                 explanation: "Choice C directly introduces a balanced argument by acknowledging both benefits and drawbacks, which is what the essay will develop.",
                 subject: .ebrw, topic: EBRWTopic.craftStructure.rawValue, difficulty: .hard),

        // Expression of Ideas
        Question(id: UUID(),
                 text: "Which revision of the underlined sentence best improves clarity?\n'The report, which was written by the team, it was submitted on Friday.'",
                 options: ["The report which was written by the team, submitted on Friday.",
                           "The report written by the team was submitted on Friday.",
                           "The team wrote the report, it was submitted on Friday.",
                           "The report was submitted Friday, written by the team."],
                 correctIndex: 1,
                 explanation: "Choice B eliminates the pronoun 'it' that causes a run-on, producing a clean sentence.",
                 subject: .ebrw, topic: EBRWTopic.expressionIdeas.rawValue, difficulty: .medium),

        Question(id: UUID(),
                 text: "To make the argument more persuasive, the author should add:",
                 options: ["a personal anecdote", "specific data and statistics", "more adjectives", "a restatement of the claim"],
                 correctIndex: 1,
                 explanation: "Specific data and statistics provide concrete evidence that strengthens persuasion.",
                 subject: .ebrw, topic: EBRWTopic.expressionIdeas.rawValue, difficulty: .medium),

        Question(id: UUID(),
                 text: "Which transition best connects these two sentences: 'Sales fell sharply. ___, the company's share price rose.'",
                 options: ["Therefore", "Furthermore", "Nevertheless", "Similarly"], correctIndex: 2,
                 explanation: "'Nevertheless' signals contrast, fitting because the share price rose despite falling sales.",
                 subject: .ebrw, topic: EBRWTopic.expressionIdeas.rawValue, difficulty: .medium),

        // Standard English Conventions
        Question(id: UUID(),
                 text: "Choose the correct punctuation: 'My brother who lives in Boston ___ is a doctor.'",
                 options: [", who lives in Boston,", "who lives in Boston,", ", who lives in Boston", "who lives in Boston"],
                 correctIndex: 0,
                 explanation: "Non-restrictive clauses (extra info) need commas on both sides.",
                 subject: .ebrw, topic: EBRWTopic.standardEnglish.rawValue, difficulty: .medium),

        Question(id: UUID(),
                 text: "Which is grammatically correct?",
                 options: ["Each of the students have submitted their essay.",
                           "Each of the students has submitted their essay.",
                           "Each of the students have submitted his essay.",
                           "Each of the students has submitted his or her essay."],
                 correctIndex: 3,
                 explanation: "'Each' is singular, so 'has' is correct; 'his or her' is the traditional formal pronoun agreement.",
                 subject: .ebrw, topic: EBRWTopic.standardEnglish.rawValue, difficulty: .medium),

        Question(id: UUID(),
                 text: "Choose the version with correct subject-verb agreement:\n'The committee, along with several advisors, ___ ready to vote.'",
                 options: ["are", "is", "were", "have been"], correctIndex: 1,
                 explanation: "The subject is 'committee' (singular); phrases like 'along with' don't change number → 'is'.",
                 subject: .ebrw, topic: EBRWTopic.standardEnglish.rawValue, difficulty: .medium),

        Question(id: UUID(),
                 text: "Which version correctly uses the semicolon?",
                 options: ["She loves hiking; however, she prefers the mountains.",
                           "She loves hiking, however; she prefers the mountains.",
                           "She loves hiking however; she prefers the mountains.",
                           "She loves hiking; however she prefers the mountains."],
                 correctIndex: 0,
                 explanation: "Semicolon before a conjunctive adverb like 'however,' followed by a comma.",
                 subject: .ebrw, topic: EBRWTopic.standardEnglish.rawValue, difficulty: .hard),

        // Information and Ideas
        Question(id: UUID(),
                 text: "Based on the passage: 'Photosynthesis converts light energy into chemical energy stored in glucose.' The primary function of photosynthesis is to:",
                 options: ["produce oxygen", "store energy in glucose", "consume carbon dioxide", "release water"],
                 correctIndex: 1,
                 explanation: "The passage explicitly states photosynthesis stores chemical energy in glucose.",
                 subject: .ebrw, topic: EBRWTopic.informationIdeas.rawValue, difficulty: .easy),

        Question(id: UUID(),
                 text: "A researcher claims that daily exercise improves memory. Which evidence would best support this claim?",
                 options: ["An anecdote about one student who exercises and has good grades",
                           "A peer-reviewed study showing improved memory scores in exercising participants",
                           "An opinion piece in a health magazine",
                           "A survey with 10 volunteers over one week"],
                 correctIndex: 1,
                 explanation: "Peer-reviewed studies with a controlled methodology provide the strongest scientific evidence.",
                 subject: .ebrw, topic: EBRWTopic.informationIdeas.rawValue, difficulty: .medium),

        Question(id: UUID(),
                 text: "The author's primary purpose in the passage is most likely to:",
                 options: ["entertain readers with a personal story",
                           "persuade readers to change their behavior",
                           "inform readers about a scientific phenomenon",
                           "compare two competing theories"],
                 correctIndex: 2,
                 explanation: "Informational/expository passages primarily aim to convey factual knowledge.",
                 subject: .ebrw, topic: EBRWTopic.informationIdeas.rawValue, difficulty: .medium),

        Question(id: UUID(),
                 text: "Which inference is best supported by: 'Despite years of negotiation, the two nations remained at odds over territorial boundaries'?",
                 options: ["The negotiations were successful.",
                           "The nations will never reach agreement.",
                           "The dispute is longstanding and unresolved.",
                           "Territorial boundaries no longer matter."],
                 correctIndex: 2,
                 explanation: "'Despite years' and 'remained at odds' indicate the conflict is ongoing and longstanding.",
                 subject: .ebrw, topic: EBRWTopic.informationIdeas.rawValue, difficulty: .medium),

        Question(id: UUID(),
                 text: "What does the graph most likely show if bars increase steadily from 2010 to 2020?",
                 options: ["A decline in the measured variable",
                           "No change over time",
                           "Consistent growth over the decade",
                           "A sharp spike followed by a drop"],
                 correctIndex: 2,
                 explanation: "Steadily increasing bars indicate consistent growth over the period shown.",
                 subject: .ebrw, topic: EBRWTopic.informationIdeas.rawValue, difficulty: .easy),

        Question(id: UUID(),
                 text: "Choose the most logical conclusion: 'All mammals are warm-blooded. Whales are mammals. Therefore...'",
                 options: ["whales are fish", "whales are cold-blooded", "whales are warm-blooded", "some whales are cold-blooded"],
                 correctIndex: 2,
                 explanation: "Syllogistic reasoning: if all mammals are warm-blooded and whales are mammals, whales are warm-blooded.",
                 subject: .ebrw, topic: EBRWTopic.informationIdeas.rawValue, difficulty: .easy),

        Question(id: UUID(),
                 text: "The tone of 'The government's half-hearted measures barely scratched the surface of the problem' is best described as:",
                 options: ["optimistic", "critical", "neutral", "celebratory"], correctIndex: 1,
                 explanation: "'Half-hearted' and 'barely scratched the surface' convey criticism of inadequate action.",
                 subject: .ebrw, topic: EBRWTopic.craftStructure.rawValue, difficulty: .medium),

        Question(id: UUID(),
                 text: "Which choice best maintains the essay's formal academic tone?\n'The results were ___.'",
                 options: ["pretty surprising", "quite unexpected", "kinda shocking", "super weird"],
                 correctIndex: 1,
                 explanation: "'Quite unexpected' uses formal diction appropriate for academic writing.",
                 subject: .ebrw, topic: EBRWTopic.expressionIdeas.rawValue, difficulty: .easy),

        Question(id: UUID(),
                 text: "Which is the correct plural possessive form of 'child'?",
                 options: ["child's", "childrens'", "children's", "childrens"], correctIndex: 2,
                 explanation: "'Children' is an irregular plural; possessive is formed by adding 's → children's.",
                 subject: .ebrw, topic: EBRWTopic.standardEnglish.rawValue, difficulty: .easy),

        Question(id: UUID(),
                 text: "Which sentence contains a dangling modifier?",
                 options: ["Running through the park, the dog barked loudly.",
                           "Running through the park, she spotted a rainbow.",
                           "She was running through the park when she spotted a rainbow.",
                           "The dog barked while she ran through the park."],
                 correctIndex: 0,
                 explanation: "'Running through the park' should modify the subject, but 'the dog' isn't running through the park — 'she' is.",
                 subject: .ebrw, topic: EBRWTopic.standardEnglish.rawValue, difficulty: .hard),
    ]

    // MARK: - Helpers

    static func questions(for subject: Subject) -> [Question] {
        all.filter { $0.subject == subject }
    }

    static func questions(for topic: String) -> [Question] {
        all.filter { $0.topic == topic }
    }

    static func diagnosticSet() -> [Question] {
        // 10 math + 10 EBRW, mixed difficulty
        let mathQ = math.shuffled().prefix(10)
        let ebrwQ = ebrw.shuffled().prefix(10)
        return Array((mathQ + ebrwQ).shuffled())
    }

    static func quizSet(topic: String, count: Int = 10) -> [Question] {
        let pool = questions(for: topic).shuffled()
        return Array(pool.prefix(count))
    }

    /// All unique topics
    static var allTopics: [(subject: Subject, topic: String)] {
        MathTopic.allCases.map { (.math, $0.rawValue) } +
        EBRWTopic.allCases.map { (.ebrw, $0.rawValue) }
    }
}
