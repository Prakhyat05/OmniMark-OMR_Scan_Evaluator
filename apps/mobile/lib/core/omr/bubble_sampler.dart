import 'dart:math' as math;
import 'package:image/image.dart' as img;

/// Bubble Pixel Sample
class BubbleSample {
  final double meanIntensity; // 0.0 (darkest black) to 255.0 (pure white)
  final double minIntensity;  // Darkest pixel within inner bubble mask
  final List<int> patch32x32; // 32x32 grayscale pixel buffer (length: 1024)

  const BubbleSample({
    required this.meanIntensity,
    required this.minIntensity,
    required this.patch32x32,
  });
}

/// On-Device Bubble Sampler.
/// Extracts subpixel circular mask mean intensity and crops standardized 32x32 patches.
class BubbleSampler {
  const BubbleSampler();

  /// Samples a circular bubble region from an [img.Image] given normalized coordinates `[0.0, 1.0]`.
  BubbleSample sampleBubble(
    img.Image image, {
    required double cxNorm,
    required double cyNorm,
    required double radiusNorm,
  }) {
    final int imgW = image.width;
    final int imgH = image.height;

    final int cx = (cxNorm * imgW).round();
    final int cy = (cyNorm * imgH).round();
    final int radius = math.max(3, (radiusNorm * imgW).round());

    // 1. Calculate circular mask mean and min intensity
    double sumVal = 0.0;
    double minVal = 255.0;
    int count = 0;
    final int innerR = math.max(2, radius - 2);

    for (int dy = -innerR; dy <= innerR; dy++) {
      final int py = cy + dy;
      if (py < 0 || py >= imgH) continue;

      for (int dx = -innerR; dx <= innerR; dx++) {
        final int px = cx + dx;
        if (px < 0 || px >= imgW) continue;

        if (dx * dx + dy * dy <= innerR * innerR) {
          final pixel = image.getPixel(px, py);
          // Luminance = 0.299*R + 0.587*G + 0.114*B
          final double luma = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114;
          sumVal += luma;
          if (luma < minVal) minVal = luma;
          count++;
        }
      }
    }

    final double meanIntensity = count > 0 ? (sumVal / count) : 255.0;

    // 2. Extract 32x32 crop
    final int cropRadius = radius + 4;
    final int cropX0 = cx - cropRadius;
    final int cropY0 = cy - cropRadius;
    final int cropSize = cropRadius * 2;

    final List<int> patch32 = List<int>.filled(32 * 32, 255);

    for (int ty = 0; ty < 32; ty++) {
      final double srcY = cropY0 + (ty / 31.0) * cropSize;
      final int srcYi = srcY.clamp(0.0, (imgH - 1).toDouble()).round();

      for (int tx = 0; tx < 32; tx++) {
        final double srcX = cropX0 + (tx / 31.0) * cropSize;
        final int srcXi = srcX.clamp(0.0, (imgW - 1).toDouble()).round();

        final p = image.getPixel(srcXi, srcYi);
        final int gray = (p.r * 0.299 + p.g * 0.587 + p.b * 0.114).round().clamp(0, 255);
        patch32[ty * 32 + tx] = gray;
      }
    }

    return BubbleSample(
      meanIntensity: double.parse(meanIntensity.toStringAsFixed(2)),
      minIntensity: double.parse(minVal.toStringAsFixed(2)),
      patch32x32: patch32,
    );
  }
}
