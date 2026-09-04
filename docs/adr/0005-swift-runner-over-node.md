# ADR-0005: The Mac challenge runner is written in Swift

- **Status:** accepted
- **Date:** 2026-09-04
- **Deciders:** project owner (master plan LD-17)

## Context

The runner builds and tests submitted Xcode projects on the Mac and returns structured
results to the phone. The original plan allowed "Node/TypeScript for speed, or Swift".
Both can shell out to `xcodebuild` and serve HTTP.

The deciding question is not language ergonomics; it is **where the result types live**.
The runner's output becomes evidence records consumed by the scoring engine. If the
runner defines those types independently, they will drift from the app's definitions,
and the drift will show up as silently mis-scored submissions.

## Decision

The runner is a Swift SPM executable that links `IOSReadyRunnerAPI` from
`Packages/IOSReadyKit`, sharing the request and result types with the app.

## Consequences

**Easier:** one toolchain, one set of model definitions, no serialization drift. The
runner's parsers are testable from the same `swift test` invocation, and its
fixture-based parser tests run on Linux.

**Harder:** slightly more ceremony than a quick Node script for the HTTP layer.

**Accepted cost:** writing a small HTTP service in Swift without a web framework.

## Alternatives considered

- **Node/TypeScript.** Faster to stand up an HTTP server; guarantees a second copy of
  every shared type. Rejected on drift risk.
- **A pure CLI with no HTTP.** Considered, and the CLI mode is kept — but the phone
  needs to submit and poll without the user retyping paths, so the service earns its keep.

## Revisit when

The HTTP layer in Swift becomes a genuine time sink, at which point reconsider — but
keep the shared result types regardless.
