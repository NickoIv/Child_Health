import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../core/photos/compression.dart';
import '../models/photo.dart';

/// Storage for photos and scans (requirements 2.2 and 2.5).
///
/// Reads are one-shot rather than streamed: a photo never changes after it is
/// written, so a live listener would only cost reads.
abstract class PhotoRepository {
  Future<Photo> upload({
    required String childId,
    required Uint8List bytes,
    String caption = '',
  });

  Future<Photo?> byId(String photoId);

  Future<void> delete(String photoId);
}

const _uuid = Uuid();

class MemoryPhotoRepository implements PhotoRepository {
  final _store = <String, Photo>{};

  @override
  Future<Photo> upload({
    required String childId,
    required Uint8List bytes,
    String caption = '',
  }) async {
    final prepared = preparePhoto(bytes);
    final photo = Photo(
      id: _uuid.v4(),
      childId: childId,
      base64Data: prepared.base64Data,
      width: prepared.width,
      height: prepared.height,
      createdAt: DateTime.now(),
      caption: caption,
    );
    _store[photo.id] = photo;
    return photo;
  }

  @override
  Future<Photo?> byId(String photoId) async => _store[photoId];

  @override
  Future<void> delete(String photoId) async => _store.remove(photoId);
}
