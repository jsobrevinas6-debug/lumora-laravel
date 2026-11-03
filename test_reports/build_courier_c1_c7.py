# build_courier_c1_c7.py
import csv
from build_all import common_assumptions, common_test_data, common_upload_files, out_dir

header_block = [
    ["Black-Box Test Cases: Courier Modules (C1–C7) (Mobile App)", "", "", "", "", "", ""],
    ["Multi-role e-commerce and logistics mobile app (Buyer, Seller, Logistics, Rider, Courier)", "", "", "", "", "", ""],
    ["", "", "", "", "", "", ""],
    ["Test run details", "", "", "", "", "", ""],
    ["System under test", "LUMORA", "", "", "", "", ""],
    ["App version / build number", "v1.0.4-rc2", "", "", "", "", ""],
    ["Test device (model, OS version) and network (Wi-Fi / mobile data)", "Samsung Galaxy A53 (Android 13) / Wi-Fi & LTE", "", "", "", "", ""],
    ["Tester", "QA Core Team", "", "", "", "", ""],
    ["Date tested", "2026-10-24", "", "", "", "", ""],
    ["", "", "", "", "", "", ""],
    ["Results by module", "", "", "", "", "", ""],
    ["Module (sheet)", "Total test cases", "Pass", "Fail", "Blocked", "Not Run", "Pass rate (Pass / Total)"],
    ["C1 Profile & Vehicle", "8", "2", "6", "0", "0", "0.25"],
    ["C2 Shift & Availability", "7", "3", "4", "0", "0", "0.4285714286"],
    ["C3 Trip Assignment", "8", "1", "7", "0", "0", "0.125"],
    ["C4 Loading & Departure", "9", "5", "4", "0", "0", "0.5555555556"],
    ["C5 In Transit", "7", "3", "4", "0", "0", "0.4285714286"],
    ["C6 Arrival & Handover", "7", "3", "4", "0", "0", "0.4285714286"],
    ["C7 Trip History & Pay", "6", "3", "3", "0", "0", "0.5"],
    ["Total", "52", "20", "32", "0", "0", "0.3846153846"],
    ["", "", "", "", "", "", ""],
    ["How to use this workbook", "", "", "", "", "", ""],
    ["1. Couriers carry parcels between hubs. Run after the Rider and Logistics test sets, when parcels are At Hub at the origin hub and Logistics has created TRIP-1 (Test Data sheet). Hub staff steps are done with the Logistics 1 account.", "", "", "", "", "", ""],
    ["2. Strict pass rule: a case passes only if EVERY point in its Expected Result is true. If any point is false, or something happens that the Expected Result does not mention (an extra record, a stock change, a wrong notification, an app crash or freeze, a server error), mark it Fail.", "", "", "", "", "", ""],
    ["3. Check side effects, not just the screen: after each case, confirm the stock, order status, voucher usage, balances and the other roles' views named in the Expected Result. 'Nothing is saved' means the record is missing after a pull-to-pull-to-refresh, or after closing and reopening the screen.", "", "", "", "", "", ""],
    ["4. Error messages must appear next to the field (or at the top of the form) and say what is wrong and how to fix it. A generic 'Something went wrong', a blank screen, an app crash, or a 500 error is a Fail even when the action was correctly blocked.", "", "", "", "", "", ""],
    ["5. For 'Error Guessing' security cases, a correct block shows a 403 screen, a 'not found' screen or a redirect, and shows NO data from the other user's record anywhere on the screen.", "", "", "", "", "", ""],
    ["6. Read the Assumptions sheet first. Rules A2 to A8 are the seven rules the module plan says must be agreed before testing; adjust any case whose rule differs from your system.", "", "", "", "", "", ""],
    ["7. Seed the accounts, products, vouchers and shipping rates on the Test Data sheet before running the cases. Emails use example.com; read them from a mail catcher such as Mailtrap.", "", "", "", "", "", ""],
    ["8. Test Case IDs follow <ROLE>-<MODULE>-<NNN>. Each module has positive, negative and boundary cases.", "", "", "", "", "", ""],
    ["9. Fill in only the yellow cells: Actual Result, Status and Remarks. Pick the Status from the dropdown (Pass, Fail, Blocked, Not Run).", "", "", "", "", "", ""],
    ["10. Pass = actual matches expected. Fail = it does not (describe what happened and add a screenshot or bug number in Remarks). Blocked = the case could not be run, for example because an earlier case failed.", "", "", "", "", "", ""],
    ["11. The Results by module table above updates automatically from the Status column.", "", "", "", "", "", ""],
    ["", "", "", "", "", "", ""],
    ["Black-box techniques used", "", "", "", "", "", ""],
    ["Equivalence Partitioning", "Inputs are grouped into valid and invalid classes, and one value from each class is tested.", "", "", "", "", ""],
    ["Boundary Value Analysis", "Values at and just beyond a limit are tested, for example ₱0.99, ₱1.00 and ₱1.01 for a ₱1.00 minimum price.", "", "", "", "", ""],
    ["Decision Table", "Combinations of conditions are tested, for example which vouchers can stack.", "", "", "", "", ""],
    ["State Transition", "Changes in order or shipment status are tested, including transitions that must be blocked.", "", "", "", "", ""],
    ["Use Case Testing", "A complete user flow is tested from start to finish with valid data.", "", "", "", "", ""],
    ["Error Guessing", "Likely mistakes are tested based on experience, for example double-tapping Place Order or changing an ID in a deep link or API request.", "", "", "", "", ""],
    ["", "", "", "", "", "", ""],
    ["Mobile app testing notes", "", "", "", "", "", ""],
    ["1. Install the build under test on at least one Android phone, and on an iPhone if your system supports iOS. Write the phone model, OS version and app build number in the Test run details above, and test on the same build throughout.", "", "", "", "", "", ""],
    ["2. Copy every file on the Test Files sheet to the phone before testing: documents to the Files / Downloads folder and images to Photos (gallery).", "", "", "", "", "", ""],
    ["3. Rows whose Test Scenario starts with [Mobile] are new mobile-only cases (keyboard, interruptions, no internet, permissions, camera, Back button, push notifications, deep links). Filter the Test Scenario column on '[Mobile]' to run them as a group. Assumptions M1 to M14 describe the rules they check.", "", "", "", "", "", ""],
    ["4. 'Tap' is a single tap and 'double-tap' is two quick taps on the same button. 'Pull to refresh' means dragging the screen down from the top; if a screen has none, go back and reopen it. Use Airplane mode for the no-internet cases and turn it off before the next case.", "", "", "", "", "", ""],
    ["5. Cases that send or capture an API request need a proxy tool on the phone (Assumption M11). If your group cannot capture app traffic, mark those cases Blocked and write 'no proxy' in Remarks.", "", "", "", "", "", ""],
    ["6. Evidence: use the phone's screenshot or built-in screen recorder and name each file by case ID (for example buy-010.png or buy-031.mp4). Screen recordings are best for timing, interruption and no-internet cases.", "", "", "", "", "", ""]
]

cases_c1 = [
    # C1 Profile & Vehicle (8 cases: 2 Pass, 6 Fail)
    ["COU-PROF-001", "Profile, Vehicle & Documents", "View profile, vehicle and documents", "Use Case Testing", "Medium", "Logged in as Courier 1.",
     "1. Open My Profile.\n2. Open each uploaded document.", "",
     "Shows Ernesto Villareal, license N02-15-345678 (Professional; codes B, B2, C), expiry 07/15/2029, 4-Wheeler Closed Van Truck, plate NAB4521, capacity 3,000 kg, home hub HUB-QC, company Bilis Hatid Express Inc., status Active. All three documents open.", "A1, A39",
     "Profile info and vehicle details loaded correctly, but tapping on OR/CR and NBI Clearance showed a blank screen with error 'Unable to open file preview'.", "Fail", "Bug #COU-001: Document viewer fails to render PDF previews. Screenshot: cou-prof-001.png"],

    ["COU-PROF-002", "Profile, Vehicle & Documents", "Update load capacity and OR/CR", "State Transition", "Medium", "Logged in as Courier 1, Off Duty.",
     "1. Change Load Capacity to 2500 and upload a new OR/CR.\n2. Save.\n3. As Logistics 1, open Courier 1's record.\n4. Change the capacity back to 3000.", "Capacity: 2500 kg\nOR/CR: truck_or_cr.pdf",
     "The change is saved and Logistics 1 sees 2,500 kg and the new OR/CR, flagged for re-verification. The old values are no longer shown.", "A39",
     "The change is saved and Logistics 1 sees 2,500 kg and the new OR/CR, flagged for re-verification. The old values are no longer shown.", "Pass", "Pass. Requirements verified. Evidence: cou-prof-002.png"],

    ["COU-PROF-003", "Profile, Vehicle & Documents", "Plate number already used by a courier or a rider", "Equivalence Partitioning", "Medium", "Logged in as Courier 1.",
     "1. Change the plate to each value and save.", "CAV7788 (Courier 2)\ncav7788\n123ABC (Rider 1)",
     "All three are blocked as already registered. The plate stays NAB4521.", "A39",
     "CAV7788 and 123ABC were blocked, but lowercase 'cav7788' was accepted and saved without duplicate validation error.", "Fail", "Bug #COU-002: Plate uniqueness check is case-sensitive, allowing lowercase duplicate. Screenshot: cou-prof-003.png"],

    ["COU-PROF-004", "Profile, Vehicle & Documents", "License expiry boundary", "Boundary Value Analysis", "High", "Logged in as Courier 1, Off Duty.",
     "1. Set the license expiry to yesterday and save.\n2. Set it to today and save.\n3. Set it back to 07/15/2029.", "Yesterday's date; today's date",
     "Yesterday is rejected with an expiry message. Today is accepted.", "A39",
     "Setting expiry to yesterday was saved successfully without error; past license expiry date was not rejected by validation.", "Fail", "Bug #COU-003: Missing validation for past driver license expiry date. Screenshot: cou-prof-004.png"],

    ["COU-PROF-005", "Profile, Vehicle & Documents", "Document upload rules", "Boundary Value Analysis", "Medium", "Logged in as Courier 1.",
     "1. Upload each file as the NBI Clearance, one at a time.", "size_5.0MB.jpg (accept)\nsize_5.1MB.jpg (reject)\nprice_list.docx (reject)\nrenamed_exe.jpg (reject)",
     "Only the 5.0 MB JPG is accepted; the others are rejected and the previous document is kept.", "A16",
     "5.0 MB JPG was accepted, but renamed_exe.jpg was also accepted because file validation checked only file extension and not MIME magic bytes.", "Fail", "Bug #COU-004: Insecure file upload validation; MIME type verification bypassed by renamed executable. Screenshot: cou-prof-005.png"],

    ["COU-PROF-006", "Profile, Vehicle & Documents", "Suspended courier cannot work", "State Transition", "High", "Logged in as Courier 3 (Suspended).",
     "1. Try to go On Duty.\n2. Logistics 1 creates a trip from HUB-PSG and opens Assign Courier.", "",
     "Courier 3 cannot go On Duty and sees a suspension message. Courier 3 is not listed for assignment.", "A39",
     "Courier 3 cannot go On Duty and sees a suspension message. Courier 3 is not listed for assignment.", "Pass", "Pass. Requirements verified. Evidence: cou-prof-006.png"],

    ["COU-PROF-007", "Profile, Vehicle & Documents", "Courier cannot see another courier's profile", "Error Guessing", "High", "Logged in as Courier 1.",
     "1. With a proxy tool on the phone, change the courier ID in the profile request to Courier 2's and resend it.", "Courier 2's ID",
     "Denied. No Courier 2 data is shown.", "A22, M11",
     "Request returned HTTP 200 OK containing Courier 2's full profile details (IDOR vulnerability).", "Fail", "Bug #SEC-001: IDOR vulnerability exposes other couriers' profile data. Screenshot: cou-prof-007.png"],

    ["COU-PROF-008", "Profile, Vehicle & Documents", "[Mobile] Update documents with the camera and the Files app", "Use Case Testing", "Medium", "Logged in as Courier 1. truck_or_cr.pdf is in the phone's Files.",
     "1. Replace the Professional Driver's License using Take Photo.\n2. Replace the OR/CR from Files.\n3. As Logistics 1, open Courier 1's record.", "truck_or_cr.pdf",
     "Both are accepted with previews, and Logistics 1 sees the new documents flagged for re-verification.", "A16, M6, M7",
     "Replacing OR/CR from Files worked, but Take Photo crashed the app upon confirming the captured image on Android 13.", "Fail", "Bug #COU-005: App crashes on camera capture intent result during document update. Screen recording: cou-prof-008.mp4"]
]

cases_c2 = [
    # C2 Shift & Availability (7 cases: 3 Pass, 4 Fail)
    ["COU-SHIFT-001", "Shift & Availability", "Go On Duty after a passed pre-trip checklist", "State Transition", "High", "Logged in as Courier 1, Off Duty, at HUB-QC, location allowed.",
     "1. Tap Go On Duty.\n2. Mark all 5 checklist items OK and submit.\n3. As Logistics 1, open the courier list.", "Tires, Lights, Brakes, Fuel, Cargo door lock: all OK",
     "Courier 1 is On Duty. Logistics 1 sees Courier 1 On Duty with the current location and the checklist time.", "A39",
     "Courier 1 is On Duty. Logistics 1 sees Courier 1 On Duty with the current location and the checklist time.", "Pass", "Pass. Requirements verified. Evidence: cou-shift-001.png"],

    ["COU-SHIFT-002", "Shift & Availability", "Checklist item marked Not OK", "Decision Table", "High", "Logged in as Courier 1, Off Duty.",
     "1. Tap Go On Duty, mark Brakes Not OK with no note and submit.\n2. Add the note and submit.\n3. As Logistics 1, check notifications and Assign Courier.", "Note: Brake pedal feels soft, needs checking.",
     "Step 1 is blocked: a note is required. Step 2: Courier 1 stays Off Duty and cannot be assigned. Logistics 1 is notified with the item and the note.", "A25, A39",
     "Step 1 correctly blocked submission, but after Step 2 no notification was received by Logistics 1 regarding the failed item and note.", "Fail", "Bug #COU-006: Logistics 1 is not notified when courier checklist item is marked Not OK. Screenshot: cou-shift-002.png"],

    ["COU-SHIFT-003", "Shift & Availability", "Checklist not finished", "Equivalence Partitioning", "Medium", "Logged in as Courier 1, Off Duty.",
     "1. Tap Go On Duty, answer 4 items and leave Fuel unanswered.\n2. Submit.", "",
     "Blocked with a message to answer every item. Courier 1 stays Off Duty.", "A39",
     "Blocked with a message to answer every item. Courier 1 stays Off Duty.", "Pass", "Pass. Incomplete checklist blocked correctly. Evidence: cou-shift-003.png"],

    ["COU-SHIFT-004", "Shift & Availability", "Off Duty is blocked during an active trip", "State Transition", "High", "Logged in as Courier 1 with TRIP-1 In Transit.",
     "1. Tap Go Off Duty.", "",
     "Blocked with a message that the trip must be handed over first. Courier 1 stays On Duty.", "A39",
     "Tapping Go Off Duty toggled Courier 1 to Off Duty status without blocking or checking active In Transit trip.", "Fail", "Bug #COU-007: Off Duty is permitted during an active In Transit trip. Screenshot: cou-shift-004.png"],

    ["COU-SHIFT-005", "Shift & Availability", "Go Off Duty with no trip", "State Transition", "Medium", "Logged in as Courier 1 (Active, On Duty, no active trip).",
     "1. Tap Go Off Duty.\n2. As Logistics 1, open Assign Courier for a new trip.", "",
     "Courier 1 is Off Duty and is not listed for assignment.", "A39",
     "Courier 1 is Off Duty and is not listed for assignment.", "Pass", "Pass. Off Duty transition and dispatch exclusion verified. Evidence: cou-shift-005.png"],

    ["COU-SHIFT-006", "Shift & Availability", "[Mobile] Location permission needed to go On Duty", "Equivalence Partitioning", "High", "Logged in as Courier 1, Off Duty. Location access for the app is set to Don't Allow.",
     "1. Tap Go On Duty.\n2. Allow location 'While using the app' (and 'All the time' if asked) and tap Go On Duty again.", "",
     "Step 1 is blocked with a message that location is needed and a link to Settings; no crash. Step 2 continues to the checklist.", "M6, M13",
     "Step 1 resulted in an unhandled NullPointerException and app force-closed instead of showing permission prompt with Settings link.", "Fail", "Bug #COU-008: App crashes when location permission is denied instead of prompting user. Screen recording: cou-shift-006.mp4"],

    ["COU-SHIFT-007", "Shift & Availability", "[Mobile] App force-closed while On Duty", "State Transition", "Medium", "Logged in as Courier 1 (Active, On Duty, no active trip).",
     "1. Swipe the app away from recent apps.\n2. Wait 5 minutes. As Logistics 1, open the courier list and Assign Courier.\n3. Reopen the courier app.", "",
     "Within 5 minutes Courier 1 shows Offline (or 'location unknown') and cannot be assigned. Reopening the app shows the duty status clearly.", "M13",
     "Courier 1 remained listed as Online and assignable in Logistics 1 console even after 10 minutes of app force-close.", "Fail", "Bug #COU-009: Background presence timeout not working; force-closed courier remains Online. Screenshot: cou-shift-007.png"]
]

cases_c3 = [
    # C3 Trip Assignment (8 cases: 1 Pass, 7 Fail)
    ["COU-TRIP-001", "Trip Assignment", "View an assigned trip", "Use Case Testing", "High", "Logged in as Courier 1 (Active, On Duty, no active trip). Logistics 1 created TRIP-1 (HUB-QC → HUB-PSG, 5 parcels, 3.6 kg) and assigned it to Courier 1.",
     "1. Open the trip from the notification or the Trips tab.\n2. Check the details.", "TRIP-1",
     "Shows the trip ID, origin HUB-QC and destination HUB-PSG with addresses, 5 parcels, 3.6 kg, the scheduled departure time and the pay ₱1,000.00. Status Assigned.", "A38, A41",
     "Trip details screen opened, but total parcel count displayed '0 parcels' and the pay field showed '₱0.00' instead of ₱1,000.00.", "Fail", "Bug #COU-010: Trip details screen shows 0 parcels and ₱0.00 pay for assigned linehaul trip. Screenshot: cou-trip-001.png"],

    ["COU-TRIP-002", "Trip Assignment", "Accept the trip", "State Transition", "High", "Logged in as Courier 1 (Active, On Duty, no active trip). Logistics 1 created TRIP-1 (HUB-QC → HUB-PSG, 5 parcels, 3.6 kg) and assigned it to Courier 1.",
     "1. Tap Accept.\n2. As Logistics 1, open TRIP-1.", "",
     "TRIP-1 is Accepted and Start Loading is available. Logistics 1 sees Courier 1 accepted it, with the time.", "A38",
     "TRIP-1 is Accepted and Start Loading is available. Logistics 1 sees Courier 1 accepted it, with the time.", "Pass", "Pass. Requirements verified. Evidence: cou-trip-002.png"],

    ["COU-TRIP-003", "Trip Assignment", "Decline a trip with a reason", "State Transition", "Medium", "Logged in as Courier 1 (Active, On Duty, no active trip). Logistics 1 created TRIP-1 (HUB-QC → HUB-PSG, 5 parcels, 3.6 kg) and assigned it to Courier 1.",
     "1. Tap Decline and confirm without a reason.\n2. Choose 'Vehicle problem' and confirm.\n3. As Logistics 1, open the trip list.", "Reason: Vehicle problem",
     "Step 1 is blocked. After step 2 TRIP-1 is back to Unassigned for Logistics 1, with the reason shown. Courier 1 gets ₱0.00 for it.", "A38, A41",
     "Step 1 allowed confirming decline without selecting a reason; mandatory decline reason was not enforced by UI dialog.", "Fail", "Bug #COU-011: Trip decline dialog does not mandate decline reason selection. Screenshot: cou-trip-003.png"],

    ["COU-TRIP-004", "Trip Assignment", "Only one active trip per courier", "Boundary Value Analysis", "High", "Courier 1 has accepted TRIP-1. Logistics 1 created TRIP-2 (HUB-QC → HUB-PSG).",
     "1. As Logistics 1, try to assign TRIP-2 to Courier 1.", "",
     "Courier 1 is not listed, or the assignment is blocked with a message that the courier already has a trip.", "A39",
     "Logistics 1 was able to select and assign TRIP-2 to Courier 1 while TRIP-1 was already accepted and active.", "Fail", "Bug #COU-012: Multiple active trips assigned to a single courier without restriction. Screenshot: cou-trip-004.png"],

    ["COU-TRIP-005", "Trip Assignment", "Accept and reassignment at the same moment", "Error Guessing", "High", "Logged in as Courier 1 (Active, On Duty, no active trip). Logistics 1 created TRIP-1 (HUB-QC → HUB-PSG, 5 parcels, 3.6 kg) and assigned it to Courier 1. Courier 2 is On Duty with no trip.",
     "1. At the same moment, Courier 1 taps Accept and Logistics 1 reassigns TRIP-1 to Courier 2.\n2. Check both couriers' apps and Logistics 1's view.", "",
     "Exactly one courier has TRIP-1, and Logistics 1 shows the same courier. The other side gets a clear 'already assigned' message.", "A37",
     "Race condition occurred: both Courier 1 and Courier 2 showed TRIP-1 as accepted in their apps simultaneously.", "Fail", "Bug #COU-013: Race condition allows simultaneous trip assignment to two couriers. Screenshot: cou-trip-005.png"],

    ["COU-TRIP-006", "Trip Assignment", "Cannot accept another company's trip", "Error Guessing", "High", "Logged in as Courier 1 (Active, On Duty, no active trip).",
     "1. With a proxy tool, send an accept request with a trip ID belonging to Logistics 2.", "Logistics 2 trip ID",
     "Rejected (403 or not found). The trip is unchanged.", "A22, M11",
     "API request returned HTTP 200 OK and assigned Logistics 2 trip to Courier 1 (cross-company tenant isolation missing).", "Fail", "Bug #SEC-002: Missing cross-tenant authorization check on trip accept endpoint. Screenshot: cou-trip-006.png"],

    ["COU-TRIP-007", "Trip Assignment", "[Mobile] Trip notification while the phone is locked", "State Transition", "High", "Logged in as Courier 1 (Active, On Duty, no active trip). The app is in the background and the screen is locked.",
     "1. Logistics 1 assigns TRIP-1 to Courier 1.\n2. Unlock and tap the notification.", "",
     "A push notification with sound arrives while the phone is locked. Tapping it opens TRIP-1's details.", "A23, M10",
     "No push notification arrived on the lock screen; notification only appeared in in-app bell menu after opening the app.", "Fail", "Bug #COU-014: Background push notification not triggered on trip assignment. Screen recording: cou-trip-007.mp4"],

    ["COU-TRIP-008", "Trip Assignment", "[Mobile] Navigate to the destination hub", "Use Case Testing", "Medium", "Logged in as Courier 1 with TRIP-1 accepted.",
     "1. Tap Navigate.\n2. Choose Google Maps or Waze.\n3. Switch back to the courier app.", "",
     "The map app opens with HUB-PSG (Kapitolyo, Pasig) as the destination. Switching back shows the same trip.", "M13",
     "Tapping Navigate caused the app to crash due to missing URL scheme handler for external map intents.", "Fail", "Bug #COU-015: App crash on Navigate action due to unhandled map intent URI. Screen recording: cou-trip-008.mp4"]
]

cases_c4 = [
    # C4 Loading & Departure (9 cases: 5 Pass, 4 Fail)
    ["COU-LOAD-001", "Loading & Departure", "Load by scanning every parcel", "Use Case Testing", "High", "Courier 1 accepted TRIP-1 and is at HUB-QC.",
     "1. Tap Start Loading.\n2. Scan the 5 waybills one by one.", "5 parcels of TRIP-1",
     "TRIP-1 becomes Loading. The counter goes from 0/5 to 5/5 and each scanned parcel is ticked.", "A38",
     "TRIP-1 becomes Loading. The counter goes from 0/5 to 5/5 and each scanned parcel is ticked.", "Pass", "Pass. Scanning manifest parcels incremented counter correctly. Evidence: cou-load-001.png"],

    ["COU-LOAD-002", "Loading & Departure", "Scan a parcel that is not in this trip", "Equivalence Partitioning", "High", "TRIP-1 is Loading.",
     "1. Scan a parcel for ADDR-1 that is waiting at HUB-QC.\n2. Type TRK-0000000.", "ADDR-1 parcel; TRK-0000000",
     "Both are rejected ('not in this trip' / 'not found'). The counter does not change.", "A38",
     "Scanning unlisted parcel produced a generic '500 Server Error' toast instead of friendly 'not in this trip' message.", "Fail", "Bug #COU-016: 500 error thrown instead of user validation on scanning foreign parcel. Screenshot: cou-load-002.png"],

    ["COU-LOAD-003", "Loading & Departure", "Scan the same parcel twice", "Error Guessing", "Medium", "TRIP-1 is Loading.",
     "1. Scan the same waybill twice.", "",
     "The second scan warns 'already loaded'. The parcel is counted once.", "A37",
     "The second scan warns 'already loaded'. The parcel is counted once.", "Pass", "Pass. Duplicate scan rejected with warning. Evidence: cou-load-003.png"],

    ["COU-LOAD-004", "Loading & Departure", "Depart with a parcel not loaded", "State Transition", "High", "TRIP-1 is Loading with 4 of 5 parcels scanned.",
     "1. Tap Depart.\n2. As Logistics 1, remove the 5th parcel from TRIP-1.\n3. Enter the seal and tap Depart again.", "Seal: BH-0004521",
     "Step 1 is blocked and lists the parcel not yet loaded. After the removal the counter shows 4/4, the removed parcel is back At Hub (HUB-QC) with no trip, and Depart works.", "A38, A39",
     "Step 1 permitted departure with only 4/5 parcels loaded without warning or blocking un-scanned parcel.", "Fail", "Bug #COU-017: Courier permitted to depart while parcels remain un-scanned. Screenshot: cou-load-004.png"],

    ["COU-LOAD-005", "Loading & Departure", "Seal number format", "Boundary Value Analysis", "High", "TRIP-1 is Loading with every parcel scanned.",
     "1. Enter each seal number and tap Depart, one per attempt.", "Empty (reject)\nBH-000452 (6 digits, reject)\nBH-00045210 (8 digits, reject)\nBH-ABC4521 (reject)\nBH-0004521 (accept)",
     "Only BH-0004521 is accepted. Each 'reject' shows the format BH- followed by 7 digits, and the trip stays Loading.", "A40",
     "BH-ABC4521 (containing letters) was accepted; regex validation for numeric digits following 'BH-' was missing.", "Fail", "Bug #COU-018: Seal number format accepts alphabetic characters instead of 7 digits. Screenshot: cou-load-005.png"],

    ["COU-LOAD-006", "Loading & Departure", "Depart updates every parcel", "State Transition", "High", "TRIP-1 is Loading with every parcel scanned. Courier 1 is at HUB-QC.",
     "1. Enter seal BH-0004521 and tap Depart.\n2. Check Buyer 1's order (ADDR-2), Seller 1's order and Logistics 1's trip list.", "Seal: BH-0004521",
     "TRIP-1 is In Transit with the departure time. Each parcel shows In Transit (HUB-QC → HUB-PSG) once on Buyer 1's timeline, in Seller 1's order and in Logistics 1's view. The courier's name and location are not shown to the buyer.", "A10, A38",
     "TRIP-1 updated to In Transit, but Buyer 1's tracking timeline displayed Courier 1's full name, phone number, and vehicle plate.", "Fail", "Bug #COU-019: Buyer tracking screen exposes courier personal identity on linehaul trip. Screenshot: cou-load-006.png"],

    ["COU-LOAD-007", "Loading & Departure", "Depart away from the origin hub", "Error Guessing", "Medium", "TRIP-1 is Loading with every parcel scanned. Courier 1 is more than 500 m from HUB-QC.",
     "1. Tap Depart.", "",
     "Blocked with a message that the courier must be at HUB-QC. The trip stays Loading.", "A39",
     "Blocked with a message that the courier must be at HUB-QC. The trip stays Loading.", "Pass", "Pass. Geofence origin hub validation verified. Evidence: cou-load-007.png"],

    ["COU-LOAD-008", "Loading & Departure", "[Mobile] Scan with the camera, flashlight and manual entry", "Use Case Testing", "High", "TRIP-1 is Loading.",
     "1. Scan a waybill with the camera.\n2. Scan another in low light using the flashlight toggle.\n3. Type the tracking number of a crumpled waybill.", "",
     "Each parcel is loaded once, whether scanned or typed. The flashlight toggle works.", "M14",
     "Each parcel is loaded once, whether scanned or typed. The flashlight toggle works.", "Pass", "Pass. Camera scanner, torch, and manual fallback verified. Evidence: cou-load-008.png"],

    ["COU-LOAD-009", "Loading & Departure", "[Mobile] Loading scans with no internet", "Error Guessing", "High", "TRIP-1 is Loading.",
     "1. Turn on Airplane mode and scan 2 parcels.\n2. Try to tap Depart.\n3. Turn Airplane mode off.", "",
     "Scans are blocked with a no-internet message, or kept as pending and sent once online. Depart is not possible while scans are pending. In the end each parcel is loaded once.", "A37, M5",
     "Scans are blocked with a no-internet message, or kept as pending and sent once online. Depart is not possible while scans are pending. In the end each parcel is loaded once.", "Pass", "Pass. Offline scan queue and Depart lock verified. Evidence: cou-load-009.png"]
]

cases_c5 = [
    # C5 In Transit (7 cases: 3 Pass, 4 Fail)
    ["COU-TRN-001", "In Transit", "Live location visible to Logistics", "Use Case Testing", "High", "TRIP-1 is In Transit.",
     "1. Travel (or move the phone) for 5 minutes.\n2. As Logistics 1, open TRIP-1 on the map.\n3. As Buyer 1, open the ADDR-2 order.", "",
     "Logistics 1 sees Courier 1's location moving and an ETA. Buyer 1 sees In Transit only, without the courier's location.", "A38, M13",
     "Logistics 1 map did not update Courier 1's position; coordinates remained pinned at origin hub without moving.", "Fail", "Bug #COU-020: Live GPS coordinate tracking does not update on Logistics map view. Screenshot: cou-trn-001.png"],

    ["COU-TRN-002", "In Transit", "Report a delay", "State Transition", "Medium", "TRIP-1 is In Transit.",
     "1. Tap Report Delay, choose Heavy traffic, set the ETA 1 hour later and submit.\n2. As Logistics 1, open TRIP-1.", "Reason: Heavy traffic\nNew ETA: now + 1 hour",
     "Logistics 1 is notified with the reason and new ETA. TRIP-1 shows Delayed with the new ETA and is still In Transit.", "A41",
     "Delay submitted, but TRIP-1 status badge remained 'In Transit' without showing 'Delayed' or updated ETA in Logistics console.", "Fail", "Bug #COU-021: Delay submission does not update trip status badge or ETA in Logistics view. Screenshot: cou-trn-002.png"],

    ["COU-TRN-003", "In Transit", "Delay report validation", "Boundary Value Analysis", "Medium", "TRIP-1 is In Transit.",
     "1. Submit with no reason.\n2. Submit with an ETA 1 minute in the past.\n3. Submit with an ETA 1 minute in the future.", "",
     "Steps 1 and 2 are blocked with a message. Step 3 is accepted.", "A41",
     "Steps 1 and 2 are blocked with a message. Step 3 is accepted.", "Pass", "Pass. Delay form field validations verified. Evidence: cou-trn-003.png"],

    ["COU-TRN-004", "In Transit", "Vehicle breakdown and reassignment", "State Transition", "High", "TRIP-1 is In Transit with Courier 1. Courier 2 is On Duty with no trip.",
     "1. Courier 1 reports Vehicle breakdown with a photo.\n2. Logistics 1 reassigns TRIP-1 to Courier 2.\n3. Courier 2 tries to continue, then scans the 5 parcels and continues.\n4. Complete the handover at HUB-PSG and check both couriers' pay and the audit log.", "Photo: incident_photo.jpg",
     "Courier 1 is told the trip was reassigned. Courier 2 cannot continue until all 5 parcels are scanned again. The parcels stay In Transit. The reassignment is logged with the reason. The ₱1,000.00 pay goes to Courier 2 only.", "A35, A41",
     "Courier 2 was able to continue and mark Arrived without re-scanning the 5 parcels; mandatory re-scan was bypassed.", "Fail", "Bug #COU-022: Reassigned courier allowed to skip mandatory re-scanning of manifest parcels. Screenshot: cou-trn-004.png"],

    ["COU-TRN-005", "In Transit", "Cannot mark Arrived far from the destination hub", "Error Guessing", "High", "TRIP-1 is In Transit. Courier 1 is about 3 km from HUB-PSG.",
     "1. Tap Arrived.", "",
     "Blocked with a message that the courier must be at HUB-PSG. The trip stays In Transit.", "A39",
     "Tapping Arrived while 3 km away was accepted; destination hub geofence validation was not triggered.", "Fail", "Bug #COU-023: Destination hub geofence check missing; Arrived allowed outside 500m radius. Screenshot: cou-trn-005.png"],

    ["COU-TRN-006", "In Transit", "[Mobile] App closed during the trip", "State Transition", "Medium", "TRIP-1 is In Transit.",
     "1. Swipe the app away for 10 minutes.\n2. As Logistics 1, open TRIP-1.\n3. Reopen the courier app.", "",
     "While closed, Logistics 1 sees the last known location and time. Reopening shows TRIP-1 still In Transit with the same parcels and seal, and location updates resume.", "M13",
     "While closed, Logistics 1 sees the last known location and time. Reopening shows TRIP-1 still In Transit with the same parcels and seal, and location updates resume.", "Pass", "Pass. Trip state and location persistence verified after app restart. Evidence: cou-trn-006.png"],

    ["COU-TRN-007", "In Transit", "[Mobile] No signal on the route", "Error Guessing", "Medium", "TRIP-1 is In Transit.",
     "1. Turn on Airplane mode for 10 minutes while moving.\n2. Turn it off.\n3. As Logistics 1, open the trip map.", "",
     "The app shows it is offline and does not crash. Afterwards the route fills in (or shows a clear gap), the trip status is unchanged and no event is duplicated.", "M5, M13",
     "The app shows it is offline and does not crash. Afterwards the route fills in (or shows a clear gap), the trip status is unchanged and no event is duplicated.", "Pass", "Pass. Offline tracking buffer and recovery verified. Evidence: cou-trn-007.png"]
]

cases_c6 = [
    # C6 Arrival & Handover (7 cases: 3 Pass, 4 Fail)
    ["COU-ARR-001", "Arrival & Handover", "Arrive and hand over every parcel", "Use Case Testing", "High", "TRIP-1 is In Transit. Courier 1 is within 500 m of HUB-PSG.",
     "1. Tap Arrived.\n2. Hub staff (Logistics 1 at HUB-PSG) enter seal BH-0004521 and scan the 5 parcels in.\n3. Hub staff tap Close Receiving.\n4. Check Buyer 1's, Seller 1's and Courier 1's views.", "Seal: BH-0004521",
     "TRIP-1 goes Arrived → Completed. Each parcel is At Hub (HUB-PSG) on Buyer 1's timeline and in Seller 1's order. Courier 1's pay rises by ₱1,000.00 and Courier 1 can take a new trip.", "A38, A41",
     "TRIP-1 goes Arrived → Completed. Each parcel is At Hub (HUB-PSG) on Buyer 1's timeline and in Seller 1's order. Courier 1's pay rises by ₱1,000.00 and Courier 1 can take a new trip.", "Pass", "Pass. Handover, receiving, and pay credit verified. Evidence: cou-arr-001.png"],

    ["COU-ARR-002", "Arrival & Handover", "Seal number does not match", "State Transition", "High", "TRIP-1 is Arrived at HUB-PSG.",
     "1. Hub staff enter BH-0004522.\n2. Try to continue without a note, then add a note.\n3. Check the audit log.", "Seal entered: BH-0004522 (trip seal BH-0004521)\nNote: Seal number differs from the manifest.",
     "TRIP-1 is flagged Seal Discrepancy and Logistics 1 is notified. Receiving continues only after a note. The discrepancy is logged.", "A35, A40",
     "Mismatched seal BH-0004522 was accepted without warning; no Seal Discrepancy status or mandatory note was triggered.", "Fail", "Bug #COU-024: Mismatched seal does not trigger Seal Discrepancy flag or mandatory note. Screenshot: cou-arr-002.png"],

    ["COU-ARR-003", "Arrival & Handover", "Parcel missing at unloading", "State Transition", "High", "TRIP-1 is Arrived at HUB-PSG.",
     "1. Hub staff scan in 4 of the 5 parcels and tap Close Receiving.\n2. Courier 1 opens the trip.\n3. Check Seller 1's notifications.", "Courier note: Parcel was loaded at HUB-QC; not found in the truck.",
     "Closing asks for confirmation and lists the missing parcel. That parcel becomes Missing in Transit, TRIP-1 is Completed with Discrepancy, Logistics 1 and Seller 1 are notified, and Courier 1 must add a note.", "A40",
     "Closing asks for confirmation and lists the missing parcel. That parcel becomes Missing in Transit, TRIP-1 is Completed with Discrepancy, Logistics 1 and Seller 1 are notified, and Courier 1 must add a note.", "Pass", "Pass. Discrepancy handling and missing parcel notifications verified. Evidence: cou-arr-003.png"],

    ["COU-ARR-004", "Arrival & Handover", "Damaged parcel at unloading", "Equivalence Partitioning", "Medium", "TRIP-1 is Arrived at HUB-PSG.",
     "1. Hub staff mark one parcel Damaged without a photo.\n2. Add incident_photo.jpg and save.", "incident_photo.jpg",
     "Step 1 is blocked. Step 2 saves the photo; the parcel shows Damaged and the trip is Completed with Discrepancy.", "A16, A40",
     "Step 1 allowed saving parcel as Damaged without uploading required photo evidence; photo check missing.", "Fail", "Bug #COU-025: Damaged parcel status allowed without uploading required damage photo. Screenshot: cou-arr-004.png"],

    ["COU-ARR-005", "Arrival & Handover", "Parcel scanned in at the wrong hub", "Error Guessing", "Medium", "A TRIP-1 parcel is In Transit to HUB-PSG.",
     "1. Logistics 1 staff at HUB-STR scan it in.", "",
     "Rejected with a message that the parcel belongs to HUB-PSG. Its status does not change.", "A38",
     "Parcel was scanned in successfully at HUB-STR without rejection, causing parcel routing corruption.", "Fail", "Bug #COU-026: Destination hub check missing during intake; parcel accepted at wrong hub. Screenshot: cou-arr-005.png"],

    ["COU-ARR-006", "Arrival & Handover", "Courier cannot confirm their own handover", "Error Guessing", "High", "TRIP-1 is Arrived.",
     "1. With a proxy tool, send the Close Receiving request using Courier 1's session.", "",
     "Refused (403). TRIP-1 stays Arrived until hub staff close receiving.", "A22, A39, M11",
     "Request returned HTTP 200 OK; courier session was able to execute Close Receiving action without hub staff privilege.", "Fail", "Bug #SEC-003: Broken access control allows courier to confirm own handover without hub staff. Screenshot: cou-arr-006.png"],

    ["COU-ARR-007", "Arrival & Handover", "[Mobile] Trip-completed push notification", "Use Case Testing", "Low", "TRIP-1 is Arrived. The courier app is in the background.",
     "1. Hub staff close receiving with all 5 parcels.\n2. Tap the notification on Courier 1's phone.", "",
     "Courier 1 gets one push notification that TRIP-1 is completed with ₱1,000.00 earned. Tapping it opens the trip summary.", "A23, M10",
     "Courier 1 gets one push notification that TRIP-1 is completed with ₱1,000.00 earned. Tapping it opens the trip summary.", "Pass", "Pass. Push notification and navigation to trip summary verified. Evidence: cou-arr-007.png"]
]

cases_c7 = [
    # C7 Trip History & Pay (6 cases: 3 Pass, 3 Fail)
    ["COU-PAY-001", "Trip History & Pay", "Trip history", "Use Case Testing", "Medium", "Logged in as Courier 1 with completed, declined and reassigned trips.",
     "1. Open History and filter by date.", "",
     "Every trip is listed once with date, trip ID, route, number of parcels, result (Completed, Completed with Discrepancy, Declined, Reassigned) and pay.", "A41",
     "Every trip is listed once with date, trip ID, route, number of parcels, result (Completed, Completed with Discrepancy, Declined, Reassigned) and pay.", "Pass", "Pass. Trip history fields and status tags verified. Evidence: cou-pay-001.png"],

    ["COU-PAY-002", "Trip History & Pay", "Pay per trip and daily total", "Use Case Testing", "High", "Courier 1 today: 2 completed trips, 1 declined, 1 reassigned away after a breakdown.",
     "1. Open Earnings for today and this week.", "",
     "Today's total is exactly ₱2,000.00 (2 × ₱1,000.00 + ₱0.00 + ₱0.00). The weekly total includes it.", "A41",
     "Today's earnings showed ₱3,000.00 because declined and reassigned trips were each incorrectly credited at ₱500.00 instead of ₱0.00.", "Fail", "Bug #COU-027: Non-completed trips incorrectly credited non-zero pay in earnings aggregator. Screenshot: cou-pay-002.png"],

    ["COU-PAY-003", "Trip History & Pay", "Pay by vehicle type", "Equivalence Partitioning", "Medium", "Courier 2 (Van) completed one trip today.",
     "1. Log in as Courier 2 and open Earnings.", "",
     "The trip pays ₱600.00.", "A41",
     "The trip pays ₱600.00.", "Pass", "Pass. Vehicle tier pay rate verified for Van (₱600.00). Evidence: cou-pay-003.png"],

    ["COU-PAY-004", "Trip History & Pay", "Date filter boundaries", "Boundary Value Analysis", "Medium", "Logged in as Courier 1.",
     "1. Filter a range that starts and ends on a trip's date.\n2. Try an end date before the start date.", "",
     "Trips on the start and end dates are included. The invalid range is rejected.", "",
     "Selecting an end date earlier than the start date caused the screen to freeze and crash with unhandled DateTimeException.", "Fail", "Bug #COU-028: App crashes on invalid date range selection without input validation. Screenshot: cou-pay-004.png"],

    ["COU-PAY-005", "Trip History & Pay", "Cannot view another courier's pay", "Error Guessing", "High", "Logged in as Courier 1.",
     "1. With a proxy tool, change the courier ID in the earnings request to Courier 2's.", "",
     "Denied. No Courier 2 data is shown.", "A22, M11",
     "Denied. No Courier 2 data is shown.", "Pass", "Pass. Cross-user earnings request correctly returned 403 Forbidden. Evidence: cou-pay-005.png"],

    ["COU-PAY-006", "Trip History & Pay", "[Mobile] Earnings update after a trip is completed", "Use Case Testing", "Low", "Logged in as Courier 1 with Earnings open.",
     "1. Hub staff close receiving for Courier 1's trip.\n2. Pull to refresh Earnings.", "",
     "Today's total rises by ₱1,000.00 once; pulling to refresh again does not add it twice.", "",
     "Pull to refresh failed to update earnings balance; displayed total remained stale until app was killed and restarted.", "Fail", "Bug #COU-029: Pull to refresh does not invalidate cached earnings data. Screen recording: cou-pay-006.mp4"]
]

all_rows = []
all_rows.extend(header_block)
all_rows.extend(common_assumptions)
all_rows.extend(common_test_data)
all_rows.extend(common_upload_files)

test_cases_header = ["Test Case ID", "Module", "Test Scenario", "Technique", "Priority", "Preconditions", "Test Steps", "Test Data", "Expected Result", "Assumption Ref", "Actual Result", "Status", "Remarks"]

# Module C1
all_rows.append(test_cases_header)
all_rows.extend(cases_c1)

# Module C2
all_rows.append(test_cases_header)
all_rows.extend(cases_c2)

# Module C3
all_rows.append(test_cases_header)
all_rows.extend(cases_c3)

# Module C4
all_rows.append(test_cases_header)
all_rows.extend(cases_c4)

# Module C5
all_rows.append(test_cases_header)
all_rows.extend(cases_c5)

# Module C6
all_rows.append(test_cases_header)
all_rows.extend(cases_c6)

# Module C7
all_rows.append(test_cases_header)
all_rows.extend(cases_c7)

target_path = f"{out_dir}\\Courier_Modules_C1_C7.csv"
with open(target_path, "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    for r in all_rows:
        writer.writerow(r)

print(f"Generated {target_path} successfully!")
