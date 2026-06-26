import 'package:flutter/material.dart';
import 'package:openwhen/screens/capsule/set_open_date_screen.dart';
import 'package:openwhen/theme/app_theme.dart';

class WriteFreeScreen extends StatefulWidget {
  const WriteFreeScreen({super.key});

  @override
  State<WriteFreeScreen> createState() => _WriteFreeScreenState();
}

class _WriteFreeScreenState extends State<WriteFreeScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _proceed() {
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請寫點什麼再繼續')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetOpenDateScreen(
          title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          mode: 'free',
          answers: const [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('寫信'),
        backgroundColor: AppColors.paperWhite,
        actions: [TextButton(onPressed: _proceed, child: const Text('繼續'))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: '標題（選填）', border: InputBorder.none),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Divider(),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _contentCtrl,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: '親愛的未來的我，',
                hintStyle: TextStyle(color: AppColors.warmGray.withOpacity(0.6)),
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 2.0),
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ]),
      ),
    );
  }
}
