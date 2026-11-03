# build_rider_r1_r7.py
import csv
from build_all import common_assumptions, common_test_data, common_upload_files, out_dir

header_block = [
    ["Black-Box Test Cases: Rider Modules (R1–R7) (Mobile App)", "", "", "", "", "", ""],
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
    ["R1 Profile & Vehicle", "8", "3", "5", "0", "0", "0.375"],
    ["R2 Availability", "7", "4", "3", "0", "0", "0.5714285714"],
    ["R3 Job Assignment", "9", "2", "7", "0", "0", "0.2222222222"],
    ["R4 Pickup", "7", "4", "3", "0", "0", "0.5714285714"],
    ["R5 Delivery", "11", "4", "7", "0", "0", "0.3636363636"],
    ["R6 Failed Delivery", "5", "2", "3", "0", "0", "0.4"],
    ["R7 Earnings & COD", "6", "1", "5", "0", "0", "0.1666666667"],
    ["Total", "53", "20", "33", "0", "0", "0.3773584906"],
    ["", "", "", "", "", "", ""],
    ["How to use this workbook", "", "", "", "", "", ""],
    ["1. Riders need orders that sellers have marked Ready for Pickup. Run with the Logistics test set.", "", "", "", "", "", ""],
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

cases_r1 = [
    # R1 Profile & Vehicle (8 cases: 3 Pass, 5 Fail)
    ["RID-PROF-001", "Profile, Vehicle & Documents", "View profile, vehicle and verification status", "Use Case Testing", "Medium", "Logged in as Rider 1.",
     "1. Open My Profile.\n2. Open each uploaded document.", "",
     "Shows Pedro Jose Garcia, license N01-23-456789, expiry 03/22/2030, Motorcycle, plate 123ABC, company Bilis Hatid Express Inc., status Active. Both documents open.", "A1",
     "Shows Pedro Jose Garcia, license N01-23-456789, expiry 03/22/2030, Motorcycle, plate 123ABC, company Bilis Hatid Express Inc., status Active. Both documents open.", "Pass", "Pass. Requirements verified. Evidence: rid-prof-001.png"],

    ["RID-PROF-002", "Profile, Vehicle & Documents", "Update vehicle details", "State Transition", "Medium", "Logged in as Rider 1.",
     "1. Change the plate number and upload a new OR/CR.\n2. Save.\n3. As Logistics 1, open Rider 1's record.", "Plate: 789GHI\nOR/CR: or_cr.pdf (900 KB)",
     "The change is saved and shown to Logistics 1 with the new OR/CR, flagged for re-verification. The old plate is no longer shown.", "",
     "The new plate and OR/CR were saved, but Logistics 1 dashboard did not show the re-verification badge and still displayed the old plate until manual server restart.", "Fail", "Bug #RID-001: Logistics portal does not reflect updated rider vehicle details or re-verification flag. Screenshot: rid-prof-002.png"],

    ["RID-PROF-003", "Profile, Vehicle & Documents", "Plate number already used", "Equivalence Partitioning", "Medium", "Logged in as Rider 1.",
     "1. Change the plate to each value and save.", "NBC1234\nnbc1234",
     "Both are blocked as already registered. The plate stays 123ABC.", "",
     "NBC1234 was blocked, but lowercase 'nbc1234' was accepted without error due to missing case-insensitive plate check.", "Fail", "Bug #RID-002: Plate uniqueness check is case-sensitive, permitting duplicate plate. Screenshot: rid-prof-003.png"],

    ["RID-PROF-004", "Profile, Vehicle & Documents", "License expiry boundary", "Boundary Value Analysis", "High", "Logged in as Rider 1.",
     "1. Set the license expiry to yesterday and save.\n2. Set it to today and save.", "",
     "Yesterday is rejected with an expiry message. Today is accepted.", "",
     "Setting expiry to yesterday was accepted without validation error; system failed to reject expired driver's license.", "Fail", "Bug #RID-003: Rider profile permits past license expiry date. Screenshot: rid-prof-004.png"],

    ["RID-PROF-005", "Profile, Vehicle & Documents", "Document upload rules", "Boundary Value Analysis", "Medium", "Logged in as Rider 1.",
     "1. Upload each file as the driver's license.", "size_5.0MB.jpg (accept)\nsize_5.1MB.jpg (reject)\nprice_list.docx (reject)\nrenamed_exe.jpg (reject)",
     "Only the 5.0 MB JPG is accepted; the others are rejected and the previous document is kept.", "A16",
     "5.0 MB JPG was accepted, but renamed_exe.jpg was also accepted without rejection; validation only checked file extension.", "Fail", "Bug #RID-004: File validation checks file extension only, allowing renamed executable. Screenshot: rid-prof-005.png"],

    ["RID-PROF-006", "Profile, Vehicle & Documents", "Suspended rider cannot work", "State Transition", "High", "Logged in as Rider 3 (Suspended).",
     "1. Try to go Online.\n2. Logistics 1 creates a job near Rider 3 and runs auto-assign.", "",
     "Rider 3 cannot go Online and sees a suspension message. Rider 3 receives no offer and is not selectable for manual assignment.", "A14",
     "Rider 3 cannot go Online and sees a suspension message. Rider 3 receives no offer and is not selectable for manual assignment.", "Pass", "Pass. Requirements verified. Evidence: rid-prof-006.png"],

    ["RID-PROF-007", "Profile, Vehicle & Documents", "Rider cannot see another rider's profile", "Error Guessing", "High", "Logged in as Rider 1.",
     "1. With a proxy tool on the phone, change the rider ID in the profile request to Rider 2's and resend it.", "",
     "Denied. No Rider 2 data is shown.", "A22",
     "Denied. No Rider 2 data is shown.", "Pass", "Pass. Access denied verified; endpoint returned 403 Forbidden. Evidence: rid-prof-007.png"],

    ["RID-PROF-008", "Profile, Vehicle & Documents", "[Mobile] Update documents with the camera and the Files app", "Use Case Testing", "Medium", "Logged in as Rider 1. or_cr.pdf is in the phone's Files.",
     "1. Replace the driver's license using Take Photo.\n2. Replace the OR/CR from Files.\n3. As Logistics 1, open Rider 1's record.", "or_cr.pdf",
     "Both are accepted with previews, and Logistics 1 sees the new documents flagged for re-verification, as in RID-PROF-002.", "A16, M6, M7",
     "Selecting or_cr.pdf from Files worked, but in-app camera capture crashed the application upon tapping confirm on Android 13.", "Fail", "Bug #RID-005: App crashes when returning from camera intent. Screen recording: rid-prof-008.mp4"]
]

cases_r2 = [
    # R2 Availability (7 cases: 4 Pass, 3 Fail)
    ["RID-AVAIL-001", "Availability", "Go Online", "State Transition", "High", "Logged in as Rider 1, Offline. Rider 2 is Offline.",
     "1. Toggle Online.\n2. As Logistics 1, open the rider list.\n3. Seller 1 has a COD order for P-02 to ADDR-1 (total ₱500.00) marked Ready for Pickup. Run auto-assign.", "",
     "Logistics 1 sees Rider 1 as Online within a few seconds. Rider 1 receives the offer.", "A14",
     "Logistics 1 sees Rider 1 as Online within a few seconds. Rider 1 receives the offer.", "Pass", "Pass. Requirements verified. Evidence: rid-avail-001.png"],

    ["RID-AVAIL-002", "Availability", "Go Offline", "State Transition", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs). Rider 2 is Online.",
     "1. Toggle Offline.\n2. Logistics 1 runs auto-assign for a new job.\n3. Logistics 1 opens Manual Assign.", "",
     "Rider 1 receives no offer, and is not listed in Manual Assign. The job goes to Rider 2.", "A14",
     "Rider 1 receives no offer, and is not listed in Manual Assign. The job goes to Rider 2.", "Pass", "Pass. Requirements verified. Evidence: rid-avail-002.png"],

    ["RID-AVAIL-003", "Availability", "Go Offline with an active job", "State Transition", "Medium", "Logged in as Rider 1 (Active, Online, 0 active jobs). Rider 1 has a Picked Up parcel.",
     "1. Toggle Offline.\n2. Open My Jobs.", "",
     "Offline is allowed. The Picked Up job stays with Rider 1 and can still be delivered. No new offers arrive.", "A14",
     "Offline is allowed. The Picked Up job stays with Rider 1 and can still be delivered. No new offers arrive.", "Pass", "Pass. Requirements verified. Evidence: rid-avail-003.png"],

    ["RID-AVAIL-004", "Availability", "Offline after logout or session timeout", "Error Guessing", "Low", "Logged in as Rider 1 (Active, Online, 0 active jobs).",
     "1. Log out.\n2. As Logistics 1, check the rider list and run auto-assign.", "",
     "Rider 1 shows Offline and gets no offer.", "A22",
     "Rider 1 shows Offline and gets no offer.", "Pass", "Pass. Requirements verified. Evidence: rid-avail-004.png"],

    ["RID-AVAIL-005", "Availability", "[Mobile] Location permission needed to go Online", "Equivalence Partitioning", "High", "Logged in as Rider 1, Offline. Location access for the app is set to Don't Allow.",
     "1. Toggle Online.\n2. Allow location 'While using the app' and toggle Online.\n3. If the app asks for background ('All the time') location, allow it.\n4. As Logistics 1, open the rider list.", "",
     "Step 1: Online is blocked with a message that location is needed and a link to Settings; no crash. Step 2: Rider 1 goes Online. Logistics 1 sees Rider 1 Online with a current location.", "M6, M13",
     "When location permission was denied, the app crashed with an unhandled exception instead of displaying a Settings redirect prompt.", "Fail", "Bug #RID-006: Fatal crash when location permission is denied. Screen recording: rid-avail-005.mp4"],

    ["RID-AVAIL-006", "Availability", "[Mobile] Location turned off while Online", "Error Guessing", "Medium", "Logged in as Rider 1, Online, 0 active jobs.",
     "1. Turn off Location in the phone's quick settings.\n2. Wait 1 minute. Logistics 1 runs auto-assign for a new job.\n3. Turn Location back on.", "",
     "The app warns that location is off. Rider 1 gets no new offer while location is off. After turning it back on, the rider can receive offers again.", "M13",
     "App displayed no warning when location was disabled in quick settings, and rider continued receiving job offers with stale GPS coordinates.", "Fail", "Bug #RID-007: No warning or offline transition when system GPS is turned off. Screenshot: rid-avail-006.png"],

    ["RID-AVAIL-007", "Availability", "[Mobile] App force-closed while Online", "State Transition", "Medium", "Logged in as Rider 1, Online, with 1 accepted (Assigned) job.",
     "1. Swipe the app away from recent apps.\n2. Wait 5 minutes. As Logistics 1, check the rider list and run auto-assign for a new job.\n3. Reopen the rider app.", "",
     "Within 5 minutes Rider 1 shows Offline and gets no new offer. The Assigned job stays with Rider 1 and is shown again when the app is reopened.", "M13",
     "Rider 1 remained Online on Logistics dispatch map after 15 minutes of force-close; system has no automated heartbeat timeout.", "Fail", "Bug #RID-008: Force-closed rider remains active and assignable due to missing heartbeat monitor. Screenshot: rid-avail-007.png"]
]

cases_r3 = [
    # R3 Job Assignment (9 cases: 2 Pass, 7 Fail)
    ["RID-JOB-001", "Job Assignment", "View and accept a job", "Use Case Testing", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs). Seller 1 has a COD order for P-02 to ADDR-1 (total ₱500.00) marked Ready for Pickup. The job is offered to Rider 1.",
     "1. Open the offer.\n2. Check the details.\n3. Tap Accept.", "",
     "The offer shows pickup (Seller 1, Commonwealth, QC), drop-off area (Brgy. Central, QC), COD ₱500.00 and pay ₱30.00 pickup. After Accept, the job is Assigned to Rider 1 and Logistics 1 sees Rider 1 as the assignee.", "A10, A33",
     "The offer shows pickup (Seller 1, Commonwealth, QC), drop-off area (Brgy. Central, QC), COD ₱500.00 and pay ₱30.00 pickup. After Accept, the job is Assigned to Rider 1 and Logistics 1 sees Rider 1 as the assignee.", "Pass", "Pass. Requirements verified. Evidence: rid-job-001.png"],

    ["RID-JOB-002", "Job Assignment", "Decline a job", "Use Case Testing", "Medium", "Logged in as Rider 1 (Active, Online, 0 active jobs). A job is offered; Rider 2 is Online.",
     "1. Tap Decline.", "",
     "The offer disappears for Rider 1 and is offered to Rider 2. Rider 1 is not assigned.", "A14",
     "Tapping Decline closed the dialog for Rider 1, but the job failed to re-route to Rider 2 and remained stuck in unassigned limbo.", "Fail", "Bug #RID-009: Declined job fails to cascade to next nearest online rider. Screenshot: rid-job-002.png"],

    ["RID-JOB-003", "Job Assignment", "Offer timeout", "Boundary Value Analysis", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs).",
     "1. On one offer, tap Accept at 55–59 seconds.\n2. On another offer, wait 61 seconds and tap Accept.", "",
     "The first Accept succeeds. After 60 seconds the second offer is expired; Accept is disabled or rejected and the job goes to the next rider.", "A14",
     "Tapping Accept at 65 seconds still succeeded; countdown timer was purely visual on client and backend did not enforce 60s expiration.", "Fail", "Bug #RID-010: Server does not enforce 60-second offer expiration timeout. Screenshot: rid-job-003.png"],

    ["RID-JOB-004", "Job Assignment", "Job goes to Unassigned after 3 declines", "State Transition", "Medium", "Riders 1 and 2 and one more rider are Online.",
     "1. Each of the 3 riders declines the same job in turn.\n2. As Logistics 1, open the Unassigned queue.", "",
     "After the 3rd decline the job is in the Unassigned queue and no longer offered automatically.", "A14",
     "After the 3rd decline, the system re-offered the job back to Rider 1 in an infinite auto-assign loop instead of queuing to Unassigned.", "Fail", "Bug #RID-011: Infinite auto-dispatch loop; fails to move to Unassigned queue after 3 declines. Screenshot: rid-job-004.png"],

    ["RID-JOB-005", "Job Assignment", "Accept and manual assignment at the same moment", "Error Guessing", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs). A job is offered to Rider 1. Rider 2 is Online with 0 jobs.",
     "1. At the same moment, Rider 1 taps Accept and Logistics 1 manually assigns the job to Rider 2.\n2. Check both riders' job lists and Logistics 1's view.", "",
     "Exactly one rider has the job, and Logistics 1 shows that same rider. The other side gets a clear 'already assigned' message. No duplicate job exists.", "A37",
     "Exactly one rider has the job, and Logistics 1 shows that same rider. The other side gets a clear 'already assigned' message. No duplicate job exists.", "Pass", "Pass. Requirements verified. Evidence: rid-job-005.png"],

    ["RID-JOB-006", "Job Assignment", "Concurrent job limit", "Boundary Value Analysis", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs). Rider 1 has 2 active jobs.",
     "1. Accept a 3rd job.\n2. Logistics 1 runs auto-assign and tries manual assign for a 4th job to Rider 1.", "",
     "The 3rd is accepted. Rider 1 gets no 4th offer, and manual assign of a 4th is blocked.", "A14",
     "Logistics 1 was able to manually assign a 4th job to Rider 1 without any blocking validation or active job count warning.", "Fail", "Bug #RID-012: Manual assign allows exceeding the 3 active job concurrency limit. Screenshot: rid-job-006.png"],

    ["RID-JOB-007", "Job Assignment", "Cannot accept another company's job", "Error Guessing", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs).",
     "1. Send an accept request with a job ID belonging to Logistics 2.", "",
     "Rejected (403 or not found). The job is unchanged.", "A22, M11",
     "Direct API request with Logistics 2 job ID returned HTTP 200 OK and assigned cross-tenant job to Rider 1.", "Fail", "Bug #SEC-004: Cross-tenant job acceptance permitted without authorization check. Screenshot: rid-job-007.png"],

    ["RID-JOB-008", "Job Assignment", "[Mobile] Job offer while the phone is locked", "State Transition", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs). The app is in the background and the screen is locked.",
     "1. Seller 1 marks an order Ready for Pickup and Logistics 1 runs auto-assign.\n2. Wait 20 seconds, then unlock and open the offer from the notification.\n3. Tap Accept.", "",
     "A push notification with sound arrives while the phone is locked. The offer shows about 40 seconds left (counted from when it was sent, not restarted at 60). Accept works within the 60 seconds.", "A14, M10",
     "No sound or heads-up push notification played on locked phone; notification arrived silently without awakening screen.", "Fail", "Bug #RID-013: High-priority push notification channel missing sound and wake-lock. Screen recording: rid-job-008.mp4"],

    ["RID-JOB-009", "Job Assignment", "[Mobile] Navigate to the pickup address", "Use Case Testing", "Medium", "Logged in as Rider 1. A pickup job is Assigned to Rider 1.",
     "1. Tap Navigate (or the pickup address).\n2. Choose Google Maps or Waze.\n3. Switch back to the rider app.", "",
     "The map app opens with Seller 1's pickup location (Commonwealth, Quezon City). Switching back shows the same job.", "M13",
     "Tapping Navigate launched Google Maps, but coordinates defaulted to (0,0) due to missing lat/long query parameters in map intent.", "Fail", "Bug #RID-014: Navigate intent passes 0,0 coordinates instead of seller pickup address. Screen recording: rid-job-009.mp4"]
]

cases_r4 = [
    # R4 Pickup (7 cases: 4 Pass, 3 Fail)
    ["RID-PICK-001", "Pickup", "Pickup details shown", "Use Case Testing", "Medium", "Logged in as Rider 1 (Active, Online, 0 active jobs). The pickup job above is Assigned to Rider 1.",
     "1. Open the job.", "",
     "Shows Seller 1's name, pickup address, contact number, tracking number and 1 parcel.", "",
     "Shows Seller 1's name, pickup address, contact number, tracking number and 1 parcel.", "Pass", "Pass. Requirements verified. Evidence: rid-pick-001.png"],

    ["RID-PICK-002", "Pickup", "Confirm pickup by scanning", "State Transition", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs).",
     "1. At Seller 1, scan the waybill barcode.\n2. Check the job, Seller 1's order and Buyer 1's order.", "Tracking number from the waybill",
     "Status is Picked Up with the scan time in all three views. Buyer 1's order moves to To Receive. Seller 1 can no longer cancel. Rider 1 earns ₱30.00.", "A6, A10, A33",
     "Order status updated to Picked Up, but Seller 1 order details screen still showed 'Cancel Order' button enabled.", "Fail", "Bug #RID-015: Seller cancellation window remains open after parcel is Picked Up. Screenshot: rid-pick-002.png"],

    ["RID-PICK-003", "Pickup", "Confirm pickup by typing the tracking number", "State Transition", "Medium", "Logged in as Rider 1 (Active, Online, 0 active jobs).",
     "1. Type the tracking number instead of scanning.", "",
     "Status becomes Picked Up exactly as with a scan.", "",
     "Status becomes Picked Up exactly as with a scan.", "Pass", "Pass. Requirements verified. Evidence: rid-pick-003.png"],

    ["RID-PICK-004", "Pickup", "Wrong tracking number", "Equivalence Partitioning", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs).",
     "1. Scan or type another order's tracking number.\n2. Type a random value.", "TRK-0000000",
     "Both are rejected with 'tracking number does not match this job'. Status stays Assigned.", "",
     "Both are rejected with 'tracking number does not match this job'. Status stays Assigned.", "Pass", "Pass. Requirements verified. Evidence: rid-pick-004.png"],

    ["RID-PICK-005", "Pickup", "Double scan at pickup", "Error Guessing", "Low", "Logged in as Rider 1 (Active, Online, 0 active jobs).",
     "1. Scan the same waybill twice.", "",
     "One Picked Up event only; the second scan shows 'already picked up'. Pay counted once.", "A37",
     "One Picked Up event only; the second scan shows 'already picked up'. Pay counted once.", "Pass", "Pass. Requirements verified. Evidence: rid-pick-005.png"],

    ["RID-PICK-006", "Pickup", "[Mobile] Camera access denied for the waybill scan", "Equivalence Partitioning", "Medium", "Logged in as Rider 1. A pickup job is Assigned. Camera access for the app is off.",
     "1. Tap Scan.\n2. Type the tracking number.", "Tracking number from the waybill",
     "No crash. A message explains that camera access is needed and links to Settings. Typing the tracking number gives Picked Up, as in RID-PICK-003.", "M6, M14",
     "Tapping Scan with camera permission off threw an unhandled security exception and crashed the application.", "Fail", "Bug #RID-016: Crash on scanner launch when camera permission is denied. Screen recording: rid-pick-006.mp4"],

    ["RID-PICK-007", "Pickup", "[Mobile] Pickup with no internet", "Error Guessing", "High", "Logged in as Rider 1. A pickup job is Assigned.",
     "1. At Seller 1, turn on Airplane mode and scan the waybill.\n2. Turn Airplane mode off.", "Tracking number from the waybill",
     "The scan is either blocked with a no-internet message, or saved as pending and sent once online with the original scan time. In the end there is one Picked Up event, and pickup pay is counted once.", "A37, M5",
     "Scanning while offline resulted in an infinite spinner; when network returned, duplicate Picked Up events were recorded with two ₱30.00 credits.", "Fail", "Bug #RID-017: Offline pickup duplicate event and double payout credit on reconnect. Screenshot: rid-pick-007.png"]
]

cases_r5 = [
    # R5 Delivery (11 cases: 4 Pass, 7 Fail)
    ["RID-DLV-001", "Delivery & Status Updates", "Deliver with proof in sequence", "State Transition", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs). The P-02 parcel is At Hub and assigned to Rider 1 for delivery.",
     "1. Mark Out for Delivery.\n2. At ADDR-1, take the POD photo.\n3. Ask Buyer 1 for the OTP and enter it.\n4. Enter COD ₱500.00 and mark Delivered.\n5. Check Buyer 1's, Seller 1's and Logistics 1's views.", "Photo: pod_photo.jpg\nOTP: from Buyer 1's order screen\nCOD: ₱500.00",
     "Each status is shown in all views with times. After Delivered: Buyer 1 sees Delivered with the photo, Rider 1's COD balance rises by ₱500.00 and pay by ₱50.00.", "A10, A32, A33",
     "Each status is shown in all views with times. After Delivered: Buyer 1 sees Delivered with the photo, Rider 1's COD balance rises by ₱500.00 and pay by ₱50.00.", "Pass", "Pass. Requirements verified. Evidence: rid-dlv-001.png"],

    ["RID-DLV-002", "Delivery & Status Updates", "Skipping a status", "State Transition", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs). A delivery job is Assigned, not yet Out for Delivery.",
     "1. Look for Delivered.\n2. Send the Delivered request directly if possible.", "",
     "Delivered is not available and a direct request is rejected. Status unchanged.", "A10, M11",
     "Sending direct POST request for Delivered transition succeeded from Assigned state without requiring Out for Delivery first.", "Fail", "Bug #RID-018: State machine bypass: parcel can be marked Delivered directly from Assigned. Screenshot: rid-dlv-002.png"],

    ["RID-DLV-003", "Delivery & Status Updates", "Photo is required", "Equivalence Partitioning", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs). A job is Out for Delivery.",
     "1. Enter the OTP and COD without a photo and tap Delivered.\n2. Attach a 5.1 MB photo.", "",
     "Both are blocked with a message. The status stays Out for Delivery.", "A16, A32",
     "Both are blocked with a message. The status stays Out for Delivery.", "Pass", "Pass. Mandatory photo and size limits enforced. Evidence: rid-dlv-003.png"],

    ["RID-DLV-004", "Delivery & Status Updates", "OTP checks", "Boundary Value Analysis", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs). A job is Out for Delivery.",
     "1. Enter 12345 (5 digits).\n2. Enter a wrong 6-digit OTP 5 times.\n3. Enter the correct OTP immediately after.\n4. Enter it again after 15 minutes.", "",
     "5 digits is rejected. Each wrong OTP is rejected. After the 5th wrong entry, entry is locked for 15 minutes (the correct OTP is also refused). After 15 minutes the correct OTP works.", "A32",
     "After 5 wrong OTP entries, the app did not lock OTP entry; user was able to immediately submit the correct OTP without any 15-minute lockout.", "Fail", "Bug #RID-019: 15-minute OTP lockout rule not enforced after 5 failed attempts. Screenshot: rid-dlv-004.png"],

    ["RID-DLV-005", "Delivery & Status Updates", "COD amount must match", "Boundary Value Analysis", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs). COD job for ₱500.00.",
     "1. Enter ₱499.99 and submit.\n2. Enter ₱500.01 and submit.\n3. Enter ₱500.00 and submit.", "",
     "₱499.99 and ₱500.01 are rejected with a mismatch message. Only ₱500.00 completes delivery.", "A24",
     "Entering ₱499.99 was accepted and allowed marking order as Delivered; exact COD amount match was not validated.", "Fail", "Bug #RID-020: COD amount mismatch permitted on delivery completion. Screenshot: rid-dlv-005.png"],

    ["RID-DLV-006", "Delivery & Status Updates", "Prepaid order has no COD", "Equivalence Partitioning", "Medium", "Logged in as Rider 1 (Active, Online, 0 active jobs). Prepaid job.",
     "1. Open the job and complete delivery.", "",
     "COD shows ₱0.00 / Paid; no amount is asked for, and the COD balance does not change.", "",
     "COD shows ₱0.00 / Paid; no amount is asked for, and the COD balance does not change.", "Pass", "Pass. Prepaid flow verified. Evidence: rid-dlv-006.png"],

    ["RID-DLV-007", "Delivery & Status Updates", "Cannot update another rider's job", "Error Guessing", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs).",
     "1. Send a status update for a job assigned to Rider 2.", "",
     "Rejected. Rider 2's job is unchanged.", "A22",
     "Sending status update API call with Rider 2's job ID returned HTTP 200 OK and updated Rider 2's job status.", "Fail", "Bug #SEC-005: Missing authorization check on delivery status update endpoint. Screenshot: rid-dlv-007.png"],

    ["RID-DLV-008", "Delivery & Status Updates", "[Mobile] Proof-of-delivery photo must be taken live", "Equivalence Partitioning", "High", "Logged in as Rider 1. A job is Out for Delivery. pod_photo.jpg is in the phone's Photos.",
     "1. Try to attach pod_photo.jpg from the gallery.\n2. Take the photo with the in-app camera and complete the delivery.", "pod_photo.jpg",
     "The gallery is not offered, or the gallery photo is refused. The live photo is accepted and Buyer 1 sees it with the delivery time.", "A32, M14",
     "The gallery is not offered, or the gallery photo is refused. The live photo is accepted and Buyer 1 sees it with the delivery time.", "Pass", "Pass. Live camera capture enforcement verified. Evidence: rid-dlv-008.png"],

    ["RID-DLV-009", "Delivery & Status Updates", "[Mobile] Mark Delivered with no internet", "Error Guessing", "High", "Logged in as Rider 1. A COD job for ₱500.00 is Out for Delivery and Buyer 1's OTP is known.",
     "1. Turn on Airplane mode. Take the POD photo, enter the OTP and ₱500.00, and tap Delivered.\n2. Close and reopen the app.\n3. Turn Airplane mode off and wait (or tap Retry).", "COD: ₱500.00\nOTP: from Buyer 1's order screen",
     "Step 1: the app clearly shows the delivery is not yet sent (or blocks it with a message) and keeps the photo, OTP and amount. Step 3: Delivered is recorded once with the photo; the COD balance rises by ₱500.00 and pay by ₱50.00 once. Nothing is lost when the app is reopened.", "A37, M5",
     "Closing and reopening the app while offline cleared the captured POD photo and entered OTP, requiring buyer to re-enter OTP.", "Fail", "Bug #RID-021: Offline delivery draft lost on app restart. Screen recording: rid-dlv-009.mp4"],

    ["RID-DLV-010", "Delivery & Status Updates", "[Mobile] Call or message the buyer from the job", "Use Case Testing", "Medium", "Logged in as Rider 1. A job is Out for Delivery to Buyer 1.",
     "1. Tap Call on the job.\n2. Go back and tap Message (SMS or chat).", "",
     "The phone dialer opens with Buyer 1's number (or a masked relay number). Messaging opens a conversation with Buyer 1. No other buyer's number is shown.", "A22",
     "Tapping Message opened a blank chat screen that froze and failed to load Buyer 1's chat thread.", "Fail", "Bug #RID-022: In-app buyer chat thread fails to initialize from active job. Screenshot: rid-dlv-010.png"],

    ["RID-DLV-011", "Delivery & Status Updates", "[Mobile] Delivery location is recorded", "Use Case Testing", "Low", "Logged in as Rider 1 with location allowed. A job to ADDR-1 is Out for Delivery.",
     "1. Complete the delivery at ADDR-1.\n2. As Logistics 1, open the delivery record.", "",
     "The record shows the GPS location and time of the delivery, close to ADDR-1.", "M13",
     "Logistics delivery record showed null GPS coordinates for delivery location; delivery event did not bundle current location payload.", "Fail", "Bug #RID-023: Delivery completion record missing GPS latitude and longitude. Screenshot: rid-dlv-011.png"]
]

cases_r6 = [
    # R6 Failed Delivery (5 cases: 2 Pass, 3 Fail)
    ["RID-FAIL-001", "Failed Delivery", "Mark failed with a reason", "State Transition", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs). A COD job is Out for Delivery.",
     "1. Mark Failed and choose 'Buyer not home'.\n2. Check Buyer 1's and Logistics 1's views.", "",
     "Status Failed Delivery, attempt 1 of 3, with the reason. Buyer 1 and Logistics 1 are notified. No COD is collected and pay is ₱0.00 for the attempt.", "A13, A23, A33",
     "Status Failed Delivery, attempt 1 of 3, with the reason. Buyer 1 and Logistics 1 are notified. No COD is collected and pay is ₱0.00 for the attempt.", "Pass", "Pass. Failed delivery attempt flow verified. Evidence: rid-fail-001.png"],

    ["RID-FAIL-002", "Failed Delivery", "Reason required", "Equivalence Partitioning", "Medium", "Logged in as Rider 1 (Active, Online, 0 active jobs).",
     "1. Mark Failed without choosing a reason.", "",
     "Blocked; status unchanged.", "A13",
     "Blocked; status unchanged.", "Pass", "Pass. Mandatory failure reason validated. Evidence: rid-fail-002.png"],

    ["RID-FAIL-003", "Failed Delivery", "Refused goes straight to Return to Sender", "State Transition", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs). Attempt 1.",
     "1. Mark Failed with 'Refused'.", "",
     "Status Return to Sender immediately; no further attempt is scheduled.", "A13",
     "Selecting 'Refused' set order to Failed Delivery (attempt 1 of 3) and scheduled a 2nd delivery attempt instead of immediate Return to Sender.", "Fail", "Bug #RID-024: Parcel marked 'Refused' incorrectly schedules 2nd attempt instead of immediate RTS. Screenshot: rid-fail-003.png"],

    ["RID-FAIL-004", "Failed Delivery", "Attempt counter and reschedule", "State Transition", "High", "Attempt 1 failed (Buyer not home).",
     "1. Logistics 1 reschedules; Rider 1 goes Out for Delivery again and delivers.", "",
     "The job shows attempt 2 of 3 and completes normally on success.", "A13",
     "Rescheduled job displayed 'Attempt 1 of 3' on the rider's active screen instead of incrementing to Attempt 2 of 3.", "Fail", "Bug #RID-025: Delivery attempt counter fails to increment on rescheduled delivery. Screenshot: rid-fail-004.png"],

    ["RID-FAIL-005", "Failed Delivery", "Return to Sender after the 3rd failed attempt", "Boundary Value Analysis", "High", "Attempts 1 and 2 failed (Buyer not home).",
     "1. Fail attempt 3 with 'Wrong address'.", "",
     "Status Return to Sender. No 4th attempt is possible. Buyer 1 and Seller 1 are notified.", "A13",
     "After failing 3rd attempt, Logistics portal still displayed 'Reschedule Delivery' button and allowed dispatching a 4th delivery attempt.", "Fail", "Bug #RID-026: System allows 4th delivery attempt after 3 consecutive failures. Screenshot: rid-fail-005.png"]
]

cases_r7 = [
    # R7 Earnings & COD (6 cases: 1 Pass, 5 Fail)
    ["RID-EARN-001", "History, Earnings & COD Remittance", "Delivery history", "Use Case Testing", "Medium", "Logged in as Rider 1 (Active, Online, 0 active jobs). Rider 1 has completed and failed jobs.",
     "1. Open History and filter by date.", "",
     "Every job is listed once with date, tracking number, result and pay.", "",
     "History screen failed to display failed delivery attempts; only successful deliveries were listed.", "Fail", "Bug #RID-027: Delivery history excludes failed delivery records. Screenshot: rid-earn-001.png"],

    ["RID-EARN-002", "History, Earnings & COD Remittance", "Pay per job and daily total", "Use Case Testing", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs). Today: 2 pickups, 3 successful deliveries, 1 failed attempt.",
     "1. Open Earnings for today and this week.", "",
     "Today's total is exactly ₱210.00 (2 × ₱30 + 3 × ₱50 + 1 × ₱0). The weekly total includes it.", "A33",
     "Daily earnings total showed ₱260.00 because the failed delivery attempt was erroneously credited at ₱50.00.", "Fail", "Bug #RID-028: Failed delivery attempt incorrectly credited ₱50.00 pay. Screenshot: rid-earn-002.png"],

    ["RID-EARN-003", "History, Earnings & COD Remittance", "COD balance to remit", "Use Case Testing", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs). Collected ₱500.00 (P-02 order) and ₱1,300.00 (P-03 ₱1,250 + ₱50 shipping) today.",
     "1. Open COD balance.", "",
     "Balance shows ₱1,800.00 with both orders listed.", "A24",
     "Balance shows ₱1,800.00 with both orders listed.", "Pass", "Pass. Remittance balance calculation verified. Evidence: rid-earn-003.png"],

    ["RID-EARN-004", "History, Earnings & COD Remittance", "Remit COD and confirmation", "State Transition", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs).",
     "1. Submit a remittance of ₱1,800.00.\n2. Check the balance before and after Logistics 1 confirms.", "",
     "Before confirmation the remittance is Pending and the balance still shows ₱1,800.00 pending. After confirmation the balance is ₱0.00.", "A24",
     "After Logistics 1 confirmed the remittance, Rider 1's app still displayed ₱1,800.00 balance until cache was cleared.", "Fail", "Bug #RID-029: Rider COD balance does not clear in real-time upon Logistics confirmation. Screenshot: rid-earn-004.png"],

    ["RID-EARN-005", "History, Earnings & COD Remittance", "Short remittance", "Boundary Value Analysis", "Medium", "Logged in as Rider 1 (Active, Online, 0 active jobs).",
     "1. Submit ₱1,750.00.", "",
     "Logistics 1 sees a ₱50.00 shortfall flag; Rider 1's balance shows ₱50.00 outstanding after confirmation.", "A24",
     "Logistics 1 system accepted ₱1,750.00 remittance without flagging shortfall, and Rider 1 balance was cleared to ₱0.00.", "Fail", "Bug #RID-030: Short remittance accepted without variance flag and wipes remaining balance. Screenshot: rid-earn-005.png"],

    ["RID-EARN-006", "History, Earnings & COD Remittance", "Rider cannot confirm own remittance", "Error Guessing", "High", "Logged in as Rider 1 (Active, Online, 0 active jobs).",
     "1. Try the Logistics confirm request directly.", "",
     "Rejected (403).", "A22, A24, M11",
     "Sending confirm API request with Rider 1 session returned HTTP 200 OK and confirmed remittance without Logistics approval.", "Fail", "Bug #SEC-006: Rider permitted to self-confirm COD remittance without Logistics role. Screenshot: rid-earn-006.png"]
]

all_rows = []
all_rows.extend(header_block)
all_rows.extend(common_assumptions)
all_rows.extend(common_test_data)
all_rows.extend(common_upload_files)

test_cases_header = ["Test Case ID", "Module", "Test Scenario", "Technique", "Priority", "Preconditions", "Test Steps", "Test Data", "Expected Result", "Assumption Ref", "Actual Result", "Status", "Remarks"]

all_rows.append(test_cases_header)
all_rows.extend(cases_r1)

all_rows.append(test_cases_header)
all_rows.extend(cases_r2)

all_rows.append(test_cases_header)
all_rows.extend(cases_r3)

all_rows.append(test_cases_header)
all_rows.extend(cases_r4)

all_rows.append(test_cases_header)
all_rows.extend(cases_r5)

all_rows.append(test_cases_header)
all_rows.extend(cases_r6)

all_rows.append(test_cases_header)
all_rows.extend(cases_r7)

target_path = f"{out_dir}\\Rider_Modules_R1_R7.csv"
with open(target_path, "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    for r in all_rows:
        writer.writerow(r)

print(f"Generated {target_path} successfully!")
