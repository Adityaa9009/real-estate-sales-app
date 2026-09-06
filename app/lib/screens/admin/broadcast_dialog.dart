import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/database_service.dart';

class BroadcastDialog extends StatefulWidget {
  const BroadcastDialog({super.key});

  @override
  State<BroadcastDialog> createState() => _BroadcastDialogState();
}

class _BroadcastDialogState extends State<BroadcastDialog> {
  final _titleController = TextEditingController(text: 'Holiday & Office Update');
  final _messageController = TextEditingController(
    text: 'All employees please note: Tomorrow the office will observe a holiday. For emergency visits, outside sales may coordinate directly.',
  );
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      await DatabaseService.sendBroadcast(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        createdBy: 'Aditya Duhan (Admin)',
        targetRoles: ['inside_sales', 'outside_sales', 'executive'],
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Broadcast announcement published to all employee dashboards!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      title: const Row(
        children: [
          Icon(Icons.campaign_rounded, color: AppColors.primary, size: 24),
          SizedBox(width: 10),
          Text('1-Click Broadcast Message', style: TextStyle(fontSize: 18, color: AppColors.textPrimary)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send an instant notification/banner to all employees regarding updates, holidays, or sales incentives.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text('Announcement Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(hintText: 'e.g. Festival Holiday Notice'),
            ),
            const SizedBox(height: 14),
            const Text('Message Body', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _messageController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(hintText: 'Write update details here...'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton.icon(
          onPressed: _isSending ? null : _send,
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('Send to All Staff'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        ),
      ],
    );
  }
}
