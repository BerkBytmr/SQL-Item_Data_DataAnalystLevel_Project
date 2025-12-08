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

	
	
	
	