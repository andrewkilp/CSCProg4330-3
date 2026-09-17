import 'package:flutter/material.dart';

class CategoryHeading extends StatelessWidget {
  const CategoryHeading({
    super.key,
    required this.category,
    required this.itemCount,
  });
  final String category;
  final int itemCount;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      '$category ($itemCount)',
      style: Theme.of(context).textTheme.titleMedium,
    ),
  );
}
