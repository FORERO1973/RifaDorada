import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/rifa.dart';
import '../models/participante.dart';

class ReportService {
  static final ReportService instance = ReportService._();
  ReportService._();

  Future<void> generatePdfReport({
    required Rifa rifa,
    required List<Participante> participantes,
    required String? organizacion,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(
          base: await pw.Font.helvetica(),
          bold: await pw.Font.helveticaBold(),
        ),
        build: (context) => [
          _buildHeader(rifa, organizacion),
          _buildSummary(participantes, rifa),
          pw.SizedBox(height: 24),
          _buildTable(participantes, rifa),
          _buildFooter(),
        ],
      ),
    );

    final bytes = await pdf.save();
    await _share(bytes, rifa.nombre);
  }

  pw.Widget _buildHeader(Rifa rifa, String? organizacion) {
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFFFD700),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                (organizacion ?? 'RIFADORADA').toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'REPORTE DE RIFA',
                style: pw.TextStyle(
                  fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(height: 1, color: PdfColors.grey600),
              pw.SizedBox(height: 8),
              pw.Text(
                rifa.nombre,
                style: pw.TextStyle(fontSize: 14, color: PdfColors.black),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _infoItem('Tipo', rifa.tipoRifa),
            _infoItem('Valor', '\$${NumberFormat('#,###').format(rifa.precioNumero)}'),
            _infoItem('Total Números', '${rifa.cantidadNumeros}'),
            _infoItem('Creada', DateFormat('dd/MM/yyyy').format(rifa.fechaCreacion)),
            if (rifa.fechaSorteo != null)
              _infoItem('Sorteo', DateFormat('dd/MM/yyyy').format(rifa.fechaSorteo!)),
          ],
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _infoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label.toUpperCase(),
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _buildSummary(List<Participante> participantes, Rifa rifa) {
    final pagados = participantes.where((p) => p.estaPagado).toList();
    final abonados = participantes.where((p) => p.estaAbonado && !p.estaPagado).toList();
    final pendientes = participantes.where((p) => !p.estaAbonado && !p.estaPagado).toList();

    final recaudado = pagados.fold<double>(0, (s, p) => s + p.totalPagado) +
        abonados.fold<double>(0, (s, p) => s + p.totalPagado);

    final porCobrar = pendientes.fold<double>(0, (s, p) => s + p.numeros.length * rifa.precioNumero)
        + abonados.fold<double>(0, (s, p) => s + (p.numeros.length * rifa.precioNumero - p.totalPagado));

    final vendidos = participantes.fold<int>(0, (s, p) => s + p.numeros.length);
    final disponibles = rifa.cantidadNumeros - vendidos;
    final pct = rifa.cantidadNumeros > 0 ? (vendidos * 100 / rifa.cantidadNumeros).toStringAsFixed(0) : '0';

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('RESUMEN FINANCIERO',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _summaryCard('Números Vendidos', '$vendidos / ${rifa.cantidadNumeros} ($pct%)', PdfColors.blue),
              _summaryCard('Disponibles', '$disponibles', PdfColors.grey600),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _summaryCard('Pagados', '${pagados.length}', PdfColors.green700),
              _summaryCard('Abonados', '${abonados.length}', PdfColors.orange700),
              _summaryCard('Pendientes', '${pendientes.length}', PdfColors.red700),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _summaryCard('Recaudado', '\$${NumberFormat('#,###').format(recaudado)}', PdfColors.green700),
              _summaryCard('Por Cobrar', '\$${NumberFormat('#,###').format(porCobrar)}', PdfColors.orange700),
              _summaryCard('Potencial', '\$${NumberFormat('#,###').format(recaudado + porCobrar)}', PdfColors.blue),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryCard(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Container(
          width: 90,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            children: [
              pw.Text(value,
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
              pw.SizedBox(height: 2),
              pw.Text(label,
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTable(List<Participante> participantes, Rifa rifa) {
    participantes.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('DETALLE DE PARTICIPANTES',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFFFD700),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          cellStyle: pw.TextStyle(fontSize: 7),
          rowDecoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          ),
          headers: ['#', 'Nombre', 'WhatsApp', 'Números', 'Estado', 'Pagado', 'Total', 'Abonos'],
          data: participantes.asMap().entries.map((e) {
            final p = e.value;
            final idx = e.key + 1;
            final total = p.numeros.length * rifa.precioNumero;
            final estado = p.estadoPago == EstadoPago.pagado ? 'PAGADO'
                : p.estadoPago == EstadoPago.abonado ? 'ABONADO' : 'PENDIENTE';
            return [
              '$idx',
              p.nombre,
              p.whatsapp,
              p.numeros.join(', '),
              estado,
              '\$${NumberFormat('#,###').format(p.totalPagado)}',
              '\$${NumberFormat('#,###').format(total)}',
              '${p.abonos.length}',
            ];
          }).toList(),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 40),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
            pw.Text('RifaDorada'),
          ],
        ),
      ],
    );
  }

  Future<void> _share(Uint8List bytes, String rifaNombre) async {
    try {
      final dir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final name = 'Reporte_${rifaNombre.replaceAll(' ', '_')}_$dateStr.pdf';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Reporte de Rifa: $rifaNombre',
      );
    } catch (e) {
      debugPrint('[PDF] Error: $e');
      rethrow;
    }
  }
}
