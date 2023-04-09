/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM project..CovidDeaths$
ORDER BY 3,4


-- Cleaning Date in SQL Queries
-------------------------------------

-- Standardized Date Format CovidDeaths Table

-- Shows orginal Date Format in "date" column
Select date, CONVERT(Date, date) as Date
From project..CovidDeaths$


ALTER TABLE CovidDeaths$ 
ADD DateConverted Date;

UPDATE CovidDeaths$
SET DateConverted = CONVERT(Date, date)

-- Shows cleaned up Date column
Select DateConverted as Date, CONVERT(Date, date)
From project..CovidDeaths$


-- Standardized Date Format CovidVaccinations Table
Select date, CONVERT(Date, date) as Date
From project..CovidVaccinations$

ALTER TABLE CovidVaccinations$ 
ADD DateConverted Date;

UPDATE CovidVaccinations$ 
SET DateConverted = CONVERT(Date, date)

-- Shows cleaned up Date column
Select DateConverted as Date, CONVERT(Date, date)
From project..CovidVaccinations$ 



-- Selecting Data
Select location, date, total_cases, new_cases, total_deaths, population
FROM project..CovidDeaths$
order by 1,2

--Total cases vs Total Deaths
-- Shows likelihood of dying if contract covid in your country
-- Have to Cast data since they are stored as nvarchar

Select location, date, total_cases, total_deaths, 
	(cast(total_deaths as float) / cast(total_cases as float))*100 as DeathPercentage
FROM project..CovidDeaths$
WHERE location like '%United states%'
and continent is not null
order by 1,2


-- Total Cases vs Population
-- What percentage of population got covid

Select location, date, total_cases, population, 
	(cast(total_cases as float) / population)*100 as InfectedPercentage
FROM project..CovidDeaths$
WHERE location like '%United states%'
and continent is not null
order by 1,2


-- Which Countries have Highest Infection Rate compared to Population
Select 
	location,
	population,
	Max(cast(total_cases as float)) as HighestInfectionCount,
	Max(cast(total_cases as float) / population)*100 as InfectedPercentage
FROM project..CovidDeaths$
WHERE continent is not null
Group by location,population
Order by InfectedPercentage desc


-- Showing Countries with Highest Death Count per Population
-- As of 4/6/23
Select 
	location,
	Max(cast(total_deaths as int)) as TotalDeathCount,
	Max(cast(total_cases as int) / population)*100 as InfectedPercentage
FROM project..CovidDeaths$
WHERE continent is not null
Group by location
Order by TotalDeathCount desc


-- ACTUAL Showing Continents with Total Death Counts

Select 
	location,
	Max(cast(total_deaths as int)) as TotalDeathCount
FROM project..CovidDeaths$
WHERE continent is null
Group by location
Order by TotalDeathCount desc

-- Showing Continents with Total Death Counts (for drill down effect)
-- *only taking death count of highest country in one continent

Select 
	continent,
	Max(cast(total_deaths as int)) as TotalDeathCount
FROM project..CovidDeaths$
WHERE continent is not null
Group by continent
Order by TotalDeathCount desc



-- GLOBAL NUMBERS


-- DeathPercentage per Day
Select date,
	SUM(new_cases) as TotalCases, 
	SUM(new_deaths) as TotalDeaths,
	SUM(new_deaths)/ SUM(NULLIF(new_cases,0))*100 AS DeathPercentage
From project..CovidDeaths$
Where continent is not null
Group by date
Order by 1,2


-- Looking at Total Population vs Vaccinations

Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations
, SUM(Cast (vac.new_vaccinations as bigint)) 
OVER (Partition by dth.location Order by dth.location, dth.date) as RollingCountPeopleVaccinated
From project..CovidVaccinations$ vac
Join project..CovidDeaths$ dth
	On dth.location = vac.location
	and dth.date = vac.date
Where dth.continent is not null
Order by 2,3


--USE CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingCountPeopleVaccinated)
as 
(
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations
, SUM(Cast (vac.new_vaccinations as bigint)) 
OVER (Partition by dth.location Order by dth.location, dth.date) as RollingCountPeopleVaccinated
From project..CovidVaccinations$ vac
Join project..CovidDeaths$ dth
	On dth.location = vac.location
	and dth.date = vac.date
Where dth.continent is not null
)

select *, (RollingCountPeopleVaccinated/Population) * 100 as PercentagePopulationVaccinated
from PopvsVac


-- Creating View 

Create View TotalDeathCountByCountry as 
Select 
	location,
	Max(cast(total_deaths as int)) as TotalDeathCount
FROM project..CovidDeaths$
WHERE continent is null
Group by location


