-- A fourth purpose for one-time codes: confirming that the person asking to delete an
-- account owns its mailbox. Same table and the same security rules as the other three;
-- only the list of allowed purposes grows. Widening a CHECK is compatible with instances
-- still running the previous release, which never write the new value.
ALTER TABLE email_verifications DROP CONSTRAINT email_verifications_purpose_check;
ALTER TABLE email_verifications ADD CONSTRAINT email_verifications_purpose_check
    CHECK (purpose IN ('signup', 'password_reset', 'sign_out', 'delete_account'));
