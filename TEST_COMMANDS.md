# SNIT Canister Test Commands

This file contains `dfx canister call` commands to test the full API surface of the SNIT canister.

## Prerequisites

```bash
# Start local replica
dfx start --clean --background

# Deploy canister
dfx deploy snit

# Initialize canister (required after deployment)
dfx canister call snit admin_init
```

## Test Principals

```bash
# Get your identity principal
dfx identity get-principal

# Create test identities
dfx identity new alice --storage-mode=plaintext
dfx identity new bob --storage-mode=plaintext
dfx identity new dave_app --storage-mode=plaintext

# Get test principals (save these for use in commands below)
dfx identity use alice && dfx identity get-principal
dfx identity use bob && dfx identity get-principal
dfx identity use dave_app && dfx identity get-principal

# Return to default identity
dfx identity use default
```

---

## 1. ICRC1 Standard Functions

### Token Metadata

```bash
# Get token name
dfx canister call snit icrc1_name

# Get token symbol
dfx canister call snit icrc1_symbol

# Get decimals
dfx canister call snit icrc1_decimals

# Get fee
dfx canister call snit icrc1_fee

# Get all metadata
dfx canister call snit icrc1_metadata

# Get minting account
dfx canister call snit icrc1_minting_account

# Get total supply
dfx canister call snit icrc1_total_supply

# Get supported standards
dfx canister call snit icrc1_supported_standards
```

### Balance Queries

```bash
# Check balance of a principal (replace with actual principal)
dfx canister call snit icrc1_balance_of '(record { owner = principal "aaaaa-aa"; subaccount = null })'

# Check balance using your current identity
dfx canister call snit icrc1_balance_of "(record { owner = principal \"$(dfx identity get-principal)\"; subaccount = null })"
```

### Transfer (Will fail - non-transferable)

```bash
# Attempt transfer (should fail with "SNIT tokens are non-transferable")
dfx canister call snit icrc1_transfer '(record {
  to = record { owner = principal "aaaaa-aa"; subaccount = null };
  amount = 100;
  fee = null;
  memo = null;
  from_subaccount = null;
  created_at_time = null
})'
```

---

## 2. ICRC2 Standard Functions (Approvals - Blocked)

### Allowance Query

```bash
# Check allowance
dfx canister call snit icrc2_allowance '(record {
  account = record { owner = principal "aaaaa-aa"; subaccount = null };
  spender = record { owner = principal "aaaaa-aa"; subaccount = null }
})'
```

### Approve (Will fail - non-transferable)

```bash
# Attempt approve (should fail)
dfx canister call snit icrc2_approve '(record {
  spender = record { owner = principal "aaaaa-aa"; subaccount = null };
  amount = 1000;
  fee = null;
  memo = null;
  from_subaccount = null;
  created_at_time = null;
  expected_allowance = null;
  expires_at = null
})'
```

### Transfer From (Will fail - non-transferable)

```bash
# Attempt transfer_from (should fail)
dfx canister call snit icrc2_transfer_from '(record {
  from = record { owner = principal "aaaaa-aa"; subaccount = null };
  to = record { owner = principal "aaaaa-aa"; subaccount = null };
  amount = 100;
  fee = null;
  memo = null;
  spender_subaccount = null;
  created_at_time = null
})'
```

---

## 3. ICRC3 Standard Functions (Transaction Log)

```bash
# Get blocks (transaction history)
dfx canister call snit icrc3_get_blocks '(vec { record { start = 0; length = 10 } })'

# Get archives
dfx canister call snit icrc3_get_archives '(record { from = null })'

# Get tip certificate
dfx canister call snit icrc3_get_tip_certificate

# Get supported block types
dfx canister call snit icrc3_supported_block_types

# Get current tip
dfx canister call snit get_tip
```

---

## 4. ICRC4 Standard Functions (Batch Operations - Blocked)

```bash
# Get batch limits
dfx canister call snit icrc4_maximum_update_batch_size
dfx canister call snit icrc4_maximum_query_batch_size

# Batch balance query
dfx canister call snit icrc4_balance_of_batch '(vec {
  record { owner = principal "aaaaa-aa"; subaccount = null }
})'

# Batch transfer (will fail - non-transferable)
dfx canister call snit icrc4_transfer_batch '(vec {
  record {
    to = record { owner = principal "aaaaa-aa"; subaccount = null };
    amount = 100;
    fee = null;
    memo = null;
    from_subaccount = null;
    created_at_time = null
  }
})'
```

---

## 5. ICRC10 Standard

```bash
# Get supported standards (same as icrc1_supported_standards)
dfx canister call snit icrc10_supported_standards
```

---

## 6. Dave (Partner App) Management

### Register as Dave

```bash
# Register current identity as a Dave
dfx canister call snit dave_register '("My App Name", opt "Description of my awesome app")'

# Register without description
dfx canister call snit dave_register '("Another App", null)'
```

### Admin: Approve Dave

```bash
# Approve a pending Dave (admin only - use default/owner identity)
# Replace DAVE_PRINCIPAL with actual principal
dfx canister call snit admin_approve_dave '(principal "DAVE_PRINCIPAL")'
```

### Admin: Manage Dave Status

```bash
# Suspend a Dave
dfx canister call snit admin_suspend_dave '(principal "DAVE_PRINCIPAL")'

# Revoke a Dave
dfx canister call snit admin_revoke_dave '(principal "DAVE_PRINCIPAL")'
```

### Query Daves

```bash
# Get specific Dave profile
dfx canister call snit snit_dave_profile '(principal "DAVE_PRINCIPAL")'

# Get all Daves
dfx canister call snit snit_all_daves

# Get only active Daves
dfx canister call snit snit_active_daves

# Get only pending Daves
dfx canister call snit snit_pending_daves
```

---

## 7. Principal Linking (BagOfSnit)

### Request Link

```bash
# Request to link current principal to a primary principal
# (Run as secondary/alice identity wanting to link to primary/default)
dfx identity use alice
dfx canister call snit request_link '(principal "PRIMARY_PRINCIPAL")'
```

### Confirm Link

```bash
# Confirm a link request (run as primary)
dfx identity use default
dfx canister call snit confirm_link '(principal "SECONDARY_PRINCIPAL")'
```

### Remove Link

```bash
# Remove a linked principal (run as primary)
dfx canister call snit remove_link '(principal "SECONDARY_PRINCIPAL")'
```

### Query Links

```bash
# Get all principals linked to a primary
dfx canister call snit snit_linked_principals '(principal "PRIMARY_PRINCIPAL")'

# Resolve any principal to its BagOfSnit primary
dfx canister call snit snit_resolve_bag '(principal "ANY_PRINCIPAL")'
```

---

## 8. SNIT Minting (Dave Operations)

### Mint SNIT to User

```bash
# Mint SNIT to a user (must be called as an approved Dave)
dfx identity use dave_app
dfx canister call snit snit_mint '(principal "USER_PRINCIPAL")'
```

### Preview Mint Amount

```bash
# Preview how much would be minted (query - no identity requirement)
dfx canister call snit snit_preview_mint '(principal "USER_PRINCIPAL", principal "DAVE_PRINCIPAL")'
```

---

## 9. SNIT Purchasing (Burn) & Snitdust

### Purchase Content (Burn SNIT, Earn Snitdust)

When a user burns SNIT via `snit_purchase`, they earn Snitdust credits (1:1 ratio) with that Dave. The Dave can then consume dust when granting content.

```bash
# Purchase/burn SNIT (earns Snitdust 1:1)
dfx canister call snit snit_purchase '(record {
  dave = principal "DAVE_PRINCIPAL";
  amount = 100
})'
```

### Query Snitdust Balance

```bash
# Query dust balance for any user-dave pair (public)
dfx canister call snit snit_dust_balance '(principal "USER_PRINCIPAL", principal "DAVE_PRINCIPAL")'

# Dave queries their user's dust balance (caller must be the Dave)
dfx identity use dave_app
dfx canister call snit snit_my_dust '(principal "USER_PRINCIPAL")'
```

### Consume Snitdust (Dave Operation)

```bash
# Dave consumes dust when granting content (returns remaining dust balance)
dfx identity use dave_app
dfx canister call snit snit_consume_dust '(principal "USER_PRINCIPAL", 100)'
```

---

## 10. User Queries

```bash
# Get SNIT balance (resolves linked principals automatically)
dfx canister call snit snit_balance '(principal "USER_PRINCIPAL")'

# Get user profile (level, XP, totals)
dfx canister call snit snit_user_profile '(principal "USER_PRINCIPAL")'

# Get all affinities for a user
dfx canister call snit snit_user_affinities '(principal "USER_PRINCIPAL")'

# Get specific user-dave affinity
dfx canister call snit snit_affinity '(principal "USER_PRINCIPAL", principal "DAVE_PRINCIPAL")'
```

---

## 11. Level Configuration

```bash
# Get current level config
dfx canister call snit snit_level_config

# Update level config (admin only)
dfx canister call snit admin_update_level_config '(record {
  base_mint_amount = 100_000_000;
  user_level_multiplier = 110;
  dave_level_multiplier = 105;
  affinity_multiplier = 102;
  xp_per_mint = 10;
  xp_per_burn = 15;
  xp_per_level = 100;
  multiplier_scale = 100
})'
```

---

## 12. Admin Functions

### Direct Mint (Admin Only)

```bash
# Admin direct mint
dfx canister call snit mint '(record {
  to = record { owner = principal "USER_PRINCIPAL"; subaccount = null };
  amount = 1000000;
  memo = null;
  created_at_time = null
})'
```

### Direct Burn

```bash
# Burn tokens (caller burns their own)
dfx canister call snit burn '(record {
  amount = 1000;
  memo = null;
  from_subaccount = null;
  created_at_time = null
})'
```

### Grant XP (Admin Only)

```bash
# Grant XP to user (admin only)
dfx canister call snit admin_grant_xp '(principal "USER_PRINCIPAL", 500)'
```

### Update Owner (Admin Only)

```bash
# Transfer ownership (admin only - be careful!)
dfx canister call snit admin_update_owner '(principal "NEW_OWNER_PRINCIPAL")'
```

### Deposit Cycles

```bash
# Deposit cycles to canister
dfx canister call snit deposit_cycles
```

---

## Full Integration Test Script

```bash
#!/bin/bash
set -e

echo "=== SNIT Integration Test ==="

# Setup
dfx identity use default
OWNER=$(dfx identity get-principal)
echo "Owner: $OWNER"

# Create test identities
dfx identity new test_dave --storage-mode=plaintext 2>/dev/null || true
dfx identity new test_user --storage-mode=plaintext 2>/dev/null || true

dfx identity use test_dave
DAVE=$(dfx identity get-principal)
echo "Dave: $DAVE"

dfx identity use test_user
USER=$(dfx identity get-principal)
echo "User: $USER"

# Switch to owner
dfx identity use default

echo ""
echo "=== Token Info ==="
dfx canister call snit icrc1_name
dfx canister call snit icrc1_symbol
dfx canister call snit icrc1_decimals
dfx canister call snit icrc1_total_supply

echo ""
echo "=== Register Dave ==="
dfx identity use test_dave
dfx canister call snit dave_register '("Test App", opt "A test partner app")'

echo ""
echo "=== Check Pending Daves ==="
dfx canister call snit snit_pending_daves

echo ""
echo "=== Approve Dave ==="
dfx identity use default
dfx canister call snit admin_approve_dave "(principal \"$DAVE\")"

echo ""
echo "=== Check Active Daves ==="
dfx canister call snit snit_active_daves

echo ""
echo "=== Mint SNIT to User ==="
dfx identity use test_dave
dfx canister call snit snit_mint "(principal \"$USER\")"

echo ""
echo "=== Check User Balance ==="
dfx canister call snit snit_balance "(principal \"$USER\")"

echo ""
echo "=== Check User Profile ==="
dfx canister call snit snit_user_profile "(principal \"$USER\")"

echo ""
echo "=== Check Affinity ==="
dfx canister call snit snit_affinity "(principal \"$USER\", principal \"$DAVE\")"

echo ""
echo "=== User Purchase (Burns SNIT, Earns Dust) ==="
dfx identity use test_user
dfx canister call snit snit_purchase "(record { dave = principal \"$DAVE\"; amount = 50_000_000 })"

echo ""
echo "=== Check Updated Balance ==="
dfx canister call snit snit_balance "(principal \"$USER\")"

echo ""
echo "=== Check Updated Profile ==="
dfx canister call snit snit_user_profile "(principal \"$USER\")"

echo ""
echo "=== Check Snitdust Balance ==="
dfx canister call snit snit_dust_balance "(principal \"$USER\", principal \"$DAVE\")"

echo ""
echo "=== Dave Checks User Dust ==="
dfx identity use test_dave
dfx canister call snit snit_my_dust "(principal \"$USER\")"

echo ""
echo "=== Dave Consumes Dust ==="
dfx canister call snit snit_consume_dust "(principal \"$USER\", 25_000_000)"

echo ""
echo "=== Check Remaining Dust ==="
dfx canister call snit snit_my_dust "(principal \"$USER\")"

echo ""
echo "=== Test Transfer Blocking ==="
dfx identity use test_user
dfx canister call snit icrc1_transfer "(record { to = record { owner = principal \"$OWNER\"; subaccount = null }; amount = 100; fee = null; memo = null; from_subaccount = null; created_at_time = null })" || echo "Transfer correctly blocked!"

echo ""
echo "=== Transaction History ==="
dfx canister call snit icrc3_get_blocks '(vec { record { start = 0; length = 100 } })'

echo ""
echo "=== Test Complete ==="
dfx identity use default
```

---

## Notes

- Replace `DAVE_PRINCIPAL`, `USER_PRINCIPAL`, `PRIMARY_PRINCIPAL`, `SECONDARY_PRINCIPAL` with actual principal IDs
- Most SNIT operations require specific roles (admin, approved Dave, etc.)
- Transfers are intentionally blocked - SNIT is non-transferable
- Use `dfx identity use <name>` to switch between test identities
- The canister owner is the identity that deployed the canister
