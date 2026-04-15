import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_colors.dart';
import '../auth/login_view.dart';
import '../auth/workspace_selection_view.dart';
import 'profile_view.dart';
import 'workspace_users_view.dart';

class SystemView extends StatelessWidget {
  const SystemView({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Salir',
              style: TextStyle(color: AppColors.dangerBase),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authController = AuthController();
      await authController.signOut();

      if (context.mounted) {
        // Navigate to LoginView and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 20),
        _buildSectionTitle('Cuenta'),
        const SizedBox(height: 10),
        _buildSettingsTile(
          icon: Icons.person_outline,
          title: 'Perfil',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileView()),
            );
          },
        ),
        _buildSettingsTile(
          icon: Icons.group_outlined,
          title: 'Usuarios con acceso',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkspaceUsersView(),
              ),
            );
          },
        ),
        _buildSettingsTile(
          icon: Icons.business_center_outlined,
          title: 'Cambiar Espacio de Trabajo',
          onTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const WorkspaceSelectionView()),
            );
          },
        ),
        const SizedBox(height: 30),
        _buildSectionTitle('Sesión'),
        const SizedBox(height: 10),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.dangerBg.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout, color: AppColors.dangerBase),
          ),
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.dangerBase,
            ),
          ),
          onTap: () => _handleLogout(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.menuBackground,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppColors.contentBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.menuBackground),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
