import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../auth/data/app_user.dart';
import 'patient_prescription.dart';

const _teal = PdfColor.fromInt(0xFF128A8B);
const _ink = PdfColor.fromInt(0xFF102828);
const _muted = PdfColor.fromInt(0xFF6B7A7A);
const _line = PdfColor.fromInt(0xFFDDE9E9);

// The PDF uses the built-in Helvetica, which only covers basic Latin: keep
// characters like "—" or "·" out of anything printed here.

/// Builds a one-page A4 PDF of [rx] that a patient can take or send to a
/// pharmacy: prescriber (with licence and facility), patient, date,
/// diagnosis / notes, every medicine, and the doctor's signature.
///
/// [dio] fetches the signature image; if that fails (offline, missing file)
/// the PDF is still produced with a "signed electronically" line instead.
Future<Uint8List> buildPrescriptionPdf({
  required PatientPrescription rx,
  required AppUser? patient,
  required Dio dio,
}) async {
  Uint8List? signature;
  final signatureUrl = rx.signatureUrl;
  if (signatureUrl != null && signatureUrl.isNotEmpty) {
    try {
      final response = await dio.get<List<int>>(
        signatureUrl,
        options: Options(
          responseType: ResponseType.bytes,
          // Binary, not JSON — keep it out of the offline response cache.
          extra: {'offline': false},
        ),
      );
      if ((response.statusCode ?? 0) < 400 && response.data != null) {
        signature = Uint8List.fromList(response.data!);
      }
    } catch (_) {}
  }

  final date = DateFormat('d MMMM yyyy');
  final doc = pw.Document(
    title: 'Prescription ${rx.id}',
    author: rx.doctorName,
    creator: 'Ask Musawo',
  );

  pw.Widget label(String text) => pw.Text(
    text.toUpperCase(),
    style: const pw.TextStyle(fontSize: 8, color: _muted, letterSpacing: 0.8),
  );

  pw.Widget field(String title, String? value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        label(title),
        pw.SizedBox(height: 2),
        pw.Text(
          (value == null || value.isEmpty) ? 'Not recorded' : value,
          style: const pw.TextStyle(fontSize: 10.5, color: _ink),
        ),
      ],
    ),
  );

  final patientAge = _age(patient);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Ask Musawo',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: _teal,
                      ),
                    ),
                    pw.Text(
                      'Medical prescription',
                      style: const pw.TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  label('Prescription no.'),
                  pw.Text(
                    rx.id,
                    style: const pw.TextStyle(fontSize: 9, color: _ink),
                  ),
                  pw.SizedBox(height: 4),
                  label('Date issued'),
                  pw.Text(
                    date.format(rx.issuedOn),
                    style: const pw.TextStyle(fontSize: 10, color: _ink),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(height: 2, color: _teal),
          pw.SizedBox(height: 16),

          // Prescriber and patient
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    field('Prescriber', rx.doctorName),
                    field('Specialty', rx.doctorSpecialization),
                    field('UMDPC licence no.', rx.licenseNo),
                    field(
                      'Facility',
                      [rx.doctorFacility, rx.doctorFacilityAddress]
                          .whereType<String>()
                          .where((s) => s.isNotEmpty)
                          .join(', '),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    field('Patient', rx.patientName ?? patient?.name),
                    field(
                      'Age / sex',
                      [patientAge, patient?.gender]
                          .whereType<String>()
                          .where((s) => s.isNotEmpty)
                          .join(' / '),
                    ),
                    field('Phone', patient?.phoneNumber),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          if (rx.notes != null && rx.notes!.trim().isNotEmpty) ...[
            label('Diagnosis / notes'),
            pw.SizedBox(height: 4),
            pw.Text(
              rx.notes!.trim(),
              style: const pw.TextStyle(fontSize: 10.5, color: _ink),
            ),
            pw.SizedBox(height: 16),
          ],

          // Medicines
          pw.Text(
            'Rx',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: _teal,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Medicine', 'Dosage', 'Qty', 'Instructions'],
            data: [
              for (var i = 0; i < rx.items.length; i++)
                [
                  '${i + 1}',
                  rx.items[i].medicationName,
                  rx.items[i].dosage,
                  '${rx.items[i].quantity}',
                  rx.items[i].instructions ?? '',
                ],
            ],
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: _teal),
            cellStyle: const pw.TextStyle(fontSize: 9.5, color: _ink),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 5,
            ),
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _line, width: 0.6),
              bottom: pw.BorderSide(color: _line, width: 0.6),
            ),
            columnWidths: {
              0: const pw.FixedColumnWidth(18),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2.2),
              3: const pw.FixedColumnWidth(30),
              4: const pw.FlexColumnWidth(3.2),
            },
          ),
          if (rx.items.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Text(
                'See the attached prescription image in the app.',
                style: const pw.TextStyle(fontSize: 10, color: _muted),
              ),
            ),

          pw.Spacer(),

          // Signature
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  label('Status'),
                  pw.Text(
                    rx.status == 'dispensed' && rx.dispensedAt != null
                        ? 'Dispensed on ${date.format(rx.dispensedAt!)}'
                        : rx.statusLabel,
                    style: const pw.TextStyle(fontSize: 10, color: _ink),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (signature != null)
                    pw.Image(pw.MemoryImage(signature), height: 48)
                  else
                    pw.Text(
                      'Signed electronically',
                      style: const pw.TextStyle(fontSize: 9, color: _muted),
                    ),
                  pw.Container(width: 160, height: 0.8, color: _ink),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    rx.doctorName,
                    style: const pw.TextStyle(fontSize: 9.5, color: _ink),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Container(height: 0.6, color: _line),
          pw.SizedBox(height: 6),
          pw.Text(
            'Issued through Ask Musawo by a doctor licensed by the Uganda '
            'Medical and Dental Practitioners Council. Pharmacists can confirm '
            'this prescription with the prescriber or at care@askmusawo.co.ug, '
            'quoting the prescription number.',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ),
    ),
  );

  return doc.save();
}

String? _age(AppUser? patient) {
  final dob = DateTime.tryParse(patient?.dateOfBirth ?? '');
  if (dob == null) {
    final age = patient?.age;
    return (age == null || age.isEmpty) ? null : '$age years';
  }
  final now = DateTime.now();
  var years = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
    years--;
  }
  return '$years years';
}
