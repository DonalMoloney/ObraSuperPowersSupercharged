---
name: testing-anti-patterns
description: Recognize common testing mistakes and how to fix them; prevents tests from lying about code quality
when_to_use: when reviewing tests, setting up test infrastructure, or debugging why tests pass but code fails
version: 1.1.0
---

# Testing Anti-Patterns

## Overview

Tests that don't test. Tests that pass when code is broken. Tests that break when you refactor safely.

**Core principle:** Tests should catch real bugs, not give false confidence.

## The Anti-Patterns

### Anti-Pattern 1: Testing Mock Behavior

**❌ Wrong:**
```typescript
// This tests the mock, not the code
const mockService = jest.fn().mockReturnValue({ status: 'ok' });
expect(mockService()).toEqual({ status: 'ok' });
```

**Why it fails:** You're testing that the mock returns what you told it to return. You learn nothing about real behavior.

**✅ Right:**
```typescript
// Test the real service (or a real-like stub)
const result = await realService.getStatus();
expect(result.status).toBe('ok');
```

### Anti-Pattern 2: Test-Only Methods in Production

**❌ Wrong:**
```typescript
class User {
  constructor(id, name) {
    this.id = id;
    this.name = name;
  }
  
  // PRODUCTION CODE JUST FOR TESTS
  setNameForTesting(name) {
    this.name = name;
  }
}

// Test uses it
test('name updates', () => {
  const user = new User(1, 'Alice');
  user.setNameForTesting('Bob'); // This method shouldn't exist
});
```

**Why it fails:** Your production code now has code paths that only exist for tests. They'll never be tested in production.

**✅ Right:**
```typescript
// Use the real API or dependency injection
test('name updates', () => {
  const user = new User(1, 'Alice');
  // Test goes through real update mechanism
  user.update({ name: 'Bob' });
});
```

### Anti-Pattern 3: Mocking Without Understanding

**❌ Wrong:**
```typescript
// You mock DATABASE_QUERY without knowing what it does
jest.mock('database', () => ({
  query: jest.fn().mockReturnValue({ rows: [] })
}));

test('fetches users', async () => {
  expect(await getUsers()).toEqual([]);
});
```

**Why it fails:** Your mock doesn't match real behavior (real query might throw, return null, etc.). Test passes, production fails.

**✅ Right:**
```typescript
// Understand what the real function does first
// Then mock it accurately OR use a test double that behaves like reality
const mockQuery = jest.fn(async (sql) => {
  if (!sql.includes('SELECT')) throw new Error('Invalid SQL');
  return { rows: [] };
});
```

### Anti-Pattern 4: Incomplete Mocks

**❌ Wrong:**
```typescript
const mockUser = {
  name: 'Alice'
  // Missing: id, email, isActive, etc.
};

test('displays user', () => {
  expect(formatUser(mockUser)).toBe('Alice'); // Works with incomplete mock
});
```

**Why it fails:** Production code that accesses `mockUser.email` or `mockUser.isActive` crashes, but your test never tried.

**✅ Right:**
```typescript
const mockUser = {
  id: 1,
  name: 'Alice',
  email: 'alice@example.com',
  isActive: true
  // All required fields
};

test('displays user', () => {
  expect(formatUser(mockUser)).toMatch('Alice');
});
```

### Anti-Pattern 5: Tests as Afterthought

**❌ Wrong:**
```typescript
// Write code, then write minimal tests just to say you tested
function calculateTotal(items) {
  let total = 0;
  items.forEach(item => {
    total += item.price * item.quantity;
  });
  return total;
}

test('calculateTotal', () => {
  const result = calculateTotal([{ price: 10, quantity: 2 }]);
  expect(result).toBe(20); // Only tests happy path
});
```

**Why it fails:** Edge cases (negative prices, missing fields, null items) aren't tested.

**✅ Right:**
```typescript
describe('calculateTotal', () => {
  test('sums prices × quantities', () => {
    expect(calculateTotal([{ price: 10, quantity: 2 }])).toBe(20);
  });
  
  test('handles empty list', () => {
    expect(calculateTotal([])).toBe(0);
  });
  
  test('handles negative prices', () => {
    expect(calculateTotal([{ price: -10, quantity: 1 }])).toBe(-10);
  });
  
  test('handles missing quantity', () => {
    expect(() => calculateTotal([{ price: 10 }])).toThrow();
  });
});
```

## Red Flags

- Test passes but production fails
- Tests all pass, but code breaks in weird ways
- Refactoring always breaks tests (shouldn't!)
- Test coverage is high but bugs still ship
- "We have good test coverage" but you don't believe it

## Remember

- Tests should catch real bugs
- Mock what's external; test what's yours
- Complete mocks; incomplete mocks hide bugs
- Edge cases matter more than happy paths
- If tests don't catch real breakage, they're lying
