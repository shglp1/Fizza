import 'package:flutter/material.dart';
import 'package:fizza_domain/fizza_domain.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class SubscriptionDetailsScreen extends StatefulWidget {
  final UserSubscriptionEntity subscription;

  const SubscriptionDetailsScreen({super.key, required this.subscription});

  @override
  State<SubscriptionDetailsScreen> createState() => _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState extends State<SubscriptionDetailsScreen> {
  final _subscriptionRepo = GetIt.I<ISubscriptionRepository>();
  bool _isCancelling = false;

  Future<void> _handleCancel() async {
    final now = DateTime.now();
    final isPreStart = now.isBefore(widget.subscription.startDate);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPreStart ? 'Cancel subscription?' : 'Cancel renewal?'),
        content: Text(isPreStart
            ? 'If you cancel before the month starts, the full amount will be refunded to your wallet.'
            : 'Your current month will continue until the end date. The subscription will NOT renew next month. No refund will be issued.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isPreStart ? 'Confirm cancellation' : 'Stop renewal'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isCancelling = true);
      final result = await _subscriptionRepo.cancelSubscription(widget.subscription.id);
      
      if (!mounted) return;
      setState(() => _isCancelling = false);

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${failure.message}')),
          );
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isPreStart
                ? 'Subscription cancelled. A full refund has been added to your wallet.'
                : 'Your subscription will not renew after this period.')),
          );
          Navigator.pop(context); // Go back to home
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subscription;
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Plan', sub.planType.toUpperCase()),
            _buildDetailRow('Status', sub.isActive ? 'Active' : 'Inactive'),
            _buildDetailRow('Start Date', DateFormat('MMM dd, yyyy').format(sub.startDate)),
            _buildDetailRow('End Date', DateFormat('MMM dd, yyyy').format(sub.endDate)),
            _buildDetailRow('Auto-Renew', sub.autoRenew ? 'On' : 'Off'),
            _buildDetailRow('Beneficiary', sub.beneficiaryId ?? 'Self'),
            
            const Spacer(),
            
            if (sub.isActive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                  ),
                  onPressed: _isCancelling ? null : _handleCancel,
                  child: _isCancelling 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Cancel Subscription'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
