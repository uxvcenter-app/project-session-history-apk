import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_format.dart';
import '../../models/category_model.dart';
import '../../models/session_model.dart';
import '../../providers/session_provider.dart';

class EditSessionScreen extends StatefulWidget {
  final SessionModel session;
  const EditSessionScreen({super.key, required this.session});

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;

  late String _category;
  late DateTime _date;
  late TimeOfDay _time;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _titleController = TextEditingController(text: s.title);
    _contentController = TextEditingController(text: s.content);
    _tagsController = TextEditingController(text: s.tags.join(', '));
    _category = s.category;
    _date = s.date;
    _time = _parseStoredTime(s.time);
  }


  TimeOfDay _parseStoredTime(String value) {
    final raw = value.trim().toUpperCase();

    final twelveHour =
        RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(raw);
    if (twelveHour != null) {
      var hour = int.tryParse(twelveHour.group(1)!) ?? 0;
      final minute = int.tryParse(twelveHour.group(2)!) ?? 0;
      final period = twelveHour.group(3)!;
      if (period == 'AM' && hour == 12) hour = 0;
      if (period == 'PM' && hour != 12) hour += 12;
      return TimeOfDay(
        hour: hour.clamp(0, 23).toInt(),
        minute: minute.clamp(0, 59).toInt(),
      );
    }

    final twentyFourHour =
        RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw);
    if (twentyFourHour != null) {
      final hour = int.tryParse(twentyFourHour.group(1)!) ?? 0;
      final minute = int.tryParse(twentyFourHour.group(2)!) ?? 0;
      return TimeOfDay(
        hour: hour.clamp(0, 23).toInt(),
        minute: minute.clamp(0, 59).toInt(),
      );
    }

    return TimeOfDay.now();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: force24HourTimePicker,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final updated = widget.session.copyWith(
      title: _titleController.text.trim(),
      category: _category,
      date: _date,
      time: formatTime24(_time),
      content: _contentController.text.trim(),
      tags: tags,
    );

    final provider = context.read<SessionProvider>();
    final success = await provider.updateSession(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Impossible de contacter le serveur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Session'),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
            ),
            const SizedBox(height: 18),

            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: CategoryModel.defaults
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Row(children: [
                          Icon(c.icon, color: c.color, size: 18),
                          const SizedBox(width: 8),
                          Text(c.name),
                        ]),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Text(DateFormat('dd/MM/yyyy').format(_date)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Time', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Text(formatTime24(_time)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            const Text('Content', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contentController,
              maxLines: 6,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Contenu requis' : null,
            ),
            const SizedBox(height: 18),

            const Text('Tags/Keywords (comma separated)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(controller: _tagsController),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
