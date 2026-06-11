---
name: condition-based-waiting
description: Replace arbitrary timeouts with condition polling for reliable async tests; fixes flaky tests with race conditions
when_to_use: when tests are flaky due to timing, you're using sleep(N), or waiting for events that may arrive at unpredictable times
version: 1.1.0
---

# Condition-Based Waiting

## Overview

Tests fail inconsistently? Stop using `sleep(N)`. Poll for the actual condition you care about.

**Core principle:** Wait for the condition to be true, not for arbitrary time to pass.

## The problem with sleep()

```typescript
// ❌ Flaky — might fail if the event takes >100ms
test('event arrives', async () => {
  service.startAsync();
  await sleep(100);
  expect(eventCollector.count).toBe(1);
});
```

The test passes when the service is fast and fails when it's slow. The actual requirement is "wait until the event arrives", not "wait 100ms".

## The solution: condition polling

```typescript
// ✅ Reliable — waits until the event actually arrives (or timeout)
test('event arrives', async () => {
  service.startAsync();
  await waitForEventCount(eventCollector, 1, { timeout: 5000 });
  expect(eventCollector.count).toBe(1);
});
```

Poll for the real condition. Timeout if it doesn't arrive within reason.

## Common patterns

### Pattern 1: Wait for event type

```typescript
await waitForEvent(collector, 'user:created', { timeout: 5000 });
```

### Pattern 2: Wait for N events

```typescript
await waitForEventCount(collector, 5, { timeout: 10000 });
```

### Pattern 3: Wait for custom predicate

```typescript
await waitForEventMatch(collector, (event) => event.payload.status === 'ready', {
  timeout: 5000,
});
```

## When to use

**Use condition-based waiting when:**
- Test uses `sleep(N)` anywhere
- Test is flaky (passes sometimes, fails other times)
- Waiting for an event, state change, or async operation to complete
- Timeout is important (service might be down, not just slow)

**Don't use when:**
- You genuinely need to test that something does NOT happen (use short timeout + assert absence)
- You're testing timing itself (e.g., "operation takes < 100ms")

## Benefits

- **Reliable:** Tests pass when the behavior works, fail when it doesn't (never timing-dependent)
- **Fast:** No arbitrary waits; runs as fast as the system can deliver
- **Clear intent:** Code says what you're actually waiting for, not how long
- **Debuggable:** If it times out, you know the condition didn't arrive (not "I guessed wrong on the timeout")

## Real-world impact

From a real test suite (2025-10-03):
- Before: 47% pass rate (flaky)
- Added condition-based waiting
- After: 100% pass rate (stable across runs)
- Bonus: Tests run ~2s faster (no arbitrary sleep calls)

## Implementation

The exact utility functions depend on your framework, but the concept is universal:

1. **Start polling** — check condition every Xms
2. **Timeout** — if condition doesn't arrive within T seconds, fail with clear message
3. **Return** — when condition is true, continue test immediately

## Remember

- `sleep()` = test is flaky
- Condition polling = test is reliable
- Name what you're waiting for, not how long you're waiting
