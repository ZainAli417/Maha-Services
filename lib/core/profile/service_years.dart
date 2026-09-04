/// How long a candidate has actually served, computed from dated roles.
///
/// This exists because a count of jobs was once stored under a field called
/// `experienceYears`, so a candidate with two postings was shown as "2 years"
/// everywhere — including on a profile whose single role ran from 2008 to 2016.
/// A duration and a job count are different measurements, and the only way to
/// stop them being confused again is for the duration to have one definition
/// that every screen reads.
///
/// Pure and dependency-free on purpose: the recruiter list, the admin CV sheet
/// and the tests all need this, and none of them should need a Firestore
/// connection to ask how long somebody has flown.
library;

abstract final class ServiceYears {
  /// Total distinct time served across [experiences], in years.
  ///
  /// Overlapping postings are counted once — somebody who flew for two
  /// operators in the same two years has two years of service, not four.
  /// Returns null when nothing is dated well enough to measure, which is not
  /// the same as zero and must not be rendered as it.
  static num? from(List<Map<String, dynamic>> experiences) {
    final now = DateTime.now();
    final spans = <({DateTime start, DateTime end})>[];

    for (final e in experiences) {
      final start = month(e['startDate']);
      if (start == null) continue;
      final isCurrent = e['isCurrent'] == true;
      final end = isCurrent ? now : (month(e['endDate']) ?? now);
      if (end.isBefore(start)) continue;
      spans.add((start: start, end: end));
    }
    if (spans.isEmpty) return null;

    spans.sort((a, b) => a.start.compareTo(b.start));
    var total = Duration.zero;
    var blockStart = spans.first.start;
    var blockEnd = spans.first.end;

    for (final span in spans.skip(1)) {
      if (span.start.isAfter(blockEnd)) {
        total += blockEnd.difference(blockStart);
        blockStart = span.start;
        blockEnd = span.end;
      } else if (span.end.isAfter(blockEnd)) {
        blockEnd = span.end;
      }
    }
    total += blockEnd.difference(blockStart);

    final years = total.inDays / 365.25;
    // Under six months is a posting, not "years of experience"; rounding it up
    // to 1 would overstate the candidate.
    return years < 0.5 ? null : years;
  }

  /// How many of [experiences] carry a usable start date.
  ///
  /// Shown alongside the figure so a reader can tell whether "6.2 yrs" was
  /// measured from the whole history or from the two roles that happened to be
  /// dated.
  static int datedRoles(List<Map<String, dynamic>> experiences) =>
      experiences.where((e) => month(e['startDate']) != null).length;

  /// Parses the month formats this data actually contains.
  ///
  /// The onboarding form writes MM/YYYY, the CV extractor and the imported
  /// profiles write YYYY-MM, and a few carry a bare year. One field, several
  /// spellings — so the parser reads all of them and refuses anything else
  /// rather than guessing.
  static DateTime? month(dynamic raw) {
    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return null;

    final iso = RegExp(r'^(\d{4})-(\d{1,2})').firstMatch(text);
    if (iso != null) {
      final m = int.parse(iso.group(2)!);
      if (m < 1 || m > 12) return null;
      return DateTime(int.parse(iso.group(1)!), m);
    }

    final slash = RegExp(r'^(\d{1,2})[/-](\d{4})$').firstMatch(text);
    if (slash != null) {
      final m = int.parse(slash.group(1)!);
      if (m < 1 || m > 12) return null;
      return DateTime(int.parse(slash.group(2)!), m);
    }

    final year = RegExp(r'^(\d{4})$').firstMatch(text);
    if (year != null) return DateTime(int.parse(year.group(1)!));

    return null;
  }

  /// "6.2 yrs" — one decimal, because the input is month-precision and a
  /// second decimal would claim accuracy the data does not have.
  static String label(num years) => '${years.toStringAsFixed(1)} yrs';
}
