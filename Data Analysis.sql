use Adventure_works;

-- 1. Lookup the productname from the Product sheet to Sales sheet. 
SELECT prod.productkey,prod.EnglishProductName,sum(sales.salesamount) AS "Total Sales"
FROM dimproduct AS prod JOIN factinternetsales_new AS sales
ON sales.productkey = prod.productkey
GROUP BY prod.ProductKey,prod.EnglishProductName
ORDER BY prod.productkey ASC;

-- 2. Lookup the Customerfullname from the Customer and Unit Price from Product sheet to Sales sheet. 
SELECT cust.customerkey,concat(cust.firstname ," ",cust.MiddleName," " ,cust.lastname) AS "Full Name" ,
product.EnglishProductName, sales.unitprice 
FROM dimcustomer AS cust JOIN factinternetsales_new AS sales
ON cust.CustomerKey = sales.CustomerKey JOIN dimproduct AS product
ON sales.ProductKey = product.Productkey;

-- 3.Calculate the Productioncost uning the columns(unit cost ,order quantity) 
SELECT ProductStandardCost , OrderQuantity ,
    (ProductStandardCost * OrderQuantity) AS ProductionCost
FROM factinternetsales_new;


-- 4.Calculate the SalesAmount using the columns(unit cost ,order quantity)
SELECT UnitPrice , OrderQuantity , UnitPriceDiscountPct ,
    (UnitPrice * OrderQuantity * (1-UnitPriceDiscountPct)) AS SalesAmount
FROM factinternetsales_new;


-- 5. Calculate the profit.
SELECT concat(round(SUM( (UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) - (ProductStandardCost * OrderQuantity))/1000000,2)," M") As Total_Profit
FROM factinternetsales_new;

-- 6. Month wise Sales
SELECT monthname(orderDate) AS Month,concat(round(sum(salesamount)/1000000,2)," M") AS Sales
FROM factinternetsales_new
GROUP BY monthname(orderdate) 
ORDER BY sum(SalesAmount) DESC;

-- 7. Year wise Sales
SELECT year(orderdate) AS Year,concat(round(sum(salesamount)/1000000,2)," M") AS Sales
FROM factinternetsales_new
GROUP BY Year
ORDER BY Year ASC;

-- 8. Quarter wise Sales
SELECT concat("Q-",Quarter(orderdate)) AS Quarter,concat(round(sum(salesamount)/1000000,2)," M") AS Sales
FROM factinternetsales_new
GROUP BY Quarter
ORDER BY Quarter ASC;


-- 9. KPI ( total sales , order quantity , total profit , Distinct Orders )
CREATE VIEW KPI AS 
SELECT concat(round(sum(SalesAmount)/1000000,2)," M") AS "Total Sales",
concat(round(count(OrderQuantity)/1000,2)," K") AS "Order Quantity" ,
concat(round(sum((UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) - (ProductStandardCost * OrderQuantity))/1000000,2)," M") AS "Total Profit",
concat(round(count(distinct salesordernumber)/1000,2)," K") AS "Distinct Orders"
FROM factinternetsales_new;
 
select * from KPI;


-- 10. Customer wise Data using Stored Procedure
Delimiter ==
CREATE PROCEDURE CustInfo( in A int)
BEGIN
SELECT cust.CustomerKey,concat(cust.firstname ," ",cust.MiddleName," " ,cust.lastname) AS "Full Name",
sum(sales.salesamount),count(distinct(sales.orderquantity))
FROM dimcustomer AS cust JOIN factinternetsales_new AS sales
ON cust.CustomerKey = sales.CustomerKey
WHERE cust.CustomerKey = A
GROUP BY cust.CustomerKey,concat(cust.firstname ," ",cust.MiddleName," " ,cust.lastname);
END ==
delimiter ;

CALL custinfo(11002);