--Total Revenue
select * from sales
SELECT 
    SUM(revenue) AS total_revenue
FROM sales;
---Total Units Sold

SELECT 
    SUM(units_sold) AS total_units_sold
FROM sales;

---gross margin %

SELECT 
    ROUND(
        AVG(
            (retail_price - cost_price) * 1.0 /
            NULLIF(retail_price, 0)
        ),
        4
    ) AS gross_margin_percentage
FROM products;



--Revenue by SKU

SELECT 
    s.sku,
    SUM(s.revenue) AS total_revenue
FROM sales s
GROUP BY s.sku
ORDER BY total_revenue DESC;



---Revenue by category
SELECT 
    p.category,
    SUM(s.revenue) AS total_revenue
FROM sales s
JOIN products p 
    ON s.sku = p.sku
GROUP BY p.category
ORDER BY total_revenue DESC;
--Monthly Sales Trends


SELECT 
    DATEFROMPARTS(YEAR(date), MONTH(date), 1) AS month,
    SUM(revenue) AS monthly_revenue
FROM sales
GROUP BY DATEFROMPARTS(YEAR(date), MONTH(date), 1)
ORDER BY month;




SELECT 
    DATEFROMPARTS(YEAR(date), MONTH(date), 1) AS month,
    SUM(units_sold) AS total_units_sold
FROM sales
GROUP BY DATEFROMPARTS(YEAR(date), MONTH(date), 1)
ORDER BY month;


----sell through rate

SELECT 
    p.sku,
    ISNULL(s.units_sold, 0) AS units_sold,
    ISNULL(po.units_received, 0) AS units_received,
    ROUND(
        ISNULL(s.units_sold, 0) * 1.0 /
        NULLIF(ISNULL(po.units_received, 0), 0),
        2
    ) AS sell_through_rate
FROM products p

LEFT JOIN (
    SELECT 
        sku,
        SUM(units_sold) AS units_sold
    FROM sales
    GROUP BY sku
) s 
    ON p.sku = s.sku

LEFT JOIN (
    SELECT 
        sku,
        SUM(units_ordered) AS units_received
    FROM purchase_orders
    GROUP BY sku
) po 
    ON p.sku = po.sku

ORDER BY sell_through_rate DESC;

---stockout deection


SELECT 
    p.sku,
    ISNULL(s.units_sold, 0) AS total_sold,
    ISNULL(po.units_received, 0) AS total_received,
    CASE 
        WHEN ISNULL(s.units_sold, 0) > ISNULL(po.units_received, 0)
        THEN 'Stockout Risk'
        ELSE 'No Stockout'
    END AS stockout_status
FROM products p

LEFT JOIN (
    SELECT 
        sku,
        SUM(units_sold) AS units_sold
    FROM sales
    GROUP BY sku
) s 
    ON p.sku = s.sku

LEFT JOIN (
    SELECT 
        sku,
        SUM(units_ordered) AS units_received
    FROM purchase_orders
    GROUP BY sku
) po 
    ON p.sku = po.sku

ORDER BY stockout_status DESC;

---overstock risk
SELECT 
    i.sku,

    SUM(s.units_sold) AS total_units_sold,

    ROUND(
        SUM(s.units_sold) * 1.0 /
        NULLIF((i.opening_stock + i.closing_stock) / 2.0, 0),
        2
    ) AS stock_turn,

    CASE 
        WHEN 
            SUM(s.units_sold) * 1.0 /
            NULLIF((i.opening_stock + i.closing_stock) / 2.0, 0)
            < 0.5
        THEN 'Overstock'
        ELSE 'Healthy'
    END AS overstock_risk

FROM inventory i
LEFT JOIN sales s
    ON i.sku = s.sku

GROUP BY 
    i.sku,
    i.opening_stock,
    i.closing_stock

ORDER BY stock_turn desc;



----supplier performance 


SELECT 
    AVG(DATEDIFF(DAY, order_date, delivery_date) * 1.0) 
    AS avg_lead_time_days
FROM purchase_orders
WHERE delivery_date IS NOT NULL;




SELECT 
    p.supplier,
    AVG(DATEDIFF(DAY, po.order_date, po.delivery_date) * 1.0) 
        AS avg_lead_time_days
FROM purchase_orders po
JOIN products p 
    ON po.sku = p.sku
WHERE po.delivery_date IS NOT NULL
GROUP BY p.supplier
ORDER BY avg_lead_time_days DESC;

----total unit orderded 
SELECT 
    SUM(units_ordered) AS total_units_ordered
FROM purchase_orders;


---Inventory turnover


SELECT 
    p.sku,
    ISNULL(s.total_sales, 0) AS total_sales,
    ISNULL(i.avg_inventory, 0) AS avg_inventory,
    ROUND(
        ISNULL(s.total_sales, 0) * 1.0 /
        NULLIF(ISNULL(i.avg_inventory, 0), 0),
        2
    ) AS inventory_turnover
FROM products p

LEFT JOIN (
    SELECT 
        sku,
        SUM(units_sold * revenue) AS total_sales
    FROM sales
    GROUP BY sku
) s 
    ON p.sku = s.sku

LEFT JOIN (
    SELECT 
        sku,
        AVG((opening_stock + closing_stock) / 2.0) AS avg_inventory
    FROM inventory
    GROUP BY sku
) i 
    ON p.sku = i.sku

ORDER BY inventory_turnover DESC;


---Top 5 Products by revenue
SELECT *
FROM (
    SELECT 
        sku,
        SUM(revenue) AS revenue,
        RANK() OVER (ORDER BY SUM(revenue) DESC) AS rnk
    FROM sales
    GROUP BY sku
) ranked
WHERE rnk <= 5;




--bottom 5 products by revenue

SELECT *
FROM (
    SELECT 
        sku,
        SUM(revenue) AS revenue,
        RANK() OVER (ORDER BY SUM(revenue) ) AS rnk
    FROM sales
    GROUP BY sku
) ranked
WHERE rnk <= 5;