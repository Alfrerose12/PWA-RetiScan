import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'permission_service.dart';

class PdfService {
  static Future<void> generateAndShareReport({
    required String patientName,
    required String analysisResult,
    required String date,
  }) async {
    // Solicitar permiso de almacenamiento
    bool hasPermission = await PermissionService.requestStoragePermission();
    if (!hasPermission) {
      print('No hay permisos de almacenamiento');
      // En versiones recientes de Android, getTemporaryDirectory no requiere permiso,
      // pero es buena práctica tenerlo cubierto si guardaríamos en descargas.
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Reporte de Análisis RetiScan', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Paciente: $patientName', style: pw.TextStyle(fontSize: 18)),
              pw.Text('Fecha de análisis: $date', style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 30),
              pw.Text('Resultado del Diagnóstico:', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Text(
                  analysisResult,
                  style: pw.TextStyle(fontSize: 16),
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.Text(
                'Este documento es generado automáticamente por RetiScan y no sustituye la evaluación médica profesional.',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/Reporte_Retiscan_${patientName.replaceAll(" ", "_")}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Compartir el archivo generado
      await Share.shareXFiles([XFile(file.path)], text: 'Aquí tienes tu reporte de análisis de RetiScan.');
    } catch (e) {
      print('Error al generar o compartir PDF: $e');
    }
  }
}
