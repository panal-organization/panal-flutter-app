import 'package:flutter/material.dart';
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
                                            child: Text(
                                              ws.nombre ?? 'Sin nombre',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textBase,
                                              ),
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
    );
  }
}
