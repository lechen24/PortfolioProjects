SELECT *
FROM CovidDeath$
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM CovidVac$
--ORDER BY 3,4
--Need to include continent is not null otherwise, locations like "world", "low income", etc shows up

-- Select data that we are going to be using

SELECT location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM CovidDeath$
WHERE continent IS NOT NULL
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country
SELECT location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
FROM CovidDeath$
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population got covid
--Needed to convert total_cases to floats since they are currently nvarchar. Can't max a nvarchar
--Can you use cast instead. ex: CAST(total_cases AS INT)

SELECT location, 
	date, 
	population,
	total_cases, 
	(CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100 AS Deathpercentage
FROM CovidDeath$
WHERE location LIKE '%zIMBabwe%'AND continent IS NOT NULL
ORDER BY 1,2

--Looking at Countries with Highest Infection Rate compared to Population
--Needed to convert total_cases to floats since they are currently nvarchar. Can't max a nvarchar

SELECT location,
	population,
	MAX(CONVERT(float, total_cases)) AS HighestInfectionCount,
	MAX(CONVERT(float, total_cases)/ population) * 100 AS PercentPopulationInfected
FROM CovidDeath$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

--Showing Countries with Highest Death Count per Population

SELECT location,
	population,
	MAX(CONVERT(float, total_deaths)) AS TotalDeathCount
FROM CovidDeath$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 3 DESC

--Let's break things down by continent
--Showing continents with the highest death count 

SELECT location,
	MAX(CONVERT(float, total_deaths)) AS TotalDeathCount
FROM CovidDeath$
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC


--Global Numbers by date
--Needed to convert the date into datetime. Needed cases <> 0 otherwise div 0 error.
SELECT date, 
	SUM(new_cases) AS TotalCases, 
	SUM(new_deaths) AS TotalDeaths,
	SUM(new_deaths)/SUM(new_cases) * 100 AS Deathpercentage
FROM CovidDeath$
WHERE continent IS NOT NULL 
GROUP BY date
HAVING date >= CONVERT(datetime, '2020-01-23') AND SUM(new_cases) <> 0
ORDER BY 1 ASC

--Global Numbers in Total
SELECT SUM(new_cases) AS TotalCases, 
	SUM(new_deaths) AS TotalDeaths,
	SUM(new_deaths)/SUM(new_cases) * 100 AS Deathpercentage
FROM CovidDeath$
WHERE continent IS NOT NULL 
ORDER BY 1 ASC

--Looking at Total Population vs Vaccination
--Needed to convert int -> bigint since it gave an arithmetic overflow error
--OVER PARTITION allows me to SUM over by a certain location it restarts at a new country and rolls over the #'s everyday.

SELECT *
FROM CovidVac$ Vac 

SELECT vac.continent,
	vac.location,
	vac.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM CovidVac$ Vac 
JOIN CovidDeath$ Dea
ON vac.location = dea.location AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--USE CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
AS
(
SELECT vac.continent,
	vac.location,
	vac.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM CovidVac$ Vac 
JOIN CovidDeath$ Dea
ON vac.location = dea.location AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rollingpeoplevaccinated/population) * 100
FROM PopvsVac

--Creating View to store data for later visulizations

CREATE VIEW PopvsVac AS
SELECT vac.continent,
	vac.location,
	vac.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM CovidVac$ Vac 
JOIN CovidDeath$ Dea
ON vac.location = dea.location AND vac.date = dea.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PopvsVac