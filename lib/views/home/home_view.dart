import 'package:flutter/material.dart';
import 'package:panal_flutter_app/utils/app_colors.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Bienvenido, Usuario',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textBase,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Dashboard Cards
          Row(
            children: [
              _buildSummaryCard(
                title: 'Tareas Pendientes',
                count: '12',
                color: AppColors.primaryBase,
                bgColor: AppColors.primaryBg,
                icon: Icons.task_alt,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: 'Alertas',
                count: '3',
                color: AppColors.dangerBase,
                bgColor: AppColors.dangerBg,
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryCard(
                title: 'Inventario Bajo',
                count: '5',
                color: AppColors.orangeBase,
                bgColor: AppColors.orangeBg,
                icon: Icons.inventory,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: 'Activos',
                count: '89',
                color: AppColors.successBase,
                bgColor: AppColors.successBg,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String count,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              count,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textBase,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
