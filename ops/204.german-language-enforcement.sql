-- @operation: export
-- @entity: batch
-- @name: German and English Language Profiles and Codec Adjustments
-- @exportedAt: 2026-07-07T23:22:00.000Z

-- Clean up existing definitions to allow safe re-runs
DELETE FROM quality_profiles WHERE name IN ('1080p HDR [Deu]', '1080p HDR [Eng]');
DELETE FROM quality_profile_qualities WHERE quality_profile_name IN ('1080p HDR [Deu]', '1080p HDR [Eng]');
DELETE FROM quality_profile_languages WHERE quality_profile_name IN ('1080p HDR [Deu]', '1080p HDR [Eng]');
DELETE FROM quality_profile_custom_formats WHERE quality_profile_name IN ('1080p HDR [Deu]', '1080p HDR [Eng]');

DELETE FROM condition_languages WHERE custom_format_name IN ('Not German', 'Not English');
DELETE FROM custom_format_conditions WHERE custom_format_name IN ('Not German', 'Not English');
DELETE FROM custom_format_tags WHERE custom_format_name IN ('Not German', 'Not English');
DELETE FROM custom_formats WHERE name IN ('Not German', 'Not English');

-- 1. Create Custom Formats
INSERT INTO "custom_formats" ("name", "description") VALUES ('Not German', 'Matches releases that do not contain German audio/subtitles');
INSERT INTO "custom_formats" ("name", "description") VALUES ('Not English', 'Matches releases that do not contain English audio/subtitles');

INSERT INTO "tags" ("name") VALUES ('Language') ON CONFLICT ("name") DO NOTHING;
INSERT INTO "custom_format_tags" ("custom_format_name", "tag_name") VALUES ('Not German', 'Language');
INSERT INTO "custom_format_tags" ("custom_format_name", "tag_name") VALUES ('Not English', 'Language');

-- Add conditions for Not German
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('Not German', 'Not German', 'language', 'all', 0, 1);
INSERT INTO condition_languages (custom_format_name, condition_name, language_name, except_language) 
VALUES ('Not German', 'Not German', 'German', 1);

INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('Not German', 'Includes German', 'language', 'all', 1, 1);
INSERT INTO condition_languages (custom_format_name, condition_name, language_name, except_language) 
VALUES ('Not German', 'Includes German', 'German', 0);

-- Add conditions for Not English
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('Not English', 'Not English', 'language', 'all', 0, 1);
INSERT INTO condition_languages (custom_format_name, condition_name, language_name, except_language) 
VALUES ('Not English', 'Not English', 'English', 1);

INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('Not English', 'Includes English', 'language', 'all', 1, 1);
INSERT INTO condition_languages (custom_format_name, condition_name, language_name, except_language) 
VALUES ('Not English', 'Includes English', 'English', 0);


-- 2. Create the Quality Profiles
INSERT INTO quality_profiles (name, description, upgrades_allowed, minimum_custom_format_score, upgrade_until_score, upgrade_score_increment)
VALUES ('1080p HDR [Deu]', 'Custom 1080p Quality HDR profile prioritizing German language releases.', 1, 20000, 888888, 1);

INSERT INTO quality_profiles (name, description, upgrades_allowed, minimum_custom_format_score, upgrade_until_score, upgrade_score_increment)
VALUES ('1080p HDR [Eng]', 'Custom 1080p Quality HDR profile prioritizing English language releases.', 1, 20000, 888888, 1);


-- 3. Clone qualities from baseline '1080p Quality HDR'
INSERT INTO quality_profile_qualities (quality_profile_name, quality_group_name, quality_name, position, upgrade_until)
SELECT '1080p HDR [Deu]', quality_group_name, quality_name, position, upgrade_until
FROM quality_profile_qualities
WHERE quality_profile_name = '1080p Quality HDR';

INSERT INTO quality_profile_qualities (quality_profile_name, quality_group_name, quality_name, position, upgrade_until)
SELECT '1080p HDR [Eng]', quality_group_name, quality_name, position, upgrade_until
FROM quality_profile_qualities
WHERE quality_profile_name = '1080p Quality HDR';


-- 4. Clone languages from baseline '1080p Quality HDR'
INSERT INTO quality_profile_languages (quality_profile_name, language_name, type)
SELECT '1080p HDR [Deu]', language_name, type
FROM quality_profile_languages
WHERE quality_profile_name = '1080p Quality HDR';

INSERT INTO quality_profile_languages (quality_profile_name, language_name, type)
SELECT '1080p HDR [Eng]', language_name, type
FROM quality_profile_languages
WHERE quality_profile_name = '1080p Quality HDR';


-- 5. Clone custom formats from baseline '1080p Quality HDR'
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score)
SELECT '1080p HDR [Deu]', custom_format_name, arr_type, score
FROM quality_profile_custom_formats
WHERE quality_profile_name = '1080p Quality HDR';

INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score)
SELECT '1080p HDR [Eng]', custom_format_name, arr_type, score
FROM quality_profile_custom_formats
WHERE quality_profile_name = '1080p Quality HDR';


-- 6. Apply x265 and AV1 Codec Preferences (+10000 for AV1, +5000 for x265/h265)
UPDATE quality_profile_custom_formats
SET score = 10000
WHERE quality_profile_name IN ('1080p HDR [Deu]', '1080p HDR [Eng]') AND custom_format_name = 'AV1';

UPDATE quality_profile_custom_formats
SET score = 5000
WHERE quality_profile_name IN ('1080p HDR [Deu]', '1080p HDR [Eng]') AND custom_format_name IN ('x265 (Bluray)', 'x265 (WEB)', 'h265', 'x265');


-- 7. Apply Language rules for '1080p HDR [Deu]'
-- Must contain German (Not German = -999999)
INSERT OR REPLACE INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score)
VALUES ('1080p HDR [Deu]', 'Not German', 'radarr', -999999),
       ('1080p HDR [Deu]', 'Not German', 'sonarr', -999999);

-- English is NOT mandatory (Not English = 0)
INSERT OR REPLACE INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score)
VALUES ('1080p HDR [Deu]', 'Not English', 'radarr', 0),
       ('1080p HDR [Deu]', 'Not English', 'sonarr', 0);

-- Prefer German+English Dual Language (German DL = +1000)
UPDATE quality_profile_custom_formats
SET score = 1000
WHERE quality_profile_name = '1080p HDR [Deu]' AND custom_format_name = 'German DL';


-- 8. Apply Language rules for '1080p HDR [Eng]'
-- Must contain English (Not English = -999999)
INSERT OR REPLACE INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score)
VALUES ('1080p HDR [Eng]', 'Not English', 'radarr', -999999),
       ('1080p HDR [Eng]', 'Not English', 'sonarr', -999999);

-- German is NOT mandatory (Not German = 0)
INSERT OR REPLACE INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score)
VALUES ('1080p HDR [Eng]', 'Not German', 'radarr', 0),
       ('1080p HDR [Eng]', 'Not German', 'sonarr', 0);

-- Prefer German+English Dual Language (German DL = +1000)
UPDATE quality_profile_custom_formats
SET score = 1000
WHERE quality_profile_name = '1080p HDR [Eng]' AND custom_format_name = 'German DL';
