/* 
 * Preparatory tables
 */
-- Average prices of food in Czech Republic (not region-wise)
CREATE OR REPLACE TABLE t_czechia_price_full AS
SELECT 
    cp.value AS price,
    cp.category_code, 
    YEAR(cp.date_from) AS year,
    cpc.name AS category,
    cpc.price_value,
    cpc.price_unit
FROM 
    czechia_price cp 
JOIN 
    czechia_price_category cpc
    ON cp.category_code = cpc.code
WHERE 
    cp.region_code IS NULL;

-- Average salaries in Czech Republic
SELECT 
    value, 
    calculation_code, 
    industry_branch_code, 
    payroll_year
FROM 
    czechia_payroll 
WHERE 
    value_type_code = 5958
LIMIT 2;

CREATE OR REPLACE TABLE t_czechia_payroll_full AS
SELECT 
    cp.payroll_year,
    cp.value, 
    cp.calculation_code,
    cp.industry_branch_code,
    cp.unit_code,
    cp.value_type_code,
    cpc.name AS calculation,
    cpib.name AS industry_branch,
    cpvt.name AS value_type
FROM 
    czechia_payroll cp 
JOIN 
    czechia_payroll_calculation cpc 
    ON cp.calculation_code = cpc.code
JOIN 
    czechia_payroll_industry_branch cpib
    ON cp.industry_branch_code = cpib.code
JOIN 
    czechia_payroll_unit cpu
    ON cp.unit_code = cpu.code
JOIN 
    czechia_payroll_value_type cpvt
    ON cp.value_type_code = cpvt.code
WHERE 
    cp.value_type_code = 5958;


-- Understanding the year range in czechia_price
SELECT DISTINCT 
    YEAR(date_from) AS start_year, 
    YEAR(date_to) AS end_year,
    YEAR(date_to) - YEAR(date_from) AS year_difference
FROM 
    czechia_price;
-- there seems to be always the same year in date_from as in date_to, so when in joining czechia
-- payroll and czechia price over years,
-- it should not matter if I choose date from or to in the czechia price table
-- for join of czechia price and czechia payroll I can use join on year (payroll_year in czechia_payroll)

-- Create the primary joined table
CREATE OR REPLACE TABLE t_Radka_Storchova_project_SQL_primary_final AS
SELECT 
    cpf.price, 
    cpf.category_code, 
    cpf.category, 
    cpf.year, 
    cpf.price_value, 
    cpf.price_unit,
    cpayf.value AS salary, 
    cpayf.industry_branch_code, 
    cpayf.industry_branch,
    cpayf.calculation_code
FROM 
    t_czechia_price_full AS cpf
JOIN 
    t_czechia_payroll_full AS cpayf
    ON cpf.year = cpayf.payroll_year;


-- Secondary table for additional European data
-- Create the secondary table
CREATE OR REPLACE TABLE t_Radka_Storchova_project_SQL_secondary_final AS
SELECT 
    c.country,
    e.year,
    e.population, 
    e.gini,
    e.GDP
FROM 
    countries c
JOIN 
    economies e 
    ON e.country = c.country
WHERE 
    c.continent = 'Europe'
    AND e.year BETWEEN 2006 AND 2018
ORDER BY 
    c.country, 
    e.year;

