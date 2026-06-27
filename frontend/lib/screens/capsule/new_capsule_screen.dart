import 'package:flutter/material.dart';
import 'package:openwhen/screens/capsule/write_free_screen.dart';
import 'package:openwhen/screens/capsule/write_ai_screen.dart';
import 'package:openwhen/theme/app_theme.dart';

class NewCapsuleScreen extends StatelessWidget {
  const NewCapsuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('寫一封信'), backgroundColor: AppColors.paperWhite),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text('選擇書寫模式', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            Text('你想怎麼寫這封信？', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.warmGray)),
            const SizedBox(height: 40),
            _ModeCard(
              icon: Icons.edit_note,
              title: '自由模式',
              description: '直接書寫，完全自由\n沒有引導，只有你和這封信',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WriteFreeScreen())),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              icon: Icons.psychology_outlined,
              title: 'AI 協助模式',
              description: 'AI 帶你走過 9 個問題\n幫你挖掘當下最真實的自己',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WriteAiScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.icon, required this.title, required this.description, required this.onTap});
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.paperWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.warmBrown.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(children: [
            Icon(icon, size: 36, color: AppColors.forestGreen),
            const SizedBox(width: 20),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.warmGray)),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ]),
        ),
      ),
    );
  }
}
