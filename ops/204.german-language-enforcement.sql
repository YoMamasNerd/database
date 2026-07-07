-- @operation: export
-- @entity: batch
-- @name: German Language Enforcement and Dual Language Preference
-- @exportedAt: 2026-07-07T23:10:00.000Z

-- Create Not German Custom Format
INSERT INTO "custom_formats" ("name", "description") VALUES ('Not German', 'Matches releases that do not contain German audio/subtitles');

INSERT INTO "tags" ("name") VALUES ('Language') ON CONFLICT ("name") DO NOTHING;
INSERT INTO "custom_format_tags" ("custom_format_name", "tag_name") VALUES ('Not German', 'Language');

-- Add Not German conditions (Except German and Not Include German)
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('Not German', 'Not German', 'language', 'all', 0, 1);

INSERT INTO condition_languages (custom_format_name, condition_name, language_name, except_language) 
VALUES ('Not German', 'Not German', 'German', 1);

INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required)
VALUES ('Not German', 'Includes German', 'language', 'all', 1, 1);

INSERT INTO condition_languages (custom_format_name, condition_name, language_name, except_language) 
VALUES ('Not German', 'Includes German', 'German', 0);

-- Assign Not German a score of -999999 in all Quality Profiles
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score)
SELECT DISTINCT quality_profile_name, 'Not German', arr_type, -999999
FROM quality_profile_custom_formats qp
WHERE NOT EXISTS (
  SELECT 1 FROM quality_profile_custom_formats
  WHERE quality_profile_name = qp.quality_profile_name
    AND custom_format_name = 'Not German'
    AND arr_type = qp.arr_type
);

-- Change the score of German DL from -999999 to +1000 in all Quality Profiles
UPDATE quality_profile_custom_formats
SET score = 1000
WHERE custom_format_name = 'German DL';
