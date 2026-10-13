import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/category_form_sheet.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/round_back_button.dart';

class CategoryItem {
  String name;
  String transactions;
  IconData icon;

  CategoryItem({
    required this.name,
    required this.transactions,
    required this.icon,
  });
}

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  bool isExpense = true;

  final List<CategoryItem> expenseCategories = [
    CategoryItem(
      name: 'Food & Dining',
      transactions: '128 transactions',
      icon: Icons.lunch_dining,
    ),
    CategoryItem(
      name: 'Shopping',
      transactions: '54 transactions',
      icon: Icons.shopping_bag,
    ),
    CategoryItem(
      name: 'Transport',
      transactions: '76 transactions',
      icon: Icons.directions_bus,
    ),
    CategoryItem(
      name: 'Entertainment',
      transactions: '31 transactions',
      icon: Icons.movie,
    ),
    CategoryItem(
      name: 'Other',
      transactions: '9 transactions',
      icon: Icons.more_horiz,
    ),
  ];

  final List<CategoryItem> incomeCategories = [
    CategoryItem(
      name: 'Salary',
      transactions: '12 transactions',
      icon: Icons.work,
    ),
    CategoryItem(
      name: 'Business',
      transactions: '8 transactions',
      icon: Icons.store,
    ),
    CategoryItem(
      name: 'Investment',
      transactions: '5 transactions',
      icon: Icons.trending_up,
    ),
    CategoryItem(
      name: 'Other Income',
      transactions: '3 transactions',
      icon: Icons.account_balance_wallet,
    ),
  ];

  List<CategoryItem> get categories =>
      isExpense ? expenseCategories : incomeCategories;

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTheme.body(13, color: Colors.white)),
      ),
    );
  }

  /// Opens the add / edit sheet. Pass a category to edit it.
  Future<void> showCategoryDialog({CategoryItem? category}) async {
    final result = await showCategoryFormSheet(
      context,
      initialName: category?.name,
      initialIcon: category?.icon,
      isDuplicate: (name) => categories.any(
        (item) =>
            item != category && item.name.toLowerCase() == name.toLowerCase(),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      if (category == null) {
        categories.add(
          CategoryItem(
            name: result.name,
            transactions: '0 transactions',
            icon: result.icon,
          ),
        );
      } else {
        category.name = result.name;
        category.icon = result.icon;
      }
    });

    _toast(category == null ? 'Category added' : 'Category updated');
  }

  Future<void> deleteCategory(CategoryItem category) async {
    final confirm = await showConfirmDeleteDialog(
      context,
      title: 'Delete this category?',
      message: 'Are you sure you want to delete "${category.name}"?\n'
          "This can't be undone.",
    );

    if (confirm && mounted) {
      setState(() {
        categories.remove(category);
      });
      _toast('Category deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header (same position as the other screens)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: RoundBackButton(),
                    ),
                    Text('Categories', style: AppTheme.heading(17)),
                  ],
                ),
              ),
            ),

            // Expense / Income switch
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 38,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    _tabButton(
                      label: 'Expense',
                      selected: isExpense,
                      onTap: () {
                        setState(() => isExpense = true);
                      },
                    ),
                    _tabButton(
                      label: 'Income',
                      selected: !isExpense,
                      onTap: () {
                        setState(() => isExpense = false);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Category list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDFA),
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: categories.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(28),
                            child: Center(child: Text('No categories yet.')),
                          )
                        : Column(
                            children: categories.map((category) {
                              return _categoryRow(category);
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),

            // Add category button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => showCategoryDialog(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.terracotta,
                    side: const BorderSide(color: AppColors.terracotta),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    '+ Add category',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),

            // Bottom navigation
            Container(
              height: 66,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(Icons.home_outlined, 'Home'),
                  _navItem(Icons.savings_outlined, 'Saving'),
                  _navItem(Icons.pie_chart_outline, 'Dashboard'),
                  _navItem(Icons.notifications_none, 'Alerts'),
                  _navItem(Icons.person_outline, 'Account'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.terracotta : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.terracotta,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryRow(CategoryItem category) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF0E4D0),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(category.icon, color: AppColors.terracotta, size: 20),
          ),
          const SizedBox(width: 10),

          // Tap the category name or details to edit
          Expanded(
            child: InkWell(
              onTap: () => showCategoryDialog(category: category),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      category.transactions,
                      style: const TextStyle(
                        color: Color(0xFF978778),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Delete icon stays on the right
          IconButton(
            onPressed: () => deleteCategory(category),
            icon: const Icon(
              Icons.delete_outline,
              color: Color(0xFFD45F49),
              size: 19,
            ),
            tooltip: 'Delete category',
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label) {
    final selected = label == 'Account';

    return InkWell(
      onTap: () {
        // Connect each item to your existing app navigation.
      },
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 21,
              color: selected ? AppColors.terracotta : const Color(0xFFB3A58F),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: selected
                    ? AppColors.terracotta
                    : const Color(0xFF9C8E7B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}