import 'dart:convert';
import 'dart:typed_data';

/// A stored photo.
///
/// Kept in its own `photos` collection rather than inside the diary entry.
/// Firestore returns whole documents — there is no field projection — so an
/// inline image would be downloaded every time the feed is listed, turning a
/// scroll through the diary into megabytes of traffic. The entry keeps only
/// the ids and the bytes are fetched when something actually displays them.
class Photo {
  const Photo({
    required this.id,
    required this.childId,
    required this.base64Data,
    required this.width,
    required this.height,
    required this.createdAt,
    this.caption = '',
  });

  final String id;
  final String childId;
  final String base64Data;
  final int width;
  final int height;
  final DateTime createdAt;
  final String caption;

  Uint8List get bytes => base64Decode(base64Data);

  double get aspectRatio => height == 0 ? 1 : width / height;

  Map<String, dynamic> toMap() => {
    'child_id': childId,
    'data': base64Data,
    'width': width,
    'height': height,
    'created_at': createdAt.toIso8601String(),
    'caption': caption,
  };

  factory Photo.fromMap(String id, Map<String, dynamic> map) => Photo(
    id: id,
    childId: map['child_id'] as String? ?? '',
    base64Data: map['data'] as String? ?? '',
    width: (map['width'] as num?)?.toInt() ?? 0,
    height: (map['height'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    caption: map['caption'] as String? ?? '',
  );
}
