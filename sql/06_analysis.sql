-- 06_analysis.sql
-- Ten business questions about crop-insurance coverage.
-- Amounts are in Rs lakh (1 lakh = 100,000).
--
-- IMPORTANT: population columns mostly repeat the same census figure
-- on every year's row, but 20 districts have different values across
-- years (see 05_data_model.sql). Summing population across years would
-- multiply it, so ratios that use population are computed PER YEAR (Q3)
-- or with MAX (Q7).
-- District identity is (state, district name); district_code is not
-- unique (see 04 check 9c), so joins use district_id.

-- Q1. Which states reach the most farmers, and with how much cover?
SELECT
    state_name,
    SUM(total_farmers_covered)      AS farmers_covered,
    ROUND(SUM(sum_insured_lakh), 0) AS sum_insured_lakh
FROM clean_insurance
GROUP BY state_name
ORDER BY farmers_covered DESC NULLS LAST;
-- Result : Top three states 1) MADHYA PRADESH - Farmers Covered (9149678) 
--                           2) MAHARASHTRA - Farmers Covered (8939015)
--                           3) UTTAR PRADESH - Farmers Covered (7239576)


-- Q2. How has coverage changed year to year?
--     LAG() reads the previous year's value, giving year-on-year % change.
--     Limitation attached to result : some districts are missing from some years (see 04), so part
--     of a yearly change can come from missing rows, not real change.
WITH yearly AS (
    SELECT
        insurance_year,
        COUNT(*)                                  AS districts_reporting,
        SUM(total_farmers_covered)                AS farmers_covered,
        SUM(sum_insured_lakh)                     AS sum_insured_lakh,
        SUM(gross_premium_amount_to_be_paid_lakh) AS gross_premium_lakh
    FROM clean_insurance
    GROUP BY insurance_year
)
SELECT
    insurance_year,
    districts_reporting,
    farmers_covered,
    ROUND(sum_insured_lakh, 0)   AS sum_insured_lakh,
    ROUND(gross_premium_lakh, 0) AS gross_premium_lakh,
    ROUND(100.0 * (farmers_covered - LAG(farmers_covered) OVER (ORDER BY insurance_year))
          / NULLIF(LAG(farmers_covered) OVER (ORDER BY insurance_year), 0), 1) AS farmers_yoy_change_pct
FROM yearly
ORDER BY insurance_year;
-- Result : 2018 (NULL), 2019 (-17.8 %), 2020 (-1.5 %), 2021 (-11.7 %)


-- Q3. What share of the rural population is covered, per state and year?
--     Rural population is the denominator because crop insurance is
--     bought by farming households, not city residents.
--     100.0 (a decimal) forces decimal division; integer / integer
--     would round every ratio down to 0.
SELECT
    state_name,
    insurance_year,
    SUM(total_farmers_covered)  AS farmers_covered,
    SUM(total_population_rural) AS rural_population,
    ROUND(100.0 * SUM(total_farmers_covered)
          / NULLIF(SUM(total_population_rural), 0), 2) AS pct_rural_population_covered
FROM clean_insurance
GROUP BY state_name, insurance_year
ORDER BY pct_rural_population_covered DESC NULLS LAST;
-- Result : 88 rows.
--          Full output: results/pct_rural_farmers_covered.csv
--          Highest: Chhattisgarh 2021, 6.47% of rural population covered.
--          Lowest:  Gujarat 2019, 0.00 %.
--          Even the best state covers under 7% of its rural population.

-- one imp observation here, rows should be 108 (27 x 4) but its only 88 
-- check for the states with no coverage in some years 

-- Q4. Who pays the premium: farmers, state governments or the centre?
--     Shares are computed from the three premium parts, not from the
--     gross premium column, because 140 rows have parts that do not add
--     up to the gross figure (see 04 check 7).
-- Q4a. National split
SELECT
    ROUND(SUM(farmers_premium_amount_lakh), 0) AS farmers_paid_lakh,
    ROUND(SUM(state_premium_amount_lakh), 0)   AS states_paid_lakh,
    ROUND(SUM(gov_premium_amount_lakh), 0)     AS centre_paid_lakh,
    ROUND(100 * SUM(farmers_premium_amount_lakh)
          / NULLIF(SUM(farmers_premium_amount_lakh) + SUM(state_premium_amount_lakh)
                   + SUM(gov_premium_amount_lakh), 0), 1) AS farmers_share_pct
FROM clean_insurance;
-- Result : farmers_paid_lakh (562363) , states_paid_lakh (1973984), centre_paid_lakh (1764325), farmers_share_pct(13.1)

-- Q4b. Split by state
WITH state_premiums AS (
    SELECT
        state_name,
        SUM(farmers_premium_amount_lakh) AS farmers_paid,
        SUM(state_premium_amount_lakh)   AS state_paid,
        SUM(gov_premium_amount_lakh)     AS centre_paid
    FROM clean_insurance
    GROUP BY state_name
)
SELECT
    state_name,
    ROUND(100 * farmers_paid / NULLIF(farmers_paid + state_paid + centre_paid, 0), 1) AS farmers_share_pct,
    ROUND(100 * state_paid   / NULLIF(farmers_paid + state_paid + centre_paid, 0), 1) AS state_share_pct,
    ROUND(100 * centre_paid  / NULLIF(farmers_paid + state_paid + centre_paid, 0), 1) AS centre_share_pct
FROM state_premiums
ORDER BY farmers_share_pct DESC NULLS LAST;
-- Result : results/split_by_state.csv


-- Q5. Which districts pay the most and the least farmers' premium (all years)?
-- Q5a. Top 10
SELECT state_name, district_name,
       ROUND(SUM(farmers_premium_amount_lakh), 1) AS farmers_premium_lakh
FROM clean_insurance
GROUP BY state_name, district_name
ORDER BY farmers_premium_lakh DESC NULLS LAST
LIMIT 10;
-- Result : results/top_premium_paying_dist.csv

-- Q5b. Bottom 10 (excluding districts that paid nothing)
SELECT state_name, district_name,
       ROUND(SUM(farmers_premium_amount_lakh), 1) AS farmers_premium_lakh
FROM clean_insurance
GROUP BY state_name, district_name
HAVING SUM(farmers_premium_amount_lakh) > 0
ORDER BY farmers_premium_lakh ASC
LIMIT 10;
-- Result : results/bottom_premium_paying_dist.csv


-- Q6. Which districts cover more farmers than the average district?
WITH district_totals AS (
    SELECT state_name, district_name, SUM(total_farmers_covered) AS farmers_covered
    FROM clean_insurance
    GROUP BY state_name, district_name
)
SELECT state_name, district_name, farmers_covered
FROM district_totals
WHERE farmers_covered > (SELECT AVG(farmers_covered) FROM district_totals)
ORDER BY farmers_covered DESC;
-- Result : results/high_coverage_than_avg_dist.csv

-- Q6b. How many districts is that, out of all?
WITH district_totals AS (
    SELECT state_name, district_name, SUM(total_farmers_covered) AS farmers_covered
    FROM clean_insurance
    GROUP BY state_name, district_name
)
SELECT
    COUNT(*) FILTER (WHERE farmers_covered > (SELECT AVG(farmers_covered) FROM district_totals)) AS above_average,
    COUNT(*) AS all_districts
FROM district_totals;
-- Result : Above average (179), All Districts (565)


-- Q7. Large rural districts (over 10 lakh rural people): how well covered?
--     MAX() takes the census figure once instead of summing it per year.
--     For the 20 districts whose population changes across years, MAX()
--     uses the largest value, which slightly understates their coverage %.
SELECT
    state_name,
    district_name,
    MAX(total_population_rural)          AS rural_population,
    ROUND(AVG(total_farmers_covered), 0) AS avg_farmers_covered_per_year,
    ROUND(100.0 * AVG(total_farmers_covered)
          / NULLIF(MAX(total_population_rural), 0), 2) AS pct_rural_covered
FROM clean_insurance
GROUP BY state_name, district_name
HAVING MAX(total_population_rural) > 1000000
ORDER BY pct_rural_covered DESC NULLS LAST;
-- Result : results/large_rural_dist_coverage.csv


-- Q8. Premium rate: how much premium per Rs 100 of cover, by state?
SELECT
    state_name,
    ROUND(100 * SUM(gross_premium_amount_to_be_paid_lakh) / NULLIF(SUM(sum_insured_lakh), 0), 2) AS gross_premium_rate_pct,
    ROUND(100 * SUM(farmers_premium_amount_lakh)          / NULLIF(SUM(sum_insured_lakh), 0), 2) AS farmers_premium_rate_pct
FROM clean_insurance
GROUP BY state_name
ORDER BY gross_premium_rate_pct DESC NULLS LAST;
-- Result : results/premium_rate_by_state.csv


-- Q9. Top 3 districts in every state (JOIN on the dimension tables + RANK window).
--     Joins use district_id, not district_code: a shared code would match
--     two districts and double-count their farmers.
--     RANK() numbers districts within each state (PARTITION BY) by farmers covered.
WITH district_totals AS (
    SELECT s.state_name, d.district_name, SUM(c.total_farmers_covered) AS farmers_covered
    FROM clean_insurance c
    JOIN districts d ON c.district_id = d.district_id
    JOIN states    s ON c.state_code  = s.state_code
    GROUP BY s.state_name, d.district_name
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY state_name ORDER BY farmers_covered DESC NULLS LAST) AS rank_in_state
    FROM district_totals
)
SELECT state_name, rank_in_state, district_name, farmers_covered
FROM ranked
WHERE rank_in_state <= 3
ORDER BY state_name, rank_in_state;
-- Result : results/09_top3_dist_statewise.csv

-- Q10. How concentrated is coverage? Share of each state's covered
--      farmers that sits in its top 3 districts.
WITH district_totals AS (
    SELECT s.state_name, d.district_name, SUM(c.total_farmers_covered) AS farmers_covered
    FROM clean_insurance c
    JOIN districts d ON c.district_id = d.district_id
    JOIN states    s ON c.state_code  = s.state_code
    GROUP BY s.state_name, d.district_name
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY state_name ORDER BY farmers_covered DESC NULLS LAST) AS rank_in_state
    FROM district_totals
)
SELECT
    state_name,
    COUNT(*) AS districts,
    ROUND(100.0 * SUM(farmers_covered) FILTER (WHERE rank_in_state <= 3)
          / NULLIF(SUM(farmers_covered), 0), 1) AS top3_share_pct
FROM ranked
GROUP BY state_name
ORDER BY top3_share_pct DESC NULLS LAST;
-- Result : results/10_share_in_top3_dist.csv

-- Check: Q10's districts must add up to Q1's grand total.
-- If these differ, the joins are duplicating or dropping rows.
SELECT
    (SELECT SUM(total_farmers_covered) FROM clean_insurance)  AS total_from_fact_table,
    (SELECT SUM(c.total_farmers_covered)
       FROM clean_insurance c
       JOIN districts d ON c.district_id = d.district_id)     AS total_through_join;
-- Result : total_from_fact_table (50297012), total_through_join (50297012)
