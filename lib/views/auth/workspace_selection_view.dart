import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../controllers/app_controllers.dart';
import '../../layout/main.layout.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_toast.dart';

class WorkspaceSelectionView extends StatefulWidget {
  const WorkspaceSelectionView({super.key});

  @override
  State<WorkspaceSelectionView> createState() => _WorkspaceSelectionViewState();
}

class _WorkspaceSelectionViewState extends State<WorkspaceSelectionView> {
  bool _isLoading = true;
  List<WorkspacesUsuarios> _workspaces = [];
  String? _userId;
  String? _userPlanId;
  String? _premiumPlanId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadPlans();
    await _loadWorkspaces();
  }

  Future<void> _loadPlans() async {
    try {
      final ctrl = PlanController();
      final plans = await ctrl.getAll();
      if (mounted) {
        setState(() {
          // Identificar el plan premium dinámicamente o usar el fallback
          final premiumPlan = plans
              .where(
                (p) => p.nombre?.toLowerCase().contains('premium') ?? false,
              )
              .firstOrNull;
          _premiumPlanId = premiumPlan?.id ?? '69a3df3381a5be4cb1bd8bc3';
        });
      }
    } catch (e) {
      debugPrint('Error loading plans: $e');
      if (mounted) {
        setState(() {
          _premiumPlanId = '69a3df3381a5be4cb1bd8bc3';
        });
      }
    }
  }

  Future<void> _loadWorkspaces() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    _userPlanId = prefs.getString('user_plan');

    if (_userId != null) {
      final controller = WorkspacesUsuariosController();
      try {
        final list = await controller.getByUserId(_userId!);
        if (mounted) {
          setState(() {
            _workspaces = list;
            // Inferir el plan del usuario si no está en SharedPreferences
            if (_userPlanId == null && list.isNotEmpty) {
              final personalWs = list
                  .where((wu) => wu.workspace?.adminId == _userId)
                  .firstOrNull;
              if (personalWs != null) {
                _userPlanId = personalWs.workspace?.planId;
              }
            }
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

  Future<void> _selectWorkspace(String workspaceId, {String? planId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_workspace_id', workspaceId);
    if (planId != null) {
      await prefs.setString('workspace_plan_id', planId);
    } else {
      await prefs.remove('workspace_plan_id');
    }
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
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.secondaryBase,
                            ),
                          )
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
                                child: Container(
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
                                        child: Icon(
                                          ws.adminId == _userId
                                              ? Icons.person_rounded
                                              : Icons.business_center_rounded,
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
                                            if (ws.codigo != null &&
                                                ws.codigo!.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              GestureDetector(
                                                onTap: () {
                                                  Clipboard.setData(
                                                    ClipboardData(
                                                      text: ws.codigo!,
                                                    ),
                                                  );
                                                },
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.key_rounded,
                                                      size: 14,
                                                      color: AppColors
                                                          .secondaryBase,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Código: ${ws.codigo}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey,
                                                        fontWeight:
                                                            FontWeight.w500,
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
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                if (ws.planId ==
                                                        _premiumPlanId ||
                                                    ws.planId ==
                                                        '69a3df3381a5be4cb1bd8bc3') ...[
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .warningBase
                                                          .withOpacity(0.08),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
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
                                                          size: 12,
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Premium',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppColors
                                                                .warningBase,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                ] else if (ws.adminId ==
                                                    _userId) ...[
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .secondaryBase
                                                          .withOpacity(0.08),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: const [
                                                        Icon(
                                                          Icons.person_rounded,
                                                          color: AppColors
                                                              .secondaryBase,
                                                          size: 12,
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Personal',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppColors
                                                                .secondaryBase,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Material(
                                        color: Colors.transparent,
                                        child: IconButton(
                                          onPressed: () => _selectWorkspace(
                                            ws.id!,
                                            planId: ws.planId,
                                          ),
                                          icon: const Icon(
                                            Icons.chevron_right_rounded,
                                            size: 32,
                                            color: Colors.grey,
                                          ),
                                          splashRadius: 24,
                                        ),
                                      ),
                                    ],
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
                child: const Icon(
                  Icons.group_add_rounded,
                  color: AppColors.secondaryBase,
                ),
              ),
              title: const Text(
                'Unirse a un espacio existente',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
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
                  color:
                      (_userPlanId == _premiumPlanId ||
                          _userPlanId == '69a3df3381a5be4cb1bd8bc3')
                      ? AppColors.secondaryBase.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_business_rounded,
                  color:
                      (_userPlanId == _premiumPlanId ||
                          _userPlanId == '69a3df3381a5be4cb1bd8bc3')
                      ? AppColors.secondaryBase
                      : Colors.grey,
                ),
              ),
              title: Text(
                'Crear un nuevo espacio',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color:
                      (_userPlanId == _premiumPlanId ||
                          _userPlanId == '69a3df3381a5be4cb1bd8bc3')
                      ? AppColors.textBase
                      : Colors.grey,
                ),
              ),
              subtitle: Text(
                (_userPlanId == _premiumPlanId ||
                        _userPlanId == '69a3df3381a5be4cb1bd8bc3')
                    ? 'Conviértete en el administrador'
                    : 'Disponible solo en Plan Premium',
                style: TextStyle(
                  color:
                      (_userPlanId == _premiumPlanId ||
                          _userPlanId == '69a3df3381a5be4cb1bd8bc3')
                      ? Colors.grey
                      : Colors.red.shade300,
                  fontSize: 12,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                color: AppColors.secondaryBase,
                tooltip: 'Ser miembro premium',
                onPressed: _openUpgradePage,
              ),
              onTap: () {
                if (_userPlanId == _premiumPlanId ||
                    _userPlanId == '69a3df3381a5be4cb1bd8bc3') {
                  Navigator.pop(ctx);
                  _showCreateWorkspaceDialog();
                } else {
                  _openUpgradePage();
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _openUpgradePage() async {
    final upgradeUrl = Uri.parse(
      'http://192.168.0.141:5173/panal-web-application/pricing',
    );
    if (await canLaunchUrl(upgradeUrl)) {
      await launchUrl(upgradeUrl, mode: LaunchMode.externalApplication);
    } else {
      AppToast.show(context, 'No se pudo abrir la URL de pago', isError: true);
    }
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Unirse a Espacio'),
            content: TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Código del espacio de trabajo',
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, codeController.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryBase,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Unirse',
                  style: TextStyle(color: Colors.white),
                ),
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
        // Verificar si el workspace es gratuito y ya tiene miembros
        final wsList = await WorkspacesController().getByCode(result);
        if (wsList.isNotEmpty) {
          final ws = wsList.first;
          final premiumId = _premiumPlanId ?? '69a3df3381a5be4cb1bd8bc3';
          final isPremiumWs = ws.planId == premiumId;
          if (!isPremiumWs) {
            // Verificar cuántos miembros tiene el workspace
            final members = await WorkspacesUsuariosController()
                .getByWorkspaceId(ws.id!);
            if (members.isNotEmpty) {
              if (!mounted) return;
              setState(() => _isLoading = false);
              AppToast.show(
                context,
                'Este espacio gratuito ya tiene un miembro. Actualiza a Premium para invitar más usuarios.',
                isError: true,
              );
              return;
            }
          }
        }

        final ctrl = WorkspacesController();
        final success = await ctrl.joinByCode(_userId!, result);

        if (success) {
          AppToast.show(context, 'Te has unido al espacio exitosamente');
          _loadWorkspaces();
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        final errorMsg = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('Exception', '');
        AppToast.show(context, errorMsg, isError: true);
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Crear Espacio'),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del espacio de trabajo',
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryBase,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Crear',
                  style: TextStyle(color: Colors.white),
                ),
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
        final newWs = await ctrl.createWorkspace(
          Workspaces(nombre: result, adminId: _userId),
        );

        if (newWs != null) {
          AppToast.show(context, 'Espacio creado exitosamente');
          _loadWorkspaces();
        } else {
          setState(() => _isLoading = false);
          AppToast.show(context, 'No se pudo crear el espacio', isError: true);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        final errorMsg = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('Exception', '');
        AppToast.show(context, errorMsg, isError: true);
      }
    }
  }
}
