import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/meal_plan_service.dart';
import '../services/pdf_service.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final MealPlanService _mealPlanService = MealPlanService();
  final TextEditingController _newItemController = TextEditingController();
  String _selectedCategory = 'Other';
  bool _isGeneratingPdf = false;

  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Meat & Seafood',
    'Dairy',
    'Grains & Cereals',
    'Condiments & Oils',
    'Spices & Herbs',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _mealPlanService.addListener(_onMealPlanChanged);
  }

  @override
  void dispose() {
    _mealPlanService.removeListener(_onMealPlanChanged);
    _newItemController.dispose();
    super.dispose();
  }

  void _onMealPlanChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFfcf9f8),
        title: Text(
          'Add Custom Item',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1b110d),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newItemController,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF1b110d),
              ),
              decoration: InputDecoration(
                hintText: 'Item name',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF9a5e4c),
                ),
                filled: true,
                fillColor: const Color(0xFFf3eae7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF1b110d),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFf3eae7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF9a5e4c),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_newItemController.text.trim().isNotEmpty) {
                _mealPlanService.addCustomGroceryItem(
                  _newItemController.text.trim(),
                  _selectedCategory,
                );
                _newItemController.clear();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef6a42),
            ),
            child: Text(
              'Add',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (_mealPlanService.groceryList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No items in grocery list to download',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      await PdfService.generateAndDownloadGroceryListPdf(_mealPlanService.groceryList);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Grocery list PDF downloaded successfully!',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: const Color(0xFFef6a42),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to generate PDF: ${e.toString()}',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  Map<String, List<GroceryItem>> _groupItemsByCategory() {
    Map<String, List<GroceryItem>> grouped = {};
    
    for (GroceryItem item in _mealPlanService.groceryList) {
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = [];
      }
      grouped[item.category]!.add(item);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<GroceryItem>> groupedItems = _groupItemsByCategory();
    int totalItems = _mealPlanService.groceryList.length;
    int checkedItems = _mealPlanService.groceryList.where((item) => item.isChecked).length;

    return Scaffold(
      backgroundColor: const Color(0xFFfcf9f8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/meal-plan'),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1b110d),
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Grocery List',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1b110d),
                          ),
                        ),
                        if (totalItems > 0)
                          Text(
                            '$checkedItems of $totalItems items checked',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: const Color(0xFF9a5e4c),
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: _isGeneratingPdf 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1b110d),
                            ),
                          )
                        : const Icon(
                            Icons.more_vert,
                            color: Color(0xFF1b110d),
                          ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'add',
                        child: Row(
                          children: [
                            const Icon(Icons.add, color: Color(0xFF1b110d)),
                            const SizedBox(width: 8),
                            Text(
                              'Add Item',
                              style: GoogleFonts.plusJakartaSans(),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'regenerate',
                        child: Row(
                          children: [
                            const Icon(Icons.refresh, color: Color(0xFF1b110d)),
                            const SizedBox(width: 8),
                            Text(
                              'Regenerate List',
                              style: GoogleFonts.plusJakartaSans(),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'download',
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Color(0xFF1b110d)),
                            const SizedBox(width: 8),
                            Text(
                              'Download PDF',
                              style: GoogleFonts.plusJakartaSans(),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            const Icon(Icons.clear_all, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'Clear List',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'add':
                          _showAddItemDialog();
                          break;
                        case 'regenerate':
                          _mealPlanService.regenerateGroceryList();
                          break;
                        case 'download':
                          _downloadPdf();
                          break;
                        case 'clear':
                          _showClearConfirmation();
                          break;
                      }
                    },
                  ),
                ],
              ),
            ),

            // Progress Bar
            if (totalItems > 0)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFf3eae7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: totalItems > 0 ? checkedItems / totalItems : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFef6a42),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

            // Grocery List
            Expanded(
              child: totalItems == 0
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: const Color(0xFF9a5e4c).withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No grocery items',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF9a5e4c),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add meals to your plan to generate\na grocery list automatically',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: const Color(0xFF9a5e4c),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groupedItems.keys.length,
                      itemBuilder: (context, index) {
                        String category = groupedItems.keys.elementAt(index);
                        List<GroceryItem> items = groupedItems[category]!;
                        return _buildCategorySection(category, items);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: totalItems > 0 ? FloatingActionButton.extended(
        onPressed: _isGeneratingPdf ? null : _downloadPdf,
        backgroundColor: _isGeneratingPdf 
            ? Colors.grey 
            : const Color(0xFFef6a42),
        icon: _isGeneratingPdf 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.picture_as_pdf,
                color: Colors.white,
              ),
        label: Text(
          _isGeneratingPdf ? 'Generating...' : 'Download PDF',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCategorySection(String category, List<GroceryItem> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              category,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1b110d),
              ),
            ),
          ),

          // Category Items
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                int itemIndex = _mealPlanService.groceryList.indexOf(entry.value);
                GroceryItem item = entry.value;
                bool isLast = entry.key == items.length - 1;

                return Container(
                  decoration: BoxDecoration(
                    border: isLast ? null : const Border(
                      bottom: BorderSide(
                        color: Color(0xFFf3eae7),
                        width: 1,
                      ),
                    ),
                  ),
                  child: CheckboxListTile(
                    value: item.isChecked,
                    onChanged: (value) {
                      _mealPlanService.toggleGroceryItem(itemIndex);
                    },
                    title: Text(
                      item.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: item.isChecked 
                            ? const Color(0xFF9a5e4c) 
                            : const Color(0xFF1b110d),
                        decoration: item.isChecked 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                    ),
                    subtitle: item.quantity > 1 
                        ? Text(
                            'Quantity: ${item.quantity}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: const Color(0xFF9a5e4c),
                            ),
                          )
                        : null,
                    secondary: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFF9a5e4c),
                        size: 20,
                      ),
                      onPressed: () {
                        _mealPlanService.removeGroceryItem(itemIndex);
                      },
                    ),
                    activeColor: const Color(0xFFef6a42),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFfcf9f8),
        title: Text(
          'Clear Grocery List',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1b110d),
          ),
        ),
        content: Text(
          'Are you sure you want to clear all items from your grocery list?',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF1b110d),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF9a5e4c),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _mealPlanService.clearGroceryList();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Clear',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 