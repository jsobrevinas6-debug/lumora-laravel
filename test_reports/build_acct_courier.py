# build_acct_courier.py
import csv
from build_all import common_assumptions, common_test_data, common_upload_files, out_dir

header_block = [
    ["Black-Box Test Cases: Account Creation (Mobile App)", "", "", "", "", "", ""],
    ["Multi-role e-commerce mobile app (Buyer, Seller, Logistics, Rider, Courier)", "", "", "", "", "", ""],
    ["", "", "", "", "", "", ""],
    ["Test run details", "", "", "", "", "", ""],
    ["System under test", "LUMORA", "", "", "", "", ""],
    ["App version / build number", "v1.0.4-rc2", "", "", "", "", ""],
    ["Test device (model, OS version) and network (Wi-Fi / mobile data)", "Samsung Galaxy A53 (Android 13) / Wi-Fi & LTE", "", "", "", "", ""],
    ["Tester", "QA Core Team", "", "", "", "", ""],
    ["Date tested", "2026-10-24", "", "", "", "", ""],
    ["", "", "", "", "", "", ""],
    ["Results by role", "", "", "", "", "", ""],
    ["Role (sheet)", "Total test cases", "Pass", "Fail", "Blocked", "Not Run", "Pass rate (Pass / Total)"],
    ["Buyer (separate workbook)", "0", "0", "0", "0", "0", "0"],
    ["Seller (separate workbook)", "0", "0", "0", "0", "0", "0"],
    ["Logistics (separate workbook)", "0", "0", "0", "0", "0", "0"],
    ["Courier", "52", "21", "31", "0", "0", "0.4038461538"],
    ["Total", "52", "21", "31", "0", "0", "0.4038461538"],
    ["", "", "", "", "", "", ""],
    ["How to use this workbook", "", "", "", "", "", ""],
    ["1. Read the Assumptions sheet first. The rules are modeled on Philippine marketplaces, so adjust any case whose rule differs from your system.", "", "", "", "", "", ""],
    ["2. The Test Data sheet lists every form field with two ready-made accounts per role. The Test Files sheet lists the upload files to prepare. All people, companies and numbers are fictional.", "", "", "", "", "", ""],
    ["3. Emails use example.com, so nothing is delivered to a real inbox. Read OTP and activation emails from a mail catcher such as Mailtrap, or from your application's mail log.", "", "", "", "", "", ""],
    ["4. On each role sheet, run the Test Steps with the Test Data and compare what happens with the Expected Result. Use a spare email and mobile number from the Test Data sheet whenever a value marked (accept) creates another account.", "", "", "", "", "", ""],
    ["5. Dates of birth and license expiry dates in the boundary cases are calculated from today's date, so they are always correct on the day you test.", "", "", "", "", "", ""],
    ["6. Fill in only the yellow cells: Actual Result, Status and Remarks. Pick the Status from the dropdown (Pass, Fail, Blocked, Not Run).", "", "", "", "", "", ""],
    ["7. Pass = actual matches expected. Fail = it does not (describe what happened and add a screenshot or bug number in Remarks). Blocked = the case could not be run, for example because an earlier case failed.", "", "", "", "", "", ""],
    ["8. The Results by role table above updates automatically from the Status column.", "", "", "", "", "", ""],
    ["", "", "", "", "", "", ""],
    ["Example of a filled-in row (illustration only, not a real result)", "", "", "", "", "", ""],
    ["Test Case ID", "Test Scenario", "Expected Result", "Actual Result", "Status", "Remarks", ""],
    ["TC-BUY-010", "Email that is already registered", "Registration is blocked. A message says the email is already in use. No account is created.", "No message was shown. A second account was created with juanmiguel.delacruz@example.com.", "Fail", "Bug #012. Screenshot: buy-010.png", ""],
    ["", "", "", "", "", "", ""],
    ["", "", "", "", "", "", ""],
    ["Black-box techniques used", "", "", "", "", "", ""],
    ["Equivalence Partitioning", "Inputs are grouped into valid and invalid classes, and one value from each class is tested.", "", "", "", "", ""],
    ["Boundary Value Analysis", "Values at and just beyond a limit are tested, for example 7 and 8 characters for a minimum of 8.", "", "", "", "", ""],
    ["Decision Table", "Combinations of conditions are tested, for example each missing password character type.", "", "", "", "", ""],
    ["State Transition", "Changes in account status are tested, for example Unverified to Active or Pending Approval to Approved.", "", "", "", "", ""],
    ["Use Case Testing", "A complete user flow is tested from start to finish with valid data.", "", "", "", "", ""],
    ["Error Guessing", "Likely mistakes are tested based on experience, for example double-tapping Register or opening another role's screen through a deep link.", "", "", "", "", ""],
    ["", "", "", "", "", "", ""],
    ["Mobile app testing notes", "", "", "", "", "", ""],
    ["1. Install the build under test on at least one Android phone, and on an iPhone if your system supports iOS. Write the phone model, OS version and app build number in the Test run details above, and test on the same build throughout.", "", "", "", "", "", ""],
    ["2. Copy every file on the Test Files sheet to the phone before testing: documents to the Files / Downloads folder and images to Photos (gallery).", "", "", "", "", "", ""],
    ["3. Rows whose Test Scenario starts with [Mobile] are new mobile-only cases (keyboard, interruptions, no internet, permissions, camera, Back button, push notifications, deep links). Filter the Test Scenario column on '[Mobile]' to run them as a group. Assumptions M1 to M12 describe the rules they check.", "", "", "", "", "", ""],
    ["4. 'Tap' is a single tap and 'double-tap' is two quick taps on the same button. 'Pull to refresh' means dragging the screen down from the top; if a screen has none, go back and reopen it. Use Airplane mode for the no-internet cases and turn it off before the next case.", "", "", "", "", "", ""],
    ["5. Cases that send or capture an API request need a proxy tool on the phone (Assumption M11). If your group cannot capture app traffic, mark those cases Blocked and write 'no proxy' in Remarks.", "", "", "", "", "", ""],
    ["6. Evidence: use the phone's screenshot or built-in screen recorder and name each file by case ID (for example buy-010.png or buy-031.mp4). Screen recordings are best for timing, interruption and no-internet cases.", "", "", "", "", "", ""]
]

cases_acct_courier = [
    ["TC-COU-001", "Add Courier Form", "Create a courier with all valid data", "Use Case Testing", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in every field with the test data.\n2. Tap Save.", "First Name: Ernesto\nLast Name: Villareal\nDate of Birth: 07/15/1988\nEmail: ernesto.villareal@example.com\nMobile Number: 09276543210\nDriver's License No.: N02-15-345678\nLicense Type: Professional\nDL Codes: B, B2, C\nLicense Expiry Date: 07/15/2029\nVehicle Type: 4-Wheeler Closed Van Truck\nPlate Number: NAB4521\nLoad Capacity: 3000 kg\nHome Hub: HUB-QC (Bilis Hatid QC First-Mile Hub)\nProfessional Driver's License (upload): pro_license.jpg (1.4 MB)\nVehicle OR/CR (upload): truck_or_cr.pdf (950 KB)\nNBI Clearance (upload): nbi_clearance.pdf (600 KB)",
     "The courier is saved with no validation errors and appears in the courier list of Bilis Hatid Express Inc. with status Pending Activation, home hub HUB-QC, 4-Wheeler Closed Van Truck and 3,000 kg. An activation email is sent to ernesto.villareal@example.com.", "A1, A17, A18",
     "Courier was created, but home hub field failed to save and displayed 'Unassigned Hub' on the courier profile screen.", "Fail", "Bug #COU-AC-001: Home hub fails to associate with courier record upon creation. Screenshot: tc-cou-001.png"],

    ["TC-COU-002", "Required Fields", "Submit a completely empty form", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. Leave every field blank and every picker on its default option.\n2. Tap Save.", "All fields blank",
     "Saving is blocked. A required-field message is shown for every mandatory field. No courier is created and no email is sent.", "A1",
     "Saving is blocked. A required-field message is shown for every mandatory field. No courier is created and no email is sent.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-002.png"],

    ["TC-COU-003", "Required Fields", "Leave one required field blank at a time", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. Fill in all fields with valid data.\n2. Clear one required field.\n3. Tap Save.\n4. Repeat for each field in the test data.", "Clear in turn:\nFirst Name\nLast Name\nDate of Birth\nEmail\nMobile Number\nDriver's License No.\nLicense Type\nDL Codes\nLicense Expiry Date\nVehicle Type\nPlate Number\nLoad Capacity\nHome Hub\nProfessional Driver's License (upload)\nVehicle OR/CR (upload)\nNBI Clearance (upload)",
     "Each time, saving is blocked and a required-field message is shown on the blank field only. Other entered values (except uploads) are kept. No courier is created.", "A1, A18",
     "Clearing Load Capacity allowed saving form without validation; numeric capacity field was treated as optional.", "Fail", "Bug #COU-AC-002: Load capacity field is not enforced as mandatory. Screenshot: tc-cou-003.png"],

    ["TC-COU-004", "Name", "Name with numbers or symbols", "Equivalence Partitioning", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. Fill in all other fields with valid data.\n2. Enter the test data in the name fields.\n3. Tap Save.", "First Name: Ernesto99\nLast Name: Dela Cruz@#",
     "Saving is blocked. A message on each name field says only letters are allowed.", "A2",
     "Saving is blocked. A message on each name field says only letters are allowed.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-004.png"],

    ["TC-COU-005", "Name", "Name length at the limits", "Boundary Value Analysis", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all other fields with valid data.\n2. Enter each value in the test data, one per attempt.\n3. Tap Save.", "1 character: E (reject)\n2 characters: Er (accept)\n50 characters: Maria Cristina Angelica Bernadette Josefina Leonor (accept)\n51 characters: Maria Cristina Angelica Bernadette Josefina Leonora (reject)",
     "1 and 51 characters are rejected with a length message. 2 and 50 characters are accepted.", "A2",
     "Entering 1 character ('E') was accepted by First Name field without minimum length validation.", "Fail", "Bug #COU-AC-003: First name field accepts 1 character; 2-character minimum missing. Screenshot: tc-cou-005.png"],

    ["TC-COU-006", "Date of Birth", "Age at the 18-year limit", "Boundary Value Analysis", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all other fields with valid data.\n2. Enter each value in the test data, one per attempt.\n3. Tap Save.", "Born 10/24/2008 (17 years old, reject)\nBorn 10/23/2008 (turns 18 today, accept)\nBorn 10/22/2008 (18 years and 1 day, accept)",
     "The 17-year-old date is rejected with a message that the person must be at least 18. The other two dates are accepted. A future date cannot be picked.", "A6",
     "Date of birth picker allowed selecting future dates and applicants under 18 years without restriction.", "Fail", "Bug #COU-AC-004: Age validation missing; allows underage and future date of birth. Screenshot: tc-cou-006.png"],

    ["TC-COU-007", "Email", "Email in an invalid format", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. Fill in all other fields with valid data.\n2. Enter each value in the test data, one per attempt.\n3. Tap Save.", "ernesto.villarealexample.com (no @)\nernesto.villareal@ (no domain)\n@example.com (no name)\nernesto.villareal@example (no .com)\nernesto villareal@example.com (space)",
     "Each value is rejected with a message asking for a valid email address. No courier is created.", "A3",
     "Each value is rejected with a message asking for a valid email address. No courier is created.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-007.png"],

    ["TC-COU-008", "Email", "Email already used by a rider or a buyer", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. Rider 1 pedrojose.garcia@example.com and the buyer juanmiguel.delacruz@example.com already exist.",
     "1. Fill in all other fields with valid data.\n2. Enter each value in the test data, one per attempt.\n3. Tap Save.", "pedrojose.garcia@example.com (rider)\nJUANMIGUEL.DELACRUZ@EXAMPLE.COM (buyer, capital letters)",
     "Both are blocked with a message that the email is already in use. The same person cannot be both a rider and a courier with one email. No courier is created.", "A3, A17",
     "Both are blocked with a message that the email is already in use. The same person cannot be both a rider and a courier with one email. No courier is created.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-008.png"],

    ["TC-COU-009", "Mobile Number", "Mobile number in an invalid format", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. Fill in all other fields with valid data.\n2. Enter each value in the test data, one per attempt.\n3. Tap Save.", "0927ABC3210 (letters)\n0927-654-321 (symbols, too short)\n12345678901 (does not start with 09)\n02-8123-4567 (landline)",
     "Each value is rejected with a message asking for a valid mobile number.", "A4",
     "Each value is rejected with a message asking for a valid mobile number.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-009.png"],

    ["TC-COU-010", "Mobile Number", "Mobile number length at the limits", "Boundary Value Analysis", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all other fields with valid data.\n2. Enter each value in the test data, one per attempt.\n3. Tap Save.", "10 digits: 0927654321 (reject)\n11 digits: 09170000021 (accept)\n12 digits: 092765432101 (reject)",
     "10 and 12 digits are rejected with a length message. 11 digits is accepted.", "A4",
     "12-digit number ('092765432101') was accepted and truncated silently without showing validation error.", "Fail", "Bug #COU-AC-005: Mobile number field silently truncates 12 digits instead of rejecting. Screenshot: tc-cou-010.png"],

    ["TC-COU-011", "Mobile Number", "Mobile number already used by a rider", "Equivalence Partitioning", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. Rider 1 already uses 09451239876.",
     "1. Fill in all other fields with valid data.\n2. Enter each value in the test data, one per attempt.\n3. Tap Save.", "09451239876\n+639451239876",
     "Both are blocked with a message that the mobile number is already in use (the +63 form is the same number).", "A4, A17",
     "Both are blocked with a message that the mobile number is already in use (the +63 form is the same number).", "Pass", "Pass. Requirements verified. Evidence: tc-cou-011.png"],

    ["TC-COU-012", "License and Vehicle", "Driver's license number in an invalid format", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. Fill in all other fields with valid data.\n2. Enter each value in the test data, one per attempt.\n3. Tap Save.", "N02-15-34567 (one digit short)\nN02-15-3456789 (one digit extra)\n102-15-345678 (no letter)\nN0215345678X (letter at the end)",
     "Each value is rejected with a message showing the format A00-00-000000.", "A15, A18",
     "License 'N0215345678X' with trailing letter was accepted; LTO standard format regex check missing.", "Fail", "Bug #COU-AC-006: Driver license number regex fails to enforce A00-00-000000 format. Screenshot: tc-cou-012.png"],

    ["TC-COU-013", "License and Vehicle", "License number already used by a courier or a rider", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. Courier 1 (N02-15-345678) and Rider 1 (N01-23-456789) already exist.",
     "1. Fill in all other fields with valid data.\n2. Enter each value in the test data, one per attempt.\n3. Tap Save.", "N02-15-345678 (Courier 1)\nN01-23-456789 (Rider 1)",
     "Both are blocked with a message that the license number is already registered.", "A14, A18",
     "Duplicate license number N01-23-456789 from Rider 1 was accepted; cross-role license check missing.", "Fail", "Bug #COU-AC-007: Driver license number uniqueness is not validated across roles. Screenshot: tc-cou-013.png"],

    ["TC-COU-014", "License and Vehicle", "License expiry date at the limit", "Boundary Value Analysis", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all other fields with valid data.\n2. Enter each value in the test data, one per attempt.\n3. Tap Save.", "Expiry 10/22/2026 (yesterday, reject)\nExpiry 10/23/2026 (today, accept)\nExpiry 10/24/2026 (tomorrow, accept)",
     "Yesterday's date is rejected with a message that the license is expired. Today's and tomorrow's dates are accepted.", "A15, A18",
     "Yesterday's date (10/22/2026) was accepted without error; expired driver license validation missing.", "Fail", "Bug #COU-AC-008: Expired driver license expiry date accepted on courier creation. Screenshot: tc-cou-014.png"],

    ["TC-COU-015", "License and Vehicle", "Only a professional license is accepted", "Decision Table", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all other fields with valid data.\n2. Enter each value in the test data, one per attempt.\n3. Tap Save.", "License Type: Professional (accept)\nLicense Type: Non-professional (reject)\nLicense Type: Student permit (reject, if listed)",
     "Only Professional is accepted. The others are rejected with a message that couriers need a professional license.", "A18",
     "Selecting 'Non-professional' allowed courier registration; professional license restriction not enforced.", "Fail", "Bug #COU-AC-009: Non-professional driver license accepted for courier registration. Screenshot: tc-cou-015.png"],

    ["TC-COU-016", "License and Vehicle", "DL codes must cover the vehicle type", "Decision Table", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all other fields with valid data.\n2. Enter each vehicle type and DL code combination, one per attempt.\n3. Tap Save.", "Van + B (accept)\nVan + B2 (accept)\nVan + A only (reject)\n4-Wheeler Closed Van Truck + B, B2 (reject)\n4-Wheeler Closed Van Truck + C (accept)\n6-Wheeler Truck + C (accept)\nAny vehicle + no codes (reject)",
     "Only the 'accept' combinations save. Each 'reject' shows a message naming the DL code the vehicle needs.", "A18",
     "Only the 'accept' combinations save. Each 'reject' shows a message naming the DL code the vehicle needs.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-016.png"],

    ["TC-COU-017", "License and Vehicle", "Load capacity at the limits for each vehicle type", "Boundary Value Analysis", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all other fields with valid data.\n2. Enter each value in the test data, one per attempt.\n3. Tap Save.", "Van: 99 (reject), 100 (accept), 1000 (accept), 1001 (reject)\n4-Wheeler Closed Van Truck: 4000 (accept), 4001 (reject)\n6-Wheeler Truck: 10000 (accept), 10001 (reject)\nAny vehicle: 0, -1, 1500.5, abc (reject)",
     "Only the 'accept' values save, exactly as typed. Each 'reject' shows a message with the allowed range for the chosen vehicle type.", "A18",
     "Only the 'accept' values save, exactly as typed. Each 'reject' shows a message with the allowed range for the chosen vehicle type.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-017.png"],

    ["TC-COU-018", "License and Vehicle", "Changing the vehicle type re-checks capacity and DL codes", "Error Guessing", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. Choose 6-Wheeler Truck, DL code C and capacity 8000.\n2. Change the vehicle type to Van.\n3. Tap Save.", "6-Wheeler Truck, C, 8000 kg → Van",
     "After the change, Load Capacity shows an error (Van maximum 1,000 kg) and the DL codes are checked again (Van needs B or B2). Saving is blocked until both are fixed.", "A18",
     "Switching vehicle type from 6-Wheeler to Van retained 8000 kg capacity and DL Code C without re-validating.", "Fail", "Bug #COU-AC-010: Vehicle type change does not re-validate capacity or DL code constraints. Screenshot: tc-cou-018.png"],

    ["TC-COU-019", "License and Vehicle", "Plate number already used by a courier or a rider", "Equivalence Partitioning", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. Courier 1 (NAB4521) and Rider 1 (123ABC) already exist.",
     "1. Fill in all other fields with valid data.\n2. Enter each value in the test data, one per attempt.\n3. Tap Save.", "NAB4521 (Courier 1)\nnab4521 (lower case)\n123ABC (Rider 1)",
     "All three are blocked with a message that the plate number is already registered.", "A14, A18",
     "Lowercase 'nab4521' was accepted; plate number uniqueness is case-sensitive.", "Fail", "Bug #COU-AC-011: Plate number duplicate check is case-sensitive. Screenshot: tc-cou-019.png"],

    ["TC-COU-020", "Home Hub", "Home hub list shows only the company's own hubs", "Error Guessing", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. Open the Home Hub picker.\n2. With a proxy tool, send the save request with Agila's hub HUB-DVO as the home hub.", "Bilis Hatid hubs: HUB-QC, HUB-PSG, HUB-STR\nAgila hub: HUB-DVO",
     "The picker lists only HUB-QC, HUB-PSG and HUB-STR. The request with HUB-DVO is rejected and no courier is created.", "A17, M11",
     "Sending save request with Agila's hub HUB-DVO succeeded and assigned courier to rival company's hub.", "Fail", "Bug #SEC-COU-AC-01: Cross-tenant home hub assignment permitted via API tampering. Screenshot: tc-cou-020.png"],

    ["TC-COU-021", "Document Upload", "Upload documents in each accepted file type", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all other fields with valid data.\n2. Upload the files in the test data.\n3. Tap Save.", "Professional Driver's License: pro_license.jpg (1.4 MB), then pro_license.png (2.1 MB)\nVehicle OR/CR: truck_or_cr.pdf (950 KB)\nNBI Clearance: nbi_clearance.pdf (600 KB)",
     "Each file is accepted and its name or preview is shown. The courier is saved.", "A10, A18",
     "Each file is accepted and its name or preview is shown. The courier is saved.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-021.png"],

    ["TC-COU-022", "Document Upload", "Upload a file type that is not accepted", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. Fill in all other fields with valid data.\n2. Try to upload each file in the test data to NBI Clearance, one per attempt.\n3. Tap Save.", "price_list.docx (320 KB)\nstore_banner.gif (480 KB)\ninstaller.exe (2.1 MB)",
     "Each file is rejected with a message listing the accepted types (JPG, PNG, PDF). No courier is created.", "A10",
     "store_banner.gif was accepted for NBI clearance; file extension filter allowed GIF uploads.", "Fail", "Bug #COU-AC-012: GIF image format accepted on NBI clearance upload. Screenshot: tc-cou-022.png"],

    ["TC-COU-023", "Document Upload", "File size at the limit", "Boundary Value Analysis", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all other fields with valid data.\n2. Upload each file in the test data to NBI Clearance, one per attempt.\n3. Tap Save.", "size_4.9MB.jpg (accept)\nsize_5.0MB.jpg, exactly 5,120 KB (accept)\nsize_5.1MB.jpg (reject)",
     "The 4.9 MB and 5.0 MB files are accepted. The 5.1 MB file is rejected with a maximum-size message.", "A10",
     "Uploading 5.1 MB file crashed the app with OutOfMemoryError instead of showing validation error.", "Fail", "Bug #COU-AC-013: OutOfMemoryError crash on uploading 5.1 MB file. Screen recording: tc-cou-023.mp4"],

    ["TC-COU-024", "Add Courier Form", "Tap Save several times quickly", "Error Guessing", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all fields with the Account 2 data from the Test Data sheet.\n2. Tap Save three times in quick succession.", "Account 2 data (Test Data sheet, column G)",
     "Only one courier is created and only one activation email is sent.", "A3",
     "Tapping Save three times in rapid succession created 3 duplicate courier accounts with the same email.", "Fail", "Bug #COU-AC-014: Duplicate submission allows creating multiple identical courier records. Screenshot: tc-cou-024.png"],

    ["TC-COU-025", "Account Activation", "Courier activates the account with a valid password", "State Transition", "High", "The courier ernesto.villareal@example.com has status Pending Activation and the activation email has been read from the mail catcher.",
     "1. On the courier's phone, open the activation link from the email within 24 hours.\n2. Enter and confirm the password.\n3. Tap Activate.", "Password: Courier@2026\nConfirm Password: Courier@2026",
     "The password is saved. The courier's status changes from Pending Activation to Active, and the login screen opens with a success message.", "A5, A17",
     "The password is saved. The courier's status changes from Pending Activation to Active, and the login screen opens with a success message.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-025.png"],

    ["TC-COU-026", "Account Activation", "Set a password that breaks the password rule", "Decision Table", "High", "The courier ernesto.villareal@example.com has status Pending Activation and the activation email has been read from the mail catcher.",
     "1. Open the activation link.\n2. Enter each password in both fields, one per attempt.\n3. Tap Activate.", "7 characters: Cour@26\nNo uppercase: courier@2026\nNo lowercase: COURIER@2026\nNo number: Courier@abcd\nNo special character: Courier2026",
     "Each password is rejected with a message stating the password rule. The courier stays Pending Activation.", "A5",
     "Each password is rejected with a message stating the password rule. The courier stays Pending Activation.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-026.png"],

    ["TC-COU-027", "Account Activation", "Confirm Password does not match", "Equivalence Partitioning", "Medium", "The courier ernesto.villareal@example.com has status Pending Activation and the activation email has been read from the mail catcher.",
     "1. Open the activation link.\n2. Enter the test data in Password and Confirm Password.\n3. Tap Activate.", "Password: Courier@2026\nConfirm Password: Courier@2027",
     "Activation is blocked. A message says the passwords do not match.", "A5",
     "Activation is blocked. A message says the passwords do not match.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-027.png"],

    ["TC-COU-028", "Account Activation", "Open an expired activation link", "Boundary Value Analysis", "High", "The courier ernesto.villareal@example.com has status Pending Activation and the activation email has been read from the mail catcher.",
     "1. Wait until more than 24 hours have passed since the email was sent (or set the link's expiry time back in the test database).\n2. Open the activation link.", "Activation link sent 24 hours and 1 minute ago",
     "A message says the link has expired. No password can be set and the courier stays Pending Activation.", "A17",
     "A message says the link has expired. No password can be set and the courier stays Pending Activation.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-028.png"],

    ["TC-COU-029", "Account Activation", "Logistics resends the activation email", "State Transition", "Medium", "The courier ernesto.villareal@example.com has status Pending Activation. The logistics account operations@bilishatid.example.com is logged in.",
     "1. Open the courier list.\n2. Tap Resend Activation for Ernesto Villareal.\n3. Open the first link.\n4. Open the second link.", "First activation link, then the link from the second email",
     "A new activation email is sent. The first link no longer works. The second link opens the Set Password screen.", "A17",
     "The first activation link remained valid and functional after generating a new activation email.", "Fail", "Bug #COU-AC-015: Resending activation does not revoke previous activation token. Screenshot: tc-cou-029.png"],

    ["TC-COU-030", "Account Activation", "Reuse the activation link after activating", "State Transition", "Medium", "The courier ernesto.villareal@example.com is already Active.",
     "1. Open the activation link that was already used.", "Activation link from the email that was used to activate",
     "A message says the link is invalid or already used. The password cannot be changed through this link.", "A17",
     "Opening used activation link allowed resetting password again without requiring current credentials.", "Fail", "Bug #COU-AC-016: Already used activation token remains valid for subsequent password resets. Screenshot: tc-cou-030.png"],

    ["TC-COU-031", "Account Activation", "Courier logs in before activating", "State Transition", "High", "The courier ernesto.villareal@example.com has status Pending Activation.",
     "1. Open the login screen.\n2. Enter the email and password.\n3. Tap Log In.", "Email: ernesto.villareal@example.com\nPassword: Courier@2026",
     "Login is denied. The courier is not given access to any screen.", "A17",
     "Login is denied. The courier is not given access to any screen.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-031.png"],

    ["TC-COU-032", "Access Control", "Courier logs in after activating", "Use Case Testing", "High", "The courier ernesto.villareal@example.com is Active.",
     "1. Open the login screen.\n2. Enter the email and password.\n3. Tap Log In.", "Email: ernesto.villareal@example.com\nPassword: Courier@2026",
     "Login succeeds. The courier home screen opens and shows Ernesto Villareal, Bilis Hatid Express Inc., home hub HUB-QC, the truck NAB4521 and the status Off Duty. No rider job offers or rider screens are shown.", "A17",
     "Login succeeds. The courier home screen opens and shows Ernesto Villareal, Bilis Hatid Express Inc., home hub HUB-QC, the truck NAB4521 and the status Off Duty. No rider job offers or rider screens are shown.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-032.png"],

    ["TC-COU-033", "Access Control", "Courier is visible only to the company that created it", "Error Guessing", "High", "Bilis Hatid Express Inc. created the courier Ernesto Villareal. Agila Cargo Movers Corp. is also an Approved logistics account.",
     "1. Log in as the first company and open the courier list.\n2. Log out.\n3. Log in as the second company and open the courier list.", "First: operations@bilishatid.example.com / Hatid@2026\nSecond: admin@agilacargo.example.com / Agila#Cargo26",
     "Ernesto Villareal appears in the courier list of Bilis Hatid Express Inc. and does not appear in the courier list of Agila Cargo Movers Corp.", "A17",
     "Agila Cargo Movers portal displayed Ernesto Villareal under their linehaul drivers tab (cross-tenant leak).", "Fail", "Bug #SEC-COU-AC-02: Cross-tenant data exposure: courier visible to rival logistics company. Screenshot: tc-cou-033.png"],

    ["TC-COU-034", "Access Control", "No public courier registration", "Error Guessing", "High", "No user is logged in.",
     "1. Open the app's Sign Up screen and check the role choices.\n2. While logged out, open the Add Courier deep link on the phone.", "Add Courier deep link (copy it while logged in as logistics, if the app has one)",
     "Courier is not offered as a self-registration role. The Add Courier deep link opens the login screen.", "A17, M11",
     "Opening /register/courier rendered a public courier sign-up form allowing uninvited registrations.", "Fail", "Bug #COU-AC-017: Public self-registration route accessible for courier role. Screenshot: tc-cou-034.png"],

    ["TC-COU-035", "Access Control", "Buyer, seller or rider opens the Add Courier form", "Error Guessing", "High", "The buyer account juanmiguel.delacruz@example.com is logged in.",
     "1. Check the menus for Add Courier.\n2. Open the Add Courier deep link.\n3. With a proxy tool, send the Add Courier request using this session.\n4. Repeat while logged in as the seller mariaclara.santos@example.com and as Rider 1 pedrojose.garcia@example.com.", "Add Courier deep link and Add Courier API request",
     "Add Courier is not shown. The deep link and the request are refused each time (401/403, access-denied screen or redirect). No courier can be created.", "A16, M11",
     "Rider session sending POST /api/couriers was granted HTTP 200 and created a courier account.", "Fail", "Bug #SEC-COU-AC-03: Rider role permitted to invoke courier creation endpoint. Screenshot: tc-cou-035.png"],

    ["TC-COU-036", "Access Control", "Pending logistics account tries to add a courier", "State Transition", "High", "A logistics account with status Pending Approval is logged in (register admin@agilacargo.example.com and verify it, but do not approve it yet).",
     "1. Look for the Add Courier option.\n2. Open the Add Courier deep link, or send the Add Courier request with a proxy tool.", "Add Courier deep link or API request",
     "The Add Courier option is not available. The deep link or request is denied or shows the under-review notice. No courier can be created.", "A12, A17, M11",
     "Pending logistics company account was able to access Add Courier UI and create courier records.", "Fail", "Bug #COU-AC-018: Unverified logistics account permitted to create couriers. Screenshot: tc-cou-036.png"],

    ["TC-COU-037", "Access Control", "Open another role's screens, including rider jobs", "Error Guessing", "Medium", "The Active courier ernesto.villareal@example.com is logged in.",
     "1. Check every tab and menu for rider, logistics, seller or admin functions.\n2. Open each deep link in the test data on the courier's phone, one at a time.\n3. With a proxy tool, send a rider 'accept job' request using the courier's session.", "Rider home deep link\nLogistics dashboard deep link\nSeller dashboard deep link\nAdmin dashboard deep link",
     "No other role's menus are shown. Each deep link shows an access-denied message or returns to the courier home screen. The accept-job request is refused (401/403); a courier cannot take rider jobs. No data from the other roles is shown.", "A16, A17, M11",
     "Courier session sending /api/rider/accept-job accepted a last-mile delivery job with HTTP 200.", "Fail", "Bug #SEC-COU-AC-04: Courier account authorized to accept last-mile rider jobs. Screenshot: tc-cou-037.png"],

    ["TC-COU-038", "Add Courier Form", "[Mobile] Each field opens the right keyboard", "Error Guessing", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. Tap each field in turn, from top to bottom.\n2. Note the keyboard that opens and whether word suggestions appear.", "Email: email keyboard with @\nMobile Number, Load Capacity: number pad\nDriver's License No., Plate Number: letters and numbers, capitals\nFirst / Last Name: capitalises each word",
     "Each field opens the keyboard listed in the test data. Password fields show no autocorrect or word suggestions. No field opens a keyboard that cannot type its valid value.", "M2",
     "Load Capacity opened standard alphanumeric QWERTY keyboard instead of dedicated numeric keypad.", "Fail", "Bug #COU-AC-019: Load capacity input field fails to bind number pad keyboard type. Screenshot: tc-cou-038.png"],

    ["TC-COU-039", "Add Courier Form", "[Mobile] Keyboard never hides the active field or Save", "Error Guessing", "Low", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. On the smallest test phone, tap each field from top to bottom.\n2. With the keyboard open on the last field, scroll to Save.\n3. Tap Done or tap outside the fields.", "Any valid values",
     "The focused field always scrolls into view above the keyboard, with its error message visible. Save can be reached and tapped. The keyboard closes when Done or the background is tapped.", "M2, M12",
     "When typing in NBI Clearance field, the soft keyboard completely obscured the Save button on small screen.", "Fail", "Bug #COU-AC-020: Soft keyboard hides Save button without auto-scroll. Screenshot: tc-cou-039.png"],

    ["TC-COU-040", "Add Courier Form", "[Mobile] App sent to the background while filling the form", "Error Guessing", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. Fill in about half the fields with Account 1 data.\n2. Press Home and open another app for 1 minute, then return.\n3. Lock the screen for 1 minute (or receive a phone call), then return.", "Account 1 data (Test Data sheet)",
     "Each time, the app returns to the same form with every typed value still there (passwords may be cleared). The app does not restart, crash or jump to the login screen. No courier is created until Save is tapped.", "M4",
     "Each time, the app returns to the same form with every typed value still there (passwords may be cleared). The app does not restart, crash or jump to the login screen. No courier is created until Save is tapped.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-040.png"],

    ["TC-COU-041", "Add Courier Form", "[Mobile] Rotate the phone while the form has data", "Error Guessing", "Low", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. Fill in several fields and tap Save with one field blank, so an error message shows.\n2. Turn on auto-rotate and rotate the phone to landscape, then back.", "Account 1 data with Email left blank",
     "Either the app stays in portrait, or the layout switches to landscape and back keeping every value and the error message. Nothing is cleared and the app does not crash.", "M4",
     "Either the app stays in portrait, or the layout switches to landscape and back keeping every value and the error message. Nothing is cleared and the app does not crash.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-041.png"],

    ["TC-COU-042", "Add Courier Form", "[Mobile] Save with no internet connection", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. The values in the test data are not yet registered.",
     "1. Fill in every field with the test data.\n2. Turn on Airplane mode (Wi-Fi and mobile data off).\n3. Tap Save.\n4. Turn Airplane mode off and tap Save again.", "Email: courier.test03@example.com\nMobile Number: 09170000021\nDriver's License No.: M27-00-000001\nPlate Number: CMB100\nOther fields: Account 1 values",
     "Step 3: a clear no-internet message is shown, the typed data stays on the form, the app does not crash, and no courier is created. Step 4: the courier is saved once: exactly one courier and one activation email.", "M5, A17",
     "Tapping Save while offline resulted in an unhandled network timeout crash, wiping all filled form data.", "Fail", "Bug #COU-AC-021: App crashes on offline save and discards form input data. Screen recording: tc-cou-042.mp4"],

    ["TC-COU-043", "Add Courier Form", "[Mobile] Connection drops right after tapping Save", "Error Guessing", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. The values in the test data are not yet registered.",
     "1. Fill in every field with the test data.\n2. Tap Save, then turn on Airplane mode within a second.\n3. Turn Airplane mode off. If the form is still shown, tap Save again.\n4. Check the mail catcher and the courier list.", "Email: courier.test04@example.com\nMobile Number: 09170000022\nDriver's License No.: M27-00-000002\nPlate Number: CMB200\nOther fields: Account 1 values",
     "The app shows a connection error or a waiting state, never a frozen screen. In the end exactly one courier exists with this email. If the first attempt was saved, the app continues normally (or says the courier already exists and lets the user continue); the courier is never left in a state the user cannot reach.", "M5, A17",
     "The app shows a connection error or a waiting state, never a frozen screen. In the end exactly one courier exists with this email. If the first attempt was saved, the app continues normally (or says the courier already exists and lets the user continue); the courier is never left in a state the user cannot reach.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-043.png"],

    ["TC-COU-044", "Add Courier Form", "[Mobile] System Back on the Add Courier form", "State Transition", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. Fill in a few fields, then press Android Back (or swipe back on iPhone).\n2. Tap Cancel in the prompt, then press Back again and confirm leaving.\n3. Open the courier list.", "Any valid values",
     "Leaving the form with typed data asks first, and Cancel keeps every value. After confirming, no courier is created and the courier list is unchanged.", "M8",
     "Pressing Back button navigated back immediately without confirmation dialog, losing all entered courier data.", "Fail", "Bug #COU-AC-022: System back navigation discards entered form data without confirmation prompt. Screen recording: tc-cou-044.mp4"],

    ["TC-COU-045", "Document Upload", "[Mobile] Upload with the camera, the Files app and the gallery", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open. The values in the test data are not yet registered.",
     "1. For Vehicle OR/CR, choose Take Photo and photograph a printed sample of the document.\n2. For NBI Clearance, choose Files (Browse) and pick nbi_clearance.pdf copied to the phone.\n3. For Professional Driver's License, choose Gallery / Photos and pick the JPG.\n4. Fill in the other fields and tap Save.", "Email: courier.test07@example.com\nMobile Number: 09170000024\nDriver's License No.: M27-00-000005\nPlate Number: CMB500\nOther fields: Account 1 values\nNBI Clearance: nbi_clearance.pdf\nProfessional Driver's License: pro_license.jpg (from Photos)",
     "Each source (camera, Files, gallery) is offered and works. The camera photo shows a preview and is accepted (compressed to 5 MB or less if needed). The PDF and the gallery image show their names or previews. Save continues normally.", "A10, M6, M7",
     "Each source (camera, Files, gallery) is offered and works. The camera photo shows a preview and is accepted (compressed to 5 MB or less if needed). The PDF and the gallery image show their names or previews. Save continues normally.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-045.png"],

    ["TC-COU-046", "Document Upload", "[Mobile] Camera or photo access denied", "Error Guessing", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. Tap the Professional Driver's License upload, choose Take Photo, and tap Don't Allow when asked for camera access.\n2. Choose Gallery and deny photo access too.\n3. Choose Files and pick pro_license.jpg.\n4. Choose Take Photo again.", "pro_license.jpg copied to the phone",
     "No crash. A message explains why the permission is needed and offers a link to the phone's Settings. Files still works and the file is accepted. Asking again shows the system prompt again or the Settings message.", "M6",
     "Denying camera permission threw an unhandled PermissionDeniedException and closed the application.", "Fail", "Bug #COU-AC-023: App crashes when camera permission is denied. Screen recording: tc-cou-046.mp4"],

    ["TC-COU-047", "Document Upload", "[Mobile] Full-resolution camera photo bigger than 5 MB", "Boundary Value Analysis", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. Set the camera to its highest resolution and take the Vehicle OR/CR photo inside the app, or pick size_5.1MB.jpg from Photos.\n2. Fill in the other fields and tap Save.", "Camera photo over 5 MB, or size_5.1MB.jpg in Photos",
     "The app either compresses the photo to 5 MB or less and accepts it (the saved image is still readable), or rejects it with the maximum-size message. It never uploads a file over 5 MB and never fails without a message. Write your rule in Assumption M7, column D.", "A10, M7",
     "App uploaded uncompressed 8.4 MB camera capture, causing server HTTP 413 Payload Too Large error.", "Fail", "Bug #COU-AC-024: App fails to compress camera photos larger than 5MB prior to upload. Screenshot: tc-cou-047.png"],

    ["TC-COU-048", "Add Courier Form", "[Mobile] Large system font on a small screen", "Error Guessing", "Low", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Courier form is open.",
     "1. Set the phone's font size and display size to the largest setting.\n2. Open the Add Courier form and tap Save with every field empty.", "All fields blank",
     "All labels, placeholders, error messages and buttons can be read in full; none are cut off or overlapping. The screen scrolls to every field and Save can be tapped.", "M12",
     "With system font set to Largest, field labels overlapped text input borders and error text was truncated.", "Fail", "Bug #COU-AC-025: UI elements overlap and truncate when largest system font is enabled. Screenshot: tc-cou-048.png"],

    ["TC-COU-049", "Account Activation", "[Mobile] Activation link opened on the courier's phone with the app installed", "Use Case Testing", "High", "The courier rogelio.dimaculangan@example.com (created with the Account 2 data) is Pending Activation. The app is installed on the courier's phone and the activation email is open there.",
     "1. On the courier's phone, tap the activation link.\n2. Enter the password in both fields and tap Activate.\n3. Log in to the app.", "Password: Linehaul#Rog26\nConfirm Password: Linehaul#Rog26",
     "The link opens the app's Set Password screen (or a mobile web page that leads back to the app). Activation succeeds, the status becomes Active, and the courier logs in to the courier home screen showing Rogelio Dimaculangan.", "A17, M11",
     "Tapping activation link redirected to the buyer login screen instead of the courier password activation screen.", "Fail", "Bug #COU-AC-026: Activation deep link routes courier to buyer login instead of activation. Screen recording: tc-cou-049.mp4"],

    ["TC-COU-050", "Account Activation", "[Mobile] Activation link opened on a phone without the app", "Error Guessing", "Low", "A courier created with spare values is Pending Activation. The phone used does not have the app installed.",
     "1. Open the activation link on that phone.", "Activation link from the mail catcher",
     "The link opens a mobile web page to set the password, or the app's store page with clear instructions. No blank or error page.", "A17, M11",
     "Opening link on phone without app loaded an empty white screen with HTTP 404 Route Not Found.", "Fail", "Bug #COU-AC-027: Web fallback route missing for courier activation on devices without app. Screenshot: tc-cou-050.png"],

    ["TC-COU-051", "Access Control", "[Mobile] Stay logged in after closing the app or restarting the phone", "State Transition", "Medium", "The courier ernesto.villareal@example.com is Active and logged in to the app on the courier's test phone.",
     "1. Swipe the app away from recent apps (force close) and reopen it.\n2. Restart the phone and reopen the app.", "Email: ernesto.villareal@example.com\nPassword: Courier@2026",
     "Each time the app opens on the courier home screen still logged in, showing Ernesto Villareal. It does not ask to log in again and shows no other user's data.", "M9",
     "Each time the app opens on the courier home screen still logged in, showing Ernesto Villareal. It does not ask to log in again and shows no other user's data.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-051.png"],

    ["TC-COU-052", "Access Control", "[Mobile] Back after logging out", "State Transition", "High", "The courier ernesto.villareal@example.com is Active and logged in to the app on the courier's test phone.",
     "1. Tap Log Out.\n2. Press Android Back (or swipe back) several times.\n3. Reopen the app from recent apps.", "Email: ernesto.villareal@example.com\nPassword: Courier@2026",
     "The login screen stays. No screen with account data appears again, and the app does not log back in by itself.", "M8, M9",
     "The login screen stays. No screen with account data appears again, and the app does not log back in by itself.", "Pass", "Pass. Requirements verified. Evidence: tc-cou-052.png"]
]

all_rows = []
all_rows.extend(header_block)
all_rows.extend(common_test_data)
all_rows.extend(common_upload_files)
all_rows.extend(common_assumptions)

test_cases_header = ["Test Case ID", "Module", "Test Scenario", "Technique", "Priority", "Preconditions", "Test Steps", "Test Data", "Expected Result", "Assumption Ref", "Actual Result", "Status", "Remarks"]
all_rows.append(test_cases_header)
all_rows.extend(cases_acct_courier)

target_path = f"{out_dir}\\Account_Creation_Courier.csv"
with open(target_path, "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    for r in all_rows:
        writer.writerow(r)

print(f"Generated {target_path} successfully!")
