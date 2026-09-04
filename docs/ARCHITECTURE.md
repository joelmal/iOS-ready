# Architecture

Authoritative source: `IOS_READY_MASTER_PLAN.md` Section 17. This file is the
working reference; if they disagree, the plan wins.

## The decision everything rests on

**All domain logic lives in `Packages/IOSReadyKit`, a Swift package with no
UIKit/SwiftUI/Apple-only dependencies, that builds and tests with `swift test` on
macOS and Linux. The iOS app is a thin SwiftUI shell over it.**

Four reasons (ADR-0001):

1. Much development happens without Xcode. If scoring, session generation, content
   loading, spaced repetition, AI response parsing, resume parsing, persistence and
   result parsing are platform-agnostic, ~80% of the product is verifiable anywhere.
2. `swift test` is seconds; a simulator run is minutes.
3. The app that teaches architecture and testability should demonstrate them.
4. The Mac runner reuses the same models, so there is no schema drift.

**The enforcing rule:** a type that could be tested without a simulator must not live
in the app target. Business logic in an app-target file is a defect.

## Module map

```
Packages/IOSReadyKit/Sources/
  IOSReadyDomain/      Models, IDs, enums, protocols. Pure. No first-party imports.
  IOSReadyContent/     Content schemas, loader, validation, queries.
  IOSReadyScoring/     Evidence weighting, projections, readiness, blockers, SR.
  IOSReadyTraining/    Session generation, adaptation, recommendations.
  IOSReadyAI/          AIGateway protocol, request/response types, prompts,
                       Mock + Heuristic gateways, response validation, transports.
  IOSReadyPersistence/ Store protocol, JSONL evidence log, snapshots, export, migrations.
  IOSReadyRunnerAPI/   Shared request/result types for the Mac runner.

App/IOSReady/          SwiftUI views, view models, navigation, speech, PDFKit,
                       Keychain, platform glue. Depends on everything; nothing
                       depends on it.

Runner/                Swift SPM executable: CLI + local HTTP service, xcodebuild
                       orchestration, xcresult parsing, structural checks.
```

## Dependency rules

One-way only:

```
Domain ← Content ← Scoring ← Training
Domain ← AI
Domain ← Persistence
Domain ← RunnerAPI
```

- `IOSReadyDomain` imports **no** first-party module.
- No cycles. A test asserts both (M0-R18).
- The app depends on the package; the package never depends on the app.

## App-layer patterns

- Pragmatic MVVM: one observable view model per screen; views stay declarative.
- Feature-oriented folders (`Features/Dashboard/`), not type-oriented (`ViewModels/`).
- DI through initializers plus a small composition root; environment injection for
  cross-cutting services. **No singletons in view models** — the app must be able to
  run entirely against fakes, and in previews it will.
- Navigation state is data (a path model), so it is testable and deep-linkable.
- Build the second use case before extracting an abstraction, except where the plan
  already mandates a protocol.

## Determinism

`Clock` and `UUIDProvider` are injected everywhere time or identity is used, from the
first commit (M0-R12). This product is scheduling-heavy; retrofitting determinism
later is miserable. Tests use fixed clocks and seeded generators — never `Date()`,
never `sleep`, never real network, never randomness.

## Data flow

```
Content (validated JSON)  →  Session generator  →  Activity
                                                      ↓
                                              graded attempt
                                                      ↓
                                    EVIDENCE LOG (append-only, immutable)
                                                      ↓  pure projection
                          CompetencyState → CategoryState → ReadinessState → Blockers
                                                      ↓
                                              back into the generator
```

Scores are **derived**, never mutated in place (ADR-0002). The whole projection is a
pure function of `(EvidenceLog, CompetencyRegistry, ScoringConstants, now)`.
