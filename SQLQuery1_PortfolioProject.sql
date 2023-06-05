

SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

--Selecting data that I will be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract Covid in your country

SELECT Location, date, total_cases, total_deaths,(total_deaths/(cast(total_cases as DECIMAL)))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE LOCATION LIKE '%states%'
ORDER BY 1,2

--SELECT Location, date, total_cases, total_deaths, CONVERT(DECIMAL(18, 2), (CONVERT(DECIMAL(18, 2), total_deaths) / CONVERT(DECIMAL(18, 2), total_cases)))*100 AS DeathPercentage
--FROM PortfolioProject.dbo.CovidDeaths
--WHERE LOCATION LIKE '%states%'
--ORDER BY 1,2 

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid

SELECT Location, date, Population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE LOCATION LIKE '%states%'
ORDER BY 1,2 


--Looking at Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(cast(total_cases as INT)) as HighestInfectionCount, Max((total_cases/population))*100 AS 
  PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
--WHERE LOCATION LIKE '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc 


--Showing Countries with Highest Death Count per Population

SELECT Location, MAX(CAST(total_deaths AS int)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
--WHERE LOCATION LIKE '%states%'
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount desc


--Let's break things down by continent

--Showing continents with the highest death count per population

SELECT continent, MAX(CAST(total_deaths AS int)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
--WHERE LOCATION LIKE '%states%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc



--Global Numbers

SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
--WHERE LOCATION LIKE '%states%'
WHERE continent IS NOT NULL
  AND new_deaths != 0
GROUP BY date
ORDER BY 1,2 

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
--WHERE LOCATION LIKE '%states%'
WHERE continent IS NOT NULL
  AND new_deaths != 0
ORDER BY 1,2


--Looking at Total Population vs Vaccinations
--Have to convert to bigint instead of int here because the sum value has exceeded 2,147,483,647 as of 2023

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location,
 dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


--Using CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location,
 dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


--Using a temp table

DROP Table IF exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location,
 dea.Date) as RollingPeopleVaccinated
, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated



--Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location,
 dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated