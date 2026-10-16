import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/pro_models.dart';

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Informe de cumplimiento en PDF (para el médico o nutricionista).
/// Sin emojis: las fuentes del PDF no los dibujan.
Future<Uint8List> buildStatsPdf(StatsReport report, String username) async {
  pw.ThemeData? theme;
  try {
    // Fuente con tildes y eñes (se descarga la primera vez)
    theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.interRegular(),
      bold: await PdfGoogleFonts.interBold(),
    );
  } catch (_) {
    theme = null; // sin internet: fuente estándar
  }

  const orange = PdfColor.fromInt(0xFFFF6B35);
  const grey = PdfColor.fromInt(0xFF6B7280);
  final doc = pw.Document(title: 'Informe de suplementación', author: username);

  pw.Widget stat(String label, String value) => pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          margin: const pw.EdgeInsets.only(right: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: const pw.TextStyle(color: grey, fontSize: 9)),
              pw.SizedBox(height: 4),
              pw.Text(value, style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      );

  doc.addPage(
    pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Generado con Supplement Tracker Pro · Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(color: grey, fontSize: 8),
        ),
      ),
      build: (context) => [
        pw.Text('Informe de suplementación',
            style: const pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: orange)),
        pw.SizedBox(height: 4),
        pw.Text('$username · del ${_date(report.from)} al ${_date(report.to)}',
            style: const pw.TextStyle(color: grey, fontSize: 11)),
        pw.SizedBox(height: 18),
        pw.Row(children: [
          stat('Cumplimiento', '${report.adherence} %'),
          stat('Días completos', '${report.completeDays} de ${report.totalDays}'),
          stat('Tomas registradas', '${report.intakes}'),
          stat('Mejor racha', '${report.longestStreak} días'),
        ]),
        pw.SizedBox(height: 22),
        pw.Text('Por suplemento',
            style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Suplemento', 'Tomas hechas', 'Tomas previstas', 'Cumplimiento'],
          data: [
            for (final s in report.supplements)
              [s.name, '${s.taken}', '${s.expected}', '${s.adherence} %'],
          ],
          headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignments: {
            1: pw.Alignment.center,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
          },
        ),
        pw.SizedBox(height: 22),
        pw.Text('Por día de la semana',
            style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: [for (final w in report.weekdays) w.weekday],
          data: [
            [for (final w in report.weekdays) w.days == 0 ? '-' : '${w.completionRate} %'],
          ],
          headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignment: pw.Alignment.center,
        ),
        pw.SizedBox(height: 22),
        pw.Text('Detalle diario',
            style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Fecha', 'Tomas', 'Estado'],
          data: [
            for (final d in report.days.reversed)
              [
                _date(d.date),
                '${d.taken} / ${d.expected}',
                d.complete ? 'Completo' : (d.taken > 0 ? 'Parcial' : 'Sin tomas'),
              ],
          ],
          headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignments: {1: pw.Alignment.center, 2: pw.Alignment.center},
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Este informe solo recoge lo registrado en la app. No sustituye el consejo de un profesional sanitario.',
          style: const pw.TextStyle(color: grey, fontSize: 8),
        ),
      ],
    ),
  );
  return doc.save();
}
