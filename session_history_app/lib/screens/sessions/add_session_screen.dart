import 'dart:async';
import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/category_model.dart';
import '../../providers/session_provider.dart';
import '../../services/ai_service.dart';
import '../../widgets/category_badge.dart';

/// Écran d'ajout de session avec classification IA 100% automatique :
/// l'utilisateur ne choisit jamais lui-même la catégorie, elle est détectée
/// en direct à partir du titre/contenu (avec un léger délai de "réflexion"
/// pour un effet naturel), et affichée sous forme de badge animé.
class AddSessionScreen extends StatefulWidget {
  const AddSessionScreen({super.key});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();

  String _category = 'others';
  bool _isDetecting = false;
  Timer? _debounce;

  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _saving = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
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
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  /// Détection automatique déclenchée à chaque frappe, avec un petit délai
  /// (debounce) pour ne pas relancer le calcul à chaque caractère et
  /// donner une sensation naturelle d'"analyse" (visible via _isDetecting).
  void _onTextChanged() {
    _debounce?.cancel();
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
      setState(() {
        _category = 'others';
        _isDetecting = false;
      });
      return;
    }
    setState(() => _isDetecting = true);
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final suggestion = AiService.suggestCategory(_titleController.text, _contentController.text);
      setState(() {
        _category = suggestion;
        _isDetecting = false;
      });
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final provider = context.read<SessionProvider>();
    final success = await provider.addSession(
          title: _titleController.text.trim(),
          category: _category,
          date: _date,
          time: _time.format(context),
          content: _contentController.text.trim(),
          tags: tags,
        );

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
        title: const Text('Add Session'),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _saving
                  ? const SizedBox(
                      key: ValueKey('saving'),
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check, key: ValueKey('check')),
            ),
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
              decoration: const InputDecoration(hintText: 'Enter title'),
              onChanged: (_) => _onTextChanged(),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
            ),
            const SizedBox(height: 18),

            // Catégorie détectée automatiquement — jamais choisie par
            // l'utilisateur, avec un badge animé (fondu + léger scale).
            Row(
              children: [
                const Text('Catégorie détectée par l\'IA',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                AnimatedOpacity(
                  opacity: _isDetecting ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: CategoryBadge(
                key: ValueKey(_category),
                category: CategoryModel.byId(_category),
              ),
            ),
            const SizedBox(height: 20),

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
                          child: Text(_time.format(context)),
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
              decoration: const InputDecoration(hintText: 'Write your notes here...'),
              onChanged: (_) => _onTextChanged(),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Contenu requis' : null,
            ),
            const SizedBox(height: 18),

            const Text('Tags/Keywords (comma separated)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(hintText: 'e.g. flutter, android, development'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
