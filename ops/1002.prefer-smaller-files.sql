-- ============================================================================
-- Op 1002: Prefer Smaller Files
-- Adds Size conditions to custom profiles to prefer smaller file sizes.
-- Movies (Radarr): max 6 GB for a typical 120-min film
-- Episodes (Sonarr): max 2 GB for a typical 45-min episode
-- Only affects 1080p HDR [Deu] and 1080p HDR [Eng] profiles.
-- ============================================================================

-- Clean up existing definitions to allow safe re-runs
DELETE FROM condition_sizes WHERE custom_format_name IN ('Prefer Smaller Movie', 'Prefer Smaller Episode');
DELETE FROM custom_format_conditions WHERE custom_format_name IN ('Prefer Smaller Movie', 'Prefer Smaller Episode');
DELETE FROM quality_profile_custom_formats WHERE custom_format_name IN ('Prefer Smaller Movie', 'Prefer Smaller Episode');
DELETE FROM custom_format_tags WHERE custom_format_name IN ('Prefer Smaller Movie', 'Prefer Smaller Episode');
DELETE FROM custom_formats WHERE name IN ('Prefer Smaller Movie', 'Prefer Smaller Episode');

-- Ensure 'Size' tag exists
INSERT INTO tags (name) VALUES ('Size') ON CONFLICT (name) DO NOTHING;

-- 1. Create Custom Formats
INSERT INTO custom_formats (name, description) VALUES
  ('Prefer Smaller Movie', 'Prefers movie releases under 6 GB to keep file sizes manageable.'),
  ('Prefer Smaller Episode', 'Prefers episode releases under 2 GB to keep file sizes manageable.');

-- Tag them
INSERT INTO custom_format_tags (custom_format_name, tag_name) VALUES
  ('Prefer Smaller Movie', 'Size'),
  ('Prefer Smaller Episode', 'Size');

-- 2. Create Conditions
-- Movie size condition (Radarr only)
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('Prefer Smaller Movie', 'Movie Size Limit', 'size', 'radarr', 0, 1);

-- Episode size condition (Sonarr only)
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('Prefer Smaller Episode', 'Episode Size Limit', 'size', 'sonarr', 0, 1);

-- 3. Set size limits (in bytes)
-- 6 GB = 6 * 1024^3 = 6442450944 bytes
INSERT INTO condition_sizes (custom_format_name, condition_name, min_bytes, max_bytes)
VALUES ('Prefer Smaller Movie', 'Movie Size Limit', NULL, 6442450944);

-- 2 GB = 2 * 1024^3 = 2147483648 bytes
INSERT INTO condition_sizes (custom_format_name, condition_name, min_bytes, max_bytes)
VALUES ('Prefer Smaller Episode', 'Episode Size Limit', NULL, 2147483648);

-- 4. Assign to custom profiles with positive score
-- Radarr: only Prefer Smaller Movie
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score)
VALUES
  ('1080p HDR [Deu]', 'Prefer Smaller Movie', 'radarr', 100),
  ('1080p HDR [Eng]', 'Prefer Smaller Movie', 'radarr', 100);

-- Sonarr: only Prefer Smaller Episode
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score)
VALUES
  ('1080p HDR [Deu]', 'Prefer Smaller Episode', 'sonarr', 100),
  ('1080p HDR [Eng]', 'Prefer Smaller Episode', 'sonarr', 100);