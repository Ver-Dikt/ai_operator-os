import 'dart:io';

import 'package:flutter/material.dart';

class ResultMedia extends StatelessWidget {
  const ResultMedia({super.key, required this.source, required this.isVideo});

  final String? source;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final value = source?.trim() ?? '';
    if (!isVideo && value.isNotEmpty && !value.startsWith('mock://')) {
      if (value.startsWith('http://') || value.startsWith('https://')) {
        return Image.network(
          value,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        );
      }
      final path = value.startsWith('file://')
          ? Uri.parse(value).toFilePath()
          : value;
      return Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Center(
      child: Icon(
        isVideo ? Icons.play_circle_outline_rounded : Icons.image_outlined,
        color: const Color(0xCCFFFFFF),
        size: 74,
      ),
    );
  }
}
