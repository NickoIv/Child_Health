import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Fitting photos into Firestore documents.
///
/// Firebase Storage would be the natural home for binaries, but it requires
/// the paid Blaze plan. Firestore's free tier does not — at the cost of a hard
/// 1 MiB per document, made worse by base64, which inflates bytes by a third.
///
/// So the photo has to be small before it is encoded, and the arithmetic has
/// to be respected rather than hoped about: whatever survives compression is
/// multiplied by 4/3 and must still clear the limit with room for the other
/// fields in the document.
abstract final class PhotoLimits {
  /// Firestore's hard ceiling for one document.
  static const firestoreDocumentBytes = 1048576;

  /// The compressed JPEG itself. Chosen well below what a document could hold:
  /// a diary of several hundred photos on the free tier is limited by stored
  /// bytes and by what a phone downloads on mobile data, not by the ceiling.
  /// 400 KiB still leaves a 1280px milestone photo and a lab form readable.
  static const maxBinaryBytes = 400 * 1024;

  /// What that becomes once base64 inflates it — roughly 533 KiB, about half
  /// of Firestore's limit, leaving ample room for the other fields.
  ///
  /// The exact base64 length, four characters per three bytes rounded up, not
  /// a truncating 4/3: the discarded remainder made this a byte short of what
  /// a full-budget photo actually encodes to.
  static const maxEncodedBytes = 4 * ((maxBinaryBytes + 2) ~/ 3);

  /// Longest edge after resizing. 1280 keeps a lab form readable and a
  /// milestone photo pleasant without wasting the budget.
  static const maxEdge = 1280;

  /// Quality ladder. Each step is tried in turn until the result fits, so a
  /// simple photo keeps its quality and a busy one degrades rather than fails.
  static const qualitySteps = [82, 70, 58, 45, 35];

  /// Below this the image is unusable; better to refuse than to store mush.
  static const minQuality = 30;
}

/// A photo prepared for storage.
class PreparedPhoto {
  const PreparedPhoto({
    required this.base64Data,
    required this.width,
    required this.height,
    required this.quality,
    required this.originalBytes,
  });

  final String base64Data;
  final int width;
  final int height;
  final int quality;
  final int originalBytes;

  int get storedBytes => base64Data.length;

  /// How much smaller the stored copy is, as a percentage.
  int get reductionPercent => originalBytes == 0
      ? 0
      : (100 - (storedBytes * 100 / originalBytes)).round();
}

/// Raised when an image cannot be made to fit.
/// Why a picked photo could not be stored.
///
/// A cause rather than a sentence: the message a parent reads has to follow
/// the interface language, and this layer has no business knowing what that
/// is. [photoProblemText] turns it into words.
enum PhotoProblem { notAnImage, stillTooLarge }

class PhotoTooLargeException implements Exception {
  const PhotoTooLargeException(this.problem);

  final PhotoProblem problem;

  @override
  String toString() => 'PhotoTooLargeException(${problem.name})';
}

/// Longest-edge-preserving target size for [width] x [height].
///
/// Returns the original dimensions when the image is already small enough —
/// upscaling a thumbnail to 1280 would only waste bytes.
({int width, int height}) targetSize(
  int width,
  int height, {
  int maxEdge = PhotoLimits.maxEdge,
}) {
  final longest = width > height ? width : height;
  if (longest <= maxEdge) return (width: width, height: height);
  final scale = maxEdge / longest;
  return (
    width: (width * scale).round().clamp(1, maxEdge),
    height: (height * scale).round().clamp(1, maxEdge),
  );
}

/// Resizes and re-encodes [bytes] until the base64 form fits the budget.
///
/// Pure apart from the codec, so the ladder logic is testable without a
/// browser or a camera.
PreparedPhoto preparePhoto(Uint8List bytes) {
  // decodeImage does not merely return null on rubbish input: it probes
  // format after format, and a truncated header makes one of those decoders
  // throw a RangeError while reading past the end. Unhandled, that reaches
  // the user as a crash instead of "this file is not an image".
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } on Object {
    decoded = null;
  }

  if (decoded == null) {
    throw const PhotoTooLargeException(PhotoProblem.notAnImage);
  }

  final size = targetSize(decoded.width, decoded.height);
  final resized = size.width == decoded.width && size.height == decoded.height
      ? decoded
      : img.copyResize(
          decoded,
          width: size.width,
          height: size.height,
          interpolation: img.Interpolation.average,
        );

  for (final quality in PhotoLimits.qualitySteps) {
    final encoded = img.encodeJpg(resized, quality: quality);
    if (encoded.length <= PhotoLimits.maxBinaryBytes) {
      return PreparedPhoto(
        base64Data: base64Encode(encoded),
        width: resized.width,
        height: resized.height,
        quality: quality,
        originalBytes: bytes.length,
      );
    }
  }

  throw const PhotoTooLargeException(PhotoProblem.stillTooLarge);
}
