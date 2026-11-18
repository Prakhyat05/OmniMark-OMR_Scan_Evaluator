import 'dart:math' as math;
import 'package:image/image.dart' as img;

/// 2D Point representation with sub-pixel floating-point coordinates.
class Point2D {
  final double x;
  final double y;

  const Point2D(this.x, this.y);

  @override
  String toString() => 'Point2D(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

/// Quadrilateral corners in clockwise order: Top-Left, Top-Right, Bottom-Right, Bottom-Left.
class QuadCorners {
  final Point2D topLeft;
  final Point2D topRight;
  final Point2D bottomRight;
  final Point2D bottomLeft;

  const QuadCorners({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  List<Point2D> get toList => [topLeft, topRight, bottomRight, bottomLeft];
}

/// Industrial-Grade 4-Point Projective Homography Transformer in Pure Dart.
/// Warps perspective-distorted, tilted, or scaled mobile camera captures into
/// canonical, perfectly aligned rectangular templates (e.g. 1130x1599).
class PerspectiveTransformer {
  const PerspectiveTransformer();

  /// Computes the 3x3 projective transformation matrix mapping (u, v) in destination space
  /// back to (x, y) in source space using Gaussian elimination with partial pivoting.
  List<double>? _computeDestinationToSourceMatrix(
    QuadCorners srcQuad,
    int dstW,
    int dstH,
  ) {
    // Destination canonical coordinates (u, v)
    final dstPts = [
      const Point2D(0, 0),
      Point2D(dstW - 1.0, 0),
      Point2D(dstW - 1.0, dstH - 1.0),
      Point2D(0, dstH - 1.0),
    ];

    final srcPts = srcQuad.toList;

    // Build 8x9 augmented matrix [A | B] for solving A * H = B
    // Where H = [h00, h01, h02, h10, h11, h12, h20, h21]^T
    // Equation:
    // u*h00 + v*h01 + h02 - u*x*h20 - v*x*h21 = x
    // u*h10 + v*h11 + h12 - u*y*h20 - v*y*h21 = y
    final matrix = List.generate(8, (_) => List<double>.filled(9, 0.0));

    for (int i = 0; i < 4; i++) {
      final u = dstPts[i].x;
      final v = dstPts[i].y;
      final x = srcPts[i].x;
      final y = srcPts[i].y;

      final r1 = i * 2;
      final r2 = r1 + 1;

      matrix[r1][0] = u;
      matrix[r1][1] = v;
      matrix[r1][2] = 1.0;
      matrix[r1][3] = 0.0;
      matrix[r1][4] = 0.0;
      matrix[r1][5] = 0.0;
      matrix[r1][6] = -u * x;
      matrix[r1][7] = -v * x;
      matrix[r1][8] = x;

      matrix[r2][0] = 0.0;
      matrix[r2][1] = 0.0;
      matrix[r2][2] = 0.0;
      matrix[r2][3] = u;
      matrix[r2][4] = v;
      matrix[r2][5] = 1.0;
      matrix[r2][6] = -u * y;
      matrix[r2][7] = -v * y;
      matrix[r2][8] = y;
    }

    // Gaussian elimination with partial pivoting
    const int n = 8;
    for (int i = 0; i < n; i++) {
      // Find pivot row
      int maxRow = i;
      double maxVal = matrix[i][i].abs();
      for (int k = i + 1; k < n; k++) {
        if (matrix[k][i].abs() > maxVal) {
          maxVal = matrix[k][i].abs();
          maxRow = k;
        }
      }

      if (maxVal < 1e-9) return null; // Singular matrix

      // Swap rows
      if (maxRow != i) {
        final temp = matrix[i];
        matrix[i] = matrix[maxRow];
        matrix[maxRow] = temp;
      }

      // Eliminate below
      for (int k = i + 1; k < n; k++) {
        final factor = matrix[k][i] / matrix[i][i];
        for (int j = i; j <= n; j++) {
          matrix[k][j] -= factor * matrix[i][j];
        }
      }
    }

    // Back-substitution
    final h = List<double>.filled(8, 0.0);
    for (int i = n - 1; i >= 0; i--) {
      double sum = matrix[i][n];
      for (int j = i + 1; j < n; j++) {
        sum -= matrix[i][j] * h[j];
      }
      h[i] = sum / matrix[i][i];
    }

    // Return 3x3 matrix elements in row-major order: [h00, h01, h02, h10, h11, h12, h20, h21, 1.0]
    return [h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7], 1.0];
  }

  /// Warps [source] into canonical rectangle [targetWidth] × [targetHeight]
  /// defined by [corners] using sub-pixel bilinear interpolation.
  img.Image warpPerspective(
    img.Image source,
    QuadCorners corners, {
    int targetWidth = 1130,
    int targetHeight = 1599,
  }) {
    final m = _computeDestinationToSourceMatrix(corners, targetWidth, targetHeight);
    if (m == null) {
      // Fallback to proportional resize if homography singular
      return img.copyResize(source, width: targetWidth, height: targetHeight);
    }

    final m00 = m[0], m01 = m[1], m02 = m[2];
    final m10 = m[3], m11 = m[4], m12 = m[5];
    final m20 = m[6], m21 = m[7];

    final output = img.Image(width: targetWidth, height: targetHeight, numChannels: source.numChannels);
    final srcW = source.width;
    final srcH = source.height;

    for (int v = 0; v < targetHeight; v++) {
      for (int u = 0; u < targetWidth; u++) {
        final double denom = m20 * u + m21 * v + 1.0;
        if (denom.abs() < 1e-9) continue;

        final double sx = (m00 * u + m01 * v + m02) / denom;
        final double sy = (m10 * u + m11 * v + m12) / denom;

        if (sx < 0 || sx >= srcW - 1 || sy < 0 || sy >= srcH - 1) {
          // Fill boundary with white paper
          output.setPixelRgb(u, v, 255, 255, 255);
          continue;
        }

        // Sub-pixel Bilinear Interpolation
        final int x0 = sx.floor();
        final int y0 = sy.floor();
        final int x1 = x0 + 1;
        final int y1 = y0 + 1;

        final double dx = sx - x0;
        final double dy = sy - y0;

        final p00 = source.getPixel(x0, y0);
        final p10 = source.getPixel(x1, y0);
        final p01 = source.getPixel(x0, y1);
        final p11 = source.getPixel(x1, y1);

        final double w00 = (1.0 - dx) * (1.0 - dy);
        final double w10 = dx * (1.0 - dy);
        final double w01 = (1.0 - dx) * dy;
        final double w11 = dx * dy;

        final int r = (w00 * p00.r + w10 * p10.r + w01 * p01.r + w11 * p11.r).round().clamp(0, 255);
        final int g = (w00 * p00.g + w10 * p10.g + w01 * p01.g + w11 * p11.g).round().clamp(0, 255);
        final int b = (w00 * p00.b + w10 * p10.b + w01 * p01.b + w11 * p11.b).round().clamp(0, 255);

        output.setPixelRgb(u, v, r, g, b);
      }
    }

    return output;
  }

  /// Automatically locates the 4 outer corner fiducials (or paper boundaries)
  /// on a raw camera image.
  QuadCorners detectDocumentCorners(img.Image image) {
    final int w = image.width;
    final int h = image.height;

    // Search window in each quadrant for the darkest fiducial cluster
    final double qW = w * 0.25;
    final double qH = h * 0.25;

    Point2D? findDarkestInRegion(int startX, int endX, int startY, int endY) {
      double minLuma = 255.0;
      int bestX = (startX + endX) ~/ 2;
      int bestY = (startY + endY) ~/ 2;

      final int step = math.max(2, (w / 300).round());

      for (int y = startY; y < endY; y += step) {
        for (int x = startX; x < endX; x += step) {
          final p = image.getPixel(x, y);
          final double luma = p.r * 0.299 + p.g * 0.587 + p.b * 0.114;
          if (luma < minLuma) {
            minLuma = luma;
            bestX = x;
            bestY = y;
          }
        }
      }

      if (minLuma < 85.0) {
        // Refine center around minimum
        double sumX = 0, sumY = 0, count = 0;
        final int r = math.max(6, (w * 0.015).round());
        for (int dy = -r; dy <= r; dy++) {
          for (int dx = -r; dx <= r; dx++) {
            final nx = bestX + dx;
            final ny = bestY + dy;
            if (nx >= 0 && nx < w && ny >= 0 && ny < h) {
              final p = image.getPixel(nx, ny);
              final double luma = p.r * 0.299 + p.g * 0.587 + p.b * 0.114;
              if (luma < 90.0) {
                sumX += nx;
                sumY += ny;
                count++;
              }
            }
          }
        }
        if (count > 0) {
          return Point2D(sumX / count, sumY / count);
        }
      }
      return null;
    }

    final tl = findDarkestInRegion(0, qW.round(), 0, qH.round()) ?? const Point2D(0, 0);
    final tr = findDarkestInRegion((w - qW).round(), w, 0, qH.round()) ?? Point2D(w - 1.0, 0);
    final br = findDarkestInRegion((w - qW).round(), w, (h - qH).round(), h) ?? Point2D(w - 1.0, h - 1.0);
    final bl = findDarkestInRegion(0, qW.round(), (h - qH).round(), h) ?? Point2D(0, h - 1.0);

    return QuadCorners(topLeft: tl, topRight: tr, bottomRight: br, bottomLeft: bl);
  }
}
