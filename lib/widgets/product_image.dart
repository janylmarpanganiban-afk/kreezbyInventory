import 'dart:convert';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final defaultFallback = fallback ??
        Icon(
          Icons.inventory_2,
          size: (width != null && height != null)
              ? (width! < height! ? width! * 0.5 : height! * 0.5)
              : 24,
          color: const Color(0xFF0056C6),
        );

    if (imagePath == null || imagePath!.isEmpty) {
      return defaultFallback;
    }

    final path = imagePath!.trim();

    Widget imageWidget;

    if (path.startsWith('http://') || path.startsWith('https://')) {
      imageWidget = Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => defaultFallback,
      );
    } else if (path.startsWith('data:image') || _isBase64(path)) {
      try {
        final base64String = path.contains(',') ? path.split(',').last : path;
        final bytes = base64Decode(base64String.trim());
        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => defaultFallback,
        );
      } catch (e) {
        imageWidget = defaultFallback;
      }
    } else if (path.startsWith('assets/')) {
      imageWidget = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => defaultFallback,
      );
    } else {
      imageWidget = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => defaultFallback,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  bool _isBase64(String str) {
    if (str.length < 50) return false;
    // Basic check for base64 data without prefix
    final cleanStr = str.replaceAll('\n', '').replaceAll('\r', '').trim();
    if (cleanStr.contains(' ') || cleanStr.contains('/assets/')) return false;
    final regex = RegExp(r'^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$');
    return regex.hasMatch(cleanStr);
  }
}
