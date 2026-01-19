# SNIT - Non-Transferable Engagement Token

## Overview

SNIT is a non-transferable engagement token for freemium content on the Internet Computer. It implements ICRC-1, ICRC-2, ICRC-3, and ICRC-4 standards while enforcing non-transferability between users. Only approved "Daves" (partner apps) can mint SNIT tokens to users, and users can only burn SNIT through purchases from Daves.

## Key Features

- **Non-Transferable**: User-to-user transfers are blocked. SNIT can only be minted by Daves and burned through purchases.
- **Dave System**: Partner applications ("Daves") register and get approved to mint tokens. Daves track their own level and stats.
- **Principal Linking (BagOfSnit)**: Users can link multiple principals together, sharing a unified balance across devices/wallets.
- **Level/XP System**: Users earn experience through minting and burning, progressing through levels that affect mint multipliers.
- **Affinity Tracking**: User-Dave relationships are tracked with their own level and experience.

## Contents

- `src/Snit.mo` - Main SNIT token implementation
- `src/SnitTypes.mo` - Type definitions for Dave, Affinity, UserLevel, etc.
- `runners/test_deploy.sh` - Local testing script
- `runners/prod_deploy.sh` - Production deployment script

## Setup and Installation

1. **Environment Setup**: Install the [DFINITY Internet Computer SDK](https://internetcomputer.org/docs/current/references/cli-reference/dfx-parent) and [mops](https://docs.mops.one/quick-start).

2. **Install Dependencies**:
   ```bash
   mops install
   ```

3. **Build**:
   ```bash
   dfx build snit
   ```

4. **Deploy** (local):
   ```bash
   dfx deploy snit --argument "(opt record {...})"
   dfx canister call snit admin_init
   ```

## Core Operations

### Dave Management
- `dave_register(name, description)` - Register as a Dave (partner app)
- `admin_approve_dave(principal)` - Admin approves a pending Dave
- `admin_suspend_dave(principal)` / `admin_revoke_dave(principal)` - Manage Dave status
- `snit_dave_profile(principal)` - Query Dave info
- `snit_all_daves()` / `snit_active_daves()` - List Daves

### SNIT Operations
- `snit_mint(user)` - Dave mints SNIT to a user
- `snit_purchase({dave, amount, content_id})` - User burns SNIT for content
- `snit_balance(user)` - Get user's total balance (including linked principals)
- `snit_user_profile(user)` - Get user level and stats
- `snit_affinity(user, dave)` - Get user-dave relationship stats

### Principal Linking
- `request_link(primary)` - Request to link to a primary principal
- `confirm_link(secondary)` - Primary confirms a link request
- `remove_link(secondary)` - Remove a linked principal
- `snit_linked_principals(user)` - List linked principals
- `snit_resolve_bag(principal)` - Resolve principal to its BagOfSnit

### ICRC Standards
Standard ICRC-1, ICRC-2, ICRC-3, and ICRC-4 endpoints are available for queries, but transfers between non-minting accounts will fail.

## Attribution

Forked from [PanIndustrial-Org/ICRC_fungible](https://github.com/PanIndustrial-Org/ICRC_fungible).

## License

MIT License
