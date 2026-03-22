import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../controllers/app_controllers.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_toast.dart';
import 'ordenes_history_view.dart';

class OrdenesTab extends StatefulWidget {
  const OrdenesTab({super.key});

  @override
  State<OrdenesTab> createState() => _OrdenesTabState();
}

class _OrdenesTabState extends State<OrdenesTab> {
  final TextEditingController _descController = TextEditingController();
  final AlmacenController _almacenController = AlmacenController();
  final ArticulosController _articulosController = ArticulosController();
  final TipoOrdenesController _tiposController = TipoOrdenesController();
  final OrdenesServicioController _ordenesController =
      OrdenesServicioController();

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedPhoto;

  bool _isLoading = true;
  List<Almacen> _almacenes = [];
  List<Articulos> _articulos = [];
  List<TipoOrdenes> _tipos = [];

  Almacen? _selectedAlmacen;
  Articulos? _selectedArticulo;
  TipoOrdenes? _selectedTipo;
  String _selectedEstado = 'PENDIENTE';

  final List<String> _estados = ['PENDIENTE', 'EN_PROGRESO', 'RESUELTO'];

  String? _workspaceId;
  String? _userId;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _workspaceId = prefs.getString('selected_workspace_id');
      _userId = prefs.getString('user_id');

      if (_workspaceId != null) {
        final results = await Future.wait([
          _almacenController.getByWorkspace(_workspaceId!),
          _tiposController.getAll(),
        ]);

        if (mounted) {
          setState(() {
            _almacenes = (results[0] as List<Almacen>)
                .where((a) => (a.registros ?? 0) > 0)
                .toList();
            _tipos = results[1] as List<TipoOrdenes>;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, 'Error al cargar datos', isError: true);
      }
    }
  }

  Future<void> _loadArticulos(String almacenId) async {
    try {
      final list = await _articulosController.getByAlmacen(almacenId);
      if (mounted) {
        setState(() {
          _articulos = list;
          _selectedArticulo = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading articles: $e');
    }
  }

  Future<void> _submitOrder() async {
    if (_descController.text.isEmpty ||
        _selectedArticulo == null ||
        _selectedTipo == null) {
      AppToast.show(
        context,
        'Por favor completa todos los campos requeridos',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? finalPhotoUrl;

      if (_selectedPhoto != null && _userId != null) {
        finalPhotoUrl = await _ordenesController.uploadPhotoOnly(
          _userId!,
          _selectedPhoto!.path,
        );
      }

      final Map<String, dynamic> payload = {
        'descripcion': _descController.text,
        'created_by': _userId,
        'articulo_id': _selectedArticulo!.id,
        'tipo_id': _selectedTipo!.id,
        'workspace_id': _workspaceId,
        'estado': _selectedEstado,
      };

      if (finalPhotoUrl != null) {
        payload['foto'] = finalPhotoUrl;
      }

      final success = await _ordenesController.post(
        _ordenesController.endpoint,
        payload,
      );

      if (success) {
        if (mounted)
          AppToast.show(context, 'Orden de servicio creada con éxito');
        _resetForm();
      } else {
        if (mounted)
          AppToast.show(context, 'Error al crear la orden', isError: true);
      }
    } catch (e) {
      if (mounted) AppToast.show(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _descController.clear();
      _selectedAlmacen = null;
      _selectedArticulo = null;
      _selectedTipo = null;
      _selectedPhoto = null;
      _selectedEstado = 'PENDIENTE';
      _articulos = [];
    });
  }

  void _pickPhoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.secondaryBase,
              ),
              title: const Text('Tomar foto'),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? photo = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );
                if (photo != null) setState(() => _selectedPhoto = photo);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.secondaryBase,
              ),
              title: const Text('Elegir de galería'),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? photo = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (photo != null) setState(() => _selectedPhoto = photo);
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWarehouseIcon(String? iconName) {
    switch (iconName) {
      case 'inventory':
        return Icons.inventory_2_outlined;
      case 'archive':
        return Icons.archive_outlined;
      case 'category':
        return Icons.category_outlined;
      case 'storage':
        return Icons.storage_outlined;
      case 'shipping':
        return Icons.local_shipping_outlined;
      case 'computer':
        return Icons.computer_outlined;
      case 'laptop':
        return Icons.laptop_mac_outlined;
      case 'router':
        return Icons.router_outlined;
      case 'mobile':
        return Icons.smartphone_outlined;
      case 'print':
        return Icons.print_outlined;
      case 'memory':
        return Icons.memory_outlined;
      case 'settings':
        return Icons.settings_suggest_outlined;
      case 'construction':
        return Icons.construction_outlined;
      case 'factory':
        return Icons.factory_outlined;
      case 'widgets':
        return Icons.widgets_outlined;
      case 'science':
        return Icons.science_outlined;
      default:
        return Icons.home_repair_service_outlined;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'EN_PROGRESO':
        return AppColors.secondaryBase;
      case 'RESUELTO':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _almacenes.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.secondaryBase),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.contentBackground,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.secondaryBase,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nueva Orden',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBase,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.history_rounded,
                      color: AppColors.secondaryBase,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrdenesHistoryView(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPhotoPicker(),
              const SizedBox(height: 24),
              _buildSelectionCard(
                title: 'Almacén',
                subtitle: _selectedAlmacen?.nombre ?? 'Seleccionar almacén',
                icon: _getWarehouseIcon(_selectedAlmacen?.icono),
                onTap: _showAlmacenSelection,
                isSelected: _selectedAlmacen != null,
              ),
              const SizedBox(height: 12),
              _buildSelectionCard(
                title: 'Artículo',
                subtitle: _selectedArticulo?.nombre ?? 'Seleccionar artículo',
                icon: Icons.inventory_2_outlined,
                imageUrl: _selectedArticulo?.foto,
                onTap: _selectedAlmacen == null ? null : _showArticuloSelection,
                isSelected: _selectedArticulo != null,
                enabled: _selectedAlmacen != null,
              ),
              const SizedBox(height: 12),
              _buildSelectionCard(
                title: 'Tipo de Orden',
                subtitle: _selectedTipo?.nombre ?? 'Seleccionar tipo',
                icon: Icons.assignment_outlined,
                onTap: _showTipoSelection,
                isSelected: _selectedTipo != null,
              ),
              const SizedBox(height: 12),
              _buildSelectionCard(
                title: 'Estado Inicial',
                subtitle: _selectedEstado,
                icon: Icons.info_outline_rounded,
                onTap: _showEstadoSelection,
                isSelected: true,
                customColor: _getStatusColor(_selectedEstado),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _descController,
                  maxLines: 4,
                  cursorColor: AppColors.secondaryBase,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Describe los detalles de la orden...',
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.secondaryBase,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: SizedBox(
                  width: 180,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryBase,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'CREAR ORDEN',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _selectedPhoto == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 40,
                      color: AppColors.secondaryBase.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Adjuntar evidencia',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(_selectedPhoto!.path), fit: BoxFit.cover),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPhoto = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    String? imageUrl,
    VoidCallback? onTap,
    bool isSelected = false,
    bool enabled = true,
    Color? customColor,
  }) {
    final color = customColor ?? AppColors.secondaryBase;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(icon, color: color, size: 24),
                        )
                      : Icon(icon, color: color, size: 24),
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
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: enabled
                            ? AppColors.textBase
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
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
    );
  }

  void _showAlmacenSelection() {
    _showModalList(
      title: 'Seleccionar Almacén',
      builder: (context, controller) {
        final filtered = _almacenes
            .where(
              (a) =>
                  a.nombre?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  true,
            )
            .toList();
        return ListView.builder(
          controller: controller,
          itemCount: filtered.length,
          itemBuilder: (ctx, i) => ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.secondaryBase.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getWarehouseIcon(filtered[i].icono),
                color: AppColors.secondaryBase,
                size: 22,
              ),
            ),
            title: Text(
              filtered[i].nombre ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${filtered[i].registros} artículos'),
            onTap: () {
              setState(() {
                _selectedAlmacen = filtered[i];
                _articulos = [];
              });
              _loadArticulos(filtered[i].id!);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _showArticuloSelection() {
    _showModalList(
      title: 'Seleccionar Artículo',
      builder: (context, controller) {
        final filtered = _articulos
            .where(
              (a) =>
                  a.nombre?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  true,
            )
            .toList();
        return ListView.builder(
          controller: controller,
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final tieneImagen =
                filtered[i].foto != null && filtered[i].foto!.isNotEmpty;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 4,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondaryBase.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: tieneImagen
                      ? Image.network(
                          filtered[i].foto!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.secondaryBase,
                            size: 22,
                          ),
                        )
                      : const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.secondaryBase,
                          size: 22,
                        ),
                ),
              ),
              title: Text(
                filtered[i].nombre ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                filtered[i].descripcion ?? 'Sin descripción',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                setState(() => _selectedArticulo = filtered[i]);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _showTipoSelection() {
    _showModalList(
      title: 'Tipo de Orden',
      showSearch: false,
      builder: (context, controller) {
        return ListView.builder(
          controller: controller,
          itemCount: _tipos.length,
          itemBuilder: (ctx, i) => ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.secondaryBase.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppColors.secondaryBase,
                size: 22,
              ),
            ),
            title: Text(
              _tipos[i].nombre ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              setState(() => _selectedTipo = _tipos[i]);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _showEstadoSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Estado de la Orden',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._estados.map(
              (estado) => ListTile(
                leading: Icon(
                  Icons.circle,
                  color: _getStatusColor(estado),
                  size: 16,
                ),
                title: Text(
                  estado,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: _selectedEstado == estado
                    ? const Icon(
                        Icons.check_circle,
                        color: AppColors.secondaryBase,
                      )
                    : null,
                onTap: () {
                  setState(() => _selectedEstado = estado);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showModalList({
    required String title,
    required Widget Function(BuildContext, ScrollController) builder,
    bool showSearch = true,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (showSearch) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        onChanged: (val) =>
                            setModalState(() => _searchQuery = val),
                        cursorColor: AppColors.secondaryBase,
                        decoration: InputDecoration(
                          hintText: 'Buscar...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: AppColors.contentBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Expanded(child: builder(context, controller)),
                ],
              );
            },
          ),
        ),
      ),
    ).then((_) => setState(() => _searchQuery = ''));
  }
}
