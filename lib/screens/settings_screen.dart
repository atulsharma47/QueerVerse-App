import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'edit_profile_screen.dart';
import 'welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _privateAccount = false;
  bool _loading = true;

  static const _bg = Color(0xFF0A0A12);
  static const _surface = Color(0xFF13131F);
  static const _border = Color(0xFF2A2A3A);
  static const _textLo = Color(0xFFB0B0C8);
  static const _primary = Color(0xFF8B5CF6);
  static const _danger = Colors.redAccent;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_uid.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();
      final data = doc.data();
      if (mounted) {
        setState(() {
          _notificationsEnabled =
              data?['notificationsEnabled'] as bool? ?? true;
          _privateAccount = data?['privateAccount'] as bool? ?? false;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateField(String field, bool value) async {
    if (_uid.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).set({
        field: value,
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update setting: $e')));
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Log out?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You will need to sign in again to access your account.',
          style: TextStyle(color: _textLo),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _textLo)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: _danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: _primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDanger = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: _surface,
        child: ListTile(
          leading: Icon(icon, color: isDanger ? _danger : _textLo),
          title: Text(
            title,
            style: TextStyle(
              color: isDanger ? _danger : Colors.white,
              fontSize: 15,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(color: _textLo, fontSize: 12),
                )
              : null,
          trailing:
              trailing ??
              (onTap != null
                  ? const Icon(Icons.chevron_right, color: _textLo)
                  : null),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : ListView(
              children: [
                _sectionHeader('Account'),
                _tile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  subtitle: 'Name, bio, avatar, pronouns',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  ),
                ),
                _tile(
                  icon: Icons.lock_outline,
                  title: 'Private Account',
                  subtitle: 'Only approved followers can see your posts',
                  trailing: Switch(
                    value: _privateAccount,
                    activeThumbColor: _primary,
                    onChanged: (v) {
                      setState(() => _privateAccount = v);
                      _updateField('privateAccount', v);
                    },
                  ),
                ),

                _sectionHeader('Notifications'),
                _tile(
                  icon: Icons.notifications_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Likes, comments, follows, and messages',
                  trailing: Switch(
                    value: _notificationsEnabled,
                    activeThumbColor: _primary,
                    onChanged: (v) {
                      setState(() => _notificationsEnabled = v);
                      _updateField('notificationsEnabled', v);
                    },
                  ),
                ),

                _sectionHeader('Privacy & Safety'),
                _tile(
                  icon: Icons.block,
                  title: 'Blocked Accounts',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Blocked accounts list coming soon'),
                      ),
                    );
                  },
                ),
                _tile(
                  icon: Icons.shield_outlined,
                  title: 'Report a Problem',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report flow coming soon')),
                    );
                  },
                ),

                _sectionHeader('About'),
                _tile(
                  icon: Icons.info_outline,
                  title: 'About QueerVerse',
                  subtitle: 'Version 1.0.0',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'QueerVerse',
                      applicationVersion: '1.0.0',
                      applicationLegalese: 'Your safe space 🌈',
                    );
                  },
                ),

                _sectionHeader('Account Actions'),
                _tile(
                  icon: Icons.logout,
                  title: 'Log Out',
                  isDanger: true,
                  onTap: _confirmLogout,
                ),

                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
