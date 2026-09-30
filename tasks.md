# Visily design build — tasks

Source design: `frontend/visily-to-figma.vis` (30 screens). Plan and screen inventory:
[Ask Musawo — Visily Design Coverage & Build Plan](https://claude.ai/code/artifact/85b693a2-187f-4738-9024-c0a92fe71073).

Work top to bottom. An epic is done only when every subtask, including its **Verify** items, is ticked.

## Approved decisions

| # | Topic | Decision |
| --- | --- | --- |
| 1 | Colours | Keep the app's teal brand (`seedTeal`, 4 px radius); copy the design's layout and content |
| 2 | 2FA methods | Authenticator app (TOTP) now; SMS card shown as "Coming soon" |
| 3 | Insurance | Free-text insurer + member number on the user profile; display only, no claims |
| 4 | Vouchers | Admin-created codes, fixed or % discount, expiry, usage limit |
| 5 | Card entry | Keep Pesapal's hosted page; no in-app card form |
| 6 | Saved payment methods | Out of scope |
| 7 | Prescription extraction | AI reads the photo; doctor confirms every field |
| 8 | Doctor withdrawals | Manual: doctor requests, admin approves and marks paid |
| 9 | Admin dashboard (web) | Separate round after the mobile epics |

## Conventions

- Mobile: Flutter + Riverpod + go_router under `mobile/lib/features/<feature>/{data,state,presentation}`.
- Backend: Express + Prisma (MySQL) + better-auth under `backend/src/{routes,controllers}`.
- Schema changes: edit `backend/prisma/schema.prisma`, add a migration folder, run `npx prisma migrate deploy` then `npx prisma generate`.
- Each epic ends with `flutter analyze` clean, `npx tsc --noEmit` clean, and a manual run on a device.

---

## E1. Two-factor authentication

Design: *2FA Setup*. Entry point: Settings → Two-Factor Authentication.

- [x] Backend: add `twoFactor({ issuer: "Ask Musawo" })` plugin and `appName` in `src/lib/auth.ts`
- [x] Backend: `TwoFactor` model and `User.twoFactorEnabled` in `schema.prisma`
- [x] Backend: migration `20260929180000_two_factor_review_tags`
- [x] Backend: apply the migrations and regenerate the Prisma client — applied on the VPS (backup: `~/backups/askmusawo-20260929-192852-pre-migrations.sql.gz`) and locally (new `hospital` database)
- [x] Mobile: `AppUser.twoFactorEnabled`
- [x] Mobile: `AuthRepository` — `enableTwoFactor`, `confirmTotp`, `disableTwoFactor`, `regenerateBackupCodes`, `verifySecondFactor`
- [x] Mobile: `signIn` throws `TwoFactorRequiredException` on `twoFactorRedirect`
- [x] Mobile: `AuthController.verifySecondFactor` and `refreshUser`
- [x] Mobile: `OtpCodeField` (6 boxes) and sign-in challenge sheet with recovery-code fallback (`two_factor_widgets.dart`)
- [x] Mobile: login screen opens the challenge sheet
- [x] Mobile: `TwoFactorSetupScreen` (header, switch, method cards, QR + key, code entry, recovery codes)
- [x] Mobile: route `/settings/two-factor`
- [x] Mobile: Settings row showing On / Off (restyled in E5)
- [x] Verify: `flutter analyze` and `tsc` clean
- [ ] Verify: enable → sign out → sign in asks for code → correct code signs in — API ✓ (smoke test 2026-09-29); device check pending
- [ ] Verify: wrong code shows an error and stays signed out — API ✓ (smoke test 2026-09-29); device check pending
- [ ] Verify: recovery code signs in once and is then rejected — API ✓ (smoke test 2026-09-29); device check pending
- [ ] Verify: new recovery codes replace the old ones — API ✓ (smoke test 2026-09-29); device check pending
- [ ] Verify: disable → sign in no longer asks for a code — API ✓ (smoke test 2026-09-29); device check pending

## E2. Full History (doctor)

Design: *Full History*. Entry point: doctor chat header (E3) and doctor appointment cards.

- [x] Backend: `GET /api/medical-documents/patient/:patientId` returns `{ patient, documents, appointments }`
- [x] Backend: 403 unless the doctor has an appointment or chat with the patient
- [x] Mobile: `PatientHistory` model (patient facts, documents, visits)
- [x] Mobile: `patientHistory(patientId)` in a repository + `patientHistoryProvider` (family)
- [x] Mobile: `PatientHistoryScreen`
    - [x] App bar: back, "Full History", share button (shares a text summary)
    - [x] Patient header: photo, name, age / gender / blood group chips, medical history note
    - [x] Documents: image thumbnails open full-screen; PDFs and other files open externally
    - [x] Past visits with this doctor: date, type, status, reason / notes
    - [x] Loading skeleton, empty states, error with retry
- [x] Mobile: route `/patients/:id/history`
- [x] Mobile: "Full History" action on doctor appointment cards
- [ ] Verify: doctor linked to patient sees documents; unlinked doctor gets a clear error — API ✓ (smoke test 2026-09-29); device check pending

## E3. Doctor chat header

Design: *Patient Chat*.

- [x] Mobile: when the viewer is a doctor, show a strip under the app bar with the Full History button (name, photo and call buttons stay in the app bar above it)
- [x] Mobile: "In Consultation" tag when the pair has an in-progress appointment today (online / offline stays in the app bar)
- [x] Mobile: input hint "Type message or prescription..." for doctors
- [ ] Verify: patient view of the chat is unchanged

## E4. Review and Ratings screen

Design: *Review and Ratings*.

- [x] Backend: `Review.helpedWith` column (comma-separated tags)
- [x] Backend: `POST /api/reviews` accepts `helpedWith: string[]`
- [x] Backend: review list endpoints return `helpedWith`
- [x] Mobile: `ReviewRepository.submit` sends `helpedWith`; `Review` model parses it
- [x] Mobile: `RateDoctorScreen`
    - [x] Close button, "Rating" title
    - [x] Doctor photo, name, specialty
    - [x] 5 tappable stars
    - [x] "What did the doctor help you?" checklist: Online examination, Consultation, Medicine instruction
    - [x] "Leave a public review" box with the design's placeholder
    - [x] Submit (disabled until a star is chosen), success snackbar, pop with result
- [x] Mobile: route `/review/:appointmentId`; My Appointments "Review" opens it instead of the dialog
- [x] Mobile: remove the old `_ReviewDialog`
- [x] Mobile: show helped-with tags on the doctor's Reviews screen and the doctor profile reviews tab
- [ ] Verify: review saves, shows on the doctor profile, and the appointment shows "Reviewed" — API ✓ (smoke test 2026-09-29); device check pending

## E5. Settings redesign

Designs: *Settings* and *Settings (Dark Mode)*.

- [x] Profile card: photo, name, phone, Edit Profile button, chips (Verified for doctors, 2FA on, insurance, blood group — each only when known)
- [x] Section **Profile & Health**: Account Settings (→ Edit Profile), Health Profile (→ Health Profile page)
- [x] Section **Notifications**: Push, Email, SMS switches (keep current prefs storage)
- [x] Section **Privacy & Security**: Privacy Settings page; Two-Factor Authentication with On / Off status (→ E1 route)
- [x] Section **Medical & Financial**: Appointments History (→ appointments tab), Payments & Billing (→ profile billing section)
- [x] Section **Preferences**: Dark Mode switch
- [x] Section **More**: Help & Support (email sheet — no WhatsApp number on file), About Ask Musawo with the real version (`package_info_plus`)
- [x] Log Out (tinted button) and Delete Account (text button), keep existing behaviour
- [x] Health Profile page: blood group, date of birth, age, gender, marital status, insurance, emergency contact (read + edit link)
- [x] Privacy Settings page: data-sharing explainer, download-my-data request, delete account shortcut
- [x] Doctor variant: hide patient-only rows (health, insurance); Earnings & Payouts instead of Payments & Billing
- [ ] Verify: light and dark mode screenshots match the two designs' structure

## E6. Edit Profile and User Profile additions

Designs: *Edit Profile*, *Ask Musawo - User Profile*.

- [x] Backend: user fields `phoneNumber`, `dateOfBirth`, `address`, `insuranceProvider`, `insuranceMemberNo` (schema, migration `20260929190000_user_contact_insurance`, better-auth `additionalFields`)
- [x] Backend: `PATCH` profile endpoint accepts the new fields
- [x] "Primary doctor" = doctor with the most completed visits (computed in the app from consultation history; no backend change needed)
- [x] Mobile: `AppUser` fields for the above (+ `createdAt`)
- [x] Mobile: Edit Profile — phone (helper "Used for appointment reminders and 2FA."), date of birth picker, home address, insurance provider + member number (helper "Keep this updated to avoid billing issues.")
- [x] Mobile: Edit Profile — email shown read-only (changing sign-in email needs a verification flow; out of scope), so no validation message
- [x] Mobile: Profile header — patient ID (short form of user id), "Joined <Mon YYYY>", Share Profile (share sheet with summary)
- [x] Mobile: Health Snapshot — Insurance (Active / none) and Primary Doctor row (→ doctor profile)
- [x] Mobile: Personal Information — email, phone, location rows with edit icons (→ Edit Profile)
- [x] Mobile: Preferences — Push Notifications and Health Insights & Tips switches
- [ ] Verify: fields round-trip (edit → save → reopen app → still there) — API ✓ (smoke test 2026-09-29); device check pending

## E7. Booking Confirmation step

Design: *Confirmation*. Flow becomes Book → Confirm → Pay.

- [x] Backend: `Voucher` model (code, type fixed / percent, value, expiresAt, maxUses, usedCount, active) — migration `20260929200000_vouchers`
- [x] Backend: admin `POST/GET/PATCH /api/vouchers`
- [x] Backend: `POST /api/vouchers/validate { code, doctorId }` → discount and total, priced from the doctor's fee on the server; never below UGX 1,000
- [x] Backend: payment initiation re-validates the voucher and charges the discounted amount; increments `usedCount` when the payment turns `paid`
- [x] Backend: store `voucherCode` and `discount` on `Payment`
- [x] Mobile: `BookingDraft` gains `voucherCode`, `discount`
- [x] Mobile: `BookingConfirmationScreen`
    - [x] 3-step indicator (Doctor → Schedule → Confirm)
    - [x] Rows: Service + fee, Type, Doctor, Date & Time with edit (pops back), Note
    - [x] Insurance row from profile (or "Add insurance" → Edit Profile)
    - [x] Voucher field + Apply, applied state with remove, updated total
    - [x] "Confirm Appointment" → payment route (or books directly when the doctor has no fee)
- [x] Mobile: route `/book/:doctorId/confirm`; Book screen goes there instead of `pay`; payment summary shows the voucher line
- [x] Web (small): voucher list / create / enable-disable page at Settings → Vouchers
- [ ] Verify: valid, expired, used-up and unknown codes; paid amount equals discounted total — API ✓ (smoke test 2026-09-29); device check pending

## E8. Patient appointment actions

Design: *Appointments*.

- [x] Backend: `PATCH /api/appointments/:id/reschedule` for the patient (new date/time → status back to `requested`, `appointment_updated` socket event)
- [x] Mobile: Reschedule sheet using the doctor's working days and half-hour slots (same parsers as booking)
- [x] Mobile: Reschedule button on requested / confirmed appointments (not emergencies)
- [x] Mobile: Join call button on confirmed / in-progress voice / video appointments from 10 min before start until 60 min after; starts the call with the doctor
- [ ] Verify: doctor sees the rescheduled request; join works for both call types — API ✓ (smoke test 2026-09-29); device check pending

## E9. Payment screen polish

Design: *Payout* (within decision 5).

- [x] Payment summary card: Service, Amount, Tax/Fees (Settings → Billing tax rate, priced on the server; hidden when 0), Discount (E7), Total — migration `20260929210000_payment_tax`, `GET /api/payments/quote`
- [x] Method list styled like the design (existing cards with logos and selected state kept)
- [x] Footer: receipt note and secure-payment note
- [ ] Verify: totals match what Pesapal charges — API ✓ (smoke test 2026-09-29); device check pending

## E10. Upload Prescription upgrade

Design: *HealthSync - Upload Prescription*.

- [x] Backend: `POST /api/prescriptions/extract` — uploaded photo in (read from `/uploads` on disk, no URL fetching), `{ quality, dateIssued, doctorName, licenseNo, patientName, medications }` out, via Gemini
- [x] Backend: `Prescription` gains `appointmentId`, `licenseNo`, `dateIssued` (migration `20260929220000_prescription_details`); drafts stay on the doctor's device so they never reach the pharmacy queue
- [x] Mobile: title "Upload Prescription" with consultation ID; patient strip with "Required Action" tag
- [x] Mobile: document preview with quality badge, rotate (re-encodes the photo), retake, delete
- [x] Mobile: Open Camera / Gallery buttons when empty
- [x] Mobile: Extracted Information rows, each editable, pre-filled from the extract call (medications too, when none typed yet)
- [x] Mobile: confirmation checkbox (required to send) + digital signature
- [x] Mobile: Save Draft (on device, restored on reopen) and Send to Patient; "Prescription Ready" bottom sheet on send
- [x] Mobile: keep the medication rows from the current screen below the extracted fields
- [ ] Verify: draft reopens; sent prescription appears in the patient's Prescriptions — API ✓ (smoke test 2026-09-29); device check pending

## E11. Doctor withdrawals

Design: *Doctor Earnings* (withdraw section).

- [x] Backend: `Withdrawal` model (doctorId, amount, method mobile_money / bank, destination details, status requested / approved / paid / rejected) — migration `20260929230000_withdrawals`
- [x] Backend: doctor `POST /api/withdrawals`, `GET /api/withdrawals/mine`; UGX 5,000 minimum, amount ≤ available balance (checked in a serializable transaction)
- [x] Backend: admin approve / reject / mark paid with note; available balance subtracts requested, approved and paid withdrawals; earnings returns pending amount and recent withdrawals
- [x] Mobile: Withdraw to Mobile Money sheet (network MTN / Airtel, number, amount)
- [x] Mobile: Withdraw to Bank sheet (Stanbic, Centenary, Absa, dfcu, Equity, Other; account name, number, amount)
- [x] Mobile: withdrawals listed in Recent Transactions with status and admin note
- [x] Web: Settings → Doctor Payouts (filter by status, approve, reject with reason, mark paid with reference)
- [ ] Verify: balance updates through each status — API ✓ (smoke test 2026-09-29); device check pending

## E12. Sign in with Google

Blocked until the owner creates the OAuth client IDs (first subtask).

Designs: *Login screen*, *Regester screen*.

- [ ] Owner: create Google OAuth client IDs (Android, iOS, web) and add them to `.env`
- [ ] Backend: better-auth `socialProviders.google`
- [ ] Mobile: `google_sign_in` → ID token → `POST /api/auth/sign-in/social` with `idToken`
- [ ] Mobile: "Sign in with Google" button on Login and Register
- [ ] Verify: new Google user lands as patient; existing email links to the same account

## E13. Admin Dashboard (web)

Design: *Ask Musawo - Admin Dashboard* (1440 px). Compared with `frontend/app/routes/protected/Dashboard.tsx` on 2026-09-29: the current page is built around hospital operations (admissions, patient status, team composition) and its stat cards are hard-coded. The design is a telehealth platform overview. The design's numbers are placeholders; every figure below comes from real data.

- [x] Compare the design's dashboard body with `Dashboard.tsx`
- [x] Compare the design sidebar with `nav-config.ts` (missing sections → E14)
- [x] Backend: `GET /api/admin/overview` (admin only)
    - [x] KPI cards with change vs last month: Total Patients, Total Doctors, Active Consultations (in progress), Appointments Today, Monthly Revenue (paid payments), Platform Growth (new sign-ups this quarter vs last)
    - [x] Revenue series for Today (by hour), This Week (by day), This Month (by day), This Year (by month)
    - [x] Consultations by specialty (last 30 days)
    - [x] Doctor performance: top doctors by rating with review count and Active / Suspended status
    - [x] Incomplete doctor profiles (fee, qualifications, hospital, availability → x/4), in place of the design's "Pending Verifications" — there is no verification workflow
    - [x] Recent support tickets (latest 3 with priority and status)
    - [x] System health: server load, database status and latency, API latency
- [x] Web: header "Platform Overview" with Export Data (CSV of the KPIs and revenue series) and period filter (drives revenue and specialty sections)
- [x] Web: 6 KPI cards (Platform Growth highlighted) replacing the hard-coded `StatsCards` on the admin view
- [x] Web: Revenue Analytics chart with Today / This Week / This Month / This Year tabs
- [x] Web: Consultations by Specialty donut
- [x] Web: Doctor Performance and Incomplete Doctor Profiles tables
- [x] Web: Recent Support Tickets and System Health cards
- [x] Web: right rail — Quick Actions (Add New Doctor, Add Admin User, Send Announcement, Generate Report, Process Withdrawal) and Recent Activity
- [x] Backend + web: Send Announcement → notifications to all users, patients or doctors
- [x] Keep the doctor / nurse dashboard unchanged
- [x] Verify: numbers match the database (15/15 API checks on seeded data); light + dark at 1440 px and 820 px checked by screenshot — period tabs still to click through by hand

## E14. Admin sidebar sections (web) — later round

Design sidebar sections the web app lacks. Each needs its own page and task list.

- [x] Consultations (all appointments across doctors, with call logs) — Appointments → Consultations, admin only
    - [x] Backend: `GET /api/admin/consultations` (period, status, type, search, paging; summary: totals, completion rate, avg call length, missed calls, revenue) and `GET /api/admin/calls`
    - [x] Each consultation joined with its payment (incl. voucher), calls between the pair from 12 h before to 24 h after the visit, review and prescription
    - [x] Web: summary cards, filterable table, detail panel with a timeline, Call logs tab; flags virtual visits marked completed with no recorded call
    - [x] Sidebar now honours per-item `allowedRoles` (doctors don't see admin-only links)
    - [x] Verify: 13/13 API checks on seeded data; screenshots of table, detail panel and call logs; doctor sidebar hides the link
- [x] Payments (Pesapal transactions, refunds) → E19
- [ ] Subscriptions (no subscription product exists yet — needs a decision)
- [x] Reviews & Ratings (moderation) → E15
- [x] Notifications (announcement history) → E16
- [x] Reports & Analytics → E17
- [x] Content Management → E18
- [x] Rename sections where the design's name is clearer: Support → Support Tickets, Activities Log → Audit Logs (sidebar, page heading, tab title, header; URLs unchanged). Administrators and Settings kept — same meaning

## E15. Reviews & Ratings moderation (web)

- [x] Backend: `Review.hidden`, `hiddenReason`, `hiddenAt` (migration `20260930090000_admin_content`, shared by E15–E18)
- [x] Backend: `GET /api/admin/reviews` — filters (rating, doctor search, replied / not, hidden / visible, period), paging; summary: average, total, 1–5 distribution, low ratings (≤ 2), reply rate
- [x] Backend: `PATCH /api/admin/reviews/:id` hide (with reason) / unhide
- [x] Backend: hidden reviews excluded from public doctor reviews and doctor averages; the doctor still sees them marked hidden
- [x] Web: Reviews & Ratings page — summary cards, rating distribution bars, filterable table, hide / unhide with reason
- [x] Mobile: doctor's review list shows a "Hidden by admin" label
- [x] Verify: API checks + screenshot
## E16. Notifications / announcements (web)

- [x] Backend: `Announcement` model (title, message, audience, link, sentCount, sentBy) and `Notification.announcementId` (migration)
- [x] Backend: sending records the announcement; `GET /api/admin/announcements` with read counts
- [x] Web: Notifications page — compose (audience, title, message, optional link) with preview and recipient count, history table with read rate
- [x] Dashboard "Send Announcement" opens this page
- [x] Verify: API checks + screenshot
- [ ] Follow-up (not in this round): the mobile app has no notifications inbox yet, so announcements only reach web users
## E17. Reports & Analytics (web)

- [x] Backend: `GET /api/admin/reports?from&to&granularity=day|week|month`
    - [x] Consultations over time by status; cancellation rate
    - [x] Revenue over time (paid), discounts given, tax collected
    - [x] New sign-ups over time (patients, doctors)
    - [x] Consultations and revenue by specialty
    - [x] Doctor leaderboard: consultations, completed, revenue, average rating
    - [x] Voucher usage (uses, discount given per code)
    - [x] Payouts: requested, paid, outstanding
- [x] Web: Reports page — date range + granularity, charts for each report, per-report CSV export
- [x] Verify: numbers match seeded data (9 API checks) + screenshot
## E18. Content Management — blog (web)

- [x] Backend: `BlogPost` model (slug, title, excerpt, content, category, image, accent, author, published, publishedAt); migration seeds the current posts from `lib/blogPosts.ts`
- [x] Backend: public `GET /api/blog`, `GET /api/blog/:slug` (published only); admin create / update / delete / publish
- [x] Web: Content Management page — list with status, editor (title, slug, excerpt, category, image, accent, content), live preview, publish / unpublish, delete
- [x] Web: marketing Blog, BlogPost and home BlogSection load posts from the API (server-rendered loaders, graceful fallback); `lib/blogPosts.ts` removed
- [x] Replace the hard-coded comment counts with an estimated reading time (there is no comment system)
- [x] Verify: API checks (10); blog list, post and home strip server-render from the database; drafts 404 publicly; screenshots
## E19. Payments & refunds (web)

Pesapal refund rules ([RefundRequest docs](https://developer.pesapal.com/how-to-integrate/e-commerce/api-30-json/refund-request)): only COMPLETED payments; one refund per payment; mobile money refunds must be full, card refunds may be partial; the merchant approves each refund on Pesapal, which later reports the payment as REVERSED.

- [x] Backend: `Payment` refund fields (`refundAmount`, `refundReason`, `refundStatus`, `refundRequestedAt`, `refundRequestedBy`) — migration `20260930120000_payment_refunds`
- [x] Backend: `requestRefund` in `lib/pesapal.ts` (`POST /api/Transactions/RefundRequest`)
- [x] Backend: `GET /api/admin/payments` — filters (period, status, method type, search), paging; summary: collected, pending, failed, refunded, discounts, tax; each row with patient, doctor and linked appointment
- [x] Backend: `POST /api/admin/payments/:id/sync` — re-check status with Pesapal
- [x] Backend: `POST /api/admin/payments/:id/refund` — enforces the rules above; optional "cancel the appointment too"
- [x] Backend: status sync also follows payments with a requested refund until Pesapal reports them reversed
- [x] Web: Payments page (Financial Records → Payments, admin only) — summary cards, filterable table, detail panel, Sync and Refund actions with the rules explained
- [x] Verify: 24/24 API checks against a local Pesapal mock (`PESAPAL_BASE_URL`, tests only) covering listing, every refund rule, Pesapal rejection, and sync to reversed; screenshots
- [ ] Verify: one real refund on production with a small card payment (needs your Pesapal merchant approval)

## E20. Gaps found in the side-by-side comparison (mobile)

Layout and content match the design (in the app's own teal styling) for: Settings, 2FA, Edit Profile, User Profile, Full History, Upload Prescription, Doctor Profile, Categories, Chat. The differences below are structural. None block use, but each is a place the app doesn't do what the design shows.

- [x] Full History showed image documents as file tiles when the URL had no extension (UploadThing and Unsplash links) — fixed: anything that isn't a known document type is tried as an image, with the file tile as fallback
- [x] **Book appointment** — done: a horizontal date strip (next 14 days; the doctor's closed days and time off are dimmed) and time-slot chips within the doctor's hours. The 3-step indicator was left out (the flow is two screens)
- [x] **My Appointments** — done: Upcoming / Completed / Cancelled tabs with counts; Upcoming is grouped into "In progress", "New time proposed", "Today", "Tomorrow", "Coming up" and "Waiting for the doctor to confirm"
- [x] **Doctor dashboard** — done: header with photo, name, specialty and the next free slot today; today's visits use the full appointment card (date and time, Start / Call / Reschedule / Cancel / No-show); requests keep Accept / Reject with a reason
- [x] **Doctor earnings** — done: Total earnings and This month tiles, and a line chart for Week and Month (daily) and Year (monthly; Today shows the day's total) from a new `series` field on `/api/earnings/mine` (checked against seeded payments)
- [x] **Doctor profile (patient view)** — done: "N patients seen" (distinct patients with a completed visit) next to the rating
- [x] **Time format** — done: chat, chat list and call history use 12-hour time with AM/PM
- [ ] Decide whether the design's bottom navigation labels (Home, Appointments, Inbox, Profile) should replace the app's icon-only pill navigation

## E21. User-flow gaps (patient and doctor)

Found on 2026-09-30 by walking each journey (sign-up → find a doctor → book and pay → the visit → after the visit) through the mobile app and backend. **High** = the flow breaks, or money or trust is at risk. **Medium** = the user can work around it, but the product feels incomplete. **Low** = polish.

### Patient

- [ ] **High — Forgot password.** No reset flow in the app (the web "Forgot?" link goes nowhere either). A patient who forgets their password is locked out. better-auth supports reset; it needs an email provider.
- [x] **High — Paid but not booked.** Done: the payment now carries the booking details and the server books the appointment the moment Pesapal confirms (IPN, callback or status check); the app's book call returns the same appointment (10/10 checks).
- [ ] **High — Cancelling a paid appointment.** A patient cancelling, or a doctor rejecting or cancelling a paid request, only changes the status. No refund is requested and the patient isn't told what happens to their money. Needs a policy (for example a full refund if cancelled more than X hours ahead), then an automatic refund request or an admin task.
- [ ] **High — No push notifications.** Nothing reaches the patient when the app is closed: doctor confirmed / rejected / rescheduled, new message, prescription issued, or a reminder before the visit. Updates only arrive over the live socket while the app is open. Needs Firebase Cloud Messaging (or similar), plus server-side triggers and scheduled reminders (for example 24 h and 15 min before).
- [ ] **High — Incoming calls when the app is closed.** Calls ring only while the app is open. A doctor calling at appointment time can't reach a patient whose app is in the background. Needs push-triggered call UI (CallKit on iOS, full-screen notification / ConnectionService on Android).
- [x] **Medium — Notifications inbox.** Done: a Notifications screen with unread badge on the patient Home header and doctor dashboard, live updates over the socket, tap to open the related screen, mark one / all read (read is now owner-only). The server now creates notifications for: new booking and emergency (doctor), confirmed / cancelled / rescheduled / started / completed (patient), patient cancel and reschedule (doctor), new prescription (patient), new review (doctor), payout approved / sent / rejected (doctor), refund requested (patient). 14/14 checks. Push to phones still needs Firebase (see High items).
- [x] **Medium — Visit summary.** Done: patients see the doctor's summary on completed appointments (collapsed, tap to expand), and the "How was your visit?" notification says when one was added.
- [x] **Medium — Payment history and receipts.** Done: Settings → Payments & Billing and Profile → View all open a history (total paid, each payment with voucher, status, refund) and a shareable receipt. Backend `GET /api/payments/mine` (own payments only, no unfinished checkouts).
- [x] **Medium — Lab results.** Done: Profile → Lab Results shows results a doctor has reviewed (image, date, doctor's notes; the AI analysis stays with clinicians), and patients are notified when one is reviewed. Doctors now see all of a patient's lab results, with the AI analysis, in Full History.
- [x] **Medium — Doctor-proposed new times.** Done: a doctor's reschedule is now a proposal. The patient gets a notification and an Accept / Keep original banner; accepting moves and confirms the visit, declining keeps the original time, and the doctor is told either way (the doctor's card shows "waiting for the patient"). Admins still move visits directly.
- [x] **Medium — Unread badges.** Done: the Messages tab shows the unread count in both apps, refreshed live when messages arrive or are read.
- [x] **Low — Book again.** Done: completed, cancelled and missed visits have a Book again button.
- [x] **Low — Emergency escalation.** Partly done: every admin is notified the moment an emergency is requested. Still open: an automatic reminder or reassignment if the doctor hasn't responded after N minutes (needs a scheduled job).

**Needs from you before these can be built:**
- Password reset: an email provider (for example Resend, Mailgun or an SMTP account) and the address to send from.
- Push notifications and background calls: see **E22** (FCM first, APNs later; scheduled last).
- Cancellation refunds: the refund policy (for example full refund if cancelled more than X hours before the visit).

### Doctor

- [x] **High — Starting and ending a consultation.** Done: Start consultation (rings the patient for video/voice), Call patient, End consultation, an In progress filter, and prescriptions can be written during the visit. Also fixed: any doctor could edit any appointment and any field — doctors are now limited to their own appointments, valid status steps and status/date/time/notes (11/11 checks).
- [x] **High — Professional profile editing.** Done: Edit Profile now has specialization, qualifications, years of experience, treatments, working days, working hours and Available today, written in the format the booking screen reads (unit-tested). Also fixed: `/api/me` never returned these fields, because they were missing from better-auth's `additionalFields`.
- [ ] **High — Push notifications.** No alert for a new booking request, emergency, message or call while the app is closed (shares the patient work above).
- [x] **Medium — Consultation notes.** Done: End consultation asks for a visit summary; completed visits have Add / Edit summary. Shown to the patient and in Full History.
- [x] **Medium — Reasons for reject / cancel.** Done: doctors pick or type a reason when declining or cancelling (appointments list and dashboard); patients can add one when cancelling; the reason and who cancelled are stored (migration `20260930190000_appointment_cancellation`), shown on the card and included in the notification. Also fixed: patients could cancel completed or already-cancelled visits. 13/13 checks.
- [x] **Medium — Time off.** Done: Profile → My practice → Time off. Doctors add or remove date ranges with a reason; the booking and reschedule date pickers skip those days, the server rejects bookings on them (emergencies excepted), and adding time off lists any visits already booked on those days.
- [x] **Medium — Lab requests.** Done: doctors order a test from a patient's Full History ("Order test": test type chips, plus body part or notes). It lands on the web Test Requests page, and the patient is notified. The patient's Lab Results now also lists ordered and in-progress tests ("Requested by Dr X · please visit the lab"), showing images and notes only once a result is reviewed. `POST /api/lab-results` now rejects a missing test type or a non-patient.
- [x] **Medium — Issued prescriptions.** Done: Profile → My practice → Prescriptions issued, searchable by patient or medication, with dispensing status. (Drafts are still per device.)
- [x] **Low — No-shows.** Done: confirmed visits have a No-show button; the patient sees "Missed" with Book again and is notified. (How no-shows affect payouts and refunds follows the refund policy you choose.)
- [ ] **Low — Doctor onboarding.** Doctors can't sign up themselves; admins create their accounts on the web. Decide whether that stays, or add self-sign-up with admin verification.

### Both

- [ ] **Medium — Appointment time convention.** Bookings store the chosen local wall-clock time as if it were UTC, and the app displays it back unconverted. This works while everyone is in Uganda, but server-side reminders, the admin pages and any user in another time zone would be 3 hours off. Store true UTC when booking, convert on display, and migrate existing rows in the same release. **Plan written 2026-09-30, awaiting approval:**
    - [ ] Confirm the VPS container's time zone (if it is already EAT, stored rows are true UTC and no data migration is needed)
    - [ ] Backend: `lib/clinicTime.ts` with `CLINIC_TZ` (default `Africa/Kampala`); a date string without an offset is read as Kampala time, whatever the server's own time zone
    - [ ] Backend: `formatVisit`, time-off day matching, earnings buckets, admin "today" and period ranges, and report buckets all use Kampala calendar days
    - [ ] Mobile: send `date.toUtc().toIso8601String()`; parse `date` and `proposedDate` with `.toLocal()`
    - [ ] Migration: back up, then shift `date` and `proposedDate` back 3 h on non-emergency rows (emergencies are already true UTC); doctor time off stays as calendar dates
    - [ ] Compatibility for app builds already installed (only if the app is live): the new app sends a header, and the server returns the old format to clients without it
    - [ ] Tests: update smoke suites, add a Dart round-trip unit test, then check join-call window, reschedule-in-past and emergency display
- [x] **Medium — Skeleton loaders everywhere.** Done: content that's loading always shows a skeleton shaped like it (lists, cards, carousels, section lines, AI results, checkout page, remote images). Actions in progress (buttons, uploads, voice notes) use one shared `LoadingDots` indicator. No spinners remain in `mobile/lib`.
- [x] **Medium — Offline-first mobile app.** Done (`mobile/lib/core/offline/`):
    - [x] Every GET response saved to disk. Screens open instantly from the saved copy and refresh in the background. Offline, saved data is served at once. The store is cleared on sign in and sign out.
    - [x] Data providers wrapped in `offlineFirst()`. Pull-to-refresh and invalidation go to the network first.
    - [x] App-wide "You're offline" banner. Actions that need a connection say so plainly.
    - [x] Photos and avatars cached on disk (`AppNetworkImage`).
    - [x] Chat outbox: text messages show immediately with a clock, survive restarts and send on reconnect.
    - [ ] Check on the Samsung: cold start in airplane mode shows saved data

## E22. Push notifications and background calls (FCM first, then APNs) — do last

Why: the live socket only works while the app is open. To reach a closed or sleeping phone, the VPS has to go through the OS push service: FCM on Android, APNs on iOS. Only FCM's free messaging is used; the database, API and hosting stay on the VPS. The in-app notification pipeline (`backend/src/lib/notify.ts`) is already the single place every event goes through, so push plugs in there.

### Phase 1 — FCM (Android)

- [ ] **Owner:** create a Firebase project and add an Android app with package name `ug.co.askmusawo.ask_musawo`; download `google-services.json`
- [ ] **Owner:** Firebase console → Project settings → Service accounts → generate a private key (JSON) for the server
- [ ] Backend: `DeviceToken` model (userId, token, platform, lastSeenAt) + migration; `POST /api/devices` (register / refresh) and `DELETE /api/devices/:token` (sign-out)
- [ ] Backend: `firebase-admin` with the service-account key from an environment variable; send push inside `notifyUser`, drop tokens FCM reports as invalid
- [ ] Mobile: `firebase_core` + `firebase_messaging`, `google-services.json` in `android/app/`, request notification permission (Android 13+), register the token after sign-in and on refresh, remove it on sign-out
- [ ] Mobile: tapping a push opens the same screen as the inbox item (`link`); foreground pushes refresh the inbox instead of showing a duplicate banner
- [ ] Incoming calls: a high-priority data message → full-screen incoming-call notification (`flutter_callkit_incoming` or a full-screen intent) that opens the call screen, with Accept / Decline working while the app is closed
- [ ] Appointment reminders: a scheduled job on the VPS (24 h and 15 min before) that calls `notifyUser` — needs the time-zone fix in E21 first
- [ ] Verify on real phones (including Tecno / Infinix / Samsung battery savers): app in background, app swiped away, phone locked; notification taps; a call ringing on a locked phone

### Phase 2 — APNs (iOS), when an iOS app is added

- [ ] **Owner:** Apple Developer account; create the iOS app and an APNs auth key (.p8), plus VoIP push for calls
- [ ] Add the iOS app to the same Firebase project (or send to APNs directly from the VPS) and upload the APNs key
- [ ] Mobile: iOS notification permission, CallKit / PushKit for incoming calls
- [ ] Verify on a real iPhone

## Final pass

- [x] Re-render every design screen and compare side by side with the app — done 2026-09-30 for the 14 patient and 6 doctor screens that exist in the app (Flutter web at 390 px, seeded data); findings in **E20**. Not compared: Video / Audio call, Payment (Pesapal web view) and the web Admin Dashboard (compared in E13)
- [ ] Update the plan doc's screen inventory statuses
- [ ] Commit per epic
