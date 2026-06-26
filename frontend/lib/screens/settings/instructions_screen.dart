import 'package:flutter/material.dart';
import 'package:openwhen/theme/app_theme.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('使用說明'), backgroundColor: AppColors.paperWhite),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              title: '什麼是 OpenWhen？',
              content:
                  'OpenWhen 是一個時光膠囊信件 App。你可以寫一封信給未來的自己，等到設定的日期才能開封。開封時，AI 扮演溫柔的見證者，根據信的內容提問，幫你反思當年的自己。',
            ),
            const SizedBox(height: 28),
            _SectionTitle(text: '如何寫一封信'),
            const SizedBox(height: 12),
            _Step(
              number: '1',
              title: '選擇寫信方式',
              bullets: const [
                '自由書寫 — 直接輸入你想說的話',
                'AI 協助模式 — 回答 9 個引導問題，AI 幫你整理成一封完整的信',
              ],
            ),
            _Step(
              number: '2',
              title: '設定開封日期',
              bullets: const [
                '最短 1 個月後，最長 100 年後',
                '可使用快速預設，或手動選擇精確日期與時間',
                '可選填通知 Email，到期時寄信提醒你',
              ],
            ),
            _Step(
              number: '3',
              title: '封存信件',
              bullets: const [
                '按下「封存這封信」後，信件鎖定',
                '封存後無法修改內容或提前開封',
              ],
            ),
            const SizedBox(height: 28),
            _SectionTitle(text: '開封流程'),
            const SizedBox(height: 12),
            _Step(
              number: '1',
              title: '等待日期到來',
              bullets: const ['首頁列表會顯示「可以開封了！」'],
            ),
            _Step(
              number: '2',
              title: '開封信件',
              bullets: const [
                '點進膠囊詳情頁，按「開封這封信」',
                '信件全文會完整顯示',
              ],
            ),
            _Step(
              number: '3',
              title: 'AI 反思問題',
              bullets: const [
                'AI 見證者根據信的內容提出幾個反思問題',
                '回答問題（選填），按「儲存反思」記錄你的感受',
                '下次再進入膠囊，仍可查看或修改回答',
              ],
            ),
            const SizedBox(height: 28),
            _Section(
              title: '注意事項',
              content:
                  '• 封存後無法修改信件內容\n• 膠囊只有自己可以看見\n• 刪除膠囊後無法復原',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.forestGreen,
          ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.content});
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(text: title),
        const SizedBox(height: 8),
        Text(content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.8)),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.bullets});
  final String number;
  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 1, right: 12),
            decoration: BoxDecoration(
              color: AppColors.forestGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ...bullets.map((b) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('• $b',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.warmGray, height: 1.7)),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
