import 'package:flutter/material.dart';

import '../core/app_assets.dart';

class PropertyImage extends StatelessWidget {
  const PropertyImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => Image.asset(
          AppAssets.appartementDakar,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    }

    return Image.asset(path, width: width, height: height, fit: fit);
  }
}
