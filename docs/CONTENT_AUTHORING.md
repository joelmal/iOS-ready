# Content authoring

Authoritative source: `IOS_READY_MASTER_PLAN.md` Sections 19 and 9.

Content is the product's core value, not filler. A question with a precise
`expectedConcepts` list and a real `modelAnswerOutline` is worth ten vague ones,
because those fields are what make both grading paths work.

## Where things live

```
Content/competencies/<category>.json     the registry — the join key for everything
Content/questions/<category>/*.json      explain / scenario / debug-reasoning questions
Content/behavioral/*.json                behavioral bank (M2)
Content/lessons/<competencyId>.md        refreshers, 300–800 words
Content/challenges/snippets/*.json       on-device coding challenges (M3)
Content/challenges/projects/<id>/        Xcode starter projects (M3)
Content/missions/*.json                  guided app curriculum (M4)
Content/interviews/*.json                mock interview templates (M2)
Content/schemas/*.json                   schemas for all of the above
```

Validate with `make validate-content` after every change.

## Why `expectedConcepts` and `misconceptions` are mandatory

They are not documentation. They are the grading anchor:

- The **heuristic grader** matches the user's answer against each concept's `synonyms`
  to compute completeness, and against `misconceptions` to subtract for wrong claims.
  This is what makes the whole product work offline, for free, with no credentials.
- The **AI grader** is told to map `missingPoints` onto these concept IDs, which stops
  grading from drifting with model mood and makes it auditable.

A question without them fails validation. Write the synonym list as the words a
*correct but differently-phrased* answer would actually use.

## Writing good questions

- Prefer questions that force a **decision** over questions that ask for a definition.
  "When would you use `unowned` instead of `weak`, and what breaks if you're wrong?"
  beats "What is `unowned`?"
- Ask the messy ones interviewers actually ask, including "what happens if I do this?"
  over a code block.
- Every category needs some difficulty-3 questions, or the user plateaus.
- Include questions whose honest answer is "it depends, and here is what on" —
  interviews are full of them and candidates handle them badly.
- Cover **what changed while the user was away**: modern Swift concurrency, current
  SwiftUI observation and navigation, Swift 6 data-race safety, modern testing. This is
  higher priority than material that has not changed.
- `targetAnswerWords` should reflect a good *spoken* answer, not an essay.
- `sourceNotes` is for you; it is never shown to the user.

## Worked example

`Content/questions/concurrency/actors.json` and `Content/lessons/concurrency.actors.md`
were written as the reference template. Match their depth — particularly the way the
lesson's "crisp 60-second answer" section gives the user something directly usable in
a real interview, and the way `misconceptions` carry a severity.

## Coverage thresholds

Enforced by the validator per milestone (master plan 19.5). Summary:

| By | Requirement |
|---|---|
| M1 | ≥150 questions, all competencies defined, every importance-5 competency has ≥1 question, no category <8 |
| M2 | ≥60 behavioral, ≥3 interview templates, ≥12 resume archetypes |
| M3 | ≥60 snippet challenges (≥15 per kind), ≥3 project challenges |
| M4 | ≥260 questions, every core competency has a lesson + ≥2 questions + ≥1 implement/debug task |
| M5 | ≥350 questions, core competencies at ≥2 difficulty levels |
| M6 | ≥500 questions, ≥100 snippets, ≥8 projects |
