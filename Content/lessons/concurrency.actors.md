---
competencyId: concurrency.actors
title: Actors and actor isolation
contentVersion: 0.1.0
estimatedMinutes: 6
relatedQuestionIds:
  - q.concurrency.actors.001
  - q.concurrency.actors.002
updatedAt: 2026-09-04
---

## What is this?

An `actor` is a reference type that protects its own mutable state. Only one task
may execute actor-isolated code at a time, and the compiler enforces that outside
code cannot touch isolated state synchronously.

```swift
actor ImageCache {
    private var storage: [URL: Data] = [:]

    func data(for url: URL) -> Data? { storage[url] }
    func store(_ data: Data, for url: URL) { storage[url] = data }
}

let cache = ImageCache()
let cached = await cache.data(for: url)   // await: crossing into the actor
```

## Why does it matter in production?

Shared mutable state reached from concurrent tasks is the source of the worst
bugs in a mobile codebase: intermittent, unreproducible, and usually discovered
in crash logs. Before actors you protected that state with a serial queue or a
lock and hoped every future contributor remembered. An actor moves the guarantee
from discipline to the compiler.

## What does an interviewer actually ask?

- "What problem do actors solve?"
- "How is an actor different from a serial `DispatchQueue`?"
- "What is actor reentrancy?"
- "You have a cache that fetches on miss — what goes wrong under concurrency?"

## The crisp 60-second answer

> Actors protect shared mutable state. The state is isolated to the actor and only
> one task runs actor-isolated code at a time, so you cannot get a data race on it.
> Unlike a lock, that is enforced at compile time — outside code physically cannot
> reach the state synchronously, which is why access from outside is `await`. The
> important subtlety is that actors are *reentrant*: an `await` inside an actor
> method is a suspension point, so other work can run on the actor in the gap.
> Actor methods are not atomic.

## Common mistakes

- **Describing an actor as a lock.** A lock blocks the calling thread; an actor
  suspends the calling *task* and frees the thread. Saying "it blocks" reads as a
  concurrency-model misunderstanding, and interviewers notice.
- **Assuming atomicity across `await`.** This is the single most common real bug.
- **Actor-ing everything.** Wrapping every type in an actor adds hops and
  contention. Isolate the shared mutable state, not the whole object graph.
- **Reaching for `Task.detached`** to escape isolation, then being surprised by
  warnings and lost context.

## What must I be able to explain?

Isolation, why cross-actor access is async, reentrancy, the difference from a
serial queue, and when an actor is the wrong tool (state that is not shared, or
state that is already main-actor bound).

## What must I be able to implement?

An actor-backed cache with correct in-flight deduplication:

```swift
actor ImageLoader {
    private var cache: [URL: Data] = [:]
    private var inFlight: [URL: Task<Data, Error>] = [:]

    func load(_ url: URL) async throws -> Data {
        if let cached = cache[url] { return cached }
        if let running = inFlight[url] { return try await running.value }

        let task = Task { try await URLSession.shared.data(from: url).0 }
        inFlight[url] = task
        defer { inFlight[url] = nil }

        let data = try await task.value
        cache[url] = data
        return data
    }
}
```

The naive version — check the cache, `await` a fetch, then write — issues N
requests for N concurrent callers, because every one of them saw an empty cache
before the first `await` resumed.

## What must I be able to debug or review?

Spot check-then-act sequences spanning an `await`. In review, the question to ask
of any actor method containing `await` is: *what did I assume before this line
that might no longer hold after it?*

## Tradeoffs

Actor hops are not free, and a single hot actor becomes a contention point.
Prefer value types and structured concurrency where they suffice; reach for an
actor when there is genuinely shared mutable state with concurrent access.

## Related

`concurrency.asyncawait` (prerequisite) · `concurrency.mainactor` ·
`concurrency.sendable` · `concurrency.dataraces`
