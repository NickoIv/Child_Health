import 'package:flutter/material.dart';

import '../shared/widgets.dart';
import 'family_section.dart';

/// Who else can see this child, as a tab of its own.
///
/// It used to be a card three quarters of the way down settings, which is
/// where a feature goes to be never found. A family is not a setting: it is
/// the second person in the app, and the whole of family mode — the invitation,
/// the roles, the read-only guarantee — hangs off this one screen.
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageBody(
      maxWidth: 720,
      children: [FamilySection()],
    );
  }
}
