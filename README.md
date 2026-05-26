# Game Sales Data Pipeline

> An end-to-end data analytics project by [@Nafu178](https://github.com/Nafu178) — analysing global video game sales trends from 1980 to 2016 using Python, BigQuery, and Looker Studio.

---

## Project Overview

This project simulates a real-world data pipeline where raw sales data is cleaned, modelled, stored in a cloud database, and queried using SQL.

The dataset used is the [Video Game Sales dataset](https://www.kaggle.com/datasets/gregorut/videogamesales) from Kaggle, containing ~16,000 rows of game sales data across platforms, genres, and publishers.

---

## Tools & Technologies

| Tool | Purpose |
|---|---|
| Python (Pandas) | Data cleaning and data modelling |
| Google BigQuery | Cloud data warehouse |
| SQL | Data analysis and business insights |
| Looker Studio | Dashboard and visualisation |
| Google Colab | Development environment |

---

## Project Pipeline

```
Raw CSV (16,000 rows)
      ↓
Data Cleaning (Python / Pandas)
      ↓
Exploratory Data Analysis (EDA)
      ↓
Data Modelling — Star Schema
      ↓
BigQuery — Cloud Database
      ↓
SQL Analysis — 5 Business Queries
      ↓
Looker Studio — Dashboard
```

---

## Step 1 — Data Cleaning

Raw data was loaded and cleaned using Pandas:

- Dropped rows with missing `Year` values — year is essential for trend analysis
- Filled missing `Publisher` values with `'Unknown'` to retain sales data
- Converted `Year` from float to integer
- Removed duplicate rows

```python
df = df.dropna(subset=['Year'])
df['Publisher'] = df['Publisher'].fillna('Unknown')
df['Year'] = df['Year'].astype(int)
df = df.drop_duplicates()
```

---

## Step 2 — Exploratory Data Analysis (EDA)

Five business questions were explored:

| Question | Key Finding |
|---|---|
| Which platform has the most games? | DS dominated game releases |
| Which genre sells the most globally? | Action games lead in total sales |
| Which publisher performs best? | Nintendo earns most despite releasing fewer games than EA |
| How did sales trend over the years? | Sales peaked in 2008 at $678.90M — the Wii/PS3/Xbox 360 era |
| What are the top 10 best-selling games? | Wii Sports leads at $82.74M — largely due to console bundling |

**Notable insight:** Nintendo released 696 games vs Electronic Arts' 1,339 — yet generated 63% more revenue. Volume does not equal success.

---

## Step 3 — Data Modelling (Star Schema)

The flat table was restructured into a proper star schema with 1 fact table and 3 dimension tables.

```
dim_game ————————→ fact_sales ←———————— dim_platform
                        ↑
                   dim_publisher
```

### dim_game
| Column | Type | Description |
|---|---|---|
| game_id | INT | Primary key |
| name | STRING | Game title |
| genre | STRING | Game genre |

### dim_platform
| Column | Type | Description |
|---|---|---|
| platform_id | INT | Primary key |
| platform | STRING | Platform name |

### dim_publisher
| Column | Type | Description |
|---|---|---|
| publisher_id | INT | Primary key |
| publisher | STRING | Publisher name |

### fact_sales
| Column | Type | Description |
|---|---|---|
| game_id | INT | Foreign key → dim_game |
| platform_id | INT | Foreign key → dim_platform |
| publisher_id | INT | Foreign key → dim_publisher |
| year | INT | Release year |
| na_sales | FLOAT | North America sales (millions) |
| eu_sales | FLOAT | Europe sales (millions) |
| jp_sales | FLOAT | Japan sales (millions) |
| other_sales | FLOAT | Other regions sales (millions) |
| global_sales | FLOAT | Total global sales (millions) |

---

## Step 4 — BigQuery Upload

All 4 tables were pushed to Google BigQuery using the Python BigQuery client:

```python
from google.cloud import bigquery

client = bigquery.Client(project=project_id)

tables = {
    'dim_game': dim_game,
    'dim_platform': dim_platform,
    'dim_publisher': dim_publisher,
    'fact_sales': fact_sales
}

for table_name, df_table in tables.items():
    table_id = f"{project_id}.vgsales.{table_name}"
    job = client.load_table_from_dataframe(df_table, table_id,
          job_config=bigquery.LoadJobConfig(write_disposition="WRITE_TRUNCATE"))
    job.result()
```

---

## Step 5 — SQL Analysis

Five business queries were written directly on the BigQuery star schema. Full query files are in the [`sql/`](./sql) folder.

### Query 1 — Total Sales by Genre
`sql/01_sales_by_genre.sql`

| Genre | Total Sales (M) | Total Games |
|---|---|---|
| Action | 1722.88 | 3253 |
| Sports | 1309.24 | 2304 |
| Shooter | 1026.20 | 1282 |
| Role-Playing | 923.84 | 1471 |
| Platform | 829.15 | 876 |

> Platform games average $0.95M per game — nearly double Action's $0.53M average. Fewer games, higher quality hits.

---

### Query 2 — Top 10 Publishers by Revenue
`sql/02_top_publishers.sql`

| Publisher | Total Sales (M) | Games Released | Sales per Game |
|---|---|---|---|
| Nintendo | 1784.43 | 696 | 2.56 |
| Electronic Arts | 1093.39 | 1339 | 0.82 |
| Activision | 721.41 | 966 | 0.75 |
| Sony Computer Entertainment | 607.28 | 682 | 0.89 |
| Ubisoft | 473.54 | 918 | 0.52 |

> Nintendo's $2.56M average sales per game is nearly 3x the industry average — demonstrating that brand strength consistently outperforms volume-based strategies.

---

### Query 3 — Year Over Year Sales Trend
`sql/03_yearly_trend.sql`

| Year | Total Sales (M) | Total Games |
|---|---|---|
| 2006 | 521.04 | 1008 |
| 2007 | 611.13 | 1202 |
| **2008** | **678.90** | **1428** |
| 2009 | 667.30 | 1431 |
| 2010 | 600.45 | 1259 |

> Filtered to 2016 and below — post-2016 data is incomplete in the dataset and would misrepresent actual industry trends.

---

### Query 4 — Best Selling Game Per Platform
`sql/04_best_game_per_platform.sql`

Uses `ROW_NUMBER()` window function with `PARTITION BY` inside a CTE to find the top game per platform.

| Platform | Best Selling Game | Global Sales (M) |
|---|---|---|
| Wii | Wii Sports | 82.74 |
| NES | Super Mario Bros. | 40.24 |
| GB | Pokemon Red/Pokemon Blue | 31.37 |
| DS | New Super Mario Bros. | 30.01 |
| X360 | Kinect Adventures! | 21.82 |

> Wii Sports and Kinect Adventures are outliers — both were bundled with their respective hardware, inflating their sales figures.

---

### Query 5 — Regional Sales Breakdown
`sql/05_regional_breakdown.sql`

| Region | Total Sales (M) | Percentage |
|---|---|---|
| North America | 4333.43 | 49.13% |
| Europe | 2409.12 | 27.31% |
| Japan | 1284.30 | 14.56% |
| Other | 789.01 | 8.95% |
| **Total** | **8820.36** | **100%** |

> North America accounts for nearly half of all global video game sales — making it the single most critical market for any publisher's commercial success.

---

## Step 6 — Looker Studio Dashboard

The BigQuery dataset was connected to Looker Studio where all 4 tables were blended using their respective IDs. The dashboard includes:

- Top 10 best-selling games of all time
- Global sales by genre
- Sales trend over years (line chart)
- Top 10 publishers by revenue
- Platform game count

---

## Key Business Insights

1. **Action is king** — Action games generate the most global revenue across all platforms
2. **2008 was the golden year** — Global sales peaked at $678.90M driven by the Wii, PS3, and Xbox 360
3. **Quality over quantity** — Nintendo outearns EA despite releasing half the number of games, averaging $2.56M per game vs EA's $0.82M
4. **Bundling distorts rankings** — Wii Sports ($82.74M) and Kinect Adventures ($21.82M) are outliers inflated by console bundling
5. **Western markets dominate** — North America alone accounts for 49.13% of all global game sales
6. **Market saturation** — Average sales per game dropped from $4.32M in 1989 to $0.47M by 2009 as more publishers flooded the market

---

## Repository Structure

```
game-sales-data-pipeline/
├── README.md
├── Game_Sales_&_Player_Trend_Analysis.ipynb
└── sql/
    ├── 01_sales_by_genre.sql
    ├── 02_top_publishers.sql
    ├── 03_yearly_trend.sql
    ├── 04_best_game_per_platform.sql
    └── 05_regional_breakdown.sql
```

---

## Dataset

- **Source:** [Kaggle — Video Game Sales](https://www.kaggle.com/datasets/gregorut/videogamesales)
- **Rows:** ~16,000 games
- **Period:** 1980 – 2016
- **Columns:** Name, Platform, Year, Genre, Publisher, NA_Sales, EU_Sales, JP_Sales, Other_Sales, Global_Sales

---

*Built by [@Nafu178](https://github.com/Nafu178)*
