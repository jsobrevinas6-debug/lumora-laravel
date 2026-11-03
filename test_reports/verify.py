import csv
import glob

files = glob.glob(r"c:\xampp\htdocs\lumora-laravel\test_reports\*.csv")
print("Found files:", files)

for fpath in files:
    with open(fpath, "r", encoding="utf-8") as f:
        reader = list(csv.reader(f))
    
    # find test cases header
    header_idx = None
    for i, row in enumerate(reader):
        if len(row) > 0 and row[0] == "Test Case ID":
            header_idx = i
            break
            
    print(f"\n--- Checking {fpath} ---")
    if header_idx is None:
        print("ERROR: No test case header found!")
        continue
        
    test_cases = []
    for r in reader[header_idx:]:
        if len(r) >= 13 and (r[0].startswith("COU-") or r[0].startswith("RID-") or r[0].startswith("TC-")):
            test_cases.append(r)
            
    print(f"Total test case rows: {len(test_cases)}")
    
    pass_cnt = sum(1 for tc in test_cases if tc[11] == "Pass")
    fail_cnt = sum(1 for tc in test_cases if tc[11] == "Fail")
    blocked_cnt = sum(1 for tc in test_cases if tc[11] == "Blocked")
    notrun_cnt = sum(1 for tc in test_cases if tc[11] == "Not Run")
    
    print(f"Pass: {pass_cnt}, Fail: {fail_cnt}, Blocked: {blocked_cnt}, Not Run: {notrun_cnt}")
    
    # check for empty actual result or remarks
    empty_actual = [tc[0] for tc in test_cases if not tc[10].strip()]
    if empty_actual:
        print(f"ERROR: Empty actual results in: {empty_actual}")
    else:
        print("All test cases have non-empty Actual Results!")
        
    empty_remarks = [tc[0] for tc in test_cases if not tc[12].strip()]
    if empty_remarks:
        print(f"ERROR: Empty remarks in: {empty_remarks}")
    else:
        print("All test cases have non-empty Remarks!")
