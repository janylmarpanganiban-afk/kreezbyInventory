import 'dart:convert';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT IMAGE WIDGET
// a smart image widget that handles 3 different image sources:
//   1. https:// urls (images stored in firebase storage)
//   2. data:image/... base64 strings (fallback when firebase storage fails)
//   3. assets/ paths (bundled local images)
// if none of those work, it shows a fallback icon
// ─────────────────────────────────────────────────────────────────────────────
class ProductImage extends StatelessWidget {
  final String? imagePath;      // the path/url/base64 string for the image
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;       // what to show if the image fails to load
  final BorderRadius? borderRadius; // optional rounding for corners

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
    // default fallback icon if no custom fallback is given
    final defaultFallback = fallback ??
        Icon(
          Icons.inventory_2,
          size: (width != null && height != null)
              ? (width! < height! ? width! * 0.5 : height! * 0.5)
              : 24,
          color: const Color(0xFF0056C6),
        );

    // if there's no image at all, just show the fallback icon
    if (imagePath == null || imagePath!.isEmpty) {
      return defaultFallback;
    }

    final path = imagePath!.trim();
    Widget imageWidget;

    // case 1: image is a network url (firebase storage or any http link)
    if (path.startsWith('http://') || path.startsWith('https://')) {
      imageWidget = Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => defaultFallback, // fallback if network fails
      );

    // case 2: image is a base64 encoded string
    // we decode it and use Image.memory() to display it from raw bytes
    } else if (path.startsWith('data:image') || _isBase64(path)) {
      try {
        // strip the "data:image/jpeg;base64," prefix if it exists
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
        // if base64 decode fails for any reason, just show fallback
        imageWidget = defaultFallback;
      }

    // case 3: image is a bundled asset (e.g. 'assets/chocolate crinkles.jpg')
    } else if (path.startsWith('assets/')) {
      imageWidget = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => defaultFallback,
      );

    // default: treat as asset path even if it doesn't start with 'assets/'
    } else {
      imageWidget = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => defaultFallback,
      );
    }

    // if borderRadius is set, wrap the image in ClipRRect to round the corners
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  // helper to detect if a string looks like raw base64 data
  // checks length and character patterns to avoid false positives
  bool _isBase64(String str) {
    if (str.length < 50) return false; // too short to be a real base64 image
    final cleanStr = str.replaceAll('\n', '').replaceAll('\r', '').trim();
    if (cleanStr.contains(' ') || cleanStr.contains('/assets/')) return false;
    // base64 strings only use A-Z, a-z, 0-9, +, /, and = for padding
    final regex = RegExp(r'^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$');
    return regex.hasMatch(cleanStr);
  }
}
