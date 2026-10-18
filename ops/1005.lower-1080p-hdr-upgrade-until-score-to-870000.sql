-- ============================================================================
-- Op 1005: Lower 1080p HDR upgrade-until score from 888888 to 870000
-- The upgrade-until score (cutoffFormatScore) was set to 888888 by Op 1001,
-- but that value is unreachable with the real release landscape:
--
-- Evidence (Radarr profile-12 file census, Oct 2026, 32 files on
-- '1080p HDR [Deu]'):
--   0 of 32 files reach 888888. Best observed: 874700
--   (WEBDL-1080p DV HDR AMZN). The WEB-DL path tops out at
--   860000 (1080p WEB-DL) + ~14000 addons (h265 5000, DV 3000,
--   HDR fallback 1000, German DL 1000, streamer tag 2000-3000)
--   = 866000-874700. The Quality Tier CFs (+180000-185000) that make
--   Bluray encodes reach 888888 never match any real imported file,
--   so encodes sit at ~710000.
--   Consequence of the unreachable cutoff: every file on the profile
--   stays "cutoff not met" forever -> repeated Rangarr upgrade searches
--   every 3 days, Radarr grabs the best-looking release, import then
--   fails as "not an upgrade" (score computed against the real file).
--
-- New value 870000 = minimum full DV bundle:
--   860000 (1080p WEB-DL) + 5000 (h265) + 3000 (Dolby Vision)
--   + 1000 (HDR fallback) + 1000 (German DL) = 870000
-- Separates exactly on the profile goal "1080p HDR [Deu]":
--   - WEBDL with DV satisfies the cutoff (real-world 869700-874700)
--   - best non-DV release (WEBDL with HDR10+ instead of DV) = 869000,
--     stays one step below, so a future DV release still wins
--   - Bluray encodes (~710000) keep being upgrade candidates
-- Sonarr side: identical CF layout, episode files observed at
--   868700 max -> same unreachability, same threshold applies.
-- ============================================================================

UPDATE quality_profiles
SET upgrade_until_score = 870000
WHERE name IN ('1080p HDR [Deu]', '1080p HDR [Eng]')
  AND upgrade_until_score = 888888;