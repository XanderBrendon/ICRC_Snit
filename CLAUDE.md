# Agent Instructions

## Project Overview

**SNIT** is a non-transferable engagement token for freemium content on the Internet Computer (IC). Users earn SNIT from partner apps ("Daves") and burn it to purchase content.

### Key Concepts
- **Non-transferable**: `can_transfer` hook blocks user-to-user transfers; only mint (by Daves) and burn (via purchase) work
- **Dave**: Partner applications that register, get approved by admin, and can mint SNIT to users
- **BagOfSnit**: Principal linking system - users can link multiple wallets to share one balance
- **Affinity**: User-Dave relationship tracking with separate XP/levels
- **Snitdust**: Credits earned 1:1 when burning SNIT; Daves consume dust when granting content

### Architecture
- `src/Snit.mo` - Main token canister implementing ICRC-1/2/3/4
- `src/SnitTypes.mo` - Type definitions (Dave, Affinity, UserLevel, etc.)
- `bagofsnit/` - Frontend app for principal linking (in development)
- `runners/` - Deployment scripts for test and production

### Build Commands
```bash
dfx build           # Build locally
```
