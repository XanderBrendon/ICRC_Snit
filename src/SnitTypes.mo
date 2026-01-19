module SnitTypes {

  // Dave (Partner App) Status
  public type DaveStatus = {
    #Pending;
    #Active;
    #Suspended;
    #Revoked;
  };

  // Dave (Partner App) - immutable record for storage
  public type Dave = {
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

  // Dave info for queries (stable representation)
  public type DaveInfo = {
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

  // User Level (Global per user)
  public type UserLevel = {
    level: Nat;
    experience: Nat;
    total_snit_earned: Nat;
    total_snit_spent: Nat;
  };

  // Affinity (User-Dave pairing)
  public type Affinity = {
    level: Nat;
    experience: Nat;
    total_minted: Nat;
    total_burned: Nat;
  };

  // Level Configuration
  public type LevelConfig = {
    base_mint_amount: Nat;
    user_level_multiplier: Nat; // Stored as fixed-point (e.g., 110 = 1.10x)
    dave_level_multiplier: Nat; // Stored as fixed-point (e.g., 105 = 1.05x)
    affinity_multiplier: Nat;   // Stored as fixed-point (e.g., 102 = 1.02x)
    xp_per_mint: Nat;
    xp_per_burn: Nat;
    xp_per_level: Nat;
    multiplier_scale: Nat;      // Scale for fixed-point (typically 100)
  };

  // Purchase arguments for burning SNIT
  public type PurchaseArgs = {
    dave: Principal;
    amount: Nat;
    content_id: ?Blob;
  };

  // SNIT-specific errors
  public type SnitError = {
    #NotAuthorized;
    #DaveNotFound;
    #DaveNotActive;
    #DaveAlreadyRegistered;
    #DavePendingApproval;
    #UserNotFound;
    #InsufficientBalance;
    #InvalidAmount;
    #LinkRequestNotFound;
    #LinkAlreadyExists;
    #CannotLinkToSelf;
    #PrincipalAlreadyLinked;
    #InvalidPrincipal;
    #TransferError: Text;
  };

  // Result type for SNIT operations
  public type SnitResult<T> = {
    #ok: T;
    #err: SnitError;
  };

  // Init args for SNIT-specific configuration
  public type SnitInitArgs = {
    level_config: ?LevelConfig;
  };

  // Default level configuration
  public func defaultLevelConfig() : LevelConfig {
    {
      base_mint_amount = 100_000_000; // 1 SNIT with 8 decimals
      user_level_multiplier = 110;    // 1.10x per level
      dave_level_multiplier = 105;    // 1.05x per level
      affinity_multiplier = 102;      // 1.02x per level
      xp_per_mint = 10;
      xp_per_burn = 15;
      xp_per_level = 100;
      multiplier_scale = 100;
    };
  };
};
