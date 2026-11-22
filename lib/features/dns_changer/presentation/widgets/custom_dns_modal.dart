import 'package:flutter/material.dart';
import 'package:antidotes/core/constants/app_colors.dart';

class CustomDnsModal extends StatefulWidget {
  final String adapterName;
  final Function(String primary, String? secondary) onApply;

  const CustomDnsModal({
    super.key,
    required this.adapterName,
    required this.onApply,
  });

  @override
  State<CustomDnsModal> createState() => _CustomDnsModalState();
}

class _CustomDnsModalState extends State<CustomDnsModal> {
  final TextEditingController _primaryController = TextEditingController();
  final TextEditingController _secondaryController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  bool _isValidIpv4(String ip) {
    final parts = ip.trim().split('.');
    if (parts.length != 4) return false;
    for (final p in parts) {
      final val = int.tryParse(p);
      if (val == null || val < 0 || val > 255) return false;
    }
    return true;
  }

  void _submit() {
    final primary = _primaryController.text.trim();
    final secondary = _secondaryController.text.trim();

    if (!_isValidIpv4(primary)) {
      setState(() {
        _errorMessage = 'Please enter a valid Primary IPv4 address (e.g. 1.1.1.1)';
      });
      return;
    }

    if (secondary.isNotEmpty && !_isValidIpv4(secondary)) {
      setState(() {
        _errorMessage = 'Secondary IPv4 address is invalid';
      });
      return;
    }

    widget.onApply(primary, secondary.isNotEmpty ? secondary : null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Row(
        children: [
          const Icon(Icons.edit_note_rounded, color: Color(0xFF2979FF), size: 24),
          const SizedBox(width: 10),
          Text(
            'Custom DNS Configuration',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Applying to interface: ${widget.adapterName}',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),

            // Primary DNS
            Text(
              'Preferred (Primary) DNS Server *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _primaryController,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Consolas'),
              decoration: InputDecoration(
                hintText: 'e.g. 1.1.1.1 or 8.8.8.8',
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: AppColors.surfaceBorder)),
              ),
            ),
            const SizedBox(height: 14),

            // Secondary DNS
            Text(
              'Alternate (Secondary) DNS Server (Optional)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _secondaryController,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Consolas'),
              decoration: InputDecoration(
                hintText: 'e.g. 1.0.0.1 or 8.8.4.4',
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: AppColors.surfaceBorder)),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 11.5, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Apply Custom DNS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
