import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/l10n/labels.dart';
import '../../core/photos/compression.dart';
import '../../core/theme/app_sheet.dart';
import '../../core/theme/app_snack.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass.dart';
import '../../l10n/app_localizations.dart';
import '../../models/development_log.dart';
import '../../providers.dart';
import '../shared/photo_widgets.dart';
import '../shared/widgets.dart';
import 'photo_album.dart';

/// The child, one photograph at a time.
///
/// A carousel rather than a grid, and that is the whole design: a grid is for
/// finding a picture you already know exists, and this is for looking at them.
/// One at a time, big, with the day and the words underneath — which is how
/// somebody actually shows a grandparent what the week looked like.
///
/// Everything in it comes from the diary, so a photograph attached to the
/// first tooth is in here beside one added for its own sake, and neither had
/// to be filed twice.
class PhotosScreen extends ConsumerStatefulWidget {
  const PhotosScreen({super.key});

  @override
  ConsumerState<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends ConsumerState<PhotosScreen> {
  final _pages = PageController(viewportFraction: 0.86);
  int _current = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final child = ref.watch(selectedChildProvider);
    if (child == null) return const NoChildPlaceholder();

    final logsAsync = ref.watch(logsProvider);
    if (logsAsync.hasError) {
      return PageBody(
        children: [
          SectionCard(
            title: l.navPhotos,
            icon: Icons.photo_library_outlined,
            child: ErrorState(
              error: logsAsync.error!,
              onRetry: () => ref.invalidate(logsProvider),
            ),
          ),
        ],
      );
    }

    final album = buildAlbum(logsAsync.value ?? const <DevelopmentLog>[]);
    final readOnly = ref.watch(isReadOnlyProvider);
    // A photo removed while it was on screen must not leave the index past the
    // end of the list.
    final index = album.isEmpty ? 0 : _current.clamp(0, album.length - 1);

    return Scaffold(
      floatingActionButton: readOnly
          ? null
          : liftedFab(
              context,
              FloatingActionButton.extended(
                onPressed: () => _add(child.id),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(l.photosAdd),
              ),
            ),
      body: album.isEmpty
          ? PageBody(
              children: [
                SectionCard(
                  title: l.navPhotos,
                  icon: Icons.photo_library_outlined,
                  child: EmptyState(
                    icon: Icons.photo_camera_outlined,
                    message: l.photosEmpty,
                    hint: l.photosEmptyHint,
                  ),
                ),
              ],
            )
          : _Album(
              album: album,
              index: index,
              pages: _pages,
              readOnly: readOnly,
              onChanged: (i) => setState(() => _current = i),
              onEdit: () => _edit(album[index]),
            ),
    );
  }

  Future<void> _add(String childId) async {
    await showPhotoEntrySheet(context, ref, childId: childId);
  }

  Future<void> _edit(AlbumPhoto photo) async {
    await showPhotoEntrySheet(
      context,
      ref,
      childId: photo.log.childId,
      existing: photo,
    );
  }
}

class _Album extends StatelessWidget {
  const _Album({
    required this.album,
    required this.index,
    required this.pages,
    required this.readOnly,
    required this.onChanged,
    required this.onEdit,
  });

  final List<AlbumPhoto> album;
  final int index;
  final PageController pages;
  final bool readOnly;
  final ValueChanged<int> onChanged;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = album[index];

    return Column(
      children: [
        const SizedBox(height: 8),
        SectionLabel(
          text: l.navPhotos,
          action: Text(
            l.photosCount(album.length),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Warm.onCardSoft(theme.brightness),
              fontFeatures: AppTheme.tabular,
            ),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: pages,
            onPageChanged: onChanged,
            itemCount: album.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: _Slide(photo: album[i]),
            ),
          ),
        ),
        _Caption(photo: current, readOnly: readOnly, onEdit: onEdit),
      ],
    );
  }
}

/// One photograph, filling its card.
class _Slide extends StatelessWidget {
  const _Slide({required this.photo});

  final AlbumPhoto photo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      // Tapping opens the viewer the diary already uses, on the set this
      // picture arrived in rather than on the whole album.
      onTap: () => showPhotoViewer(
        context,
        photoIds: photo.album,
        initialIndex: photo.album.indexOf(photo.photoId),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Warm.card(theme.brightness),
          borderRadius: BorderRadius.circular(Warm.cardRadius),
          boxShadow: Warm.shadow(theme.brightness),
        ),
        clipBehavior: Clip.antiAlias,
        child: PhotoFill(photoId: photo.photoId),
      ),
    );
  }
}

/// The day and the words, under the picture.
class _Caption extends StatelessWidget {
  const _Caption({
    required this.photo,
    required this.readOnly,
    required this.onEdit,
  });

  final AlbumPhoto photo;
  final bool readOnly;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // The pencil leads the row rather than trailing it. The «Добавить фото»
    // button floats over the bottom right corner, and a control underneath it
    // is a control that takes the other one's taps.
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!readOnly)
            IconButton(
              tooltip: l.commonEdit,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dayMonthYear.format(photo.date)}, '
                  '${timeOfDay.format(photo.date)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFeatures: AppTheme.tabular,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // The entry's own words where there are any, and what kind
                  // of entry it was where there are none — «Кормление» under a
                  // photograph says more than an empty line.
                  photo.caption.isNotEmpty
                      ? photo.caption
                      : localizedLogTitle(l, photo.log),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Warm.onCardSoft(theme.brightness),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Adding a photograph, or correcting one already in.
///
/// The same sheet for both, because they are the same three questions: which
/// picture, which day, and what to remember about it.
Future<void> showPhotoEntrySheet(
  BuildContext context,
  WidgetRef ref, {
  required String childId,
  AlbumPhoto? existing,
}) {
  return showAppSheet<void>(
    context,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _PhotoEntrySheet(childId: childId, existing: existing),
    ),
  );
}

class _PhotoEntrySheet extends ConsumerStatefulWidget {
  const _PhotoEntrySheet({required this.childId, this.existing});

  final String childId;
  final AlbumPhoto? existing;

  @override
  ConsumerState<_PhotoEntrySheet> createState() => _PhotoEntrySheetState();
}

class _PhotoEntrySheetState extends ConsumerState<_PhotoEntrySheet> {
  late final _description = TextEditingController(
    text: widget.existing?.log.description ?? '',
  );
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  late final List<String> _photoIds = [
    ...?widget.existing?.log.photos,
  ];

  bool _uploading = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  bool get _isNew => widget.existing == null;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.photo_camera_outlined,
                        color: Warm.accentOn(theme.brightness),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isNew ? l.photosAdd : l.photosEdit,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  SectionLabel(text: l.diaryPhotos),
                  _Picker(
                    photoIds: _photoIds,
                    uploading: _uploading,
                    onAdd: _pick,
                    onRemove: (id) => setState(() => _photoIds.remove(id)),
                  ),
                  if (_error case final message?) ...[
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  SectionLabel(text: l.photosWhen),
                  DateTimeField(
                    value: _date,
                    onChanged: (v) => setState(() => _date = v),
                  ),
                  const SizedBox(height: 18),

                  SectionLabel(text: l.photosAbout),
                  TextField(
                    controller: _description,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(hintText: l.photosAboutHint),
                  ),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Warm.hairline(theme.brightness)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _saving || _photoIds.isEmpty ? null : _save,
                    child: Text(l.commonSave),
                  ),
                  // Only an entry made of the photograph may be deleted from
                  // here. A feed keeps its own record whatever happens to the
                  // picture on it.
                  if (widget.existing?.isStandalone ?? false) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: _saving ? null : _delete,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l.commonDelete),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick() async {
    final files = await ImagePicker().pickMultiImage(imageQuality: 90);
    if (files.isEmpty) return;

    setState(() {
      _uploading = true;
      _error = null;
    });

    final repository = ref.read(photoRepositoryProvider);
    for (final file in files) {
      try {
        final photo = await repository.upload(
          childId: widget.childId,
          bytes: await file.readAsBytes(),
        );
        if (!mounted) return;
        setState(() => _photoIds.add(photo.id));
      } on PhotoTooLargeException catch (e) {
        if (mounted) {
          setState(
            () => _error = photoProblemText(
              AppLocalizations.of(context),
              e.problem,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(
            () => _error = AppLocalizations.of(context).photoUploadFailed('$e'),
          );
        }
      }
    }
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final repository = ref.read(logRepositoryProvider);
    setState(() => _saving = true);

    try {
      final existing = widget.existing;
      if (existing == null) {
        await repository.add(
          photoLog(
            childId: widget.childId,
            date: _date,
            description: _description.text,
            photoIds: List.of(_photoIds),
          ),
        );
      } else {
        await repository.update(
          editedPhotoLog(
            existing.log,
            date: _date,
            description: _description.text,
            photoIds: _photoIds,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showAppSnack(
        appSnack(friendlyError(l, e), kind: SnackKind.problem),
      );
      return;
    }

    if (!mounted) return;
    navigator.pop();
    messenger.showAppSnack(appSnack(l.photosSaved, kind: SnackKind.done));
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);

    try {
      await ref.read(logRepositoryProvider).delete(widget.existing!.log.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showAppSnack(
        appSnack(friendlyError(l, e), kind: SnackKind.problem),
      );
      return;
    }

    if (!mounted) return;
    navigator.pop();
    messenger.showAppSnack(appSnack(l.photosDeleted, kind: SnackKind.done));
  }
}

/// The thumbnails on the sheet, with a way to add and to drop one.
class _Picker extends StatelessWidget {
  const _Picker({
    required this.photoIds,
    required this.uploading,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photoIds;
  final bool uploading;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final id in photoIds)
          Stack(
            children: [
              PhotoThumb(photoId: id, size: 72),
              Positioned(
                right: -6,
                top: -6,
                child: IconButton(
                  iconSize: 18,
                  tooltip: l.commonDelete,
                  onPressed: () => onRemove(id),
                  icon: const Icon(Icons.cancel),
                ),
              ),
            ],
          ),
        if (uploading)
          const SizedBox(
            width: 72,
            height: 72,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          _AddTile(onTap: onAdd),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Warm.soft(theme.brightness),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.add_a_photo_outlined,
          color: Warm.accentOn(theme.brightness),
        ),
      ),
    );
  }
}
