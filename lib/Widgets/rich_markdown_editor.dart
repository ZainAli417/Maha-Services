// rich_markdown_editor.dart
// A self-contained rich text editor that stores plain Markdown strings.
// No extra packages needed — uses markdown_widget (already in pubspec) to preview.
// Toolbar actions insert/wrap markdown syntax into the TextEditingController.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RichMarkdownEditor extends StatefulWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;
  final String? hintText;
  final int minLines;
  final bool isMobile;

  const RichMarkdownEditor({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.validator,
    this.hintText,
    this.minLines = 4,
    this.isMobile = false,
  });

  @override
  State<RichMarkdownEditor> createState() => _RichMarkdownEditorState();
}

class _RichMarkdownEditorState extends State<RichMarkdownEditor> {
  late TextEditingController _ctrl;
  late FocusNode _focusNode;
  bool _hasFocus = false;
  bool _showPreview = false;

  static const _primary = Color(0xFF1E3A5F);
  static const _border = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF0F4F8);

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void didUpdateWidget(RichMarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync if value changed externally (e.g. reset)
    if (oldWidget.initialValue != widget.initialValue &&
        _ctrl.text != widget.initialValue) {
      _ctrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Toolbar actions ───────────────────────────────────────────────────

  void _wrap(String before, String after, {String placeholder = 'text'}) {
    final sel = _ctrl.selection;
    final text = _ctrl.text;
    if (!sel.isValid) return;

    final selectedText =
        sel.isCollapsed ? placeholder : text.substring(sel.start, sel.end);
    final newText = text.replaceRange(sel.start, sel.end, '$before$selectedText$after');
    _ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: sel.start + before.length,
        extentOffset: sel.start + before.length + selectedText.length,
      ),
    );
    widget.onChanged(_ctrl.text);
  }

  void _insertLinePrefix(String prefix, {String placeholder = 'item'}) {
    final sel = _ctrl.selection;
    final text = _ctrl.text;
    if (!sel.isValid) return;

    // Find start of line
    int lineStart = sel.start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    final before = text.substring(0, lineStart);
    final afterCursor = text.substring(lineStart);

    // Check if prefix already present, toggle off; else insert
    if (afterCursor.startsWith(prefix)) {
      final removed = afterCursor.substring(prefix.length);
      _ctrl.value = TextEditingValue(
        text: before + removed,
        selection: TextSelection.collapsed(
            offset: (sel.start - prefix.length).clamp(lineStart, before.length + removed.length)),
      );
    } else {
      _ctrl.value = TextEditingValue(
        text: before + prefix + afterCursor,
        selection: TextSelection.collapsed(offset: sel.start + prefix.length),
      );
    }
    widget.onChanged(_ctrl.text);
  }

  void _insertBulletList() {
    final sel = _ctrl.selection;
    final text = _ctrl.text;
    if (!sel.isValid) return;

    // Add a new line with bullet prefix
    final insert = sel.start == 0 || text[sel.start - 1] == '\n'
        ? '- '
        : '\n- ';
    final newText = text.replaceRange(sel.start, sel.start, insert);
    _ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + insert.length),
    );
    widget.onChanged(_ctrl.text);
  }

  void _insertNumberedList() {
    final sel = _ctrl.selection;
    final text = _ctrl.text;
    if (!sel.isValid) return;

    // Count existing numbered list items for auto-numbering
    final before = text.substring(0, sel.start);
    final matches = RegExp(r'^\d+\. ', multiLine: true).allMatches(before);
    final num = matches.length + 1;

    final insert = sel.start == 0 || text[sel.start - 1] == '\n'
        ? '$num. '
        : '\n$num. ';
    final newText = text.replaceRange(sel.start, sel.start, insert);
    _ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + insert.length),
    );
    widget.onChanged(_ctrl.text);
  }

  void _insertHorizontalRule() {
    final sel = _ctrl.selection;
    final text = _ctrl.text;
    if (!sel.isValid) return;
    final insert = '\n---\n';
    final newText = text.replaceRange(sel.start, sel.end, insert);
    _ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + insert.length),
    );
    widget.onChanged(_ctrl.text);
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final radius = widget.isMobile ? 10.0 : 12.0;
    final labelSize = widget.isMobile ? 12.0 : 14.0;
    final fontSize = widget.isMobile ? 13.0 : 14.0;

    return FormField<String>(
      initialValue: widget.initialValue,
      validator: widget.validator,
      builder: (state) {
        final hasError = state.hasError;
        final borderColor = hasError
            ? Colors.redAccent
            : _hasFocus
                ? _primary
                : _border;
        final borderWidth = _hasFocus ? 2.0 : 1.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Label row + Preview toggle ──
            Row(
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: hasError ? Colors.redAccent : Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                // Preview toggle
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => setState(() => _showPreview = !_showPreview),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _showPreview ? _primary.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _showPreview ? _primary : _border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showPreview ? Icons.edit_outlined : Icons.preview_outlined,
                            size: 13,
                            color: _showPreview ? _primary : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showPreview ? 'Edit' : 'Preview',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _showPreview ? _primary : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ── Editor container ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: borderColor, width: borderWidth),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Toolbar ──
                  if (!_showPreview)
                    _buildToolbar(fontSize),

                  if (!_showPreview)
                    Divider(height: 1, color: _border),

                  // ── Content: Editor or Preview ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _showPreview
                        ? _buildPreview(fontSize, radius)
                        : _buildTextField(fontSize),
                  ),
                ],
              ),
            ),

            // ── Error text ──
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  state.errorText ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.redAccent,
                    fontSize: widget.isMobile ? 10 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // ── Markdown hint ──
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 2),
              child: Text(
                'Supports markdown: **bold**, *italic*, - bullets, 1. numbered',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Toolbar ───────────────────────────────────────────────────────────

  Widget _buildToolbar(double fontSize) {
    final tools = [
      _ToolItem(
        label: 'B',
        tooltip: 'Bold',
        isBold: true,
        onPressed: () => _wrap('**', '**', placeholder: 'bold text'),
      ),
      _ToolItem(
        label: 'I',
        tooltip: 'Italic',
        isItalic: true,
        onPressed: () => _wrap('*', '*', placeholder: 'italic text'),
      ),
      _ToolItem(
        label: 'U',
        tooltip: 'Underline (HTML)',
        isUnderline: true,
        onPressed: () => _wrap('<u>', '</u>', placeholder: 'underline'),
      ),
      _ToolItem(
        label: 'H',
        tooltip: 'Heading',
        onPressed: () => _insertLinePrefix('## ', placeholder: 'Heading'),
      ),
      _ToolItem(
        icon: Icons.format_list_bulleted,
        tooltip: 'Bullet List',
        onPressed: _insertBulletList,
      ),
      _ToolItem(
        icon: Icons.format_list_numbered,
        tooltip: 'Numbered List',
        onPressed: _insertNumberedList,
      ),
      _ToolItem(
        icon: Icons.format_quote_rounded,
        tooltip: 'Quote',
        onPressed: () => _insertLinePrefix('> ', placeholder: 'quote'),
      ),
      _ToolItem(
        icon: Icons.horizontal_rule_rounded,
        tooltip: 'Divider',
        onPressed: _insertHorizontalRule,
      ),
      _ToolItem(
        icon: Icons.spellcheck_rounded,
        tooltip: 'Spell Check (browser)',
        onPressed: () {
          // No-op — spell check is browser-native on web
          // Activate focus so browser spell check kicks in
          _focusNode.requestFocus();
        },
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 6 : 10,
        vertical: widget.isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(widget.isMobile ? 10 : 12),
          topRight: Radius.circular(widget.isMobile ? 10 : 12),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tools.map((t) => _buildToolButton(t)).toList(),
        ),
      ),
    );
  }

  Widget _buildToolButton(_ToolItem tool) {
    return Tooltip(
      message: tool.tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: tool.onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: widget.isMobile ? 30 : 34,
            height: widget.isMobile ? 28 : 32,
            alignment: Alignment.center,
            child: tool.icon != null
                ? Icon(
                    tool.icon,
                    size: widget.isMobile ? 16 : 18,
                    color: const Color(0xFF1E3A5F),
                  )
                : Text(
                    tool.label ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: widget.isMobile ? 12 : 14,
                      fontWeight: tool.isBold ? FontWeight.w800 : FontWeight.w600,
                      fontStyle: tool.isItalic ? FontStyle.italic : FontStyle.normal,
                      decoration: tool.isUnderline ? TextDecoration.underline : null,
                      color: const Color(0xFF1E3A5F),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(double fontSize) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 10 : 14,
        vertical: widget.isMobile ? 8 : 12,
      ),
      child: TextField(
        controller: _ctrl,
        focusNode: _focusNode,
        maxLines: null,
        minLines: widget.minLines,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        spellCheckConfiguration: const SpellCheckConfiguration(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: fontSize,
          color: const Color(0xFF2C3E50),
          height: 1.6,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: fontSize - 1,
            color: Colors.grey.shade400,
          ),
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) {
          widget.onChanged(v);
          // Keep FormField in sync
          (context as Element).markNeedsBuild();
        },
      ),
    );
  }

  Widget _buildPreview(double fontSize, double radius) {
    final text = _ctrl.text.trim();
    return Container(
      key: const ValueKey('preview'),
      constraints: BoxConstraints(minHeight: widget.minLines * 24.0),
      padding: EdgeInsets.all(widget.isMobile ? 10 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(radius),
        ),
      ),
      child: text.isEmpty
          ? Text(
              'Nothing to preview yet.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: fontSize,
                color: Colors.grey.shade400,
                fontStyle: FontStyle.italic,
              ),
            )
          : _MarkdownBody(text: text, fontSize: fontSize),
    );
  }
}

// ─── Markdown renderer (inline, no extra routing) ──────────────────────────
// Parses markdown manually for zero-dependency inline rendering.
class _MarkdownBody extends StatelessWidget {
  final String text;
  final double fontSize;

  const _MarkdownBody({required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];

      // Horizontal rule
      if (RegExp(r'^-{3,}$').hasMatch(line.trim())) {
        widgets.add(const Divider(height: 12, color: Color(0xFFE2E8F0)));
        i++;
        continue;
      }

      // Heading 1/2/3
      final h3 = RegExp(r'^### (.+)').firstMatch(line);
      final h2 = RegExp(r'^## (.+)').firstMatch(line);
      final h1 = RegExp(r'^# (.+)').firstMatch(line);
      if (h3 != null || h2 != null || h1 != null) {
        final match = h3 ?? h2 ?? h1!;
        final level = h1 != null ? 1 : h2 != null ? 2 : 3;
        final hSize = level == 1
            ? fontSize + 4
            : level == 2
                ? fontSize + 2
                : fontSize + 1;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            match.group(1)!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: hSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ));
        i++;
        continue;
      }

      // Blockquote
      if (line.startsWith('> ')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: const Border(left: BorderSide(color: Color(0xFF4A90A4), width: 3)),
            color: const Color(0xFFF0F6FA),
            borderRadius: BorderRadius.circular(4),
          ),
          child: _inlineText(line.substring(2), fontSize, italic: true),
        ));
        i++;
        continue;
      }

      // Bullet list
      if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: fontSize * 0.35),
                child: Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A90A4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(child: _inlineText(line.substring(2), fontSize)),
            ],
          ),
        ));
        i++;
        continue;
      }

      // Numbered list
      final numMatch = RegExp(r'^(\d+)\. (.+)').firstMatch(line);
      if (numMatch != null) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${numMatch.group(1)}.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A90A4),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(child: _inlineText(numMatch.group(2)!, fontSize)),
            ],
          ),
        ));
        i++;
        continue;
      }

      // Empty line
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        i++;
        continue;
      }

      // Regular paragraph
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: _inlineText(line, fontSize),
      ));
      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Parses inline markdown: **bold**, *italic*, <u>underline</u>, `code`
  Widget _inlineText(String text, double fontSize, {bool italic = false}) {
    final spans = _parseInlineSpans(text, fontSize, baseItalic: italic);
    return Text.rich(
      TextSpan(children: spans),
      style: GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        height: 1.65,
        color: const Color(0xFF334155),
      ),
    );
  }

  List<InlineSpan> _parseInlineSpans(String text, double fontSize,
      {bool baseItalic = false}) {
    final spans = <InlineSpan>[];
    // Pattern order matters
    final pattern = RegExp(
      r'\*\*(.+?)\*\*'        // bold: **...**
      r'|\*(.+?)\*'           // italic: *...*
      r'|<u>(.+?)</u>'        // underline: <u>...</u>
      r'|`(.+?)`',            // code: `...`
    );

    int last = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(
          text: text.substring(last, match.start),
          style: TextStyle(fontStyle: baseItalic ? FontStyle.italic : null),
        ));
      }

      if (match.group(1) != null) {
        // Bold
        spans.add(TextSpan(
          text: match.group(1),
          style: GoogleFonts.plusJakartaSans(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ));
      } else if (match.group(2) != null) {
        // Italic
        spans.add(TextSpan(
          text: match.group(2),
          style: GoogleFonts.plusJakartaSans(
            fontSize: fontSize,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF334155),
          ),
        ));
      } else if (match.group(3) != null) {
        // Underline
        spans.add(TextSpan(
          text: match.group(3),
          style: GoogleFonts.plusJakartaSans(
            fontSize: fontSize,
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xFF1E3A5F),
          ),
        ));
      } else if (match.group(4) != null) {
        // Code
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              match.group(4)!,
              style: GoogleFonts.sourceCodePro(
                fontSize: fontSize - 1,
                color: const Color(0xFF1E3A5F),
              ),
            ),
          ),
        ));
      }
      last = match.end;
    }

    if (last < text.length) {
      spans.add(TextSpan(
        text: text.substring(last),
        style: TextStyle(fontStyle: baseItalic ? FontStyle.italic : null),
      ));
    }

    return spans;
  }
}

// ─── ToolItem data class ────────────────────────────────────────────────────
class _ToolItem {
  final String? label;
  final IconData? icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;

  const _ToolItem({
    this.label,
    this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
  });
}


// ─── Read-only Markdown Viewer ──────────────────────────────────────────────
// Use this in detail dialogs to display markdown-formatted job text richly.
class MarkdownViewer extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool isMobile;

  const MarkdownViewer({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return _MarkdownBody(
      text: text,
      fontSize: isMobile ? fontSize - 0.5 : fontSize,
    );
  }
}
