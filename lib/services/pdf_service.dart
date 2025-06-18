import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../services/meal_plan_service.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateAndDownloadGroceryListPdf(
    List<GroceryItem> groceryList,
  ) async {
    final pdf = pw.Document();
    
    // Group items by category
    Map<String, List<GroceryItem>> groupedItems = {};
    for (GroceryItem item in groceryList) {
      if (!groupedItems.containsKey(item.category)) {
        groupedItems[item.category] = [];
      }
      groupedItems[item.category]!.add(item);
    }

    // Create PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Grocery List',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateFormat('MMM dd, yyyy').format(DateTime.now()),
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.orange200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Items: ${groceryList.length}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Categories: ${groupedItems.keys.length}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Grocery items by category
            ...groupedItems.entries.map((entry) {
              String category = entry.key;
              List<GroceryItem> items = entry.value;
              
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 16),
                  
                  // Category header
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.orange100,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      category,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange800,
                      ),
                    ),
                  ),
                  
                  pw.SizedBox(height: 8),
                  
                  // Category items
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      children: items.asMap().entries.map((itemEntry) {
                        int index = itemEntry.key;
                        GroceryItem item = itemEntry.value;
                        bool isLast = index == items.length - 1;
                        
                        return pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            border: isLast
                                ? null
                                : const pw.Border(
                                    bottom: pw.BorderSide(color: PdfColors.grey200),
                                  ),
                          ),
                          child: pw.Row(
                            children: [
                              // Checkbox
                              pw.Container(
                                width: 16,
                                height: 16,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: PdfColors.grey400),
                                  borderRadius: pw.BorderRadius.circular(2),
                                ),
                                child: item.isChecked
                                    ? pw.Center(
                                        child: pw.Text(
                                          '✓',
                                          style: pw.TextStyle(
                                            fontSize: 12,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColors.green700,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              
                              pw.SizedBox(width: 12),
                              
                              // Item name
                              pw.Expanded(
                                child: pw.Text(
                                  item.name,
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    decoration: item.isChecked
                                        ? pw.TextDecoration.lineThrough
                                        : null,
                                    color: item.isChecked
                                        ? PdfColors.grey600
                                        : PdfColors.black,
                                  ),
                                ),
                              ),
                              
                              // Quantity
                              if (item.quantity > 1)
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.grey100,
                                    borderRadius: pw.BorderRadius.circular(12),
                                  ),
                                  child: pw.Text(
                                    '${item.quantity}x',
                                    style: const pw.TextStyle(
                                      fontSize: 12,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            }).toList(),
            
            pw.SizedBox(height: 30),
            
            // Footer
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Generated by InstaRecipe App',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ];
        },
      ),
    );

    // Save and share the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'grocery_list_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf',
    );
  }

  static Future<void> saveGroceryListPdf(List<GroceryItem> groceryList) async {
    try {
      final pdf = pw.Document();
      
      // Group items by category
      Map<String, List<GroceryItem>> groupedItems = {};
      for (GroceryItem item in groceryList) {
        if (!groupedItems.containsKey(item.category)) {
          groupedItems[item.category] = [];
        }
        groupedItems[item.category]!.add(item);
      }

      // Create PDF content (same as above)
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Grocery List',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      DateFormat('MMM dd, yyyy').format(DateTime.now()),
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.orange200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Items: ${groceryList.length}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Categories: ${groupedItems.keys.length}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Categories and items
              ...groupedItems.entries.map((entry) {
                String category = entry.key;
                List<GroceryItem> items = entry.value;
                
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 16),
                    
                    // Category header
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange100,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        category,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.orange800,
                        ),
                      ),
                    ),
                    
                    pw.SizedBox(height: 8),
                    
                    // Items list
                    ...items.map((item) {
                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        child: pw.Row(
                          children: [
                            pw.Container(
                              width: 16,
                              height: 16,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey400),
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                              child: item.isChecked
                                  ? pw.Center(
                                      child: pw.Text(
                                        '✓',
                                        style: pw.TextStyle(
                                          fontSize: 12,
                                          fontWeight: pw.FontWeight.bold,
                                          color: PdfColors.green700,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            pw.SizedBox(width: 12),
                            pw.Expanded(
                              child: pw.Text(
                                item.name,
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  decoration: item.isChecked
                                      ? pw.TextDecoration.lineThrough
                                      : null,
                                  color: item.isChecked
                                      ? PdfColors.grey600
                                      : PdfColors.black,
                                ),
                              ),
                            ),
                            if (item.quantity > 1)
                              pw.Text(
                                '${item.quantity}x',
                                style: const pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey700,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                );
              }).toList(),
            ];
          },
        ),
      );

      // Get the app's document directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'grocery_list_${DateFormat('yyyy_MM_dd_HH_mm').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');

      // Save the PDF to file
      await file.writeAsBytes(await pdf.save());

      // Share the file
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: fileName,
      );
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }
} 