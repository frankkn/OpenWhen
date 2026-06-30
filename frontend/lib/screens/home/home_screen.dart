import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openwhen/models/capsule.dart';
import 'package:openwhen/providers/capsule_provider.dart';
import 'package:openwhen/services/api_service.dart';
import 'package:openwhen/services/auth_service.dart';
import 'package:openwhen/theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // 每秒重建畫面，讓倒數文字與「可以開封」狀態隨時間自動更新，
    // 不需使用者手動重新整理。（isOpenable 為純前端時間比較，無需重打 API）
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _openSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paperWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.warmGray.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('版本'),
                trailing: Text(const String.fromEnvironment('APP_VERSION', defaultValue: 'dev'),
                    style: TextStyle(color: AppColors.warmGray, fontSize: 14)),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('使用說明'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/instructions');
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              if (FirebaseAuth.instance.currentUser?.email == 'admin@admin.com') ...[
                ListTile(
                  leading: const Icon(Icons.mark_email_read_outlined),
                  title: const Text('立即檢查到期通知（測試）'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    try {
                      final r = await ApiService().checkNotifications();
                      messenger.showSnackBar(SnackBar(
                        content: Text('已檢查：寄出 ${r['sent']} 封，失敗 ${r['failed']} 封'),
                      ));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('檢查失敗：$e')));
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
              ],
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red.shade400),
                title: Text('登出', style: TextStyle(color: Colors.red.shade400)),
                onTap: () async {
                  Navigator.pop(context);
                  ref.invalidate(capsulesProvider);
                  await AuthService.signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final capsulesAsync = ref.watch(capsulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenWhen'),
        backgroundColor: AppColors.paperWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              ref.invalidate(capsulesProvider);
              await AuthService.signOut();
            },
          ),
        ],
      ),
      body: capsulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗：$e')),
        data: (capsules) => capsules.isEmpty
            ? _EmptyState(onCreateTap: () => context.push('/capsule/new'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: capsules.length,
                itemBuilder: (context, i) => _CapsuleCard(
                  capsule: capsules[i],
                  onTap: () => context.push('/capsule/${capsules[i].id}'),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/capsule/new'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note),
        label: const Text('寫信'),
      ),
    );
  }
}

class _CapsuleCard extends StatelessWidget {
  const _CapsuleCard({required this.capsule, required this.onTap});
  final Capsule capsule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy年MM月dd日 HH:mm');
    final isOpened = capsule.status == CapsuleStatus.opened;

    return Card(
      color: AppColors.paperWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.warmBrown.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(4),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(
                isOpened ? Icons.lock_open : Icons.lock_outline,
                size: 16,
                color: isOpened ? AppColors.warmBrown : AppColors.forestGreen,
              ),
              const SizedBox(width: 8),
              Text(
                isOpened ? '已開封' : '待開封',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isOpened ? AppColors.warmBrown : AppColors.forestGreen,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                capsule.mode == CapsuleMode.aiAssisted ? 'AI 協助' : '自由書寫',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.warmGray, fontSize: 12),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              capsule.displayTitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              isOpened
                  ? '已於 ${capsule.openedAt != null ? fmt.format(capsule.openedAt!) : fmt.format(capsule.openDate)} 開封'
                  : !capsule.isOpenable
                      ? '${capsule.remainingText}（${fmt.format(capsule.openDate)}）'
                      : '可以開封了！',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.warmGray),
            ),
          ]),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTap});
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 64, color: AppColors.warmGray.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('還沒有信件', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.warmGray)),
          const SizedBox(height: 8),
          Text('寫一封信給未來的自己吧', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.warmGray)),
          const SizedBox(height: 24),
          FilledButton(onPressed: onCreateTap, child: const Text('開始寫信')),
        ],
      ),
    );
  }
}
