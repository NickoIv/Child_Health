import 'package:child_health_tracker/knowledge/article.dart';
import 'package:child_health_tracker/knowledge/knowledge_base.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where the numbers come from.
///
/// The base already has to cite something; this is the stricter rule, and it
/// exists because of what these articles actually contain. «Парацетамол — 15
/// мг на кг веса» and «до 3 месяцев и 38 °C — скорая» are the two kinds of
/// sentence a parent acts on at three in the morning without checking, and a
/// wrong digit in either is the worst thing this app could do.
///
/// The app gives guidance and the doctor decides — that is stated on every
/// screen that carries one of these articles. It is not a licence for a
/// number nobody can trace: a threshold with no named guideline behind it is
/// an opinion in the shape of a fact.
void main() {
  /// Bodies whose paediatric guidance these articles are allowed to rest on.
  ///
  /// A closed list on purpose. Anything else — a blog, a forum, a clinic's
  /// marketing page — is not a source for a dose, however sensible it reads.
  const trusted = [
    'воз',
    'who',
    'nice',
    'aap',
    'american academy of pediatrics',
    'healthychildren',
    'cdc',
    'nhs',
    'nih',
    'lactmed',
    'unicef',
    'юнисеф',
    'мз рк',
    'министерств',
    'постановление правительства',
    'национальный календарь',
    'esphgan',
    'espghan',
  ];

  bool isTrusted(KbSource source) {
    final title = source.title.toLowerCase();
    return trusted.any(title.contains);
  }

  /// A sentence carrying a figure a parent could act on. Any digit counts:
  /// an age, a dose, a threshold, a number of days.
  bool hasNumber(String text) => RegExp(r'\d').hasMatch(text);

  List<String> numericClaimsOf(KbArticle article) => [
        ...article.emergency,
        ...article.doNow,
        ...article.callDoctor,
        ...article.details,
      ].where(hasNumber).toList();

  test('the base is the 47 articles it is supposed to be', () {
    expect(knowledgeBase, hasLength(47));
  });

  test('there really are around two hundred numeric claims to check', () {
    // The figure in the review export. It is asserted so that a rewrite that
    // silently drops half the thresholds is noticed by something.
    final total = knowledgeBase.fold<int>(
      0,
      (sum, article) => sum + numericClaimsOf(article).length,
    );
    expect(total, greaterThan(150));
  });

  for (final article in knowledgeBase) {
    final claims = numericClaimsOf(article);
    if (claims.isEmpty) continue;

    test('«${article.title}» rests its ${claims.length} figures on a named '
        'guideline', () {
      expect(
        article.sources.any(isTrusted),
        isTrue,
        reason: 'sources are: '
            '${article.sources.map((s) => s.title).join(' | ')}',
      );
    });
  }

  group('every citation', () {
    for (final article in knowledgeBase) {
      for (final source in article.sources) {
        test('«${source.title}» in ${article.id} is usable', () {
          expect(source.title.trim(), isNotEmpty);
          // A link is optional — several of these are printed guidelines —
          // but one that exists has to be a link a parent can open safely.
          if (source.url.isNotEmpty) {
            expect(
              source.url,
              startsWith('https://'),
              reason: 'a source read by a parent is fetched over https',
            );
            expect(source.url, isNot(contains(' ')));
          }
        });
      }
    }
  });
}
