/* ________DATA QUALITY CHEACK_________*/ 

-- 1:Can we trust revenue and cost values?

select 
sum(case when StandardCost IS NULL then 1 else 0 end) as Null_StandardCost,
sum(case when  StandardCost=0 then 1 else 0 end) as Zero_StandardCost,
sum(case when  ListPrice  IS NULL then 1 else 0 end) as Null_ListPrice,
sum(case when  ListPrice=0 then 1 else 0 end) as Zero_ListPrice
from Adventure_works.DimProduct;

select 
sum(case when TotalProductCost IS NULL then 1 else 0 end) as Null_Procductcost ,
sum(case when TotalProductCost=0 then 1 else 0 end) as Zero_ProductCost,
sum(case when  SalesAmount  IS NULL then 1 else 0 end) as Null_SalesAmoiunt,
sum(case when  SalesAmount=0 then 1 else 0 end) as Zero_SalesAmount
from adventure_works.FactInternetSales;

select 
sum(case when TotalProductCost IS NULL then 1 else 0 end) as Null_Procductcost ,
sum(case when TotalProductCost=0 then 1 else 0 end) as Zero_ProductCost,
sum(case when  SalesAmount  IS NULL then 1 else 0 end) as Null_SalesAmoiunt,
sum(case when  SalesAmount=0 then 1 else 0 end) as Zero_SalesAmount
from adventure_works.FactInternetSales_new;

/* Data Quality Summary: SalesAmount and TotalProductCost contain no missing values across sales transactions. 
Missing pricing and standard cost values are limited to products with no recorded sales 
and therefore do not affect profit, revenue, or sales concentration analyses.*/

-- 2:Could geography labels split revenue and hide concentration risk?

select SalesTerritoryCountry, -- checking for diffrent country names 
count(*) as geography_record
from adventure_works.dimsalesterritory
group by SalesTerritoryCountry;

select geography.SalesTerritoryCountry, -- checking  how geography inconsistency can fragment revenue visibility 
 sum(sales.SalesAmount) as total_regional_sales
from adventure_works.dimsalesterritory as geography
 join adventure_works.FactInternetSales as sales
 on sales.SalesTerritoryKey=geography.SalesTerritoryKey
 group by geography.SalesTerritoryCountry
 order by total_regional_sales desc;
 
select geography.SalesTerritoryCountry, -- checking  how geography inconsistency can fragment revenue visibility 
 sum(sales.SalesAmount) as total_regional_sales
from adventure_works.dimsalesterritory as geography
 join adventure_works.FactInternetSales_new as sales
 on sales.SalesTerritoryKey=geography.SalesTerritoryKey
 group by geography.SalesTerritoryCountry
 order by total_regional_sales desc;
 
 /* Data Quality Summary: I identified inconsistent country naming, where the same country appeared under multiple labels. 
 This fragmented revenue across multiple categories, understating geographic concentration risk. 
 Standardizing country names ensured accurate regional revenue reporting and concentration analysis. */
 
 -- 3:Is our time data safe to use for trend comparison?

select distinct year(ShipDate) as complete_year , -- Identify complete vs incomplete years for trend analysis
  count(distinct(MONTH (ShipDate))) as months,
   case 
		when count(distinct(month( ShipDate))) = 12 then 'complete'
		else 'incomplete' end as year_status 
from adventure_works.FactInternetSales
group by YEAR(ShipDate);

select distinct year(ShipDate) as complete_year , -- Identify complete vs incomplete years for trend analysis
  count(distinct(MONTH (ShipDate))) as months,
   case 
		when count(distinct(month( ShipDate))) = 12 then 'complete'
		else 'incomplete' end as year_status 
from adventure_works.FactInternetSales_new
group by YEAR(ShipDate);

/* Data Quality Summary: 2011–2012 contain full 12 months of data and are safe for trend analysis,
while 2010,2014 is incomplete and excluded to avoid partial-period bias.