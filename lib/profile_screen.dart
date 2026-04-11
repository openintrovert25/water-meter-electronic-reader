import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  Map<String, dynamic>? _profile;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();

  bool _isEditingProfile = false;
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;
  String? _profileMessage;
  String? _passwordMessage;
  bool _profileMessageIsError = false;
  bool _passwordMessageIsError = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _auth.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _nameController.text = profile?['name'] ?? '';
        _emailController.text = profile?['email'] ?? '';
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    await _auth.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );
    await _loadProfile();
    setState(() {
      _isSavingProfile = false;
      _isEditingProfile = false;
      _profileMessage = 'Profile updated successfully!';
      _profileMessageIsError = false;
    });
  }

  Future<void> _changePassword() async {
    setState(() {
      _isSavingPassword = true;
      _passwordMessage = null;
    });
    final error = await _auth.changePassword(
      currentPassword: _currentPassController.text,
      newPassword: _newPassController.text,
    );
    setState(() {
      _isSavingPassword = false;
      if (error != null) {
        _passwordMessage = error;
        _passwordMessageIsError = true;
      } else {
        _passwordMessage = 'Password changed successfully!';
        _passwordMessageIsError = false;
        _currentPassController.clear();
        _newPassController.clear();
      }
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign Out')),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = _profile?['name'] ?? '';
    final username = _profile?['username'] ?? '';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar + name header
            CircleAvatar(
              radius: 44,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600)),
            Text('@$username',
                style:
                    TextStyle(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 28),

            // Profile info card
            _SectionCard(
              title: 'Personal Info',
              trailing: TextButton.icon(
                onPressed: () =>
                    setState(() => _isEditingProfile = !_isEditingProfile),
                icon: Icon(_isEditingProfile ? Icons.close : Icons.edit,
                    size: 16),
                label: Text(_isEditingProfile ? 'Cancel' : 'Edit'),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    enabled: _isEditingProfile,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    enabled: _isEditingProfile,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (_isEditingProfile) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSavingProfile ? null : _saveProfile,
                        child: _isSavingProfile
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                  if (_profileMessage != null) ...[
                    const SizedBox(height: 10),
                    _MessageBanner(
                        message: _profileMessage!,
                        isError: _profileMessageIsError),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Change password card
            _SectionCard(
              title: 'Change Password',
              child: Column(
                children: [
                  TextFormField(
                    controller: _currentPassController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPassController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                      border: OutlineInputBorder(),
                      helperText: 'At least 6 characters',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isSavingPassword ? null : _changePassword,
                      child: _isSavingPassword
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update Password'),
                    ),
                  ),
                  if (_passwordMessage != null) ...[
                    const SizedBox(height: 10),
                    _MessageBanner(
                        message: _passwordMessage!,
                        isError: _passwordMessageIsError),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Account info card
            _SectionCard(
              title: 'Account',
              child: Column(
                children: [
                  _InfoRow('Username', '@$username'),
                  _InfoRow(
                    'Member Since',
                    _profile?['createdAt'] != null
                        ? _formatDate(_profile!['createdAt'])
                        : '—',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Sign Out',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    DateTime? dt;
    if (value is Timestamp) {
      dt = value.toDate();
    } else if (value is String) {
      dt = DateTime.tryParse(value);
    }
    if (dt == null) return '—';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard(
      {required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                        fontSize: 13,
                        letterSpacing: 0.4)),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  final String message;
  final bool isError;
  const _MessageBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isError
            ? colorScheme.errorContainer
            : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: isError ? colorScheme.error : colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isError ? colorScheme.error : colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
