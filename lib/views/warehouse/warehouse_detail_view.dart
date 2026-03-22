import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/app_controllers.dart';
import '../../models/models.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_toast.dart';

class WarehouseDetailView extends StatefulWidget {
  final Almacen warehouse;

  const WarehouseDetailView({super.key, required this.warehouse});

  @override
  State<WarehouseDetailView> createState() => _WarehouseDetailViewState();
}

class _WarehouseDetailViewState extends State<WarehouseDetailView> {
  final ArticulosController _articulosController = ArticulosController();
  final AlmacenController _almacenController = AlmacenController();
  late Almacen _currentWarehouse;
  List<Articulos> _articulos = [];
  List<Articulos> _articulosFiltrados = [];
  List<Almacen> _almacenes = [];
  bool _isLoading = true;
  bool _showTrash = false;
  String? _userId;
  String? _workspaceId;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentWarehouse = widget.warehouse;
    _loadInitialData();
    _searchController.addListener(_onSearch);
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    _workspaceId = prefs.getString('selected_workspace_id');
    
    _loadWarehouseData();
    _loadArticulos();
    if (_workspaceId != null) {
      _loadAlmacenes();
    }
  }

  Future<void> _loadWarehouseData() async {
    if (_currentWarehouse.id == null) return;
    try {
      final updated = await _almacenController.getOne(_currentWarehouse.id!);
      if (updated != null && mounted) {
        setState(() {
          _currentWarehouse = updated;
        });
      }
    } catch (e) {
      debugPrint('Error loading warehouse data: $e');
    }
  }

  Future<void> _loadAlmacenes() async {
    try {
      if (_workspaceId != null) {
        final filteredAlmacenes = await _almacenController.getByWorkspace(_workspaceId!);
        if (mounted) {
          setState(() {
            _almacenes = filteredAlmacenes;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading other warehouses: $e');
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _articulosFiltrados = query.isEmpty
          ? List.from(_articulos)
          : _articulos
                .where(
                  (a) =>
                      (a.nombre ?? '').toLowerCase().contains(query) ||
                      (a.descripcion ?? '').toLowerCase().contains(query),
                )
                .toList();
    });
  }

  Future<void> _loadArticulos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final id = _currentWarehouse.id;
      if (id != null) {
        // Load with status filter
        final articulos = await _articulosController.getByAlmacenWithStatus(
          id,
          !_showTrash,
        );
        if (mounted) {
          setState(() {
            _articulos = articulos;
            _articulosFiltrados = List.from(articulos);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, 'Error al cargar artículos: $e', isError: true);
      }
    }
  }

  Future<void> _refreshAllData() async {
    await Future.wait([
      _loadWarehouseData(),
      _loadArticulos(),
      if (_workspaceId != null) _loadAlmacenes(),
    ]);
  }

  Future<void> _toggleTrash() async {
    setState(() {
      _showTrash = !_showTrash;
    });
    _loadArticulos();
  }

  IconData _getIconData(String? iconName) {
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

  @override
  Widget build(BuildContext context) {
    final warehouse = widget.warehouse;

    return Scaffold(
      backgroundColor: AppColors.contentBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textBase,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _buildAppBarBackground(warehouse),
            ),
            actions: [
              IconButton(
                onPressed: _toggleTrash,
                icon: Icon(
                  _showTrash
                      ? Icons.inventory_2_rounded
                      : Icons.delete_outline_rounded,
                  color: _showTrash
                      ? AppColors.secondaryBase
                      : AppColors.textBase,
                  size: 22,
                ),
                tooltip: _showTrash ? 'Ver activos' : 'Ver papelera',
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
        body: Column(
          children: [
            // Search bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textBase, fontSize: 15),
                cursorColor: AppColors.secondaryBase,
                decoration: InputDecoration(
                  hintText: 'Buscar artículos...',
                  hintStyle: TextStyle(
                    color: Colors.grey.withOpacity(0.5),
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.secondaryBase,
                    size: 22,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.contentBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.secondaryBase.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // Divider
            Container(height: 1, color: Colors.grey.withOpacity(0.08)),
            // Content
            Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshAllData,
              color: AppColors.secondaryBase,
              child: _isLoading && _articulosFiltrados.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.secondaryBase))
                  : _articulosFiltrados.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 10, bottom: 80, left: 16, right: 16),
                          itemCount: _articulosFiltrados.length,
                          itemBuilder: (context, index) {
                            return _buildArticuloCard(_articulosFiltrados[index]);
                          },
                        ),
            ),
          ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return SizedBox(
      height: 40,
      child: FloatingActionButton.extended(
        onPressed: _showCreateArticuloDialog,
        backgroundColor: AppColors.secondaryBase,
        elevation: 3,
        icon: const Icon(Icons.add, size: 20, color: Colors.white),
        label: const Text(
          'Nuevo Artículo',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateArticuloDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    XFile? selectedImageFile;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.secondaryBase),
            primaryColor: AppColors.secondaryBase,
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: AppColors.secondaryBase,
              selectionColor: AppColors.secondaryBg,
              selectionHandleColor: AppColors.secondaryBase,
            ),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  'Nuevo Artículo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBase,
                    fontSize: 18,
                  ),
                ),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nombre del artículo',
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
                            hintText: 'Ej: Tape doble cara',
                            hintStyle: TextStyle(
                              color: Colors.grey.withOpacity(0.4),
                              fontWeight: FontWeight.normal,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: AppColors.secondaryBase,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Descripción',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          style: const TextStyle(
                            color: AppColors.textBase,
                            fontWeight: FontWeight.w500,
                          ),
                          cursorColor: AppColors.secondaryBase,
                          decoration: InputDecoration(
                            hintText: 'Ej: Consumible de oficina',
                            hintStyle: TextStyle(
                              color: Colors.grey.withOpacity(0.4),
                              fontWeight: FontWeight.normal,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: AppColors.secondaryBase,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Photo Picker redesign reverted to simpler style
                        GestureDetector(
                          onTap: () async {
                            showModalBottomSheet(
                              context: ctx,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (sheetCtx) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt, color: AppColors.secondaryBase),
                                      title: const Text('Tomar foto con cámara'),
                                      onTap: () async {
                                        Navigator.pop(sheetCtx);
                                        final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                                        if (img != null) setModalState(() => selectedImageFile = img);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo_library, color: AppColors.secondaryBase),
                                      title: const Text('Elegir de galería'),
                                      onTap: () async {
                                        Navigator.pop(sheetCtx);
                                        final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                                        if (img != null) setModalState(() => selectedImageFile = img);
                                      },
                                    ),
                                    if (selectedImageFile != null)
                                      ListTile(
                                        leading: const Icon(Icons.delete, color: AppColors.dangerBase),
                                        title: const Text('Quitar foto', style: TextStyle(color: AppColors.dangerBase)),
                                        onTap: () {
                                          Navigator.pop(sheetCtx);
                                          setModalState(() => selectedImageFile = null);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: AppColors.contentBackground,
                              border: Border.all(
                                color: selectedImageFile != null ? AppColors.secondaryBase : Colors.grey.shade300,
                                width: selectedImageFile != null ? 2 : 1,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  selectedImageFile != null 
                                    ? Icons.check_circle_rounded 
                                    : Icons.camera_alt_outlined,
                                  color: selectedImageFile != null 
                                    ? AppColors.secondaryBase 
                                    : Colors.grey,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  selectedImageFile != null 
                                    ? 'Foto adjuntada' 
                                    : 'Adjuntar foto (opcional)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selectedImageFile != null 
                                      ? AppColors.secondaryBase 
                                      : Colors.grey,
                                    fontWeight: selectedImageFile != null 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Crear Artículo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result == true) {
      _createArticulo(
        nameController.text.trim(),
        descriptionController.text.trim(),
        selectedImageFile?.path,
      );
    }
  }

  Future<void> _createArticulo(
    String name,
    String description,
    String? imagePath,
  ) async {
    if (widget.warehouse.id == null) return;

    setState(() => _isLoading = true);
    try {
      // Create minimal object first as requested
      final newArticulo = Articulos(
        nombre: name,
        descripcion: description,
        almacenId: widget.warehouse.id,
        estatus: true,
      );

      final success = await _articulosController.create(newArticulo);
      if (success) {
        // Find the created article to get its ID (we don't have the returned ID from boolean create)
        // Note: Ideally the API returns the created object, but here we reload and find.
        // However, if we need to upload photo we need the object ID.
        // Let's reload and find the latest one with the same name.
        final articles = await _articulosController.getByAlmacen(
          widget.warehouse.id!,
        );
        final created = articles.firstWhere(
          (a) => a.nombre == name,
          orElse: () => articles.last,
        );

        if (imagePath != null && _userId != null) {
          await _articulosController.uploadPhoto(
            created.id!,
            _userId!,
            imagePath,
          );
        }

        if (!mounted) return;
        AppToast.show(context, 'Artículo creado correctamente');
        _loadArticulos();
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        AppToast.show(context, 'No se pudo crear el artículo', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, 'Error: $e', isError: true);
      }
    }
  }

  Future<void> _updateStatus(Articulos articulo, bool active) async {
    if (articulo.id == null) return;
    
    if (!active) {
      final confirm = await _confirmDelete();
      if (confirm != true) return;
    }

    try {
      final updateData = Articulos(estatus: active);
      final ok = await _articulosController.update(articulo.id!, updateData);
      if (ok) {
        if (!mounted) return;
        AppToast.show(
          context,
          active ? 'Artículo restaurado' : 'Artículo enviado a la papelera',
        );
        _loadArticulos();
      } else {
        if (!mounted) return;
        AppToast.show(
          context,
          'No se pudo actualizar el estado',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Error: $e', isError: true);
      }
    }
  }

  Future<bool?> _confirmDelete() async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Mover a Papelera',
          style: TextStyle(color: AppColors.textBase, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '¿Estás seguro de que deseas enviar este artículo a la papelera?',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerBase,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Mover',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(Articulos articulo) {
    final bool isTrash = !(articulo.estatus ?? true);

    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      onSelected: (val) {
        if (val == 0) _showEditArticuloDialog(articulo);
        if (val == 1) _showMoveArticuloDialog(articulo);
        if (val == 2) _updateStatus(articulo, isTrash);
      },
      itemBuilder: (context) => isTrash
          ? [
              PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    const Icon(Icons.restore_from_trash_rounded, color: AppColors.successBase, size: 18),
                    const SizedBox(width: 8),
                    const Text('Restaurar Artículo', style: TextStyle(fontSize: 14, color: AppColors.successBase)),
                  ],
                ),
              ),
            ]
          : [
              const PopupMenuItem(
                value: 0,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: AppColors.secondaryBase, size: 18),
                    SizedBox(width: 8),
                    Text('Editar Artículo', style: TextStyle(fontSize: 14, color: AppColors.textBase)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, color: AppColors.secondaryBase, size: 18),
                    SizedBox(width: 8),
                    Text('Cambiar Almacén', style: TextStyle(fontSize: 14, color: AppColors.textBase)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.dangerBase, size: 18),
                    SizedBox(width: 8),
                    Text('Mover a Papelera', style: TextStyle(fontSize: 14, color: AppColors.dangerBase)),
                  ],
                ),
              ),
            ],
    );
  }

  Future<void> _showMoveArticuloDialog(Articulos articulo) async {
    if (_almacenes.isEmpty) {
      await _loadAlmacenes();
    }
    
    // Filter out current warehouse
    final availableWarehouses = _almacenes.where((w) => w.id != widget.warehouse.id).toList();
    
    if (availableWarehouses.isEmpty) {
      AppToast.show(context, 'No hay otros almacenes en este espacio', isError: true);
      return;
    }

    String? selectedWarehouseId = availableWarehouses.first.id;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.secondaryBase)),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cambiar Almacén', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mover este artículo a:', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedWarehouseId,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                items: availableWarehouses.map((w) {
                  return DropdownMenuItem(
                    value: w.id,
                    child: Text(w.nombre ?? 'Sin nombre', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) => selectedWarehouseId = val,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryBase, foregroundColor: Colors.white),
              child: const Text('Mover', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedWarehouseId != null) {
      await _moveArticuloToWarehouse(articulo, selectedWarehouseId!);
    }
  }

  Future<void> _moveArticuloToWarehouse(Articulos articulo, String newWarehouseId) async {
    if (articulo.id == null) return;
    setState(() => _isLoading = true);
    try {
      final success = await _articulosController.update(articulo.id!, Articulos(almacenId: newWarehouseId));
      if (success) {
        AppToast.show(context, 'Artículo movido correctamente');
        _refreshAllData();
      } else {
        setState(() => _isLoading = false);
        AppToast.show(context, 'No se pudo mover el artículo', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      AppToast.show(context, 'Error: $e', isError: true);
    }
  }

  Future<void> _showEditArticuloDialog(Articulos articulo) async {
    final nameController = TextEditingController(text: articulo.nombre);
    final descriptionController = TextEditingController(text: articulo.descripcion);
    XFile? selectedImageFile;
    bool photoRemoved = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.secondaryBase),
            primaryColor: AppColors.secondaryBase,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final tieneFotoActual = articulo.foto != null && articulo.foto!.isNotEmpty;
              
              return AlertDialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('Editar Artículo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Nombre del artículo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.secondaryBase, width: 2), borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Descripción', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.secondaryBase, width: 2), borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Photo Picker in Edit reverted to simpler style
                        GestureDetector(
                          onTap: () async {
                            showModalBottomSheet(
                              context: ctx,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                              builder: (sheetCtx) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt, color: AppColors.secondaryBase),
                                      title: const Text('Tomar foto con cámara'),
                                      onTap: () async {
                                        Navigator.pop(sheetCtx);
                                        final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                                        if (img != null) setModalState(() {
                                          selectedImageFile = img;
                                          photoRemoved = false;
                                        });
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo_library, color: AppColors.secondaryBase),
                                      title: const Text('Elegir de galería'),
                                      onTap: () async {
                                        Navigator.pop(sheetCtx);
                                        final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                                        if (img != null) setModalState(() {
                                          selectedImageFile = img;
                                          photoRemoved = false;
                                        });
                                      },
                                    ),
                                    if (selectedImageFile != null || (tieneFotoActual && !photoRemoved))
                                      ListTile(
                                        leading: const Icon(Icons.delete, color: AppColors.dangerBase),
                                        title: const Text('Quitar foto', style: TextStyle(color: AppColors.dangerBase)),
                                        onTap: () {
                                          Navigator.pop(sheetCtx);
                                          setModalState(() {
                                            selectedImageFile = null;
                                            photoRemoved = true;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: AppColors.contentBackground,
                              border: Border.all(
                                color: (selectedImageFile != null || (tieneFotoActual && !photoRemoved)) 
                                    ? AppColors.secondaryBase : Colors.grey.shade300,
                                width: (selectedImageFile != null || (tieneFotoActual && !photoRemoved)) ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  (selectedImageFile != null || (tieneFotoActual && !photoRemoved))
                                      ? Icons.check_circle_rounded
                                      : Icons.camera_alt_outlined,
                                  color: (selectedImageFile != null || (tieneFotoActual && !photoRemoved)) 
                                      ? AppColors.secondaryBase : Colors.grey,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  (selectedImageFile != null || (tieneFotoActual && !photoRemoved))
                                      ? (selectedImageFile != null ? 'Nueva foto seleccionada' : 'Foto actual mantenida')
                                      : 'Sin foto adjunta',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: (selectedImageFile != null || (tieneFotoActual && !photoRemoved)) 
                                        ? AppColors.secondaryBase : Colors.grey,
                                    fontWeight: (selectedImageFile != null || (tieneFotoActual && !photoRemoved)) 
                                        ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryBase, foregroundColor: Colors.white),
                    child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result == true) {
      _updateArticulo(
        articulo,
        nameController.text.trim(),
        descriptionController.text.trim(),
        selectedImageFile?.path,
        photoRemoved,
      );
    }
  }

  Future<void> _updateArticulo(
    Articulos articulo,
    String name,
    String description,
    String? imagePath,
    bool photoRemoved,
  ) async {
    if (articulo.id == null) return;
    setState(() => _isLoading = true);
    try {
      final updateData = Articulos(
        nombre: name,
        descripcion: description,
      );
      
      final success = await _articulosController.update(articulo.id!, updateData);
      
      if (success) {
        if (imagePath != null && _userId != null) {
          await _articulosController.uploadPhoto(articulo.id!, _userId!, imagePath);
        } else if (photoRemoved) {
          await _articulosController.deletePhoto(articulo.id!);
        }

        if (!mounted) return;
        AppToast.show(context, 'Artículo actualizado correctamente');
        _loadArticulos();
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        AppToast.show(context, 'No se pudo actualizar el artículo', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, 'Error: $e', isError: true);
      }
    }
  }

  Widget _buildAppBarBackground(Almacen warehouse) {
    warehouse = _currentWarehouse;
    return Container(
      color: Colors.white,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondaryBase.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.secondaryBase.withOpacity(0.15),
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getIconData(warehouse.icono),
                    color: AppColors.secondaryBase,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  warehouse.nombre ?? 'Almacén',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBase,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchController.text.isNotEmpty;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _showTrash
                    ? Icons.delete_forever_outlined
                    : (hasSearch
                          ? Icons.search_off_rounded
                          : Icons.inventory_2_outlined),
                size: 72,
                color: AppColors.secondaryBase.withOpacity(0.15),
              ),
              const SizedBox(height: 20),
              Text(
                _showTrash
                    ? 'Papelera vacía'
                    : (hasSearch ? 'Sin resultados' : 'Sin artículos'),
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBase.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _showTrash
                    ? 'No hay artículos eliminados en este almacén.'
                    : (hasSearch
                          ? 'No se encontraron artículos con ese criterio.'
                          : 'Este almacén aún no tiene artículos registrados.'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticuloCard(Articulos articulo) {
    final bool activo = articulo.estatus ?? true;
    final bool tieneImagen = articulo.foto != null && articulo.foto!.isNotEmpty;

    return Opacity(
      opacity: activo ? 1.0 : 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.withOpacity(0.08),
          ),
          boxShadow: [
            if (activo)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar / Imagen
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: tieneImagen
                    ? Image.network(
                        articulo.foto!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                      )
                    : _buildAvatarFallback(),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      articulo.nombre ?? 'Sin nombre',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBase,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (articulo.descripcion != null &&
                        articulo.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        articulo.descripcion!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              _buildPopupMenu(articulo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.secondaryBase.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: AppColors.secondaryBase,
          size: 24,
        ),
      ),
    );
  }
}
