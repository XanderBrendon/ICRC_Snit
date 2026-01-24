# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

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
mops install              # Install dependencies
dfx build snit           # Build locally
dfx deploy snit          # Deploy to local replica
dfx canister call snit admin_init  # Initialize after deploy
```

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

