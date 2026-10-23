-- 05_data_model.sql
-- Normalised model for the cleaned insurance data:
-- states          (state_code -> state_name)
-- districts       (surrogate district_id; identity = state + district name)
-- clean_insurance gets district_id and foreign keys to states and districts.
-- WHY a surrogate key for districts: district_code is not unique here
--   (13 codes are shared by different districts; see 04 check 9c).

ALTER TABLE clean_insurance DROP CONSTRAINT IF EXISTS fk_insurance_district;
ALTER TABLE clean_insurance DROP CONSTRAINT IF EXISTS fk_insurance_states;
ALTER TABLE clean_insurance DROP COLUMN IF EXISTS district_id;
DROP TABLE IF EXISTS district_census;
DROP TABLE IF EXISTS districts;
DROP TABLE IF EXISTS states;

-- States
CREATE TABLE states (
    state_code  INT PRIMARY KEY,
    state_name  VARCHAR NOT NULL
);

INSERT INTO states (state_code, state_name)
SELECT state_code, MIN(state_name)
FROM clean_insurance
WHERE state_code IS NOT NULL
GROUP BY state_code;

-- Districts
CREATE TABLE districts (
    district_id           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    state_code            INT NOT NULL REFERENCES states (state_code),
    district_name         VARCHAR NOT NULL,
    source_district_code  INT,               -- kept for tracing, NOT a key
    UNIQUE (state_code, district_name)
);

INSERT INTO districts (state_code, district_name, source_district_code)
SELECT state_code, district_name, MIN(district_code)
FROM clean_insurance
GROUP BY state_code, district_name;

-- Link the fact rows to districts
ALTER TABLE clean_insurance ADD COLUMN district_id INT;

UPDATE clean_insurance AS c
SET district_id = d.district_id
FROM districts AS d
WHERE c.state_code = d.state_code
  AND c.district_name = d.district_name;

-- Check: every row must have matched a district
SELECT COUNT(*) AS unmatched_rows
FROM clean_insurance
WHERE district_id IS NULL;
-- Result : 0

ALTER TABLE clean_insurance ALTER COLUMN district_id SET NOT NULL;

ALTER TABLE clean_insurance
    ADD CONSTRAINT fk_insurance_states
    FOREIGN KEY (state_code) REFERENCES states (state_code);

ALTER TABLE clean_insurance
    ADD CONSTRAINT fk_insurance_district
    FOREIGN KEY (district_id) REFERENCES districts (district_id);

-- District census
-- Check first: census values must be identical across years for each district
SELECT COUNT(*) AS districts_with_changing_population
FROM (
    SELECT district_id
    FROM clean_insurance
    GROUP BY district_id
    HAVING COUNT(DISTINCT total_population) > 1
) AS changing;
-- Result : its 20 , census cannot be stored once per district as 20 districts have different population across years

-- District census is not normalised.
-- Check showed 20 districts whose population values differ across years,
-- so census figures are not constant per district and cannot be stored once.

-- Final checks
SELECT
    (SELECT COUNT(*) FROM states)          AS states,
    (SELECT COUNT(*) FROM districts)       AS districts;
-- Result states (27) and districts (565)
