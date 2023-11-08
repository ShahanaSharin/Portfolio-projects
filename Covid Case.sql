/*
Covid 19 Data Exploration
skills used: joins, CTE'S. Aggregate Functions,Converting Data Types,creating views.
*/
----selecting the columns that we are going to use 
select location, date, total_cases,new_cases,total_deaths
from public.covid_death
order by 1,2
 --total cases with total deaths
 select location, date, total_cases,total_deaths,(total_deaths::decimal/total_cases::decimal)* 100 
 as death_percentage
from public.covid_death
where location like '%India%'
order by 1,2
---change the format of date column to timestamp of PostgreSQL
ALTER TABLE covid_death
ADD covid_date TIMESTAMP;
update covid_death
SET covid_date = TO_TIMESTAMP(date ,'DD-MM-YY');
ALTER TABLE covid_death DROP COLUMN date
ALTER TABLE covid_death RENAME COLUMN covid_date TO date
COMMIT;
select date from covid_death
---total cases with population 
----shows what percentage of population got covid
select location, date, total_cases,population,(total_cases::decimal/population::decimal)* 100 
 as death_percentage
from public.covid_death
where location like '%India%'
order by 1,2

-- looking at countries with highest infection rate compared to population
select location,max(total_cases)as highestinfectioncount,population,max((total_cases::decimal/population::decimal))* 100 
 as PercentPopulationInfected
 from public.covid_death
---where location like '%India%'
group by location,population
order by PercentPopulationInfected desc
--showing countries with hightest death count per population
 select location,max(total_deaths) as Totaldeathcount
from public.covid_death
where continent is not null
group by location 
order by Totaldeathcount desc
--lets break this down by continent
---showing continents with highest death count per population
select continent,max(total_deaths) as Totaldeathcount
from public.covid_death
where continent is not null
group by continent
order by Totaldeathcount desc

--global numbers
 select date,sum(new_cases) AS total_cases,sum(new_deaths) as total_death,sum(new_deaths::decimal)/NULLIF (sum(new_cases::decimal),0)* 100  as death_percentage
from public.covid_death

where continent is not null
group by date
order by 1,2

--
ALTER TABLE covid_vaccine
ADD covid_date TIMESTAMP;
update covid_vaccine
SET covid_date = TO_TIMESTAMP(date ,'DD-MM-YY');
ALTER TABLE covid_vaccine DROP COLUMN date
ALTER TABLE covid_vaccine RENAME COLUMN covid_date TO date
COMMIT;
SELECT * 
FROM public.covid_death as cd
JOIN public.covid_vaccine as cv
 ON cd.location=cv.location
AND cd.date=cv.date 

--looking at total population vs vaccinations
SELECT cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations, 
sum(cv.new_vaccinations) over (partition by cd.location order by cd.location,cd.date) as rollingpeoplevaccinated
FROM public.covid_death as cd
JOIN public.covid_vaccine as cv
 ON cd.location=cv.location
AND cd.date=cv.date
--where cd.location like '%India%'
where cd.continent is not null
order by 1,2,3

--USE CTE
WITH popvsvac (continent, location,date,population,new_vaccination,rollingpeoplevaccinated)
as
( SELECT cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations, 
sum(cv.new_vaccinations) over (partition by cd.location order by cd.location,cd.date) as rollingpeoplevaccinated
FROM public.covid_death as cd
JOIN public.covid_vaccine as cv
 ON cd.location=cv.location
AND cd.date=cv.date
--where cd.location like '%India%'
where cd.continent is not null
 --order by 1,2,3
)
select *,(rollingpeoplevaccinated/population)*100
from popvsvac

--creating view to store data for later visualization
create view percentpopulationvaccinated as
SELECT cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations, 
sum(cv.new_vaccinations) over (partition by cd.location order by cd.location,cd.date) as rollingpeoplevaccinated
FROM public.covid_death as cd
JOIN public.covid_vaccine as cv
 ON cd.location=cv.location
AND cd.date=cv.date
--where cd.location like '%India%'
where cd.continent is not null
 --order by 1,2,3
 select * from percentpopulationvaccinated
