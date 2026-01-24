# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Workflow Preferences

- Use `bd` (beads) for task tracking

## Project Overview

SNIT is a non-transferable engagement token for freemium content on the Internet Computer (IC) platform, written in Motoko. It implements ICRC-1, ICRC-2, ICRC-3, and ICRC-4 token standards while enforcing non-transferability between regular users. Only approved "Daves" (partner apps) can mint tokens, and users can only burn tokens through purchases.

Key concepts:
- **Dave**: Partner applications that register and get approved to mint SNIT to users
- **BagOfSnit**: Principal linking system allowing users to share balance across wallets
- **Affinity**: User-Dave relationship tracking with separate XP/levels
- **Non-transferability**: `can_transfer` hook blocks user-to-user transfers

## Build and Deploy Commands

**Prerequisites:** DFINITY SDK (dfx) and mops package manager must be installed.

```bash
# Install dependencies
mops install

# Build canisters locally
dfx build snit

# Build and check for IC mainnet
dfx build --network ic prodsnit --check

# Deploy to local replica
dfx deploy snit --argument "(opt record { ... })"

# Initialize after deployment (required)
dfx canister call snit admin_init

# Run test deployment script
./runners/test_deploy.sh

# Production deployment (requires configuration)
./runners/prod_deploy.sh
```

## Architecture

### Canister Definitions (dfx.json)

- **snit**: Development build with verbose output (`-v --incremental-gc`)
- **prodsnit**: Production build with gzip and release optimization (`--incremental-gc --release`)

### Core Source Files

- `src/Snit.mo` - Main SNIT token implementation with Dave system and non-transferability
- `src/SnitTypes.mo` - Type definitions for Dave, Affinity, UserLevel, PurchaseArgs, etc.

### Initialization Pattern

The token uses `ClassPlus.ClassPlusInitializationManager` for state management. Each ICRC standard maintains its own migration state:

```motoko
stable let icrc1_migration_state = ICRC1.init(...)
stable let icrc2_migration_state = ICRC2.init(...)
stable let icrc3_migration_state = ICRC3.initialState()
stable let icrc4_migration_state = ICRC4.init(...)
```

SNIT-specific state includes:
```motoko
stable var daves: [(Principal, SnitTypes.Dave)] = []
stable var user_levels: [(Principal, SnitTypes.UserLevel)] = []
stable var affinities: [(Principal, [(Principal, SnitTypes.Affinity)])] = []
stable var bag_of_snit: [(Principal, [Principal])] = []  // Primary -> linked principals
stable var principal_to_bag: [(Principal, Principal)] = []  // Secondary -> primary
stable var link_requests: [(Principal, Principal)] = []  // Secondary -> requested primary
```

### Non-Transferability

The `can_transfer` hook in the ICRC1 environment blocks transfers where:
- Sender is not the minting account (admin/Dave mint operations)
- Receiver is not the minting account (burn operations via snit_purchase)

This allows minting and burning while preventing user-to-user transfers.

## Key Deployment Parameters

Token initialization requires configuration for each standard:

**ICRC1**: name, symbol, logo, decimals, fee, minting_account, max_supply, min_burn_amount, max_memo, max_accounts, settle_to_accounts

**ICRC2**: max_approvals_per_account, max_allowance, fee (Fixed or ICRC1), max_approvals, settle_to_approvals

**ICRC3**: maxActiveRecords, settleToRecords, maxRecordsInArchiveInstance, maxArchivePages, archiveCycles (minimum 20T), archiveIndexType

**ICRC4**: max_balances, max_transfers, fee

## SNIT-Specific APIs

### Dave Management
- `dave_register(name, description)` - Register as a Dave
- `admin_approve_dave(principal)` - Approve pending Dave
- `admin_suspend_dave(principal)` / `admin_revoke_dave(principal)` - Manage Dave status

### Token Operations
- `snit_mint(user)` - Dave mints calculated amount to user (based on levels/affinity)
- `snit_purchase({dave, amount, content_id})` - User burns SNIT for content from Dave

### Principal Linking
- `request_link(primary)` - Request to link caller to a primary principal
- `confirm_link(secondary)` - Primary confirms link request
- `remove_link(secondary)` - Remove linked principal

### Query Functions
- `snit_balance(user)` - Total balance across linked principals
- `snit_user_profile(user)` - User level and stats
- `snit_affinity(user, dave)` - User-Dave relationship stats
- `snit_dave_profile(principal)` / `snit_all_daves()` / `snit_active_daves()` - Dave queries

## Dependencies

Uses mops packages: `icrc1-mo`, `icrc2-mo`, `icrc3-mo`, `icrc4-mo`, `ic-certification`, `class-plus`

Toolchain requires moc 0.14.14

## Attribution

Forked from [PanIndustrial-Org/ICRC_fungible](https://github.com/PanIndustrial-Org/ICRC_fungible).
