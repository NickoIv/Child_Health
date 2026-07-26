import 'article.dart';
import 'content/baby_care_articles.dart';
import 'content/care_articles.dart';
import 'content/family_articles.dart';
import 'content/illness_articles.dart';
import 'content/infection_articles.dart';
import 'content/more_illness_articles.dart';
import 'content/newborn_articles.dart';

/// The whole knowledge base, bundled into the app.
///
/// Deliberately compiled in rather than fetched: a parent in a clinic queue
/// or a village with one bar of signal needs the answer to open instantly.
/// Nothing here touches the network.
const knowledgeBase = <KbArticle>[
  ...illnessArticles,
  ...newbornArticles,
  ...careArticles,
  ...infectionArticles,
  ...familyArticles,
  ...babyCareArticles,
  ...moreIllnessArticles,
];

/// Articles of one section, urgent ones first.
List<KbArticle> articlesInSection(KbSection section) =>
    knowledgeBase.where((a) => a.section == section).toList();

KbArticle? articleById(String id) {
  for (final a in knowledgeBase) {
    if (a.id == id) return a;
  }
  return null;
}

/// Articles relevant to a child of [ageMonths], most specific first.
///
/// An article scoped to 0-6 months outranks one that applies to all ages,
/// because a narrower range means it was written for exactly this stage.
List<KbArticle> articlesForAge(int ageMonths) {
  final matching = knowledgeBase.where((a) => a.relevantAt(ageMonths)).toList();
  matching.sort((a, b) {
    final spanA = a.maxMonths - a.minMonths;
    final spanB = b.maxMonths - b.minMonths;
    return spanA.compareTo(spanB);
  });
  return matching;
}

/// Function words that carry no meaning but appear in nearly every article.
///
/// Without this, «не говорит» scored the same on «не» as on «говорит», and the
/// noise buried the article the parent was looking for. Short and hand-picked
/// rather than a full stopword corpus — these are the ones that actually show
/// up in how parents phrase a question.
const _stopWords = {
  'не', 'и', 'в', 'на', 'у', 'от', 'до', 'по', 'за', 'из', 'о', 'об',
  'что', 'как', 'при', 'для', 'ли', 'же', 'бы', 'то', 'это', 'его', 'её',
  'ее', 'мой', 'моя', 'мне', 'ему', 'ей', 'мы', 'он', 'она', 'они',
  'есть', 'быть', 'делать', 'можно', 'нужно', 'надо',
};

/// Ranked full-text search over the base.
///
/// Plain substring scoring, no stemming: the base is small enough that the
/// simple thing works, and a parent typing "сопли" should find the article
/// titled "Насморк" — which is what the `tags` field is for.
List<KbArticle> searchArticles(String query, {int? ageMonths}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final words = q.split(RegExp(r'\s+')).where((t) => t.length > 1).toList();
  var terms = words.where((t) => !_stopWords.contains(t)).toList();
  // A query made entirely of function words still deserves an attempt rather
  // than an empty screen.
  if (terms.isEmpty) terms = words;
  if (terms.isEmpty) return const [];

  final scored = <({KbArticle article, int score})>[];
  for (final article in knowledgeBase) {
    final title = article.title.toLowerCase();
    final tags = article.tags.join(' ').toLowerCase();
    final body = article.searchableText;

    var score = 0;
    for (final term in terms) {
      if (title.contains(term)) {
        score += 10;
      }
      if (tags.contains(term)) {
        score += 6;
      }
      if (body.contains(term)) {
        score += 1;
      }
    }
    if (score == 0) continue;

    // Urgent material wins ties: when a parent's words are ambiguous, the
    // safer article should be the one they see first.
    if (article.section == KbSection.urgent) score += 3;
    if (ageMonths != null && article.relevantAt(ageMonths)) score += 2;

    scored.add((article: article, score: score));
  }

  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored.map((s) => s.article).toList();
}
