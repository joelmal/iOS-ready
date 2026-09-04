# ADR-0003: The Xcode project is a thin shell

- **Status:** accepted
- **Date:** 2026-09-04
- **Deciders:** project owner (master plan LD-18)

## Context

`project.pbxproj` is a large, order-sensitive, effectively machine-generated file. It
conflicts badly, and an automated agent adding files to it is a reliable way to
produce a corrupt or unmergeable project — a failure that costs far more time than the
work it interrupts.

## Decision

The `.xcodeproj` stays minimal and rarely changes. All real code lives in local Swift
packages or in Xcode file-system-synchronized folders, so adding, moving or removing a
source file requires **no** project-file edit.

## Consequences

**Easier:** ordinary development never touches the pbxproj. Merge conflicts in it
become rare enough to handle by hand when they do occur.

**Harder:** target-level configuration (capabilities, Info.plist keys, build settings)
still requires opening Xcode, so those changes cluster into Tier-A sessions.

**Accepted cost:** a small amount of indirection between the app target and its code.

## Alternatives considered

- **XcodeGen / Tuist** (generate the project from a manifest). Genuinely solves the
  problem and adds a dependency plus a generation step to every clone and CI run. Held
  in reserve: if pbxproj churn becomes painful anyway, this is the next move.
- **Committing the pbxproj and just being careful.** Not a strategy an autonomous
  agent can be trusted to follow across hundreds of commits.

## Revisit when

pbxproj conflicts happen more than about twice, or the app grows enough targets that
manual configuration becomes the bottleneck. Then adopt XcodeGen.
