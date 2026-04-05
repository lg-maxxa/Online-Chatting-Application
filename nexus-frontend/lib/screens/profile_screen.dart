import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

/// Profile Screen – view and edit the current user's profile.
/// Can be used standalone (route) or embedded in the home tab bar.
class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthService _auth;
  bool _editing = false;
  bool _saving = false;

  late final TextEditingController _usernameController;
  late final TextEditingController _statusController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthService>();
    final user = _auth.currentUser;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _statusController = TextEditingController(text: user?.status ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _statusController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final updated = await ApiService.instance.updateProfile({
        'username': _usernameController.text.trim(),
        'status': _statusController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      });
      await _auth.updateCurrentUser(UserModel.fromJson(updated));
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (file == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar upload not yet wired to S3 – see docs.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // ── Avatar ──────────────────────────────────────────────────────
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: user.profilePicUrl.isNotEmpty
                    ? NetworkImage(user.profilePicUrl)
                    : null,
                backgroundColor: AppTheme.tealGreen,
                child: user.profilePicUrl.isEmpty
                    ? Text(user.username[0].toUpperCase(),
                        style: const TextStyle(fontSize: 48, color: Colors.white))
                    : null,
              ),
              GestureDetector(
                onTap: _pickAndUploadAvatar,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.tealGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child:
                      const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Form Fields ─────────────────────────────────────────────────
          _ProfileField(
            label: 'Username',
            controller: _usernameController,
            icon: Icons.person_outline,
            enabled: _editing,
          ),
          const SizedBox(height: 14),
          _ProfileField(
            label: 'Email',
            value: user.email,
            icon: Icons.email_outlined,
            enabled: false,
          ),
          const SizedBox(height: 14),
          _ProfileField(
            label: 'Phone',
            controller: _phoneController,
            icon: Icons.phone_outlined,
            enabled: _editing,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _ProfileField(
            label: 'Status',
            controller: _statusController,
            icon: Icons.info_outline,
            enabled: _editing,
            maxLength: 139,
          ),
          const SizedBox(height: 32),

          // ── Edit / Save Button ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: _editing
                ? ElevatedButton.icon(
                    onPressed: _saving ? null : _saveProfile,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Save Changes'),
                  )
                : OutlinedButton.icon(
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.tealGreen,
                      side: const BorderSide(color: AppTheme.tealGreen),
                    ),
                  ),
          ),

          if (_editing) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _editing = false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.mediumGrey)),
            ),
          ],

          const SizedBox(height: 24),
          // ── Danger Zone ─────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: content,
    );
  }
}

// ── Reusable Profile Form Field ────────────────────────────────────────────────

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? value;
  final IconData icon;
  final bool enabled;
  final int? maxLength;
  final TextInputType? keyboardType;

  const _ProfileField({
    required this.label,
    required this.icon,
    this.controller,
    this.value,
    this.enabled = true,
    this.maxLength,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? value : null,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        counterText: '',
        filled: true,
        fillColor: enabled ? AppTheme.offWhite : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
