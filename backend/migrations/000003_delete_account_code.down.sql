-- Deletion codes are short-lived challenges, not records anyone needs; they are removed
-- so the narrower check can be restored.
DELETE FROM email_verifications WHERE purpose = 'delete_account';
ALTER TABLE email_verifications DROP CONSTRAINT email_verifications_purpose_check;
ALTER TABLE email_verifications ADD CONSTRAINT email_verifications_purpose_check
    CHECK (purpose IN ('signup', 'password_reset', 'sign_out'));
