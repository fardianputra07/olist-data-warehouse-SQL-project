from pathlib import Path
import pandas as pd

# Ganti path ini sesuai lokasi folder dataset kamu
FOLDER_PATH = r"./datasets"

# Kata kunci kolom untuk menebak asal sistem meski nama file berbeda
CRM_HINTS = {"customer_id", "customer_unique_id", "review_id", "review_score", "review_comment_message"}
ERP_HINTS = {
    "product_id", "product_category_name", "product_weight_g",
    "seller_id", "seller_city", "seller_state",
    "payment_type", "payment_installments", "payment_value",
    "order_item_id", "price", "freight_value"
}
BRIDGE_HINTS = {"order_id", "order_status", "order_purchase_timestamp"}
REF_HINTS = {"geolocation_zip_code_prefix", "geolocation_lat", "geolocation_lng"}


def detect_system(columns: list[str]) -> str:
    col_set = {c.strip().lower() for c in columns}
    scores = {
        "CRM": len(col_set & CRM_HINTS),
        "ERP": len(col_set & ERP_HINTS),
        "Jembatan (Order)": len(col_set & BRIDGE_HINTS),
        "Referensi (Geolocation)": len(col_set & REF_HINTS),
    }
    best_match = max(scores, key=scores.get)
    if scores[best_match] == 0:
        return "Tidak Terdeteksi"
    if "order_id" in col_set and scores["CRM"] == 0 and scores["ERP"] == 0:
        return "Jembatan (Order)"
    return best_match


def read_dataset(file_path: Path) -> pd.DataFrame | None:
    ext = file_path.suffix.lower()
    try:
        if ext == ".csv":
            # nrows=0 cukup untuk baca header super cepat; ganti jika ingin hitung baris akurat
            return pd.read_csv(file_path, low_memory=False)
        elif ext in {".xlsx", ".xls"}:
            return pd.read_excel(file_path)
        elif ext == ".parquet":
            return pd.read_parquet(file_path)
    except Exception as e:
        print(f"[ERROR] Gagal membaca '{file_path.name}': {e}")
    return None


def inspect_folder(folder_path: str) -> None:
    root = Path(folder_path)
    if not root.exists() or not root.is_dir():
        print(f"Folder tidak ditemukan: {root.resolve()}")
        return

    supported_exts = {".csv", ".xlsx", ".xls", ".parquet"}
    files = sorted(
        [p for p in root.rglob("*") if p.is_file() and p.suffix.lower() in supported_exts]
    )

    if not files:
        print(f"Tidak ada file dataset (.csv, .xlsx, .parquet) di dalam '{root.resolve()}'.")
        return

    print(f"Ditemukan {len(files)} file di '{root.resolve()}':\n" + "=" * 70)

    for idx, file_path in enumerate(files, start=1):
        df = read_dataset(file_path)
        if df is None:
            continue

        cols = list(df.columns)
        system_guess = detect_system(cols)

        print(f"{idx}. File       : {file_path.name}")
        print(f"   Path       : {file_path}")
        print(f"   Ukuran     : {len(df):,} baris x {len(cols)} kolom")
        print(f"   Perkiraan  : {system_guess}")
        print(f"   Kolom      : {', '.join(str(c) for c in cols)}")
        print("-" * 70)


if __name__ == "__main__":
    inspect_folder(FOLDER_PATH)