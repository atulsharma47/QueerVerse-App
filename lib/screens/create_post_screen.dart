import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

import '../services/cloudinary_service.dart';
import '../services/post_service.dart';
import '../themes/app_colors.dart';
import '../widgets/gradient_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/feed/post_success_overlay.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _postController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _previewPlayer = AudioPlayer();

  static const int _maxChars = 500;

  bool _isLoading = false;
  bool _showSuccess = false;

  File? _selectedImage;
  File? _selectedVideo;

  String? _location;
  Map<String, String>? _mood; // {'emoji': '😄', 'label': 'Happy'}
  Map<String, dynamic>?
  _musicData; // {trackName, artistName, artworkUrl, previewUrl}
  String _visibility = 'public';

  String? _pollQuestion;
  List<String>? _pollOptions;

  Map<String, dynamic>? _event; // {title, dateTime, location}

  static const List<Map<String, String>> _moods = [
    {'emoji': '😄', 'label': 'Happy'},
    {'emoji': '🥰', 'label': 'Loved'},
    {'emoji': '😌', 'label': 'Peaceful'},
    {'emoji': '🔥', 'label': 'Hyped'},
    {'emoji': '🥳', 'label': 'Celebrating'},
    {'emoji': '😢', 'label': 'Sad'},
    {'emoji': '😴', 'label': 'Sleepy'},
    {'emoji': '💪', 'label': 'Strong'},
    {'emoji': '🌈', 'label': 'Proud'},
    {'emoji': '😤', 'label': 'Frustrated'},
    {'emoji': '🤔', 'label': 'Thoughtful'},
    {'emoji': '✨', 'label': 'Blessed'},
  ];

  static const List<String> _quickEmojis = [
    '😀',
    '😂',
    '🥰',
    '😎',
    '🥳',
    '😢',
    '😡',
    '🤔',
    '👍',
    '🙌',
    '🔥',
    '💯',
    '✨',
    '🌈',
    '🏳️‍🌈',
    '🏳️‍⚧️',
    '💜',
    '💗',
    '⭐',
    '🎉',
  ];

  @override
  void dispose() {
    _postController.dispose();
    _focusNode.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  void _insertAtCursor(String value) {
    final text = _postController.text;
    final selection = _postController.selection;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    final newText = text.replaceRange(start, end, value);
    _postController.text = newText;
    _postController.selection = TextSelection.collapsed(
      offset: start + value.length,
    );
    setState(() {});
  }

  List<String> _extractHashtags(String text) {
    final matches = RegExp(r'#(\w+)').allMatches(text);
    return matches.map((m) => m.group(1)!).toSet().toList();
  }

  // ---------------------------------------------------------------------
  // Media pickers
  // ---------------------------------------------------------------------

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _selectedVideo = null; // photo & video are mutually exclusive
      });
    }
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedVideo = File(picked.path);
        _selectedImage = null;
      });
    }
  }

  // ---------------------------------------------------------------------
  // Bottom sheets
  // ---------------------------------------------------------------------

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: _quickEmojis.map((e) {
              return GestureDetector(
                onTap: () {
                  _insertAtCursor(e);
                  Navigator.pop(context);
                },
                child: Text(e, style: const TextStyle(fontSize: 28)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _showLocationSheet() async {
    final controller = TextEditingController(text: _location ?? '');
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetTitle('Add location'),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'e.g. San Francisco, CA',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 18),
            GradientButton(
              text: 'Save location',
              onPressed: () => Navigator.pop(context, controller.text.trim()),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      setState(() => _location = result.isEmpty ? null : result);
    }
  }

  Future<void> _showMoodSheet() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetTitle('How are you feeling?'),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _moods.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (context, i) {
                  final mood = _moods[i];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, mood),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.glass,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mood['emoji']!,
                            style: const TextStyle(fontSize: 26),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mood['label']!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) setState(() => _mood = result);
  }

  /// Real music search — hits the iTunes Search API (free, no auth) and
  /// lets the user preview a 30s clip before attaching a track.
  Future<void> _showMusicSheet() async {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool isSearching = false;
    String? previewingUrl;

    Future<void> runSearch(
      String query,
      void Function(void Function()) setSheetState,
    ) async {
      final q = query.trim();
      if (q.isEmpty) return;
      setSheetState(() => isSearching = true);
      try {
        final uri = Uri.https('itunes.apple.com', '/search', {
          'term': q,
          'media': 'music',
          'limit': '15',
        });
        final res = await http.get(uri);
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['results'] as List? ?? [])
            .map(
              (r) => {
                'trackName': r['trackName'] ?? '',
                'artistName': r['artistName'] ?? '',
                'artworkUrl': r['artworkUrl100'],
                'previewUrl': r['previewUrl'],
              },
            )
            .where((m) => (m['previewUrl'] as String?)?.isNotEmpty == true)
            .toList();
        setSheetState(() {
          results = list;
          isSearching = false;
        });
      } catch (_) {
        setSheetState(() => isSearching = false);
      }
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sheetTitle('Add music'),
                    const SizedBox(height: 14),
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search for a song or artist…',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      onSubmitted: (q) => runSearch(q, setSheetState),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: results.isEmpty
                          ? Center(
                              child: Text(
                                isSearching
                                    ? 'Searching…'
                                    : 'Search for a track to attach a 30s preview',
                                style: const TextStyle(color: Colors.white38),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (context, i) {
                                final track = results[i];
                                final url = track['previewUrl'] as String?;
                                final isPlaying = previewingUrl == url;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: track['artworkUrl'] != null
                                        ? Image.network(
                                            track['artworkUrl'],
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  width: 44,
                                                  height: 44,
                                                  color: AppColors.glass,
                                                  child: const Icon(
                                                    Icons.music_note,
                                                    color: Colors.white38,
                                                  ),
                                                ),
                                          )
                                        : Container(
                                            width: 44,
                                            height: 44,
                                            color: AppColors.glass,
                                            child: const Icon(
                                              Icons.music_note,
                                              color: Colors.white38,
                                            ),
                                          ),
                                  ),
                                  title: Text(
                                    track['trackName'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    track['artistName'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                      color: AppColors.secondary,
                                      size: 32,
                                    ),
                                    onPressed: () async {
                                      if (url == null) return;
                                      if (isPlaying) {
                                        await _previewPlayer.stop();
                                        setSheetState(
                                          () => previewingUrl = null,
                                        );
                                      } else {
                                        await _previewPlayer.stop();
                                        await _previewPlayer.play(
                                          UrlSource(url),
                                        );
                                        setSheetState(
                                          () => previewingUrl = url,
                                        );
                                      }
                                    },
                                  ),
                                  onTap: () => Navigator.pop(context, track),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    await _previewPlayer.stop();

    if (result != null) {
      setState(() => _musicData = result);
    }
  }

  Future<void> _showPollSheet() async {
    final questionController = TextEditingController(text: _pollQuestion ?? '');
    final optionControllers = List.generate(
      4,
      (i) => TextEditingController(
        text: (_pollOptions != null && i < _pollOptions!.length)
            ? _pollOptions![i]
            : '',
      ),
    );
    int visibleOptions = _pollOptions?.length.clamp(2, 4) ?? 2;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sheetTitle('Create a poll'),
                    const SizedBox(height: 14),
                    TextField(
                      controller: questionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Ask a question…',
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (int i = 0; i < visibleOptions; i++) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                          controller: optionControllers[i],
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Option ${i + 1}',
                          ),
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        if (visibleOptions < 4)
                          TextButton.icon(
                            onPressed: () =>
                                setSheetState(() => visibleOptions++),
                            icon: const Icon(
                              Icons.add,
                              color: AppColors.secondary,
                            ),
                            label: const Text(
                              'Add option',
                              style: TextStyle(color: AppColors.secondary),
                            ),
                          ),
                        if (visibleOptions > 2)
                          TextButton.icon(
                            onPressed: () =>
                                setSheetState(() => visibleOptions--),
                            icon: const Icon(
                              Icons.remove,
                              color: Colors.white54,
                            ),
                            label: const Text(
                              'Remove',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GradientButton(
                      text: 'Save poll',
                      onPressed: () {
                        final opts = optionControllers
                            .take(visibleOptions)
                            .map((c) => c.text.trim())
                            .where((t) => t.isNotEmpty)
                            .toList();
                        if (questionController.text.trim().isEmpty ||
                            opts.length < 2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Add a question and at least 2 options',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context, {
                          'question': questionController.text.trim(),
                          'options': opts,
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _pollQuestion = result['question'] as String;
        _pollOptions = List<String>.from(result['options'] as List);
      });
    }
  }

  Future<void> _showEventSheet() async {
    final titleController = TextEditingController(
      text: _event?['title'] as String? ?? '',
    );
    final locationController = TextEditingController(
      text: _event?['location'] as String? ?? '',
    );
    DateTime? selectedDate = _event?['dateTime'] as DateTime?;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetTitle('Create an event'),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Event title'),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? now,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365 * 2)),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                          selectedDate ?? now,
                        ),
                      );
                      setSheetState(() {
                        selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time?.hour ?? 12,
                          time?.minute ?? 0,
                        );
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            selectedDate == null
                                ? 'Pick date & time'
                                : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} · '
                                      '${selectedDate!.hour.toString().padLeft(2, '0')}:${selectedDate!.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: locationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Event location',
                    ),
                  ),
                  const SizedBox(height: 18),
                  GradientButton(
                    text: 'Save event',
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Give your event a title'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context, {
                        'title': titleController.text.trim(),
                        'dateTime': selectedDate,
                        'location': locationController.text.trim(),
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) setState(() => _event = result);
  }

  Future<void> _showVisibilitySheet() async {
    final options = [
      {'value': 'public', 'label': 'Public', 'icon': Icons.public},
      {
        'value': 'followers',
        'label': 'Followers only',
        'icon': Icons.people_outline,
      },
      {'value': 'onlyMe', 'label': 'Only me', 'icon': Icons.lock_outline},
    ];
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((o) {
            return ListTile(
              leading: Icon(o['icon'] as IconData, color: Colors.white70),
              title: Text(
                o['label'] as String,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: _visibility == o['value']
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(context, o['value'] as String),
            );
          }).toList(),
        ),
      ),
    );
    if (result != null) setState(() => _visibility = result);
  }

  Widget _sheetTitle(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  );

  // ---------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------

  Future<void> _submitPost() async {
    final hasContent =
        _postController.text.trim().isNotEmpty ||
        _selectedImage != null ||
        _selectedVideo != null;
    if (!hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something or add media first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      String? videoUrl;

      if (_selectedImage != null) {
        imageUrl = await CloudinaryService.uploadImage(_selectedImage!);
      }
      if (_selectedVideo != null) {
        videoUrl = await CloudinaryService.uploadVideo(_selectedVideo!);
      }

      await PostService.createPost(
        text: _postController.text,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        location: _location,
        mood: _mood != null ? '${_mood!['emoji']} ${_mood!['label']}' : null,
        musicData: _musicData,
        hashtags: _extractHashtags(_postController.text),
        pollQuestion: _pollQuestion,
        pollOptions: _pollOptions,
        eventData: _event,
        visibility: _visibility,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _showSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _onSuccessDone() {
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final charCount = _postController.text.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _postController,
                                focusNode: _focusNode,
                                maxLines: 6,
                                maxLength: _maxChars,
                                onChanged: (_) => setState(() {}),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                decoration: const InputDecoration(
                                  hintText: "What's on your mind?",
                                  counterText: '',
                                  border: InputBorder.none,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: _showEmojiPicker,
                                        icon: const Icon(
                                          Icons.emoji_emotions_outlined,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _insertAtCursor('#'),
                                        icon: const Icon(
                                          Icons.tag,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _showLocationSheet,
                                        icon: Icon(
                                          Icons.location_on_outlined,
                                          color: _location != null
                                              ? AppColors.secondary
                                              : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '$charCount/$_maxChars',
                                    style: TextStyle(
                                      color: charCount > _maxChars - 30
                                          ? AppColors.danger
                                          : Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),
                        _buildChips(),

                        if (_selectedImage != null) ...[
                          const SizedBox(height: 14),
                          _buildImagePreview(),
                        ],
                        if (_selectedVideo != null) ...[
                          const SizedBox(height: 14),
                          _buildVideoPreview(),
                        ],
                        if (_pollOptions != null) ...[
                          const SizedBox(height: 14),
                          _buildPollPreview(),
                        ],
                        if (_event != null) ...[
                          const SizedBox(height: 14),
                          _buildEventPreview(),
                        ],

                        const SizedBox(height: 20),
                        Text(
                          'Add to your post',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAttachmentRow(),

                        const SizedBox(height: 24),
                        InkWell(
                          onTap: _showVisibilitySheet,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.glass,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.public,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _visibility == 'public'
                                      ? 'Public'
                                      : _visibility == 'followers'
                                      ? 'Followers only'
                                      : 'Only me',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white38,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),
                        GradientButton(
                          text: 'Post',
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _submitPost,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (_showSuccess)
              Positioned.fill(
                child: PostSuccessOverlay(onDone: _onSuccessDone),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              'QUEERVERSE',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips() {
    final chips = <Widget>[];

    if (_location != null) {
      chips.add(
        _chip(
          Icons.location_on,
          _location!,
          () => setState(() => _location = null),
        ),
      );
    }
    if (_mood != null) {
      chips.add(
        _chip(
          null,
          '${_mood!['emoji']} Feeling ${_mood!['label']}',
          () => setState(() => _mood = null),
        ),
      );
    }
    if (_musicData != null) {
      chips.add(
        _chip(
          Icons.music_note,
          '${_musicData!['trackName']} — ${_musicData!['artistName']}',
          () => setState(() => _musicData = null),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _chip(IconData? icon, String label, VoidCallback onRemove) {
    return Chip(
      backgroundColor: AppColors.glass,
      side: BorderSide(color: AppColors.border),
      avatar: icon != null
          ? Icon(icon, size: 16, color: AppColors.secondary)
          : null,
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white54),
      onDeleted: onRemove,
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.file(
            _selectedImage!,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _removeButton(() => setState(() => _selectedImage = null)),
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.videocam, color: AppColors.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedVideo!.path.split('/').last,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _removeButton(() => setState(() => _selectedVideo = null)),
        ),
      ],
    );
  }

  Widget _buildPollPreview() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _pollQuestion ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _removeButton(
                () => setState(() {
                  _pollQuestion = null;
                  _pollOptions = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...?_pollOptions?.map(
            (o) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(o, style: const TextStyle(color: Colors.white70)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventPreview() {
    final dt = _event?['dateTime'] as DateTime?;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.event, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _event?['title'] as String? ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (dt != null)
                  Text(
                    '${dt.day}/${dt.month}/${dt.year} · '
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                if ((_event?['location'] as String? ?? '').isNotEmpty)
                  Text(
                    _event!['location'] as String,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ),
          _removeButton(() => setState(() => _event = null)),
        ],
      ),
    );
  }

  Widget _removeButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildAttachmentRow() {
    final items = [
      {'icon': Icons.photo_outlined, 'label': 'Photo', 'onTap': _pickImage},
      {'icon': Icons.videocam_outlined, 'label': 'Video', 'onTap': _pickVideo},
      {
        'icon': Icons.music_note_outlined,
        'label': 'Music',
        'onTap': _showMusicSheet,
      },
      {'icon': Icons.poll_outlined, 'label': 'Poll', 'onTap': _showPollSheet},
      {
        'icon': Icons.emoji_emotions_outlined,
        'label': 'Feeling',
        'onTap': _showMoodSheet,
      },
      {
        'icon': Icons.event_outlined,
        'label': 'Event',
        'onTap': _showEventSheet,
      },
    ];

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          return GestureDetector(
            onTap: item['onTap'] as VoidCallback,
            child: Container(
              width: 74,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.glass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData, color: AppColors.secondary),
                  const SizedBox(height: 6),
                  Text(
                    item['label'] as String,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
