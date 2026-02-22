import 'package:flutter/material.dart';
import '../../controllers/app_controllers.dart';
import '../../models/models.dart';
import '../../utils/app_colors.dart';

class WarehouseView extends StatefulWidget {
  const WarehouseView({super.key});

  @override
  State<WarehouseView> createState() => _WarehouseViewState();
}

class _WarehouseViewState extends State<WarehouseView> {
  final AlmacenController _almacenController = AlmacenController();
  List<Almacen> _almacenes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlmacenes();
  }

  Future<void> _loadAlmacenes() async {
    setState(() => _isLoading = true);
    try {
      final almacenes = await _almacenController.getAll();
      setState(() {
        _almacenes = almacenes;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar almacenes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // Action Button - Inside Content at Top Right
        Align(alignment: Alignment.centerRight, child: _buildCreateButton()),

        const SizedBox(height: 15),

        // List of Warehouses
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAlmacenes,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _almacenes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _almacenes.length,
                    itemBuilder: (context, index) {
                      return _buildWarehouseCard(_almacenes[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryBase,
        borderRadius: BorderRadius.circular(60),
        boxShadow: [
          BoxShadow(
            color: Colors.transparent,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Implement navigation
          },
          borderRadius: BorderRadius.circular(60),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Nuevo almacen',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppColors.secondaryBase.withOpacity(0.2),
            ),
            const SizedBox(height: 20),
            Text(
              'No tienes almacenes creados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.menuBackground.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea tu primer almacén para empezar\na gestionar tus artículos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseCard(Almacen warehouse) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to warehouse details / articles
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.secondaryBg.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Icon(
                    _getIconData(warehouse.icono),
                    color: AppColors.secondaryBase,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name and count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warehouse.nombre ?? 'Sin nombre',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.menuBackground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${warehouse.registros ?? 0} artículos registrados',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    // Map string icons to IconData if applicable, or return default
    switch (iconName) {
      case 'inventory':
        return Icons.inventory_2_outlined;
      case 'archive':
        return Icons.archive_outlined;
      case 'kitchen':
        return Icons.kitchen_outlined;
      case 'factory':
        return Icons.factory_outlined;
      default:
        return Icons.home_repair_service_outlined;
    }
  }
}
