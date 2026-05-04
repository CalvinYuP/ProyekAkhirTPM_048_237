import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/password_validator.dart';

class PasswordCriteriaList extends StatelessWidget {
  final String password;
  
  const PasswordCriteriaList({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final criteria = PasswordValidator.getCriteria(password);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: criteria.map((item) {
        final isMet = item['met'] as bool;
        final label = item['label'] as String;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMet ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: isMet ? Colors.green : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isMet ? Colors.green : AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}