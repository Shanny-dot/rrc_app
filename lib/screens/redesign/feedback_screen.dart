import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

/// "Send feedback": messages appear on the admin website's Feedback page and are emailed to staff.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const _categories = {
    'idea': (Icons.lightbulb_outline_rounded, 'Idea'),
    'problem': (Icons.report_problem_outlined, 'Problem'),
    'praise': (Icons.favorite_border_rounded, 'Praise'),
    'other': (Icons.chat_bubble_outline_rounded, 'Other'),
  };

  final _message = TextEditingController();
  String _category = 'idea';
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.length < 3) {
      setState(() => _error = 'Please tell us a little more.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    String? version;
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    final res = await ApiService().sendFeedback(
      message: text,
      category: _category,
      appVersion: version,
      platform: Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : null,
    );
    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.pop(context);
      showToast(context, 'Thanks for your feedback! Our team reads every message.');
    } else {
      setState(() {
        _sending = false;
        _error = (res['error'] ?? "Couldn't send your feedback").toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send feedback')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.pageMargin),
          children: [
            Text('Tell us what you think — ideas, problems or anything you love. Our team reads every message.',
                style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.entries.map((c) {
                final selected = _category == c.key;
                return ChoiceChip(
                  avatar: Icon(c.value.$1, size: 18, color: selected ? AppColors.primaryGold : AppColors.textSecondary),
                  label: Text(c.value.$2),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = c.key),
                  showCheckmark: false,
                  backgroundColor: AppColors.inputFill,
                  selectedColor: UiColors.goldBg,
                  side: BorderSide(color: selected ? AppColors.primaryGold : UiColors.border),
                  labelStyle: TextStyle(color: selected ? AppColors.primaryGold : AppColors.textPrimary, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _message,
              maxLines: 7,
              maxLength: 4000,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Your message',
                hintStyle: AppTextStyles.bodyMedium,
                filled: true,
                fillColor: AppColors.inputFill,
                counterStyle: AppTextStyles.labelSmall,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusInput), borderSide: BorderSide.none),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 16),
            FilledAction(text: _sending ? 'Sending…' : 'Send feedback', icon: Icons.send_rounded, onPressed: _sending ? null : _send),
          ],
        ),
      ),
    );
  }
}
