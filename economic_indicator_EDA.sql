SELECT * FROM ECONOMIC_INDICATORS;
SELECT * FROM HUMAN_DEVELOPMENT_INDEX;

--# COUNTRY WITH HIGHEST GDP FOR PERIOD OF 1960 - 2018
with gdp as
	(select country_name, year, gdp_in_usd,
	ROW_NUMBER() OVER (partition by year order by gdp_in_usd desc ) as rn
	from economic_indicators
	where gdp_in_usd is not null)
Select country_name, year, gdp_in_usd
from gdp
where rn = 1;

--# COUNTRY WITH HIGHEST GDP PER CAPITA FOR PERIOD OF 1960 - 2018
with gdp_per_capita as
	(select country_name, year, gdp_per_capita_in_usd,
	ROW_NUMBER() OVER (partition by year order by gdp_per_capita_in_usd desc ) as rn
	from economic_indicators
	where gdp_per_capita_in_usd is not null)
Select country_name, year, gdp_per_capita_in_usd
from gdp_per_capita
where rn = 1;

--# COUNTRY WITH HIGHEST AND LOWEST BIRTHRATE FOR PERIOD OF 1960 - 2018
--## highest birthrate country
with birthrate_wei as
	(select country_name, year, birthrate,
	ROW_NUMBER() OVER (partition by year order by birthrate desc ) as rn
	from economic_indicators
	where birthrate is not null)
Select country_name, year, birthrate
from birthrate_wei
where rn = 1;

--## lowest birthrate country
with birthrate_wei as
	(select country_name, year, birthrate,
	ROW_NUMBER() OVER (partition by year order by birthrate ) as rn
	from economic_indicators
	where birthrate is not null)
Select country_name, year, birthrate
from birthrate_wei
where rn = 1;

--# COUNTRY WITH HIGHEST AND LOWEST BIRTHRATE FOR PERIOD OF 1960 - 2018
--## highest deathrate country
with deathrate_wei as
	(select country_name, year, deathrate,
	ROW_NUMBER() OVER (partition by year order by deathrate desc ) as rn
	from economic_indicators
	where deathrate is not null)
Select country_name, year, deathrate
from deathrate_wei
where rn = 1;

--## lowest birthrate country
with deathrate_wei as
	(select country_name, year, deathrate,
	ROW_NUMBER() OVER (partition by year order by deathrate ) as rn
	from economic_indicators
	where deathrate is not null)
Select country_name, year, deathrate
from deathrate_wei
where rn = 1;

--# REGION WITH THE HIGHEST NUMBER OF LOW INCOME COUNTRY
select income_group, region, count(1) as total
from economic_indicators
where income_group = 'Low income'
group by income_group, region
order by 3 desc limit 1;

--# REGION WITH THE HIGHEST NUMBER OF HIGH INCOME COUNTRY
with income_groups as
	(select income_group, region, count(1) as total
	from economic_indicators
	where lower(income_group) like 'high income%'
	group by income_group, region
	order by income_group desc, count(1) desc)
select income_group, region, total 
from (Select *, row_number() over (partition by income_group order by total desc) as rn
	from income_groups)
where rn = 1
order by income_group desc;

--#COUNTRIES WHICH EXPERIENCED HIGHEST AND LOWEST GDP GROWTH 1960 - 2018 (measured by average gdp growth)
--## highest GDP growth
WITH cte_gdp AS (
    SELECT country_name, year, gdp_in_usd AS gdp
    FROM economic_indicators
    ORDER BY country_name, year
),
cte_gdp_growth as
	(SELECT *,
		ROUND(((gdp - LAG(gdp) OVER (PARTITION BY country_name ORDER BY year)) / LAG(gdp) OVER (PARTITION BY country_name ORDER BY year))::numeric * 100, 2) AS gdp_growth
	FROM cte_gdp)
Select country_name, round(avg(gdp_growth),2) as avg_gdp_growth
from cte_gdp_growth
where gdp_growth is not null
group by country_name
order by avg_gdp_growth desc
limit 5;

--## lowest GDP growth
WITH cte_gdp AS (
    SELECT country_name, year, gdp_in_usd AS gdp
    FROM economic_indicators
    ORDER BY country_name, year
),
cte_gdp_growth as
	(SELECT *,
		ROUND(((gdp - LAG(gdp) OVER (PARTITION BY country_name ORDER BY year)) / LAG(gdp) OVER (PARTITION BY country_name ORDER BY year))::numeric * 100, 2) AS gdp_growth
	FROM cte_gdp)
Select country_name, round(avg(gdp_growth),2) as avg_gdp_growth
from cte_gdp_growth
where gdp_growth is not null
group by country_name
order by avg_gdp_growth
limit 5;

--#CORRELATION BETWEEN GDP PER CAPITA AND DEATHRATE
WITH
cte_income_group as
	(SELECT income_group, year, deathrate, gdp_per_capita_in_usd
	FROM ECONOMIC_INDICATORS
	Where year between 2010 and 2018
	order by income_group, year),
cte2_income_group as
	(select *,
	case when income_group = 'High income: nonOECD' then 'High income'
		 when income_group = 'High income: OECD' then 'High income'
	else income_group end as income_groups
	from cte_income_group)
select income_groups, round(avg(deathrate),2) as avg_deathrate, round(avg(gdp_per_capita_in_usd::numeric),2) as avg_gdp_per_capita
from cte2_income_group
group by income_groups
order by 3 desc;

--#CORRELATION BETWEEN GDP PER CAPITA AND LIFE EXPECTANCY
WITH
cte_income_group as
	(SELECT income_group, year, life_expectancy_in_year, gdp_per_capita_in_usd
	FROM ECONOMIC_INDICATORS
	Where year between 2010 and 2018
	order by income_group, year),
cte2_income_group as
	(select *,
	case when income_group = 'High income: nonOECD' then 'High income'
		 when income_group = 'High income: OECD' then 'High income'
	else income_group end as income_groups
	from cte_income_group)
select income_groups, round(avg(life_expectancy_in_year),2) as avg_ife_expectancy, round(avg(gdp_per_capita_in_usd::numeric),2) as avg_gdp_per_capita
from cte2_income_group
group by income_groups
order by 2 desc;