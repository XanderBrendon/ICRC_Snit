#!/bin/bash
# SNIT Production Deployment Script
# Deploys and configures the SNIT canister on the Internet Computer mainnet.
# Ensure you have dfx (the DFINITY Canister SDK) installed and configured before running this script.

# Exit immediately if a command exits with a non-zero status, and print each command.
set -ex

# --- Configuration Section ---

# Identity configuration. Replace '{production_identity}' with your production identity name.
# This identity needs to be a controller for your canister.
PRODUCTION_IDENTITY="{production_identity}"
dfx identity use $PRODUCTION_IDENTITY

# Canister identification - You need to create this canister either via dfx or through the NNS console
PRODUCTION_CANISTER="{production_canister}"

# Check your cycles. The system needs at least 2x the archiveCycles below to create the archive canister.
# We suggest funding the initial canister with 4x the cycles configured in archiveCycles and then
# using a tool like CycleOps to monitor your cycles. You will need to add the created archive
# canisters (created after the first maxActiveRecords are created) to CycleOps manually for monitoring.

# Token configuration
TOKEN_NAME="SNIT Token"
TOKEN_SYMBOL="SNIT"
TOKEN_LOGO="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMSIgaGVpZ2h0PSIxIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxyZWN0IHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIGZpbGw9IiM0QTkwRDkiLz48L3N2Zz4="
TOKEN_DECIMALS=8
TOKEN_FEE=0  # SNIT is fee-free
MAX_SUPPLY=null
MIN_BURN_AMOUNT=1
MAX_MEMO=64
MAX_ACCOUNTS=100000000
SETTLE_TO_ACCOUNTS=99999000

# Automatically fetches the principal ID of the currently used identity.
ADMIN_PRINCIPAL=$(dfx identity get-principal)

# --- Deployment Section ---

dfx build --network ic prodsnit --check

# Deploy the canister with the specified configuration.
dfx canister --network ic install --mode install --wasm .dfx/ic/canisters/prodsnit/prodsnit.wasm.gz --argument "(opt record {icrc1 = opt record {
  name = opt \"$TOKEN_NAME\";
  symbol = opt \"$TOKEN_SYMBOL\";
  logo = opt \"$TOKEN_LOGO\";
  decimals = $TOKEN_DECIMALS;
  fee = opt variant { Fixed = $TOKEN_FEE};
  minting_account = opt record{
    owner = principal \"$ADMIN_PRINCIPAL\";
    subaccount = null;
  };
  max_supply = $MAX_SUPPLY;
  min_burn_amount = opt $MIN_BURN_AMOUNT;
  max_memo = opt $MAX_MEMO;
  advanced_settings = null;
  metadata = null;
  fee_collector = null;
  transaction_window = null;
  permitted_drift = null;
  max_accounts = opt $MAX_ACCOUNTS;
  settle_to_accounts = opt $SETTLE_TO_ACCOUNTS;
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
};})" $PRODUCTION_CANISTER

# Fetch the canister ID after deployment
SNIT_CANISTER=$(dfx canister --network ic id snit)

# Output the canister ID
echo "SNIT Canister ID: $SNIT_CANISTER"

# --- Initialization and Query Section ---

# Initialize the admin configuration of the SNIT canister
dfx canister --network ic call snit admin_init

# Fetch and display various token details
dfx canister --network ic call snit icrc1_name --query
dfx canister --network ic call snit icrc1_symbol --query
dfx canister --network ic call snit icrc1_decimals --query
dfx canister --network ic call snit icrc1_fee --query
dfx canister --network ic call snit icrc1_metadata --query

echo "SNIT deployment complete!"
