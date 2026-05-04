// lib/features/home/widgets/filter_chips.dart
// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class FilterChips extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;
  
  const FilterChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const categories = ['Semua', 'Kuliner', 'Sejarah', 'Alam', 'Budaya'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;
          
          return FilterChip(
            label: Text(category, style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
            )),
            selected: isSelected,
            onSelected: (_) => onCategorySelected(category),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primary,
            checkmarkColor: AppColors.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
          );
        },
      ),
    );
  }
}