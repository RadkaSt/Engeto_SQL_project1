/* 
 * Preparatory tables
 */
-- average prices of food in Czech Republic (not regionwise)
CREATE OR REPLACE TABLE t_czechia_price_full
SELECT cp.value AS price,cp.category_code, YEAR(cp.date_from) AS year,  
	cpc.name AS category, cpc.price_value, cpc.price_unit
FROM czechia_price cp 
JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
WHERE cp.region_code IS NULL;

SELECT *
FROM t_czechia_price_full
LIMIT 10;
-- Average salaries in Czech Republic
SELECT *
FROM czechia_payroll cp 
WHERE value_type_code = 5958
LIMIT 2;

CREATE OR REPLACE TABLE t_czechia_payroll_full
SELECT 
	cp.*, 
	cpc.name AS calculation,
	cpib.name AS industry_branch,
	cpvt.name AS value_type
FROM czechia_payroll cp 
JOIN czechia_payroll_calculation cpc 
	ON cp.calculation_code = cpc.code
JOIN czechia_payroll_industry_branch cpib
	ON cp.industry_branch_code = cpib.code
JOIN czechia_payroll_unit cpu
	ON cp.unit_code = cpu.code
JOIN czechia_payroll_value_type cpvt
	ON cp.value_type_code = cpvt.code
WHERE value_type_code = 5958;

SELECT *
FROM t_czechia_payroll_full
LIMIT 10;

SELECT DISTINCT calculation_code
FROM t_czechia_payroll_full tcpf;
/*
 * Preparing to join
 */ 
SELECT DISTINCT YEAR(date_from), YEAR(date_to), YEAR(date_to) - YEAR(date_from) AS year_difference
FROM czechia_price cp;
-- there seems to be always the same year in date_from as in date_to, so when in joining czechia
-- payroll and czechia price over years,
-- it should not matter if I choose date from or to in the czechia price table
-- for join of czechia price and czechia payroll I can use join on year (payroll_year in czechia_payroll)
SELECT *
FROM czechia_price cp
LIMIT 10;
SELECT *
FROM czechia_payroll cp 
LIMIT 10;


CREATE OR REPLACE TABLE t_Radka_Storchova_project_SQL_primary_final
SELECT cpf.price, cpf.category_code, cpf.category, cpf.`year`, cpf.price_value, cpf.price_unit,
	cpayf.value AS salary, cpayf.industry_branch_code, cpayf.industry_branch,
	cpayf.calculation_code
FROM t_czechia_price_full AS cpf
JOIN t_czechia_payroll_full AS cpayf
	ON cpf.year = cpayf.payroll_year;

SELECT *
FROM t_radka_storchova_project_sql_primary_final trspspf
LIMIT 10;

SELECT DISTINCT `year`
FROM t_Radka_Storchova_project_SQL_primary_final;
-- the primary table has data from years 2006-2018

/*
 * Tabulka 2 pro dodatečná data o dalších evropských státech
 */
-- overovaci dotazy na pochopeni dat
SELECT *
FROM countries c
LIMIT 3;
SELECT DISTINCT country
FROM economies
ORDER BY country
LIMIT 50;

-- tvorba sekundární tabulky
CREATE OR REPLACE TABLE t_Radka_Storchova_project_SQL_secondary_final
SELECT 
	c.country,
	e.`year`,
	e.population, 
	e.gini,
	e.GDP	
FROM countries c
JOIN economies e ON e.country = c.country
	WHERE c.continent = 'Europe'
		AND e.`year` BETWEEN 2006 AND 2018
ORDER BY c.`country`, e.`year`;

SELECT *
FROM t_Radka_Storchova_project_SQL_secondary_final 
LIMIT 15;

