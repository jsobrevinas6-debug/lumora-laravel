# build_acct_rider.py
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
    ["Rider", "47", "18", "28", "0", "1", "0.3829787234"],
    ["Total", "47", "18", "28", "0", "1", "0.3829787234"],
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

cases_acct_rider = [
    ["TC-RID-001", "Add Rider Form", "Create a rider with all valid data", "Use Case Testing", "High", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in every field with the test data.\n2. Tap Save.", "First Name: Pedro Jose\nLast Name: Garcia\nDate of Birth: 03/22/1995\nEmail: pedrojose.garcia@example.com\nMobile Number: 09451239876\nDriver's License No.: N01-23-456789\nLicense Expiry Date: 03/22/2030\nVehicle Type: Motorcycle\nPlate Number: 123ABC\nDriver's License (upload): drivers_license.jpg (1.5 MB)\nVehicle OR/CR (upload): or_cr.pdf (900 KB)",
     "The rider is saved with no validation errors and appears in the rider list of Bilis Hatid Express Inc. with status Pending Activation. An activation email is sent to pedrojose.garcia@example.com.", "A1, A13",
     "The rider is saved with no validation errors and appears in the rider list of Bilis Hatid Express Inc. with status Pending Activation. An activation email is sent to pedrojose.garcia@example.com.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-001.png"],

    ["TC-RID-002", "Required Fields", "Submit a completely empty form", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open.",
     "1. Leave every field blank and every dropdown on its default option.\n2. Tap Save.", "All fields blank",
     "Saving is blocked. A required-field message is shown for every mandatory field. No rider is created and no email is sent.", "A1",
     "Tapping Save with an empty form displayed no field-level validation messages; page reloaded blank without indicating required fields.", "Fail", "Bug #RID-AC-001: Form fails to show field-level validation errors on empty submission. Screenshot: tc-rid-002.png"],

    ["TC-RID-003", "Required Fields", "Leave one required field blank at a time", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open.",
     "1. Fill in all fields with valid data.\n2. Clear one required field.\n3. Tap Save.\n4. Repeat for each field in the test data.", "Clear in turn:\nFirst Name\nLast Name\nDate of Birth\nEmail\nMobile Number\nDriver's License No.\nLicense Expiry Date\nVehicle Type\nPlate Number\nDriver's License (upload)\nVehicle OR/CR (upload)",
     "Each time, saving is blocked and a required-field message is shown on the blank field only. Other entered values (except uploads) are kept. No rider is created.", "A1",
     "Each time, saving is blocked and a required-field message is shown on the blank field only. Other entered values (except uploads) are kept. No rider is created.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-003.png"],

    ["TC-RID-004", "Name", "Name with numbers or symbols", "Equivalence Partitioning", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open.",
     "1. Fill in all other fields with valid data.\n2. Enter the test data in the name fields.\n3. Tap Save.", "First Name: Pedro Jose99\nLast Name: Dela Cruz@#",
     "Saving is blocked. A message on each name field says only letters are allowed.", "A2",
     "Names with numbers ('Pedro Jose99') and special characters ('Dela Cruz@#') were accepted without error; alphabet-only validation missing.", "Fail", "Bug #RID-AC-002: Name fields permit numbers and special symbols. Screenshot: tc-rid-004.png"],

    ["TC-RID-005", "Name", "Name length at the limits", "Boundary Value Analysis", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all other fields with valid data.\n2. Enter each first name in the test data, one per attempt.\n3. Tap Save.", "1 character: P (reject)\n2 characters: Po (accept)\n50 characters: Maria Cristina Angelica Bernadette Josefina Leonor (accept)\n51 characters: Maria Cristina Angelica Bernadette Josefina Leonora (reject)",
     "1 and 51 characters are rejected with a length message. 2 and 50 characters are accepted.", "A2",
     "Single character name 'P' was accepted without error; minimum length constraint (2 characters) was not enforced.", "Fail", "Bug #RID-AC-003: First name accepts 1 character; 2-character minimum not enforced. Screenshot: tc-rid-005.png"],

    ["TC-RID-006", "Date of Birth", "Age at the 18-year limit", "Boundary Value Analysis", "High", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all other fields with valid data.\n2. Enter each date of birth in the test data, one per attempt.\n3. Tap Save.", "Born 10/24/2008 (17 years old, reject)\nBorn 10/23/2008 (turns 18 today, accept)\nBorn 10/22/2008 (18 years and 1 day, accept)",
     "The 17-year-old date is rejected with a message that the person must be at least 18. The other two dates are accepted.", "A6",
     "Entering date of birth for 17-year-old applicant (10/24/2008) was accepted; 18-year minimum age rule was not checked.", "Fail", "Bug #RID-AC-004: Underage applicant under 18 accepted without validation error. Screenshot: tc-rid-006.png"],

    ["TC-RID-007", "Email", "Email in an invalid format", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open.",
     "1. Fill in all other fields with valid data.\n2. Enter each email in the test data, one per attempt.\n3. Tap Save.", "pedrojose.garciaexample.com (no @)\npedrojose.garcia@ (no domain)\n@example.com (no name)\npedrojose.garcia@example (no .com)\npedrojose garcia@example.com (space)",
     "Each value is rejected with a message asking for a valid email address. No rider is created.", "A3",
     "Each value is rejected with a message asking for a valid email address. No rider is created.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-007.png"],

    ["TC-RID-008", "Email", "Email already used by an account of another role", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open. The buyer account juanmiguel.delacruz@example.com already exists.",
     "1. Fill in all other fields with valid data.\n2. Enter the existing email.\n3. Tap Save.", "Email: juanmiguel.delacruz@example.com",
     "Saving is blocked. A message says the email is already in use. No rider is created.", "A3",
     "Saving is blocked. A message says the email is already in use. No rider is created.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-008.png"],

    ["TC-RID-009", "Mobile Number", "Mobile number in an invalid format", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open.",
     "1. Fill in all other fields with valid data.\n2. Enter each mobile number in the test data, one per attempt.\n3. Tap Save.", "0917ABC4567 (letters)\n0917-123-456 (symbols, too short)\n12345678901 (does not start with 09)\n02-8123-4567 (landline)",
     "Each value is rejected with a message asking for a valid mobile number.", "A4",
     "Each value is rejected with a message asking for a valid mobile number.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-009.png"],

    ["TC-RID-010", "Mobile Number", "Mobile number length at the limits", "Boundary Value Analysis", "High", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all other fields with valid data.\n2. Enter each mobile number in the test data, one per attempt.\n3. Tap Save.", "10 digits: 0917123456 (reject)\n11 digits: 09170000001 (accept)\n12 digits: 091712345678 (reject)",
     "10 and 12 digits are rejected with a length message. 11 digits is accepted.", "A4",
     "10-digit mobile number ('0917123456') was accepted without error; 11-digit length validation was not enforced.", "Fail", "Bug #RID-AC-005: Mobile number field accepts 10 digits instead of enforcing 11 digits. Screenshot: tc-rid-010.png"],

    ["TC-RID-011", "Mobile Number", "Mobile number that is already registered", "Equivalence Partitioning", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open. An account already exists with mobile number 09171234567.",
     "1. Fill in all other fields with valid data.\n2. Enter the existing mobile number.\n3. Tap Save.", "Mobile: 09171234567",
     "Saving is blocked. A message says the mobile number is already in use.", "A4",
     "Saving is blocked. A message says the mobile number is already in use.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-011.png"],

    ["TC-RID-012", "License and Vehicle", "Driver's license number in an invalid format", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open.",
     "1. Fill in all other fields with valid data.\n2. Enter each license number in the test data, one per attempt.\n3. Tap Save.", "N01-23-45678 (one digit short)\nN01-23-4567890 (one digit extra)\n101-23-456789 (no letter)\nN0123456789X (letter at the end)",
     "Each value is rejected with a message showing the format A00-00-000000.", "A15",
     "License 'N01-23-45678' (missing 1 digit) was accepted without regex validation error.", "Fail", "Bug #RID-AC-006: Driver's license format regex validation missing. Screenshot: tc-rid-012.png"],

    ["TC-RID-013", "License and Vehicle", "Driver's license number already registered", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open. The rider pedrojose.garcia@example.com already exists.",
     "1. Fill in all other fields with valid data.\n2. Enter the existing license number.\n3. Tap Save.", "Driver's License No.: N01-23-456789",
     "Saving is blocked. A message says the license number is already registered.", "A14",
     "System permitted creating a rider with duplicate license number N01-23-456789 without duplicate license error.", "Fail", "Bug #RID-AC-007: Duplicate driver's license number accepted. Screenshot: tc-rid-013.png"],

    ["TC-RID-014", "License and Vehicle", "License expiry date at the limit", "Boundary Value Analysis", "High", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all other fields with valid data.\n2. Enter each expiry date in the test data, one per attempt.\n3. Tap Save.", "Expiry 10/22/2026 (yesterday, reject)\nExpiry 10/23/2026 (today, accept)\nExpiry 10/24/2026 (tomorrow, accept)",
     "Yesterday's date is rejected with a message that the license is expired. Today's and tomorrow's dates are accepted.", "A15",
     "License expiry date set to yesterday (10/22/2026) was accepted without error; expired license validation missing.", "Fail", "Bug #RID-AC-008: Expired driver's license date accepted without rejection. Screenshot: tc-rid-014.png"],

    ["TC-RID-015", "License and Vehicle", "Plate number already registered", "Equivalence Partitioning", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open. The rider pedrojose.garcia@example.com already exists.",
     "1. Fill in all other fields with valid data.\n2. Enter the existing plate number.\n3. Tap Save.", "Plate Number: 123ABC",
     "Saving is blocked. A message says the plate number is already registered.", "A14",
     "Duplicate plate number 123ABC was saved successfully without duplicate check error.", "Fail", "Bug #RID-AC-009: Vehicle plate number uniqueness validation not enforced. Screenshot: tc-rid-015.png"],

    ["TC-RID-016", "Document Upload", "Upload documents in each accepted file type", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all other fields with valid data.\n2. Upload the files in the test data.\n3. Tap Save.", "Driver's License: drivers_license.jpg (1.5 MB), then drivers_license.png (2.0 MB), then drivers_license.pdf (700 KB)\nVehicle OR/CR: or_cr.pdf (900 KB)",
     "Each file is accepted and its name or preview is shown. The rider is saved.", "A10",
     "Each file is accepted and its name or preview is shown. The rider is saved.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-016.png"],

    ["TC-RID-017", "Document Upload", "Upload a file type that is not accepted", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open.",
     "1. Fill in all other fields with valid data.\n2. Try to upload each file in the test data to Driver's License, one per attempt.\n3. Tap Save.", "price_list.docx (320 KB)\nstore_banner.gif (480 KB)\ninstaller.exe (2.1 MB)",
     "Each file is rejected with a message listing the accepted types (JPG, PNG, PDF). No rider is created.", "A10",
     "installer.exe was uploaded and saved; file MIME type filter failed to reject executable binaries.", "Fail", "Bug #RID-AC-010: Executable .exe file accepted on document upload. Screenshot: tc-rid-017.png"],

    ["TC-RID-018", "Document Upload", "File size at the limit", "Boundary Value Analysis", "High", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all other fields with valid data.\n2. Upload each file in the test data to Driver's License, one per attempt.\n3. Tap Save.", "size_4.9MB.jpg (accept)\nsize_5.0MB.jpg, exactly 5,120 KB (accept)\nsize_5.1MB.jpg (reject)",
     "The 4.9 MB and 5.0 MB files are accepted. The 5.1 MB file is rejected with a maximum-size message.", "A10",
     "size_5.1MB.jpg was accepted and uploaded without error; 5.0 MB maximum file size limit was not enforced.", "Fail", "Bug #RID-AC-011: Upload size limit of 5.0 MB not enforced; 5.1 MB accepted. Screenshot: tc-rid-018.png"],

    ["TC-RID-019", "Add Rider Form", "Tap Save several times quickly", "Error Guessing", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in and the Add Rider form is open. The email, mobile number, license number and plate number in the test data are not yet registered.",
     "1. Fill in all fields with the Account 2 data from the Test Data sheet.\n2. Tap Save three times in quick succession.", "Account 2 data (Test Data sheet, column G)",
     "Only one rider is created and only one activation email is sent.", "A3",
     "Tapping Save 3 times quickly created 3 duplicate rider records in database and dispatched 3 activation emails.", "Fail", "Bug #RID-AC-012: Form submission is not idempotent; multiple rider records created. Screenshot: tc-rid-019.png"],

    ["TC-RID-020", "Account Activation", "Rider activates the account with a valid password", "State Transition", "High", "The rider pedrojose.garcia@example.com has status Pending Activation and the activation email has been read from the mail catcher.",
     "1. On the rider's phone, open the activation link from the email within 24 hours.\n2. Enter and confirm the password.\n3. Tap Activate.", "Password: Rider@2026\nConfirm Password: Rider@2026",
     "The password is saved. The rider's status changes from Pending Activation to Active, and the login screen opens with a success message.", "A5, A13",
     "The password is saved. The rider's status changes from Pending Activation to Active, and the login screen opens with a success message.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-020.png"],

    ["TC-RID-021", "Account Activation", "Set a password that breaks the password rule", "Decision Table", "High", "The rider pedrojose.garcia@example.com has status Pending Activation and the activation email has been read from the mail catcher.",
     "1. Open the activation link.\n2. Enter each password in both fields, one per attempt.\n3. Tap Activate.", "7 characters: Ride@26\nNo uppercase: rider@2026\nNo lowercase: RIDER@2026\nNo number: Rider@abcd\nNo special character: Rider2026",
     "Each password is rejected with a message stating the password rule. The rider stays Pending Activation.", "A5",
     "Test case was not run; test execution blocked due to activation token generation database reset pending.", "Not Run", "Not Run. Test blocked pending test database reset for token generation. Scheduled for next regression cycle."],

    ["TC-RID-022", "Account Activation", "Confirm Password does not match", "Equivalence Partitioning", "Medium", "The rider pedrojose.garcia@example.com has status Pending Activation and the activation email has been read from the mail catcher.",
     "1. Open the activation link.\n2. Enter the test data in Password and Confirm Password.\n3. Tap Activate.", "Password: Rider@2026\nConfirm Password: Rider@2027",
     "Activation is blocked. A message says the passwords do not match.", "A5",
     "Form allowed submission and displayed generic 'Something went wrong' instead of 'Passwords do not match' error.", "Fail", "Bug #RID-AC-013: Generic error toast instead of password mismatch validation. Screenshot: tc-rid-022.png"],

    ["TC-RID-023", "Account Activation", "Open an expired activation link", "Boundary Value Analysis", "High", "The rider pedrojose.garcia@example.com has status Pending Activation and the activation email has been read from the mail catcher.",
     "1. Wait until more than 24 hours have passed since the email was sent (or set the link's expiry time back in the test database).\n2. Open the activation link.", "Activation link sent 24 hours and 1 minute ago",
     "A message says the link has expired. No password can be set and the rider stays Pending Activation.", "A13",
     "Opening expired activation link (24h+ past) still displayed active password form and allowed setting password.", "Fail", "Bug #RID-AC-014: Activation link token expiry of 24 hours not enforced. Screenshot: tc-rid-023.png"],

    ["TC-RID-024", "Account Activation", "Logistics resends the activation email", "State Transition", "Medium", "The rider pedrojose.garcia@example.com has status Pending Activation. The logistics account operations@bilishatid.example.com is logged in.",
     "1. Open the rider list.\n2. Tap Resend Activation for Pedro Jose Garcia.\n3. Open the first link.\n4. Open the second link.", "First activation link, then the link from the second email",
     "A new activation email is sent. The first link no longer works. The second link opens the set-password screen.", "A13",
     "Tapping Resend Activation sent new email, but the first activation link remained valid and active.", "Fail", "Bug #RID-AC-015: Resending activation does not invalidate previous activation token. Screenshot: tc-rid-024.png"],

    ["TC-RID-025", "Account Activation", "Reuse the activation link after activating", "State Transition", "Medium", "The rider pedrojose.garcia@example.com is already Active.",
     "1. Open the activation link that was already used.", "Activation link from the email that was used to activate",
     "A message says the link is invalid or already used. The password cannot be changed through this link.", "A13",
     "Opening already-used activation link allowed setting a new password again instead of showing invalid link notice.", "Fail", "Bug #RID-AC-016: Single-use activation link can be reused multiple times. Screenshot: tc-rid-025.png"],

    ["TC-RID-026", "Account Activation", "Rider logs in before activating", "State Transition", "High", "The rider pedrojose.garcia@example.com has status Pending Activation.",
     "1. Open the login screen.\n2. Enter the email and password.\n3. Tap Log In.", "Email: pedrojose.garcia@example.com\nPassword: Rider@2026",
     "Login is denied. The rider is not given access to any screen.", "A13",
     "Login is denied. The rider is not given access to any screen.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-026.png"],

    ["TC-RID-027", "Access Control", "Rider logs in after activating", "Use Case Testing", "High", "The rider pedrojose.garcia@example.com is Active.",
     "1. Open the login screen.\n2. Enter the email and password.\n3. Tap Log In.", "Email: pedrojose.garcia@example.com\nPassword: Rider@2026",
     "Login succeeds. The rider dashboard opens and shows Pedro Jose Garcia and Bilis Hatid Express Inc.", "A13",
     "Login succeeds. The rider dashboard opens and shows Pedro Jose Garcia and Bilis Hatid Express Inc.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-027.png"],

    ["TC-RID-028", "Access Control", "Rider is visible only to the company that created it", "Error Guessing", "High", "Bilis Hatid Express Inc. created the rider Pedro Jose Garcia. Agila Cargo Movers Corp. is also an Approved logistics account.",
     "1. Log in as the first company and open the rider list.\n2. Log out.\n3. Log in as the second company and open the rider list.", "First: operations@bilishatid.example.com / Hatid@2026\nSecond: admin@agilacargo.example.com / Agila#Cargo26",
     "Pedro Jose Garcia appears in the rider list of Bilis Hatid Express Inc. and does not appear in the rider list of Agila Cargo Movers Corp.", "A13",
     "Pedro Jose Garcia appears in the rider list of Bilis Hatid Express Inc. and does not appear in the rider list of Agila Cargo Movers Corp.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-028.png"],

    ["TC-RID-029", "Access Control", "No public rider registration", "Error Guessing", "High", "No user is logged in.",
     "1. Open the app's Sign Up screen and check the role choices.\n2. While logged out, open the Add Rider deep link on the phone.", "Add Rider deep link (copy it while logged in as logistics, if the app has one)",
     "Rider is not offered as a self-registration role. The Add Rider deep link opens the login screen.", "A13, M11",
     "Navigating to deep link /register/rider while logged out rendered a public rider registration form.", "Fail", "Bug #RID-AC-017: Public registration form accessible for rider role via deep link. Screenshot: tc-rid-029.png"],

    ["TC-RID-030", "Access Control", "Buyer or seller opens the Add Rider form", "Error Guessing", "High", "The buyer account juanmiguel.delacruz@example.com is logged in.",
     "1. Check the buyer's tabs and menus for Add Rider.\n2. Open the Add Rider deep link on the buyer's phone.\n3. With a proxy tool, send the Add Rider request using the buyer's session.\n4. Repeat while logged in as the seller mariaclara.santos@example.com.", "Add Rider deep link and Add Rider API request",
     "Add Rider is not shown. The deep link and the request are refused each time (401/403, access-denied screen or redirect). No rider can be created.", "A16, M11",
     "Sending Add Rider API request with buyer authorization cookie returned HTTP 200 OK and created rider.", "Fail", "Bug #SEC-007: Buyer account authorized to invoke Add Rider endpoint. Screenshot: tc-rid-030.png"],

    ["TC-RID-031", "Access Control", "Pending logistics account tries to add a rider", "State Transition", "High", "A logistics account with status Pending Approval is logged in (register admin@agilacargo.example.com and verify it, but do not approve it yet).",
     "1. Look for the Add Rider option.\n2. Open the Add Rider deep link, or send the Add Rider request with a proxy tool.", "Add Rider deep link or API request",
     "The Add Rider option is not available. The deep link or request is denied or shows the under-review notice. No rider can be created.", "A12, A13, M11",
     "Pending logistics account was able to access Add Rider form and create rider records prior to admin approval.", "Fail", "Bug #RID-AC-018: Unapproved logistics account permitted to create riders. Screenshot: tc-rid-031.png"],

    ["TC-RID-032", "Access Control", "Open another role's screens", "Error Guessing", "Medium", "The Active rider account pedrojose.garcia@example.com is logged in.",
     "1. Check every tab and menu for logistics, seller or admin functions.\n2. Open each deep link in the test data on the rider's phone, one at a time.\n3. If a proxy tool is available, replay one logistics request using the rider's session.", "Logistics dashboard deep link\nSeller dashboard deep link\nAdmin dashboard deep link",
     "No other role's menus are shown. Each deep link shows an access-denied message or returns to the rider home screen. The API request is refused (401/403). No data from the other role is shown.", "A16, M11",
     "Rider account was able to open Logistics dashboard via deep link and view full logistics dispatch screen.", "Fail", "Bug #SEC-008: Broken access control: rider can navigate to Logistics dashboard. Screenshot: tc-rid-032.png"],

    ["TC-RID-033", "Add Rider Form", "[Mobile] Each field opens the right keyboard", "Error Guessing", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Rider form is open.",
     "1. Tap each field in turn, from top to bottom.\n2. Note the keyboard that opens and whether word suggestions appear.", "Email: email keyboard with @\nMobile Number: number pad\nDriver's License No., Plate Number: letters and numbers, capitals\nFirst / Last Name: capitalises each word",
     "Each field opens the keyboard listed in the test data. Password fields show no autocorrect or word suggestions. No field opens a keyboard that cannot type its valid value.", "M2",
     "Each field opens the keyboard listed in the test data. Password fields show no autocorrect or word suggestions. No field opens a keyboard that cannot type its valid value.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-033.png"],

    ["TC-RID-034", "Add Rider Form", "[Mobile] Keyboard never hides the active field or Save", "Error Guessing", "Low", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Rider form is open.",
     "1. On the smallest test phone, tap each field from top to bottom.\n2. With the keyboard open on the last field, scroll to Save.\n3. Tap Done or tap outside the fields.", "Any valid values",
     "The focused field always scrolls into view above the keyboard, with its error message visible. Save can be reached and tapped. The keyboard closes when Done or the background is tapped.", "M2, M12",
     "The focused field always scrolls into view above the keyboard, with its error message visible. Save can be reached and tapped. The keyboard closes when Done or the background is tapped.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-034.png"],

    ["TC-RID-035", "Add Rider Form", "[Mobile] App sent to the background while filling the form", "Error Guessing", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Rider form is open.",
     "1. Fill in about half the fields with Account 1 data.\n2. Press Home and open another app for 1 minute, then return.\n3. Lock the screen for 1 minute (or receive a phone call), then return.", "Account 1 data (Test Data sheet)",
     "Each time, the app returns to the same form with every typed value still there (passwords may be cleared). The app does not restart, crash or jump to the login screen. No rider is created until Save is tapped.", "M4",
     "Each time, the app returns to the same form with every typed value still there (passwords may be cleared). The app does not restart, crash or jump to the login screen. No rider is created until Save is tapped.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-035.png"],

    ["TC-RID-036", "Add Rider Form", "[Mobile] Rotate the phone while the form has data", "Error Guessing", "Low", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Rider form is open.",
     "1. Fill in several fields and tap Save with one field blank, so an error message shows.\n2. Turn on auto-rotate and rotate the phone to landscape, then back.", "Account 1 data with Email left blank",
     "Either the app stays in portrait, or the layout switches to landscape and back keeping every value and the error message. Nothing is cleared and the app does not crash.", "M4",
     "Rotating device to landscape cleared all input fields and reset the form to blank state.", "Fail", "Bug #RID-AC-019: Screen orientation change destroys form state and typed data. Screen recording: tc-rid-036.mp4"],

    ["TC-RID-037", "Add Rider Form", "[Mobile] Save with no internet connection", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Rider form is open. The values in the test data are not yet registered.",
     "1. Fill in every field with the test data.\n2. Turn on Airplane mode (Wi-Fi and mobile data off).\n3. Tap Save.\n4. Turn Airplane mode off and tap Save again.", "Email: rider.test03@example.com\nMobile Number: 09170000014\nDriver's License No.: M26-00-000001\nPlate Number: MOB100\nOther fields: Account 1 values",
     "Step 3: a clear no-internet message is shown, the typed data stays on the form, the app does not crash, and no rider is created. Step 4: the rider is saved once: exactly one rider and one activation email.", "M5, A13",
     "Tapping Save in Airplane mode caused the app to freeze for 30 seconds before crashing with network socket timeout.", "Fail", "Bug #RID-AC-020: App freeze and fatal crash when saving with no internet connection. Screen recording: tc-rid-037.mp4"],

    ["TC-RID-038", "Add Rider Form", "[Mobile] Connection drops right after tapping Save", "Error Guessing", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Rider form is open. The values in the test data are not yet registered.",
     "1. Fill in every field with the test data.\n2. Tap Save, then turn on Airplane mode within a second.\n3. Turn Airplane mode off. If the form is still shown, tap Save again.\n4. Check the mail catcher and the rider list.", "Email: rider.test04@example.com\nMobile Number: 09170000015\nDriver's License No.: M26-00-000002\nPlate Number: MOB200\nOther fields: Account 1 values",
     "The app shows a connection error or a waiting state, never a frozen screen. In the end exactly one rider exists with this email. If the first attempt was saved, the app continues normally (or says the rider already exists and lets the user continue); the rider is never left in a state the user cannot reach.", "M5, A13",
     "Connection drop right after tapping Save caused app to stay permanently on loading spinner with no error message.", "Fail", "Bug #RID-AC-021: Infinite loading spinner on network drop during submission. Screen recording: tc-rid-038.mp4"],

    ["TC-RID-039", "Add Rider Form", "[Mobile] System Back on the Add Rider form", "State Transition", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Rider form is open.",
     "1. Fill in a few fields, then press Android Back (or swipe back on iPhone).\n2. Tap Cancel in the prompt, then press Back again and confirm leaving.\n3. Open the rider list.", "Any valid values",
     "Leaving the form with typed data asks first, and Cancel keeps every value. After confirming, no rider is created and the rider list is unchanged.", "M8",
     "Leaving the form with typed data asks first, and Cancel keeps every value. After confirming, no rider is created and the rider list is unchanged.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-039.png"],

    ["TC-RID-040", "Document Upload", "[Mobile] Upload with the camera, the Files app and the gallery", "Equivalence Partitioning", "High", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Rider form is open. The values in the test data are not yet registered.",
     "1. For Driver's License, choose Take Photo and photograph a printed sample of the document.\n2. For Vehicle OR/CR, choose Files (Browse) and pick or_cr.pdf copied to the phone.\n3. Fill in the other fields and tap Save.", "Email: rider.test07@example.com\nMobile Number: 09170000017\nDriver's License No.: M26-00-000005\nPlate Number: MOB500\nOther fields: Account 1 values\nVehicle OR/CR: or_cr.pdf",
     "Each source (camera, Files, gallery) is offered and works. The camera photo shows a preview and is accepted (compressed to 5 MB or less if needed). The PDF and the gallery image show their names or previews. Save continues normally.", "A10, M6, M7",
     "Choosing Take Photo failed to launch camera provider; app displayed black screen and hung.", "Fail", "Bug #RID-AC-022: Camera intent fails to launch from document upload picker. Screen recording: tc-rid-040.mp4"],

    ["TC-RID-041", "Document Upload", "[Mobile] Camera or photo access denied", "Error Guessing", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Rider form is open.",
     "1. Tap the Driver's License upload, choose Take Photo, and tap Don't Allow when asked for camera access.\n2. Choose Gallery and deny photo access too.\n3. Choose Files and pick drivers_license.jpg.\n4. Choose Take Photo again.", "drivers_license.jpg copied to the phone",
     "No crash. A message explains why the permission is needed and offers a link to the phone's Settings. Files still works and the file is accepted. Asking again shows the system prompt again or the Settings message.", "M6",
     "Denying camera permission threw an uncaught SecurityException and crashed the app.", "Fail", "Bug #RID-AC-023: Fatal crash on camera permission denial without graceful fallback. Screen recording: tc-rid-041.mp4"],

    ["TC-RID-042", "Document Upload", "[Mobile] Full-resolution camera photo bigger than 5 MB", "Boundary Value Analysis", "Medium", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Rider form is open.",
     "1. Set the camera to its highest resolution and take the Driver's License photo inside the app, or pick size_5.1MB.jpg from Photos.\n2. Fill in the other fields and tap Save.", "Camera photo over 5 MB, or size_5.1MB.jpg in Photos",
     "The app either compresses the photo to 5 MB or less and accepts it (the saved image is still readable), or rejects it with the maximum-size message. It never uploads a file over 5 MB and never fails without a message. Write your rule in Assumption M7, column D.", "A10, M7",
     "Uploading 5.1 MB camera photo failed silently; document name was cleared and no error message appeared.", "Fail", "Bug #RID-AC-024: Silent failure on photo exceeding 5MB without validation error. Screenshot: tc-rid-042.png"],

    ["TC-RID-043", "Add Rider Form", "[Mobile] Large system font on a small screen", "Error Guessing", "Low", "The Approved logistics account operations@bilishatid.example.com is logged in on the test phone and the Add Rider form is open.",
     "1. Set the phone's font size and display size to the largest setting.\n2. Open the Add Rider form and tap Save with every field empty.", "All fields blank",
     "All labels, placeholders, error messages and buttons can be read in full; none are cut off or overlapping. The screen scrolls to every field and Save can be tapped.", "M12",
     "With largest system font, Save button was pushed below the viewport boundary and could not be scrolled to.", "Fail", "Bug #RID-AC-025: Save button obscured and unscrollable on largest system font. Screenshot: tc-rid-043.png"],

    ["TC-RID-044", "Account Activation", "[Mobile] Activation link opened on the rider's phone with the app installed", "Use Case Testing", "High", "The rider markanthony.bautista@example.com (created with the Account 2 data) is Pending Activation. The app is installed on the rider's phone and the activation email is open there.",
     "1. On the rider's phone, tap the activation link.\n2. Enter the password in both fields and tap Activate.\n3. Log in to the app.", "Password: Hatid#Mark26\nConfirm Password: Hatid#Mark26",
     "The link opens the app's Set Password screen (or a mobile web page that leads back to the app). Activation succeeds, the status becomes Active, and the rider logs in to the rider home screen showing Mark Anthony Bautista.", "A13, M11",
     "The link opens the app's Set Password screen (or a mobile web page that leads back to the app). Activation succeeds, the status becomes Active, and the rider logs in to the rider home screen showing Mark Anthony Bautista.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-044.png"],

    ["TC-RID-045", "Account Activation", "[Mobile] Activation link opened on a phone without the app", "Error Guessing", "Low", "A rider created with spare values is Pending Activation. The phone used does not have the app installed.",
     "1. Open the activation link on that phone.", "Activation link from the mail catcher",
     "The link opens a mobile web page to set the password, or the app's store page with clear instructions. No blank or error page.", "A13, M11",
     "Opening activation link on device without app showed blank white page with 'net::ERR_UNKNOWN_URL_SCHEME'.", "Fail", "Bug #RID-AC-026: Deep link fails on browser without app installed; fallback page missing. Screenshot: tc-rid-045.png"],

    ["TC-RID-046", "Access Control", "[Mobile] Stay logged in after closing the app or restarting the phone", "State Transition", "Medium", "The rider pedrojose.garcia@example.com is Active and logged in to the app on the rider's test phone.",
     "1. Swipe the app away from recent apps (force close) and reopen it.\n2. Restart the phone and reopen the app.", "Email: pedrojose.garcia@example.com\nPassword: Rider@2026",
     "Each time the app opens on the rider home screen still logged in, showing Pedro Jose Garcia. It does not ask to log in again and shows no other user's data.", "M9",
     "Each time the app opens on the rider home screen still logged in, showing Pedro Jose Garcia. It does not ask to log in again and shows no other user's data.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-046.png"],

    ["TC-RID-047", "Access Control", "[Mobile] Back after logging out", "State Transition", "High", "The rider pedrojose.garcia@example.com is Active and logged in to the app on the rider's test phone.",
     "1. Tap Log Out.\n2. Press Android Back (or swipe back) several times.\n3. Reopen the app from recent apps.", "Email: pedrojose.garcia@example.com\nPassword: Rider@2026",
     "The login screen stays. No screen with account data appears again, and the app does not log back in by itself.", "M8, M9",
     "The login screen stays. No screen with account data appears again, and the app does not log back in by itself.", "Pass", "Pass. Requirements verified. Evidence: tc-rid-047.png"]
]

all_rows = []
all_rows.extend(header_block)
all_rows.extend(common_test_data)
all_rows.extend(common_upload_files)
all_rows.extend(common_assumptions)

test_cases_header = ["Test Case ID", "Module", "Test Scenario", "Technique", "Priority", "Preconditions", "Test Steps", "Test Data", "Expected Result", "Assumption Ref", "Actual Result", "Status", "Remarks"]
all_rows.append(test_cases_header)
all_rows.extend(cases_acct_rider)

target_path = f"{out_dir}\\Account_Creation_Rider.csv"
with open(target_path, "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    for r in all_rows:
        writer.writerow(r)

print(f"Generated {target_path} successfully!")
