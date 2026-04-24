import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class ExportUtils {
  static const List<String> _measurementKeys = [
    'Across Back',
    'Top Length (Long)',
    'Top Length (Short)',
    'Chest',
    'Sleeve Length (Long)',
    'Sleeve Length (Short)',
    'Around Arm',
    'Vest Length',
    'Neck',
    'Waist',
    'Trouser Length',
    'Shorts Length',
    'Hip',
    'Tie',
    'Bass',
  ];

  static Future<void> exportOrdersToExcel(List<TailorOrder> orders) async {
    final excel = Excel.createExcel();
    final sheet = excel['Orders'];

    // Header row
    sheet.appendRow([
      TextCellValue('Order ID'),
      TextCellValue('Customer Name'),
      TextCellValue('Style'),
      TextCellValue('Fabric'),
      TextCellValue('Price'),
      TextCellValue('Paid Amount'),
      TextCellValue('Balance'),
      TextCellValue('Status'),
      TextCellValue('Delivery Date'),
      TextCellValue('Order Date'),
    ]);

    // Data rows
    for (final order in orders) {
      sheet.appendRow([
        TextCellValue(order.id),
        TextCellValue(order.customerName),
        TextCellValue(order.style),
        TextCellValue(order.fabric),
        DoubleCellValue(order.price),
        DoubleCellValue(order.paidAmount),
        DoubleCellValue(order.balanceAmount),
        TextCellValue(order.status.name),
        TextCellValue(DateFormat('yyyy-MM-dd').format(order.deliveryDate)),
        TextCellValue(DateFormat('yyyy-MM-dd').format(order.createdAt)),
      ]);
    }

    final String fileName = 'Tailor_Orders_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    await _saveAndShare(excel, fileName);
  }

  static Future<void> exportCustomersToExcel(List<Customer> customers) async {
    final excel = Excel.createExcel();
    final sheet = excel['Customers'];

    // Header row
    sheet.appendRow([
      TextCellValue('Customer ID'),
      TextCellValue('Name'),
      TextCellValue('Phone'),
      TextCellValue('Email'),
      ..._measurementKeys.map((k) => TextCellValue(k)),
      TextCellValue('Other Measurements'),
      TextCellValue('Joined Date'),
    ]);

    // Data rows
    for (final customer in customers) {
      final otherMeasurements = customer.measurements.entries
          .where((e) => !_measurementKeys.contains(e.key))
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');

      sheet.appendRow([
        TextCellValue(customer.id),
        TextCellValue(customer.name),
        TextCellValue(customer.phone),
        TextCellValue(customer.email ?? ''),
        ..._measurementKeys.map((k) {
          final val = customer.measurements[k];
          return val != null ? DoubleCellValue(val) : TextCellValue('');
        }),
        TextCellValue(otherMeasurements),
        TextCellValue(DateFormat('yyyy-MM-dd').format(customer.createdAt)),
      ]);
    }

    final String fileName = 'Tailor_Customers_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    await _saveAndShare(excel, fileName);
  }

  static Future<void> exportAllData({
    required List<Customer> customers,
    required List<TailorOrder> orders,
  }) async {
    final excel = Excel.createExcel();
    
    // Customers Sheet
    final Sheet? customerSheet = excel['Customers'];
    if (customerSheet != null) {
      customerSheet.appendRow([
        TextCellValue('Customer ID'),
        TextCellValue('Name'),
        TextCellValue('Phone'),
        TextCellValue('Email'),
        ..._measurementKeys.map((k) => TextCellValue(k)),
        TextCellValue('Other Measurements'),
        TextCellValue('Joined Date'),
      ]);
      for (final customer in customers) {
        final otherMeasurements = customer.measurements.entries
            .where((e) => !_measurementKeys.contains(e.key))
            .map((e) => '${e.key}: ${e.value}')
            .join(', ');
        customerSheet.appendRow([
          TextCellValue(customer.id),
          TextCellValue(customer.name),
          TextCellValue(customer.phone),
          TextCellValue(customer.email ?? ''),
          ..._measurementKeys.map((k) {
            final val = customer.measurements[k];
            return val != null ? DoubleCellValue(val) : TextCellValue('');
          }),
          TextCellValue(otherMeasurements),
          TextCellValue(DateFormat('yyyy-MM-dd').format(customer.createdAt)),
        ]);
      }
    }

    // Orders Sheet
    final Sheet? orderSheet = excel['Orders'];
    if (orderSheet != null) {
      orderSheet.appendRow([
        TextCellValue('Order ID'),
        TextCellValue('Customer Name'),
        TextCellValue('Style'),
        TextCellValue('Fabric'),
        TextCellValue('Price'),
        TextCellValue('Paid Amount'),
        TextCellValue('Balance'),
        TextCellValue('Status'),
        TextCellValue('Delivery Date'),
        TextCellValue('Order Date'),
      ]);
      for (final order in orders) {
        orderSheet.appendRow([
          TextCellValue(order.id),
          TextCellValue(order.customerName),
          TextCellValue(order.style),
          TextCellValue(order.fabric),
          DoubleCellValue(order.price),
          DoubleCellValue(order.paidAmount),
          DoubleCellValue(order.balanceAmount),
          TextCellValue(order.status.name),
          TextCellValue(DateFormat('yyyy-MM-dd').format(order.deliveryDate)),
          TextCellValue(DateFormat('yyyy-MM-dd').format(order.createdAt)),
        ]);
      }
    }

    // Remove default Sheet1 if it exists and is empty
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final String fileName = 'Tailor_Full_Export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    await _saveAndShare(excel, fileName);
  }

  static Future<void> _saveAndShare(Excel excel, String fileName) async {
    final bytes = excel.encode();
    if (bytes == null) return;

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Exported Data');
  }
}
