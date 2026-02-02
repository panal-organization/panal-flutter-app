import 'package:flutter/material.dart';
import 'package:panal_flutter_app/utils/app_colors.dart';

class WarehouseView extends StatelessWidget {
  const WarehouseView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.textBg.withOpacity(0.5)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondaryBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: AppColors.secondaryBase,
              ),
            ),
            title: Text(
              'Producto Item #$index',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textBase,
              ),
            ),
            subtitle: Text('Stock disponible: ${100 - index * 5} unidades'),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textBase,
            ),
          ),
        );
      },
    );
  }
}
