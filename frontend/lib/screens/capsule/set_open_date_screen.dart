import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openwhen/providers/capsule_provider.dart';
import 'package:openwhen/services/api_service.dart';
import 'package:openwhen/theme/app_theme.dart';

class SetOpenDateScreen extends ConsumerStatefulWidget {
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
  ConsumerState<SetOpenDateScreen> createState() => _SetOpenDateScreenState();
}

class _SetOpenDateScreenState extends ConsumerState<SetOpenDateScreen> {
  DateTime? _date; // 只存年月日；時間部分忽略
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0); // 預設早上 8:00
  bool _sendEmail = false;
  bool _useLoginEmail = true;
  final _customEmailCtrl = TextEditingController();
  late final TextEditingController _titleCtrl =
      TextEditingController(text: widget.title ?? '');
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
    _titleCtrl.dispose();
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
          ('1 天後', const Duration(days: 1)),
          ('1 週後', const Duration(days: 7)),
          ('1 個月後', const Duration(days: 30)),
          ('1 年後', const Duration(days: 365)),
          ('2 年後', const Duration(days: 365 * 2)),
          ('3 年後', const Duration(days: 365 * 3)),
          ('5 年後', const Duration(days: 365 * 5)),
        ];

  /// 合併日期與時間成最終開封時間；尚未選日期時為 null。
  DateTime? get _openDateTime {
    final d = _date;
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day, _time.hour, _time.minute);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _date ?? now.add(const Duration(days: 1));
    // 一般使用者可選任意未來時間（下限為今天），管理員不限
    final firstDate = _isAdmin
        ? DateTime(1900)
        : DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(9999),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
  }

  /// 套用快捷鈕。日級以上只設日期（時間維持預設/使用者選的）；
  /// 管理員測試用的秒/分/時級則連時間一起設成精確值。
  void _applyPreset(Duration offset) {
    final dt = DateTime.now().add(offset);
    setState(() {
      _date = DateTime(dt.year, dt.month, dt.day);
      if (offset < const Duration(days: 1)) {
        _time = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }
    });
  }

  String _formatDate(DateTime dt) => '${dt.year}年${dt.month}月${dt.day}日';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _weekday(DateTime dt) {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return '週${names[dt.weekday - 1]}';
  }

  Future<void> _save() async {
    final openDateTime = _openDateTime;
    if (openDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先選擇開封日期')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final titleInput = _titleCtrl.text.trim();
      await ApiService().createCapsule(
        title: titleInput.isEmpty ? null : titleInput,
        content: widget.content,
        mode: widget.mode,
        openDate: openDateTime,
        notificationEmail: _notificationEmail,
        answers: widget.answers,
      );
      if (!mounted) return;
      ref.invalidate(capsulesProvider); // 讓首頁重新抓列表，回去馬上看到新的信
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('信件已封存！')),
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
              _isAdmin ? '🔑 管理員模式：可設定任意時間' : '可設定任意未來時間',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _isAdmin ? AppColors.forestGreen : AppColors.warmGray,
                  ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((p) {
                final date = DateTime.now().add(p.$2);
                final selected = _date != null &&
                    _date!.year == date.year &&
                    _date!.month == date.month &&
                    _date!.day == date.day;
                return ChoiceChip(
                  label: Text(p.$1),
                  selected: selected,
                  // 再點一次已選取的快捷鈕 → 取消選取（清空日期）
                  onSelected: (_) =>
                      selected ? setState(() => _date = null) : _applyPreset(p.$2),
                  selectedColor: AppColors.forestGreen.withValues(alpha: 0.15),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_date != null ? _formatDate(_date!) : '選擇日期'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time, size: 16),
                    label: Text(_formatTime(_time)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _OpenDateSummary(
              openDateTime: _openDateTime,
              dateText: _openDateTime != null
                  ? '${_formatDate(_openDateTime!)}（${_weekday(_openDateTime!)}）'
                  : null,
              timeText: _formatTime(_time),
            ),
            const SizedBox(height: 32),
            Text(
              '需要給這封信一個標題嗎？（選填）',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: _date != null
                    ? '預設為「致 ${_date!.year}年${_date!.month}月${_date!.day}日 的我」'
                    : '預設依開封日期自動產生',
                hintStyle: TextStyle(color: AppColors.warmGray, fontSize: 13),
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

/// 開封時間的結果摘要卡：一眼看到信件會在何時開封。
class _OpenDateSummary extends StatelessWidget {
  const _OpenDateSummary({
    required this.openDateTime,
    required this.dateText,
    required this.timeText,
  });

  final DateTime? openDateTime;
  final String? dateText; // 已含星期，例如「2026年7月1日（週三）」
  final String timeText;

  @override
  Widget build(BuildContext context) {
    final ready = openDateTime != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: ready
            ? AppColors.forestGreen.withValues(alpha: 0.08)
            : AppColors.warmGray.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ready
              ? AppColors.forestGreen.withValues(alpha: 0.3)
              : AppColors.warmGray.withValues(alpha: 0.25),
        ),
      ),
      child: ready
          ? Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mail_outline, size: 16, color: AppColors.forestGreen),
                    const SizedBox(width: 6),
                    Text(
                      '這封信將於',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.forestGreen,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dateText!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestGreen,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeText,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestGreen,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '開封',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.forestGreen,
                      ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 16, color: AppColors.warmGray),
                const SizedBox(width: 8),
                Text(
                  '請選擇開封日期',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.warmGray,
                      ),
                ),
              ],
            ),
    );
  }
}
