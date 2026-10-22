-- 01_create_raw.sql
-- Creates raw_insurance: the source data exactly as received.
-- WHY: raw is never edited. Everything else is rebuilt from it,
--      so any cleaning decision can be redone or audited.

DROP TABLE IF EXISTS raw_insurance;

CREATE TABLE raw_insurance (
    row_id                                INT PRIMARY KEY,
    src_year                              INT,
    src_state_name                        VARCHAR,
    src_district_name                     VARCHAR,
    insurance_units                       INT,
    total_farmers_covered                 INT,
    applications_loanee_farmers           INT,
    applications_non_loanee_farmers       INT,
    insured_land_area_kha                 NUMERIC,   -- thousand hectares
    farmers_premium_amount_lakh           NUMERIC,   -- Rs lakh
    state_premium_amount_lakh             NUMERIC,
    gov_premium_amount_lakh               NUMERIC,
    gross_premium_amount_to_be_paid_lakh  NUMERIC,
    sum_insured_lakh                      NUMERIC,
    percentage_male_farmers_covered       NUMERIC,
    percentage_female_farmers_covered     NUMERIC,
    percentage_others_covered             NUMERIC,
    percentage_sc_farmers_covered         NUMERIC,
    percentage_st_farmers_covered         NUMERIC,
    percentage_obc_farmers_covered        NUMERIC,
    percentage_general_farmers_covered    NUMERIC,
    percentage_marginal_farmers           NUMERIC,
    percentage_small_farmers              NUMERIC,
    percentage_other_farmers              NUMERIC,
    year_code                             INT,
    data_year                             VARCHAR,
    country                               VARCHAR,
    state_code                            INT,
    district_code                         INT,
    total_population                      INT,
    total_population_urban                INT,
    total_population_rural                INT,
    total_population_male                 INT,
    total_population_male_urban           INT,
    total_population_male_rural           INT,
    total_population_female               INT,
    total_population_female_urban         INT,
    total_population_female_rural         INT,
    number_of_households                  INT,
    number_of_households_urban            INT,
    number_of_households_rural            INT,
    land_area_urban                       NUMERIC,
    land_area_rural                       NUMERIC,
    land_area                             NUMERIC
);
