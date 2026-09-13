import 'dart:async';
import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_format.dart';
import '../../models/category_model.dart';
import '../../providers/session_provider.dart';
import '../../services/ai_service.dart';
import '../../core/messaging/app_messenger.dart';
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
  Timer? _clockTimer;
  bool _timeWasChosen = false;

  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _timeWasChosen || !_isToday(_date)) return;
      final now = TimeOfDay.now();
      if (_time.hour != now.hour || _time.minute != now.minute) {
        setState(() => _time = now);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _clockTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: todayOnly,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    final pickedToday =
        picked.year == today.year &&
        picked.month == today.month &&
        picked.day == today.day;
    setState(() {
      _date = picked;
      if (pickedToday && !_timeWasChosen) {
        _time = TimeOfDay.now();
      }
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: force24HourTimePicker,
    );
    if (picked == null) return;

    final now = DateTime.now();
    final pickedToday =
        _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
    if (pickedToday && _timeIsBeforeNow(picked)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('L’heure ne peut pas être antérieure à maintenant.'),
          ),
        );
      }
      return;
    }
    setState(() {
      _time = picked;
      _timeWasChosen = true;
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _timeIsBeforeNow(TimeOfDay time) {
    final now = TimeOfDay.now();
    return time.hour * 60 + time.minute < now.hour * 60 + now.minute;
  }

  /// Analyse distante déclenchée après une pause de frappe pour éviter
  /// d'envoyer une requête Gemini à chaque caractère.
  void _onTextChanged() {
    _debounce?.cancel();
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      setState(() {
        _category = 'others';
        _isDetecting = false;
      });
      return;
    }
    setState(() => _isDetecting = true);
    _debounce = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      final title = _titleController.text;
      final content = _contentController.text;
      final provider = context.read<SessionProvider>();
      final result = await provider.analyzeDraft(
        title: title,
        content: content,
      );
      if (!mounted ||
          title != _titleController.text ||
          content != _contentController.text) {
        return;
      }
      setState(() {
        _category =
            result?['category'] as String? ??
            AiService.suggestCategory(title, content);
        _isDetecting = false;
      });
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    if (!_timeWasChosen && _isToday(_date)) {
      _time = TimeOfDay.fromDateTime(now);
    }
    final selectedDateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    if (selectedDateTime.isBefore(now)) {
      showAppMessage(
        'La date et l’heure doivent être maintenant ou dans le futur.',
      );
      return;
    }
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
      time: formatTime24(_time),
      content: _contentController.text.trim(),
      tags: tags,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      Navigator.of(context).pop();
    } else {
      showAppMessage(
        provider.errorMessage ?? 'Impossible de contacter le serveur',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Add Session',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _saving
                        ? const SizedBox(
                            key: ValueKey('saving'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.check_rounded,
                            key: ValueKey('check'),
                            size: 20,
                          ),
                  ),
                  onPressed: _saving ? null : _save,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            _sectionLabel('Title'),
            const SizedBox(height: 8),
            _card(
              child: TextFormField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: 'Enter title',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (_) => _onTextChanged(),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
              ),
            ),
            const SizedBox(height: 20),

            // Catégorie détectée automatiquement — jamais choisie par
            // l'utilisateur, avec un badge animé (fondu + léger scale).
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Catégorie détectée par l\'IA',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                const SizedBox(width: 8),
                AnimatedOpacity(
                  opacity: _isDetecting ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.035),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: CategoryBadge(
                    key: ValueKey(_category),
                    category: CategoryModel.byId(_category),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Date'),
                      const SizedBox(height: 8),
                      _card(
                        onTap: _pickDate,
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_date),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
                      _sectionLabel('Time'),
                      const SizedBox(height: 8),
                      _card(
                        onTap: _pickTime,
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                formatTime24(_time),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Un rappel sera envoyé automatiquement à la date et à l’heure choisies.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _sectionLabel('Content'),
            const SizedBox(height: 8),
            _card(
              child: TextFormField(
                controller: _contentController,
                maxLines: 6,
                style: const TextStyle(fontSize: 14.5, height: 1.4),
                decoration: const InputDecoration(
                  hintText: 'Write your notes here...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (_) => _onTextChanged(),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Contenu requis' : null,
              ),
            ),
            const SizedBox(height: 20),

            _sectionLabel('Tags/Keywords'),
            const SizedBox(height: 8),
            _card(
              child: TextFormField(
                controller: _tagsController,
                style: const TextStyle(fontSize: 14.5),
                decoration: const InputDecoration(
                  hintText: 'e.g. flutter, android, development',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13.5,
        letterSpacing: -0.1,
      ),
    );
  }

  /// Carte "input" au style unifié : fond blanc, ombre douce, coins arrondis.
  /// Si [onTap] est fourni, la carte devient tappable (ex : date/heure).
  Widget _card({required Widget child, VoidCallback? onTap}) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
