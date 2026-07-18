-- ============================================================================
-- Op 1003: Penalize Oversized Releases
-- Adds negative-scoring Custom Formats that penalize releases exceeding the
-- size limits from Op 1002. This counteracts the massive Quality Tier bonuses
-- (Tier 1: +185000, Tier 4: +182000) that cause oversized releases from
-- premium groups (e.g. NTb, HDC) to win against smaller, equally good releases.
--
-- Movies (Radarr): releases > 6 GB get -200000 score
-- Episodes (Sonarr): releases > 2 GB get -200000 score
-- Only affects 1080p HDR [Deu] and 1080p HDR [Eng] profiles.
--
-- Threshold chosen so that:
--   Tier 4 bonus (+182000) - penalty (-200000) = -18000 net
--   → a small x265 release (even without tier bonus) wins against an oversized
--     tier-4 release. But if no small alternative exists, the oversized
--     release can still be grabbed (score is negative but not -999999 ban).
-- ============================================================================

-- Clean up existing definitions to allow safe re-runs
DELETE FROM condition_sizes WHERE custom_format_name IN ('Penalize Oversized Movie', 'Penalize Oversized Episode');
DELETE FROM custom_format_conditions WHERE custom_format_name IN ('Penalize Oversized Movie', 'Penalize Oversized Episode');
DELETE FROM quality_profile_custom_formats WHERE custom_format_name IN ('Penalize Oversized Movie', 'Penalize Oversized Episode');
DELETE FROM custom_format_tags WHERE custom_format_name IN ('Penalize Oversized Movie', 'Penalize Oversized Episode');
DELETE FROM custom_formats WHERE name IN ('Penalize Oversized Movie', 'Penalize Oversized Episode');

-- Ensure 'Size' tag exists
INSERT INTO tags (name) VALUES ('Size') ON CONFLICT (name) DO NOTHING;

-- 1. Create Custom Formats
INSERT INTO custom_formats (name, description) VALUES
  ('Penalize Oversized Movie', 'Penalizes movie releases over 6 GB to counteract Quality Tier bonuses on oversized files.'),
  ('Penalize Oversized Episode', 'Penalizes episode releases over 2 GB to counteract Quality Tier bonuses on oversized files.');

-- Tag them
INSERT INTO custom_format_tags (custom_format_name, tag_name) VALUES
  ('Penalize Oversized Movie', 'Size'),
  ('Penalize Oversized Episode', 'Size');

-- 2. Create Conditions
-- Movie size condition (Radarr only) — matches releases LARGER than 6 GB
-- min_bytes = 6 GB, max_bytes = NULL (no upper limit)
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('Penalize Oversized Movie', 'Movie Size Upper Limit', 'size', 'radarr', 0, 1);

-- Episode size condition (Sonarr only) — matches releases LARGER than 2 GB
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('Penalize Oversized Episode', 'Episode Size Upper Limit', 'size', 'sonarr', 0, 1);

-- 3. Set size thresholds (in bytes)
-- 6 GB = 6 * 1024^3 = 6442450944 bytes
-- min_bytes = 6442450944 means "release must be greater than 6 GB"
-- max_bytes = 1000 GB = 1073741824000 bytes (effectively unlimited, but
--   Radarr/Sonarr require max > min — NULL gets converted to 0 and rejected)
INSERT INTO condition_sizes (custom_format_name, condition_name, min_bytes, max_bytes)
VALUES ('Penalize Oversized Movie', 'Movie Size Upper Limit', 6442450944, 1073741824000);

-- 2 GB = 2 * 1024^3 = 2147483648 bytes
INSERT INTO condition_sizes (custom_format_name, condition_name, min_bytes, max_bytes)
VALUES ('Penalize Oversized Episode', 'Episode Size Upper Limit', 2147483648, 1073741824000);

-- 4. Assign to custom profiles with NEGATIVE score
-- -200000 is enough to override the highest Quality Tier bonus (+185000 for Tier 1)
-- while still allowing oversized grabs when no alternative exists (not a ban).
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score)
VALUES
  ('1080p HDR [Deu]', 'Penalize Oversized Movie', 'radarr', -200000),
  ('1080p HDR [Eng]', 'Penalize Oversized Movie', 'radarr', -200000);

INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score)
VALUES
  ('1080p HDR [Deu]', 'Penalize Oversized Episode', 'sonarr', -200000),
  ('1080p HDR [Eng]', 'Penalize Oversized Episode', 'sonarr', -200000);