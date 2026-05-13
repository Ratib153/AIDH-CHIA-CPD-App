import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../theme/app_theme.dart';
import '../activities/add_activity_screen.dart';

/// Camera-driven QR/barcode scanner.
///
/// On a successful scan the user can choose to "Use as activity" — that pushes
/// `AddActivityScreen` with the scanned content pre-filled into the activity
/// title (and provider, when the QR payload is JSON with those fields).
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _handled = false;
  String? _lastError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _ScannedActivity _parsePayload(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return _ScannedActivity(
            rawText: trimmed,
            title: (decoded['title'] ??
                    decoded['name'] ??
                    decoded['activityDescription'] ??
                    decoded['activity'])
                ?.toString(),
            provider: (decoded['provider'] ??
                    decoded['organisation'] ??
                    decoded['organization'])
                ?.toString(),
          );
        }
      } catch (_) {
        // Falls through to plain-text handling.
      }
    }
    return _ScannedActivity(rawText: trimmed, title: trimmed, provider: null);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final code = capture.barcodes
        .firstWhere(
          (b) => (b.rawValue ?? '').trim().isNotEmpty,
          orElse: () => Barcode(),
        )
        .rawValue;
    if (code == null || code.trim().isEmpty) return;

    _handled = true;
    await _controller.stop();
    final parsed = _parsePayload(code);
    if (!mounted) return;
    await _showResultSheet(parsed);
  }

  Future<void> _showResultSheet(_ScannedActivity scanned) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.successSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check_circle,
                          color: AppColors.success, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'QR code scanned',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scanned content',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        scanned.rawText,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      if (!mounted) return;
                      final saved =
                          await Navigator.of(context).pushReplacement<bool, void>(
                        MaterialPageRoute(
                          builder: (_) => AddActivityScreen(
                            prefilledDescription: scanned.title,
                            prefilledProvider: scanned.provider,
                          ),
                        ),
                      );
                      if (saved == true && mounted) {
                        Navigator.of(context).maybePop(true);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Use as activity'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      _handled = false;
                      await _controller.start();
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan another'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            tooltip: 'Toggle flash',
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Switch camera',
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                    errorBuilder: (context, error, child) {
                      _lastError = error.errorDetails?.message ??
                          error.errorCode.toString();
                      return _ErrorView(message: _lastError ?? 'Camera error');
                    },
                  ),
                  const IgnorePointer(child: _ScanReticle()),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Point the camera at a CPD QR code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'When detected, you can use the scanned content to pre-fill a new activity.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanReticle extends StatelessWidget {
  const _ScanReticle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 3),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined,
              color: Colors.white70, size: 64),
          const SizedBox(height: 12),
          const Text(
            'Camera unavailable',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: const Text('Go back',
                style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannedActivity {
  const _ScannedActivity({
    required this.rawText,
    required this.title,
    required this.provider,
  });

  final String rawText;
  final String? title;
  final String? provider;
}
