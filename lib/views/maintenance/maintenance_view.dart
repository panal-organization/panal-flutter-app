import 'package:flutter/material.dart';
import 'package:panal_flutter_app/utils/app_colors.dart';

class MaintenanceView extends StatelessWidget {
  const MaintenanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildSectionHeader('Mantenimientos Programados'),
        _buildMaintenanceItem(
          'Revisión General Maquinaria A',
          'Hoy, 14:00 PM',
          AppColors.dangerBase,
          'Alta Prioridad',
        ),
        _buildMaintenanceItem(
          'Cambio de Aceite Generador',
          'Mañana, 09:00 AM',
          AppColors.warningBase,
          'Media Prioridad',
        ),
        const SizedBox(height: 16),
        _buildSectionHeader('Historial Reciente'),
        _buildMaintenanceItem(
          'Calibración de Sensores',
          'Ayer',
          AppColors.successBase,
          'Completado',
          isHistory: true,
        ),
        _buildMaintenanceItem(
          'Limpieza de Filtros',
          'Hace 2 días',
          AppColors.successBase,
          'Completado',
          isHistory: true,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textBase,
        ),
      ),
    );
  }

  Widget _buildMaintenanceItem(
    String title,
    String time,
    Color statusColor,
    String statusText, {
    bool isHistory = false,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.textBg.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isHistory ? Colors.grey : AppColors.textBase,
                      decoration: isHistory ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
