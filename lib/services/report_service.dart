import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
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

  static const _navy = 0xFF1B2A4A;
  static const _gold = 0xFFD4AF37;
  static const _accent = 0xFFF5F0E8;

  Future<void> generatePdfReport({
    required Rifa rifa,
    required List<Participante> participantes,
    required String? organizacion,
    Map<String, String>? numerosEstado,
  }) async {
    final pdf = pw.Document();

    Uint8List? logoBytes;
    try {
      final data = await rootBundle.load('assets/logo/logo.png');
      logoBytes = data.buffer.asUint8List();
    } catch (_) {
      logoBytes = null;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 35, vertical: 30),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        header: (context) => _buildHeader(rifa, organizacion, logoBytes),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 16),
          _buildInfoRow(rifa),
          pw.SizedBox(height: 16),
          _buildSummary(participantes, rifa),
          pw.SizedBox(height: 16),
          if (numerosEstado != null) ...[
            _buildNumeroGrid(rifa, numerosEstado),
            pw.SizedBox(height: 16),
          ],
          _buildTable(participantes, rifa),
        ],
      ),
    );

    final bytes = await pdf.save();
    await _share(bytes, rifa.nombre);
  }

  pw.Widget _buildHeader(Rifa rifa, String? organizacion, Uint8List? logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColor.fromInt(_navy), PdfColor.fromInt(0xFF2C3E6B)],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: const pw.BorderRadius.only(
          topLeft: pw.Radius.circular(12),
          topRight: pw.Radius.circular(12),
          bottomLeft: pw.Radius.circular(4),
          bottomRight: pw.Radius.circular(4),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 14),
              child: pw.Image(pw.MemoryImage(logo), width: 48, height: 48),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  (organizacion ?? 'RIFADORADA').toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  rifa.nombre,
                  style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(_gold)),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('REPORTE DE RIFA',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              pw.SizedBox(height: 2),
              if (rifa.fechaSorteo != null)
                pw.Text('Sorteo: ${DateFormat('dd/MM/yyyy').format(rifa.fechaSorteo!)}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(_gold))),
              pw.Text('Creada: ${DateFormat('dd/MM/yyyy').format(rifa.fechaCreacion)}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(_gold))),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(Rifa rifa) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _infoBadge('Tipo', rifa.tipoRifa),
        _infoBadge('Valor', '\$${NumberFormat('#,###').format(rifa.precioNumero)}'),
        _infoBadge('Total Números', '${rifa.cantidadNumeros}'),
        _infoBadge('Creada', DateFormat('dd/MM/yyyy').format(rifa.fechaCreacion)),
        if (rifa.fechaSorteo != null)
          _infoBadge('Sorteo', DateFormat('dd/MM/yyyy').format(rifa.fechaSorteo!)),
      ],
    );
  }

  pw.Widget _infoBadge(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label.toUpperCase(),
            style: pw.TextStyle(fontSize: 6, color: PdfColors.grey600, letterSpacing: 1)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(_navy))),
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
    final pct = rifa.cantidadNumeros > 0 ? (vendidos * 100 / rifa.cantidadNumeros) : 0.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('RESUMEN EJECUTIVO',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        _progressBar(pct),
        pw.SizedBox(height: 10),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly, children: [
          _summaryCard('Vendidos', '$vendidos / ${rifa.cantidadNumeros}', PdfColors.blue800),
          _summaryCard('Disponibles', '$disponibles', PdfColors.grey600),
        ]),
        pw.SizedBox(height: 6),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly, children: [
          _summaryCard('Pagados', '${pagados.length}', PdfColors.green700),
          _summaryCard('Abonados', '${abonados.length}', PdfColors.orange700),
          _summaryCard('Pendientes', '${pendientes.length}', PdfColors.red700),
        ]),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly, children: [
          _summaryCard('Recaudado', '\$${NumberFormat('#,###').format(recaudado)}', PdfColors.green700),
          _summaryCard('Por Cobrar', '\$${NumberFormat('#,###').format(porCobrar)}', PdfColors.orange700),
          _summaryCard('Potencial', '\$${NumberFormat('#,###').format(recaudado + porCobrar)}', PdfColors.blue800),
        ]),
      ],
    );
  }

  pw.Widget _progressBar(double pct) {
    return pw.Container(
      height: 18,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(9)),
      ),
      child: pw.Stack(
        alignment: pw.Alignment.centerLeft,
        children: [
          pw.Container(
            width: pct * 4.35,
            height: 14,
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColor.fromInt(_gold), PdfColor.fromInt(0xFF8B6914)],
                begin: pw.Alignment.centerLeft,
                end: pw.Alignment.centerRight,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
          ),
          pw.Positioned.fill(
            child: pw.Center(
              child: pw.Text('${pct.toStringAsFixed(0)}% vendidos',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold,
                      color: pct > 40 ? PdfColors.white : PdfColors.black)),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryCard(String label, String value, PdfColor color) {
    return pw.Container(
      width: 100,
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 3),
          pw.Text(label, style: pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  pw.Widget _buildTable(List<Participante> participantes, Rifa rifa) {
    participantes.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));

    final headerDecoration = pw.BoxDecoration(
      gradient: pw.LinearGradient(
        colors: [PdfColor.fromInt(_navy), PdfColor.fromInt(0xFF2C3E6B)],
        begin: pw.Alignment.centerLeft,
        end: pw.Alignment.centerRight,
      ),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('DETALLE DE PARTICIPANTES',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _buildDataTable(participantes, rifa, headerDecoration),
      ],
    );
  }

  pw.Widget _buildNumeroGrid(Rifa rifa, Map<String, String> estados) {
    final cols = rifa.tipoRifa == '3 cifras' ? 8 : 10;
    final digitos = rifa.tipoRifa == '3 cifras' ? 3 : 2;
    final total = rifa.cantidadNumeros;
    final rows = (total / cols).ceil();

    final verde = PdfColors.green800;
    final amarillo = PdfColor.fromInt(0xFFFBC02D);
    final azul = PdfColors.blue700;
    final gris = PdfColors.grey200;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('ESTADO DE NÚMEROS',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.start, children: [
          _gridLegend(verde, 'Disponible'),
          pw.SizedBox(width: 10),
          _gridLegend(amarillo, 'Reservado'),
          pw.SizedBox(width: 10),
          _gridLegend(azul, 'Pagado'),
        ]),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
          columnWidths: {for (var i = 0; i < cols; i++) i: const pw.FlexColumnWidth(1)},
          children: [
            for (var r = 0; r < rows; r++) ...[
              pw.TableRow(
                children: [
                  for (var c = 0; c < cols; c++) ...[
                    () {
                      final idx = r * cols + c;
                      if (idx >= total) return _gridCell('', gris, PdfColors.grey300);
                      final numStr = idx.toString().padLeft(digitos, '0');
                      final est = estados[numStr];
                      final color = est == 'pagado' ? azul : est == 'reservado' ? amarillo : verde;
                      final textColor = est == 'reservado' ? PdfColors.black : PdfColors.white;
                      return _gridCell(numStr, color, textColor);
                    }(),
                  ],
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  pw.Widget _gridLegend(PdfColor color, String label) {
    return pw.Row(children: [
      pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(color: color, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)))),
      pw.SizedBox(width: 3),
      pw.Text(label, style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
    ]);
  }

  pw.Widget _gridCell(String text, PdfColor bg, PdfColor fg) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(2),
      color: bg,
      alignment: pw.Alignment.center,
      child: pw.Text(text, style: pw.TextStyle(fontSize: 6, color: fg, fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _buildDataTable(List<Participante> participantes, Rifa rifa, pw.BoxDecoration headerDecoration) {
    final cellStyle = pw.TextStyle(fontSize: 7);
    final altColor = PdfColor.fromInt(_accent);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.5),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(1.2),
        5: pw.FlexColumnWidth(1.2),
        6: pw.FlexColumnWidth(1.2),
        7: pw.FlexColumnWidth(0.8),
      },
      children: [
        pw.TableRow(
          decoration: headerDecoration,
          children: ['#', 'Nombre', 'WhatsApp', 'Números', 'Estado', 'Pagado', 'Total', 'Abonos']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(h, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ))
              .toList(),
        ),
        ...participantes.asMap().entries.map((e) {
          final p = e.value;
          final idx = e.key + 1;
          final total = p.numeros.length * rifa.precioNumero;
          final isPagado = p.estadoPago == EstadoPago.pagado;
          final isAbonado = p.estadoPago == EstadoPago.abonado;
          final estado = isPagado ? 'PAGADO' : isAbonado ? 'ABONADO' : 'PENDIENTE';
          final estadoColor = isPagado ? PdfColors.green700 : isAbonado ? PdfColors.orange700 : PdfColors.red700;
          final rowColor = e.key.isEven ? null : altColor;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: rowColor,
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.3)),
            ),
            children: [
              _cell('$idx', pw.Alignment.center, cellStyle),
              _cell(p.nombre, pw.Alignment.centerLeft, cellStyle),
              _cell(p.whatsapp, pw.Alignment.centerLeft, cellStyle),
              _cell(p.numeros.join(', '), pw.Alignment.centerLeft, cellStyle),
              pw.Padding(
                padding: const pw.EdgeInsets.all(3),
                child: pw.Text(estado, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: estadoColor)),
              ),
              _cell('\$${NumberFormat('#,###').format(p.totalPagado)}', pw.Alignment.centerRight, cellStyle),
              _cell('\$${NumberFormat('#,###').format(total)}', pw.Alignment.centerRight, cellStyle),
              _cell('${p.abonos.length}', pw.Alignment.center, cellStyle),
            ],
          );
        }),
      ],
    );
  }

  pw.Padding _cell(String text, pw.Alignment align, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Container(
        alignment: align,
        child: pw.Text(text, style: style),
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.Text(
            'RifaDorada',
            style: pw.TextStyle(fontSize: 7, color: PdfColor.fromInt(_navy), fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Pág. ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
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
