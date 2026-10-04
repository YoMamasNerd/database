-- ============================================================================
-- Op 1004: Penalize Fake-Resolution Releases (WAREZCX)
-- Negative-scoring Custom Format for releases whose titles claim a higher
-- resolution than the actual video stream.
--
-- Evidence (own Sonarr history census, Oct 2026, 23 unique WAREZCX imports):
--   4 of 23 were fake: 1080p DV HDR in the title, real 720p video
--   (Lanterns S01E01/E04/E06 HMAX, Dark.Matter S02E04 ATV).
--   All 4 fakes: NZB size 556-620 MiB. Smallest truthful 1080p DV release
--   of the same group: 966 MiB (Lioness S03E07). A real 1080p DV episode
--   under ~800 MiB is physically implausible, and NZB size cannot be faked
--   (segment count is fixed by the upload).
--   Rejected alternative: a DV.HDR title regex — truthful releases of the
--   same group are also DV.HDR (Lioness, Slow.Horses, Ted.Lasso, MobLand),
--   so the title alone does not separate fake from real. Size does.
--
-- Score -10000 IS safe here because the two conditions (group + size) match
-- only the lying releases: truthful WAREZCX 1080p DV releases (~1 GB+) do
-- not match the size condition and keep their full score. No calibration
-- grey zone, no group ban.
--
-- Known ceiling: a genuinely short episode (~20 min) at real 1080p DV under
-- 800 MiB from this group would be penalized. Relax the threshold or add a
-- runtime condition if that case shows up in practice.
--
-- Only affects 1080p HDR [Deu] and 1080p HDR [Eng] profiles.
-- ============================================================================

-- Clean up existing definitions to allow safe re-runs
DELETE FROM quality_profile_custom_formats WHERE custom_format_name = 'Penalize Fake Resolution';
DELETE FROM condition_patterns WHERE custom_format_name = 'Penalize Fake Resolution';
DELETE FROM condition_sizes WHERE custom_format_name = 'Penalize Fake Resolution';
DELETE FROM custom_format_conditions WHERE custom_format_name = 'Penalize Fake Resolution';
DELETE FROM custom_format_tags WHERE custom_format_name = 'Penalize Fake Resolution';
DELETE FROM regular_expressions WHERE name = 'WAREZCX';
DELETE FROM custom_formats WHERE name = 'Penalize Fake Resolution';

-- Ensure 'Penalty' tag exists
INSERT INTO tags (name) VALUES ('Penalty') ON CONFLICT (name) DO NOTHING;

-- 1. Create named regular expression (Profilarr convention)
INSERT INTO regular_expressions (name, pattern, description) VALUES
  ('WAREZCX', '(?<=^|[\\s.-])WAREZCX\\b', 'Release group with confirmed fake-resolution releases (1080p title, 720p video): Lanterns S01E01/E04/E06, Dark.Matter S02E04.');

-- 2. Create Custom Format
INSERT INTO custom_formats (name, description) VALUES
  ('Penalize Fake Resolution', 'Penalizes releases claiming 1080p that are physically too small to be real 1080p (NZB < 800 MiB), so grab-time title scores cannot beat better existing files. Matches only group + undersize, not the whole group: truthful releases keep their full score.');

-- Tag it
INSERT INTO custom_format_tags (custom_format_name, tag_name) VALUES
  ('Penalize Fake Resolution', 'Penalty');

-- 3. Conditions (both required, AND):
--    a) release title matches the group
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('Penalize Fake Resolution', 'Fake Resolution Group', 'release_title', 'all', 0, 1);

INSERT INTO condition_patterns (custom_format_name, condition_name, regular_expression_name)
VALUES ('Penalize Fake Resolution', 'Fake Resolution Group', 'WAREZCX');

--    b) NZB size smaller than 800 MiB (838860800 bytes). min_bytes = 0
--       means no lower bound, matching Op 1003''s GiB-style byte convention.
INSERT INTO condition_sizes (custom_format_name, condition_name, min_bytes, max_bytes)
VALUES ('Penalize Fake Resolution', 'Undersize For Claimed Resolution', 0, 838860800);

-- 4. Assign to custom profiles with a ban-level negative score.
--    Safe because only lying releases match both conditions.
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score)
VALUES
  ('1080p HDR [Deu]', 'Penalize Fake Resolution', 'all', -10000),
  ('1080p HDR [Eng]', 'Penalize Fake Resolution', 'all', -10000);