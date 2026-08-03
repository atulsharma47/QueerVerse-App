import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/event_service.dart';
import '../themes/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/events/join_celebration_overlay.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    setState(() {
      _selectedDate = pickedDate;
      _selectedTime = pickedTime;
    });
  }

  Future<void> _createEvent() async {
    if (_titleController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in every field')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final eventDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    await EventService.createEvent(
      title: _titleController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      eventDate: eventDateTime,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    // Go back to the previous screen first.
    Navigator.pop(context);

    // Wait until the previous screen is visible.
    await Future.delayed(const Duration(milliseconds: 250));

    // Show the celebration on top of the existing screen.
    showJoinCelebration(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
        suffixIcon: icon != null
            ? Icon(icon, color: AppColors.textSecondary, size: 20)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = (_selectedDate == null || _selectedTime == null)
        ? 'Select Event Date & Time'
        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} • ${_selectedTime!.format(context)}';

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 100, 18, 32),
            child: Column(
              children: [
                GlassCard(
                  child: Column(
                    children: [
                      _field(
                        controller: _titleController,
                        label: 'Event Title',
                        icon: Icons.edit_outlined,
                      ),
                      const SizedBox(height: 15),
                      _field(
                        controller: _locationController,
                        label: 'Location',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 15),
                      _field(
                        controller: _descriptionController,
                        label: 'Description',
                        icon: Icons.edit_outlined,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 22),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Date & Time',
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _selectDateTime,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                color: AppColors.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  dateLabel,
                                  style: GoogleFonts.outfit(
                                    color: (_selectedDate == null)
                                        ? AppColors.hint
                                        : AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      GradientButton(
                        text: 'Create Event',
                        isLoading: _isLoading,
                        onPressed: _createEvent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
