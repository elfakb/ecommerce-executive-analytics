"""Export BI views to CSV for Tableau Public."""
import pandas as pd
from sqlalchemy import create_engine

from config import PROCESSED_DIR, db_url

VIEWS = ["bi_items", "bi_orders", "bi_customer_segments", "bi_margin_bridge"]


def main() -> None:
    engine = create_engine(db_url())
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    for v in VIEWS:
        df = pd.read_sql(f"SELECT * FROM {v}", engine)
        df.to_csv(PROCESSED_DIR / f"{v}.csv", index=False)
        print(f"{v:<24} {len(df):>8,} rows")


if __name__ == "__main__":
    main()
