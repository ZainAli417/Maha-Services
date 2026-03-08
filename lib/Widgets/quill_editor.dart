// lib/Widgets/quill_editor.dart
//
// Standardised rich-text widgets for the entire app, powered by flutter_quill.
//
// Exports:
//   • AppRichTextEditor  – editable Quill editor with full toolbar
//   • AppRichTextViewer  – read-only Quill renderer (backward-compat with plain text)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper: parse a Firestore string → Quill Document
// ─────────────────────────────────────────────────────────────────────────────
Document _parseDocument(String raw) {
  if (raw.trim().isEmpty) return Document();
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return Document.fromJson(decoded);
    }
  } catch (_) {}
  // Fallback: treat as plain text
  return Document()..insert(0, raw);
}

// ─────────────────────────────────────────────────────────────────────────────
// AppRichTextEditor
// ─────────────────────────────────────────────────────────────────────────────
class AppRichTextEditor extends StatefulWidget {
  final String label;

  /// Raw value from provider/Firestore – either Delta JSON string or plain text.
  final String initialDelta;

  /// Called with the updated Delta JSON string every time the document changes.
  final ValueChanged<String> onChanged;

  final String? Function(String?)? validator;
  final String? hintText;

  /// Minimum visible lines in the editor body.
  final int minLines;
  final bool isMobile;

  const AppRichTextEditor({
    super.key,
    required this.label,
    required this.initialDelta,
    required this.onChanged,
    this.validator,
    this.hintText,
    this.minLines = 5,
    this.isMobile = false,
  });

  @override
  State<AppRichTextEditor> createState() => _AppRichTextEditorState();
}

class _AppRichTextEditorState extends State<AppRichTextEditor> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  late final ScrollController _scrollController;
  bool _hasFocus = false;

  static const _primary = Color(0xFF1E3A5F);
  static const _border = Color(0xFFE2E8F0);
  static const _toolbarBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controller = QuillController(
      document: _parseDocument(widget.initialDelta),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _controller.addListener(_onDocumentChanged);
    _focusNode.addListener(() {
      if (mounted) setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  void _onDocumentChanged() {
    final delta = jsonEncode(_controller.document.toDelta().toJson());
    widget.onChanged(delta);
  }

  @override
  void dispose() {
    _controller.removeListener(_onDocumentChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.isMobile ? 10.0 : 12.0;
    final labelSize = widget.isMobile ? 12.0 : 13.0;
    final editorFontSize = widget.isMobile ? 13.0 : 14.0;
    final minH = widget.minLines * (editorFontSize * 1.7);

    return FormField<String>(
      initialValue: widget.initialDelta,
      validator: widget.validator != null
          ? (_) {
        // Extract plain text for validation
        final text = _controller.document.toPlainText().trim();
        return widget.validator!(text.isEmpty ? null : text);
      }
          : null,
      builder: (state) {
        final borderColor = state.hasError
            ? Colors.redAccent
            : _hasFocus
            ? _primary
            : _border;
        final borderWidth = _hasFocus ? 2.0 : 1.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Label ──
            Text(
              widget.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: labelSize,
                fontWeight: FontWeight.w600,
                color: state.hasError
                    ? Colors.redAccent
                    : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),

            // ── Editor card ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: borderColor, width: borderWidth),
                boxShadow: _hasFocus
                    ? [
                  BoxShadow(
                    color: _primary.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Quill Toolbar ──
                  Container(
                    decoration: BoxDecoration(
                      color: _toolbarBg,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(radius)),
                      border: const Border(
                          bottom:
                          BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                    ),
                    child: QuillSimpleToolbar(
                      controller: _controller,
                      config: QuillSimpleToolbarConfig(
                        showFontFamily: false,
                        showFontSize: widget.isMobile ? false : true,
                        showBoldButton: true,
                        showIndent:false,
                        showItalicButton: true,
                        showUnderLineButton: false,
                        showStrikeThrough: false,
                        showColorButton: false,
                        showBackgroundColorButton: false,
                        showClearFormat: true,
                        showAlignmentButtons: true,
                        showLeftAlignment: false,
                        showRightAlignment: false,
                        showCenterAlignment: false,
                        showJustifyAlignment: true,
                        showHeaderStyle: true,
                        showListNumbers: true,
                        showListBullets: true,
                        showListCheck: false,
                        showCodeBlock: false,
                        showQuote: false,
                        showLink: true,
                        showUndo: true,
                        showRedo: true,
                        showSmallButton: false,
                        showSearchButton: false,
                        showSubscript: false,
                        showSuperscript: false,
                        showInlineCode: false,
                        // removed showDivider as it's not present in current API
                        toolbarSize: widget.isMobile ? 25 : 30,
                        buttonOptions: QuillSimpleToolbarButtonOptions(
                          base: QuillToolbarBaseButtonOptions(
                            iconSize: widget.isMobile ? 14 : 16,
                            iconButtonFactor: 1,
                          ),
                        ),
                        toolbarSectionSpacing: 0,
                        toolbarIconAlignment: WrapAlignment.start,
                        // removed sharedConfigurations (no longer supported)
                      ),
                    ),
                  ),

                  // ── Editor body ──
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minH),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isMobile ? 10 : 14,
                        vertical: widget.isMobile ? 8 : 10,
                      ),
                      child: QuillEditor(
                        controller: _controller,
                        focusNode: _focusNode,
                        scrollController: _scrollController, // required now
                        config: QuillEditorConfig(
                          placeholder: widget.hintText,
                          padding: EdgeInsets.zero,
                          autoFocus: false,
                          expands: false,
                          scrollable: true,
                          customStyles: DefaultStyles(
                            paragraph: DefaultTextBlockStyle(
                              GoogleFonts.plusJakartaSans(
                                fontSize: editorFontSize,
                                color: const Color(0xFF2C3E50),
                                height: 1.65,
                              ),
                              HorizontalSpacing.zero,
                              VerticalSpacing.zero,
                              VerticalSpacing.zero,
                              null,
                            ),
                            placeHolder: DefaultTextBlockStyle(
                              GoogleFonts.plusJakartaSans(
                                fontSize: editorFontSize,
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic,
                              ),
                              HorizontalSpacing.zero,
                              VerticalSpacing.zero,
                              VerticalSpacing.zero,
                              null,
                            ),
                          ),
                          // sharedConfigurations removed
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Error text ──
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 4),
                child: Text(
                  state.errorText ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.redAccent,
                    fontSize: widget.isMobile ? 10 : 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppRichTextViewer  (read-only, backward-compatible)
// ─────────────────────────────────────────────────────────────────────────────
class AppRichTextViewer extends StatefulWidget {
  /// Accept either a Delta JSON string (new format) or plain text (legacy).
  final String deltaOrPlainText;
  final bool isMobile;
  final double? fontSize;

  const AppRichTextViewer({
    super.key,
    required this.deltaOrPlainText,
    this.isMobile = false,
    this.fontSize,
  });

  @override
  State<AppRichTextViewer> createState() => _AppRichTextViewerState();
}

class _AppRichTextViewerState extends State<AppRichTextViewer> {
  late QuillController _controller;
  late final ScrollController _scrollController;
  late final FocusNode _viewerFocusNode;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _viewerFocusNode = FocusNode(canRequestFocus: false);
    _controller = QuillController(
      document: _parseDocument(widget.deltaOrPlainText),
      selection: const TextSelection.collapsed(offset: 0),
      // readOnly is handled by how the editor is used (QuillEditor doesn't need a readOnly flag here)
    );
  }

  @override
  void didUpdateWidget(AppRichTextViewer old) {
    super.didUpdateWidget(old);
    if (old.deltaOrPlainText != widget.deltaOrPlainText) {
      _controller.dispose();
      _controller = QuillController(
        document: _parseDocument(widget.deltaOrPlainText),
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _viewerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.fontSize ?? (widget.isMobile ? 13.5 : 15.0);

    if (widget.deltaOrPlainText.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return QuillEditor(
      controller: _controller,
      focusNode: _viewerFocusNode,
      scrollController: _scrollController, // required
      config: QuillEditorConfig(
        autoFocus: false,
        expands: false,
        scrollable: false,
        padding: EdgeInsets.zero,
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
            GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              color: const Color(0xFF475569),
              height: 1.7,
            ),
            HorizontalSpacing.zero,
            VerticalSpacing(4, 4),
            VerticalSpacing.zero,
            null,
          ),
          bold: GoogleFonts.plusJakartaSans(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
          italic: GoogleFonts.plusJakartaSans(
            fontSize: fontSize,
            fontStyle: FontStyle.italic,
          ),
          lists: DefaultListBlockStyle(
            GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              color: const Color(0xFF475569),
              height: 1.65,
            ),
            HorizontalSpacing(widget.isMobile ? 12 : 16, 0),
            VerticalSpacing(2, 2),
            VerticalSpacing.zero,
            null,
            null,
          ),
          h1: DefaultTextBlockStyle(
            GoogleFonts.plusJakartaSans(
              fontSize: fontSize + 6,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
            HorizontalSpacing.zero,
            VerticalSpacing(8, 4),
            VerticalSpacing.zero,
            null,
          ),
          h2: DefaultTextBlockStyle(
            GoogleFonts.plusJakartaSans(
              fontSize: fontSize + 3,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
            HorizontalSpacing.zero,
            VerticalSpacing(6, 4),
            VerticalSpacing.zero,
            null,
          ),
          h3: DefaultTextBlockStyle(
            GoogleFonts.plusJakartaSans(
              fontSize: fontSize + 1,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
            HorizontalSpacing.zero,
            VerticalSpacing(4, 2),
            VerticalSpacing.zero,
            null,
          ),
          quote: DefaultTextBlockStyle(
            GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF64748B),
            ),
            HorizontalSpacing(widget.isMobile ? 12 : 16, 0),
            VerticalSpacing(6, 6),
            VerticalSpacing.zero,
            BoxDecoration(
              border: const Border(
                  left: BorderSide(color: Color(0xFF4A90A4), width: 3)),
              color: const Color(0xFFF0F6FA),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        // sharedConfigurations removed
      ),
    );
  }
}