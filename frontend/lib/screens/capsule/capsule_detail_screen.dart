import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openwhen/models/capsule.dart';
import 'package:openwhen/providers/capsule_provider.dart';
import 'package:openwhen/services/api_service.dart';
import 'package:openwhen/theme/app_theme.dart';

class CapsuleDetailScreen extends ConsumerStatefulWidget {
  const CapsuleDetailScreen({super.key, required this.capsuleId});
  final String capsuleId;

  @override
  ConsumerState<CapsuleDetailScreen> createState() => _CapsuleDetailScreenState();
}

class _CapsuleDetailScreenState extends ConsumerState<CapsuleDetailScreen> {
  bool _opening = false;
  bool _generating = false;
  bool _deleting = false;
  List<Reflection>? _reflections;
  List<TextEditingController>? _reflectionControllers;

  @override
  void dispose() {
    _reflectionControllers?.forEach((c) => c.dispose());
    super.dispose();
  }

  void _initReflectionsFromCapsule(Capsule capsule) {
    if (_reflections != null) return;
    if (capsule.status == CapsuleStatus.opened && capsule.reflections.isNotEmpty) {
      _reflections = List.of(capsule.reflections);
      _reflectionControllers = capsule.reflections
          .map((r) => TextEditingController(text: r.answerText ?? ''))
          .toList();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除膠囊'),
        content: const Text('刪除後無法復原，確定要刪除這個膠囊嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ApiService().deleteCapsule(widget.capsuleId);
      if (!mounted) return;
      ref.invalidate(capsulesProvider);
      context.go('/');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('刪除失敗：$e')));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _openCapsule() async {
    setState(() => _opening = true);
    try {
      await ApiService().openCapsule(widget.capsuleId);
      ref.invalidate(capsuleDetailProvider(widget.capsuleId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('開封失敗：$e')));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _generateReflections(String content) async {
    setState(() => _generating = true);
    try {
      final questions = await ApiService().generateReflections(content);
      setState(() {
        _reflections = questions.map((q) => Reflection(questionText: q)).toList();
        _reflectionControllers = questions.map((_) => TextEditingController()).toList();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('生成失敗：$e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _saveReflections(Capsule capsule) async {
    final updated = List.generate(
      _reflections!.length,
      (i) => _reflections![i].copyWith(answerText: _reflectionControllers![i].text.trim()),
    );
    try {
      await ApiService().saveReflections(capsule.id, updated);
      ref.invalidate(capsuleDetailProvider(widget.capsuleId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('反思已儲存')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('儲存失敗：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final capsuleAsync = ref.watch(capsuleDetailProvider(widget.capsuleId));
    final fmt = DateFormat('yyyy年MM月dd日 HH:mm');

    ref.listen(capsuleDetailProvider(widget.capsuleId), (_, next) {
      next.whenData(_initReflectionsFromCapsule);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('膠囊詳情'),
        backgroundColor: AppColors.paperWhite,
        actions: [
          IconButton(
            icon: _deleting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_outline),
            onPressed: _deleting ? null : _confirmDelete,
            color: Colors.red.shade400,
          ),
        ],
      ),
      body: capsuleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗：$e')),
        data: (capsule) {
          _initReflectionsFromCapsule(capsule);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _MetaRow(label: '建立於', value: fmt.format(capsule.createdAt)),
              _MetaRow(label: '開封日', value: fmt.format(capsule.openDate)),
              _MetaRow(
                label: '狀態',
                value: capsule.status == CapsuleStatus.opened ? '已開封' : '待開封',
              ),
              const SizedBox(height: 32),

              // Locked — not yet openable
              if (capsule.status == CapsuleStatus.locked && !capsule.isOpenable)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.paperWhite,
                    border: Border.all(color: AppColors.warmBrown.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '還有 ${capsule.daysUntilOpen} 天才能打開',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.forestGreen),
                  ),
                ),

              // Locked — ready to open
              if (capsule.status == CapsuleStatus.locked && capsule.isOpenable)
                FilledButton(
                  onPressed: _opening ? null : _openCapsule,
                  child: _opening
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('開封這封信'),
                ),

              // Opened — show letter
              if (capsule.status == CapsuleStatus.opened) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.paperWhite,
                    border: Border.all(color: AppColors.warmBrown.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    capsule.content ?? '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 2.0),
                  ),
                ),
                const SizedBox(height: 32),

                // Reflections
                if (_reflections != null) ...[
                  Text(
                    'AI 見證者的問題',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.forestGreen,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_reflections!.length, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Text(
                            _reflections![i].questionText,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _reflectionControllers![i],
                            maxLines: 3,
                            decoration: const InputDecoration(hintText: '你的回答（選填）'),
                          ),
                        ]),
                      )),
                  FilledButton(
                    onPressed: () => _saveReflections(capsule),
                    child: const Text('儲存反思'),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: _generating ? null : () => _generateReflections(capsule.content ?? ''),
                    icon: _generating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome, size: 16),
                    label: Text(_generating ? '生成中…' : '產生 AI 反思問題'),
                  ),
                ],
              ],
            ]),
          );
        },
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 72,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.warmGray)),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ]),
    );
  }
}
