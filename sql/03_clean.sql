-- 03_clean.sql
-- Builds clean_insurance FROM raw_insurance. Never edits raw.
-- Re-runnable: drops and rebuilds the clean table every time.

-- Cleaning decisions:
--   1. Names: trim spaces, collapse repeated spaces, uppercase.
--      WHY: 'Pune', 'PUNE ' and 'PUNE' would otherwise be three
--      different groups in every GROUP BY.
--   2. Shorter, clearer names: src_year -> insurance_year,
--      src_state_name -> state_name, src_district_name -> district_name.
--   3. Units kept as in the source and stated in column names
--      (_lakh = Rs lakh, _kha = thousand hectares).
--   4. Columns not used in the analysis (urban/gender population
--      splits, year_code) are left in raw only.

DROP TABLE IF EXISTS clean_insurance ;

CREATE TABLE clean_insurance AS
SELECT
    row_id,
    src_year                                                        AS insurance_year,
    UPPER(TRIM(REGEXP_REPLACE(src_state_name,    '\s+', ' ', 'g'))) AS state_name,
    UPPER(TRIM(REGEXP_REPLACE(src_district_name, '\s+', ' ', 'g'))) AS district_name,
    state_code,
    district_code,
    insurance_units,
    total_farmers_covered,
    applications_loanee_farmers,
    applications_non_loanee_farmers,
    insured_land_area_kha,
    farmers_premium_amount_lakh,
    state_premium_amount_lakh,
    gov_premium_amount_lakh,
    gross_premium_amount_to_be_paid_lakh,
    sum_insured_lakh,
    percentage_male_farmers_covered,
    percentage_female_farmers_covered,
    percentage_others_covered,
    percentage_sc_farmers_covered,
    percentage_st_farmers_covered,
    percentage_obc_farmers_covered,
    percentage_general_farmers_covered,
    percentage_marginal_farmers,
    percentage_small_farmers,
    percentage_other_farmers,
    TRIM(data_year) AS data_year,
    TRIM(country)   AS country,
    total_population,
    total_population_rural,
    number_of_households,
    number_of_households_rural,
    land_area,
    land_area_rural
FROM raw_insurance;

ALTER TABLE clean_insurance ADD PRIMARY KEY (row_id);

-- Check 1: row count must equal raw (cleaning should not lose rows).
SELECT
    (SELECT COUNT(*) FROM raw_insurance)   AS raw_rows,
    (SELECT COUNT(*) FROM clean_insurance) AS clean_rows;
-- Result : raw_rows(1870), clean_rows(1870)

-- Check 2: did name cleaning merge any spelling variants?
--          If clean < raw, some names differed only by case or spaces.
SELECT
    (SELECT COUNT(DISTINCT src_state_name)    FROM raw_insurance)   AS raw_states,
    (SELECT COUNT(DISTINCT state_name)        FROM clean_insurance) AS clean_states,
    (SELECT COUNT(DISTINCT src_district_name) FROM raw_insurance)   AS raw_districts,
    (SELECT COUNT(DISTINCT district_name)     FROM clean_insurance) AS clean_districts;
-- Result : raw_states(27), clean_states(27) and raw_districts(560), clean_districts(560)      
