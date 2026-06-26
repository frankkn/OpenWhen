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
  final _emailCtrl = TextEditingController();
  bool _saving = false;

  // 預設快速選項
  static final _presets = [
    ('3 個月後', Duration(days: 90)),
    ('半年後', Duration(days: 180)),
    ('1 年後', Duration(days: 365)),
    ('3 年後', Duration(days: 365 * 3)),
  ];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 90)),
      firstDate: now.add(const Duration(days: 90)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _openDate = picked);
  }

  Future<void> _save() async {
    if (_openDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請先選擇開封日期')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService().createCapsule(
        title: widget.title,
        content: widget.content,
        mode: widget.mode,
        openDate: _openDate!,
        notificationEmail: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        answers: widget.answers,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('膠囊已封存！')));
      context.go('/');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('儲存失敗：$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定開封日期'), backgroundColor: AppColors.paperWhite),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('什麼時候打開這封信？', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('最短 3 個月，最長 10 年', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.warmGray)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets.map((p) {
              final date = DateTime.now().add(p.$2);
              final selected = _openDate?.year == date.year &&
                  _openDate?.month == date.month &&
                  _openDate?.day == date.day;
              return ChoiceChip(
                label: Text(p.$1),
                selected: selected,
                onSelected: (_) => setState(() => _openDate = date),
                selectedColor: AppColors.forestGreen.withOpacity(0.15),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(_openDate != null
                ? '${_openDate!.year}年${_openDate!.month}月${_openDate!.day}日'
                : '自訂日期'),
          ),
          const SizedBox(height: 32),
          Text('通知 Email（選填）', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('到期時寄通知給這個 email', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.warmGray)),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'your@email.com'),
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const CircularProgressIndicator() : const Text('封存這封信'),
          ),
        ]),
      ),
    );
  }
}
