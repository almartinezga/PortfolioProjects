/*
Covid-19 Data Exploration for Tableau Dashboard

*/


-- 1. Global Numbers (table)

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM "CovidDeaths"
WHERE continent is NOT NULL
ORDER BY 1,2;

-- 2. Total Deaths per continent (bar chart)

SELECT location, SUM(new_deaths) AS total_death_count
FROM "CovidDeaths"
WHERE continent is NULL
AND location NOT IN ('World', 'European Union', 'International')
AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY total_death_count DESC;

-- 3. Percentage of the population infected per country (map)

SELECT location, population, MAX(total_cases) as highest_infection_count, MAX(total_cases/population)*100 AS percent_population_infected
FROM "CovidDeaths"
WHERE total_cases IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_infected DESC; 

-- 4. Percentage of the population infected (line chart and forecast)

SELECT location, population, date, COALESCE(MAX(total_cases),0) AS Highest_Infection_Count, COALESCE(MAX(Total_cases/Population)*100,0) AS Percent_Population_Infected
FROM "CovidDeaths"
GROUP BY location, population, date
ORDER BY Percent_Population_Infected DESC;