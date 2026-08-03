import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

/// Wraps the authenticated part of the app. Keeps Firestore's isOnline /
/// lastSeen in sync with real app lifecycle state, and re-syncs email
/// verification status whenever the app comes back to the foreground
/// (in case the user verified their email in another tab/app meanwhile).
class PresenceWrapper extends StatefulWidget {
  final String uid;
  final Widget child;

  const PresenceWrapper({super.key, required this.uid, required this.child});

  @override
  State<PresenceWrapper> createState() => _PresenceWrapperState();
}

class _PresenceWrapperState extends State<PresenceWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    UserService.setOnline(widget.uid);
    _refreshEmailVerification();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    UserService.setOffline(widget.uid);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        UserService.setOnline(widget.uid);
        _refreshEmailVerification();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        UserService.setOffline(widget.uid);
        break;
    }
  }

  Future<void> _refreshEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed != null) {
        await UserService.syncEmailVerified(
          widget.uid,
          refreshed.emailVerified,
        );
      }
    } catch (_) {
      // Silently ignore — non-critical background sync
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
