import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/app_controllers.dart';
import '../../models/models.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_toast.dart';

class WorkspaceUsersView extends StatefulWidget {
  const WorkspaceUsersView({super.key});

  @override
  State<WorkspaceUsersView> createState() => _WorkspaceUsersViewState();
}

class _WorkspaceUsersViewState extends State<WorkspaceUsersView> {
  final WorkspacesUsuariosController _usuariosController =
      WorkspacesUsuariosController();
  final WorkspacesController _workspacesController = WorkspacesController();

  List<WorkspacesUsuarios> _users = [];
  bool _isLoading = true;
  String? _currentUserId;
  String? _workspaceId;
  Workspaces? _currentWorkspace;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('user_id');
      _workspaceId = prefs.getString('selected_workspace_id');

      if (_workspaceId != null) {
        // Fetch workspace to check admin_id
        final ws = await _workspacesController.getOne(_workspaceId!);

        // Fetch joined users
        final us = await _usuariosController.getByWorkspaceId(_workspaceId!);

        if (mounted) {
          setState(() {
            _currentWorkspace = ws;
            _users = us;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading WorkspaceUsers: $e');
      if (mounted) {
        AppToast.show(context, 'Error al cargar usuarios', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeUser(WorkspacesUsuarios entry) async {
    if (entry.id == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Usuario'),
        content: Text(
          '¿Estás seguro de que deseas remover a ${entry.usuario?.nombre ?? 'este usuario'} del espacio de trabajo?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remover',
              style: TextStyle(color: AppColors.dangerBase),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) setState(() => _isLoading = true);
      try {
        final success = await _usuariosController.remove(entry.id!);
        if (success) {
          if (mounted) AppToast.show(context, 'Usuario removido correctamente');
          _loadInitialData();
        } else {
          if (mounted)
            AppToast.show(
              context,
              'No se pudo remover el usuario',
              isError: true,
            );
        }
      } catch (e) {
        if (mounted) AppToast.show(context, 'Error: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  bool get _isAdmin {
    if (_currentWorkspace == null || _currentUserId == null) return false;
    return _currentWorkspace!.adminId == _currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.contentBackground,
      appBar: AppBar(
        title: const Text(
          'Usuarios con Acceso',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textBase,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textBase),
      ),
      body: _isLoading && _users.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryBase),
            )
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              color: AppColors.secondaryBase,
              child: _users.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final entry = _users[index];
                        return _buildUserCard(entry);
                      },
                    ),
            ),
    );
  }

  Widget _buildUserCard(WorkspacesUsuarios entry) {
    final user = entry.usuario;
    if (user == null) return const SizedBox.shrink();

    final bool isEntryAdmin = _currentWorkspace?.adminId == user.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.secondaryBase.withOpacity(0.1),
          backgroundImage: user.foto != null ? NetworkImage(user.foto!) : null,
          child: user.foto == null
              ? Text(
                  (user.nombre ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.secondaryBase,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user.nombre ?? 'Sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.correo ?? 'Sin correo',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            if (isEntryAdmin)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBase.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Administrador / Dueño',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.secondaryBase,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: _isAdmin && !isEntryAdmin
            ? IconButton(
                icon: const Icon(
                  Icons.person_remove_outlined,
                  color: AppColors.dangerBase,
                  size: 22,
                ),
                onPressed: () => _removeUser(entry),
              )
            : (isEntryAdmin
                  ? const Icon(
                      Icons.star,
                      color: AppColors.secondaryBase,
                      size: 20,
                    )
                  : null),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 80,
                color: Colors.grey.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay otros usuarios en este espacio',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
