import 'package:flutter/foundation.dart';

import '../../../core/assessments/candidate_sitting.dart';
import '../../../services/backend_api.dart';

/// The candidate's own assessment record.
///
/// Read from the backend rather than Firestore: the sitting document carries
/// the pass mark and the verdict, and neither is the candidate's to see until
/// a recruiter has been told. `GET /assessment/mine` returns the score and
/// nothing that pre-empts a decision.
///
/// Search and filtering are held here but decided in [SittingLibrary], so the
/// rules can be tested without a screen or a network.
class MySittingsProvider extends ChangeNotifier {
  List<CandidateSitting> _all = const [];
  List<CandidateSitting> get all => _all;

  bool _loading = true;
  bool get loading => _loading;

  bool _loadedOnce = false;

  String _error = '';
  String get error => _error;

  SittingFilter _filter = SittingFilter.all;
  SittingFilter get filter => _filter;

  String _query = '';
  String get query => _query;

  /// What the list should show, after the search box and the filter row.
  List<SittingJobGroup> get groups => SittingLibrary.byJob(
        SittingLibrary.filter(SittingLibrary.search(_all, _query), _filter),
      );

  /// The number on the sidebar. Counts what is waiting on the candidate.
  int get toDoCount => SittingLibrary.toDoCount(_all);

  ({int taken, int? average, int? best}) get record =>
      SittingLibrary.record(_all);

  int get completedCount => _all.where((s) => s.isDone).length;

  /// True when the list is empty because of the filter, not because there is
  /// nothing at all — the two need different things said about them.
  bool get filteredToNothing => _all.isNotEmpty && groups.isEmpty;

  void setFilter(SittingFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  /// Loads once. The sidebar badge and the screen share this provider, so
  /// whichever renders first pays for the fetch and the other is instant.
  Future<void> load({bool force = false}) async {
    if (_loadedOnce && !force) return;
    _loadedOnce = true;
    _loading = true;
    _error = '';
    notifyListeners();
    try {
      final res = await BackendApi.get('/assessment/mine');
      _all = [
        for (final raw in (res['assessments'] as List? ?? const []))
          if (raw is Map)
            CandidateSitting.fromJson(Map<String, dynamic>.from(raw)),
      ];
    } on BackendException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load your assessments. Check your connection.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(force: true);
}
