
 --Data Cleaning 
	select distinct( Item_Fat_Content) from blinkit_data
	update blinkit_data 
	set Item_Fat_Content = case
	when Item_Fat_Content in ('LF','low  fat') then 'Low Fat'
	when Item_Fat_Content='reg' then 'Regular'
	else Item_Fat_Content
	end

--ranking outlet sizes by sales
	select Outlet_Size, 
	SUM(Total_Sales) as total_sales,
	RANK() over (order by sum(Total_Sales) desc) as rank_
	from blinkit_data
	group by Outlet_Size

-- top-selling item type per outlet
	with cte_ as (
	select Outlet_Type as outlet_type,
	Item_Type as item_type,
	cast(SUM(Total_Sales) as decimal(10,2)) as total_sales,
	RANK() over (partition by outlet_type order by sum(total_sales) desc ) as ranking_
	from blinkit_data
	group by Outlet_Type,Item_Type )
	select *
	from cte_
	where ranking_=1 

--percentage contribution of each item to total sales
	with cte_ as(
	select Item_Type,
	cast(SUM(Total_Sales) AS decimal(10,2)) as total_sales
	from blinkit_data
	group by Item_Type )
	select Item_Type,total_sales,
	cast(SUM(total_sales) over() as decimal(10,2)) as total_without_filter,
	concat(cast(total_sales / SUM(total_sales) over() as decimal(10,2) ) , '%')
	from cte_
	
--finding underperforming items(below average)
	SELECT  Item_Type,
	cast(sum(Total_Sales) as decimal(10,2))
	FROM blinkit_data
	group by Item_Type
	having sum(Total_Sales) < (SELECT AVG(Total_Sales) FROM blinkit_data)
	ORDER BY Total_Sales ;

--year over year sales growth
	with cte_ as (
	select Outlet_Establishment_Year as year_,
	SUM(Total_Sales) as total_sales,
	coalesce(LAG(Outlet_Establishment_Year) over(order by Outlet_Establishment_Year asc),0) as prev_year,
	coalesce(LAG(sum(Total_Sales)) over (order by Outlet_Establishment_Year asc),0) as prev_year_sales
	from blinkit_data
	group by Outlet_Establishment_Year )
    select year_,
	total_sales,
	prev_year,
	prev_year_sales,
	cast(total_sales - prev_year_sales AS decimal(10,2) ) as growth
	from cte_

--sales segmentation by item type
	with cte_ as (
	select Item_Type as item_type,
	cast(SUM(Total_Sales) as decimal(10,2)) as total_sales
	from blinkit_data
	group by Item_Type )
	select item_type,
	total_sales,
	case 
	when total_sales >75000 then 'High'
	when total_sales>25000 then 'Medium'
	else 'Low' 
	end as segmentation
	from cte_
	order by total_sales desc

--finding best 5 selling item type
	with cte as (
	select Item_Type as item_type,
	SUM(Total_Sales) as total_sales,
	RANK() over(order by sum(Total_Sales) asc) as ranking
	from blinkit_data
	group by Item_Type)
	select item_type,
	cast(total_sales as decimal(10,2)) as total_sales,
	ranking
	from cte
	where ranking<=5
	
--finding items whose sales are greater than average
	WITH cte AS (
    SELECT Item_Type AS item_type,
           SUM(Total_Sales) AS total_sales
    FROM blinkit_data
    GROUP BY Item_Type
	),
	avg_cte AS (
    SELECT AVG(total_sales) AS general_avg
    FROM cte
	)
	SELECT 
    cte.item_type,
    cte.total_sales,
    avg_cte.general_avg
	FROM cte, avg_cte
	WHERE cte.total_sales > avg_cte.general_avg;
	
	select * from blinkit_data

	
	
	
	  clean up all this queries i will put on portolio project
ChatGPT said:
/* =========================================================
   DATA CLEANING
   ========================================================= */

-- Standardize Item_Fat_Content values
UPDATE blinkit_data
SET Item_Fat_Content =
    CASE
        WHEN Item_Fat_Content IN ('LF', 'low  fat') THEN 'Low Fat'
        WHEN Item_Fat_Content = 'reg' THEN 'Regular'
        ELSE Item_Fat_Content
    END;

-- Review distinct fat content values
SELECT DISTINCT Item_Fat_Content
FROM blinkit_data;


/* =========================================================
   SALES ANALYSIS
   ========================================================= */

-- Rank outlet sizes by total sales
SELECT
    Outlet_Size,
    SUM(Total_Sales) AS total_sales,
    RANK() OVER (ORDER BY SUM(Total_Sales) DESC) AS rank_
FROM blinkit_data
GROUP BY Outlet_Size;


-- Top-selling item type per outlet
WITH outlet_item_sales AS (
    SELECT
        Outlet_Type,
        Item_Type,
        CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS total_sales,
        RANK() OVER (
            PARTITION BY Outlet_Type
            ORDER BY SUM(Total_Sales) DESC
        ) AS rank_
    FROM blinkit_data
    GROUP BY Outlet_Type, Item_Type
)
SELECT
    Outlet_Type,
    Item_Type,
    total_sales
FROM outlet_item_sales
WHERE rank_ = 1;


-- Percentage contribution of each item type to total sales
WITH item_sales AS (
    SELECT
        Item_Type,
        CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS total_sales
    FROM blinkit_data
    GROUP BY Item_Type
)
SELECT
    Item_Type,
    total_sales,
    CAST(SUM(total_sales) OVER () AS DECIMAL(10,2)) AS total_sales_all,
    CONCAT(
        CAST(total_sales / SUM(total_sales) OVER () * 100 AS DECIMAL(5,2)),
        '%'
    ) AS contribution_pct
FROM item_sales;


-- Underperforming item types (below average total sales)
SELECT
    Item_Type,
    CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS total_sales
FROM blinkit_data
GROUP BY Item_Type
HAVING SUM(Total_Sales) <
       (SELECT AVG(Total_Sales) FROM blinkit_data)
ORDER BY total_sales;


-- Year-over-year sales growth
WITH yearly_sales AS (
    SELECT
        Outlet_Establishment_Year AS year_,
        SUM(Total_Sales) AS total_sales,
        LAG(SUM(Total_Sales)) OVER (
            ORDER BY Outlet_Establishment_Year
        ) AS prev_year_sales
    FROM blinkit_data
    GROUP BY Outlet_Establishment_Year
)
SELECT
    year_,
    total_sales,
    COALESCE(prev_year_sales, 0) AS prev_year_sales,
    CAST(total_sales - COALESCE(prev_year_sales, 0) AS DECIMAL(10,2)) AS growth
FROM yearly_sales;


/* =========================================================
   SEGMENTATION & RANKING
   ========================================================= */

-- Sales segmentation by item type
WITH item_sales AS (
    SELECT
        Item_Type,
        CAST(SUM(Total_Sales) AS DECIMAL(10,2)) AS total_sales
    FROM blinkit_data
    GROUP BY Item_Type
)
SELECT
    Item_Type,
    total_sales,
    CASE
        WHEN total_sales > 75000 THEN 'High'
        WHEN total_sales > 25000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_segment
FROM item_sales
ORDER BY total_sales DESC;


-- Top 5 best-selling item types
WITH ranked_items AS (
    SELECT
        Item_Type,
        SUM(Total_Sales) AS total_sales,
        RANK() OVER (ORDER BY SUM(Total_Sales) DESC) AS rank_
    FROM blinkit_data
    GROUP BY Item_Type
)
SELECT
    Item_Type,
    CAST(total_sales AS DECIMAL(10,2)) AS total_sales,
    rank_
FROM ranked_items
WHERE rank_ <= 5;


-- Item types with above-average total sales
WITH item_sales AS (
    SELECT
        Item_Type,
        SUM(Total_Sales) AS total_sales
    FROM blinkit_data
    GROUP BY Item_Type
),
avg_sales AS (
    SELECT AVG(total_sales) AS general_avg
    FROM item_sales
)
SELECT
    i.Item_Type,
    i.total_sales,
    a.general_avg
FROM item_sales i
CROSS JOIN avg_sales a
WHERE i.total_sales > a.general_avg;


/* =========================================================
   RAW DATA (OPTIONAL)
   ========================================================= */

SELECT *
FROM blinkit_data;







No file chosenNo file chosen
ChatGPT can make mistakes. Check important info.
