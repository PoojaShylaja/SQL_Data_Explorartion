SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4 

SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4 

--select data that we are going to be using
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Looking at total cases vs total deaths
--shows liklihood of dying if you contract covid in your country
SELECT location,date,total_cases,total_deaths,
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
FROM PortfolioProject..CovidDeaths
--where total_deaths='India' 
ORDER BY 5 DESC

--NULLIF(CONVERT(float, total_cases), 0))
-- we get wrong data that is total cases less that total no of deaths 
SELECT location,date,CONVERT(float, total_deaths) AS cases,CONVERT(float, total_cases) AS deaths
FROM PortfolioProject..CovidDeaths
WHERE CONVERT(float, total_deaths)<CONVERT(float, total_cases) 

--Looking at total cases vs total population
--what % of population got covid
SELECT location,population,date,total_cases,new_cases,(total_cases/population)*100 AS TotalCovidPerc
FROM PortfolioProject..CovidDeaths
WHERE location='India'
order by 3 DESC

--Looking at countries with highest infection rate compared to population 
SELECT location,population,MAX(CAST(total_cases AS bigint))AS HighestInfectionCount,MAX((CAST(total_cases AS bigint)/population)*100) AS TotalCovidPerc
FROM PortfolioProject..CovidDeaths
GROUP BY location,population
ORDER BY TotalCovidPerc DESC

--showing countries with highest death count
SELECT location,MAX(CONVERT(BIGINT,total_deaths)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location 
ORDER BY TotalDeathCount DESC

--Lets break things by continent
SELECT location,MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Showing continents with highest Death count
SELECT continent,MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent	
ORDER BY TotalDeathCount DESC

--Global numbers
SELECT date,SUM(new_cases) AS TotalCases ,SUM(CAST(new_deaths AS BIGINT)) AS TotalDeaths,(SUM(CAST(new_deaths AS BIGINT))/NULLIF(SUM(new_cases),0))*100 AS DeathPercent
FROM PortfolioProject..CovidDeaths
--WHERE location='India' AND 
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) AS TotalCases ,SUM(CAST(new_deaths AS BIGINT)) AS TotalDeaths,(SUM(CAST(new_deaths AS BIGINT))/NULLIF(SUM(new_cases),0))*100 AS DeathPercent
FROM PortfolioProject..CovidDeaths
--WHERE location='India' AND 
WHERE continent IS NOT NULL
ORDER BY 1,2


--Next table
SELECT *
FROM PortfolioProject..CovidVaccinations

--Join Tables
SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location 
   AND dea.date = vac.date

--Looking at total Population vs vaccinations
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date

--Looking at total Population vs vaccinations by locations
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location)
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date

--Looking at total Population vs vaccinations by locations by adding daily new vaccination
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date,dea.location) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
ORDER BY 2,3


--Looking at total Population vs vaccinations by locations and total percent that got vaccinated with cte
WITH PopvsVac (Continent,Location,Date,Population,New_vaccinations,RollingPeopleVaccinated)
as
(
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(BIGINT,new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location AND
   dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY doesnt work inside
)
SELECT *,(RollingPeopleVaccinated/Population) AS PERCENTAGEOFVACC
FROM PopvsVac
--WHERE Location='India'
ORDER BY 2,3

--TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar(255),
 location nvarchar(255),
 date datetime,
 population numeric,
 new_vaccinations numeric,
 RollingPeopleVaccinated numeric
 )

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(BIGINT,new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location AND
   dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY doesnt work inside

SELECT *,(RollingPeopleVaccinated/Population) AS PERCENTAGEOFVACC
FROM #PercentPopulationVaccinated
--WHERE Location='India'
ORDER BY 2,3

--Creating view to see data for later visualization
--MAKE sure to create view in the same database
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(BIGINT,new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location AND
   dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY doesnt work inside

SELECT * FROM PercentPopulationVaccinated