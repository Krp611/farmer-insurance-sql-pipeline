-- 04_data_quality.sql
-- Finds problems in clean_insurance BEFORE trusting any analysis.
-- Each query returns counts;

-- 1. Shape of the data
SELECT
    COUNT(*)                      AS total_rows,
    COUNT(DISTINCT state_name)    AS states,
    COUNT(DISTINCT district_name) AS districts,
    MIN(insurance_year)           AS first_year,
    MAX(insurance_year)           AS last_year
FROM clean_insurance;

-- 2. Missing values in the key columns
--    COUNT(col) skips NULLs, so COUNT(*) - COUNT(col) = number of NULLs.
SELECT
    COUNT(*) - COUNT(state_name)                           AS null_state_name,
    COUNT(*) - COUNT(district_name)                        AS null_district_name,
    COUNT(*) - COUNT(state_code)                           AS null_state_code,
    COUNT(*) - COUNT(district_code)                        AS null_district_code,
    COUNT(*) - COUNT(total_farmers_covered)                AS null_farmers_covered,
    COUNT(*) - COUNT(sum_insured_lakh)                     AS null_sum_insured,
    COUNT(*) - COUNT(gross_premium_amount_to_be_paid_lakh) AS null_gross_premium,
    COUNT(*) - COUNT(total_population)                     AS null_population
FROM clean_insurance;

-- 3. Impossible values: negatives in counts or money
SELECT
    COUNT(*) FILTER (WHERE total_farmers_covered < 0)       AS negative_farmers,
    COUNT(*) FILTER (WHERE sum_insured_lakh < 0)            AS negative_sum_insured,
    COUNT(*) FILTER (WHERE farmers_premium_amount_lakh < 0) AS negative_farmers_premium,
    COUNT(*) FILTER (WHERE total_population < 0)            AS negative_population
FROM clean_insurance;

-- 4. Premium charged with zero cover (or the reverse)
SELECT
    COUNT(*) FILTER (WHERE sum_insured_lakh = 0 AND gross_premium_amount_to_be_paid_lakh > 0) AS premium_without_cover,
    COUNT(*) FILTER (WHERE sum_insured_lakh > 0 AND gross_premium_amount_to_be_paid_lakh = 0) AS cover_without_premium
FROM clean_insurance;

-- 5. Are percentage columns on a 0-100 scale or a 0-1 scale?
--    RUN THIS BEFORE QUERY 6. If max_male_pct is about 1, change
--    every "- 100" in query 6 to "- 1" and "> 1" to "> 0.01".
SELECT
    MIN(percentage_male_farmers_covered) AS min_male_pct,
    MAX(percentage_male_farmers_covered) AS max_male_pct
FROM clean_insurance;

-- 6. Do percentage groups add up to ~100? (tolerance: 1 point)
--    Rows with a NULL in a group give a NULL sum and are not counted.
SELECT
    COUNT(*) FILTER (WHERE ABS(percentage_male_farmers_covered
                             + percentage_female_farmers_covered
                             + percentage_others_covered - 100) > 1)          AS gender_not_100,
    COUNT(*) FILTER (WHERE ABS(percentage_sc_farmers_covered
                             + percentage_st_farmers_covered
                             + percentage_obc_farmers_covered
                             + percentage_general_farmers_covered - 100) > 1) AS category_not_100,
    COUNT(*) FILTER (WHERE ABS(percentage_marginal_farmers
                             + percentage_small_farmers
                             + percentage_other_farmers - 100) > 1)           AS farm_size_not_100
FROM clean_insurance;

-- 7. Does farmers + state + central premium equal the gross premium? (1% tolerance)
SELECT
    COUNT(*) FILTER (
        WHERE ABS(farmers_premium_amount_lakh + state_premium_amount_lakh + gov_premium_amount_lakh
                  - gross_premium_amount_to_be_paid_lakh)
              > 0.01 * gross_premium_amount_to_be_paid_lakh
    ) AS premium_parts_mismatch
FROM clean_insurance;

-- 8. More than one row for the same district in the same year?
SELECT insurance_year, state_name, district_name, COUNT(*) AS rows_for_same_district_year
FROM clean_insurance
GROUP BY insurance_year, state_name, district_name
HAVING COUNT(*) > 1
ORDER BY rows_for_same_district_year DESC;

-- 9. Code consistency (needed before building the data model in 05)
--    9a. A state_code with more than one state name
SELECT state_code, COUNT(DISTINCT state_name) AS names
FROM clean_insurance
GROUP BY state_code
HAVING COUNT(DISTINCT state_name) > 1;

--    9b. A district_code that appears under more than one state_code
SELECT district_code, COUNT(DISTINCT state_code) AS states
FROM clean_insurance
GROUP BY district_code
HAVING COUNT(DISTINCT state_code) > 1;
