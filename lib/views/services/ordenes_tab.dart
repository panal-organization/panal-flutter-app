import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class OrdenesTab extends StatelessWidget {
  const OrdenesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Órdenes de Servicio en Construcción',
        style: TextStyle(
          color: AppColors.textBase,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
