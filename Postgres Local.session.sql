COPY covid_death
FROM '/private/tmp/CovidDeaths - CovidDeaths-2.csv' DELIMITER ',' CSV HEADER;
COPY covid_vaccination
FROM '/private/tmp/CovidVaccinations - CovidVaccinations.csv' DELIMITER ',' CSV HEADER;

--Covid 19 Data Exploration 

SELECT *
FROM covid_death
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Select Data to be starting with

SELECT location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM covid_death
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Total Cases vs Total Deaths

SELECT location,
    date,
    total_cases,
    total_deaths,
    (total_deaths / total_cases) * 100 AS deathPercentage
FROM covid_death
WHERE location LIKE '%States%'
    AND continent IS NOT NULL
ORDER BY 1,2;

-- Total Cases vs Population

SELECT location,
    date,
    population,
    total_cases,
    (total_cases / population) * 100 as percentPopulationInfected
From covid_death
order by 1,2;

-- Countries with Highest Infection Rate compared to Population

SELECT location,
    population,
    MAX(total_cases) AS highestInfectionCount,
    MAX((total_cases::float / population::float) * 100) AS percentPopulationInfected
FROM covid_death
GROUP BY location,
    population
ORDER BY percentPopulationInfected DESC;

-- Countries with Highest Death Count per Population

SELECT location,
    MAX(CAST(total_deaths AS int)) AS totalDeathCount
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY totalDeathCount DESC;

-- Showing contintents with the highest death count per population

SELECT continent,
    MAX(CAST(total_deaths AS int)) AS totalDeathCount
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY totalDeathCount DESC;

-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS int)) OVER (
        PARTITION BY dea.location
        ORDER BY dea.location,
            dea.Date
    ) AS rollingPeopleVaccinated
FROM covid_death dea
    JOIN covid_vaccination vac ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac AS (
    SELECT dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS int)) OVER (
            PARTITION BY dea.location
            ORDER BY dea.location,
                dea.date
        ) AS rollingPeopleVaccinated
    FROM covid_death dea
        JOIN covid_vaccination vac ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL --ORDER BY 2,3
)
SELECT *,
    (rollingPeopleVaccinated / population) * 100
FROM PopvsVac;

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS int)) OVER (
        PARTITION BY dea.Location
        ORDER BY dea.location,
            dea.date
    ) AS rollingPeopleVaccinated
FROM covid_death dea
    JOIN covid_vaccination vac ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;