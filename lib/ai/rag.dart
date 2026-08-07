import '../knowledge/article.dart';
import '../knowledge/knowledge_base.dart';

/// Retrieval for the assistant.
///
/// The model is never allowed to answer from its own memory. It gets a slice
/// of the knowledge base as context and is instructed to work only from it —
/// so what this file selects is the entire universe the answer can come from.
/// Retrieval quality is therefore a safety property, not just a relevance one.
class RetrievedContext {
  const RetrievedContext({required this.articles, required this.promptBlock});

  final List<KbArticle> articles;

  /// The articles rendered for the prompt.
  final String promptBlock;

  bool get isEmpty => articles.isEmpty;
}

/// Picks the articles most likely to answer [question].
///
/// [ageMonths] biases retrieval towards age-appropriate material — advice for
/// a newborn and for a five-year-old differ enough that mixing them is unsafe.
///
/// [ageFallback] is what a medical question gets when the search finds nothing;
/// an everyday one is left with an empty context rather than a handful of
/// unrelated articles listed underneath it as its sources.
RetrievedContext retrieveFor(
  String question, {
  int? ageMonths,
  int limit = 4,
  bool ageFallback = true,
}) {
  // Named, not merely mentioned. What comes back here is the only thing the
  // strict prompt may answer from, so an article that shares one common word
  // with the question is not a source — it is noise that turns into «в моей
  // базе нет ответа».
  var matches = searchArticles(
    question,
    ageMonths: ageMonths,
    requireStrongMatch: true,
  );

  // A question the search cannot place at all still deserves the age-relevant
  // basics rather than an empty context, which would make the model refuse
  // even simple things.
  if (matches.isEmpty && ageMonths != null && ageFallback) {
    matches = articlesForAge(ageMonths).take(limit).toList();
  }

  final selected = matches.take(limit).toList();
  return RetrievedContext(
    articles: selected,
    promptBlock: selected.map(_render).join('\n\n---\n\n'),
  );
}

/// One article as plain text for the prompt. Keeps the section labels so the
/// model can tell an instruction from a red flag from background reading.
String _render(KbArticle a) {
  final buffer = StringBuffer()
    ..writeln('# ${a.title} [id: ${a.id}]')
    ..writeln(a.summary)
    ..writeln();

  if (a.emergency.isNotEmpty) {
    buffer.writeln('СКОРАЯ ПОМОЩЬ (103):');
    for (final e in a.emergency) {
      buffer.writeln('- $e');
    }
    buffer.writeln();
  }

  buffer.writeln('ЧТО ДЕЛАТЬ СЕЙЧАС:');
  for (final d in a.doNow) {
    buffer.writeln('- $d');
  }
  buffer.writeln();

  buffer.writeln('КОГДА К ВРАЧУ:');
  for (final c in a.callDoctor) {
    buffer.writeln('- $c');
  }

  if (a.details.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('ПОДРОБНОСТИ:');
    for (final d in a.details) {
      buffer.writeln('- $d');
    }
  }

  buffer
    ..writeln()
    ..writeln('ИСТОЧНИКИ: ${a.sources.map((s) => s.title).join('; ')}');

  return buffer.toString();
}
