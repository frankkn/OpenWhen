import 'package:flutter/material.dart';
import 'package:openwhen/screens/capsule/set_open_date_screen.dart';
import 'package:openwhen/services/api_service.dart';
import 'package:openwhen/theme/app_theme.dart';

const _questions = [
  // 維度① 現在的狀態
  '你現在在做什麼？生活的重心是什麼？',
  '你現在的心情，用一句話描述是什麼？',
  // 維度② 恐懼／擔憂
  '你現在最擔心的事是什麼？',
  '有什麼事情讓你最近睡不好，或一直放不下？',
  // 維度③ 期待／希望
  '一年後，你最希望什麼事情有所改變？',
  '你希望未來的自己，變成什麼樣的人？',
  // 維度④ 未完成的事
  '有什麼事你一直想做，但還沒有去做？',
  '如果明天一切都會改變，你今天會做什麼？',
  // 維度⑤ 對未來自己說的話
  '如果只能對未來的自己說一句話，你想說什麼？',
];

class WriteAiScreen extends StatefulWidget {
  const WriteAiScreen({super.key});

  @override
  State<WriteAiScreen> createState() => _WriteAiScreenState();
}

class _WriteAiScreenState extends State<WriteAiScreen> {
  int _current = 0;
  final List<String> _answers = List.filled(_questions.length, '');
  late final List<TextEditingController> _controllers = List.generate(
    _questions.length,
    (i) => TextEditingController(),
  );
  bool _loading = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    _answers[_current] = _controllers[_current].text.trim();
    if (_current < _questions.length - 1) {
      setState(() => _current++);
    } else {
      _generateLetter();
    }
  }

  void _prev() {
    _answers[_current] = _controllers[_current].text.trim();
    setState(() => _current--);
  }

  Future<void> _generateLetter() async {
    setState(() => _loading = true);
    try {
      final answersPayload = List.generate(_questions.length, (i) => {
        'question_number': i + 1,
        'question_text': _questions[i],
        'answer_text': _answers[i].isEmpty ? null : _answers[i],
      });
      final letter = await ApiService().generateLetter(answersPayload);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SetOpenDateScreen(
            title: null,
            content: letter,
            mode: 'ai_assisted',
            answers: answersPayload,
          ),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('生成失敗：$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI 正在整理你的信件…'),
          ],
        )),
      );
    }

    final isFirst = _current == 0;
    final isLast = _current == _questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('第 ${_current + 1} 題／共 ${_questions.length} 題'),
        backgroundColor: AppColors.paperWhite,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LinearProgressIndicator(
            value: (_current + 1) / _questions.length,
            backgroundColor: AppColors.warmBrown.withOpacity(0.15),
            color: AppColors.forestGreen,
          ),
          const SizedBox(height: 32),
          Text(
            _questions[_current],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, height: 1.6),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: TextField(
              controller: _controllers[_current],
              maxLines: null,
              expands: true,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '（可以跳過）',
                hintStyle: TextStyle(color: AppColors.warmGray.withOpacity(0.6)),
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8),
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
          const SizedBox(height: 24),
          Row(children: [
            if (!isFirst)
              Expanded(
                child: OutlinedButton(onPressed: _prev, child: const Text('上一題')),
              ),
            if (!isFirst) const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _next,
                child: Text(isLast ? '完成，整理成信件' : '下一題'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
