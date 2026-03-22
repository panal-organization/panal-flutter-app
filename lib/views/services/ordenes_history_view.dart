import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../controllers/app_controllers.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_toast.dart';

class OrdenesHistoryView extends StatefulWidget {
  const OrdenesHistoryView({super.key});

  @override
  State<OrdenesHistoryView> createState() => _OrdenesHistoryViewState();
}

class _OrdenesHistoryViewState extends State<OrdenesHistoryView> {
  bool _isLoading = true;
  List<OrdenesServicio> _ordenes = [];
  List<TipoOrdenes> _tipos = [];

  String? _workspaceId;
  String _searchQuery = '';
  String _selectedStateFilter = 'TODOS';

  final OrdenesServicioController _ordenesController =
      OrdenesServicioController();
  final TipoOrdenesController _tiposController = TipoOrdenesController();
  final WorkspacesController _workspacesController = WorkspacesController();

  String? _currentUserId;
  bool _isOwner = false;

  final List<Map<String, dynamic>> _statusEnum = [
    {'id': 'PENDIENTE', 'label': 'PENDIENTE', 'color': Colors.orange},
    {
      'id': 'EN_PROGRESO',
      'label': 'EN PROGRESO',
      'color': AppColors.secondaryBase,
    },
    {'id': 'RESUELTO', 'label': 'RESUELTO', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _workspaceId = prefs.getString('selected_workspace_id');

      if (_workspaceId != null) {
        _currentUserId = prefs.getString('user_id');

        final responses = await Future.wait([
          _ordenesController.getByWorkspace(_workspaceId!),
          _tiposController.getAll(),
          _workspacesController.getOne(_workspaceId!),
        ]);

        if (mounted) {
          setState(() {
            _ordenes = responses[0] as List<OrdenesServicio>;
            _tipos = responses[1] as List<TipoOrdenes>;
            final ws = responses[2] as Workspaces?;
            if (ws != null && _currentUserId != null) {
              _isOwner = ws.adminId == _currentUserId;
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, 'Error al cargar historial', isError: true);
      }
    }
  }

  Future<void> _refreshData() async {
    if (_workspaceId == null) return;
    try {
      final list = await _ordenesController.getByWorkspace(_workspaceId!);
      if (mounted) setState(() => _ordenes = list);
    } catch (e) {
      debugPrint('Error updating: $e');
    }
  }

  Future<void> _updateStatus(OrdenesServicio orden, String newState) async {
    if (orden.estado == newState) return;

    setState(() => _isLoading = true);
    try {
      // Usamos el método update enviando el modelo con el nuevo estado
      final updatedOrden = OrdenesServicio(
        id: orden.id, // Importante mantener el ID
        estado: newState,
        descripcion: orden.descripcion,
        articuloId: orden.articuloId,
        tipoId: orden.tipoId,
        workspaceId: orden.workspaceId,
        createdBy: orden.createdBy,
        foto: orden.foto,
      );

      final success = await _ordenesController.update(orden.id!, updatedOrden);
      if (success) {
        await _refreshData();
        if (mounted)
          AppToast.show(
            context,
            'Estado actualizado a ${_friendlyStateName(newState)}',
          );
      } else {
        if (mounted)
          AppToast.show(
            context,
            'No se pudo actualizar el estado',
            isError: true,
          );
      }
    } catch (e) {
      if (mounted) AppToast.show(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyStateName(String? state) {
    if (state == 'EN_PROGRESO') return 'EN PROGRESO';
    return state ?? 'PENDIENTE';
  }

  List<OrdenesServicio> get _filteredOrdenes {
    var list = _ordenes.where((o) => !(o.isDeleted ?? false)).toList();

    if (_selectedStateFilter != 'TODOS') {
      list = list.where((o) => o.estado == _selectedStateFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list
          .where((o) => (o.descripcion?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    // Sort by most recent
    list.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.contentBackground,
      appBar: AppBar(
        title: const Text(
          'Historial de Órdenes',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppColors.textBase,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textBase,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: AppColors.secondaryBase,
              child: _isLoading && _ordenes.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondaryBase,
                      ),
                    )
                  : _filteredOrdenes.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      itemCount: _filteredOrdenes.length,
                      itemBuilder: (context, index) =>
                          _buildOrdenCard(_filteredOrdenes[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              cursorColor: AppColors.secondaryBase,
              decoration: InputDecoration(
                hintText: 'Buscar órdenes...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.contentBackground,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.secondaryBase,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['TODOS', 'PENDIENTE', 'EN_PROGRESO', 'RESUELTO'].map((
                state,
              ) {
                final isSelected = _selectedStateFilter == state;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      _friendlyStateName(state),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) =>
                        setState(() => _selectedStateFilter = state),
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: AppColors.secondaryBase,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide.none,
                    ),
                    elevation: 0,
                    pressElevation: 0,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildOrdenCard(OrdenesServicio orden) {
    final statusData = _statusEnum.firstWhere(
      (s) => s['id'] == (orden.estado ?? 'PENDIENTE'),
      orElse: () => _statusEnum[0],
    );
    final Color statusColor = statusData['color'];

    // Verificamos si los IDs existen antes de buscar
    final tipo = _tipos.firstWhere(
      (t) => t.id == orden.tipoId,
      orElse: () => TipoOrdenes(nombre: 'Otro'),
    );
    final articuloName = orden.articulo?.nombre ?? 'Desconocido';
    final hasImage = orden.foto != null && orden.foto!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(orden),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBase.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: hasImage
                          ? Image.network(
                              orden.foto!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.assignment_rounded,
                                color: AppColors.secondaryBase,
                              ),
                            )
                          : const Icon(
                              Icons.assignment_rounded,
                              color: AppColors.secondaryBase,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tipo.nombre ?? 'General',
                              style: TextStyle(
                                color: AppColors.secondaryBase,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _friendlyStateName(orden.estado),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          articuloName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textBase,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          orden.descripcion ?? 'Sin descripción',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(orden.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(OrdenesServicio orden) {
    final statusData = _statusEnum.firstWhere(
      (s) => s['id'] == (orden.estado ?? 'PENDIENTE'),
      orElse: () => _statusEnum[0],
    );
    final tipo = _tipos.firstWhere(
      (t) => t.id == orden.tipoId,
      orElse: () => TipoOrdenes(nombre: 'No definido'),
    );
    final articuloName = orden.articulo?.nombre ?? 'No definido';

    final creatorName = orden.creator?.nombre ?? 'Usuario Desconocido';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Detalle de la Orden',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBase,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showStatusChangeSheet(orden),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (statusData['color'] as Color).withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _friendlyStateName(orden.estado),
                                  style: TextStyle(
                                    color: statusData['color'],
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.edit_rounded,
                                  size: 12,
                                  color: statusData['color'],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (orden.foto != null && orden.foto!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          orden.foto!,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    const SizedBox(height: 24),
                    _buildDetailItem(
                      'DESCRIPCIÓN',
                      orden.descripcion ?? 'Sin descripción',
                      Icons.notes_rounded,
                    ),
                    const SizedBox(height: 24),
                    _buildDetailItem(
                      'EQUIPO / ARTÍCULO',
                      articuloName,
                      Icons.inventory_2_rounded,
                    ),
                    const SizedBox(height: 24),
                    _buildDetailItem(
                      'TIPO DE ORDEN',
                      tipo.nombre ?? 'N/A',
                      Icons.assignment_rounded,
                    ),
                    const SizedBox(height: 24),
                    _buildDetailItem(
                      'REPORTADO POR',
                      creatorName,
                      Icons.person_rounded,
                    ),
                    const SizedBox(height: 24),
                    _buildDetailItem(
                      'FECHA DE CREACIÓN',
                      _formatDate(orden.createdAt),
                      Icons.calendar_today_rounded,
                    ),
                    const SizedBox(height: 40),
                    if (_isOwner) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditOrderSheet(orden);
                          },
                          icon: const Icon(
                            Icons.edit_note_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'EDITAR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryBase,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textBase,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'CERRAR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBase,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showStatusChangeSheet(OrdenesServicio orden) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Actualizar Estado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ..._statusEnum.map((s) {
                final isCurrent = s['id'] == (orden.estado ?? 'PENDIENTE');
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? s['color'].withOpacity(0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrent
                          ? s['color'].withOpacity(0.5)
                          : Colors.grey.withOpacity(0.1),
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.circle, color: s['color'], size: 16),
                    title: Text(
                      s['label'],
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrent ? s['color'] : AppColors.textBase,
                      ),
                    ),
                    trailing: isCurrent
                        ? Icon(Icons.check_circle, color: s['color'])
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _updateStatus(orden, s['id']);
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditOrderSheet(OrdenesServicio orden) {
    final TextEditingController descController = TextEditingController(
      text: orden.descripcion,
    );
    String? tempTipoId = orden.tipoId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Editar Orden',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBase,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'DESCRIPCIÓN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Escribe la nueva descripción...',
                    filled: true,
                    fillColor: AppColors.contentBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'TIPO DE ORDEN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tipos.length,
                    itemBuilder: (context, index) {
                      final t = _tipos[index];
                      final isSelected = tempTipoId == t.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setModalState(() => tempTipoId = t.id),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.secondaryBase
                                  : AppColors.contentBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.secondaryBase
                                    : Colors.transparent,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              t.nombre ?? '',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textBase,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      final newDesc = descController.text.trim();
                      if (newDesc.isEmpty) return;

                      Navigator.pop(context);
                      setState(() => _isLoading = true);

                      try {
                        final updated = OrdenesServicio(
                          id: orden.id,
                          descripcion: newDesc,
                          estado: orden.estado,
                          articuloId: orden.articuloId,
                          tipoId: tempTipoId,
                          workspaceId: orden.workspaceId,
                          createdBy: orden.createdBy,
                          foto: orden.foto,
                        );

                        final success = await _ordenesController.update(
                          orden.id!,
                          updated,
                        );
                        if (success) {
                          await _refreshData();
                          if (mounted)
                            AppToast.show(
                              context,
                              'Orden actualizada correctamente',
                            );
                        } else {
                          if (mounted)
                            AppToast.show(
                              context,
                              'No se pudo actualizar la orden',
                              isError: true,
                            );
                        }
                      } catch (e) {
                        if (mounted)
                          AppToast.show(context, 'Error: $e', isError: true);
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryBase,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'GUARDAR CAMBIOS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (_) {
      return '';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 80,
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sin historial de órdenes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Las órdenes que crees aparecerán aquí.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
