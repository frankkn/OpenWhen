import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  List<Reflection>? _reflections;
  List<TextEditingController>? _reflectionControllers;

  Future<void> _openCapsule() async {
    setState(() => _opening = true);
    try {
      await ApiService().openCapsule(widget.capsuleId);
      // 開封後生成反思問題
      final capsule = await ApiService().getCapsule(widget.capsuleId);
      final questions = await ApiService().generateReflections(capsule.content);
      setState(() {
        _reflections = questions.map((q) => Reflection(questionText: q)).toList();
        _reflectionControllers = questions.map((_) => TextEditingController()).toList();
      });
      ref.invalidate(capsuleDetailProvider(widget.capsuleId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('開封失敗：$e')));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _saveReflections(Capsule capsule) async {
    final updated = List.generate(
      _reflections!.length,
      (i) => _reflections![i].copyWith(answerText: _reflectionControllers![i].text.trim()),
    );
    await ApiService().saveReflections(capsule.id, updated);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('反思已儲存')));
  }

  @override
  Widget build(BuildContext context) {
    final capsuleAsync = ref.watch(capsuleDetailProvider(widget.capsuleId));
    final fmt = DateFormat('yyyy年MM月dd日');

    return Scaffold(
      appBar: AppBar(title: const Text('膠囊詳情'), backgroundColor: AppColors.paperWhite),
      body: capsuleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗：$e')),
        data: (capsule) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _MetaRow(label: '建立於', value: fmt.format(capsule.createdAt)),
            _MetaRow(label: '開封日', value: fmt.format(capsule.openDate)),
            _MetaRow(
              label: '狀態',
              value: capsule.status == CapsuleStatus.opened ? '已開封' : '待開封',
            ),
            const SizedBox(height: 32),
            if (capsule.status == CapsuleStatus.locked) ...[
              if (capsule.isOpenable)
                FilledButton(
                  onPressed: _opening ? null : _openCapsule,
                  child: _opening
                      ? const CircularProgressIndicator()
                      : const Text('開封這封信'),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.paperWhite,
                    border: Border.all(color: AppColors.warmBrown.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '還有 ${capsule.daysUntilOpen} 天才能打開',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.forestGreen),
                  ),
                ),
            ],
            if (capsule.status == CapsuleStatus.opened) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.paperWhite,
                  border: Border.all(color: AppColors.warmBrown.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  capsule.content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 2.0),
                ),
              ),
              if (_reflections != null) ...[
                const SizedBox(height: 32),
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
                        Text(_reflections![i].questionText, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
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
              ],
            ],
          ]),
        ),
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
