import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/child.dart';
import '../../providers.dart';

/// Thumbnail that fetches its own bytes.
///
/// Diary entries carry only photo ids, so each tile pulls what it needs when
/// it is built. The provider keeps the result alive, so scrolling back and
/// forth does not re-read the document.
class PhotoThumb extends ConsumerWidget {
  const PhotoThumb({
    required this.photoId,
    this.size = 72,
    this.album = const [],
    super.key,
  });

  final String photoId;
  final double size;

  /// Every photo of the entry this thumbnail belongs to, so the viewer can
  /// swipe between them. Empty for a thumbnail that stands alone.
  final List<String> album;

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
            color: Warm.soft(theme.brightness),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, _) => Container(
            color: Warm.soft(theme.brightness),
            child: Icon(
              Icons.broken_image_outlined,
              color: theme.colorScheme.outline,
            ),
          ),
          data: (p) => p == null
              ? Container(
                  color: Warm.soft(theme.brightness),
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: theme.colorScheme.outline,
                  ),
                )
              : InkWell(
                  onTap: () => _open(context),
                  child: Image.memory(p.bytes, fit: BoxFit.cover),
                ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    final ids = album.contains(photoId) ? album : [photoId];
    showPhotoViewer(
      context,
      photoIds: ids,
      initialIndex: ids.indexOf(photoId),
    );
  }
}

/// A photograph filling whatever box it is given.
///
/// [PhotoThumb] is square, tappable and small; the album's carousel wants the
/// opposite of all three — the whole card, cropped to it, with the tap handled
/// by the slide around it.
class PhotoFill extends ConsumerWidget {
  const PhotoFill({required this.photoId, super.key});

  final String photoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final photo = ref.watch(photoProvider(photoId));

    return photo.when(
      loading: () => ColoredBox(
        color: Warm.soft(theme.brightness),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => ColoredBox(
        color: Warm.soft(theme.brightness),
        child: Icon(
          Icons.broken_image_outlined,
          color: theme.colorScheme.outline,
        ),
      ),
      data: (p) => p == null
          ? ColoredBox(
              color: Warm.soft(theme.brightness),
              child: Icon(
                Icons.image_not_supported_outlined,
                color: theme.colorScheme.outline,
              ),
            )
          : Image.memory(
              p.bytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
    );
  }
}

/// Opens the full-screen viewer.
///
/// A route rather than a dialog: a photo filling the screen wants the back
/// gesture and the system back button to close it, which is what popping a
/// route gives for free.
void showPhotoViewer(
  BuildContext context, {
  required List<String> photoIds,
  int initialIndex = 0,
}) {
  if (photoIds.isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _PhotoViewer(
        photoIds: photoIds,
        initialIndex: initialIndex.clamp(0, photoIds.length - 1),
      ),
    ),
  );
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.photoIds, required this.initialIndex});

  final List<String> photoIds;
  final int initialIndex;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  /// While a photo is zoomed in, dragging has to pan it rather than turn the
  /// page — otherwise the first drag after pinching flicks to the next photo.
  bool _zoomed = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final many = widget.photoIds.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l.commonClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: many
            ? Text(
                '${_index + 1} / ${widget.photoIds.length}',
                style: const TextStyle(fontSize: 16),
              )
            : null,
      ),
      body: PageView.builder(
        controller: _pages,
        physics: _zoomed
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        onPageChanged: (i) => setState(() {
          _index = i;
          _zoomed = false;
        }),
        itemCount: widget.photoIds.length,
        itemBuilder: (context, i) => _ZoomablePhoto(
          key: ValueKey(widget.photoIds[i]),
          photoId: widget.photoIds[i],
          onZoomChanged: (zoomed) {
            if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
          },
        ),
      ),
    );
  }
}

class _ZoomablePhoto extends ConsumerStatefulWidget {
  const _ZoomablePhoto({
    required this.photoId,
    required this.onZoomChanged,
    super.key,
  });

  final String photoId;
  final ValueChanged<bool> onZoomChanged;

  @override
  ConsumerState<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends ConsumerState<_ZoomablePhoto> {
  final _transform = TransformationController();

  @override
  void initState() {
    super.initState();
    _transform.addListener(_reportZoom);
  }

  @override
  void dispose() {
    _transform.removeListener(_reportZoom);
    _transform.dispose();
    super.dispose();
  }

  void _reportZoom() {
    // Row 0 of the matrix carries the horizontal scale; a hair above 1 counts
    // as zoomed, so a stray pinch does not leave the page unswipeable.
    widget.onZoomChanged(_transform.value.getMaxScaleOnAxis() > 1.01);
  }

  /// Double tap zooms to the point touched, and again to go back — the
  /// gesture every photo viewer has, and the only one that works one-handed.
  void _toggleZoom(TapDownDetails details) {
    if (_transform.value.getMaxScaleOnAxis() > 1.01) {
      _transform.value = Matrix4.identity();
      return;
    }
    const scale = 2.5;
    final position = details.localPosition;
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        -position.dx * (scale - 1),
        -position.dy * (scale - 1),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = ref.watch(photoProvider(widget.photoId));

    return photo.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      error: (_, _) => const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white54),
      ),
      data: (p) {
        if (p == null) {
          return const Center(
            child: Icon(Icons.image_not_supported_outlined,
                color: Colors.white54),
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onDoubleTapDown: _toggleZoom,
              // The handler lives on the down event; without this the double
              // tap never registers as one.
              onDoubleTap: () {},
              child: InteractiveViewer(
                transformationController: _transform,
                minScale: 1,
                maxScale: 5,
                child: Center(child: Image.memory(p.bytes)),
              ),
            ),
            if (p.caption.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    p.caption,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
      children: [
        for (final id in photoIds) PhotoThumb(photoId: id, album: photoIds),
      ],
    );
  }
}
