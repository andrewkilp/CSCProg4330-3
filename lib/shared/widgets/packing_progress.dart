import 'package:flutter/material.dart';

class PackingProgress extends StatelessWidget {
  const PackingProgress({
    super.key,
    required this.packedCount,
    required this.totalCount,
  });
  final int packedCount;
  final int totalCount;
  @override
  Widget build(BuildContext context) {
    final total = totalCount < 0 ? 0 : totalCount;
    final packed = packedCount.clamp(0, total);
    final progress = total == 0 ? 0.0 : packed / total;
    return Semantics(
      label: '$packed of $total items packed.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${(progress * 100).round()}% packed'),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }
}
