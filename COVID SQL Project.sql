/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

--View the Dataset

SELECT *
FROM Portfolioproject..CovidDeaths
ORDER BY location, date

SELECT *
FROM Portfolioproject..CovidVaccinations
ORDER BY location, date

--Total Deaths vs Total Cases

--Shows likelihood of dying by contracting covid in a particular country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM Portfolioproject..CovidDeaths
WHERE location LIKE 'India'
AND continent IS NOT NULL
ORDER BY location, date

--Total Cases vs Total Population

--Shows percentage of population infected with COVID in a particular country

SELECT Location, date, total_cases, population, (total_cases/population)*100 AS InfectionRate
FROM Portfolioproject..CovidDeaths
WHERE location like 'India'
AND continent IS NOT NULL
ORDER BY location, date

--Countries with highest Infection Rates

SELECT location, max(total_cases) as HighestPositiveCases, population, max((total_cases/population)*100) AS InfectionRate
FROM Portfolioproject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectionRate DESC

--Continent with Highest Death Count

SELECT location, MAX(CAST(total_deaths as int)) AS HighestDeathCount
FROM Portfolioproject..CovidDeaths
WHERE location IN ('Europe', 'North America', 'Europe', 'South America', 'Oceania', 'Africa')
--Need to specify the continents as the data includes values from Economic Classes as well
GROUP BY location
ORDER BY HighestDeathCount DESC

--GLOBAL NUMBERS

--Finding the Total Cases, Total Deaths and the Death Rate due to COVID globally

SELECT date, SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths as int)) AS Total_Deaths, (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS Death_Rate
FROM Portfolioproject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date

--Total Population vs Total Vaccination using Temeperory Table

-- Used Temp Table to perform Calculation on Partition By 

DROP Table IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 AS Vaccinated_Percentage
FROM #PercentPopulationVaccinated
ORDER BY location, Date

--Total Population vs Total Vaccination using CTE

-- Used CTE to perform Calculation on Partition By 

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS Vaccinated_Percentage
FROM PopvsVac
ORDER BY location, date


--Creating a View for Population Vaccinated as a % of Total Population

CREATE VIEW
PercentPopulationVaccinated
AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

