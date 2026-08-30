/// The hiring stages a candidate moves through, and the rule that they only
/// move forward.
///
/// A stage is a record of something that happened: a candidate who reached
/// Interview was interviewed. Moving them back to Screening would not undo the
/// interview, it would only make the record disagree with it — and if a
/// decision is ever questioned, the record is what there is to answer with.
///
/// Pure and self-contained so the rule can be tested without Firestore, and so
/// there is exactly one definition of it for the UI and the write path to
/// share. Two definitions is how a locked button ends up guarding an unlocked
/// database.
abstract final class HiringPipeline {
  static const stages = [
    'Shortlist',
    'Screening',
    'Interview',
    'Technical',
    'Offer',
    'Handover',
  ];

  /// Terminal outcomes. They sit outside the ordered stages: a rejection is
  /// not "further along" than an offer, it is a different kind of ending.
  static const terminal = {'rejected', 'withdrawn'};

  /// Stages that mean the same thing under a different name.
  static const _aliases = {
    'shortlisted': 'shortlist',
    'hired': 'handover',
    'pending': 'shortlist',
  };

  static String normalize(String status) {
    final key = status.toLowerCase().trim();
    return _aliases[key] ?? key;
  }

  /// Position in the pipeline, or -1 for anything that is not a stage.
  static int indexOf(String status) {
    final key = normalize(status);
    for (var i = 0; i < stages.length; i++) {
      if (stages[i].toLowerCase() == key) return i;
    }
    return -1;
  }

  static bool isTerminal(String status) => terminal.contains(normalize(status));

  /// The stage after [status], or null at the end of the pipeline.
  static String? next(String status) {
    if (isTerminal(status)) return null;
    final i = indexOf(status);
    if (i < 0 || i >= stages.length - 1) return null;
    return stages[i + 1].toLowerCase();
  }

  /// Whether [to] is a legal move from [from].
  ///
  /// Forward only, one rule with three exceptions worth stating:
  ///   * A candidate can be rejected or withdrawn from any live stage — that
  ///     is an outcome, not a step backwards.
  ///   * Nothing moves out of a terminal state. Reopening a rejection is a new
  ///     decision and belongs in a new request, where it stays visible.
  ///   * Re-selecting the stage a candidate is already on changes nothing and
  ///     is allowed, so a double-click is not an error.
  static bool canMove({required String from, required String to}) {
    if (isTerminal(from)) return false;
    if (isTerminal(to)) return true;

    final start = indexOf(from);
    final target = indexOf(to);
    if (target < 0) return false;

    // An unrecognised current stage is treated as the beginning rather than
    // as a block: an old document with a status nobody uses any more should
    // not strand the candidate.
    if (start < 0) return true;

    return target >= start;
  }

  /// Why a move was refused, for a message the admin can act on.
  static String refusalReason({required String from, required String to}) {
    if (isTerminal(from)) {
      return 'This candidate is already marked ${normalize(from)}. '
          'Reopening them is a new decision — send them through again rather '
          'than editing the record of the last one.';
    }
    return 'A candidate cannot move back to ${normalize(to)} from '
        '${normalize(from)}. Stages only go forward, so the record keeps '
        'matching what actually happened.';
  }

  /// The stages a candidate on [status] may be moved to, in order.
  static List<String> allowedFrom(String status) => [
        for (final stage in stages)
          if (canMove(from: status, to: stage.toLowerCase()))
            stage.toLowerCase(),
      ];
}
