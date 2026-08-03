import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../services/user_service.dart';
import '../widgets/feed/feed_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final pronounsController = TextEditingController();
  final orientationController = TextEditingController();
  final genderController = TextEditingController();
  final locationController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  File? selectedAvatar;
  String profileImageUrl = '';

  List<String> existingPhotoUrls = [];
  List<File> newPhotoFiles = [];

  final List<String> _lookingForOptions = [
    'Dating',
    'Meetups',
    'Friends',
    'Long Term',
    'Casual',
    'Networking',
  ];
  final List<String> _interestOptions = [
    'Gaming',
    'Music',
    'Coffee',
    'Movies',
    'Travel',
    'Gym',
    'Reading',
    'Art',
    'Cooking',
    'Photography',
    'Dancing',
    'Hiking',
  ];
  final Set<String> selectedLookingFor = {};
  final Set<String> selectedInterests = {};

  String relationshipStatus = '';
  String smokingStatus = '';
  String drinkingStatus = '';
  String prideStatus = '';

  final List<String> _relationshipOptions = [
    'Single',
    'Long Term',
    'It\'s Complicated',
    'Open',
  ];
  final List<String> _smokingOptions = [
    'Non-smoker',
    'Occasionally',
    'Regularly',
  ];
  final List<String> _drinkingOptions = [
    'Never',
    'Occasionally drinks',
    'Regularly',
  ];
  final List<String> _prideOptions = [
    'Proud & Out',
    'Selectively Out',
    'Private',
    'Still Exploring',
  ];

  bool isIdVerified = false;
  bool isUploadingId = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();

      if (data != null) {
        nameController.text = data['name'] ?? '';
        bioController.text = data['bio'] ?? '';
        pronounsController.text = data['pronouns'] ?? '';
        orientationController.text = data['orientation'] ?? '';
        genderController.text = data['gender'] ?? '';
        locationController.text = data['location'] ?? '';
        profileImageUrl = data['profileImage'] ?? '';
        existingPhotoUrls = List<String>.from(data['photos'] ?? []);
        selectedLookingFor.addAll(List<String>.from(data['lookingFor'] ?? []));
        selectedInterests.addAll(List<String>.from(data['interests'] ?? []));
        relationshipStatus = data['relationshipStatus'] ?? '';
        smokingStatus = data['smokingStatus'] ?? '';
        drinkingStatus = data['drinkingStatus'] ?? '';
        prideStatus = data['prideStatus'] ?? '';
        isIdVerified = data['isIdVerified'] ?? false;
      }
    } catch (e) {
      debugPrint("LOAD PROFILE ERROR: $e");
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => selectedAvatar = File(picked.path));
    }
  }

  Future<void> pickPhotos() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      setState(() {
        newPhotoFiles.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  void removeExistingPhoto(int index) {
    setState(() => existingPhotoUrls.removeAt(index));
  }

  void removeNewPhoto(int index) {
    setState(() => newPhotoFiles.removeAt(index));
  }

  /// Self-serve ID verification: upload immediately marks isIdVerified.
  /// This is a placeholder until real manual/automated review exists.
  Future<void> uploadIdDocument() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => isUploadingId = true);
    try {
      final url = await CloudinaryService.uploadImage(File(picked.path));
      if (url != null) {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        await UserService.markIdVerified(uid, url);
        setState(() => isIdVerified = true);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ID verified')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => isUploadingId = false);
    }
  }

  Future<void> saveProfile() async {
    setState(() => isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String imageUrl = profileImageUrl;

      if (selectedAvatar != null) {
        final uploaded = await CloudinaryService.uploadImage(selectedAvatar!);
        if (uploaded != null) imageUrl = uploaded;
      }

      final uploadedNewUrls = <String>[];
      for (final file in newPhotoFiles) {
        final url = await CloudinaryService.uploadImage(file);
        if (url != null) uploadedNewUrls.add(url);
      }
      final allPhotos = [...existingPhotoUrls, ...uploadedNewUrls];

      await UserService.updateProfile(uid, {
        'name': nameController.text.trim(),
        'bio': bioController.text.trim(),
        'pronouns': pronounsController.text.trim(),
        'orientation': orientationController.text.trim(),
        'gender': genderController.text.trim(),
        'location': locationController.text.trim(),
        'profileImage': imageUrl,
        'photos': allPhotos,
        'isPhotoVerified': allPhotos.isNotEmpty, // recomputed each save
        'lookingFor': selectedLookingFor.toList(),
        'interests': selectedInterests.toList(),
        'relationshipStatus': relationshipStatus,
        'smokingStatus': smokingStatus,
        'drinkingStatus': drinkingStatus,
        'prideStatus': prideStatus,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.pop(context);
    } catch (e) {
      debugPrint("SAVE PROFILE ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    pronounsController.dispose();
    orientationController.dispose();
    genderController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: FC.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: FC.textHi),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: FC.textMid),
          filled: true,
          fillColor: FC.card,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: FC.border.withValues(alpha: 0.6)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: FC.primary, width: 1.5),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _choiceChipGroup({
    required List<String> options,
    required Set<String> selected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () {
            setState(() {
              isSelected ? selected.remove(option) : selected.add(option);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(colors: [FC.primary, FC.accent])
                  : null,
              color: isSelected ? null : FC.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : FC.border.withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : FC.textMid,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _singleChoiceGroup({
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return GestureDetector(
          onTap: () => onSelect(isSelected ? '' : option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(colors: [FC.primary, FC.accent])
                  : null,
              color: isSelected ? null : FC.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : FC.border.withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : FC.textMid,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _photoThumb({required Widget image, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(width: 90, height: 90, child: image),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: FC.bg,
        body: Center(child: CircularProgressIndicator(color: FC.primary)),
      );
    }

    return Scaffold(
      backgroundColor: FC.bg,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: FC.bg,
        foregroundColor: FC.textHi,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: pickAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [FC.primary, FC.accent],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: FC.card,
                        backgroundImage: selectedAvatar != null
                            ? FileImage(selectedAvatar!)
                            : (profileImageUrl.isNotEmpty
                                      ? NetworkImage(profileImageUrl)
                                      : null)
                                  as ImageProvider?,
                        child: selectedAvatar == null && profileImageUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: FC.textLo,
                              )
                            : null,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: FC.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _sectionLabel('Basic Info'),
            _field('Name', nameController),
            _field('Bio', bioController, maxLines: 3),
            _field('Pronouns', pronounsController),
            _field('Orientation', orientationController),
            _field('Gender', genderController),
            _field('Location', locationController),

            _sectionLabel('Looking For'),
            _choiceChipGroup(
              options: _lookingForOptions,
              selected: selectedLookingFor,
            ),
            const SizedBox(height: 20),

            _sectionLabel('Interests'),
            _choiceChipGroup(
              options: _interestOptions,
              selected: selectedInterests,
            ),
            const SizedBox(height: 20),

            _sectionLabel('Relationship Status'),
            _singleChoiceGroup(
              options: _relationshipOptions,
              selectedValue: relationshipStatus,
              onSelect: (v) => setState(() => relationshipStatus = v),
            ),
            const SizedBox(height: 20),

            _sectionLabel('Smoking'),
            _singleChoiceGroup(
              options: _smokingOptions,
              selectedValue: smokingStatus,
              onSelect: (v) => setState(() => smokingStatus = v),
            ),
            const SizedBox(height: 20),

            _sectionLabel('Drinking'),
            _singleChoiceGroup(
              options: _drinkingOptions,
              selectedValue: drinkingStatus,
              onSelect: (v) => setState(() => drinkingStatus = v),
            ),
            const SizedBox(height: 20),

            _sectionLabel('Pride'),
            _singleChoiceGroup(
              options: _prideOptions,
              selectedValue: prideStatus,
              onSelect: (v) => setState(() => prideStatus = v),
            ),
            const SizedBox(height: 24),

            _sectionLabel('My Photos'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 0; i < existingPhotoUrls.length; i++)
                  _photoThumb(
                    image: Image.network(
                      existingPhotoUrls[i],
                      fit: BoxFit.cover,
                    ),
                    onRemove: () => removeExistingPhoto(i),
                  ),
                for (int i = 0; i < newPhotoFiles.length; i++)
                  _photoThumb(
                    image: Image.file(newPhotoFiles[i], fit: BoxFit.cover),
                    onRemove: () => removeNewPhoto(i),
                  ),
                GestureDetector(
                  onTap: pickPhotos,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: FC.border.withValues(alpha: 0.7),
                      ),
                      color: FC.card,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: FC.textLo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _sectionLabel('Verification'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FC.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isIdVerified
                      ? Colors.greenAccent.withValues(alpha: 0.4)
                      : FC.border.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isIdVerified ? Icons.verified : Icons.badge_outlined,
                    color: isIdVerified
                        ? Colors.greenAccent.shade400
                        : FC.textMid,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isIdVerified ? 'ID Verified' : 'Verify your ID',
                          style: const TextStyle(
                            color: FC.textHi,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        if (!isIdVerified)
                          const Text(
                            'Builds trust with matches',
                            style: TextStyle(color: FC.textLo, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  if (!isIdVerified)
                    TextButton(
                      onPressed: isUploadingId ? null : uploadIdDocument,
                      child: isUploadingId
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: FC.primary,
                              ),
                            )
                          : const Text(
                              'Upload',
                              style: TextStyle(
                                color: FC.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FC.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : const Text(
                        'Save Profile',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
