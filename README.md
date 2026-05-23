# Game Sales Data Pipeline

A end-to-end data analytics project built using Python, BigQuery, and Looker Studio — analysing global video game sales trends from 1980 to 2016.

---

## Project Overview

This project simulates a real-world data pipeline where raw sales data is cleaned, modelled, stored in a cloud database, and visualised in an interactive dashboard.

The dataset used is the [Video Game Sales dataset](https://www.kaggle.com/datasets/gregorut/videogamesales) from Kaggle, containing ~16,000 rows of game sales data across platforms, genres, and publishers.

---

## Tools & Technologies

| Tool | Purpose |
|---|---|
| Python (Pandas) | Data cleaning and data modelling |
| Google BigQuery | Cloud data warehouse |
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

## Step 5 — Looker Studio Dashboard

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
3. **Quality over quantity** — Nintendo outearns EA despite releasing half the number of games
4. **Wii Sports is an outlier** — Its $82.74M sales figure is inflated by Nintendo Wii console bundling
5. **Western markets dominate** — NA and EU sales consistently outperform JP and other regions

---

## Dataset

- Source: [Kaggle — Video Game Sales](https://www.kaggle.com/datasets/gregorut/videogamesales)
- Rows: ~16,000 games
- Period: 1980 – 2016
- Columns: Name, Platform, Year, Genre, Publisher, NA_Sales, EU_Sales, JP_Sales, Other_Sales, Global_Sales
