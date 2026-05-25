import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final String username;

  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;

  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _websiteCtrl;

  String _savedDisplayName = '';
  String _savedBio = '';
  String _savedEmail = '';
  String _savedWebsite = '';

  @override
  void initState() {
    super.initState();
    _displayNameCtrl = TextEditingController(text: _savedDisplayName);
    _bioCtrl = TextEditingController(text: _savedBio);
    _emailCtrl = TextEditingController(text: _savedEmail);
    _websiteCtrl = TextEditingController(text: _savedWebsite);
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _startEditing() => setState(() => _editing = true);

  void _cancelEditing() {
    _displayNameCtrl.text = _savedDisplayName;
    _bioCtrl.text = _savedBio;
    _emailCtrl.text = _savedEmail;
    _websiteCtrl.text = _savedWebsite;
    setState(() => _editing = false);
  }

  void _saveChanges() {
    setState(() {
      _savedDisplayName = _displayNameCtrl.text.trim();
      _savedBio = _bioCtrl.text.trim();
      _savedEmail = _emailCtrl.text.trim();
      _savedWebsite = _websiteCtrl.text.trim();
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
  }

  String get _initials {
    final name = _savedDisplayName.isNotEmpty ? _savedDisplayName : widget.username;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit profile',
              onPressed: _startEditing,
            )
          else ...[
            TextButton(onPressed: _cancelEditing, child: const Text('Cancel')),
            FilledButton(
              onPressed: _saveChanges,
              child: const Text('Save'),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
              ),
              const SizedBox(height: 16),
              _ProfileField(
                label: 'Website',
                controller: _websiteCtrl,
                editing: _editing,
                hint: 'https://example.com',
                icon: Icons.link_outlined,
                keyboardType: TextInputType.url,
              ),
            ],
          ),
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

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.editing,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (editing) {
      return TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
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
        borderRadius: BorderRadius.circular(12),
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
