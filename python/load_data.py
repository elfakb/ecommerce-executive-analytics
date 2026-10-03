"""Load Olist CSV files into PostgreSQL. Safe to re-run (tables are truncated first)."""
import pandas as pd
from sqlalchemy import create_engine, text

from config import RAW_DIR, db_url


TABLES = [
    ("olist_customers_dataset.csv", "customers", [], [], {}),
    ("olist_sellers_dataset.csv", "sellers", [], [], {}),
    ("product_category_name_translation.csv", "product_category_translation", [], [], {}),
    (
        "olist_products_dataset.csv", "products", [],
        ["product_name_length", "product_description_length", "product_photos_qty",
         "product_weight_g", "product_length_cm", "product_height_cm", "product_width_cm"],
        {"product_name_lenght": "product_name_length",          # orijinal veri setinde yazım hatası var
         "product_description_lenght": "product_description_length"},
    ),
    (
        "olist_orders_dataset.csv", "orders",
        ["order_purchase_timestamp", "order_approved_at", "order_delivered_carrier_date",
         "order_delivered_customer_date", "order_estimated_delivery_date"], [], {},
    ),
    ("olist_order_items_dataset.csv", "order_items", ["shipping_limit_date"], [], {}),
    ("olist_order_payments_dataset.csv", "order_payments", [], [], {}),
    (
        "olist_order_reviews_dataset.csv", "order_reviews",
        ["review_creation_date", "review_answer_timestamp"], [], {},
    ),
]

STRING_ZIP_COLS = {"customer_zip_code_prefix", "seller_zip_code_prefix"}


def main() -> None:
    engine = create_engine(db_url())

    with engine.begin() as conn:
        tables = ", ".join(t[1] for t in TABLES)
        conn.execute(text(f"TRUNCATE {tables} RESTART IDENTITY CASCADE"))

    for csv_name, table, date_cols, int_cols, rename in TABLES:
        path = RAW_DIR / csv_name
        if not path.exists():
            raise FileNotFoundError(f"Missing file: {path}")

        df = pd.read_csv(path, dtype={c: str for c in STRING_ZIP_COLS})
        df = df.rename(columns=rename)

        for col in date_cols:
            df[col] = pd.to_datetime(df[col], errors="coerce")
        for col in int_cols:
            df[col] = pd.to_numeric(df[col], errors="coerce").astype("Int64")

        df.to_sql(table, engine, if_exists="append", index=False,
                  chunksize=5000, method="multi")
        print(f"{table:<32} {len(df):>8,} rows loaded")

    print("Done.")


if __name__ == "__main__":
    main()