--Vaccination Progress
--what percent of population has new covid cases monthly?
with RankedData as (
	select
		location,
		STRFTIME('%Y-%m', date) as month,
		population,
(new_cases / population) * 100 as MonthlyDxRate,
		rank() over (
			partition by location,
			STRFTIME('%Y-%m', date)
			order by
				(new_cases / population) * 100 desc
		) as rank
	from
		CovidDeaths1a cda
	group by
		location,
		MONTH
)
select
	location,
	month,
	population,
	MonthlyDxRate
from
	RankedData --where rank =1 and location = 'United States'
order by
	MonthlyDxRate desc --limit 1;
	-- describes worst monthly diagnosis rate for each country 
	with RankedData as (
		SELECT
			location,
			strftime('%Y-%m', date) as month,
			population,
			(new_cases / population) * 100 as MonthlyDeathRate,
			row_number() over(
				partition by location
				order by
					(new_cases / population) * 100 desc
			) as rnk
		from
			CovidDeaths1a cda
	)
select
	location,
	month,
	population,
	MonthlyDeathRate
from
	RankedData
where
	rnk = 1
order by
	location --how has the vaccination coverage evolved over time in different countries? 
	--which countries had the most fully vaccinated individuals?
SELECT
	location,
	population_density,
	SUM(
		CAST(
			COALESCE(NULLIF(people_fully_vaccinated, ''), '0') AS INTEGER
		)
	) as AmtPplFullyVaccPerCountry,
	SUM(
		CAST(
			COALESCE(NULLIF(people_vaccinated, ''), '0') AS INTEGER
		)
	) as AmtPplVaccPerCountry
FROM
	CovidVaccinations1a cva
WHERE
	people_fully_vaccinated != ''
	OR people_vaccinated != ''
GROUP BY
	location,
	population_density
ORDER BY
	AmtPplFullyVaccPerCountry DESC,
	AmtPplVaccPerCountry DESC,
	population_density DESC;

--vaccination rates new people vacced per month for each country 
with RankedData as (
	select
		location,
		strftime('%Y-%m', date) as month,
		new_people_vaccinated_smoothed_per_hundred,
		row_number() over (
			partition by location,
			strftime('%Y-%m', date)
			order by
				new_people_vaccinated_smoothed_per_hundred desc
		) as rnk
	from
		CovidVaccinations1a cva
	where
		new_people_vaccinated_smoothed_per_hundred != ''
)
select
	location,
	month,
	new_people_vaccinated_smoothed_per_hundred
from
	RankedData
where
	rnk = 1
	and location = 'United States'
order by
	location,
	month with RankedData as (
		select
			location,
			strftime('%Y-%m', date) as month,
			max(new_people_vaccinated_smoothed_per_hundred) as MaxRate,
			row_number() over (
				partition by location
				order by
					max(new_people_vaccinated_smoothed_per_hundred) desc
			) as rnk
		from
			CovidVaccinations1a cva
		where
			new_people_vaccinated_smoothed_per_hundred != ''
		group by
			location,
			month
	)
select
	location,
	month,
	MaxRate
from
	RankedData
where
	rnk = 1
	and location = 'India'
order by
	maxrate desc --Effectiveness of Vaccination
	--is there are relationship between vaccination rate and decrease in covid death?
select
	dea.location,
	dea.date,
	dea.new_deaths,
	vac.new_vaccinations_smoothed_per_million
from
	CovidDeaths1a dea
	JOIN CovidVaccinations1a vac ON dea.location = vac.location
	AND dea.date = vac.date --how do different types of vaccines compare in terms of impact on reducing cases, hospitalization, death?
	--are ther trends in breakthrough infections or deaths among fully vaccinated people?
select
	dea.location,
	dea.date,
	dea.new_cases,
	vac.people_fully_vaccinated
from
	CovidDeaths1a dea
	JOIN CovidVaccinations1a vac ON dea.location = vac.location
	AND dea.date = vac.date --Geography
	--are there geographical clusters where vaccination rates are particularly high or low?
	--how does vaccination coverage differ between urban and ruural areas within countries?
	--does the vacc rate differ between low income and high income individuals?
select
	location,
	date,
	new_cases
from
	CovidDeaths1a cda
where
	location like '%low income%'
	or location like '%high income%' --are there regional variations that impact vaccination on reducing covid mortality?
	--Demographics
	--how does vaccination coverage vary among different age groups?
	--are there disparities in vacicnation rates based on gender, ethnicity, ses factors?
select
	location,
	female_smokers,
	male_smokers
from
	CovidVaccinations1a
where
	female_smokers != ''
	and location = 'United States' --what are trends in vaccine hesitancy over time? has public attitude changed?
	--relationship between vaccination rate and populationdensity/income
select
	location,
	population_density as PopDens,
	sum(people_fully_vaccinated) as AmtPplFullyVacc
from
	CovidVaccinations1a cva
group by
	PopDens,
	location
order by
	PopDens desc,
	AmtPplFullyVacc desc