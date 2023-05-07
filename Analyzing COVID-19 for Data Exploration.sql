--  The following query uses 'SELECT *' ('Select all') to take a quick glance at the data to make sure it was successfully uploaded in both tables.
--  I set Continent as 'NOT NULL' to discard query results that group the entire continent as one location entity. That means the query will return results for countries like Afghanistan, but not continents like Asia.

SELECT *
FROM "CovidDeaths"
WHERE continent is NOT NULL;

SELECT *
FROM "CovidVaccinations"
WHERE continent is NOT NULL;

--  The following query selects the data I am actualy going to be using and order by location and date.

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM "CovidDeaths"
WHERE continent is NOT NULL
ORDER BY 1,2;

--  The following query looks at Total Cases vs Total Deaths to calculate the Mortality Risk in each country.
--  In simpler words, it shows the likelihood of dying if you get COVID-19 in your country.
--  I use 'NOT NULL' in total_cases to discard unnecessary rows of data where there are not cases of COVID-19.

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Mortality_Risk
FROM "CovidDeaths"
WHERE continent is NOT NULL
	AND total_cases is NOT NULL
ORDER BY 1,2;

--  The following query looks at Mexico's Mortality Risk to show an example.

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Mortality_Risk
FROM "CovidDeaths"
WHERE location like '%Mexico%'
	AND continent is NOT NULL
	AND total_cases is NOT NULL
ORDER BY 1,2;

--  The following query looks at Total Cases vs Population to show what percentage of the population has gotten COVID-19.
--  I use Mexico as an example.

SELECT location, date, total_cases, population, (total_cases/population)*100 AS Infection_Rate
FROM "CovidDeaths"
WHERE location like '%Mexico%'
	AND total_cases is NOT NULL
ORDER BY 1,2;

--  The following query shows countries with the Highest Infection Rate relative to their Population.
--  It uses 'MAX' to only display the row with the most confirmed cases because it has the most up-to-date figures.

SELECT location, population, MAX(total_cases) AS Cumulative_Confirmed_Cases, MAX((total_cases/population))*100 AS Infection_Rate
FROM "CovidDeaths"
WHERE continent is NOT NULL
	AND total_cases is NOT NULL
GROUP BY location, population
ORDER BY Infection_Rate DESC;

-- The following query shows countries with the Highest Mortality Rate relative to their Population.

SELECT location, population, MAX(total_deaths) AS Cumulative_Confirmed_Deaths, MAX((total_deaths/population))*100 AS Mortality_Rate
FROM "CovidDeaths"
WHERE continent is NOT NULL
	AND total_deaths is NOT NULL
GROUP BY location, population
ORDER BY Mortality_Rate DESC;

-- With some modifications, we can use it to consider continents instead of countries and build a query that returns confirmed deaths by continent.
-- I use 'NOT like '%income%'' to discard rows to only display locations by geographical factors (continent) and not socioeconomic factors (Ex. Low income country).

SELECT location, MAX(total_deaths) AS Cumulative_Confirmed_Deaths
FROM "CovidDeaths"
WHERE continent is NULL
	AND location NOT like '%income%'
	AND location NOT like '%World%'
GROUP BY location
ORDER BY Cumulative_Confirmed_Deaths DESC;

--  With some other changes, we can also look at the World Data as a whole (not divided by countries or continents) and sort it by date to get a grasp on how cases and deaths advanced through the pandemic.
--  I sum 'new cases' and 'new_deaths' to show the total cases and deaths per day.

SELECT date, SUM(new_cases) AS Total_New_Cases, SUM(new_deaths) AS Total_New_Deaths, SUM(new_deaths) / SUM(NULLIF(new_cases, 0))*100 AS Mortality_Rate
FROM "CovidDeaths"
WHERE continent is NOT NULL
GROUP BY date;

--  To join both tables, I use the following query.

SELECT *
FROM "CovidDeaths" as dea
JOIN "CovidVaccinations" as vac
	ON dea.location = vac.location
	AND dea.date = vac.date;
	
--  The following query looks at Total Population vs Vaccinations.
--  Rows that display "NULL" on new_vaccinations mean that on that specific date people were not people vaccinated.

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM "CovidDeaths" as dea
JOIN "CovidVaccinations" as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

--  By doing some modifications to the query, I can add a new column that displays the total of people vaccinated in each country. 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinations
FROM "CovidDeaths" as dea
JOIN "CovidVaccinations" as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

--  With some other modifications to the query, the new column could display the cumulative number of people vaccinated in each country each date. 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cumulative_new_vaccinations
FROM "CovidDeaths" as dea
JOIN "CovidVaccinations" as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

--  To be able to divide the Total of Population with the cumulative_new_vaccinations I just created, I will create a temporary table.
--  Now I am able to get the percentage of vaccinations divided by the Total Population.


DROP TABLE IF EXISTS PercentagePopulationVaccinated;

CREATE TEMPORARY TABLE PercentagePopulationVaccinated
(
Continent text,
Location text,
Date date,
Population numeric,
New_vaccinations numeric,
Cumulative_new_vaccinations numeric
);

INSERT INTO PercentagePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cumulative_new_vaccinations
FROM "CovidDeaths" as dea
JOIN "CovidVaccinations" as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

Select *, (Cumulative_new_vaccinations/Population)*100 AS Percentage_People_Vaccinated
FROM PercentagePopulationVaccinated;

--  The following query with 'create view' can be used to store data for later visualizations.

CREATE VIEW PercentagePopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cumulative_new_vaccinations
FROM "CovidDeaths" as dea
JOIN "CovidVaccinations" as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *
FROM PercentagePopulationVaccinated;