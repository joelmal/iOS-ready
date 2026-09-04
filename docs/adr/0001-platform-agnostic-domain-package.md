# ADR-0001: Domain logic lives in a platform-agnostic Swift package

- **Status:** accepted
- **Date:** 2026-09-04
- **Deciders:** project owner (master plan LD-13, §17.1)

## Context

The obvious shape for this product is a SwiftUI app with its logic inside the app
target. But much of the development is done by a coding agent, and agents frequently
run in environments with no Xcode — CI containers, Linux boxes, web sessions. An
agent that cannot build or test what it writes is guessing, and guessing compounds.

Separately, this product's value is concentrated in logic that has nothing to do with
UIKit or SwiftUI: evidence weighting, readiness projection, session generation, spaced
repetition, content validation, AI response parsing, resume parsing, xcresult parsing.

## Decision

All domain logic lives in `Packages/IOSReadyKit`, a Swift package with **no Apple-UI
dependencies**, buildable and testable with `swift build` / `swift test` on macOS and
Linux. The iOS app target is a thin SwiftUI shell over it. The Mac runner links the
same package.

Enforcing rule: **a type that could be tested without a simulator must not live in the
app target.** Business logic in an app-target file is a defect.

## Consequences

**Easier:** ~80% of the product is verifiable without a Mac. The inner test loop is
seconds rather than minutes. The runner and the app cannot drift apart, because they
share model definitions. The app that teaches architecture and testability
demonstrates them.

**Harder:** some genuinely platform-flavoured logic (speech metrics, PDF extraction)
needs a protocol in the package and an implementation in the app, which is a little
more ceremony than calling the framework directly.

**Accepted cost:** a strict dependency rule that must be enforced by a test
(M0-R18), because it will otherwise erode one convenient import at a time.

## Alternatives considered

- **Everything in the app target.** Simplest to start; makes autonomous development
  nearly unverifiable and slows every test run. Rejected.
- **Multiple separate packages from day one.** More ceremony than a solo project
  needs at M0. The single package has internal modules and can be split later.

## Revisit when

Build times for the single package exceed roughly a minute, or a genuine need appears
to version parts of it independently.
