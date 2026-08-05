import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:child_health_tracker/core/photos/compression.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/core/l10n/labels.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// A photo-like image: smooth gradients plus noise, so the JPEG encoder cannot
/// collapse it the way it would a flat colour field.
Uint8List _photo(int width, int height, {int seed = 1}) {
  final random = math.Random(seed);
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgb(
        x,
        y,
        (x * 255 ~/ width + random.nextInt(60)).clamp(0, 255),
        (y * 255 ~/ height + random.nextInt(60)).clamp(0, 255),
        (random.nextInt(255)),
      );
    }
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 100));
}

void main() {
  group('targetSize', () {
    test('leaves a small image alone', () {
      // Upscaling a thumbnail to 1280 would only waste bytes.
      expect(targetSize(800, 600), (width: 800, height: 600));
      expect(targetSize(1280, 720), (width: 1280, height: 720));
    });

    test('scales the longest edge down to the limit', () {
      expect(targetSize(4000, 3000), (width: 1280, height: 960));
      expect(targetSize(3000, 4000), (width: 960, height: 1280));
    });

    test('preserves the aspect ratio', () {
      final result = targetSize(4032, 3024);
      final before = 4032 / 3024;
      final after = result.width / result.height;
      expect(after, closeTo(before, 0.01));
    });

    test('never returns a zero dimension', () {
      final result = targetSize(5000, 3);
      expect(result.width, greaterThan(0));
      expect(result.height, greaterThan(0));
    });
  });

  group('the Firestore arithmetic', () {
    test('the binary budget leaves room after base64 inflation', () {
      // base64 is 4/3 of the input; the encoded form must clear the budget,
      // and the budget must clear the document limit.
      final encodedSize = (PhotoLimits.maxBinaryBytes * 4 / 3).ceil();
      expect(encodedSize, lessThanOrEqualTo(PhotoLimits.maxEncodedBytes));
      expect(
        PhotoLimits.maxEncodedBytes,
        lessThan(PhotoLimits.firestoreDocumentBytes),
      );
    });

    test('there is headroom for the rest of the document', () {
      final headroom =
          PhotoLimits.firestoreDocumentBytes - PhotoLimits.maxEncodedBytes;
      expect(
        headroom,
        greaterThan(100 * 1024),
        reason: 'child_id, timestamps and Firestore overhead must also fit',
      );
    });
  });

  group('preparePhoto', () {
    test('a large photo is resized and fits the budget', () {
      final prepared = preparePhoto(_photo(4000, 3000));

      expect(prepared.width, 1280);
      expect(prepared.height, 960);
      expect(prepared.base64Data.length, lessThan(PhotoLimits.maxEncodedBytes));
      expect(prepared.reductionPercent, greaterThan(0));
    });

    test('the result is valid base64 that decodes back to an image', () {
      final prepared = preparePhoto(_photo(2000, 1500));
      final decoded = base64Decode(prepared.base64Data);
      final image = img.decodeImage(decoded);

      expect(image, isNotNull);
      expect(image!.width, prepared.width);
      expect(image.height, prepared.height);
    });

    test('a small image keeps its dimensions', () {
      final prepared = preparePhoto(_photo(400, 300));
      expect(prepared.width, 400);
      expect(prepared.height, 300);
    });

    test('quality drops only as far as needed', () {
      final prepared = preparePhoto(_photo(600, 400));
      expect(
        prepared.quality,
        PhotoLimits.qualitySteps.first,
        reason: 'a small image should not be degraded at all',
      );
    });

    test('a busy full-size photo still fits, degrading if it must', () {
      final prepared = preparePhoto(_photo(4032, 3024, seed: 7));
      expect(prepared.base64Data.length, lessThan(PhotoLimits.maxEncodedBytes));
      expect(PhotoLimits.qualitySteps, contains(prepared.quality));
    });

    test('rejects data that is not an image', () {
      expect(
        () => preparePhoto(Uint8List.fromList([1, 2, 3, 4, 5])),
        throwsA(isA<PhotoTooLargeException>()),
      );
    });

    test('the failure says which problem it was, in every language', () async {
      try {
        preparePhoto(Uint8List.fromList([0, 0, 0]));
        fail('should have thrown');
      } on PhotoTooLargeException catch (e) {
        expect(e.problem, PhotoProblem.notAnImage);

        // The sentence a parent sees is looked up per locale rather than
        // carried on the exception, so none of them may be blank.
        for (final locale in supportedLocales) {
          final l = await AppLocalizations.delegate.load(locale);
          expect(photoProblemText(l, e.problem).trim(), isNotEmpty);
        }
      }
    });
  });
}
