# E-Commerce Executive Analytics

> **Revenue grew 138% year over year, but estimated profit margin fell 1.15 pp. The main driver: freight cost per item rose 6% while item prices stayed flat.**

🇹🇷 [Türkçe README](README.tr.md)

## Business problem

How are the company's sales, profitability and customer performance evolving, and what is behind any change in margin? This is an end-to-end analyst project: raw data, SQL modeling, margin driver analysis, a Tableau dashboard and a one-page executive summary.

## Dashboard
<img width="1449" height="823" alt="Ekran Resmi 2026-10-04 01 34 55" src="https://github.com/user-attachments/assets/ee208536-c062-47f2-8151-2705629d3afb" />

<img width="1449" height="823" alt="Ekran Resmi 2026-10-04 01 37 50" src="https://github.com/user-attachments/assets/c1526b5c-f3ac-4532-8497-f5bcadf4ab72" />
<img width="1449" height="823" alt="Ekran Resmi 2026-10-04 01 38 25" src="https://github.com/user-attachments/assets/5cb24e86-dfe1-4376-97a1-21f114c98f0a" />


The Tableau dashboard (built from CSV exports of the SQL views) tells the story in three charts:

1. **Revenue and margin trend (Jan 2017 – Aug 2018):** revenue climbs steadily while monthly margin falls from about 25% to about 21–22%.
2. **Cost structure (Jan–Aug 2017 vs Jan–Aug 2018):** freight rises from 16.04% to 17.06% of revenue, and the margin falls from 22.76% to 21.61%.
3. **Freight per item:** BRL 19.32 → 20.48 (+6%) while the average item price stayed flat (120.46 → 120.08). This is the main driver of the margin decline.

## Dataset

[Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle): about 100K orders across 9 tables. See `data/README.md` for download steps.

**Analysis window:** Jan 2017 – Aug 2018 (2016 is too sparse, and data after Aug 2018 is incomplete). Canceled and unavailable orders are excluded. YoY compares **Jan–Aug 2018 vs Jan–Aug 2017**.

## Key findings (Jan–Aug 2018 vs Jan–Aug 2017)

| Metric | 2017 | 2018 | Change |
|---|---|---|---|
| Revenue (BRL) | 3.08M | 7.34M | +138.3% |
| Estimated profit (BRL) | 701K | 1.59M | +126.3% |
| Profit margin | 22.76% | 21.61% | **-1.15 pp** |
| Orders | 22,562 | 53,530 | +137.3% |
| AOV (BRL) | 136.55 | 137.14 | +0.4% |
| Customers | 21,936 | 52,336 | +138.6% |

1. **Growth is volume-driven.** Orders more than doubled, while basket value did not move.
2. **Margin erosion is mainly freight.** Freight per item rose 6.0% (BRL 19.32 → 20.48) while the average item price was flat (120.46 → 120.08). Freight went from 16.04% to 17.06% of revenue (+1.02 pp). If the company bears the full freight cost (my base assumption), this explains about 89% of the decline. The COGS share moved only +0.13 pp.
3. **It is not a geographic mix problem.** Margin fell in all five regions (Southeast -0.8 pp, South -1.7, Northeast -2.4, Central-West -2.2, North -2.8). The regional mix effect was slightly positive (+0.13 pp).
4. **Growth is slowing.** Monthly YoY revenue growth fell from +687% (Jan) to +49% (Aug). This is largely a low-base effect (only 800 orders in Jan 2017). Monthly orders in 2018 are flat at 6–7K.
5. **Most of the margin erosion happened during 2017.** Monthly margin was 24.9% in Jan 2017 and about 21.6% by Aug 2017. In 2018 it stabilized around 21–22%.

Full write-up: [`docs/executive_summary.md`](docs/executive_summary.md)

## Assumptions and limitations (important)

Olist has **no cost data**, so profit is an **estimate**:

`profit = price − price × category_cogs_rate − freight_value × freight_absorbed_share`

- COGS rates per category are my own assumptions (`sql/02_staging/01_cost_assumptions.sql`). Categories without a specific rate use a 65% default.
- `freight_value` is real data, but it is the freight charged to the customer. Treating it as a company cost is an assumption.
- All parameters live in the `cost_parameters` table, so scenarios can be re-run.

**Sensitivity analysis**

| Scenario | Margin 2017 | Margin 2018 | Change |
|---|---|---|---|
| Freight 100% borne by company (base) | 22.76% | 21.61% | -1.15 pp |
| Freight 50% borne by company | 30.78% | 30.14% | -0.64 pp |

Margin levels depend on the assumptions. The direction of the change and its main driver (freight per item) do not: freight explains roughly 80–89% of the decline in both scenarios.

## Methodology

- **SQL (PostgreSQL):** CTEs, window functions (`LAG`, `RANK`, `DENSE_RANK`, `NTILE`, running sums), complex JOINs and views. Business rules are defined once, in staging views.
- **Margin bridge:** the margin change is split into a **mix effect** (shift between categories/regions) and a **rate effect** (margin change inside each category/region).
- **Data quality:** reviews are deduplicated to one per order (547 orders had several) so revenue is not double counted. Customers are identified by `customer_unique_id`.
- **Additional SQL analyses:** product ranking, regional performance, RFM customer segmentation and delivery vs review scores are in `sql/03_analysis`.
- **Dashboard:** Tableau, fed by CSV exports of the SQL views.

## Repository structure

```
sql/01_schema      tables, indexes, data quality checks
sql/02_staging     cost assumptions, clean views
sql/03_analysis    monthly revenue, YoY, AOV, profit, ranking, regions, RFM, delivery, margin bridge, freight driver
sql/04_bi_views    views exported to Tableau
python/            load_data.py, export_views.py
docs/              executive summary, images
```

## How to run

```bash
brew install postgresql@16 && createdb ecommerce_analytics
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
# put the Kaggle CSVs into data/raw/
psql -d ecommerce_analytics -f sql/01_schema/01_create_tables.sql
python python/load_data.py
psql -d ecommerce_analytics -f sql/01_schema/02_create_indexes.sql
psql -d ecommerce_analytics -f sql/02_staging/01_cost_assumptions.sql
psql -d ecommerce_analytics -f sql/02_staging/02_clean_views.sql
psql -d ecommerce_analytics -f sql/03_analysis/09_margin_driver_analysis.sql
psql -d ecommerce_analytics -f sql/04_bi_views/01_bi_views.sql
python python/export_views.py
```

