/////////////////////
///
/// SNIT Token - Non-transferable token for freemium app content purchases
///
/// Users earn SNIT through partner apps (Daves) and burn SNIT to acquire content.
/// Key features:
/// - Non-transferable (user-to-user transfers blocked)
/// - Dave-initiated minting
/// - Principal linking system (multiple principals -> one BagOfSnit)
/// - Level system with XP for users, Daves, and affinities
///
/////////////////////

import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import CertTree "mo:ic-certification/CertTree";
import ClassPlus "mo:class-plus";

import ICRC1 "mo:icrc1-mo/ICRC1";
import ICRC2 "mo:icrc2-mo/ICRC2";
import ICRC3 "mo:icrc3-mo/";
import ICRC4 "mo:icrc4-mo/ICRC4";

import SnitTypes "./SnitTypes";

shared ({ caller = _owner }) actor class Snit(args: ?{
    icrc1 : ?ICRC1.InitArgs;
    icrc2 : ?ICRC2.InitArgs;
    icrc3 : ICRC3.InitArgs;
    icrc4 : ?ICRC4.InitArgs;
    snit : ?SnitTypes.SnitInitArgs;
  }
) = this {

    let Map = ICRC1.Map;
    let Set = ICRC1.Set;

    D.print("Loading SNIT token state");
    let manager = ClassPlus.ClassPlusInitializationManager(_owner, Principal.fromActor(this), true);

    // ============================================
    // ICRC Default Arguments
    // ============================================

    let default_icrc1_args : ICRC1.InitArgs = {
      name = ?"Snitcoin";
      symbol = ?"SNIT";
      logo = ?"data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMSIgaGVpZ2h0PSIxIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxyZWN0IHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIGZpbGw9IiM0QTkwRDkiLz48L3N2Zz4=";
      decimals = 0;
      fee = ?#Fixed(0); // No fees for SNIT
      minting_account = ?{
        owner = _owner;
        subaccount = null;
      };
      max_supply = null;
      min_burn_amount = ?1;
      max_memo = ?64;
      advanced_settings = null;
      metadata = null;
      fee_collector = null;
      transaction_window = null;
      permitted_drift = null;
      max_accounts = ?100000000;
      settle_to_accounts = ?99999000;
    };

    let default_icrc2_args : ICRC2.InitArgs = {
      max_approvals_per_account = ?10000;
      max_allowance = ?#TotalSupply;
      fee = ?#Fixed(0);
      advanced_settings = null;
      max_approvals = ?10000000;
      settle_to_approvals = ?9990000;
    };

    let default_icrc3_args : ICRC3.InitArgs = {
      maxActiveRecords = 3000;
      settleToRecords = 2000;
      maxRecordsInArchiveInstance = 500_000;
      maxArchivePages = 62500;
      archiveIndexType = #Stable;
      maxRecordsToArchive = 8000;
      archiveCycles = 20_000_000_000_000;
      archiveControllers = null;
      supportedBlocks = [
        { block_type = "1xfer"; url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3" },
        { block_type = "2xfer"; url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3" },
        { block_type = "2approve"; url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3" },
        { block_type = "1mint"; url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3" },
        { block_type = "1burn"; url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3" }
      ];
    };

    let default_icrc4_args : ICRC4.InitArgs = {
      max_balances = ?200;
      max_transfers = ?200;
      fee = ?#Fixed(0);
    };

    // Parse init args
    let icrc1_args : ICRC1.InitArgs = switch(args) {
      case(null) default_icrc1_args;
      case(?args) {
        switch(args.icrc1) {
          case(null) default_icrc1_args;
          case(?val) {
            { val with minting_account = switch(val.minting_account) {
              case(?v) ?v;
              case(null) ?{ owner = _owner; subaccount = null };
            }};
          };
        };
      };
    };

    let icrc2_args : ICRC2.InitArgs = switch(args) {
      case(null) default_icrc2_args;
      case(?args) switch(args.icrc2) { case(null) default_icrc2_args; case(?val) val };
    };

    let icrc3_args : ICRC3.InitArgs = switch(args) {
      case(null) default_icrc3_args;
      case(?args) switch(?args.icrc3) { case(null) default_icrc3_args; case(?val) val };
    };

    let icrc4_args : ICRC4.InitArgs = switch(args) {
      case(null) default_icrc4_args;
      case(?args) switch(args.icrc4) { case(null) default_icrc4_args; case(?val) val };
    };

    // ============================================
    // ICRC Migration States
    // ============================================

    stable let icrc1_migration_state = ICRC1.init(ICRC1.initialState(), #v0_1_0(#id), ?icrc1_args, _owner);
    stable let icrc2_migration_state = ICRC2.init(ICRC2.initialState(), #v0_1_0(#id), ?icrc2_args, _owner);
    stable let icrc4_migration_state = ICRC4.init(ICRC4.initialState(), #v0_1_0(#id), ?icrc4_args, _owner);
    stable let icrc3_migration_state = ICRC3.initialState();
    stable let cert_store : CertTree.Store = CertTree.newStore();
    let ct = CertTree.Ops(cert_store);

    stable var owner = _owner;
    stable var icrc3_migration_state_new = icrc3_migration_state;

    // ============================================
    // SNIT-Specific Stable State
    // ============================================

    // Dave (Partner App) storage
    stable let daves = Map.new<Principal, SnitTypes.Dave>();

    // User levels
    stable let user_levels = Map.new<Principal, SnitTypes.UserLevel>();

    // Affinities (user-dave pairs) - key is "user_principal:dave_principal"
    stable let affinities = Map.new<Text, SnitTypes.Affinity>();

    // Principal linking (maps linked principal -> primary BagOfSnit principal)
    stable let linked_principals = Map.new<Principal, Principal>();

    // Maps primary principal -> set of linked principals
    stable let bag_links = Map.new<Principal, Set.Set<Principal>>();

    // Pending link requests (secondary -> primary)
    stable let pending_links = Map.new<Principal, Principal>();

    // Level configuration
    stable var level_config : SnitTypes.LevelConfig = switch(args) {
      case(null) SnitTypes.defaultLevelConfig();
      case(?a) switch(a.snit) {
        case(null) SnitTypes.defaultLevelConfig();
        case(?s) switch(s.level_config) {
          case(null) SnitTypes.defaultLevelConfig();
          case(?c) c;
        };
      };
    };

    // ============================================
    // ICRC1 Class Setup
    // ============================================

    let #v0_1_0(#data(icrc1_state_current)) = icrc1_migration_state;
    private var _icrc1 : ?ICRC1.ICRC1 = null;

    private func _get_icrc1_state() : ICRC1.CurrentState {
      return icrc1_state_current;
    };

    private func get_icrc1_environment() : ICRC1.Environment {
      {
        get_time = null;
        get_fee = null;
        add_ledger_transaction = ?icrc3().add_record;
      };
    };

    func icrc1() : ICRC1.ICRC1 {
      switch(_icrc1) {
        case(null) {
          let initclass : ICRC1.ICRC1 = ICRC1.ICRC1(?icrc1_migration_state, Principal.fromActor(this), get_icrc1_environment());
          ignore initclass.register_supported_standards({ name = "ICRC-3"; url = "https://github.com/dfinity/ICRC/ICRCs/icrc-3/" });
          ignore initclass.register_supported_standards({ name = "ICRC-10"; url = "https://github.com/dfinity/ICRC/ICRCs/icrc-10/" });
          _icrc1 := ?initclass;
          initclass;
        };
        case(?val) val;
      };
    };

    // ============================================
    // ICRC2 Class Setup
    // ============================================

    let #v0_1_0(#data(icrc2_state_current)) = icrc2_migration_state;
    private var _icrc2 : ?ICRC2.ICRC2 = null;

    private func _get_icrc2_state() : ICRC2.CurrentState {
      return icrc2_state_current;
    };

    private func get_icrc2_environment() : ICRC2.Environment {
      { icrc1 = icrc1(); get_fee = null };
    };

    func icrc2() : ICRC2.ICRC2 {
      switch(_icrc2) {
        case(null) {
          let initclass : ICRC2.ICRC2 = ICRC2.ICRC2(?icrc2_migration_state, Principal.fromActor(this), get_icrc2_environment());
          _icrc2 := ?initclass;
          initclass;
        };
        case(?val) val;
      };
    };

    // ============================================
    // ICRC4 Class Setup
    // ============================================

    let #v0_1_0(#data(icrc4_state_current)) = icrc4_migration_state;
    private var _icrc4 : ?ICRC4.ICRC4 = null;

    private func _get_icrc4_state() : ICRC4.CurrentState {
      return icrc4_state_current;
    };

    private func get_icrc4_environment() : ICRC4.Environment {
      { icrc1 = icrc1(); get_fee = null };
    };

    func icrc4() : ICRC4.ICRC4 {
      switch(_icrc4) {
        case(null) {
          let initclass : ICRC4.ICRC4 = ICRC4.ICRC4(?icrc4_migration_state, Principal.fromActor(this), get_icrc4_environment());
          _icrc4 := ?initclass;
          ignore icrc1().register_supported_standards({ name = "ICRC-4"; url = "https://github.com/dfinity/ICRC/blob/main/ICRCs/ICRC-4" });
          initclass;
        };
        case(?val) val;
      };
    };

    // ============================================
    // ICRC3 Class Setup
    // ============================================

    private func updated_certification(_cert: Blob, _lastIndex: Nat) : Bool {
      ct.setCertifiedData();
      return true;
    };

    private func get_certificate_store() : CertTree.Store {
      return cert_store;
    };

    private func get_icrc3_environment() : ICRC3.Environment {
      {
        updated_certification = ?updated_certification;
        get_certificate_store = ?get_certificate_store;
      };
    };

    func ensure_block_types(icrc3Class: ICRC3.ICRC3) : () {
      let supportedBlocks = Buffer.fromIter<ICRC3.BlockType>(icrc3Class.supported_block_types().vals());
      let blockequal = func(a : {block_type: Text}, b : {block_type: Text}) : Bool { a.block_type == b.block_type };

      for (bt in [
        { block_type = "1xfer"; url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3" },
        { block_type = "2xfer"; url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3" },
        { block_type = "2approve"; url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3" },
        { block_type = "1mint"; url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3" },
        { block_type = "1burn"; url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3" }
      ].vals()) {
        if (Buffer.indexOf<ICRC3.BlockType>(bt, supportedBlocks, blockequal) == null) {
          supportedBlocks.add(bt);
        };
      };
      icrc3Class.update_supported_blocks(Buffer.toArray(supportedBlocks));
    };

    let icrc3 = ICRC3.Init<system>({
      manager = manager;
      initialState = icrc3_migration_state_new;
      args = ?icrc3_args;
      pullEnvironment = ?get_icrc3_environment;
      onInitialize = ?(func(newClass: ICRC3.ICRC3) : async* () {
        ensure_block_types(newClass);
      });
      onStorageChange = func(state: ICRC3.State) {
        icrc3_migration_state_new := state;
      };
    });

    // ============================================
    // Non-Transferability Hook
    // ============================================

    // Block all user-to-user transfers
    private func can_transfer<system>(
      trx: ICRC1.Value,
      trxtop: ?ICRC1.Value,
      notification: ICRC1.TransactionRequestNotification
    ) : Result.Result<(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC1.TransactionRequestNotification), Text> {
      // Allow mints (from minting account) and burns (to minting account)
      let minting_account = icrc1().minting_account();

      // If from minting account -> this is a mint, allow it
      if (notification.from.owner == minting_account.owner) {
        return #ok(trx, trxtop, notification);
      };

      // If to minting account -> this is a burn, allow it
      if (notification.to.owner == minting_account.owner) {
        return #ok(trx, trxtop, notification);
      };

      // Block all other transfers
      #err("SNIT tokens are non-transferable");
    };

    private func can_approve<system>(
      _trx: ICRC2.Value,
      _trxtop: ?ICRC2.Value,
      _notification: ICRC2.TokenApprovalNotification
    ) : Result.Result<(trx: ICRC2.Value, trxtop: ?ICRC2.Value, notification: ICRC2.TokenApprovalNotification), Text> {
      #err("SNIT tokens cannot be approved for transfer");
    };

    private func can_transfer_from<system>(
      _trx: ICRC2.Value,
      _trxtop: ?ICRC2.Value,
      _notification: ICRC2.TransferFromNotification
    ) : Result.Result<(trx: ICRC2.Value, trxtop: ?ICRC2.Value, notification: ICRC2.TransferFromNotification), Text> {
      #err("SNIT tokens are non-transferable");
    };

    private func can_transfer_batch<system>(
      _notification: ICRC4.TransferBatchNotification
    ) : Result.Result<(notification: ICRC4.TransferBatchNotification), ICRC4.TransferBatchResults> {
      #err([?#Err(#GenericBatchError({ message = "SNIT tokens are non-transferable"; error_code = 1 }))]);
    };

    // ============================================
    // Helper Functions
    // ============================================

    // Resolve any principal to its BagOfSnit primary principal
    private func resolve_bag(principal: Principal) : Principal {
      switch (Map.get(linked_principals, Map.phash, principal)) {
        case (?primary) primary;
        case (null) principal; // Not linked, return itself
      };
    };

    // Create affinity key from user and dave principals
    private func affinity_key(user: Principal, dave: Principal) : Text {
      Principal.toText(user) # ":" # Principal.toText(dave);
    };

    // Get or create user level
    private func get_or_create_user_level(user: Principal) : SnitTypes.UserLevel {
      let resolved = resolve_bag(user);
      switch (Map.get(user_levels, Map.phash, resolved)) {
        case (?level) level;
        case (null) {
          let newLevel : SnitTypes.UserLevel = {
            level = 0;
            experience = 0;
            total_snit_earned = 0;
            total_snit_spent = 0;
          };
          ignore Map.put(user_levels, Map.phash, resolved, newLevel);
          newLevel;
        };
      };
    };

    // Get or create affinity
    private func get_or_create_affinity(user: Principal, dave: Principal) : SnitTypes.Affinity {
      let resolved = resolve_bag(user);
      let key = affinity_key(resolved, dave);
      switch (Map.get(affinities, Map.thash, key)) {
        case (?aff) aff;
        case (null) {
          let newAff : SnitTypes.Affinity = {
            level = 0;
            experience = 0;
            total_minted = 0;
            total_burned = 0;
          };
          ignore Map.put(affinities, Map.thash, key, newAff);
          newAff;
        };
      };
    };

    // Calculate level from XP
    private func calculate_level(xp: Nat, xp_per_level: Nat) : Nat {
      if (xp_per_level == 0) return 0;
      xp / xp_per_level;
    };

    // Apply multiplier (fixed-point math)
    private func apply_multiplier(base: Nat, multiplier: Nat, level: Nat, scale: Nat) : Nat {
      if (level == 0) return base;
      var result = base;
      var i = 0;
      while (i < level) {
        result := (result * multiplier) / scale;
        i += 1;
      };
      result;
    };

    // Calculate mint amount based on levels
    private func calculate_mint_amount(user: Principal, dave: Principal) : Nat {
      let resolved = resolve_bag(user);
      let userLevel = get_or_create_user_level(resolved);
      let daveData = switch (Map.get(daves, Map.phash, dave)) {
        case (?d) d;
        case (null) return level_config.base_mint_amount;
      };
      let aff = get_or_create_affinity(resolved, dave);

      var amount = level_config.base_mint_amount;
      amount := apply_multiplier(amount, level_config.user_level_multiplier, userLevel.level, level_config.multiplier_scale);
      amount := apply_multiplier(amount, level_config.dave_level_multiplier, daveData.level, level_config.multiplier_scale);
      amount := apply_multiplier(amount, level_config.affinity_multiplier, aff.level, level_config.multiplier_scale);
      amount;
    };

    // Add XP and update level
    private func add_user_xp(user: Principal, xp: Nat) : () {
      let resolved = resolve_bag(user);
      let current = get_or_create_user_level(resolved);
      let newXp = current.experience + xp;
      let newLevel = calculate_level(newXp, level_config.xp_per_level);
      let updated : SnitTypes.UserLevel = {
        level = newLevel;
        experience = newXp;
        total_snit_earned = current.total_snit_earned;
        total_snit_spent = current.total_snit_spent;
      };
      ignore Map.put(user_levels, Map.phash, resolved, updated);
    };

    private func add_affinity_xp(user: Principal, dave: Principal, xp: Nat) : () {
      let resolved = resolve_bag(user);
      let key = affinity_key(resolved, dave);
      let current = get_or_create_affinity(resolved, dave);
      let newXp = current.experience + xp;
      let newLevel = calculate_level(newXp, level_config.xp_per_level);
      let updated : SnitTypes.Affinity = {
        level = newLevel;
        experience = newXp;
        total_minted = current.total_minted;
        total_burned = current.total_burned;
      };
      ignore Map.put(affinities, Map.thash, key, updated);
    };

    private func add_dave_xp(dave: Principal, xp: Nat) : () {
      switch (Map.get(daves, Map.phash, dave)) {
        case (?d) {
          let newXp = d.level * level_config.xp_per_level + xp; // Reconstruct XP
          let newLevel = calculate_level(newXp, level_config.xp_per_level);
          let updated : SnitTypes.Dave = {
            d with level = newLevel;
          };
          ignore Map.put(daves, Map.phash, dave, updated);
        };
        case (null) {};
      };
    };

    // ============================================
    // Dave Registration Functions
    // ============================================

    public shared({ caller }) func dave_register(name: Text, description: ?Text) : async SnitTypes.SnitResult<()> {
      // Check if already registered
      if (Map.has(daves, Map.phash, caller)) {
        return #err(#DaveAlreadyRegistered);
      };

      let now = Nat64.fromNat(Int.abs(Time.now()));
      let newDave : SnitTypes.Dave = {
        principal = caller;
        name = name;
        description = description;
        registered_at = now;
        approved_at = null;
        status = #Pending;
        level = 0;
        total_snit_minted = 0;
        total_snit_burned = 0;
      };
      ignore Map.put(daves, Map.phash, caller, newDave);
      #ok(());
    };

    public shared({ caller }) func admin_approve_dave(principal: Principal) : async SnitTypes.SnitResult<()> {
      if (caller != owner) { return #err(#NotAuthorized) };

      switch (Map.get(daves, Map.phash, principal)) {
        case (null) { #err(#DaveNotFound) };
        case (?dave) {
          let now = Nat64.fromNat(Int.abs(Time.now()));
          let updated : SnitTypes.Dave = {
            dave with
            status = #Active;
            approved_at = ?now;
          };
          ignore Map.put(daves, Map.phash, principal, updated);
          #ok(());
        };
      };
    };

    public shared({ caller }) func admin_suspend_dave(principal: Principal) : async SnitTypes.SnitResult<()> {
      if (caller != owner) { return #err(#NotAuthorized) };

      switch (Map.get(daves, Map.phash, principal)) {
        case (null) { #err(#DaveNotFound) };
        case (?dave) {
          let updated : SnitTypes.Dave = { dave with status = #Suspended };
          ignore Map.put(daves, Map.phash, principal, updated);
          #ok(());
        };
      };
    };

    public shared({ caller }) func admin_revoke_dave(principal: Principal) : async SnitTypes.SnitResult<()> {
      if (caller != owner) { return #err(#NotAuthorized) };

      switch (Map.get(daves, Map.phash, principal)) {
        case (null) { #err(#DaveNotFound) };
        case (?dave) {
          let updated : SnitTypes.Dave = { dave with status = #Revoked };
          ignore Map.put(daves, Map.phash, principal, updated);
          #ok(());
        };
      };
    };

    // ============================================
    // Principal Linking Functions
    // ============================================

    // Request to link caller (secondary) to a primary principal
    public shared({ caller }) func request_link(primary: Principal) : async SnitTypes.SnitResult<()> {
      // Cannot link to self
      if (caller == primary) {
        return #err(#CannotLinkToSelf);
      };

      // Check if caller is already linked
      if (Map.has(linked_principals, Map.phash, caller)) {
        return #err(#PrincipalAlreadyLinked);
      };

      // Check if primary is itself linked (we want to link to the root)
      let resolvedPrimary = resolve_bag(primary);

      // Store pending request
      ignore Map.put(pending_links, Map.phash, caller, resolvedPrimary);
      #ok(());
    };

    // Primary confirms the link request from secondary
    public shared({ caller }) func confirm_link(secondary: Principal) : async SnitTypes.SnitResult<()> {
      // Check if there's a pending request from secondary to caller
      switch (Map.get(pending_links, Map.phash, secondary)) {
        case (null) { return #err(#LinkRequestNotFound) };
        case (?requestedPrimary) {
          // Verify the request was for this caller (or their resolved bag)
          let resolvedCaller = resolve_bag(caller);
          if (requestedPrimary != resolvedCaller) {
            return #err(#LinkRequestNotFound);
          };

          // Remove pending request
          Map.delete(pending_links, Map.phash, secondary);

          // Add link
          ignore Map.put(linked_principals, Map.phash, secondary, resolvedCaller);

          // Update bag_links set
          let links = switch (Map.get(bag_links, Map.phash, resolvedCaller)) {
            case (?set) set;
            case (null) Set.new<Principal>();
          };
          Set.add(links, Set.phash, secondary);
          ignore Map.put(bag_links, Map.phash, resolvedCaller, links);

          // Merge balances: transfer secondary's balance to primary
          let secondaryAccount : ICRC1.Account = { owner = secondary; subaccount = null };
          let primaryAccount : ICRC1.Account = { owner = resolvedCaller; subaccount = null };
          let secondaryBalance = icrc1().balance_of(secondaryAccount);

          if (secondaryBalance > 0) {
            // Burn from secondary
            let burnResult = await* icrc1().burn_tokens(secondary, {
              from_subaccount = null;
              amount = secondaryBalance;
              memo = ?Text.encodeUtf8("Link merge");
              created_at_time = null;
            }, false);

            // Mint to primary
            switch(burnResult) {
              case (#trappable(#Ok(_))) {
                ignore await* icrc1().mint_tokens(owner, {
                  to = primaryAccount;
                  amount = secondaryBalance;
                  memo = ?Text.encodeUtf8("Link merge");
                  created_at_time = null;
                });
              };
              case (_) {};
            };
          };

          #ok(());
        };
      };
    };

    // Remove a link (called by primary)
    public shared({ caller }) func remove_link(secondary: Principal) : async SnitTypes.SnitResult<()> {
      let resolvedCaller = resolve_bag(caller);

      // Check if secondary is linked to caller
      switch (Map.get(linked_principals, Map.phash, secondary)) {
        case (null) { return #err(#LinkRequestNotFound) };
        case (?primary) {
          if (primary != resolvedCaller) {
            return #err(#NotAuthorized);
          };

          // Remove from linked_principals
          Map.delete(linked_principals, Map.phash, secondary);

          // Remove from bag_links set
          switch (Map.get(bag_links, Map.phash, resolvedCaller)) {
            case (?set) {
              Set.delete(set, Set.phash, secondary);
              ignore Map.put(bag_links, Map.phash, resolvedCaller, set);
            };
            case (null) {};
          };

          #ok(());
        };
      };
    };

    // ============================================
    // SNIT Mint/Purchase Functions
    // ============================================

    // Dave-initiated minting
    public shared({ caller }) func snit_mint(user: Principal) : async ICRC1.TransferResult {
      // Verify caller is an active Dave
      switch (Map.get(daves, Map.phash, caller)) {
        case (null) { return #Err(#GenericError({ message = "Dave not found"; error_code = 1 })) };
        case (?dave) {
          switch (dave.status) {
            case (#Active) {};
            case (#Pending) { return #Err(#GenericError({ message = "Dave pending approval"; error_code = 2 })) };
            case (#Suspended) { return #Err(#GenericError({ message = "Dave suspended"; error_code = 3 })) };
            case (#Revoked) { return #Err(#GenericError({ message = "Dave revoked"; error_code = 4 })) };
          };
        };
      };

      // Resolve user to their BagOfSnit primary
      let resolved = resolve_bag(user);
      let amount = calculate_mint_amount(resolved, caller);

      // Mint tokens
      let result = await* icrc1().mint_tokens(owner, {
        to = { owner = resolved; subaccount = null };
        amount = amount;
        memo = ?Text.encodeUtf8("SNIT mint from " # Principal.toText(caller));
        created_at_time = null;
      });

      switch(result) {
        case (#trappable(#Ok(idx))) {
          // Update stats
          // Update user level
          let userLevel = get_or_create_user_level(resolved);
          let updatedUser : SnitTypes.UserLevel = {
            userLevel with
            total_snit_earned = userLevel.total_snit_earned + amount;
          };
          ignore Map.put(user_levels, Map.phash, resolved, updatedUser);
          add_user_xp(resolved, level_config.xp_per_mint);

          // Update dave stats
          switch (Map.get(daves, Map.phash, caller)) {
            case (?d) {
              let updatedDave : SnitTypes.Dave = {
                d with total_snit_minted = d.total_snit_minted + amount;
              };
              ignore Map.put(daves, Map.phash, caller, updatedDave);
              add_dave_xp(caller, level_config.xp_per_mint);
            };
            case (null) {};
          };

          // Update affinity
          let key = affinity_key(resolved, caller);
          let aff = get_or_create_affinity(resolved, caller);
          let updatedAff : SnitTypes.Affinity = {
            aff with total_minted = aff.total_minted + amount;
          };
          ignore Map.put(affinities, Map.thash, key, updatedAff);
          add_affinity_xp(resolved, caller, level_config.xp_per_mint);

          #Ok(idx);
        };
        case (#trappable(#Err(e))) { #Err(e) };
        case (#awaited(#Ok(idx))) { #Ok(idx) };
        case (#awaited(#Err(e))) { #Err(e) };
        case (#err(#trappable(err))) { #Err(#GenericError({ message = err; error_code = 100 })) };
        case (#err(#awaited(err))) { #Err(#GenericError({ message = err; error_code = 100 })) };
      };
    };

    // Purchase (burn) SNIT
    public shared({ caller }) func snit_purchase(args: SnitTypes.PurchaseArgs) : async ICRC1.TransferResult {
      // Verify Dave is active
      switch (Map.get(daves, Map.phash, args.dave)) {
        case (null) { return #Err(#GenericError({ message = "Dave not found"; error_code = 1 })) };
        case (?dave) {
          switch (dave.status) {
            case (#Active) {};
            case (_) { return #Err(#GenericError({ message = "Dave not active"; error_code = 2 })) };
          };
        };
      };

      if (args.amount == 0) {
        return #Err(#GenericError({ message = "Amount must be greater than 0"; error_code = 5 }));
      };

      // Resolve caller to their BagOfSnit primary
      let resolved = resolve_bag(caller);

      // Check balance
      let balance = icrc1().balance_of({ owner = resolved; subaccount = null });
      if (balance < args.amount) {
        return #Err(#InsufficientFunds({ balance = balance }));
      };

      // Burn tokens (must be called from the resolved principal)
      // If caller is linked, we need to burn from the primary
      let burnResult = await* icrc1().burn_tokens(resolved, {
        from_subaccount = null;
        amount = args.amount;
        memo = switch(args.content_id) {
          case (?id) ?id;
          case (null) ?Text.encodeUtf8("SNIT purchase at " # Principal.toText(args.dave));
        };
        created_at_time = null;
      }, false);

      switch(burnResult) {
        case (#trappable(#Ok(idx))) {
          // Update user stats
          let userLevel = get_or_create_user_level(resolved);
          let updatedUser : SnitTypes.UserLevel = {
            userLevel with
            total_snit_spent = userLevel.total_snit_spent + args.amount;
          };
          ignore Map.put(user_levels, Map.phash, resolved, updatedUser);
          add_user_xp(resolved, level_config.xp_per_burn);

          // Update dave stats
          switch (Map.get(daves, Map.phash, args.dave)) {
            case (?d) {
              let updatedDave : SnitTypes.Dave = {
                d with total_snit_burned = d.total_snit_burned + args.amount;
              };
              ignore Map.put(daves, Map.phash, args.dave, updatedDave);
              add_dave_xp(args.dave, level_config.xp_per_burn);
            };
            case (null) {};
          };

          // Update affinity
          let key = affinity_key(resolved, args.dave);
          let aff = get_or_create_affinity(resolved, args.dave);
          let updatedAff : SnitTypes.Affinity = {
            aff with total_burned = aff.total_burned + args.amount;
          };
          ignore Map.put(affinities, Map.thash, key, updatedAff);
          add_affinity_xp(resolved, args.dave, level_config.xp_per_burn);

          #Ok(idx);
        };
        case (#trappable(#Err(e))) { #Err(e) };
        case (#awaited(#Ok(idx))) { #Ok(idx) };
        case (#awaited(#Err(e))) { #Err(e) };
        case (#err(#trappable(err))) { #Err(#GenericError({ message = err; error_code = 100 })) };
        case (#err(#awaited(err))) { #Err(#GenericError({ message = err; error_code = 100 })) };
      };
    };

    // ============================================
    // Query Functions
    // ============================================

    // User queries
    public query func snit_balance(user: Principal) : async Nat {
      let resolved = resolve_bag(user);
      icrc1().balance_of({ owner = resolved; subaccount = null });
    };

    public query func snit_user_profile(user: Principal) : async ?SnitTypes.UserLevel {
      let resolved = resolve_bag(user);
      Map.get(user_levels, Map.phash, resolved);
    };

    public query func snit_user_affinities(user: Principal) : async [(Principal, SnitTypes.Affinity)] {
      let resolved = resolve_bag(user);
      let prefix = Principal.toText(resolved) # ":";
      let results = Buffer.Buffer<(Principal, SnitTypes.Affinity)>(8);

      for ((key, aff) in Map.entries(affinities)) {
        if (Text.startsWith(key, #text prefix)) {
          // Extract dave principal from key
          let davePrincipalText = Text.trimStart(key, #text prefix);
          // Principal.fromText can trap on invalid input, but since we control
          // key format, it should always be valid
          let davePrincipal = Principal.fromText(davePrincipalText);
          results.add((davePrincipal, aff));
        };
      };
      Buffer.toArray(results);
    };

    public query func snit_affinity(user: Principal, dave: Principal) : async ?SnitTypes.Affinity {
      let resolved = resolve_bag(user);
      let key = affinity_key(resolved, dave);
      Map.get(affinities, Map.thash, key);
    };

    public query func snit_linked_principals(primary: Principal) : async [Principal] {
      let resolved = resolve_bag(primary);
      switch (Map.get(bag_links, Map.phash, resolved)) {
        case (?set) { Iter.toArray(Set.keys(set)) };
        case (null) { [] };
      };
    };

    public query func snit_resolve_bag(principal: Principal) : async Principal {
      resolve_bag(principal);
    };

    // Dave queries
    public query func snit_dave_profile(dave: Principal) : async ?SnitTypes.DaveInfo {
      switch (Map.get(daves, Map.phash, dave)) {
        case (?d) {
          ?{
            principal = d.principal;
            name = d.name;
            description = d.description;
            registered_at = d.registered_at;
            approved_at = d.approved_at;
            status = d.status;
            level = d.level;
            total_snit_minted = d.total_snit_minted;
            total_snit_burned = d.total_snit_burned;
          };
        };
        case (null) null;
      };
    };

    public query func snit_all_daves() : async [SnitTypes.DaveInfo] {
      let results = Buffer.Buffer<SnitTypes.DaveInfo>(8);
      for ((_, d) in Map.entries(daves)) {
        results.add({
          principal = d.principal;
          name = d.name;
          description = d.description;
          registered_at = d.registered_at;
          approved_at = d.approved_at;
          status = d.status;
          level = d.level;
          total_snit_minted = d.total_snit_minted;
          total_snit_burned = d.total_snit_burned;
        });
      };
      Buffer.toArray(results);
    };

    public query func snit_active_daves() : async [SnitTypes.DaveInfo] {
      let results = Buffer.Buffer<SnitTypes.DaveInfo>(8);
      for ((_, d) in Map.entries(daves)) {
        switch (d.status) {
          case (#Active) {
            results.add({
              principal = d.principal;
              name = d.name;
              description = d.description;
              registered_at = d.registered_at;
              approved_at = d.approved_at;
              status = d.status;
              level = d.level;
              total_snit_minted = d.total_snit_minted;
              total_snit_burned = d.total_snit_burned;
            });
          };
          case (_) {};
        };
      };
      Buffer.toArray(results);
    };

    public query func snit_pending_daves() : async [SnitTypes.DaveInfo] {
      let results = Buffer.Buffer<SnitTypes.DaveInfo>(8);
      for ((_, d) in Map.entries(daves)) {
        switch (d.status) {
          case (#Pending) {
            results.add({
              principal = d.principal;
              name = d.name;
              description = d.description;
              registered_at = d.registered_at;
              approved_at = d.approved_at;
              status = d.status;
              level = d.level;
              total_snit_minted = d.total_snit_minted;
              total_snit_burned = d.total_snit_burned;
            });
          };
          case (_) {};
        };
      };
      Buffer.toArray(results);
    };

    // Utility queries
    public query func snit_preview_mint(user: Principal, dave: Principal) : async Nat {
      calculate_mint_amount(user, dave);
    };

    public query func snit_level_config() : async SnitTypes.LevelConfig {
      level_config;
    };

    // ============================================
    // Admin Functions
    // ============================================

    public shared({ caller }) func admin_update_level_config(config: SnitTypes.LevelConfig) : async () {
      if (caller != owner) { D.trap("Unauthorized") };
      level_config := config;
    };

    public shared({ caller }) func admin_grant_xp(user: Principal, xp: Nat) : async () {
      if (caller != owner) { D.trap("Unauthorized") };
      add_user_xp(user, xp);
    };

    public shared({ caller }) func admin_update_owner(new_owner: Principal) : async Bool {
      if (caller != owner) { D.trap("Unauthorized") };
      owner := new_owner;
      true;
    };

    // ============================================
    // Standard ICRC1 Functions
    // ============================================

    public shared query func icrc1_name() : async Text {
      icrc1().name();
    };

    public shared query func icrc1_symbol() : async Text {
      icrc1().symbol();
    };

    public shared query func icrc1_decimals() : async Nat8 {
      icrc1().decimals();
    };

    public shared query func icrc1_fee() : async ICRC1.Balance {
      icrc1().fee();
    };

    public shared query func icrc1_metadata() : async [ICRC1.MetaDatum] {
      icrc1().metadata();
    };

    public shared query func icrc1_total_supply() : async ICRC1.Balance {
      icrc1().total_supply();
    };

    public shared query func icrc1_minting_account() : async ?ICRC1.Account {
      ?icrc1().minting_account();
    };

    public shared query func icrc1_balance_of(args: ICRC1.Account) : async ICRC1.Balance {
      icrc1().balance_of(args);
    };

    public shared query func icrc1_supported_standards() : async [ICRC1.SupportedStandard] {
      icrc1().supported_standards();
    };

    public shared query func icrc10_supported_standards() : async [ICRC1.SupportedStandard] {
      icrc1().supported_standards();
    };

    // Transfer is blocked for non-mint/burn
    public shared({ caller }) func icrc1_transfer(args: ICRC1.TransferArgs) : async ICRC1.TransferResult {
      switch(await* icrc1().transfer_tokens(caller, args, false, ?#Sync(can_transfer))) {
        case (#trappable(val)) val;
        case (#awaited(val)) val;
        case (#err(#trappable(err))) D.trap(err);
        case (#err(#awaited(err))) D.trap(err);
      };
    };

    // ============================================
    // Standard ICRC2 Functions (Blocked)
    // ============================================

    public query({ caller = _ }) func icrc2_allowance(args: ICRC2.AllowanceArgs) : async ICRC2.Allowance {
      icrc2().allowance(args.spender, args.account, false);
    };

    public shared({ caller }) func icrc2_approve(args: ICRC2.ApproveArgs) : async ICRC2.ApproveResponse {
      switch(await* icrc2().approve_transfers(caller, args, false, ?#Sync(can_approve))) {
        case (#trappable(val)) val;
        case (#awaited(val)) val;
        case (#err(#trappable(err))) D.trap(err);
        case (#err(#awaited(err))) D.trap(err);
      };
    };

    public shared({ caller }) func icrc2_transfer_from(args: ICRC2.TransferFromArgs) : async ICRC2.TransferFromResponse {
      switch(await* icrc2().transfer_tokens_from(caller, args, ?#Sync(can_transfer_from))) {
        case (#trappable(val)) val;
        case (#awaited(val)) val;
        case (#err(#trappable(err))) D.trap(err);
        case (#err(#awaited(err))) D.trap(err);
      };
    };

    // ============================================
    // Standard ICRC3 Functions
    // ============================================

    public query func icrc3_get_blocks(args: ICRC3.GetBlocksArgs) : async ICRC3.GetBlocksResult {
      icrc3().get_blocks(args);
    };

    public query func icrc3_get_archives(args: ICRC3.GetArchivesArgs) : async ICRC3.GetArchivesResult {
      icrc3().get_archives(args);
    };

    public query func icrc3_get_tip_certificate() : async ?ICRC3.DataCertificate {
      icrc3().get_tip_certificate();
    };

    public query func icrc3_supported_block_types() : async [ICRC3.BlockType] {
      icrc3().supported_block_types();
    };

    public query func get_tip() : async ICRC3.Tip {
      icrc3().get_tip();
    };

    // ============================================
    // Standard ICRC4 Functions (Blocked)
    // ============================================

    public shared({ caller }) func icrc4_transfer_batch(args: ICRC4.TransferBatchArgs) : async ICRC4.TransferBatchResults {
      switch(await* icrc4().transfer_batch_tokens(caller, args, ?#Sync(can_transfer), ?#Sync(can_transfer_batch))) {
        case (#trappable(val)) val;
        case (#awaited(val)) val;
        case (#err(#trappable(err))) err;
        case (#err(#awaited(err))) err;
      };
    };

    public shared query func icrc4_balance_of_batch(request: ICRC4.BalanceQueryArgs) : async ICRC4.BalanceQueryResult {
      icrc4().balance_of_batch(request);
    };

    public shared query func icrc4_maximum_update_batch_size() : async ?Nat {
      ?icrc4().get_state().ledger_info.max_transfers;
    };

    public shared query func icrc4_maximum_query_batch_size() : async ?Nat {
      ?icrc4().get_state().ledger_info.max_balances;
    };

    // ============================================
    // Internal Mint/Burn for Owner
    // ============================================

    public shared({ caller }) func mint(args: ICRC1.Mint) : async ICRC1.TransferResult {
      if (caller != owner) { D.trap("Unauthorized") };
      switch(await* icrc1().mint_tokens(caller, args)) {
        case (#trappable(val)) val;
        case (#awaited(val)) val;
        case (#err(#trappable(err))) D.trap(err);
        case (#err(#awaited(err))) D.trap(err);
      };
    };

    public shared({ caller }) func burn(args: ICRC1.BurnArgs) : async ICRC1.TransferResult {
      switch(await* icrc1().burn_tokens(caller, args, false)) {
        case (#trappable(val)) val;
        case (#awaited(val)) val;
        case (#err(#trappable(err))) D.trap(err);
        case (#err(#awaited(err))) D.trap(err);
      };
    };

    // ============================================
    // Initialization and Lifecycle
    // ============================================

    private stable var _init = false;

    public shared(_msg) func admin_init() : async () {
      if (_init == false) {
        let _ = icrc1().metadata();
        let _ = icrc2().metadata();
        let _ = icrc4().metadata();
        let _ = icrc3().stats();
      };
      _init := true;
    };

    public shared func deposit_cycles() : async () {
      let amount = ExperimentalCycles.available();
      let accepted = ExperimentalCycles.accept<system>(amount);
      assert (accepted == amount);
    };

    system func postupgrade() {
      // Re-wire listeners after upgrade if needed
    };
};
