// integrations/storage/noop: the MVP AudioStore implementation — stores nothing.
//
// MVP DELIBERATELY DOES NOT RETAIN USER AUDIO. Recordings are streamed to the provider and
// discarded: no audio table, no bucket, no backup containing user voice.
//
// Why: voice is personal data with real privacy weight; storing it creates retention,
// consent, deletion and jurisdiction obligations we gain nothing from at MVP; and it costs
// money. What we keep is the derived assessment, which is what the product needs.
//
// Wired when AUDIO_RETENTION_ENABLED=false.
//
// See ARCHITECTURE.md 12.3.

package noop
