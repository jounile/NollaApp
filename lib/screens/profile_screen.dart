import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../services/app_logger.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  final String authToken;

  const ProfileScreen({super.key, required this.username, required this.authToken});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  String? _errorMessage;

  Profile? _profile;

  late final TextEditingController _displayNameCtrl = TextEditingController();
  late final TextEditingController _bioCtrl = TextEditingController();
  late final TextEditingController _emailCtrl = TextEditingController();
  late final TextEditingController _websiteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final result = await ProfileService.fetchProfile(widget.authToken);
    if (!mounted) return;
    if (result.success && result.profile != null) {
      _applyProfile(result.profile!);
      setState(() => _loading = false);
    } else {
      setState(() {
        _loading = false;
        _errorMessage = result.message;
      });
    }
  }

  void _applyProfile(Profile p) {
    _profile = p;
    _displayNameCtrl.text = p.displayName;
    _bioCtrl.text = p.bio;
    _emailCtrl.text = p.email;
    _websiteCtrl.text = p.website;
  }

  void _startEditing() => setState(() => _editing = true);

  void _cancelEditing() {
    if (_profile != null) _applyProfile(_profile!);
    setState(() => _editing = false);
  }

  Future<void> _saveChanges() async {
    if (!(_formKey.currentState?.validate() ?? true)) return;
    final current = _profile ?? Profile(username: widget.username, displayName: '', bio: '', email: '', website: '');
    final updated = current.copyWith(
      displayName: _displayNameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      website: _websiteCtrl.text.trim(),
    );

    setState(() => _saving = true);
    final result = await ProfileService.updateProfile(widget.authToken, updated);
    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      _applyProfile(result.profile ?? updated);
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed to save profile')),
      );
    }
  }

  bool _hasUnsavedChanges() {
    final p = _profile;
    if (p == null) return false;
    return _displayNameCtrl.text.trim() != p.displayName ||
        _bioCtrl.text.trim() != p.bio ||
        _emailCtrl.text.trim() != p.email ||
        _websiteCtrl.text.trim() != p.website;
  }

  String get _initials {
    final name = (_profile?.displayName.isNotEmpty == true)
        ? _profile!.displayName
        : widget.username;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_editing || !_hasUnsavedChanges(),
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('Your edits will be lost.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          _cancelEditing();
          Navigator.pop(context);
        }
      },
      child: Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.terminal),
            tooltip: 'View logs',
            onPressed: () => showLogViewer(context, filter: const ['[ProfileService]']),
          ),
          if (_loading || _saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit profile',
              onPressed: _errorMessage == null ? _startEditing : null,
            )
          else ...[
            TextButton(onPressed: _cancelEditing, child: const Text('Cancel')),
            FilledButton(onPressed: _saveChanges, child: const Text('Save')),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _ErrorView(message: _errorMessage!, onRetry: _fetchProfile)
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _Avatar(initials: _initials, theme: theme),
                        const SizedBox(height: 8),
                        Text(
                          '@${widget.username}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _ProfileField(
                          label: 'Display name',
                          controller: _displayNameCtrl,
                          editing: _editing,
                          hint: 'Your full name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _ProfileField(
                          label: 'Bio',
                          controller: _bioCtrl,
                          editing: _editing,
                          hint: 'Tell the community about yourself',
                          icon: Icons.info_outline,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _ProfileField(
                          label: 'Email',
                          controller: _emailCtrl,
                          editing: _editing,
                          hint: 'your@email.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _ProfileField(
                          label: 'Website',
                          controller: _websiteCtrl,
                          editing: _editing,
                          hint: 'https://example.com',
                          icon: Icons.link_outlined,
                          keyboardType: TextInputType.url,
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            if (!RegExp(r'^https?://').hasMatch(v)) return 'Must start with https://';
                            return null;
                          },
                        ),
                      ],
                    ),
                    ),
                  ),
      ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final ThemeData theme;

  const _Avatar({required this.initials, required this.theme});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 52,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool editing;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.editing,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (editing) {
      return TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      );
    }

    final value = controller.text;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: value.isNotEmpty
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
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
