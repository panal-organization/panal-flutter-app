import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import '../../controllers/app_controllers.dart';
import '../../layout/main.layout.dart';
import '../../utils/app_colors.dart';

class WorkspaceSelectionView extends StatefulWidget {
  const WorkspaceSelectionView({super.key});

  @override
  State<WorkspaceSelectionView> createState() => _WorkspaceSelectionViewState();
}

class _WorkspaceSelectionViewState extends State<WorkspaceSelectionView> {
  bool _isLoading = true;
  List<WorkspacesUsuarios> _workspaces = [];
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadWorkspaces();
  }

  Future<void> _loadWorkspaces() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');

    if (_userId != null) {
      final controller = WorkspacesUsuariosController();
      try {
        final list = await controller.getByUserId(_userId!);
        if (mounted) {
          setState(() {
            _workspaces = list;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectWorkspace(String workspaceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_workspace_id', workspaceId);
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainLayout()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.menuBackground,
      body: Stack(
        children: [
          // Graphic Hexagon background
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: SvgPicture.asset(
                'assets/app/Hexagon.svg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    'Selecciona un Espacio',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Elige dónde trabajarás hoy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 30,
                      left: 20,
                      right: 20,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _workspaces.isEmpty
                        ? const Center(
                            child: Text(
                              'No tienes espacios asignados',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _workspaces.length,
                            itemBuilder: (context, index) {
                              final wu = _workspaces[index];
                              final ws = wu.workspace;
                              if (ws == null) return const SizedBox.shrink();

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _selectWorkspace(ws.id!),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Ink(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                        horizontal: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.contentBackground,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.15),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.menuBackground
                                                  .withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.business_center_rounded,
                                              color: AppColors.menuBackground,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  ws.nombre ?? 'Sin nombre',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textBase,
                                                  ),
                                                ),
                                                if (ws.codigo != null && ws.codigo!.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  GestureDetector(
                                                    onTap: () {
                                                      Clipboard.setData(ClipboardData(text: ws.codigo!));
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Código copiado al portapapeles')),
                                                      );
                                                    },
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.key_rounded,
                                                          size: 14,
                                                          color: AppColors.secondaryBase,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Código: ${ws.codigo}',
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.grey,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        const Icon(
                                                          Icons.copy_rounded,
                                                          size: 14,
                                                          color: Colors.grey,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                if (wu.usuario?.isPremium ==
                                                    true) ...[
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppColors.warningBg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      border: Border.all(
                                                        color: AppColors
                                                            .warningBase,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: const [
                                                        Icon(
                                                          Icons.star_rounded,
                                                          color: AppColors
                                                              .warningBase,
                                                          size: 14,
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Premium',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: AppColors
                                                                .warningBase,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            size: 28,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 48,
        child: FloatingActionButton.extended(
          onPressed: _showAddWorkspaceOptions,
          backgroundColor: AppColors.secondaryBase,
          elevation: 2,
          icon: const Icon(Icons.add, size: 20, color: Colors.white),
          label: const Text(
            'Nuevo Espacio',
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

  void _showAddWorkspaceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Opciones de Espacio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBase,
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBase.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group_add_rounded, color: AppColors.secondaryBase),
              ),
              title: const Text('Unirse a un espacio existente', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Usa un código de invitación'),
              onTap: () {
                Navigator.pop(ctx);
                _showJoinWorkspaceDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBase.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_business_rounded, color: AppColors.secondaryBase),
              ),
              title: const Text('Crear un nuevo espacio', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Conviértete en el administrador'),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateWorkspaceDialog();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showJoinWorkspaceDialog() async {
    final codeController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Unirse a Espacio'),
            content: TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Código del espacio',
                labelStyle: const TextStyle(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.secondaryBase, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, codeController.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryBase,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Unirse', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final ctrl = WorkspacesController();
        final list = await ctrl.getByCode(result);
        if (list.isNotEmpty) {
          final ws = list.first;
          final wuCtrl = WorkspacesUsuariosController();
          await wuCtrl.create(WorkspacesUsuarios(
            workspaceId: ws.id,
            usuarioId: _userId,
          ));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Te has unido al espacio exitosamente')),
          );
          _loadWorkspaces();
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró ningún espacio con ese código')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al unirse: $e')),
        );
      }
    }
  }

  Future<void> _showCreateWorkspaceDialog() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Crear Espacio'),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del espacio',
                labelStyle: const TextStyle(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.secondaryBase, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryBase,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Crear', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final ctrl = WorkspacesController();
        final newWs = await ctrl.createWorkspace(Workspaces(
          nombre: result,
          adminId: _userId,
        ));
        
        if (newWs != null && newWs.id != null) {
          final wuCtrl = WorkspacesUsuariosController();
          await wuCtrl.create(WorkspacesUsuarios(
            workspaceId: newWs.id,
            usuarioId: _userId,
          ));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Espacio creado exitosamente')),
          );
          _loadWorkspaces();
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo crear el espacio')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear: $e')),
        );
      }
    }
  }
}
