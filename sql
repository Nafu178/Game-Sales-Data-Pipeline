-- ============================================
-- Query 1: Total Sales by Genre
-- Description: Ranks all genres by total global
-- sales and shows how many games exist per genre.
-- Tables used: fact_sales, dim_game
-- ============================================

SELECT
    dg.genre,
    SUM(fs.global_sales)            AS total_sales,
    COUNT(*)                        AS total_games,
    ROUND(SUM(fs.global_sales) 
          / COUNT(*), 2)            AS avg_sales_per_game
FROM `your_project.vgsales.fact_sales` fs
JOIN `your_project.vgsales.dim_game` dg
    ON fs.game_id = dg.game_id
GROUP BY dg.genre
ORDER BY total_sales DESC

-- ============================================
-- Query 2: Top 10 Publishers by Revenue
-- Description: Ranks top publishers by total
-- global sales and calculates average sales per
-- game to measure quality vs quantity.
-- Tables used: fact_sales, dim_publisher
-- ============================================

SELECT
    dp.publisher,
    SUM(fs.global_sales)            AS total_sales,
    COUNT(*)                        AS total_games,
    ROUND(SUM(fs.global_sales) 
          / COUNT(*), 2)            AS sales_per_game
FROM `your_project.vgsales.fact_sales` fs
JOIN `your_project.vgsales.dim_publisher` dp
    ON fs.publisher_id = dp.publisher_id
GROUP BY dp.publisher
ORDER BY total_sales DESC
LIMIT 10

-- ============================================
-- Query 3: Year Over Year Sales Trend
-- Description: Shows total global sales and
-- average sales per game for each year.
-- Filtered to 2016 and below due to incomplete
-- data in the dataset for years after 2016.
-- Tables used: fact_sales
-- ============================================

SELECT
    fs.year,
    SUM(fs.global_sales)            AS total_sales,
    COUNT(*)                        AS total_games,
    ROUND(SUM(fs.global_sales) 
          / COUNT(*), 2)            AS avg_sales_per_game
FROM `your_project.vgsales.fact_sales` fs
WHERE fs.year <= 2016
GROUP BY fs.year
ORDER BY fs.year ASC

-- ============================================
-- Query 4: Best Selling Game Per Platform
-- Description: Finds the single highest selling
-- game for every platform using ROW_NUMBER()
-- window function inside a CTE.
-- Tables used: fact_sales, dim_game, dim_platform
-- ============================================

WITH ranked_games AS (
    SELECT
        dp.platform,
        dg.name                         AS game_name,
        fs.global_sales,
        ROW_NUMBER() OVER (
            PARTITION BY dp.platform
            ORDER BY fs.global_sales DESC
        )                               AS row_num
    FROM `your_project.vgsales.fact_sales` fs
    JOIN `your_project.vgsales.dim_game` dg
        ON fs.game_id = dg.game_id
    JOIN `your_project.vgsales.dim_platform` dp
        ON fs.platform_id = dp.platform_id
)

SELECT
    platform,
    game_name,
    global_sales
FROM ranked_games
WHERE row_num = 1
ORDER BY global_sales DESC

-- ============================================
-- Query 5: Regional Sales Breakdown
-- Description: Summarises total sales by region
-- and calculates each region's percentage share
-- of total global sales.
-- Tables used: fact_sales
-- ============================================

SELECT
    ROUND(SUM(fs.na_sales), 2)      AS north_america_sales,
    ROUND(SUM(fs.eu_sales), 2)      AS europe_sales,
    ROUND(SUM(fs.jp_sales), 2)      AS japan_sales,
    ROUND(SUM(fs.other_sales), 2)   AS other_sales,
    ROUND(SUM(fs.global_sales), 2)  AS total_global_sales,
    ROUND(SUM(fs.na_sales) 
          / SUM(fs.global_sales) 
          * 100, 2)                 AS na_percentage,
    ROUND(SUM(fs.eu_sales) 
          / SUM(fs.global_sales) 
          * 100, 2)                 AS eu_percentage,
    ROUND(SUM(fs.jp_sales) 
          / SUM(fs.global_sales) 
          * 100, 2)                 AS jp_percentage,
    ROUND(SUM(fs.other_sales) 
          / SUM(fs.global_sales) 
          * 100, 2)                 AS other_percentage
FROM `your_project.vgsales.fact_sales` fs
