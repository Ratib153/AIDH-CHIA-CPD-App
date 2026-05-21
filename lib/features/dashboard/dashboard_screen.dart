import 'dart:math' as math;

import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CPD Tracker', style: textTheme.headlineSmall),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Progress', style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Certification Cycle 2026-2029',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        _ProgressRing(percentage: 0.86, centerTop: '86%', centerBottom: '70/60'),
                        SizedBox(width: 16),
                        Expanded(child: _ProgressStats()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _ActionGrid(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Activities', style: textTheme.titleMedium),
                TextButton(onPressed: () {}, child: const Text('See All')),
              ],
            ),
            const SizedBox(height: 8),
            const _ActivityTile(
              title: 'AHIMA Conference 2024',
              subtitle: 'Conference · Oct 15, 2024',
              points: '15',
            ),
            const _ActivityTile(
              title: 'Health Data Analytics Course',
              subtitle: 'Education · Sep 28, 2024',
              points: '10',
            ),
            const _ActivityTile(
              title: 'Clinical Documentation Review',
              subtitle: 'Research · Sep 10, 2024',
              points: '5',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.percentage,
    required this.centerTop,
    required this.centerBottom,
  });

  final double percentage;
  final String centerTop;
  final String centerBottom;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 126,
      height: 126,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(126, 126),
            painter: _ProgressPainter(percentage: percentage),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                centerTop,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D1321),
                ),
              ),
              Text(
                centerBottom,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5570),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter({required this.percentage});
  final double percentage;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const strokeWidth = 10.0;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final basePaint = Paint()
      ..color = const Color(0xFFE7ECF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = const Color(0xFF0F6FFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, basePaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percentage,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}

class _ProgressStats extends StatelessWidget {
  const _ProgressStats();

  @override
  Widget build(BuildContext context) {
    const valueStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Color(0xFF0D1321),
    );
    const labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFF62708D),
    );

    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatRow(label: 'Points Earned', value: '70', valueStyle: valueStyle, labelStyle: labelStyle),
        SizedBox(height: 8),
        _StatRow(label: 'Points Remaining', value: '10', valueStyle: valueStyle, labelStyle: labelStyle),
        SizedBox(height: 8),
        _StatRow(label: 'Target', value: '60 pts', valueStyle: valueStyle, labelStyle: labelStyle),
        SizedBox(height: 8),
        _StatRow(label: 'On Track', value: 'Yes', valueStyle: valueStyle, labelStyle: labelStyle),
        SizedBox(height: 8),
        _StatRow(label: 'Time Left', value: '2 years', valueStyle: valueStyle, labelStyle: labelStyle),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.valueStyle,
    required this.labelStyle,
  });

  final String label;
  final String value;
  final TextStyle valueStyle;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: const [
        _ActionButton(label: 'Add Activity', icon: Icons.add_circle_outline),
        _ActionButton(label: 'Scan Event', icon: Icons.qr_code_scanner),
        _ActionButton(label: 'View All', icon: Icons.list_alt_outlined),
        _ActionButton(label: 'Export', icon: Icons.file_download_outlined),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: const Color(0xFF0F6FFF)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1321),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.points,
  });

  final String title;
  final String subtitle;
  final String points;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D1321),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle),
          ),
          trailing: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE9F0FF),
              shape: BoxShape.circle,
            ),
            child: Text(
              points,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F6FFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
