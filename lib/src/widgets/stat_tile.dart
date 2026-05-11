import 'package:flutter/material.dart';

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F0C),
        border: Border(
          left: BorderSide(color: Color(0xFFE34F34), width: 3),
          top: BorderSide(color: Color(0xFF34382E)),
          right: BorderSide(color: Color(0xFF34382E)),
          bottom: BorderSide(color: Color(0xFF34382E)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF8E927F),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFFF1E7CF),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
