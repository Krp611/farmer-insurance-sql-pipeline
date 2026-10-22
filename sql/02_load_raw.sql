-- 02_load_raw.sql
-- Loads the CSV into raw_insurance with a server-side bulk COPY.
-- BEFORE RUNNING (Mac Terminal, from the repo folder):
--     cp data/raw/data.csv /tmp/data.csv
-- WHY /tmp: COPY is executed by the PostgreSQL server process,
--     which runs as its own OS user and cannot read home
--     folders. /tmp is readable by every user.
-- WHY COPY: one bulk operation instead of one INSERT per row.

TRUNCATE raw_insurance;   -- empties the table so the load is safe to re-run

COPY raw_insurance
FROM '/tmp/data.csv'
WITH (FORMAT csv, HEADER true);

-- Check: must equal (lines in the CSV - 1 header line).
--   Terminal:  wc -l data/raw/farmers_insurance.csv
SELECT COUNT(*) AS rows_loaded FROM raw_insurance;

