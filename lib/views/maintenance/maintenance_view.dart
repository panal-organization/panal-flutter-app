import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import '../../controllers/app_controllers.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_toast.dart';

class MaintenanceView extends StatefulWidget {
  const MaintenanceView({super.key});

  @override
  State<MaintenanceView> createState() => _MaintenanceViewState();
}

class _MaintenanceViewState extends State<MaintenanceView> {
  bool _isLoading = true;
  List<OrdenesServicio> _maintOrdenes = [];
  List<TipoOrdenes> _tipos = [];
  String? _workspaceId;
  String? _currentUserId;
  bool _isOwner = false;

  final OrdenesServicioController _ordenesController = OrdenesServicioController();
  final TipoOrdenesController _tiposController = TipoOrdenesController();
  final WorkspacesController _workspacesController = WorkspacesController();

  final List<Map<String, dynamic>> _statusEnum = [
    {'id': 'PENDIENTE', 'label': 'PENDIENTE', 'color': Colors.orange},
    {'id': 'EN_PROGRESO', 'label': 'EN PROGRESO', 'color': AppColors.secondaryBase},
    {'id': 'RESUELTO', 'label': 'RESUELTO', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _workspaceId = prefs.getString('selected_workspace_id');
      _currentUserId = prefs.getString('user_id');

      if (_workspaceId != null) {
        final responses = await Future.wait([
          _ordenesController.getByWorkspace(_workspaceId!),
          _tiposController.getAll(),
          _workspacesController.getOne(_workspaceId!),
        ]);

        final allOrdenes = responses[0] as List<OrdenesServicio>;
        _tipos = responses[1] as List<TipoOrdenes>;
        final ws = responses[2] as Workspaces?;

        if (ws != null && _currentUserId != null) {
          _isOwner = ws.adminId == _currentUserId;
        }

        // Ordenar y filtrar
        final maintTipo = _tipos.firstWhere(
          (t) => t.nombre?.toUpperCase() == 'MANTENIMIENTO',
          orElse: () => TipoOrdenes(id: 'none'),
        );

        if (mounted) {
          setState(() {
            _maintOrdenes = allOrdenes.where((o) {
              final isMaint = o.tipoId == maintTipo.id;
              final isPendingOrInProgress = o.estado == 'PENDIENTE' || o.estado == 'EN_PROGRESO';
              return isMaint && isPendingOrInProgress;
            }).toList();
            _maintOrdenes.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, 'Error al cargar mantenimiento', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.secondaryBase));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'ORDENES DE MANTENIMIENTO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade600,
              letterSpacing: 1.2
            ),
          ),
        ),
        Expanded(
          child: _maintOrdenes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.secondaryBase,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: _maintOrdenes.length,
                    itemBuilder: (context, index) => _buildMaintCard(_maintOrdenes[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMaintCard(OrdenesServicio orden) {
    final statusData = _statusEnum.firstWhere(
      (s) => s['id'] == (orden.estado ?? 'PENDIENTE'),
      orElse: () => _statusEnum[0],
    );
    final hasImage = orden.foto != null && orden.foto!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(orden),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: AppColors.secondaryBase.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: hasImage
                    ? Image.network(orden.foto!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.engineering_rounded, color: AppColors.secondaryBase))
                    : const Icon(Icons.engineering_rounded, color: AppColors.secondaryBase),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orden.articulo?.nombre ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textBase),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      orden.descripcion ?? 'Sin descripción',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    GestureDetector(
                      onTap: () => _updateStatusStep(orden),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: (statusData['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _friendlyStateName(orden.estado),
                              style: TextStyle(color: statusData['color'], fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit_rounded, size: 10, color: statusData['color']),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(OrdenesServicio orden) {
    final statusData = _statusEnum.firstWhere((s) => s['id'] == (orden.estado ?? 'PENDIENTE'), orElse: () => _statusEnum[0]);
    final articuloName = orden.articulo?.nombre ?? 'No definido';
    final creatorName = orden.creator?.nombre ?? 'Usuario Desconocido';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
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
                        const Text('Detalle de Mantenimiento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textBase)),
                        GestureDetector(
                          onTap: () => _updateStatusStep(orden),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: (statusData['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                Text(_friendlyStateName(orden.estado), style: TextStyle(color: statusData['color'], fontWeight: FontWeight.w900, fontSize: 11)),
                                const SizedBox(width: 6),
                                Icon(Icons.edit_rounded, size: 12, color: statusData['color']),
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
                        child: Image.network(orden.foto!, width: double.infinity, height: 250, fit: BoxFit.cover, errorBuilder: (_,__,___) => const SizedBox.shrink()),
                      ),
                    const SizedBox(height: 24),
                    _buildDetailItem('EQUIPO / ARTÍCULO', articuloName, Icons.inventory_2_rounded),
                    const SizedBox(height: 24),
                    _buildDetailItem('DESCRIPCIÓN TÉCNICA', orden.descripcion ?? 'Sin descripción', Icons.notes_rounded),
                    const SizedBox(height: 24),
                    _buildDetailItem('SOLICITADO POR', creatorName, Icons.person_rounded),
                    const SizedBox(height: 24),
                    _buildDetailItem('FECHA DE REPORTE', _formatDate(orden.createdAt), Icons.calendar_today_rounded),
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
                          icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                          label: const Text('EDITAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryBase, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.textBase, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: const Text('CERRAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateStatusStep(OrdenesServicio orden) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Actualizar Estado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ..._statusEnum.map((s) {
                final isCurrent = s['id'] == (orden.estado ?? 'PENDIENTE');
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(orden, s['id']);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCurrent ? s['color'].withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isCurrent ? s['color'].withOpacity(0.5) : Colors.grey.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: s['color'], size: 16),
                        const SizedBox(width: 12),
                        Text(s['label'], style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCurrent ? s['color'] : AppColors.textBase)),
                        const Spacer(),
                        if (isCurrent) Icon(Icons.check_circle, color: s['color']),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(OrdenesServicio orden, String newState) async {
    if (newState == orden.estado) return;
    
    setState(() => _isLoading = true);
    try {
      final updated = OrdenesServicio(
        id: orden.id,
        descripcion: orden.descripcion,
        estado: newState,
        articuloId: orden.articuloId,
        tipoId: orden.tipoId,
        workspaceId: orden.workspaceId,
        createdBy: orden.createdBy,
        foto: orden.foto,
      );

      final success = await _ordenesController.update(orden.id!, updated);
      if (success) {
        await _loadData();
        if (mounted) AppToast.show(context, 'Estado actualizado correctamente');
      } else {
        if (mounted) AppToast.show(context, 'No se pudo actualizar el estado', isError: true);
      }
    } catch (e) {
      if (mounted) AppToast.show(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditOrderSheet(OrdenesServicio orden) {
    final TextEditingController descController = TextEditingController(text: orden.descripcion);
    String? tempTipoId = orden.tipoId;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Editar Orden', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textBase)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded))
                  ],
                ),
                const SizedBox(height: 16),
                const Text('DESCRIPCIÓN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Escribe la nueva descripción...',
                    filled: true,
                    fillColor: AppColors.contentBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('TIPO DE ORDEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
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
                              color: isSelected ? AppColors.secondaryBase : AppColors.contentBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? AppColors.secondaryBase : Colors.transparent),
                            ),
                            alignment: Alignment.center,
                            child: Text(t.nombre ?? '', style: TextStyle(color: isSelected ? Colors.white : AppColors.textBase, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
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
                        
                        final success = await _ordenesController.update(orden.id!, updated);
                        if (success) {
                          await _loadData();
                          if (mounted) AppToast.show(context, 'Orden actualizada correctamente');
                        } else {
                          if (mounted) AppToast.show(context, 'No se pudo actualizar la orden', isError: true);
                        }
                      } catch (e) {
                        if (mounted) AppToast.show(context, 'Error: $e', isError: true);
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryBase, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('GUARDAR CAMBIOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textBase, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  String _friendlyStateName(String? state) {
    switch (state) {
      case 'PENDIENTE': return 'PENDIENTE';
      case 'EN_PROGRESO': return 'EN PROGRESO';
      case 'RESUELTO': return 'RESUELTO';
      default: return state ?? 'PENDIENTE';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.engineering_outlined, size: 80, color: Colors.grey.withOpacity(0.2)),
          ),
          const SizedBox(height: 24),
          const Text('Sin labores de mantenimiento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
