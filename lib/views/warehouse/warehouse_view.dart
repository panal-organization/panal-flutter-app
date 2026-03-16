import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/app_controllers.dart';
import '../../models/models.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_toast.dart';

class WarehouseView extends StatefulWidget {
  const WarehouseView({super.key});

  @override
  State<WarehouseView> createState() => _WarehouseViewState();
}

class _WarehouseViewState extends State<WarehouseView> {
  final AlmacenController _almacenController = AlmacenController();
  List<Almacen> _almacenes = [];
  bool _isLoading = true;
  String? _workspaceId;

  @override
  void initState() {
    super.initState();
    _loadAlmacenes();
  }

  Future<void> _loadAlmacenes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _workspaceId = prefs.getString('selected_workspace_id');

      if (_workspaceId != null) {
        final almacenes = await _almacenController.getByWorkspace(_workspaceId!);
        if (mounted) {
          setState(() {
            _almacenes = almacenes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, 'Error al cargar almacenes: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by parent
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Search or filters can go here later
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAlmacenes,
              color: AppColors.secondaryBase,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondaryBase,
                      ),
                    )
                  : _almacenes.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                            top: 10,
                            bottom: 100, // Space for FAB
                            left: 4,
                            right: 4,
                          ),
                          itemCount: _almacenes.length,
                          itemBuilder: (context, index) {
                            return _buildWarehouseCard(_almacenes[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 44,
        child: FloatingActionButton.extended(
          onPressed: _showCreateWarehouseDialog,
          backgroundColor: AppColors.secondaryBase,
          elevation: 3,
          icon: const Icon(Icons.add, size: 20, color: Colors.white),
          label: const Text(
            'Nuevo Almacén',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
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
            const SizedBox(height: 80),
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppColors.secondaryBase.withOpacity(0.15),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin almacenes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textBase.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Crea un almacén para organizar tus artículos y llevar un control de inventario.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
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
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to articles view (Placeholder)
            AppToast.show(context, 'Navegando a: ${warehouse.nombre}');
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBase.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      _getIconData(warehouse.icono),
                      color: AppColors.secondaryBase,
                      size: 26,
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
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBase,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${warehouse.registros ?? 0} artículos',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateWarehouseDialog() async {
    final nameController = TextEditingController();
    String selectedIcon = 'inventory';

    // Combined icons: Support Focused + Generic Inventory
    final Map<String, IconData> iconsAvailable = {
      'inventory': Icons.inventory_2_outlined,
      'archive': Icons.archive_outlined,
      'category': Icons.category_outlined,
      'storage': Icons.storage_outlined,
      'shipping': Icons.local_shipping_outlined,
      'computer': Icons.computer_outlined,
      'laptop': Icons.laptop_mac_outlined,
      'router': Icons.router_outlined,
      'mobile': Icons.smartphone_outlined,
      'print': Icons.print_outlined,
      'memory': Icons.memory_outlined,
      'settings': Icons.settings_suggest_outlined,
      'construction': Icons.construction_outlined,
      'factory': Icons.factory_outlined,
      'widgets': Icons.widgets_outlined,
      'science': Icons.science_outlined,
    };

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              scrollable: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Nuevo Almacén',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBase,
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nombre del almacén',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      style: const TextStyle(
                        color: AppColors.textBase,
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: AppColors.secondaryBase,
                      decoration: InputDecoration(
                        hintText: 'Ej: Consumibles',
                        hintStyle: TextStyle(
                          color: Colors.grey.withOpacity(0.4),
                          fontWeight: FontWeight.normal,
                        ),
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Selecciona un icono',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: iconsAvailable.length,
                        itemBuilder: (context, index) {
                          String key = iconsAvailable.keys.elementAt(index);
                          IconData iconData = iconsAvailable.values.elementAt(index);
                          return _buildIconOption(
                            iconData,
                            key,
                            selectedIcon,
                            (val) => setModalState(() => selectedIcon = val),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      AppToast.show(ctx, 'Ingresa un nombre', isError: true);
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryBase,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Crear',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      _createWarehouse(nameController.text.trim(), selectedIcon);
    }
  }

  Future<void> _createWarehouse(String name, String icon) async {
    if (_workspaceId == null) return;

    setState(() => _isLoading = true);
    try {
      final newAlmacen = Almacen(
        nombre: name,
        icono: icon,
        workspaceId: _workspaceId!,
        registros: 0,
      );

      final success = await _almacenController.create(newAlmacen);
      if (success) {
        if (!mounted) return;
        AppToast.show(context, 'Almacén creado correctamente');
        _loadAlmacenes();
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        AppToast.show(context, 'No se pudo crear el almacén', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, 'Error: $e', isError: true);
      }
    }
  }

  Widget _buildIconOption(
    IconData icon,
    String value,
    String currentValue,
    Function(String) onSelect,
  ) {
    final isSelected = value == currentValue;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondaryBase.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.secondaryBase : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.secondaryBase : Colors.grey,
          size: 18,
        ),
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'inventory': return Icons.inventory_2_outlined;
      case 'archive': return Icons.archive_outlined;
      case 'category': return Icons.category_outlined;
      case 'storage': return Icons.storage_outlined;
      case 'shipping': return Icons.local_shipping_outlined;
      case 'computer': return Icons.computer_outlined;
      case 'laptop': return Icons.laptop_mac_outlined;
      case 'router': return Icons.router_outlined;
      case 'mobile': return Icons.smartphone_outlined;
      case 'print': return Icons.print_outlined;
      case 'memory': return Icons.memory_outlined;
      case 'settings': return Icons.settings_suggest_outlined;
      case 'construction': return Icons.construction_outlined;
      case 'factory': return Icons.factory_outlined;
      case 'widgets': return Icons.widgets_outlined;
      case 'science': return Icons.science_outlined;
      default: return Icons.home_repair_service_outlined;
    }
  }
}
