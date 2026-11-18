import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:omr_mobile_app/core/omr/perspective_transformer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PerspectiveTransformer transformer;

  setUp(() {
    transformer = const PerspectiveTransformer();
  });

  group('PerspectiveTransformer Tests', () {
    test('Correctly maps identity canonical quad with zero distortion', () {
      final source = img.Image(width: 400, height: 600);
      img.fill(source, color: img.ColorRgb8(255, 255, 255));
      // Draw a black dot at center (200, 300)
      img.fillCircle(source,
          x: 200, y: 300, radius: 10, color: img.ColorRgb8(0, 0, 0));

      const corners = QuadCorners(
        topLeft: Point2D(0, 0),
        topRight: Point2D(399, 0),
        bottomRight: Point2D(399, 599),
        bottomLeft: Point2D(0, 599),
      );

      final warped = transformer.warpPerspective(
        source,
        corners,
        targetWidth: 400,
        targetHeight: 600,
      );

      expect(warped.width, equals(400));
      expect(warped.height, equals(600));

      // Center should remain black
      final centerP = warped.getPixel(200, 300);
      expect(centerP.r, lessThan(30));
      expect(centerP.g, lessThan(30));
      expect(centerP.b, lessThan(30));
    });

    test(
        'Correctly rectifies trapezoid perspective tilt into rectangular canvas',
        () {
      final source = img.Image(width: 500, height: 700);
      img.fill(source, color: img.ColorRgb8(255, 255, 255));

      // Trapezoid corners (narrow top, wide bottom)
      const trapezoidCorners = QuadCorners(
        topLeft: Point2D(50, 40),
        topRight: Point2D(450, 40),
        bottomRight: Point2D(490, 660),
        bottomLeft: Point2D(10, 660),
      );

      final warped = transformer.warpPerspective(
        source,
        trapezoidCorners,
        targetWidth: 400,
        targetHeight: 600,
      );

      expect(warped.width, equals(400));
      expect(warped.height, equals(600));
    });

    test('Detects outer fiducial markers on real sample scan', () async {
      final file = File('assets/samples/sample_1_vedehi_224567.jpg');
      if (!await file.exists()) return;

      final Uint8List bytes = await file.readAsBytes();
      final img.Image? decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);

      final corners = transformer.detectDocumentCorners(decoded!);

      expect(corners.topLeft.x, lessThan(decoded.width * 0.30));
      expect(corners.topLeft.y, lessThan(decoded.height * 0.30));
      expect(corners.topRight.x, greaterThan(decoded.width * 0.70));
      expect(corners.bottomRight.x, greaterThan(decoded.width * 0.70));
      expect(corners.bottomLeft.x, lessThan(decoded.width * 0.30));

      // Warp real sample into canonical template size 1130x1599
      final warped = transformer.warpPerspective(
        decoded,
        corners,
        targetWidth: 1130,
        targetHeight: 1599,
      );

      expect(warped.width, equals(1130));
      expect(warped.height, equals(1599));
    });
  });
}
