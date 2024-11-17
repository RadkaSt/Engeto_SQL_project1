-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
SELECT *
FROM t_radka_storchova_project_sql_primary_final tpf
LIMIT 2;

SELECT 
    year,
    industry_branch,
    industry_branch_code,
    AVG(salary) AS average_salary
FROM 
    t_radka_storchova_project_sql_primary_final
GROUP BY 
    year, industry_branch_code
ORDER BY 
    industry_branch, year;
   
-- 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
-- (Porovnání kupní síly obyvatel vztáhnuté na chleba a mléko pro rok 2006 a 2018,
-- kolik těchto potravin je možné si koupit za průměrný plat v dané době) 
SELECT DISTINCT year
FROM t_radka_storchova_project_sql_primary_final tpf
ORDER BY year;

SELECT
	round(AVG(price),2) AS averagy_price, category, price_value, price_unit,
	round(AVG(salary),0) AS average_salary
FROM t_radka_storchova_project_sql_primary_final tpf 
WHERE year = '2018'
GROUP BY category;

-- V roce 2018 byla průměrná mzda 32536 Kč, cena 1 kg chleba 24,24 Kč a cena 1l mléka 19,82 Kč. 

SELECT
	round(AVG(price),2) AS averagy_price, category, price_value, price_unit,
	round(AVG(salary),0) AS average_salary
FROM t_radka_storchova_project_sql_primary_final tpf 
WHERE year = '2006'
GROUP BY category;

-- V roce 2006 byla průměrná mzda 20754 Kč, cena 1 kg chleba 16,12 Kč a cena 1l mléka 14,44 Kč. 

-- 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
SELECT 
	round(AVG(price),2) AS averagy_price, category, price_value, price_unit,
	year
FROM t_radka_storchova_project_sql_primary_final tpf
GROUP BY category,year;


-- 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
CREATE OR REPLACE TABLE t_radka_storchova_Q4
SELECT 
	round(AVG(price),2) AS average_price, round(AVG(salary),2) AS average_salary,
	year
FROM t_radka_storchova_project_sql_primary_final tpf
GROUP BY year;

WITH growth_rates AS (
    SELECT
        year,
        (average_price - LAG(average_price) OVER (ORDER BY year)) / LAG(average_price) OVER (ORDER BY year) * 100 AS price_growth,
        (CAST(REPLACE(average_salary, ',', '') AS DECIMAL(10,2)) - LAG(CAST(REPLACE(average_salary, ',', '') AS DECIMAL(10,2))) OVER (ORDER BY year)) /
        LAG(CAST(REPLACE(average_salary, ',', '') AS DECIMAL(10,2))) OVER (ORDER BY year) * 100 AS salary_growth
    FROM
        t_radka_storchova_Q4
)
SELECT
    year,
    price_growth,
    salary_growth,
    (price_growth - salary_growth) AS growth_difference
FROM
    growth_rates
WHERE
   (price_growth - salary_growth) > 10;
/*  5.Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste 
 * výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném 
 * nebo násdujícím roce výraznějším růstem?
 */
SELECT *
FROM t_radka_storchova_project_sql_secondary_final tpsf
WHERE country = "Czech Republic";

SELECT round(AVG(tp.price),2) AS average_price, round(AVG(tp.salary),2) AS average_salary,
	tp.year AS year, ts.GDP 
FROM t_radka_storchova_project_sql_primary_final tp
JOIN t_radka_storchova_project_sql_secondary_final ts 
	ON tp.year = ts.`year` 
	WHERE ts.country = 'Czech Republic'
GROUP BY year;


