-- A third purpose for one-time codes: confirming a sign-out from the account's own
-- mailbox. Same table and the same security rules as sign-up and password reset; only
-- the list of allowed purposes grows. Widening a CHECK is compatible with instances still
-- running the previous release, which never write the new value.
ALTER TABLE email_verifications DROP CONSTRAINT email_verifications_purpose_check;
ALTER TABLE email_verifications ADD CONSTRAINT email_verifications_purpose_check
    CHECK (purpose IN ('signup', 'password_reset', 'sign_out'));
