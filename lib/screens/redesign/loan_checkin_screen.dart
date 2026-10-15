import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import 'help_screen.dart';

/// Yearly "Is your loan still competitive?" check-in, opened from the alert or the Home card.
class LoanCheckinScreen extends StatefulWidget {
  final String? message;
  const LoanCheckinScreen({Key? key, this.message}) : super(key: key);

  @override
  State<LoanCheckinScreen> createState() => _LoanCheckinScreenState();
}

class _LoanCheckinScreenState extends State<LoanCheckinScreen> {
  final _note = TextEditingController();
  ProgramContact _contact = const ProgramContact();
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    ProgramContact.load().then((c) {
      if (mounted) setState(() => _contact = c);
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _requestReview() async {
    setState(() => _sending = true);
    final res = await ApiService().requestBroker(kind: 'loan_review', note: _note.text.trim());
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = res['success'] == true;
    });
    if (!_sent) showToast(context, (res['error'] ?? "Couldn't send your request").toString(), error: true);
  }

  Widget _point(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.check_rounded, size: 18, color: UiColors.green)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, height: 1.4))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan check-in')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.pageMargin),
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: UiColors.goldBg, shape: BoxShape.circle),
              child: const Icon(Icons.home_work_outlined, color: AppColors.primaryGold, size: 34),
            ),
            const SizedBox(height: 20),
            Text('Is your loan still competitive?', style: AppTextStyles.h2),
            const SizedBox(height: 10),
            Text(widget.message ?? 'Rates and lender offers change all the time. A free review checks you\'re still on a good deal.',
                style: AppTextStyles.bodyLarge.copyWith(height: 1.5)),
            const SizedBox(height: 22),
            _point('Free, no-obligation review with your broker'),
            _point('Compare your rate with today\'s offers'),
            _point('Check your loan still suits your plans'),
            const SizedBox(height: 18),
            if (_sent)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: UiColors.greenBg, borderRadius: BorderRadius.circular(AppDimens.radiusCard)),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, color: UiColors.green),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Request sent. ${_contact.name} will be in touch soon.',
                      style: AppTextStyles.labelLarge.copyWith(color: UiColors.green))),
                ]),
              )
            else ...[
              TextField(
                controller: _note,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Anything we should know? e.g. best time to call (optional)',
                  hintStyle: AppTextStyles.bodyMedium,
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusInput), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              FilledAction(text: _sending ? 'Sending…' : 'Request a review', icon: Icons.send_rounded, onPressed: _sending ? null : _requestReview),
            ],
            const SizedBox(height: 26),
            Text('Or talk to your broker now', style: AppTextStyles.labelMedium),
            const SizedBox(height: 10),
            BrokerActions(info: _contact, emailSubject: 'Loan review'),
          ],
        ),
      ),
    );
  }
}
