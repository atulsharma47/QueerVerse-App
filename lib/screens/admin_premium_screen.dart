import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/feed/feed_app_bar.dart';

class AdminPremiumScreen extends StatefulWidget {
  const AdminPremiumScreen({super.key});

  @override
  State<AdminPremiumScreen> createState() => _AdminPremiumScreenState();
}

class _AdminPremiumScreenState extends State<AdminPremiumScreen> {
  final _emailController = TextEditingController();
  UserModel? foundUser;
  bool isSearching = false;
  bool isUpdating = false;
  String? searchError;

  Future<void> _search() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      isSearching = true;
      searchError = null;
      foundUser = null;
    });

    try {
      final user = await UserService.findUserByEmail(email);
      setState(() => foundUser = user);
      if (user == null) {
        setState(() => searchError = 'No user found with that email');
      }
    } catch (e) {
      setState(() => searchError = '$e');
    } finally {
      if (mounted) setState(() => isSearching = false);
    }
  }

  Future<void> _togglePremium() async {
    if (foundUser == null) return;
    setState(() => isUpdating = true);
    try {
      final newValue = !foundUser!.isPremium;
      await UserService.setPremium(foundUser!.uid, newValue);
      final refreshed = await UserService.fetchUser(foundUser!.uid);
      setState(() => foundUser = refreshed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newValue ? 'Premium granted' : 'Premium revoked'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FC.bg,
      appBar: AppBar(
        title: const Text('Manage Premium'),
        backgroundColor: FC.bg,
        foregroundColor: FC.textHi,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    style: const TextStyle(color: FC.textHi),
                    decoration: InputDecoration(
                      hintText: "User's email",
                      hintStyle: const TextStyle(color: FC.textLo),
                      filled: true,
                      fillColor: FC.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSearching ? null : _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FC.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isSearching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.search, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (searchError != null)
              Text(
                searchError!,
                style: const TextStyle(color: Colors.redAccent),
              ),

            if (foundUser != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: FC.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: FC.border.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: FC.primary,
                          backgroundImage: foundUser!.profileImage.isNotEmpty
                              ? NetworkImage(foundUser!.profileImage)
                              : null,
                          child: foundUser!.profileImage.isEmpty
                              ? Text(
                                  foundUser!.name.isNotEmpty
                                      ? foundUser!.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                foundUser!.name,
                                style: const TextStyle(
                                  color: FC.textHi,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                foundUser!.email,
                                style: const TextStyle(
                                  color: FC.textLo,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (foundUser!.isPremium)
                          const Icon(Icons.diamond, color: Color(0xFFF7B733)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isUpdating ? null : _togglePremium,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: foundUser!.isPremium
                              ? Colors.redAccent
                              : const Color(0xFFF7B733),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isUpdating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                foundUser!.isPremium
                                    ? 'Revoke Premium'
                                    : 'Grant Premium',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
