import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/app_controllers.dart';
import '../../models/models.dart';
import '../../utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_toast.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final UsuariosController _usuariosController = UsuariosController();
  final RolesController _rolesController = RolesController();
  final ImagePicker _picker = ImagePicker();
  Future<Map<String, dynamic>>? _profileDataFuture;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  void _refreshProfile() {
    setState(() {
      _profileDataFuture = _loadProfileData();
    });
  }

  Future<Map<String, dynamic>> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) throw Exception('No user ID found');

    final user = await _usuariosController.getOne(userId);
    if (user == null) throw Exception('User not found');

    Roles? role;
    if (user.rolId != null) {
      role = await _rolesController.getOne(user.rolId!);
    }

    return {'user': user, 'role': role};
  }

  Future<void> _pickAndUploadImage(String userId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      _showCustomToast("Subiendo imagen...");

      final success = await _usuariosController.updatePhoto(userId, image.path);

      if (success) {
        _showCustomToast("Imagen actualizada correctamente");
        _refreshProfile();
      } else {
        _showCustomToast("Error al subir la imagen", isError: true);
      }
    } catch (e) {
      _showCustomToast("Error: $e", isError: true);
    }
  }

  void _showCustomToast(String message, {bool isError = false}) {
    AppToast.show(context, message, isError: isError);
  }

  Future<void> _showChangePasswordDialog(String userId) async {
    final passController = TextEditingController();
    final confirmPassController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passController,
              obscureText: true,
              cursorColor: AppColors.secondaryBase,
              decoration: const InputDecoration(
                labelText: 'Nueva Contraseña',
                labelStyle: TextStyle(color: AppColors.secondaryBase),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.secondaryBase),
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPassController,
              obscureText: true,
              cursorColor: AppColors.secondaryBase,
              decoration: const InputDecoration(
                labelText: 'Confirmar Contraseña',
                labelStyle: TextStyle(color: AppColors.secondaryBase),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.secondaryBase),
                ),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final pass = passController.text.trim();
              final confirm = confirmPassController.text.trim();

              if (pass.isEmpty || confirm.isEmpty) {
                _showCustomToast("Ambos campos son requeridos", isError: true);
                return;
              }

              if (pass != confirm) {
                _showCustomToast("Las contraseñas no coinciden", isError: true);
                return;
              }

              final updatedUser = Usuarios(id: userId, contrasena: pass);
              final success = await _usuariosController.update(
                userId,
                updatedUser,
              );
              if (success) {
                _showCustomToast("Contraseña actualizada");
                if (mounted) Navigator.pop(context);
              } else {
                _showCustomToast("Error al cambiar contraseña", isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryBase,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.contentBackground,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppColors.headerBackground,
        foregroundColor: AppColors.menuBackground,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryBase),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data;
          final user = data?['user'] as Usuarios?;
          final role = data?['role'] as Roles?;

          if (user == null) {
            return const Center(
              child: Text('No se pudo cargar la información del usuario'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile Picture Header
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.primaryBg,
                          backgroundImage: user.foto != null
                              ? NetworkImage(
                                  user.foto!.startsWith('http')
                                      ? user.foto!
                                      : 'http://3.19.63.85:3000${user.foto!}',
                                )
                              : null,
                          child: user.foto == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.secondaryBase,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _pickAndUploadImage(user.id!),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.secondaryBase,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  user.nombre ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.menuBackground,
                  ),
                ),
                Text(
                  user.correo ?? 'Sin correo',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                // Info Cards
                _buildInfoCard(
                  title: 'Información Personal',
                  items: [
                    _buildInfoItem(
                      Icons.badge_outlined,
                      'ID',
                      user.id ?? 'N/A',
                    ),
                    _buildInfoItem(
                      Icons.email_outlined,
                      'Correo',
                      user.correo ?? 'N/A',
                    ),
                    _buildInfoItem(
                      Icons.toggle_on_outlined,
                      'Estatus',
                      (user.estatus ?? false) ? 'Activo' : 'Inactivo',
                      color: (user.estatus ?? false)
                          ? AppColors.successBase
                          : AppColors.dangerBase,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Cuenta',
                  items: [
                    _buildInfoItem(
                      Icons.admin_panel_settings_outlined,
                      'Rol',
                      role?.nombre ?? 'Cargando...',
                    ),
                    _buildInfoItem(
                      Icons.calendar_today_outlined,
                      'Creado',
                      _formatDate(user.createdAt),
                    ),
                    _buildInfoItem(
                      Icons.update_outlined,
                      'Actualizado',
                      _formatDate(user.updatedAt),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showChangePasswordDialog(user.id!),
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Cambiar Contraseña'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryBase,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({required String title, List<Widget>? items}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.menuBackground,
            ),
          ),
          const SizedBox(height: 16),
          if (items != null) ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.contentBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.menuBackground),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color ?? AppColors.menuBackground,
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
