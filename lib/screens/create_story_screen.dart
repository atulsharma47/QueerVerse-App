import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../services/story_service.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  Uint8List? _imageBytes;
  bool _uploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _imageBytes = bytes);
  }

  Future<void> _postStory() async {
    if (_imageBytes == null) return;
    setState(() => _uploading = true);

    try {
      final url = await CloudinaryService.uploadImageBytes(_imageBytes!);
      if (url == null) throw Exception('Upload failed');

      final user = FirebaseAuth.instance.currentUser;
      await StoryService.createStory(
        userId: user?.uid ?? '',
        userName: user?.displayName ?? 'User',
        imageUrl: url,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not post story: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('New Story'),
        actions: [
          if (_imageBytes != null)
            TextButton(
              onPressed: _uploading ? null : _postStory,
              child: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: Center(
        child: _imageBytes == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  const Text(
                    'Choose from gallery',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  const Text(
                    'Take a photo',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              )
            : Image.memory(_imageBytes!, fit: BoxFit.contain),
      ),
    );
  }
}
