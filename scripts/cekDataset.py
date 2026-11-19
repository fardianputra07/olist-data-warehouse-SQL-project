import pandas as pd, glob, os

for path in sorted(glob.glob("datasets/*.csv")):
    df = pd.read_csv("datasets/olist_order_reviews_dataset.csv", dtype=str, keep_default_na=False)
    print(df["review_comment_message"].str.contains(r"[\r\n]", regex=True).sum())
