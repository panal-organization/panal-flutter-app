import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../controllers/app_controllers.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_toast.dart';

class TicketsTab extends StatefulWidget {
  const TicketsTab({super.key});

  @override
  State<TicketsTab> createState() => _TicketsTabState();
}

class _TicketsTabState extends State<TicketsTab> {
  bool _isLoading = true;
  List<Tickets> _tickets = [];
  String? _workspaceId;
  String? _userId;
  final ImagePicker _picker = ImagePicker();
  String _searchQuery = '';
  String _selectedStateFilter = 'TODOS';
  bool _isPremium = true; // default until prefs loaded

  static const String _premiumPlanId = '69a3df3381a5be4cb1bd8bc3';
  static const int _freeDailyTicketLimit = 10;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      _workspaceId = prefs.getString('selected_workspace_id');
      _userId = prefs.getString('user_id');
      final planId = prefs.getString('workspace_plan_id');
      _isPremium = planId == _premiumPlanId || planId == null;

      if (_workspaceId != null) {
        final ticketsController = TicketsController();
        final ticketsResp = await ticketsController.getByWorkspace(
          _workspaceId!,
        );
        setState(() {
          _tickets = ticketsResp;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar tickets: $e')));
      }
    }
  }

  Future<void> _deleteTicket(Tickets ticket) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar Ticket',
          style: TextStyle(color: AppColors.textBase),
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este ticket?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerBase,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final controller = TicketsController();
      final updateData = Tickets(isDeleted: true);
      final ok = await controller.update(ticket.id!, updateData);
      if (ok) {
        _loadTickets();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el ticket')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _showPhotoOptions(BuildContext context, Tickets ticket) async {
    final hasPhoto = ticket.foto != null && ticket.foto!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.secondaryBase,
              ),
              title: const Text('Tomar foto con cámara'),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcessImage(
                  ticket.id!,
                  ImageSource.camera,
                  isUpdate: hasPhoto,
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.secondaryBase,
              ),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _pickAndProcessImage(
                  ticket.id!,
                  ImageSource.gallery,
                  isUpdate: hasPhoto,
                );
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.dangerBase),
                title: const Text(
                  'Eliminar foto',
                  style: TextStyle(color: AppColors.dangerBase),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteImage(ticket.id!);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndProcessImage(
    String ticketId,
    ImageSource source, {
    bool isUpdate = false,
  }) async {
    if (_userId == null) {
      AppToast.show(context, "Error: Sesión no válida", isError: true);
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image == null) return;

      if (!mounted) return;
      AppToast.show(
        context,
        isUpdate ? "Actualizando imagen..." : "Subiendo imagen...",
      );

      final controller = TicketsController();
      final success = await controller.uploadPhoto(
        ticketId,
        _userId!,
        image.path,
      );

      if (!mounted) return;
      if (success) {
        AppToast.show(
          context,
          isUpdate
              ? "Imagen actualizada correctamente"
              : "Imagen subida correctamente",
        );
        _loadTickets(); // Reload tickets to show the image
      } else {
        AppToast.show(
          context,
          isUpdate
              ? "Error al actualizar la imagen"
              : "Error al subir la imagen",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, "Error: $e", isError: true);
    }
  }

  Future<void> _deleteImage(String ticketId) async {
    try {
      AppToast.show(context, "Eliminando imagen...");
      final controller = TicketsController();
      final success = await controller.deletePhoto(ticketId);
      if (!mounted) return;
      if (success) {
        AppToast.show(context, "Imagen eliminada");
        _loadTickets();
      } else {
        AppToast.show(context, "Error al eliminar la imagen", isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, "Error: $e", isError: true);
    }
  }

  Future<void> _showChangeStateDialog(Tickets ticket) async {
    String newState = ticket.estado ?? 'PENDIENTE';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.secondaryBase,
            ),
            primaryColor: AppColors.secondaryBase,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.white,
                title: const Text(
                  'Cambiar Estado',
                  style: TextStyle(
                    color: AppColors.textBase,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                content: DropdownButtonFormField<String>(
                  value: newState,
                  decoration: InputDecoration(
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
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'PENDIENTE',
                      child: Text('Pendiente'),
                    ),
                    DropdownMenuItem(
                      value: 'EN_PROGRESO',
                      child: Text('En Progreso'),
                    ),
                    DropdownMenuItem(
                      value: 'RESUELTO',
                      child: Text('Resuelto'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => newState = val);
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, newState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryBase,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Guardar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result != null && result != ticket.estado) {
      try {
        final controller = TicketsController();
        // Cargar ticket existente primero para no sobreescribir nulos
        final updateData = Tickets(estado: result);
        final ok = await controller.update(ticket.id!, updateData);
        if (ok) {
          _loadTickets();
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo cambiar el estado')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showEditDialog(Tickets ticket) async {
    final titleController = TextEditingController(text: ticket.titulo);
    final descController = TextEditingController(text: ticket.descripcion);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.secondaryBase,
            ),
            primaryColor: AppColors.secondaryBase,
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: AppColors.secondaryBase,
              selectionColor: AppColors.secondaryBg,
              selectionHandleColor: AppColors.secondaryBase,
            ),
          ),
          child: AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Editar Ticket',
              style: TextStyle(
                color: AppColors.textBase,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Título del problema',
                        labelStyle: const TextStyle(fontSize: 14),
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
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Descripción detallada',
                        labelStyle: const TextStyle(fontSize: 14),
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty &&
                      descController.text.trim().isNotEmpty) {
                    Navigator.pop(ctx, {
                      'titulo': titleController.text.trim(),
                      'descripcion': descController.text.trim(),
                    });
                  } else {
                    AppToast.show(
                      ctx,
                      "Debes llenar título y descripción",
                      isError: true,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryBase,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Guardar Cambios',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final controller = TicketsController();
        final updateData = Tickets(
          titulo: result['titulo'],
          descripcion: result['descripcion'],
        );

        final ok = await controller.update(ticket.id!, updateData);
        if (ok) {
          AppToast.show(context, "Ticket actualizado correctamente");
          _loadTickets();
        } else {
          if (!mounted) return;
          setState(() => _isLoading = false);
          AppToast.show(
            context,
            "No se pudo actualizar el ticket",
            isError: true,
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        AppToast.show(context, "Error: $e", isError: true);
      }
    }
  }

  Future<void> _showCreateDialog() async {
    // Free plan: enforce daily ticket limit
    if (!_isPremium) {
      final today = DateTime.now();
      final todayTickets = _tickets.where((t) {
        if (t.isDeleted == true) return false;
        if (t.createdAt == null) return false;
        final dt = DateTime.tryParse(t.createdAt!);
        if (dt == null) return false;
        final local = dt.toLocal();
        return local.year == today.year &&
            local.month == today.month &&
            local.day == today.day;
      }).length;

      if (todayTickets >= _freeDailyTicketLimit) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.star_rounded, color: AppColors.warningBase, size: 22),
                SizedBox(width: 8),
                Text(
                  'Límite del día alcanzado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBase,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: Text(
              'Con el plan gratuito puedes crear hasta $_freeDailyTicketLimit tickets por día.\n\nHas creado $todayTickets tickets hoy. Activa Premium para tickets ilimitados.',
              style: const TextStyle(color: Colors.grey, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final upgradeUrl = Uri.parse('http://localhost:5173/panal-web-application/pricing');
                  if (await canLaunchUrl(upgradeUrl)) {
                    await launchUrl(upgradeUrl, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 16, color: Colors.white),
                label: const Text(
                  'Ver Premium',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warningBase,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
        return;
      }
    }

    final titleController = TextEditingController();
    final descController = TextEditingController();
    String priorityValue = 'MEDIA';
    String categoryValue = 'SOPORTE';
    XFile? selectedImage;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.secondaryBase,
            ),
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
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  'Nuevo Ticket',
                  style: TextStyle(
                    color: AppColors.textBase,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Título del problema',
                            labelStyle: const TextStyle(fontSize: 14),
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
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Descripción detallada',
                            labelStyle: const TextStyle(fontSize: 14),
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
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: priorityValue,
                                decoration: InputDecoration(
                                  labelText: 'Prioridad',
                                  labelStyle: const TextStyle(fontSize: 14),
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
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'BAJA',
                                    child: Text(
                                      'BAJA (-)',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'MEDIA',
                                    child: Text(
                                      'MEDIA (!)',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ALTA',
                                    child: Text(
                                      'ALTA (!!)',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'CRITICA',
                                    child: Text(
                                      'CRÍTICA (!!!)',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null)
                                    setModalState(() => priorityValue = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: categoryValue,
                                decoration: InputDecoration(
                                  labelText: 'Categoría',
                                  labelStyle: const TextStyle(fontSize: 14),
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
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'BUG',
                                    child: Text(
                                      'Error / Bug',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'SOPORTE',
                                    child: Text(
                                      'Soporte',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'MEJORA',
                                    child: Text(
                                      'Mejora',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'MANTENIMIENTO',
                                    child: Text(
                                      'Mantenimiento',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null)
                                    setModalState(() => categoryValue = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Image Picker Section
                        GestureDetector(
                          onTap: () async {
                            showModalBottomSheet(
                              context: ctx,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (sheetCtx) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(
                                        Icons.camera_alt,
                                        color: AppColors.secondaryBase,
                                      ),
                                      title: const Text(
                                        'Tomar foto con cámara',
                                      ),
                                      onTap: () async {
                                        Navigator.pop(sheetCtx);
                                        final img = await _picker.pickImage(
                                          source: ImageSource.camera,
                                          imageQuality: 70,
                                        );
                                        if (img != null)
                                          setModalState(
                                            () => selectedImage = img,
                                          );
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(
                                        Icons.photo_library,
                                        color: AppColors.secondaryBase,
                                      ),
                                      title: const Text('Elegir de galería'),
                                      onTap: () async {
                                        Navigator.pop(sheetCtx);
                                        final img = await _picker.pickImage(
                                          source: ImageSource.gallery,
                                          imageQuality: 70,
                                        );
                                        if (img != null)
                                          setModalState(
                                            () => selectedImage = img,
                                          );
                                      },
                                    ),
                                    if (selectedImage != null)
                                      ListTile(
                                        leading: const Icon(
                                          Icons.delete,
                                          color: AppColors.dangerBase,
                                        ),
                                        title: const Text(
                                          'Quitar foto seleccionada',
                                          style: TextStyle(
                                            color: AppColors.dangerBase,
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.pop(sheetCtx);
                                          setModalState(
                                            () => selectedImage = null,
                                          );
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
                                color: selectedImage != null
                                    ? AppColors.secondaryBase
                                    : Colors.grey.shade300,
                                width: selectedImage != null ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  selectedImage != null
                                      ? Icons.check_circle
                                      : Icons.camera_alt_outlined,
                                  color: selectedImage != null
                                      ? AppColors.secondaryBase
                                      : Colors.grey,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  selectedImage != null
                                      ? 'Foto adjuntada (clic para cambiar)'
                                      : 'Adjuntar foto (opcional)',
                                  style: TextStyle(
                                    color: selectedImage != null
                                        ? AppColors.secondaryBase
                                        : Colors.grey,
                                    fontWeight: selectedImage != null
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
                    onPressed: () => Navigator.pop(ctx, null),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (titleController.text.trim().isNotEmpty &&
                          descController.text.trim().isNotEmpty) {
                        Navigator.pop(ctx, {
                          'titulo': titleController.text.trim(),
                          'descripcion': descController.text.trim(),
                          'prioridad': priorityValue,
                          'categoria': categoryValue,
                          'image_path': selectedImage?.path,
                        });
                      } else {
                        AppToast.show(
                          ctx,
                          "Debes llenar título y descripción",
                          isError: true,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryBase,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Crear Ticket',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final controller = TicketsController();
        String? finalPhotoUrl;

        // Si el usuario adjuntó una foto, primero la subimos
        if (result['image_path'] != null && _userId != null) {
          AppToast.show(context, "Subiendo foto...");
          final url = await controller.uploadPhotoOnly(
            _userId!,
            result['image_path'],
          );
          if (url != null) {
            finalPhotoUrl = url;
          }
        }

        final newTicket = Tickets(
          titulo: result['titulo'],
          descripcion: result['descripcion'],
          estado: 'PENDIENTE',
          prioridad: result['prioridad'],
          categoria: result['categoria'],
          workspaceId: _workspaceId,
          createdBy: _userId,
          foto:
              finalPhotoUrl, // Asignamos la url que generó el backend de manera nativa
        );

        final ok = await controller.create(newTicket);
        if (ok) {
          AppToast.show(context, "Ticket creado correctamente");
          _loadTickets(); // recargar
        } else {
          if (!mounted) return;
          setState(() => _isLoading = false);
          AppToast.show(context, "No se pudo crear el ticket", isError: true);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        AppToast.show(context, "Error: $e", isError: true);
      }
    }
  }

  Map<String, List<Tickets>> _groupTickets() {
    Map<String, List<Tickets>> map = {
      'PENDIENTE': [],
      'EN_PROGRESO': [],
      'RESUELTO': [],
    };
    for (var t in _tickets) {
      if (t.isDeleted == true) continue;

      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final title = (t.titulo ?? '').toLowerCase();
        final desc = (t.descripcion ?? '').toLowerCase();

        if (!title.contains(query) && !desc.contains(query)) {
          continue;
        }
      }

      final state = t.estado ?? 'PENDIENTE';
      if (_selectedStateFilter != 'TODOS' && state != _selectedStateFilter) {
        continue;
      }
      if (!map.containsKey(state)) {
        map[state] = [];
      }
      map[state]!.add(t);
    }

    map.forEach((key, list) {
      list.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        final dA = DateTime.tryParse(a.createdAt!) ?? DateTime.now();
        final dB = DateTime.tryParse(b.createdAt!) ?? DateTime.now();
        return dB.compareTo(dA); // Newest first
      });
    });

    return map;
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    switch (status) {
      case 'PENDIENTE':
        bg = AppColors.dangerBg;
        text = AppColors.dangerBase;
        break;
      case 'EN_PROGRESO':
        bg = AppColors.warningBg;
        text = AppColors.warningBase;
        break;
      case 'RESUELTO':
        bg = AppColors.successBg;
        text = AppColors.successBase;
        break;
      default:
        bg = AppColors.textBg;
        text = AppColors.textBase;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color bg;
    Color text;
    switch (priority) {
      case 'BAJA':
        bg = AppColors.infoBg;
        text = AppColors.infoBase;
        break;
      case 'MEDIA':
        bg = AppColors.secondaryBg;
        text = AppColors.secondaryBase;
        break;
      case 'ALTA':
        bg = AppColors.warningBg;
        text = AppColors.warningBase;
        break;
      case 'CRITICA':
        bg = AppColors.dangerBg;
        text = AppColors.dangerBase;
        break;
      default:
        bg = AppColors.textBg;
        text = AppColors.textBase;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            priority,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.category_outlined, size: 12, color: Colors.blueGrey),
          const SizedBox(width: 4),
          Text(
            category,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(Tickets t) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      onSelected: (val) {
        if (val == 0) _showChangeStateDialog(t);
        if (val == 1) _showEditDialog(t);
        if (val == 2) _deleteTicket(t);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.sync_alt, color: AppColors.secondaryBase, size: 18),
              SizedBox(width: 8),
              Text(
                'Cambiar estado',
                style: TextStyle(fontSize: 14, color: AppColors.textBase),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: AppColors.secondaryBase,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Editar ticket',
                style: TextStyle(fontSize: 14, color: AppColors.textBase),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: AppColors.dangerBase, size: 18),
              SizedBox(width: 8),
              Text(
                'Eliminar ticket',
                style: TextStyle(fontSize: 14, color: AppColors.dangerBase),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoWidget(Tickets t) {
    if (t.foto != null && t.foto!.isNotEmpty) {
      String imgUrl = t.foto!;
      if (!imgUrl.startsWith('http')) {
        imgUrl = '${ApiController.baseUrl}/$imgUrl';
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          imgUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildGenericPhoto(),
        ),
      );
    }
    return _buildGenericPhoto();
  }

  Widget _buildGenericPhoto() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.secondaryBg.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.confirmation_number_outlined,
        color: AppColors.secondaryBase,
        size: 24,
      ),
    );
  }

  Widget _buildTicketCard(Tickets t, int index) {
    String dateStr = '';
    String editedStr = '';
    if (t.createdAt != null) {
      final dt = DateTime.tryParse(t.createdAt!);
      if (dt != null) {
        dateStr = DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
      }
    }
    if (t.createdAt != null && t.updatedAt != null) {
      final dtCr = DateTime.tryParse(t.createdAt!);
      final dtUp = DateTime.tryParse(t.updatedAt!);
      if (dtCr != null &&
          dtUp != null &&
          dtUp.difference(dtCr).inMinutes.abs() > 0) {
        editedStr =
            'Editado: ${DateFormat('dd/MM HH:mm').format(dtUp.toLocal())}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _showTicketDetail(t);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila Superior: Badge estado, fecha y menú
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#$index',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(t.estado ?? 'PENDIENTE'),
                      ],
                    ),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            if (editedStr.isNotEmpty)
                              Text(
                                editedStr,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        _buildPopupMenu(t),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Centro: Foto, Título y Descripción
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoWidget(t),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.titulo ?? 'Sin Título',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBase,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.descripcion ?? 'Sin descripción',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Fila inferior: Wrap para evitar overflow de Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPriorityBadge(t.prioridad ?? 'MEDIA'),
                    _buildCategoryBadge(t.categoria ?? 'SOPORTE'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTicketDetail(Tickets t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        String dateStr = '';
        String editedStr = '';
        if (t.createdAt != null) {
          final dt = DateTime.tryParse(t.createdAt!);
          if (dt != null) {
            dateStr = DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
          }
        }
        if (t.createdAt != null && t.updatedAt != null) {
          final dtCr = DateTime.tryParse(t.createdAt!);
          final dtUp = DateTime.tryParse(t.updatedAt!);
          if (dtCr != null &&
              dtUp != null &&
              dtUp.difference(dtCr).inMinutes.abs() > 0) {
            editedStr =
                'Editado: ${DateFormat('dd/MM/yyyy HH:mm').format(dtUp.toLocal())}';
          }
        }
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      t.titulo ?? 'Ticket Abierto',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBase,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [_buildStatusBadge(t.estado ?? 'PENDIENTE')],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPriorityBadge(t.prioridad ?? 'MEDIA'),
                  _buildCategoryBadge(t.categoria ?? 'SOPORTE'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (editedStr.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_note,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            editedStr,
                            style: const TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  if (t.foto != null && t.foto!.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        final url = t.foto!.startsWith('http')
                            ? t.foto!
                            : '${ApiController.baseUrl}/${t.foto!}';
                        _showFullScreenImage(url);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          t.foto!.startsWith('http')
                              ? t.foto!
                              : '${ApiController.baseUrl}/${t.foto!}',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildGenericPhotoExpanded(),
                        ),
                      ),
                    )
                  else
                    _buildGenericPhotoExpanded(),

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showPhotoOptions(context, t);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryBase,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Descripción del Problema',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBase,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.contentBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  t.descripcion ?? 'Sin descripción',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textBase,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryBase,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cerrar Módulo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenericPhotoExpanded() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.contentBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: Icon(Icons.support_agent, color: Colors.grey, size: 54),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondaryBase),
      );
    }

    if (_workspaceId == null) {
      return const Center(child: Text('Ningún espacio seleccionado.'));
    }

    final groups = _groupTickets();
    final hasTickets = groups.values.any((list) => list.isNotEmpty);
    final hasAnyTickets = _tickets.any((t) => t.isDeleted != true);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          if (hasAnyTickets)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.secondaryBase,
                      ),
                      primaryColor: AppColors.secondaryBase,
                      textSelectionTheme: const TextSelectionThemeData(
                        cursorColor: AppColors.secondaryBase,
                        selectionColor: AppColors.secondaryBg,
                        selectionHandleColor: AppColors.secondaryBase,
                      ),
                    ),
                    child: TextField(
                      cursorColor: AppColors.secondaryBase,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar tickets...',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.secondaryBase,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('TODOS', 'Todos'),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'PENDIENTE',
                          'Pendientes',
                          color: AppColors.dangerBase,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'EN_PROGRESO',
                          'En Progreso',
                          color: AppColors.warningBase,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'RESUELTO',
                          'Resueltos',
                          color: AppColors.successBase,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: hasTickets
                ? ListView(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 80,
                    ),
                    children: [
                      if (groups['PENDIENTE']!.isNotEmpty) ...[
                        _buildSectionTitle(
                          'Pendientes',
                          groups['PENDIENTE']!.length,
                        ),
                        ...groups['PENDIENTE']!.asMap().entries.map(
                          (e) => _buildTicketCard(
                            e.value,
                            groups['PENDIENTE']!.length - e.key,
                          ),
                        ),
                      ],
                      if (groups['EN_PROGRESO']!.isNotEmpty) ...[
                        _buildSectionTitle(
                          'En Progreso',
                          groups['EN_PROGRESO']!.length,
                        ),
                        ...groups['EN_PROGRESO']!.asMap().entries.map(
                          (e) => _buildTicketCard(
                            e.value,
                            groups['EN_PROGRESO']!.length - e.key,
                          ),
                        ),
                      ],
                      if (groups['RESUELTO']!.isNotEmpty) ...[
                        _buildSectionTitle(
                          'Resuelto',
                          groups['RESUELTO']!.length,
                        ),
                        ...groups['RESUELTO']!.asMap().entries.map(
                          (e) => _buildTicketCard(
                            e.value,
                            groups['RESUELTO']!.length - e.key,
                          ),
                        ),
                      ],
                    ],
                  )
                : const Center(
                    child: Text(
                      'No se encontraron tickets.',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 40,
        child: FloatingActionButton.extended(
          onPressed: _showCreateDialog,
          backgroundColor: AppColors.secondaryBase,
          elevation: 2,
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: const Text(
            'Nuevo Ticket',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBase,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.secondaryBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: AppColors.secondaryBase,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, {Color? color}) {
    final isSelected = _selectedStateFilter == value;
    final activeColor = color ?? AppColors.secondaryBase;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStateFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
