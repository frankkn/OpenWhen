import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openwhen/services/api_service.dart';
import 'package:openwhen/theme/app_theme.dart';

class SetOpenDateScreen extends StatefulWidget {
  const SetOpenDateScreen({
    super.key,
    required this.title,
    required this.content,
    required this.mode,
    required this.answers,
  });

  final String? title;
  final String content;
  final String mode;
  final List<Map<String, dynamic>> answers;

  @override
  State<SetOpenDateScreen> createState() => _SetOpenDateScreenState();
}

class _SetOpenDateScreenState extends State<SetOpenDateScreen> {
  DateTime? _openDate;
  TimeOfDay _openTime = const TimeOfDay(hour: 8, minute: 0);
  bool _sendEmail = false;
  bool _useLoginEmail = true;
  final _customEmailCtrl = TextEditingController();
  bool _saving = false;

  String? get _loginEmail => FirebaseAuth.instance.currentUser?.email;

  String? get _notificationEmail {
    if (!_sendEmail) return null;
    if (_useLoginEmail) return _loginEmail;
    final v = _customEmailCtrl.text.trim();
    return v.isEmpty ? null : v;
  }

  @override
  void dispose() {
    _customEmailCtrl.dispose();
    super.dispose();
  }

  bool get _isAdmin =>
      FirebaseAuth.instance.currentUser?.email == 'admin@admin.com';

  List<(String, Duration)> get _presets => _isAdmin
      ? [
          ('20 秒後', const Duration(seconds: 20)),
          ('1 分鐘後', const Duration(minutes: 1)),
          ('1 小時後', const Duration(hours: 1)),
          ('1 天後', const Duration(days: 1)),
          ('1 週後', const Duration(days: 7)),
        ]
      : [
          ('1 個月後', const Duration(days: 30)),
          ('3 個月後', const Duration(days: 90)),
          ('1 年後', const Duration(days: 365)),
          ('3 年後', const Duration(days: 365 * 3)),
        ];

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initialDate = _isAdmin
        ? now.add(const Duration(days: 1))
        : now.add(const Duration(days: 30));
    final firstDate = _isAdmin
        ? DateTime(1900)
        : now.add(const Duration(days: 30));
    final lastDate = _isAdmin
        ? DateTime(9999)
        : now.add(const Duration(days: 365 * 100));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _openTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _openTime = pickedTime;
      _openDate = DateTime(
        picked.year, picked.month, picked.day,
        pickedTime.hour, pickedTime.minute,
      );
    });
  }

  DateTime _presetDateTime(Duration offset) => DateTime.now().add(offset);

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}年${dt.month}月${dt.day}日 $h:$m';
  }

  Future<void> _save() async {
    if (_openDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先選擇開封日期')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService().createCapsule(
        title: widget.title,
        content: widget.content,
        mode: widget.mode,
        openDate: _openDate!,
        notificationEmail: _notificationEmail,
        answers: widget.answers,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('膠囊已封存！')),
      );
      context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定開封日期'),
        backgroundColor: AppColors.paperWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '什麼時候打開這封信？',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _isAdmin ? '🔑 管理員模式：可設定任意時間' : '最短 1 個月，最長 100 年',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _isAdmin ? AppColors.forestGreen : AppColors.warmGray,
                  ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((p) {
                final date = _presetDateTime(p.$2);
                final selected = _openDate != null &&
                    _openDate!.year == date.year &&
                    _openDate!.month == date.month &&
                    _openDate!.day == date.day;
                return ChoiceChip(
                  label: Text(p.$1),
                  selected: selected,
                  onSelected: (_) => setState(() => _openDate = date),
                  selectedColor: AppColors.forestGreen.withValues(alpha: 0.15),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                _openDate != null ? _formatDateTime(_openDate!) : '自訂日期與時間',
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '到期時寄 Email 通知',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: _sendEmail,
                  // ignore: deprecated_member_use
                  activeColor: AppColors.forestGreen,
                  onChanged: (v) => setState(() => _sendEmail = v),
                ),
              ],
            ),
            if (_sendEmail) ...[
              const SizedBox(height: 12),
              // ignore: deprecated_member_use
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.forestGreen,
                title: Text('使用登入的 Email'),
                subtitle: Text(_loginEmail ?? '', style: TextStyle(color: AppColors.warmGray, fontSize: 13)),
                value: true,
                // ignore: deprecated_member_use
                groupValue: _useLoginEmail,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _useLoginEmail = v!),
              ),
              // ignore: deprecated_member_use
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.forestGreen,
                title: const Text('使用其他 Email'),
                value: false,
                // ignore: deprecated_member_use
                groupValue: _useLoginEmail,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _useLoginEmail = v!),
              ),
              if (!_useLoginEmail) ...[
                const SizedBox(height: 4),
                TextField(
                  controller: _customEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'your@email.com'),
                ),
              ],
            ],
            const SizedBox(height: 48),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('封存這封信'),
            ),
          ],
        ),
      ),
    );
  }
}
