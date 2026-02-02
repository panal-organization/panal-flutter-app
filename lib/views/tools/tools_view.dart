import 'package:flutter/material.dart';
import 'package:panal_flutter_app/utils/app_colors.dart';

class ToolsView extends StatelessWidget {
  const ToolsView({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textBg.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.build,
                size: 40,
                color: index % 2 == 0
                    ? AppColors.warningBase
                    : AppColors.infoBase,
              ),
              const SizedBox(height: 12),
              Text(
                'Herramienta ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBase,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                index % 2 == 0 ? 'En uso' : 'Disponible',
                style: TextStyle(
                  color: index % 2 == 0
                      ? AppColors.warningBase
                      : AppColors.successBase,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
