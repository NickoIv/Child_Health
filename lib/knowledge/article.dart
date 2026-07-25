/// Sections of the knowledge base, in the order a parent meets them.
enum KbSection {
  urgent('Тревожные признаки', 'Когда действовать немедленно'),
  newborn('Новорождённый', 'Первые месяцы'),
  feeding('Кормление', 'ГВ, смесь, прикорм'),
  sleep('Сон', 'Режим и трудности'),
  illness('Болезни', 'Симптомы и уход'),
  development('Развитие', 'Что и когда осваивает ребёнок'),
  care('Уход и безопасность', 'Быт, гигиена, дом'),
  mother('Маме', 'Здоровье и состояние мамы');

  const KbSection(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

/// A cited source. Every article carries at least one — an unsourced claim
/// about a child's health has no place here.
class KbSource {
  const KbSource(this.title, {this.url = ''});

  final String title;
  final String url;
}

/// One knowledge-base article.
///
/// The shape is deliberately rigid. A tired parent at 3am needs the same three
/// things every time, in the same order: what to do now, when to call the
/// doctor, when to call an ambulance. Long-form explanation comes after, and
/// is optional. This is the whole point of the format — it is what makes the
/// base different from a search-engine results page.
class KbArticle {
  const KbArticle({
    required this.id,
    required this.section,
    required this.title,
    required this.summary,
    required this.doNow,
    required this.callDoctor,
    required this.sources,
    this.emergency = const [],
    this.details = const [],
    this.minMonths = 0,
    this.maxMonths = 216,
    this.tags = const [],
  });
  // The format invariants — every article must say what to do now, when to
  // seek help, and where the claim comes from — are enforced by
  // test/knowledge_base_test.dart rather than by asserts here. A const
  // constructor cannot inspect list contents, and a test names the offending
  // article instead of failing anonymously at construction.

  final String id;
  final KbSection section;
  final String title;

  /// One sentence, shown in lists. No preamble, no "в этой статье мы".
  final String summary;

  /// Concrete actions, imperative mood. This is what gets read first.
  final List<String> doNow;

  /// Thresholds for a planned visit or a call to the paediatrician.
  final List<String> callDoctor;

  /// Signs that mean an ambulance, not a wait-and-see. Rendered in red and
  /// pinned above everything else.
  final List<String> emergency;

  /// Optional background, for when there is time to read.
  final List<String> details;

  final List<KbSource> sources;

  /// Age range the article is relevant for, in months.
  final int minMonths;
  final int maxMonths;

  /// Extra search terms — the words a parent would actually type, including
  /// colloquial ones that never appear in the article body.
  final List<String> tags;

  bool relevantAt(int ageMonths) =>
      ageMonths >= minMonths && ageMonths <= maxMonths;

  /// Everything searchable, lowercased once at call time.
  String get searchableText => [
    title,
    summary,
    ...tags,
    ...doNow,
    ...callDoctor,
    ...emergency,
    ...details,
  ].join(' ').toLowerCase();
}
