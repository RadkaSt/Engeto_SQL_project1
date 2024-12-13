-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
SELECT 
    year,
    industry_branch,
    industry_branch_code,
    AVG(salary) AS average_salary,
    LAG(AVG(salary)) OVER (PARTITION BY industry_branch_code ORDER BY year) AS previous_year_salary,
    AVG(salary) - LAG(AVG(salary)) OVER (PARTITION BY industry_branch_code ORDER BY year) AS salary_change
FROM 
    t_radka_storchova_project_sql_primary_final
GROUP BY 
    year, 
    industry_branch_code, 
    industry_branch
ORDER BY 
    industry_branch, year;
   
-- 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
-- (Porovnání kupní síly obyvatel vztáhnuté na chleba a mléko pro rok 2006 a 2018,
-- kolik těchto potravin je možné si koupit za průměrný plat v dané době) 
-- Zjištění prvního a posledního roku
SELECT 
    MIN(year) AS first_year, 
    MAX(year) AS last_year
FROM 
    t_radka_storchova_project_sql_primary_final;

-- Výpočet průměrných cen mléka a chleba a počtu jednotek dostupných za průměrný plat pro první a poslední rok
SELECT 
    tpf.year,
    category,
    price_unit,
    ROUND(AVG(price), 2) AS average_price,
    ROUND(AVG(salary), 0) AS average_salary,
    CASE 
        WHEN category = 'Mléko polotučné pasterované' THEN ROUND(AVG(salary) / AVG(price), 2)
        WHEN category = 'Chléb konzumní kmínový' THEN ROUND(AVG(salary) / AVG(price), 2)
        ELSE NULL
    END AS units_affordable
FROM 
    t_radka_storchova_project_sql_primary_final tpf
WHERE 
    (year IN (SELECT MIN(year) FROM t_radka_storchova_project_sql_primary_final)
    OR 
    year IN (SELECT MAX(year) FROM t_radka_storchova_project_sql_primary_final))
    AND category IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
GROUP BY 
    tpf.year, 
    category, 
    price_unit
ORDER BY 
    tpf.year, 
    category;

-- V roce 2018 byla průměrná mzda 32536 Kč, cena 1 kg chleba 24,24 Kč a cena 1l mléka 19,82 Kč. 
-- V roce 2006 byla průměrná mzda 20754 Kč, cena 1 kg chleba 16,12 Kč a cena 1l mléka 14,44 Kč. 

-- 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
SELECT 
	round(AVG(price),2) AS averagy_price, category, price_value, price_unit,
	year
FROM t_radka_storchova_project_sql_primary_final tpf
GROUP BY category,year, price_value, price_unit;


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


-- Výpočet růstu HDP, mezd a cen potravin mezi jednotlivými roky
WITH CurrentYear AS (
    SELECT 
        ts.year AS year,
        ts.GDP AS current_GDP,
        AVG(tp.salary) AS current_salary,
        AVG(tp.price) AS current_price
    FROM 
        t_radka_storchova_project_sql_primary_final tp
    JOIN 
        t_radka_storchova_project_sql_secondary_final ts 
        ON tp.year = ts.year 
    WHERE 
        ts.country = 'Czech Republic'
    GROUP BY 
        ts.year, ts.GDP
),
PreviousYear AS (
    SELECT 
        ts.year + 1 AS year,
        ts.GDP AS previous_GDP,
        AVG(tp.salary) AS previous_salary,
        AVG(tp.price) AS previous_price
    FROM 
        t_radka_storchova_project_sql_primary_final tp
    JOIN 
        t_radka_storchova_project_sql_secondary_final ts 
        ON tp.year = ts.year 
    WHERE 
        ts.country = 'Czech Republic'
    GROUP BY 
        ts.year, ts.GDP
)
-- Spojení dat aktuálního roku s předchozím rokem
SELECT 
    cy.year,
    cy.current_GDP,
    ROUND(((cy.current_GDP - py.previous_GDP) / py.previous_GDP) * 100, 2) AS GDP_growth_percentage,
    cy.current_salary,
    ROUND(((cy.current_salary - py.previous_salary) / py.previous_salary) * 100, 2) AS salary_growth_percentage,
    cy.current_price,
    ROUND(((cy.current_price - py.previous_price) / py.previous_price) * 100, 2) AS price_growth_percentage
FROM 
    CurrentYear cy
LEFT JOIN 
    PreviousYear py
    ON cy.year = py.year
ORDER BY 
    cy.year;
