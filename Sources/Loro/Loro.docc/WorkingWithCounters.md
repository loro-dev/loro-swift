# Working with Counters

Learn how to use LoroCounter for distributed counting operations.

## Overview

``LoroCounter`` is a CRDT counter that accumulates all applied values across distributed peers. It supports both integer and floating-point numbers, making it ideal for scenarios like vote counts, score tracking, inventory management, or any distributed counting use case.

## Basic Operations

### Creating a Counter

```swift
import Loro

let doc = LoroDoc()
let counter = doc.getCounter(id: "score")
```

### Incrementing

```swift
// Increment by 1
try counter.increment(value: 1)

// Increment by any amount
try counter.increment(value: 10)
try counter.increment(value: 0.5) // Floating point supported
```

### Decrementing

```swift
// Decrement by 1
try counter.decrement(value: 1)

// Decrement by any amount
try counter.decrement(value: 5)
try counter.decrement(value: 2.5)
```

### Reading the Value

```swift
let currentValue = counter.getValue()
print("Current count: \(currentValue)")
```

## How Counters Work

Unlike regular variables, CRDT counters don't suffer from lost updates in distributed systems. When multiple peers increment/decrement concurrently, all operations are preserved:

```swift
let doc1 = LoroDoc()
try doc1.setPeerId(peer: 1)
let counter1 = doc1.getCounter(id: "votes")

let doc2 = LoroDoc()
try doc2.setPeerId(peer: 2)
let counter2 = doc2.getCounter(id: "votes")

// Both peers increment concurrently
try counter1.increment(value: 1)  // +1
try counter2.increment(value: 1)  // +1

// Sync both ways
let _ = try doc2.import(bytes: doc1.export(mode: .snapshot))
let _ = try doc1.import(bytes: doc2.export(mode: .snapshot))

// Both counters now show 2 (both increments preserved)
print(counter1.getValue()) // 2.0
print(counter2.getValue()) // 2.0
```

## Nested Counters

Counters can be nested inside other containers:

```swift
let doc = LoroDoc()
let map = doc.getMap(id: "stats")

// Create a counter inside a map
let viewCount = try map.insertContainer(key: "views", child: LoroCounter())
try viewCount.increment(value: 1)

// Create counters inside a list
let list = doc.getList(id: "scores")
let score1 = try list.insertContainer(pos: 0, child: LoroCounter())
try score1.increment(value: 100)
```

## Subscribing to Changes

```swift
let doc = LoroDoc()
let counter = doc.getCounter(id: "observed")

let subscription = counter.subscribe { event in
    print("Counter changed!")
}

try counter.increment(value: 1)
doc.commit() // Triggers callback

subscription?.detach()
```

## Complete Example: Voting System

```swift
import Loro

class VotingSystem {
    let doc: LoroDoc
    let votesMap: LoroMap

    init(peerId: UInt64) throws {
        doc = LoroDoc()
        try doc.setPeerId(peer: peerId)
        votesMap = doc.getMap(id: "votes")
    }

    func upvote(itemId: String) throws {
        let counter = try votesMap.getOrCreateContainer(
            key: itemId,
            child: LoroCounter()
        )
        try counter.increment(value: 1)
    }

    func downvote(itemId: String) throws {
        let counter = try votesMap.getOrCreateContainer(
            key: itemId,
            child: LoroCounter()
        )
        try counter.decrement(value: 1)
    }

    func getVotes(itemId: String) -> Double {
        if let container = votesMap.get(key: itemId)?.asContainer(),
           case .counter(let counter) = container {
            return counter.getValue()
        }
        return 0
    }

    func export() throws -> Data {
        return try doc.export(mode: .snapshot)
    }

    func sync(with data: Data) throws {
        let _ = try doc.import(bytes: data)
    }
}

// Usage
let voting = try VotingSystem(peerId: 1)
try voting.upvote(itemId: "post-123")
try voting.upvote(itemId: "post-123")
try voting.downvote(itemId: "post-456")

print(voting.getVotes(itemId: "post-123")) // 2.0
print(voting.getVotes(itemId: "post-456")) // -1.0
```

## Complete Example: Game Score Tracker

```swift
import Loro

class GameScoreTracker {
    let doc: LoroDoc
    let players: LoroMap

    init() {
        doc = LoroDoc()
        players = doc.getMap(id: "players")
    }

    func addPlayer(name: String) throws {
        let playerMap = try players.insertContainer(key: name, child: LoroMap())
        let _ = try playerMap.insertContainer(key: "score", child: LoroCounter())
        let _ = try playerMap.insertContainer(key: "kills", child: LoroCounter())
        let _ = try playerMap.insertContainer(key: "deaths", child: LoroCounter())
    }

    func addScore(player: String, points: Double) throws {
        if let container = players.get(key: player)?.asContainer(),
           case .map(let playerMap) = container,
           let scoreContainer = playerMap.get(key: "score")?.asContainer(),
           case .counter(let score) = scoreContainer {
            try score.increment(value: points)
        }
    }

    func recordKill(player: String) throws {
        if let container = players.get(key: player)?.asContainer(),
           case .map(let playerMap) = container,
           let killsContainer = playerMap.get(key: "kills")?.asContainer(),
           case .counter(let kills) = killsContainer {
            try kills.increment(value: 1)
        }
    }

    func getStats(player: String) -> (score: Double, kills: Double, deaths: Double)? {
        guard let container = players.get(key: player)?.asContainer(),
              case .map(let playerMap) = container else {
            return nil
        }

        var score = 0.0
        var kills = 0.0
        var deaths = 0.0

        if let c = playerMap.get(key: "score")?.asContainer(),
           case .counter(let counter) = c {
            score = counter.getValue()
        }
        if let c = playerMap.get(key: "kills")?.asContainer(),
           case .counter(let counter) = c {
            kills = counter.getValue()
        }
        if let c = playerMap.get(key: "deaths")?.asContainer(),
           case .counter(let counter) = c {
            deaths = counter.getValue()
        }

        return (score, kills, deaths)
    }
}
```

## Topics

### Counter Type

- ``LoroCounter``
