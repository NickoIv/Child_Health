import 'package:child_health_tracker/knowledge/article.dart';
import 'package:child_health_tracker/knowledge/knowledge_base.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('format invariants', () {
    // These are the rules that make the base different from a search results
    // page. A const constructor cannot check them, so they are checked here —
    // and the failure message names the offending article.
    for (final article in knowledgeBase) {
      group('«${article.title}» (${article.id})', () {
        test('says what to do now', () {
          expect(article.doNow, isNotEmpty);
        });

        test('says when to see a doctor', () {
          expect(article.callDoctor, isNotEmpty);
        });

        test('cites at least one source', () {
          expect(article.sources, isNotEmpty);
          for (final s in article.sources) {
            expect(s.title.trim(), isNotEmpty);
          }
        });

        test('has a one-line summary without filler', () {
          expect(article.summary.trim(), isNotEmpty);
          expect(
            article.summary.length,
            lessThan(120),
            reason: 'the summary is shown in lists and must stay one line',
          );
          for (final filler in const [
            'в этой статье',
            'мы расскажем',
            'давайте разберёмся',
            'как известно',
          ]) {
            expect(
              article.summary.toLowerCase(),
              isNot(contains(filler)),
              reason: 'no preamble — the parent has no time for it',
            );
          }
        });

        test('has a sane age range', () {
          expect(article.minMonths, greaterThanOrEqualTo(0));
          expect(article.maxMonths, greaterThan(article.minMonths));
        });
      });
    }

    test('article ids are unique', () {
      final ids = knowledgeBase.map((a) => a.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every urgent article carries emergency signs', () {
      for (final a in knowledgeBase.where(
        (a) => a.section == KbSection.urgent,
      )) {
        expect(
          a.emergency,
          isNotEmpty,
          reason: '«${a.title}» is filed as urgent but lists no red flags',
        );
      }
    });

    test('the base covers every section it declares', () {
      for (final section in KbSection.values) {
        expect(
          articlesInSection(section),
          isNotEmpty,
          reason: 'section «${section.title}» has no articles',
        );
      }
    });
  });

  group('lookup', () {
    test('finds an article by id', () {
      expect(articleById('fever')?.title, contains('Температура'));
    });

    test('returns null for an unknown id', () {
      expect(articleById('no-such-article'), isNull);
    });
  });

  group('articlesForAge', () {
    test('excludes material outside the age range', () {
      final forTeen = articlesForAge(160);
      expect(forTeen.any((a) => a.id == 'colic'), isFalse);
      expect(forTeen.any((a) => a.id == 'jaundice'), isFalse);
    });

    test('includes newborn material for a newborn', () {
      final forNewborn = articlesForAge(1);
      expect(forNewborn.any((a) => a.id == 'colic'), isTrue);
      expect(forNewborn.any((a) => a.id == 'jaundice'), isTrue);
      expect(forNewborn.any((a) => a.id == 'safe-sleep'), isTrue);
    });

    test('puts age-specific articles before general ones', () {
      final list = articlesForAge(2);
      final colic = list.indexWhere((a) => a.id == 'colic');
      final generic = list.indexWhere((a) => a.id == 'red-flags');
      expect(colic, lessThan(generic));
    });
  });

  group('search', () {
    test('an empty query returns nothing', () {
      expect(searchArticles(''), isEmpty);
      expect(searchArticles('   '), isEmpty);
    });

    test('finds an article by its title word', () {
      final results = searchArticles('температура');
      expect(results.first.id, 'fever');
    });

    test('finds an article by a colloquial tag absent from the text', () {
      // A parent types "сопли", the article is titled "Насморк".
      final results = searchArticles('сопли');
      expect(results.map((a) => a.id), contains('runny-nose'));
    });

    test('finds the choking article by everyday wording', () {
      final results = searchArticles('подавился');
      expect(results.first.id, 'choking');
    });

    test('is case-insensitive', () {
      expect(
        searchArticles('СЫПЬ').map((a) => a.id),
        contains('rash'),
      );
    });

    test('ranks urgent material higher on an ambiguous query', () {
      final results = searchArticles('дышать');
      expect(
        results.first.section,
        KbSection.urgent,
        reason: 'when the words are ambiguous the safer article comes first',
      );
    });

    test('returns nothing for a query with no match', () {
      expect(searchArticles('квантовая механика'), isEmpty);
    });

    test('finds the topics a parent actually searches for', () {
      // The words on the left are what gets typed at 3am; the ids on the
      // right are what must come back. A base that cannot be searched in
      // the parent's own words is a base nobody reads.
      const expectations = {
        'ветрянка': 'chickenpox',
        'болит ухо': 'otitis',
        'закисли глазки': 'conjunctivitis',
        'лающий кашель': 'croup',
        'приучить к горшку': 'potty-training',
        'истерика': 'tantrums',
        'не говорит': 'speech',
        'уплотнение в груди': 'mastitis',
        'не радуюсь ребенку': 'postpartum-mood',
        'адаптация': 'kindergarten',
        'проглотил': 'home-safety',
        'температура без симптомов': 'roseola',
      };
      expectations.forEach((query, id) {
        final ids = searchArticles(query).map((a) => a.id).take(3);
        expect(
          ids,
          contains(id),
          reason: '«$query» should surface "$id", got ${ids.toList()}',
        );
      });
    });

    test('ignores single-character noise', () {
      expect(searchArticles('а'), isEmpty);
    });
  });
}
