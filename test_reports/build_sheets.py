import csv
import os

os.makedirs(r"c:\xampp\htdocs\lumora-laravel\test_reports", exist_ok=True)

# Helper function to write CSV
def write_csv(filepath, rows):
    with open(filepath, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        for row in rows:
            writer.writerow(row)
    print(f"Wrote {filepath} with {len(rows)} lines")

print("Setting up script to generate all 4 files...")
