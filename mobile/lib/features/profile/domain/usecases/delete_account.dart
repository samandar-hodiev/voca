// profile/domain: account deletion via DELETE /api/v1/users/me. REQUIRED BY BOTH STORES and must be reachable in-app; revokes all tokens and cascades the delete server-side (ARCHITECTURE.md 8.5, 18.2).
//
// Layer rules: ARCHITECTURE.md 4.2 (what belongs in each layer), 31.1 (dependencies).
