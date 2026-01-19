# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an ICRC fungible token implementation for the Internet Computer (IC) platform, written in Motoko. It implements ICRC-1, ICRC-2, ICRC-3, ICRC-4, and ICRC-10 token standards.

## Build and Deploy Commands

**Prerequisites:** DFINITY SDK (dfx) and mops package manager must be installed.

```bash
# Install dependencies
mops install

# Build canisters locally
dfx build

# Build and check for IC mainnet
dfx build --network ic token --check

# Deploy to local replica
dfx deploy token --argument "(opt record { ... })"

# Initialize after deployment (required)
dfx canister call token admin_init

# Run test deployment script (creates test identities and exercises all features)
./runners/test_deploy.sh

# Production deployment (requires configuration)
./runners/prod_deploy.sh
```

## Architecture

### Canister Definitions (dfx.json)

- **token**: Development build with verbose output (`-v --incremental-gc`)
- **prodtoken**: Production build with gzip and release optimization (`--incremental-gc --release`)
- **allowlist**: Example token with sender restrictions
- **lotto**: Example token with burn lottery mechanics
- **sns**: SNS-compatible token matching Rust SNS ledger interface

### Core Source Files

- `src/Token.mo` - Main token implementation combining all ICRC standards
- `src/snstest.mo` - SNS ledger-compatible implementation for DeFi testing
- `src/sns_types.mo` - SNS-specific type definitions
- `src/examples/Allowlist.mo` - Demonstrates authorization hook pattern (restricts senders to allowlist)
- `src/examples/Lotto.mo` - Demonstrates transfer listener pattern (50% chance to double burned tokens)

### Initialization Pattern

The token uses `ClassPlus.ClassPlusInitializationManager` for state management. Each ICRC standard maintains its own migration state:

```motoko
stable let icrc1_migration_state = ICRC1.init(...)
stable let icrc2_migration_state = ICRC2.init(...)
stable let icrc3_migration_state = ICRC3.initialState()
stable let icrc4_migration_state = ICRC4.init(...)
```

ICRC classes are lazily initialized via private cache variables (`_icrc1`, `_icrc2`, etc.) with getter functions.

### Integration Between Standards

- ICRC1 environment includes `add_ledger_transaction = ?icrc3().add_record` to automatically log transactions
- ICRC2 and ICRC4 environments reference `icrc1()` for fee inheritance
- Certified data store (`CertTree`) provides ICRC3 transaction certification

## Key Deployment Parameters

Token initialization requires configuration for each standard:

**ICRC1**: name, symbol, logo, decimals, fee, minting_account, max_supply, min_burn_amount, max_memo, max_accounts, settle_to_accounts

**ICRC2**: max_approvals_per_account, max_allowance, fee (Fixed or ICRC1), max_approvals, settle_to_approvals

**ICRC3**: maxActiveRecords, settleToRecords, maxRecordsInArchiveInstance, maxArchivePages, archiveCycles (minimum 20T), archiveIndexType

**ICRC4**: max_balances, max_transfers, fee

## Extending the Token

To create custom token behavior:

1. Override `can_transfer` in ICRC1 environment for transfer authorization (see Allowlist.mo)
2. Register transfer listeners via `icrc1().register_token_transferred_listener()` for post-transfer actions (see Lotto.mo)
3. Override `can_approve` in ICRC2 environment for approval authorization

## Dependencies

Uses mops packages: `icrc1-mo`, `icrc2-mo`, `icrc3-mo`, `icrc4-mo`, `ic-certification`, `class-plus`

Toolchain requires moc 0.14.14
