import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/child.dart';
import '../../models/photo.dart';
import '../../providers.dart';

/// Thumbnail that fetches its own bytes.
///
/// Diary entries carry only photo ids, so each tile pulls what it needs when
/// it is built. The provider keeps the result alive, so scrolling back and
/// forth does not re-read the document.
class PhotoThumb extends ConsumerWidget {
  const PhotoThumb({required this.photoId, this.size = 72, super.key});

  final String photoId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final photo = ref.watch(photoProvider(photoId));

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: photo.when(
          loading: () => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, _) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.broken_image_outlined,
              color: theme.colorScheme.outline,
            ),
          ),
          data: (p) => p == null
              ? Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: theme.colorScheme.outline,
                  ),
                )
              : InkWell(
                  onTap: () => _open(context, p),
                  child: Image.memory(p.bytes, fit: BoxFit.cover),
                ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Photo photo) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: InteractiveViewer(
                maxScale: 5,
                child: Image.memory(photo.bytes),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      photo.caption.isEmpty
                          ? '${photo.width}×${photo.height}'
                          : photo.caption,
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A child's face, or a coloured initial while there is no photo.
///
/// Never an empty grey circle: the profile switcher is how a parent of two
/// tells whose day they are looking at, and a photo does that in a glance
/// where a name in small type does not.
class ChildAvatar extends ConsumerWidget {
  const ChildAvatar({required this.child, this.size = 46, super.key});

  final Child child;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Two adjacent validated slots, so siblings differ by more than a label.
    final accent = VizPalette.slot(
      child.gender == Gender.male ? 0 : 4,
      theme.brightness,
    );
    final radius = BorderRadius.circular(size / 3);

    final photoId = child.photoUrl;
    if (photoId == null || photoId.isEmpty) {
      return _Placeholder(child: child, size: size, accent: accent);
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: ref
            .watch(photoProvider(photoId))
            .maybeWhen(
              data: (p) => p == null
                  ? _Placeholder(child: child, size: size, accent: accent)
                  : Image.memory(p.bytes, fit: BoxFit.cover),
              orElse: () =>
                  _Placeholder(child: child, size: size, accent: accent),
            ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.child,
    required this.size,
    required this.accent,
  });

  final Child child;
  final double size;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(
        child.gender == Gender.male ? Icons.boy : Icons.girl,
        color: accent,
        size: size * 0.55,
      ),
    );
  }
}

/// Row of thumbnails for a diary entry or a medical record.
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({required this.photoIds, super.key});

  final List<String> photoIds;

  @override
  Widget build(BuildContext context) {
    if (photoIds.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final id in photoIds) PhotoThumb(photoId: id)],
    );
  }
}
