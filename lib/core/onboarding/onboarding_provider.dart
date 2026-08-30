import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/haptics.dart';

import 'candidate_profile_service.dart';
import 'cv_extraction_service.dart';
import 'models/aviation_role.dart';
import 'models/candidate_profile.dart';
import 'models/question.dart';
import 'onboarding_upload_service.dart';
import 'profile_projector.dart';
import 'role_template_service.dart';

/// Where the candidate is in the onboarding journey.
enum OnboardingPhase {
  loading,
  roleSelection,
  entryMode,
  extracting,
  form,
  submitted,
}

/// How the candidate chose to populate the form.
enum EntryMode { cv, manual }

/// Kind of content a form section renders.
enum SectionKind { questions, experience, education, certifications, review }

/// One page of the dynamic form.
class FormSection {
  const FormSection({
    required this.title,
    required this.kind,
    this.questions = const [],
  });

  final String title;
  final SectionKind kind;
  final List<OnboardingQuestion> questions;
}

/// Transient state of the background draft save, surfaced as the floating
/// save indicator on desktop and a toast on mobile.
enum SaveState { idle, saving, saved, error }

/// Drives role-template selection, CV extraction, the dynamic form, draft
/// auto-save/resume, and final submission.
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({
    RoleTemplateService? questionnaires,
    CandidateProfileService? profiles,
    CvExtractionService? extractor,
    OnboardingUploadService? uploads,
  })  : _templates = questionnaires ?? RoleTemplateService(),
        _profiles = profiles ?? CandidateProfileService(),
        _extractor = extractor ?? CvExtractionService(),
        _uploads = uploads ?? OnboardingUploadService();

  final RoleTemplateService _templates;
  final CandidateProfileService _profiles;
  final CvExtractionService _extractor;
  final OnboardingUploadService _uploads;

  static const _autoSaveDelay = Duration(milliseconds: 1200);

  // ── State ─────────────────────────────────────────────────────────────────
  OnboardingPhase phase = OnboardingPhase.loading;
  String? error;
  bool submitting = false;
  SaveState saveState = SaveState.idle;

  List<RoleTemplate> templates = [];
  String? industry;
  RoleTemplate? template;
  EntryMode? entryMode;

  final Map<String, dynamic> answers = {};
  List<ExperienceEntry> experience = [];
  List<EducationEntry> education = [];
  List<CertificationEntry> certifications = [];

  List<FormSection> sections = const [];
  int sectionIndex = 0;

  /// Question ids the CV extractor filled — used to badge the field as
  /// "from your CV" so the candidate knows what to double-check.
  final Set<String> prefilledIds = {};

  /// True once the candidate edits a prefilled field, clearing its badge.
  RoleCvExtraction? extraction;
  String? cvFilename;
  bool extracting = false;

  /// Sections whose required fields have all been satisfied at least once.
  final Set<String> _visited = {};

  /// Set after a failed Next/Submit so the current section can show its
  /// inline errors; cleared as soon as the candidate moves on.
  bool showErrors = false;

  String? _uid;
  Timer? _saveTimer;
  bool _disposed = false;

  // ── Derived ───────────────────────────────────────────────────────────────

  List<String> get industries {
    final seen = <String>[];
    for (final t in templates) {
      if (!seen.contains(t.industry)) seen.add(t.industry);
    }
    return seen;
  }

  List<RoleTemplate> get templatesInIndustry =>
      templates.where((t) => t.industry == industry).toList();

  FormSection? get currentSection =>
      sections.isEmpty ? null : sections[sectionIndex.clamp(0, sections.length - 1)];

  bool get isFirstSection => sectionIndex == 0;
  bool get isLastSection =>
      sections.isEmpty || sectionIndex >= sections.length - 1;

  double get progress =>
      sections.isEmpty ? 0 : (sectionIndex + 1) / sections.length;

  /// Share of required questions across the whole template that are answered.
  double get completeness {
    final required = <OnboardingQuestion>[];
    for (final s in sections) {
      required.addAll(s.questions.where((q) => q.required && isVisible(q)));
    }
    if (required.isEmpty) return 1;
    final done = required.where((q) => q.isAnswered(answers[q.id])).length;
    return done / required.length;
  }

  bool sectionIsComplete(int index) {
    if (index < 0 || index >= sections.length) return false;
    return missingIn(sections[index]).isEmpty;
  }

  bool sectionWasVisited(int index) =>
      index >= 0 && index < sections.length && _visited.contains(sections[index].title);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Loads templates and any resumable draft for [uid].
  Future<void> init(String uid) async {
    _uid = uid;
    phase = OnboardingPhase.loading;
    error = null;
    _notify();
    try {
      templates = await _templates.loadRoles();
      industry = industries.isEmpty ? null : industries.first;

      final saved = await _profiles.load(uid);
      if (saved != null && saved.targetRole.roleId.isNotEmpty) {
        final match = _findTemplate(saved.targetRole.roleId);
        if (match != null) {
          _adoptTemplate(match, resume: saved);
          phase = OnboardingPhase.form;
          _notify();
          return;
        }
      }
      phase = OnboardingPhase.roleSelection;
    } catch (e) {
      error = 'Could not load onboarding: $e';
      phase = OnboardingPhase.roleSelection;
    }
    _notify();
  }

  RoleTemplate? _findTemplate(String id) {
    for (final t in templates) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ── Role selection ────────────────────────────────────────────────────────

  void selectIndustry(String value) {
    industry = value;
    _notify();
  }

  void selectTemplate(RoleTemplate t) {
    _adoptTemplate(t);
    phase = OnboardingPhase.entryMode;
    final uid = _uid;
    if (uid != null) {
      _profiles.markDraftStarted(
        uid,
        TargetRole(industry: t.industry, roleId: t.id, roleTitle: t.title),
      );
    }
    _notify();
  }

  /// Returns to the picker, discarding the in-memory form for the old role.
  void changeRole() {
    template = null;
    entryMode = null;
    extraction = null;
    cvFilename = null;
    answers.clear();
    prefilledIds.clear();
    _visited.clear();
    experience = [];
    education = [];
    certifications = [];
    sections = const [];
    sectionIndex = 0;
    phase = OnboardingPhase.roleSelection;
    _notify();
  }

  void _adoptTemplate(RoleTemplate t, {CandidateProfile? resume}) {
    template = t;
    industry = t.industry;
    sections = _buildSections(t);
    sectionIndex = 0;
    answers.clear();
    prefilledIds.clear();
    _visited.clear();
    experience = [];
    education = [];
    certifications = [];

    if (resume != null) {
      answers.addAll(ProfileProjector.hydrate(t, resume));
      experience = List.of(resume.experience);
      education = List.of(resume.education);
      certifications = List.of(resume.certifications);
      _visited.addAll(resume.completedSections);
      cvFilename = resume.cvSourceFile;
      entryMode = resume.cvSourceFile != null ? EntryMode.cv : EntryMode.manual;
    }
  }

  /// Question groups in template order, with the structured-history pages
  /// inserted before Documents and a Review page last.
  static List<FormSection> _buildSections(RoleTemplate t) {
    final groups = t.sections;
    const docs = 'Documents';
    final questionSections = [
      for (final g in groups)
        if (g != docs)
          FormSection(
            title: g,
            kind: SectionKind.questions,
            questions: t.questionsIn(g),
          ),
    ];
    return [
      ...questionSections,
      // No "Work Experience" page. Employment history is already asked for by
      // the role template — employer type, operator, aircraft, hours, recency —
      // so a second free-form job list made the candidate type the same career
      // twice. The [ExperienceEntry] model stays: the CV extractor still fills
      // it, and both the recruiter and admin views render whatever it holds.
      const FormSection(title: 'Education', kind: SectionKind.education),
      const FormSection(
          title: 'Certifications', kind: SectionKind.certifications),
      if (groups.contains(docs))
        FormSection(
          title: docs,
          kind: SectionKind.questions,
          questions: t.questionsIn(docs),
        ),
      const FormSection(title: 'Review & Submit', kind: SectionKind.review),
    ];
  }

  // ── Entry mode ────────────────────────────────────────────────────────────

  void chooseManual() {
    entryMode = EntryMode.manual;
    phase = OnboardingPhase.form;
    _notify();
    _scheduleSave();
  }

  /// Runs the CV through the extractor and pre-fills the form.
  Future<void> uploadCv(Uint8List bytes, String filename) async {
    final t = template;
    if (t == null) return;
    entryMode = EntryMode.cv;
    cvFilename = filename;
    extracting = true;
    error = null;
    phase = OnboardingPhase.extracting;
    _notify();

    final result = await _extractor.extract(
      bytes,
      filename: filename,
      template: t,
    );

    extraction = result;
    extracting = false;

    if (result.failed) {
      error =
          'We could not read that CV automatically. You can still fill the form in — nothing was lost.';
    } else {
      _applyExtraction(result);
    }

    phase = OnboardingPhase.form;
    _notify();
    _scheduleSave();
  }

  void _applyExtraction(RoleCvExtraction result) {
    result.answers.forEach((id, value) {
      answers[id] = value;
      prefilledIds.add(id);
    });

    final personal = result.personalInfo;
    if (personal != null) {
      _seed('personalInfo.fullName', personal.fullName);
      _seed('personalInfo.email', personal.email);
      _seed('personalInfo.phone', personal.phone);
      _seed('personalInfo.summary', personal.summary);
      _seed('personalInfo.location.city', personal.location.city);
      _seed('personalInfo.location.country', personal.location.country);
    }

    if (result.experience.isNotEmpty) experience = List.of(result.experience);
    if (result.education.isNotEmpty) education = List.of(result.education);
    if (result.certifications.isNotEmpty) {
      certifications = List.of(result.certifications);
    }
  }

  /// Fills the question that maps to [path] when the extractor found a value
  /// for it but did not key it by question id.
  void _seed(String path, String value) {
    if (value.trim().isEmpty) return;
    final t = template;
    if (t == null) return;
    for (final q in t.questions) {
      if (q.mapsTo != path) continue;
      if (answers.containsKey(q.id)) return;
      answers[q.id] = value.trim();
      prefilledIds.add(q.id);
      return;
    }
  }

  /// Skips extraction and continues with an empty form.
  void skipExtraction() {
    entryMode = EntryMode.manual;
    extraction = null;
    cvFilename = null;
    phase = OnboardingPhase.form;
    _notify();
  }

  // ── Answers ───────────────────────────────────────────────────────────────

  dynamic answer(String id) => answers[id];

  bool wasPrefilled(String id) => prefilledIds.contains(id);

  void setAnswer(String id, dynamic value) {
    final blank = value == null ||
        (value is String && value.trim().isEmpty) ||
        (value is List && value.isEmpty);
    if (blank) {
      answers.remove(id);
    } else {
      answers[id] = value;
    }
    prefilledIds.remove(id);
    _clearDependents(id);
    _notify();
    _scheduleSave();
  }

  /// Drops answers whose controlling question no longer permits them, so a
  /// candidate who switches from Military to Airline does not silently submit
  /// a stale squadron name.
  void _clearDependents(String changedId) {
    final t = template;
    if (t == null) return;
    for (final q in t.questions) {
      if (q.dependsOnId != changedId) continue;
      if (!isVisible(q)) answers.remove(q.id);
    }
  }

  bool isVisible(OnboardingQuestion q) {
    final depId = q.dependsOnId;
    if (depId == null) return true;
    final dep = answers[depId];
    if (dep == null) return false;

    final accepted = q.dependsOnValues.isNotEmpty
        ? q.dependsOnValues
        : (q.dependsOnValue == null ? const <String>[] : [q.dependsOnValue!]);
    if (accepted.isEmpty) return true;

    if (dep is List) {
      return dep.any((v) => accepted.contains(v.toString()));
    }
    return accepted.contains(dep.toString());
  }

  List<OnboardingQuestion> visibleQuestions(FormSection section) =>
      section.questions.where(isVisible).toList();

  /// Required, visible questions in [section] that are still unanswered.
  List<OnboardingQuestion> missingIn(FormSection section) => section.questions
      .where((q) => q.required && isVisible(q))
      .where((q) => !q.isAnswered(answers[q.id]))
      .toList();

  /// Every unanswered required question across the whole form.
  List<OnboardingQuestion> get allMissing => [
        for (final s in sections) ...missingIn(s),
      ];

  // ── Structured history ────────────────────────────────────────────────────

  String _newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

  void addExperience() {
    experience = [...experience, ExperienceEntry(id: _newId('exp'))];
    _notify();
    _scheduleSave();
  }

  void updateExperience(int index, ExperienceEntry entry) {
    if (index < 0 || index >= experience.length) return;
    final next = [...experience]..[index] = entry;
    experience = next;
    _notify();
    _scheduleSave();
  }

  void removeExperience(int index) {
    if (index < 0 || index >= experience.length) return;
    experience = [...experience]..removeAt(index);
    _notify();
    _scheduleSave();
  }

  void addEducation() {
    education = [...education, EducationEntry(id: _newId('edu'))];
    _notify();
    _scheduleSave();
  }

  void updateEducation(int index, EducationEntry entry) {
    if (index < 0 || index >= education.length) return;
    education = [...education]..[index] = entry;
    _notify();
    _scheduleSave();
  }

  void removeEducation(int index) {
    if (index < 0 || index >= education.length) return;
    education = [...education]..removeAt(index);
    _notify();
    _scheduleSave();
  }

  void addCertification() {
    certifications = [...certifications, CertificationEntry(id: _newId('cert'))];
    _notify();
    _scheduleSave();
  }

  void updateCertification(int index, CertificationEntry entry) {
    if (index < 0 || index >= certifications.length) return;
    certifications = [...certifications]..[index] = entry;
    _notify();
    _scheduleSave();
  }

  void removeCertification(int index) {
    if (index < 0 || index >= certifications.length) return;
    certifications = [...certifications]..removeAt(index);
    _notify();
    _scheduleSave();
  }

  // ── Document uploads ──────────────────────────────────────────────────────

  final Set<String> uploadingIds = {};

  Future<void> attachDocument({
    required String questionId,
    required String filename,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    uploadingIds.add(questionId);
    error = null;
    _notify();
    try {
      final doc = await _uploads.upload(
        uid: uid,
        questionId: questionId,
        filename: filename,
        bytes: bytes,
        contentType: contentType,
      );
      answers[questionId] = doc.toJson();
      prefilledIds.remove(questionId);
      Haptics.light();
    } on OnboardingUploadException catch (e) {
      Haptics.medium();
      error = e.message;
    } catch (e) {
      Haptics.medium();
      error = 'Upload failed: $e';
    } finally {
      uploadingIds.remove(questionId);
      _notify();
      _scheduleSave();
    }
  }

  Future<void> removeDocument(String questionId) async {
    final raw = answers[questionId];
    Haptics.selection();
    answers.remove(questionId);
    _notify();
    _scheduleSave();
    if (raw is Map) {
      try {
        await _uploads.remove(
            UploadedDocument.fromJson(Map<String, dynamic>.from(raw)));
      } catch (e) {
        debugPrint('⚠️ removeDocument: $e');
      }
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  /// Advances a page. Returns false (and reveals inline errors) when the
  /// current section still has unanswered required fields.
  Future<bool> next() async {
    final section = currentSection;
    if (section == null) return false;
    if (missingIn(section).isNotEmpty) {
      // Feedback lives here rather than in the action bar so every route to a
      // section change — the bar, the rail, a keyboard shortcut — feels the
      // same. A blocked advance gets the heavier tick precisely because it is
      // the one case where nothing visibly moves.
      Haptics.medium();
      showErrors = true;
      _notify();
      return false;
    }
    Haptics.light();
    _visited.add(section.title);
    showErrors = false;
    if (!isLastSection) sectionIndex++;
    _notify();
    await _save();
    return true;
  }

  Future<void> previous() async {
    if (isFirstSection) return;
    Haptics.light();
    showErrors = false;
    sectionIndex--;
    _notify();
    await _save();
  }

  /// Jumps to a section from the stepper. Only sections already reached (or
  /// the next one) are reachable, so validation cannot be skipped wholesale.
  Future<void> goToSection(int index) async {
    if (index < 0 || index >= sections.length) return;
    if (index > sectionIndex && missingIn(currentSection!).isNotEmpty) {
      Haptics.medium();
      showErrors = true;
      _notify();
      return;
    }
    if (index != sectionIndex) Haptics.light();
    showErrors = false;
    sectionIndex = index;
    _notify();
    await _save();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  CandidateProfile? _snapshot({required OnboardingStatus status}) {
    final uid = _uid;
    final t = template;
    if (uid == null || t == null) return null;
    final projected = ProfileProjector.project(t, answers);
    return CandidateProfile(
      uid: uid,
      targetRole:
          TargetRole(industry: t.industry, roleId: t.id, roleTitle: t.title),
      onboardingStatus: status,
      personalInfo: projected.personal,
      roleSpecificData: projected.roleData,
      experience: experience,
      education: education,
      certifications: certifications,
      answers: Map<String, dynamic>.from(answers),
      completedSections: _visited.toList(),
      cvSourceFile: cvFilename,
      extractionConfidence: extraction?.confidence,
      documents: ProfileProjector.documents(t, answers),
    );
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_autoSaveDelay, _save);
  }

  Future<void> _save() async {
    _saveTimer?.cancel();
    final draft = _snapshot(status: OnboardingStatus.draft);
    if (draft == null) return;
    saveState = SaveState.saving;
    _notify();
    try {
      await _profiles.saveDraft(draft);
      saveState = SaveState.saved;
    } catch (e) {
      debugPrint('⚠️ Onboarding auto-save failed: $e');
      saveState = SaveState.error;
    }
    _notify();
  }

  /// Explicit "save and finish later".
  Future<bool> saveNow() async {
    await _save();
    return saveState != SaveState.error;
  }

  /// Validates the whole form and writes the completed profile.
  Future<bool> submit() async {
    final t = template;
    final missing = allMissing;
    if (t == null) return false;
    if (missing.isNotEmpty) {
      showErrors = true;
      final section = sections.indexWhere((s) => missingIn(s).isNotEmpty);
      if (section >= 0) sectionIndex = section;
      error =
          '${missing.length} required ${missing.length == 1 ? 'field' : 'fields'} still need an answer.';
      _notify();
      return false;
    }

    final profile = _snapshot(status: OnboardingStatus.completed);
    if (profile == null) return false;

    submitting = true;
    error = null;
    _notify();
    try {
      _saveTimer?.cancel();
      await _profiles.submit(profile);
      submitting = false;
      phase = OnboardingPhase.submitted;
      _notify();
      return true;
    } catch (e) {
      error = 'Could not submit your profile: $e';
      submitting = false;
      _notify();
      return false;
    }
  }

  void clearError() {
    if (error == null) return;
    error = null;
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _saveTimer?.cancel();
    _extractor.dispose();
    super.dispose();
  }
}
