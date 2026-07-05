import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _confirmPop() async {
    final hasContent =
        _titleCtrl.text.trim().isNotEmpty || _contentCtrl.text.trim().isNotEmpty;
    if (!hasContent) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('放棄這封信？'),
        content: const Text('返回後，已寫的內容將會消失'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('繼續寫')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('放棄')),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.pop(context);
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop) _confirmPop();
      },
      child: Scaffold(
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
            inputFormatters: [LengthLimitingTextInputFormatter(200)], // DB 上限 200 字
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
                hintStyle: TextStyle(color: AppColors.warmGray.withValues(alpha: 0.6)),
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 2.0),
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ]),
      ),
      ),
    );
  }
}
