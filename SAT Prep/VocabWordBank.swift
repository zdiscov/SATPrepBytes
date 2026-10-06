// VocabWordBank.swift
// High-frequency SAT vocabulary words in MCQ format.
// Each word has a context sentence and 4 definition choices, matching the
// real digital SAT "Words in Context" question style.

import Foundation

struct VocabWord {
    let word: String
    let contextSentence: String  // The word appears in context; ask student to pick its meaning
    let options: [String]        // 4 definition choices
    let correctIndex: Int        // 0-based index of the correct definition
    let category: VocabCategory
}

enum VocabCategory: String, CaseIterable {
    case academic        = "Academic & Scholarly"
    case literary        = "Literary & Rhetorical"
    case scientific      = "Scientific & Analytical"
    case social          = "Social & Behavioral"
}

// MARK: - Word Bank (100 words)

let satVocabWordBank: [VocabWord] = [

    // ── Academic & Scholarly ─────────────────────────────────────────────

    VocabWord(word: "Substantiate",
              contextSentence: "The scientist struggled to substantiate her theory without access to the original data.",
              options: ["to disprove a claim entirely", "to support with evidence", "to simplify a complex idea", "to delay a decision"],
              correctIndex: 1, category: .academic),

    VocabWord(word: "Corroborate",
              contextSentence: "The eyewitness testimony corroborated what the security footage had already shown.",
              options: ["to contradict", "to exaggerate", "to confirm with additional evidence", "to replace"],
              correctIndex: 2, category: .academic),

    VocabWord(word: "Empirical",
              contextSentence: "The researchers insisted on empirical data rather than theoretical speculation.",
              options: ["based on observation or experiment", "related to ancient history", "derived from logic alone", "purely philosophical"],
              correctIndex: 0, category: .academic),

    VocabWord(word: "Infer",
              contextSentence: "From the blank stares, the professor could infer that the lecture had been confusing.",
              options: ["to state directly", "to deduce from evidence", "to memorize", "to argue against"],
              correctIndex: 1, category: .academic),

    VocabWord(word: "Explicit",
              contextSentence: "The contract was explicit about the penalties for late payment.",
              options: ["vague and open to interpretation", "stated clearly and directly", "hidden between the lines", "negotiable"],
              correctIndex: 1, category: .academic),

    VocabWord(word: "Implicit",
              contextSentence: "There was an implicit agreement among the colleagues that overtime would not be compensated.",
              options: ["formally written down", "loudly announced", "suggested without being directly stated", "disputed by all parties"],
              correctIndex: 2, category: .academic),

    VocabWord(word: "Pragmatic",
              contextSentence: "Rather than dreaming of a perfect solution, she took a pragmatic approach and worked with the resources available.",
              options: ["overly optimistic", "dealing with things in a realistic, practical way", "guided by emotion", "theoretical"],
              correctIndex: 1, category: .academic),

    VocabWord(word: "Ambiguous",
              contextSentence: "The wording of the law was so ambiguous that courts interpreted it in completely different ways.",
              options: ["perfectly clear", "biased toward one side", "open to more than one interpretation", "deliberately deceptive"],
              correctIndex: 2, category: .academic),

    VocabWord(word: "Redundant",
              contextSentence: "Adding more flour after the dough had already thickened was completely redundant.",
              options: ["essential and necessary", "no longer needed; unnecessarily repetitive", "innovative", "insufficient"],
              correctIndex: 1, category: .academic),

    VocabWord(word: "Salient",
              contextSentence: "The editor highlighted the most salient points of the report for quick reference.",
              options: ["least important", "most noticeable or important", "chronological", "controversial"],
              correctIndex: 1, category: .academic),

    VocabWord(word: "Eloquent",
              contextSentence: "Her eloquent speech moved the audience to tears.",
              options: ["fluent and persuasive in expression", "blunt and unpolished", "technical and precise", "monotonous"],
              correctIndex: 0, category: .academic),

    VocabWord(word: "Articulate",
              contextSentence: "The candidate was remarkably articulate, expressing complex ideas with ease.",
              options: ["able to express ideas clearly and effectively", "prone to interrupting others", "reluctant to speak in public", "overly verbose"],
              correctIndex: 0, category: .academic),

    VocabWord(word: "Synthesize",
              contextSentence: "The student's essay synthesized information from over a dozen sources into a cohesive argument.",
              options: ["to copy from a single source", "to combine elements into a unified whole", "to disprove a theory", "to separate into parts"],
              correctIndex: 1, category: .academic),

    VocabWord(word: "Credible",
              contextSentence: "The witness's story was credible because it was consistent with all available evidence.",
              options: ["barely believable", "worthy of belief or trust", "completely fabricated", "overly dramatic"],
              correctIndex: 1, category: .academic),

    VocabWord(word: "Elucidate",
              contextSentence: "The professor paused to elucidate the concept before continuing the lecture.",
              options: ["to obscure or confuse", "to make clear or explain", "to memorize", "to dismiss"],
              correctIndex: 1, category: .academic),

    // ── Literary & Rhetorical ────────────────────────────────────────────

    VocabWord(word: "Ephemeral",
              contextSentence: "The beauty of cherry blossoms is ephemeral, lasting only a few days each spring.",
              options: ["extremely vibrant", "lasting for only a short time", "uniquely colorful", "historically significant"],
              correctIndex: 1, category: .literary),

    VocabWord(word: "Ubiquitous",
              contextSentence: "Smartphones have become so ubiquitous that it is rare to see someone without one.",
              options: ["extremely expensive", "found or seeming to be found everywhere", "outdated", "highly regulated"],
              correctIndex: 1, category: .literary),

    VocabWord(word: "Rhetoric",
              contextSentence: "The politician's speech was full of rhetoric but light on specific policy proposals.",
              options: ["factual data and statistics", "language designed to persuade or impress", "scientific methodology", "legal terminology"],
              correctIndex: 1, category: .literary),

    VocabWord(word: "Didactic",
              contextSentence: "The novel has a didactic tone, repeatedly emphasizing the moral dangers of greed.",
              options: ["entertaining and lighthearted", "intended to instruct or teach a moral lesson", "ambiguous and open-ended", "purely descriptive"],
              correctIndex: 1, category: .literary),

    VocabWord(word: "Satirical",
              contextSentence: "The show was satirical, using humor to expose the absurdity of modern politics.",
              options: ["deeply serious and somber", "using irony or humor to criticize", "entirely factual", "nostalgic"],
              correctIndex: 1, category: .literary),

    VocabWord(word: "Hyperbole",
              contextSentence: "Saying 'I've told you a million times' is a classic example of hyperbole.",
              options: ["a subtle understatement", "extreme exaggeration for effect", "a direct comparison using 'like' or 'as'", "a contradiction in terms"],
              correctIndex: 1, category: .literary),

    VocabWord(word: "Poignant",
              contextSentence: "The film's final scene was poignant, leaving the audience in reflective silence.",
              options: ["confusing and disjointed", "evoking a strong sense of sadness or regret", "comedic and lighthearted", "overly long"],
              correctIndex: 1, category: .literary),

    VocabWord(word: "Evocative",
              contextSentence: "Her writing was so evocative that readers felt they were standing in the rain-soaked streets of Victorian London.",
              options: ["difficult to understand", "bringing strong images or feelings to mind", "factually inaccurate", "deliberately vague"],
              correctIndex: 1, category: .literary),

    VocabWord(word: "Juxtapose",
              contextSentence: "The author juxtaposes scenes of great wealth with images of extreme poverty to highlight inequality.",
              options: ["to combine two things into one", "to place side by side to highlight differences", "to eliminate one of two options", "to rank in order of importance"],
              correctIndex: 1, category: .literary),

    VocabWord(word: "Nuanced",
              contextSentence: "The critic praised the director's nuanced portrayal of a morally complex character.",
              options: ["black and white; without subtlety", "showing subtle and fine distinctions", "exaggerated for dramatic effect", "historically inaccurate"],
              correctIndex: 1, category: .literary),

    VocabWord(word: "Verbose",
              contextSentence: "The professor's verbose lectures often buried the key point in unnecessary detail.",
              options: ["concise and to the point", "using more words than needed", "difficult to understand", "unusually quiet"],
              correctIndex: 1, category: .literary),

    VocabWord(word: "Concise",
              contextSentence: "The editor asked the journalist to be more concise, cutting the article from 1,000 words to 300.",
              options: ["expressing much in few words", "unclear and rambling", "technically detailed", "emotionally charged"],
              correctIndex: 0, category: .literary),

    VocabWord(word: "Cynical",
              contextSentence: "After years of broken campaign promises, many voters had grown cynical about politicians.",
              options: ["overly trusting and naive", "distrustful of human sincerity", "enthusiastically optimistic", "politically neutral"],
              correctIndex: 1, category: .literary),

    VocabWord(word: "Nostalgic",
              contextSentence: "The old photographs made her nostalgic for the carefree summers of her childhood.",
              options: ["indifferent to the past", "longing for the past with a sense of fondness", "eager for the future", "resentful of past events"],
              correctIndex: 1, category: .literary),

    VocabWord(word: "Irony",
              contextSentence: "There was a sad irony in the fact that the fire station burned down first.",
              options: ["a statement that means exactly what it says", "a situation where the outcome is opposite to what was expected", "a type of logical argument", "an exaggerated comparison"],
              correctIndex: 1, category: .literary),

    // ── Scientific & Analytical ──────────────────────────────────────────

    VocabWord(word: "Exacerbate",
              contextSentence: "The drought exacerbated the food shortage that had been building for months.",
              options: ["to solve or fix a problem", "to make a bad situation worse", "to accurately measure", "to slowly improve"],
              correctIndex: 1, category: .scientific),

    VocabWord(word: "Mitigate",
              contextSentence: "City planners installed green roofs to mitigate the urban heat island effect.",
              options: ["to make something worse", "to measure precisely", "to make less severe or serious", "to completely eliminate"],
              correctIndex: 2, category: .scientific),

    VocabWord(word: "Catalyst",
              contextSentence: "The invention of the printing press served as a catalyst for the spread of literacy across Europe.",
              options: ["a final obstacle", "something that speeds up a process or change", "a type of chemical reaction", "a harmful side effect"],
              correctIndex: 1, category: .scientific),

    VocabWord(word: "Anomaly",
              contextSentence: "A temperature spike in December was an anomaly that puzzled climatologists.",
              options: ["a predictable pattern", "something that deviates from what is standard or expected", "a confirmed scientific law", "a gradual change"],
              correctIndex: 1, category: .scientific),

    VocabWord(word: "Tenuous",
              contextSentence: "The link between the two crimes was tenuous at best, unsupported by solid evidence.",
              options: ["extremely strong and clear", "very weak or flimsy", "historically documented", "scientifically proven"],
              correctIndex: 1, category: .scientific),

    VocabWord(word: "Scrutinize",
              contextSentence: "Auditors were brought in to scrutinize the company's financial records for irregularities.",
              options: ["to glance at briefly", "to approve without question", "to examine closely and critically", "to organize into categories"],
              correctIndex: 2, category: .scientific),

    VocabWord(word: "Quantify",
              contextSentence: "It is difficult to quantify the emotional impact of losing a pet.",
              options: ["to express in feelings", "to assign a numerical value or measure to", "to ignore entirely", "to compare to a historical event"],
              correctIndex: 1, category: .scientific),

    VocabWord(word: "Hypothesis",
              contextSentence: "Before running the experiment, the team proposed a hypothesis about what results to expect.",
              options: ["a proven scientific fact", "a conclusion drawn after an experiment", "a proposed explanation to be tested", "a historical record"],
              correctIndex: 2, category: .scientific),

    VocabWord(word: "Validate",
              contextSentence: "The second study validated the surprising findings of the first.",
              options: ["to disprove entirely", "to confirm or verify the accuracy of", "to complicate further", "to ignore"],
              correctIndex: 1, category: .scientific),

    VocabWord(word: "Extrapolate",
              contextSentence: "From the current growth trends, economists extrapolated that unemployment would reach 8% by year's end.",
              options: ["to look backward at historical data", "to guess without any evidence", "to extend a conclusion beyond the available data", "to reduce to a simpler form"],
              correctIndex: 2, category: .scientific),

    VocabWord(word: "Obsolete",
              contextSentence: "Once the new software launched, the old system quickly became obsolete.",
              options: ["highly advanced and current", "no longer in use; out of date", "difficult to operate", "widely adopted"],
              correctIndex: 1, category: .scientific),

    VocabWord(word: "Proliferate",
              contextSentence: "Social media platforms continued to proliferate, with new apps launching every month.",
              options: ["to gradually disappear", "to become less popular over time", "to grow or multiply rapidly", "to be carefully regulated"],
              correctIndex: 2, category: .scientific),

    VocabWord(word: "Systematic",
              contextSentence: "The investigation was systematic, leaving no stone unturned.",
              options: ["done randomly and without order", "done according to a fixed plan or method", "based on personal instinct", "rushed and incomplete"],
              correctIndex: 1, category: .scientific),

    VocabWord(word: "Sparse",
              contextSentence: "Vegetation was sparse in the desert region, with only a few cacti visible for miles.",
              options: ["dense and abundant", "thinly scattered; not dense", "brightly colored", "seasonal"],
              correctIndex: 1, category: .scientific),

    VocabWord(word: "Inherent",
              contextSentence: "There are inherent risks in any surgical procedure, no matter how skilled the surgeon.",
              options: ["existing as a natural or permanent part of something", "added on from an outside source", "avoidable with preparation", "entirely unpredictable"],
              correctIndex: 0, category: .scientific),

    // ── Social & Behavioral ──────────────────────────────────────────────

    VocabWord(word: "Bolster",
              contextSentence: "The manager's encouragement helped bolster the team's confidence before the big presentation.",
              options: ["to weaken or undermine", "to support or strengthen", "to confuse or mislead", "to replace entirely"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Prolific",
              contextSentence: "Shakespeare was a prolific writer, producing 37 plays and 154 sonnets in his lifetime.",
              options: ["producing very little work", "highly celebrated by critics", "producing a large body of work", "working in isolation"],
              correctIndex: 2, category: .social),

    VocabWord(word: "Equivocate",
              contextSentence: "When asked directly about the scandal, the official equivocated, giving vague non-answers.",
              options: ["to speak directly and honestly", "to use ambiguous language to avoid commitment", "to loudly deny all accusations", "to resign from a position"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Placate",
              contextSentence: "The company offered a refund to placate the angry customers.",
              options: ["to anger further", "to ignore the concerns of", "to make less angry or upset", "to formally apologize to in writing"],
              correctIndex: 2, category: .social),

    VocabWord(word: "Antagonize",
              contextSentence: "His sarcastic remarks only served to antagonize his already frustrated colleagues.",
              options: ["to calm and reassure", "to provoke hostility or opposition", "to inspire and motivate", "to confuse and mislead"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Condone",
              contextSentence: "The school administration refused to condone bullying in any form.",
              options: ["to formally punish", "to accept or allow behavior without protest", "to investigate thoroughly", "to clearly forbid"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Disparate",
              contextSentence: "The study brought together researchers from disparate fields, including biology, economics, and anthropology.",
              options: ["very similar and related", "essentially different; diverse", "working in opposition", "from the same institution"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Mundane",
              contextSentence: "After years of exciting fieldwork, she found it hard to return to the mundane tasks of office life.",
              options: ["exciting and unpredictable", "related to mountains and geography", "lacking interest; routine and ordinary", "highly technical"],
              correctIndex: 2, category: .social),

    VocabWord(word: "Elusive",
              contextSentence: "Despite years of searching, the cause of the disease remained elusive.",
              options: ["well-documented and understood", "difficult to find, catch, or achieve", "clearly visible to all", "recently discovered"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Pervasive",
              contextSentence: "A pervasive sense of unease spread through the community after the announcement.",
              options: ["limited to a small group", "quickly fading", "spreading through every part of something", "caused by one individual"],
              correctIndex: 2, category: .social),

    VocabWord(word: "Candid",
              contextSentence: "She was surprisingly candid in the interview, admitting flaws she would usually hide.",
              options: ["formal and rehearsed", "truthful and straightforward", "reluctant to share opinions", "overly dramatic"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Apathetic",
              contextSentence: "Voter turnout was low because many citizens felt apathetic about the election.",
              options: ["passionate and engaged", "showing little or no concern", "deeply informed", "angry and vocal"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Benevolent",
              contextSentence: "The benevolent donor gave millions to local hospitals and schools.",
              options: ["selfishly motivated", "well-meaning and generous", "politically ambitious", "reluctant and pressured"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Patronize",
              contextSentence: "She felt patronized when her supervisor explained something she already clearly understood.",
              options: ["to treat as an intellectual equal", "to treat in a condescending or superior way", "to financially support an artist", "to formally mentor"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Conform",
              contextSentence: "New employees often feel pressure to conform to the culture of the workplace.",
              options: ["to lead and innovate", "to resist all expectations", "to behave in accordance with standards or norms", "to formally object"],
              correctIndex: 2, category: .social),

    VocabWord(word: "Deviate",
              contextSentence: "The pilot was forced to deviate from the planned route due to severe weather.",
              options: ["to stick strictly to a plan", "to improve upon a method", "to depart from an established course", "to slow down"],
              correctIndex: 2, category: .social),

    VocabWord(word: "Collaborate",
              contextSentence: "The two rival companies agreed to collaborate on the vaccine research.",
              options: ["to compete aggressively", "to work jointly toward a common goal", "to independently reach the same conclusion", "to negotiate a peace agreement"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Advocate",
              contextSentence: "She spent her career as a passionate advocate for criminal justice reform.",
              options: ["a vocal opponent of a cause", "someone who publicly supports a cause", "an impartial judge of a dispute", "a neutral observer"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Marginalize",
              contextSentence: "The policy was criticized for marginalizing minority communities.",
              options: ["to bring to the center of attention", "to treat as unimportant or powerless", "to officially include in decision-making", "to study in academic research"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Resilient",
              contextSentence: "Despite years of hardship, the community proved remarkably resilient, rebuilding stronger than before.",
              options: ["easily discouraged", "able to recover quickly from difficulties", "dependent on outside help", "largely unchanged by experience"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Altruistic",
              contextSentence: "Her decision to donate a kidney to a stranger was seen as a truly altruistic act.",
              options: ["self-serving and calculated", "performed for personal fame", "motivated by concern for others' well-being", "legally required"],
              correctIndex: 2, category: .social),

    VocabWord(word: "Contentious",
              contextSentence: "The proposed border changes were contentious, sparking protests on both sides.",
              options: ["widely agreed upon", "causing or likely to cause disagreement", "resolved quickly", "supported by scientific evidence"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Diligent",
              contextSentence: "The diligent student spent three hours each evening reviewing her notes.",
              options: ["careless and distracted", "showing steady, careful effort", "naturally gifted without effort", "working only under pressure"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Impede",
              contextSentence: "A lack of funding continued to impede the research team's progress.",
              options: ["to accelerate or speed up", "to delay or obstruct", "to redirect toward a new goal", "to formally approve"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Facilitate",
              contextSentence: "The mediator was brought in to facilitate negotiations between the two parties.",
              options: ["to complicate or slow down", "to make easier or help bring about", "to formally oppose", "to document in writing"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Inevitable",
              contextSentence: "With resources running low, a conflict seemed inevitable.",
              options: ["easily avoidable", "surprising and unexpected", "certain to happen; unavoidable", "dependent on luck"],
              correctIndex: 2, category: .social),

    VocabWord(word: "Superficial",
              contextSentence: "The report offered only a superficial analysis of the problem, ignoring deeper structural issues.",
              options: ["extremely detailed and thorough", "existing only on the surface; lacking depth", "based on years of research", "intended to deceive"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Appease",
              contextSentence: "The government tried to appease protesters by promising a public inquiry.",
              options: ["to provoke or anger", "to satisfy or relieve demands, often temporarily", "to punish or penalize", "to ignore and dismiss"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Compel",
              contextSentence: "The new evidence compelled the jury to reconsider their verdict.",
              options: ["to suggest gently", "to force or drive someone to do something", "to confuse or mislead", "to publicly praise"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Diminish",
              contextSentence: "Years of public scandals began to diminish the mayor's reputation.",
              options: ["to strengthen or grow", "to make or become smaller or less significant", "to formally investigate", "to document for history"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Ambivalent",
              contextSentence: "She felt ambivalent about the job offer — excited by the salary but dreading the long commute.",
              options: ["fully committed and enthusiastic", "having mixed or contradictory feelings", "completely indifferent", "logically consistent"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Concede",
              contextSentence: "Even the opposing lawyer was forced to concede that the evidence was damning.",
              options: ["to flatly deny a point", "to argue more forcefully", "to acknowledge or admit reluctantly", "to request more time"],
              correctIndex: 2, category: .social),

    VocabWord(word: "Assert",
              contextSentence: "The report asserted that air quality had improved significantly over the past decade.",
              options: ["to question or cast doubt on", "to state or declare confidently", "to completely reject", "to measure precisely"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Impartial",
              contextSentence: "A judge must remain impartial throughout the proceedings.",
              options: ["strongly in favor of one side", "lacking any clear opinion", "treating all sides fairly and without bias", "personally involved in the case"],
              correctIndex: 2, category: .social),

    VocabWord(word: "Scrutiny",
              contextSentence: "The new CEO's business decisions came under intense scrutiny from the board.",
              options: ["public celebration and praise", "close and critical examination", "official government regulation", "financial support and investment"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Vindicate",
              contextSentence: "The DNA evidence ultimately vindicated the man who had been wrongly convicted.",
              options: ["to formally sentence someone", "to clear someone of blame or suspicion", "to punish more severely", "to publicly shame"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Undermine",
              contextSentence: "Constant criticism from the coach began to undermine the player's self-confidence.",
              options: ["to strongly support and build up", "to weaken or damage gradually", "to formally train", "to publicly praise"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Polarize",
              contextSentence: "The controversial decision polarized the nation, with strong opinions on both sides.",
              options: ["to unite people around a single cause", "to divide into opposing groups", "to calmly resolve a dispute", "to measure temperature extremes"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Innovative",
              contextSentence: "The startup's innovative approach to delivery logistics disrupted the entire industry.",
              options: ["adhering strictly to tradition", "introducing new ideas or methods", "well-established and proven", "overly complex"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Archaic",
              contextSentence: "Many of the archaic laws on the books had not been enforced in over a century.",
              options: ["extremely modern and current", "strictly enforced", "very old and no longer in use", "foreign in origin"],
              correctIndex: 2, category: .social),

    VocabWord(word: "Scrutinize",
              contextSentence: "The committee carefully scrutinized every line of the proposed budget.",
              options: ["to approve without review", "to casually glance over", "to examine in minute detail", "to publicly debate"],
              correctIndex: 2, category: .scientific),

    VocabWord(word: "Conjecture",
              contextSentence: "Without more data, any explanation for the crater's origin remained pure conjecture.",
              options: ["a proven scientific conclusion", "an opinion formed without firm evidence", "a formal scientific law", "a historical record"],
              correctIndex: 1, category: .scientific),

    VocabWord(word: "Lucid",
              contextSentence: "His explanation of the complex theory was surprisingly lucid and easy to follow.",
              options: ["confusing and difficult", "expressed clearly; easy to understand", "technical and specialized", "poetic and metaphorical"],
              correctIndex: 1, category: .academic),

    VocabWord(word: "Meticulous",
              contextSentence: "The restorer was meticulous, spending weeks on a single square foot of the painting.",
              options: ["careless and hasty", "showing great attention to detail", "creatively inspired", "working at great speed"],
              correctIndex: 1, category: .academic),

    VocabWord(word: "Ambiguous",
              contextSentence: "The survey question was so ambiguous that respondents answered it in completely different ways.",
              options: ["perfectly clear and direct", "long and complicated", "open to multiple interpretations", "intentionally misleading"],
              correctIndex: 2, category: .academic),

    VocabWord(word: "Paradox",
              contextSentence: "It is a paradox that the more choices people have, the less satisfied they often feel.",
              options: ["a logical proof with a clear answer", "a statement that seems contradictory but may be true", "a common misunderstanding", "a type of mathematical equation"],
              correctIndex: 1, category: .literary),

    VocabWord(word: "Aesthetic",
              contextSentence: "The museum curator selected pieces based on their aesthetic value as well as historical significance.",
              options: ["related to moral values", "concerned with beauty and artistic quality", "based on scientific accuracy", "focused on economic value"],
              correctIndex: 1, category: .literary),

    VocabWord(word: "Disdain",
              contextSentence: "She looked at the tabloid magazine with barely concealed disdain.",
              options: ["curiosity and interest", "deep respect", "a feeling of scorn or contempt", "nostalgia and longing"],
              correctIndex: 2, category: .social),

    VocabWord(word: "Prudent",
              contextSentence: "It seemed prudent to save money before making any major purchases.",
              options: ["risky and impulsive", "acting with careful good judgment", "overly cautious to the point of inaction", "financially irresponsible"],
              correctIndex: 1, category: .academic),

    VocabWord(word: "Inquisitive",
              contextSentence: "The inquisitive child never stopped asking 'why.'",
              options: ["shy and withdrawn", "eager to know or learn", "easily distracted", "overly critical"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Reluctant",
              contextSentence: "He was reluctant to admit his mistake in front of the whole team.",
              options: ["eager and enthusiastic", "unwilling and hesitant", "publicly embarrassed", "legally required"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Autonomy",
              contextSentence: "Teenagers naturally crave more autonomy as they grow older.",
              options: ["dependence on others for decisions", "self-governance and independence", "conflict with authority", "public recognition"],
              correctIndex: 1, category: .social),

    VocabWord(word: "Alleviate",
              contextSentence: "The medication was prescribed to alleviate the patient's chronic pain.",
              options: ["to cure permanently", "to make pain or a problem less severe", "to diagnose accurately", "to ignore a symptom"],
              correctIndex: 1, category: .scientific),

    VocabWord(word: "Profound",
              contextSentence: "The experience of fatherhood had a profound effect on his worldview.",
              options: ["insignificant and passing", "very great in depth or intensity", "easily explained", "short-lived"],
              correctIndex: 1, category: .literary),

    VocabWord(word: "Skeptical",
              contextSentence: "Scientists were initially skeptical of the new treatment, calling for more rigorous trials.",
              options: ["fully supportive and enthusiastic", "having doubts; not easily convinced", "thoroughly informed", "emotionally opposed"],
              correctIndex: 1, category: .scientific),

    VocabWord(word: "Concede",
              contextSentence: "The debater was forced to concede one of her weaker points when pressed.",
              options: ["to argue more forcefully than before", "to admit reluctantly that something is true", "to ask for more evidence", "to change the subject"],
              correctIndex: 1, category: .academic),

    VocabWord(word: "Ponder",
              contextSentence: "She sat quietly to ponder the difficult decision before her.",
              options: ["to act immediately without reflection", "to discuss openly with a group", "to think carefully about something", "to research in a library"],
              correctIndex: 2, category: .academic),
]

// MARK: - Conversion to Questions

extension VocabWord {
    /// Converts a VocabWord into a standard Question for use with the existing QuizView.
    func toQuestion() -> Question {
        // Use a stable UUID derived from the word so bookmarks persist across sessions.
        let stableId = UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", abs(word.hashValue) % 999_999_999_999))") ?? UUID()

        return Question(
            id: stableId,
            text: "As used in the following sentence, the word \"\(word)\" most nearly means:\n\n\"\(contextSentence)\"",
            options: options,
            correctIndex: correctIndex,
            explanation: "The correct answer is \"\(options[correctIndex])\".\n\nIn this context, \"\(word)\" means: \(options[correctIndex]).",
            subject: .ebrw,
            topic: "SAT Vocabulary",
            difficulty: .medium,
            isAIGenerated: false,
            aiTopicCategory: "vocab"
        )
    }
}

// MARK: - Category filter

extension Array where Element == VocabWord {
    func byCategory(_ category: VocabCategory) -> [VocabWord] {
        filter { $0.category == category }
    }
}
