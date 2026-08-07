/// Where an answer came from.
///
/// This file used to hold a gate. Two word lists decided, before the model was
/// called, whether a question was «медицинский» or «бытовой», and anything the
/// lists did not recognise was treated as medical — which meant answered only
/// from forty-seven articles, or not at all. Everything outside a child's
/// health was refused outright by the prompt.
///
/// That was asked to go three times, the last time plainly: «я хочу
/// полноценного ИИ помощника который будет отвечать на любые вопросы». So the
/// gate is gone. There is one prompt, it answers anything, and the only thing
/// left of the old machinery is this two-value label — which no longer decides
/// what may be said, only what the screen puts underneath it.
///
/// What did not move: the deterministic emergency check in
/// `assistant_service.dart` still runs before the model on every question. It
/// fires on «не дышит» and its neighbours and costs an ordinary question
/// nothing.
library;

enum AnswerMode {
  /// The knowledge base had material on this and the answer was built from it.
  /// The articles are listed under the reply as its sources.
  fromBase,

  /// The model's own knowledge — which is most questions, and is no longer a
  /// second-class outcome.
  general,
}
