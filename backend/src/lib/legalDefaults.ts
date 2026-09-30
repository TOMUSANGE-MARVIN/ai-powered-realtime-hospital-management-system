// Starting text for Ask Musawo's legal documents (E23.2). Admins edit and
// publish new versions from the web (Settings → Legal); these defaults are
// only used until the first edit is saved.
//
// DRAFT — written against Uganda's Data Protection and Privacy Act 2019 and
// the Uganda Medical and Dental Practitioners Council's expectations for
// telemedicine. Have them reviewed by a Ugandan lawyer before launch.
//
// Format: "## " headings, "- " bullet points, blank lines between paragraphs.

export const DEFAULT_LEGAL_VERSION = "2026-10-01";

export const DEFAULT_PRIVACY = `Ask Musawo connects patients in Uganda with licensed doctors for remote and in-person consultations. This policy explains what personal and health information we collect, why, who can see it, and the rights you have under the Data Protection and Privacy Act, 2019.

## Who we are

Ask Musawo ("we", "us") is the data controller for information collected through the Ask Musawo app and website. Contact us at care@askmusawo.co.ug about anything in this policy.

## What we collect

- Account details: your name, email address, phone number, date of birth, gender and address.
- Health information you give us or your doctor: symptoms, the reason for a visit, medical history, allergies, blood group, emergency contact, insurance details, uploaded documents and lab results.
- Consultation records: appointments, chat messages, voice notes, call history, prescriptions and doctors' notes.
- Payment records: amounts, payment method and transaction references. Card and mobile-money details are handled by Pesapal; we never see or store your card number.
- For doctors: licence number, practising licence document, the facility you practise at, and payout details.
- Technical information needed to run the service, such as your device type and the times you use the app.

Health information is sensitive personal data under the Act. We only collect it with your consent and only to provide your care.

## Why we use it

- To let you book, attend and pay for consultations, and to keep a record of your care.
- To let the doctor you consult see the information they need to treat you.
- To send you reminders and updates about your appointments, prescriptions and payments.
- To verify that every doctor on Ask Musawo is licensed to practise in Uganda.
- To keep the service secure, prevent fraud and meet our legal obligations.

We do not sell your information, and we do not use your health information for advertising.

## Who can see your information

- The doctors you book or message, while they are treating you. A doctor can only open your full history when they are treating you.
- A small number of Ask Musawo staff who need it to run the service (for example to resolve a payment problem).

Every time someone other than you opens your records, it is logged. You can see who opened them in the app under Settings → Privacy → Who viewed my records.
- Service providers who work for us under contract: our hosting provider, Pesapal for payments, and our file-storage provider. They may only use your information to provide their service to us.
- Authorities, when the law requires it.

## How long we keep it

We keep medical records for as long as the law requires health records to be kept, and other account information for as long as your account is open. If you delete your account we remove or anonymise your information, except records we must keep by law (for example payment records for tax purposes).

## How we protect it

Your information travels over encrypted connections (HTTPS). Access is limited by role, sign-in can be protected with two-factor authentication, and every access to patient records is logged. No system is perfectly secure; if a breach affects you, we will tell you and the Personal Data Protection Office as the Act requires.

## Where it is stored

Your information may be stored on servers outside Uganda. When it is, we make sure it is protected to the standard the Act requires.

## Your rights

Under the Data Protection and Privacy Act you can:

- ask for a copy of the information we hold about you;
- ask us to correct information that is wrong (you can edit most of it yourself in the app);
- ask us to delete your account and information (Settings → Privacy → Delete account);
- withdraw your consent at any time, although we then may not be able to provide consultations;
- complain to the Personal Data Protection Office if you think we have mishandled your information.

To use any of these rights, email care@askmusawo.co.ug. We respond within 30 days.

## Children

Ask Musawo accounts are for adults aged 18 and over. A parent or guardian may book a consultation for a child from their own account and is responsible for giving consent on the child's behalf.

## Changes to this policy

When we make important changes we will ask you to review and accept the new version in the app before you continue.`;

export const DEFAULT_TERMS = `These terms apply when you use Ask Musawo, in the app or on the website. By creating an account you agree to them.

## What Ask Musawo is

Ask Musawo is a platform that connects patients with doctors licensed by the Uganda Medical and Dental Practitioners Council. Consultations are provided by the doctors themselves, who remain professionally responsible for the care they give. Ask Musawo verifies each doctor's licence before patients can book them.

## Not for emergencies

Ask Musawo is not an emergency service. If you or someone else is in danger, has severe bleeding, chest pain, difficulty breathing, loss of consciousness or signs of a stroke, go to the nearest hospital or call emergency services immediately.

## Remote consultations have limits

A doctor may not be able to examine you properly over chat, voice or video. They may ask you to visit a health facility in person, have tests done, or seek emergency care. Follow that advice. Information in the app, including the AI symptom search, is general guidance and is not a diagnosis.

## Your account

- Give accurate information, especially about your health, so your doctor can treat you safely.
- Keep your password private. You are responsible for what happens in your account.
- You must be 18 or older. Parents and guardians may book for their children.

## Bookings, payments and cancellations

- The price is shown before you pay and includes any tax. Payments are processed by Pesapal.
- A booking is confirmed when the doctor accepts it. If the doctor declines or cancels, you will be told what happens to your payment.
- Refunds follow the refund policy shown in the app at the time you book.

## Doctors

Doctors must hold a current practising licence, practise from a licensed facility, keep their details up to date, and follow the Council's professional and ethical rules. Ask Musawo may suspend any doctor whose licence cannot be verified.

## Acceptable use

Do not misuse the service: no abusive or threatening messages, no false information, no attempts to access other people's accounts or records, and no use of Ask Musawo for anything illegal. We may suspend or close accounts that break these rules.

## Liability

Doctors are responsible for the medical advice they give. Ask Musawo is responsible for running the platform with reasonable care and skill, including verifying doctors and protecting your information. Nothing in these terms limits liability that cannot be limited under Ugandan law.

## Changes and contact

We may update these terms. When the change is important we will ask you to accept the new version in the app. These terms are governed by the laws of Uganda. Contact us at care@askmusawo.co.ug.`;

export const DEFAULT_TELEMEDICINE_CONSENT = `By booking I agree that:

- this consultation may happen by chat, voice or video, and the doctor may not be able to examine me in person;
- the doctor may ask me to visit a health facility, have tests done or seek emergency care, and I will follow that advice;
- the information I give, and my relevant medical history, will be shared with this doctor to treat me, as described in the Privacy Policy;
- Ask Musawo is not for emergencies — in an emergency I will go to the nearest hospital.`;
