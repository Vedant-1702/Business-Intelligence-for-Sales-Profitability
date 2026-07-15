/*Country Standardization*/
-- Derived Country_Clean via case- and space-insensitive pattern matching to normalize
-- equivalent country values while preserving the original attribute.

USE adventure_works;

CREATE VIEW vw_dimgeography_clean
AS
  SELECT SalesTerritoryKey,
         SalesTerritoryCountry AS raw_county,
         CASE
           WHEN Upper(Replace(SalesTerritoryCountry, ' ', '')) LIKE
                '%UNITEDSTATES%'
                 OR Upper(Replace(SalesTerritoryCountry, ' ', '')) IN (
                    'US', 'USA', 'U.S.' ) 
                    THEN 'United States'
                    
           WHEN Upper(Replace(SalesTerritoryCountry, ' ', '')) LIKE
                '%UNITEDKINGDOM%'
                 OR Upper(Replace(SalesTerritoryCountry, ' ', '')) IN ( 'UK',
                    'U.K.' )
					THEN 'United Kingdom'
                    
           WHEN Upper(Replace(SalesTerritoryCountry, ' ', '')) LIKE
                '%AUSTRALIA%'
                 OR Upper(Replace(SalesTerritoryCountry, ' ', '')) IN
                    ( 'AUS', 'AUS.' ) 
                    THEN 'Australia'
                    
           WHEN Upper(Replace(SalesTerritoryCountry, ' ', '')) LIKE
                '%CANADA%'
                 OR Upper(Replace(SalesTerritoryCountry, ' ', '')) IN
                    ( 'CAN', 'CAN.' ) 
                    THEN 'Canada'
                    
           WHEN Upper(Replace(SalesTerritoryCountry, ' ', '')) LIKE
                '%FRANCE%'
                 OR Upper(Replace(SalesTerritoryCountry, ' ', '')) IN ( 'FR',
                    'FR.' )
					THEN 'France'
                    
           WHEN Upper(Replace(SalesTerritoryCountry, ' ', '')) LIKE
                '%GERMANY%'
                 OR Upper(Replace(SalesTerritoryCountry, ' ', '')) IN
                    ( 'GER', 'GER.' ) 
                    THEN 'Germany'
         END
         AS Country_clean
  FROM   dimsalesterritory;
  
  /*Time Completeness Validation & profit computaion */
-- Derived sales year view  via CTE's funtion and view to extract complete year for the analysis
-- Prepared row-level profit computation by validating sales and cost fields

CREATE VIEW vw_fact_sales_analysis
AS
  WITH yearcompleteness
       AS 
       (
          SELECT Year(shipdate) AS SalesYear,
                 Count(DISTINCT Month(shipdate)) AS MonthCount,
                 CASE
                   WHEN Count(DISTINCT Month(shipdate)) = 12 
                   THEN 1
                   ELSE 0
                 END AS IsCompleteYear
           FROM   adventure_works.factinternetsales
           GROUP BY Year(shipdate))
  SELECT sales.salesordernumber,
         sales.salesorderlinenumber,
         sales.productkey,
         sales.customerkey,
         sales.salesterritorykey,
         sales.orderdate,
         sales.shipdate,
         Year(sales.shipdate)  AS SalesYear,
         Month(sales.shipdate) AS SalesMonth,
         prodc.englishproductcategoryname,
         subc.englishproductsubcategoryname,
         prod.englishproductname,
         sales.orderquantity,
         sales.unitprice,
         sales.discountamount,
         sales.salesamount,
         sales.totalproductcost,
         CASE
           WHEN sales.salesamount IS NOT NULL
                AND sales.totalproductcost IS NOT NULL 
                THEN
           sales.salesamount - sales.totalproductcost
           ELSE 
           NULL
         END AS Profit,
         complete.iscompleteyear,
         1 AS OrderLineCount
  FROM   adventure_works.factinternetsales AS sales
         JOIN yearcompleteness AS complete
           ON Year(sales.shipdate) = complete.salesyear
         JOIN adventure_works.dimproduct AS prod
           ON prod.productkey = sales.productkey
         JOIN adventure_works.dimproductsubcategory AS subc
           ON subc.productsubcategorykey = prod.productsubcategorykey
         JOIN adventure_works.dimproductcategory AS prodc
           ON prodc.productcategorykey = subc.productcategorykey
  WHERE  complete.iscompleteyear = 1;
  
  /* Customer view */
CREATE VIEW vw_dimcustomers
AS
  SELECT customerkey,
         datefirstpurchase,
         Concat(Trim(firstname), ' ', Trim(lastname)) AS Fullname,
         geographykey
  FROM   adventure_works.dimcustomer 