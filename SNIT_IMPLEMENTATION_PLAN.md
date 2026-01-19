# SNIT Token Implementation Plan

## Overview

SNIT is a non-transferable token for freemium app content purchases. Users earn SNIT through partner apps (Daves) and burn SNIT to acquire content.

## Key Design Decisions

- **Mint flow**: Dave-initiated (Dave calls `snit_mint(user)`)
- **Identity**: Principal linking system (users link multiple principals to one BagOfSnit)
- **Dave registration**: Self-register with admin approval

---

## File Structure

```
src/
  Snit.mo           # Main SNIT canister (NEW)
  SnitTypes.mo      # Type definitions (NEW - already created)
  Token.mo          # Existing base token (reference)
```

Add to `dfx.json`:
```json
"snit": {
  "main": "src/Snit.mo",
  "type": "motoko",
  "args": "-v --incremental-gc"
}
```

---

## Data Structures

### 1. Dave (Partner App)
```motoko
type DaveStatus = { #Pending; #Active; #Suspended; #Revoked };

type Dave = {
  principal: Principal;
  name: Text;
  description: ?Text;
  registered_at: Nat64;
  approved_at: ?Nat64;
  status: DaveStatus;
  level: Nat;
  total_snit_minted: Nat;
  total_snit_burned: Nat;
};
```

### 2. User Level (Global per user)
```motoko
type UserLevel = {
  level: Nat;
  experience: Nat;
  total_snit_earned: Nat;
  total_snit_spent: Nat;
};
```

### 3. Affinity (User-Dave pairing)
```motoko
type Affinity = {
  level: Nat;
  experience: Nat;
  total_minted: Nat;
  total_burned: Nat;
};
```

### 4. Principal Linking (BagOfSnit)
```motoko
// Maps linked principals to their primary BagOfSnit principal
stable let linked_principals = Map.new<Principal, Principal>();

// Maps primary principal to all linked principals
stable let bag_links = Map.new<Principal, Set.Set<Principal>>();

// Pending link requests (requires verification)
stable let pending_links = Map.new<Principal, Principal>();
```

---

## Core Functions

### Non-Transferability Hook
Block all user-to-user transfers in `can_transfer`:
```motoko
private func can_transfer<system>(...) : Result<...> {
  #err("SNIT tokens are non-transferable")
};
```

### Dave Registration
```motoko
// Dave self-registers (pending approval)
public shared({caller}) func dave_register(name: Text, description: ?Text) : async Result<(), SnitError>;

// Admin approves
public shared({caller}) func admin_approve_dave(principal: Principal) : async Result<(), SnitError>;
```

### Principal Linking
```motoko
// Request to link a secondary principal to primary BagOfSnit
public shared({caller}) func request_link(primary: Principal) : async Result<(), SnitError>;

// Primary confirms the link (called from primary principal)
public shared({caller}) func confirm_link(secondary: Principal) : async Result<(), SnitError>;

// Resolve any principal to its BagOfSnit primary
private func resolve_bag(principal: Principal) : Principal;
```

### Minting (Dave-initiated)
```motoko
public shared({caller}) func snit_mint(user: Principal) : async ICRC1.TransferResult {
  // 1. Verify caller is active Dave
  // 2. Resolve user to BagOfSnit primary
  // 3. Calculate amount from 3 levels
  // 4. Mint to resolved principal
  // 5. Update stats and XP
};
```

### Burning (Purchase)
```motoko
public type PurchaseArgs = {
  dave: Principal;
  amount: Nat;
  content_id: ?Blob;
};

public shared({caller}) func snit_purchase(args: PurchaseArgs) : async ICRC1.TransferResult {
  // 1. Verify Dave is active
  // 2. Burn from caller (must be BagOfSnit primary or linked)
  // 3. Update Dave level, affinity, user stats
};
```

### Level Calculation (Configurable)
```motoko
type LevelConfig = {
  base_mint_amount: Nat;
  user_level_multiplier: Nat;  // Fixed-point (110 = 1.10x)
  dave_level_multiplier: Nat;  // Fixed-point (105 = 1.05x)
  affinity_multiplier: Nat;    // Fixed-point (102 = 1.02x)
  xp_per_mint: Nat;
  xp_per_burn: Nat;
  xp_per_level: Nat;
  multiplier_scale: Nat;       // Typically 100
};

func calculate_mint_amount(user: Principal, dave: Principal) : Nat {
  // base * (user_mult ^ user_level) * (dave_mult ^ dave_level) * (affinity_mult ^ affinity_level)
};
```

---

## Query Functions

```motoko
// User queries
public query func snit_balance(user: Principal) : async Nat;
public query func snit_user_profile(user: Principal) : async ?UserLevel;
public query func snit_user_affinities(user: Principal) : async [(Principal, Affinity)];
public query func snit_linked_principals(primary: Principal) : async [Principal];

// Dave queries
public query func snit_dave_profile(dave: Principal) : async ?DaveInfo;
public query func snit_all_daves() : async [DaveInfo];
public query func snit_active_daves() : async [DaveInfo];

// Utility
public query func snit_preview_mint(user: Principal, dave: Principal) : async Nat;
public query func snit_resolve_bag(principal: Principal) : async Principal;
```

---

## Admin Functions

```motoko
public shared({caller}) func admin_approve_dave(principal: Principal) : async Result<(), SnitError>;
public shared({caller}) func admin_suspend_dave(principal: Principal) : async Result<(), SnitError>;
public shared({caller}) func admin_revoke_dave(principal: Principal) : async Result<(), SnitError>;
public shared({caller}) func admin_update_level_config(config: LevelConfig) : async ();
public shared({caller}) func admin_grant_xp(user: Principal, xp: Nat) : async ();
public shared({caller}) func admin_update_owner(new_owner: Principal) : async ();
```

---

## Implementation Sequence

### Phase 1: Core Structure
1. Create `src/SnitTypes.mo` with type definitions (DONE)
2. Create `src/Snit.mo` scaffolding (copy pattern from Token.mo)
3. Add `can_transfer` hook to block transfers
4. Add canister to `dfx.json`

### Phase 2: Dave System
1. Implement Dave storage (Map)
2. Implement `dave_register` and `admin_approve_dave`
3. Add Dave query functions

### Phase 3: Principal Linking
1. Implement link storage structures
2. Implement `request_link` and `confirm_link`
3. Implement `resolve_bag` helper
4. Add linking query functions

### Phase 4: Level System
1. Implement UserLevel and Affinity storage
2. Implement level-up and XP logic
3. Implement `calculate_mint_amount`
4. Add configurable `LevelConfig`

### Phase 5: Mint/Burn Operations
1. Implement `snit_mint` with level calculations
2. Implement `snit_purchase` with stats updates
3. Register transfer listener for additional tracking

### Phase 6: Testing
1. Update `runners/test_deploy.sh` for SNIT
2. Test Dave registration flow
3. Test principal linking
4. Test mint/burn with level calculations

---

## Key Files to Reference

- `src/Token.mo` - ICRC initialization pattern, lazy class loading
- `src/examples/Allowlist.mo:536-565` - `can_transfer` hook pattern
- `src/examples/Lotto.mo:509-526` - Transfer listener pattern

---

## Verification Steps

1. Deploy locally: `dfx deploy snit`
2. Register a test Dave: call `dave_register`
3. Approve as admin: call `admin_approve_dave`
4. Link a secondary principal: call `request_link` then `confirm_link`
5. Mint SNIT: call `snit_mint` from Dave
6. Verify balance: call `snit_balance`
7. Attempt transfer (should fail): call `icrc1_transfer`
8. Purchase content: call `snit_purchase`
9. Verify level updates: call `snit_user_profile`, `snit_dave_profile`

---

## Files Created

- `src/SnitTypes.mo` - Type definitions (created during planning)
