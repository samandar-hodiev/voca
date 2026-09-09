// auth/domain: Sign in with Apple. The app obtains the identity token natively and sends it to POST /api/v1/auth/apple; the BACKEND verifies it against Apple's public keys (ARCHITECTURE.md 8.1).
//
// Layer rules: ARCHITECTURE.md 4.2 (what belongs in each layer), 31.1 (dependencies).
