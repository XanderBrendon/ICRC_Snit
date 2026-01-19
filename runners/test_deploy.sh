#!/bin/bash
# SNIT Test Deployment Script
# Tests SNIT-specific functionality: Dave registration, minting, purchases, principal linking

set -ex

# Create test identities
dfx identity new admin --storage-mode=plaintext || true
dfx identity new dave1 --storage-mode=plaintext || true
dfx identity new alice --storage-mode=plaintext || true
dfx identity new bob --storage-mode=plaintext || true

# Get principals
dfx identity use admin
ADMIN_PRINCIPAL=$(dfx identity get-principal)

dfx identity use dave1
DAVE1_PRINCIPAL=$(dfx identity get-principal)

dfx identity use alice
ALICE_PRINCIPAL=$(dfx identity get-principal)

dfx identity use bob
BOB_PRINCIPAL=$(dfx identity get-principal)

# Deploy as admin
dfx identity use admin

dfx deploy snit --argument "(opt record {icrc1 = opt record {
  name = opt \"SNIT Token\";
  symbol = opt \"SNIT\";
  logo = opt \"data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMSIgaGVpZ2h0PSIxIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxyZWN0IHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIGZpbGw9IiM0QTkwRDkiLz48L3N2Zz4=\";
  decimals = 8;
  fee = opt variant { Fixed = 0};
  minting_account = opt record{
    owner = principal \"$ADMIN_PRINCIPAL\";
    subaccount = null;
  };
  max_supply = null;
  min_burn_amount = opt 1;
  max_memo = opt 64;
  advanced_settings = null;
  metadata = null;
  fee_collector = null;
  transaction_window = null;
  permitted_drift = null;
  max_accounts = opt 100000000;
  settle_to_accounts = opt 99999000;
};
icrc2 = opt record{
  max_approvals_per_account = opt 10000;
  max_allowance = opt variant { TotalSupply = null};
  fee = opt variant { ICRC1 = null};
  advanced_settings = null;
  max_approvals = opt 10000000;
  settle_to_approvals = opt 9990000;
};
icrc3 = opt record {
  maxActiveRecords = 3000;
  settleToRecords = 2000;
  maxRecordsInArchiveInstance = 100000000;
  maxArchivePages = 62500;
  archiveIndexType = variant {Stable = null};
  maxRecordsToArchive = 8000;
  archiveCycles = 20_000_000_000_000;
  supportedBlocks = vec {};
  archiveControllers = null;
};
icrc4 = opt record {
  max_balances = opt 200;
  max_transfers = opt 200;
  fee = opt variant { ICRC1 = null};
};})" --mode reinstall

SNIT_CANISTER=$(dfx canister id snit)
echo "SNIT Canister: $SNIT_CANISTER"

# Initialize
dfx canister call snit admin_init

echo "=== Test 1: ICRC1 Basic Queries ==="
dfx canister call snit icrc1_name --query
dfx canister call snit icrc1_symbol --query
dfx canister call snit icrc1_decimals --query
dfx canister call snit icrc1_fee --query

echo "=== Test 2: Dave Registration Flow ==="
# Dave1 registers
dfx identity use dave1
dfx canister call snit dave_register "(\"TestDave\", opt \"A test Dave partner app\")"

# Check pending status
dfx canister call snit snit_dave_profile "(principal \"$DAVE1_PRINCIPAL\")" --query

# Admin approves
dfx identity use admin
dfx canister call snit admin_approve_dave "(principal \"$DAVE1_PRINCIPAL\")"

# Verify active status
dfx canister call snit snit_dave_profile "(principal \"$DAVE1_PRINCIPAL\")" --query
dfx canister call snit snit_all_daves --query
dfx canister call snit snit_active_daves --query

echo "=== Test 3: SNIT Minting ==="
# Dave1 mints to Alice
dfx identity use dave1
dfx canister call snit snit_mint "(principal \"$ALICE_PRINCIPAL\")"

# Check Alice's balance
dfx canister call snit snit_balance "(principal \"$ALICE_PRINCIPAL\")" --query
dfx canister call snit snit_user_profile "(principal \"$ALICE_PRINCIPAL\")" --query

# Check affinity
dfx canister call snit snit_affinity "(principal \"$ALICE_PRINCIPAL\", principal \"$DAVE1_PRINCIPAL\")" --query

# Mint again to see XP accumulation
dfx canister call snit snit_mint "(principal \"$ALICE_PRINCIPAL\")"
dfx canister call snit snit_user_profile "(principal \"$ALICE_PRINCIPAL\")" --query

echo "=== Test 4: SNIT Purchase (Burn) ==="
dfx identity use alice
ALICE_BALANCE=$(dfx canister call snit snit_balance "(principal \"$ALICE_PRINCIPAL\")" --query)
echo "Alice balance before purchase: $ALICE_BALANCE"

# Alice purchases content from Dave1 (burns 50000000 = 0.5 SNIT)
dfx canister call snit snit_purchase "(record { dave = principal \"$DAVE1_PRINCIPAL\"; amount = 50000000; content_id = null })"

# Check updated balances
dfx canister call snit snit_balance "(principal \"$ALICE_PRINCIPAL\")" --query
dfx canister call snit snit_user_profile "(principal \"$ALICE_PRINCIPAL\")" --query

echo "=== Test 5: Principal Linking ==="
# Bob requests to link to Alice
dfx identity use bob
dfx canister call snit request_link "(principal \"$ALICE_PRINCIPAL\")"

# Alice confirms the link
dfx identity use alice
dfx canister call snit confirm_link "(principal \"$BOB_PRINCIPAL\")"

# Check linked principals
dfx canister call snit snit_linked_principals "(principal \"$ALICE_PRINCIPAL\")" --query
dfx canister call snit snit_resolve_bag "(principal \"$BOB_PRINCIPAL\")" --query

# Now Dave1 mints to Bob - should accumulate in Alice's bag
dfx identity use dave1
dfx canister call snit snit_mint "(principal \"$BOB_PRINCIPAL\")"

# Check that Alice's total balance increased
dfx canister call snit snit_balance "(principal \"$ALICE_PRINCIPAL\")" --query

echo "=== Test 6: Non-Transferability (expect failures) ==="
dfx identity use alice

# Attempt user-to-user transfer - should fail
echo "Attempting blocked transfer (should fail)..."
dfx canister call snit icrc1_transfer "(record {
  memo = null;
  created_at_time = null;
  amount = 10000000;
  from_subaccount = null;
  to = record {
    owner = principal \"$BOB_PRINCIPAL\";
    subaccount = null;
  };
  fee = null
})" || echo "Transfer correctly blocked!"

# Attempt approve - should fail
echo "Attempting blocked approve (should fail)..."
dfx canister call snit icrc2_approve "(record {
  memo = null;
  created_at_time = null;
  amount = 10000000;
  from_subaccount = null;
  expected_allowance = null;
  expires_at = null;
  spender = record {
    owner = principal \"$BOB_PRINCIPAL\";
    subaccount = null;
  };
  fee = null
})" || echo "Approve correctly blocked!"

echo "=== Test 7: ICRC3 Transaction History ==="
dfx canister call snit icrc3_get_blocks "(vec {record { start = 0; length = 100}})" --query
dfx canister call snit icrc3_get_archives "(record {from = null})" --query

echo "=== All SNIT Tests Complete ==="
