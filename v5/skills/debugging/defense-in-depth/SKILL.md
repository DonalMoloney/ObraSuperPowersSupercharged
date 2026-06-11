---
name: defense-in-depth
description: Layer validation across system boundaries to make bugs structurally impossible rather than just harder
when_to_use: when designing resilience, preventing data corruption, or hardening against cascading failures
version: 1.1.0
---

# Defense-in-Depth

## Overview

One layer of validation breaks and the bug escapes. Layer validation across every boundary the data crosses.

**Core principle:** Make bugs impossible, not just harder to cause.

## The Pattern

Data flows through your system. At each boundary, validate it.

```
Entry Point (validate input shape)
  ↓
Business Logic (validate invariants)
  ↓
Persistence (validate state)
  ↓
System Boundary (validate exit)
```

Each layer catches different categories of failure:

| Layer | Catches |
|-------|---------|
| **Entry** | Invalid shapes, types, ranges (user input) |
| **Business** | Invariant violations, state inconsistencies |
| **Persistence** | Corruption, partial writes, concurrency issues |
| **Exit** | Data loss, transformation errors, encoding problems |

## Example: User Balance

**Without defense-in-depth:**
```typescript
// Only one check — if it fails, balance goes negative
async function withdraw(userId, amount) {
  const balance = await db.getBalance(userId);
  if (balance >= amount) {
    await db.updateBalance(userId, balance - amount);
  }
}
```

Breaks when:
- Race condition: two withdrawals read same balance
- Database corruption: balance already negative
- Concurrent update: balance changes mid-operation

**With defense-in-depth:**
```typescript
async function withdraw(userId, amount) {
  // Layer 1: Input validation
  if (!Number.isInteger(amount) || amount <= 0) throw new Error('Invalid amount');
  
  // Layer 2: Business logic validation
  const balance = await db.getBalance(userId);
  if (balance < amount) throw new Error('Insufficient funds');
  
  // Layer 3: Database constraint (UNIQUE, CHECK)
  // Prevents negative balance even if app logic fails
  const result = await db.execute(
    'UPDATE users SET balance = balance - ? WHERE id = ? AND balance >= ?',
    [amount, userId, amount]
  );
  
  // Layer 4: Confirmation validation
  const newBalance = await db.getBalance(userId);
  if (newBalance < 0) throw new Error('Invariant violated!');
}
```

Now the bug has to cross 4 layers to escape. Much harder.

## When to Use

**Red flags you need this:**
- "It shouldn't happen but it does"
- Race conditions keep surprising you
- Data corruption incidents
- Cascading failures (one bug triggers others)
- You're storing safety-critical data (money, health, legal)

## The Four Layers

### Layer 1: Entry Point
**Validate input shape and range**

```typescript
// TypeScript helps here
function process(input: { id: string; count: number }) {
  if (count < 0) throw new Error('Count must be positive');
}
```

### Layer 2: Business Logic
**Assert invariants are maintained**

```typescript
class Account {
  withdraw(amount: number) {
    // Before: account state is valid
    console.assert(this.balance >= 0);
    
    this.balance -= amount;
    
    // After: account state is still valid
    console.assert(this.balance >= 0);
  }
}
```

### Layer 3: Persistence
**Database constraints prevent bad state**

```sql
-- Even if app fails, database won't allow:
CREATE TABLE accounts (
  id UUID PRIMARY KEY,
  balance DECIMAL(18,2) CHECK (balance >= 0)
);
```

### Layer 4: Exit
**Validate before returning to caller**

```typescript
const result = await db.withdraw(userId, amount);
console.assert(result.newBalance >= 0);
return result;
```

## Remember

- Single layer of validation = false confidence
- Four layers = bugs have to be catastrophic to escape
- Each layer catches different failure modes
- Database constraints are your friend
- Assertions + type systems + business logic + DB constraints = defense-in-depth
