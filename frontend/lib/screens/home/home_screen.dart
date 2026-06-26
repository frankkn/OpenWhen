import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openwhen/models/capsule.dart';
import 'package:openwhen/providers/capsule_provider.dart';
import 'package:openwhen/services/auth_service.dart';
import 'package:openwhen/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capsulesAsync = ref.watch(capsulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenWhen'),
        backgroundColor: AppColors.paperWhite,
        actions: [
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
        side: BorderSide(color: AppColors.warmBrown.withOpacity(0.2)),
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
              capsule.title ?? '無標題',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              isOpened
                  ? '已於 ${capsule.openedAt != null ? fmt.format(capsule.openedAt!) : fmt.format(capsule.openDate)} 開封'
                  : !capsule.isOpenable
                      ? '${capsule.daysUntilOpen} 天後可開封（${fmt.format(capsule.openDate)}）'
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
          Icon(Icons.mail_outline, size: 64, color: AppColors.warmGray.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('還沒有膠囊', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.warmGray)),
          const SizedBox(height: 8),
          Text('寫一封信給未來的自己吧', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.warmGray)),
          const SizedBox(height: 24),
          FilledButton(onPressed: onCreateTap, child: const Text('開始寫信')),
        ],
      ),
    );
  }
}
