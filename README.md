# Retail-Analytical-Project

Retail analytics  — explanation and narrative
1) Data exploration and KPI analysis
Key metrics calculated
 used SQL to compute the main KPIs, and surfaced them visually in Power BI.
 Here’s how each metric was derived and why it matters:
Total Revenue


SQL:

 SELECT SUM(revenue) AS total_revenue FROM sales;
DAX:
Total Revenue1 = SUM(sales[revenue])


Business meaning: total money earned from all sold units; baseline of business size.




Total Units Sold


SQL:

 SELECT SUM(units_sold) AS total_units_sold FROM sales;
DAX:
Total Units Sold = SUM(sales[units_sold])


Shows volume demand; also used in ratio metrics below.


Gross margin %


SQL (matches DAX’s average-of-product margins):

 SELECT ROUND(
    AVG(
        (retail_price - cost_price) * 1.0 /
        NULLIF(retail_price, 0)
    ), 4
) AS gross_margin_percentage
FROM products;


DAX:
Gross Margin % =
AVERAGEX(
    products,
    DIVIDE(
        products[retail_price] - products[cost_price],
        products[retail_price]
    )
)

Explains profitability per unit—how much of retail price stays after cost. Averaging per product gives an overall view of product-level margins.


On the dashboard this appears with a percent card.


Revenue by SKU


SQL:

 SELECT s.sku, SUM(s.revenue) AS total_revenue
FROM sales s
GROUP BY s.sku
ORDER BY total_revenue DESC;
Identifies best-selling items. Plotted as a bar chart in  Sales Overview section (Revenue by SKU).


Revenue by Category


SQL joining products and sales:

 SELECT p.category, SUM(s.revenue) AS total_revenue
FROM sales s
JOIN products p ON s.sku = p.sku
GROUP BY p.category
ORDER BY total_revenue DESC;


Useful to see broader product-group performance; can drive assortment decisions.


Monthly Sales Trends — value and volume


SQL Server version using month‑start date:

 SELECT DATEFROMPARTS(YEAR(date), MONTH(date), 1) AS month,
       SUM(revenue) AS monthly_revenue
FROM sales
GROUP BY DATEFROMPARTS(YEAR(date), MONTH(date), 1)
ORDER BY month;

 SELECT DATEFROMPARTS(YEAR(date), MONTH(date), 1) AS month,
       SUM(units_sold) AS total_units_sold
FROM sales
GROUP BY DATEFROMPARTS(YEAR(date), MONTH(date), 1)
ORDER BY month;


Plotted as line charts in the Demand Forecast section for trend visibility.


Shows seasonality or growth patterns over time.


Sell-through rate


SQL:

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
    SELECT sku, SUM(units_sold) AS units_sold
    FROM sales
    GROUP BY sku
) s ON p.sku = s.sku
LEFT JOIN (
    SELECT sku, SUM(units_ordered) AS units_received
    FROM purchase_orders
    GROUP BY sku
) po ON p.sku = po.sku
ORDER BY sell_through_rate DESC;
DAX:
Latest Stock =
CALCULATE(
    SUM(inventory[closing_stock]),
    LASTDATE(inventory[date])
)

Sell Through =
DIVIDE(
    [Total Units Sold],
    [Total Units Sold] + [Latest Stock]
)









Measures how much purchased stock was actually sold: units sold ÷ units received.


High values indicate strong sell‑through; low values suggest overbuying or slow-moving products.


Stock turns / Overstock risk


Using inventory columns opening_stock and closing_stock for average inventory:

 SELECT
    i.sku,
    SUM(s.units_sold) AS total_units_sold,
    ROUND(
        SUM(s.units_sold) * 1.0 /
        NULLIF((i.opening_stock + i.closing_stock) / 2.0, 0),
        2
    ) AS stock_turn,
    CASE
        WHEN SUM(s.units_sold) * 1.0 /
             NULLIF((i.opening_stock + i.closing_stock) / 2.0, 0) < 0.5
        THEN 'Overstock'
        ELSE 'Healthy'
    END AS overstock_risk
FROM inventory i
LEFT JOIN sales s ON i.sku = s.sku
GROUP BY i.sku, i.opening_stock, i.closing_stock
ORDER BY stock_turn DESC;

DAX:
Stock Turns =
DIVIDE(
    [Total Units Sold],
    [Latest Stock]
)




Overstock Risk = IF( [Stock Turns] < 0.5, "Overstock", "Healthy" )





Stock turn = units sold ÷ average inventory. Uses a standard inventory efficiency formula.


Lower than 0.5 flagged as overstock risk, visible in Inventory Insights page.


Supplier performance — lead time


Overall average or per supplier:

 SELECT supplier,
       AVG(DATEDIFF(DAY, order_date, delivery_date) * 1.0) AS avg_lead_time_days
FROM purchase_orders
WHERE delivery_date IS NOT NULL
GROUP BY supplier
ORDER BY avg_lead_time_days DESC;

DAX:
Lead Time (Days) =
AVERAGEX(
    purchase_orders,
    DATEDIFF(
        purchase_orders[order_date],
        purchase_orders[delivery_date],
        DAY
    )
)


Shows how long suppliers take to deliver purchases. High values signal slow supply or a risk of stockouts; low values can be an opportunity.


Total units ordered


SQL:

 SELECT SUM(units_ordered) AS total_units_ordered
FROM purchase_orders;
DAX:
Total Units Ordered =SUM(purchase_orders[units_ordered])
Useful to compare against units sold; also appears in supplier performance visuals or as a KPI card.


Top and bottom products


Top 5 by revenue:

 SELECT *
FROM (
    SELECT sku, SUM(revenue) AS revenue,
           RANK() OVER (ORDER BY SUM(revenue) DESC) AS rnk
    FROM sales
    GROUP BY sku
) ranked
WHERE rnk <= 5;


Bottom 5 by revenue:

 SELECT *
FROM (
    SELECT sku, SUM(revenue) AS revenue,
           RANK() OVER (ORDER BY SUM(revenue)) AS rnk
    FROM sales
    GROUP BY sku
) ranked
WHERE rnk <= 5;


These identify best- and worst-performing SKUs.



How this meets the KPI analysis requirement
Calculated all requested metrics: sell‑through, gross margin, stock turns, revenue trends, supplier lead times.


Identified best/worst products using revenue ranks and sell‑through or stock‑turn measures.


Displayed as cards, charts, and tables on the dashboard.



2) Identify best- and worst-performing products and explain why
Best-performing
Top SKUs by revenue (from SQL ranking) and usually also high sell‑through and decent stock turn.


E.g., SKUs appearing at the far left of Revenue by SKU chart.


Reasoning: strong customer demand; possibly well-priced or well-marketed products; good supply planning.


Worst-performing
Bottom SKUs by revenue, low sell‑through, or very low stock turn.


In the Inventory Insights table, SKUs with sell‑through near zero or stock turn < 0.5 flagged as overstock risk.


Reasoning: overstocked, low demand, poor purchasing decisions, slow-moving seasonal items, or mismatched pricing.


What to say in the assignment: show a few specific SKU examples from the dashboard/tables, then connect their KPI values to business implications.

3) Inventory insights
Stockouts and potential impact
Detection: compared total units sold vs total units received per SKU.


SQL flagged SKUs where sold > received as Stockout Risk.


Those SKUs likely experienced stockouts or shortage periods.


Potential impact:


Lost sales volume and revenue for those SKUs.


Estimate lost units: difference between sold and received, or weighted by price.


Can quantify on data: {sold} - {received} for each flagged SKU as potential units that could not be fulfilled if the logic holds.


Overstock risks
Detection: stock turn < 0.5 using average inventory formula.


Impact: high carrying costs, capital tied up, risk of obsolescence.


Inventory table shows multiple SKUs below threshold; these should be reviewed for markdowns or purchase cuts.


Practical actions
For stockouts:


Increase safety stock or reorder earlier for SKUs with frequent stockout risk.


Work with suppliers to reduce lead time or increase batch sizes.


Use forecast to align purchases with demand spikes.


For overstock:


Run promotions or bundles to clear slow-moving SKUs.


Reduce replenishment or discontinue weak products.


Reallocate shelf space or storage to high-turn products.



4) Forecasting
Simple demand forecast approach
Used historical monthly units sold trend; displayed as a line chart with forecast for next 3 months.


In Power BI, forecast feature from the Analytics pane can be applied to a time-based line chart when the visual is selected


Assumptions:


Past pattern is a reasonable indicator of near-term future (no sudden market shock).


Seasonality and existing trend captured in the line series; limited to short horizon.


Works best for top products or categories with stable demand history.


Why this method
Quick, no extra tooling needed; good for small set of top products.


Gives a directional estimate to plan procurement and prevent stockouts.


Can be refined later with more advanced models if more data or time.



5) Supplier performance
Evaluation
Average lead time calculated per supplier using delivery and order dates; shown in a bar chart.


Longer lead times = higher supply risk; may cause stockouts if not planned properly.


Shorter lead times and high units ordered suggest reliable or primary suppliers.


Risks or opportunities
Risks: suppliers with high average lead time or inconsistent delivery might delay product availability.


Opportunities:


Negotiate better terms or reduced lead time with faster suppliers.


Consolidate orders with reliable suppliers.


Use lead‑time data to define reorder points and safety stock.



6) Executive summary 


Executive Summary
Objective: Provide actionable retail analytics using sales, inventory, products, and purchase order data to improve revenue, inventory efficiency, and supplier performance.
Key insights
Strong performers


A small set of SKUs accounts for the majority of revenue; these also tend to have higher sell‑through rates and healthier stock turns.


These should be prioritized for restocking, promotions, and marketing focus.


Stockout risk identified


Several SKUs show total units sold exceeding units received, implying stockout risk and possible lost sales.
immediate action: adjust ordering schedule or quantities and collaborate with suppliers to shorten lead time for these SKUs.


Overstock risk flagged


SKUs with stock turns below 0.5 indicate slow-moving inventory.


Holding these raises carrying costs; recommend discounts, bundle deals, or revised purchasing plans.


Supplier performance varies


Average lead time differs significantly by supplier; long lead times are a potential bottleneck.


Consider renegotiating terms or shifting orders toward suppliers with better track records.


Short‑term forecast supports planning


A simple month‑level forecast using historical units sold highlights expected demand for the next three months.


This can guide order quantities and timing to balance stock availability with holding cost.


Recommendations
Prioritize top SKUs for stock availability and promotions; ensure reorder points align with forecasted demand.


Address slow-movers through markdowns or reduced future orders and possibly remove underperforming products.


Improve supplier management by targeting a shorter, more consistent lead time; potentially onboard new suppliers or adjust mix.


Use forecasting consistently for purchase planning; refine with more data or more advanced models over time.



