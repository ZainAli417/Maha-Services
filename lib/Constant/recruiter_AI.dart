import 'dart:async';
import 'dart:convert';
// Used for the typing indicator
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:job_portal/main.dart';
import '../services/backend_api.dart';

// --------------------------------------------------
// 1. DESIGN SYSTEM
// --------------------------------------------------
class AppTheme {
  static const Color primary = Color(0xFF14507F);
  static const Color primaryDark = Color(0xFF0A2E4F);
  static const Color primaryLight = Color(0xFFE0EFF7);
  static const Color accent = Color(0xFF2EC4B6);
  static const Color background = Color(0xFFF4F9FB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0B2239);
  static const Color textSecondary = Color(0xFF5E7A8E);
  static const Color textTertiary = Color(0xFF8AA5B5);
  static const Color border = Color(0xFFDCE7EF);
  static const Color success = Color(0xFF10B981);
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  bool isAnimated; // Track if we've already done the "streaming" animation
  int displayedLength; // Track how many characters are currently displayed

  ChatMessage(
    this.text, {
    this.isUser = false,
    this.isAnimated = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now(),
       displayedLength = isAnimated ? text.length : 0;
}

// --------------------------------------------------
// 2. UPDATED MAIN WIDGET
// --------------------------------------------------
class AIJDBuilderWidget extends StatefulWidget {
  final VoidCallback onClose; // Callback to minimize the widget

  const AIJDBuilderWidget({super.key, required this.onClose});

  @override
  State<AIJDBuilderWidget> createState() => _AIJDBuilderWidgetState();
}

// NOTE: To maintain history on close/open, these are moved outside the State class
// In a production app, use a Provider or Bloc to manage this state.
final List<ChatMessage> _persistentMessages = [
  ChatMessage(
    "👋 **Hello! I'm your AI Job Architect.**\n\nI can help you draft precise military and defense job descriptions.\n\nTo begin, simply tell me:\n• The **Job Title**\n• Key **Responsibilities**\n• Required **Clearance Level**",
    isAnimated: true, // Don't animate the first greeting
  ),
];
final List<Map<String, String>> _persistentHistory = [];

class _AIJDBuilderWidgetState extends State<AIJDBuilderWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.trim().isNotEmpty);
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _persistentMessages.add(
        ChatMessage(text, isUser: true, isAnimated: true),
      );
      _isTyping = true;
      _controller.clear();
    });

    _scrollToBottom();
    _persistentHistory.add({'role': 'user', 'content': text});

    // Mock/API Call
    final botResponse = await _generateContent(text, _persistentHistory);

    if (mounted) {
      setState(() {
        _persistentHistory.add({'role': 'assistant', 'content': botResponse});
        _persistentMessages.add(
          ChatMessage(botResponse, isUser: false, isAnimated: false),
        );
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  // Placeholder for your backend service logic
  Future<String> _generateContent(
    String prompt,
    List<Map<String, String>> history,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Env.backendUrl}/ai-jdbuild'),
            headers: await BackendApi.headers(),
            body: jsonEncode({
              'prompt': prompt,
              'conversationHistory': history,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? data['response'];
      }
      return "⚠️ Connection error (${response.statusCode}).";
    } catch (e) {
      return "⚠️ Error: $e";
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _persistentMessages.clear();
      _persistentHistory.clear();
      _persistentMessages.add(
        ChatMessage("👋 **Ready for a fresh start.**", isAnimated: true),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 600,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMessagesList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accent, AppTheme.primary],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JD Architect',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'AI job description builder',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearChat,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: AppTheme.textSecondary,
          ),
          IconButton(
            onPressed: widget.onClose, // Now just calls the minimize callback
            icon: const Icon(Icons.close_rounded, size: 22),
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _persistentMessages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _persistentMessages.length) {
          return const _TypingIndicator();
        }
        return _MessageBubble(message: _persistentMessages[index]);
      },
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Describe the role...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textTertiary,
                ),
                filled: true,
                fillColor: AppTheme.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _hasText ? _sendMessage : null,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: _hasText
                    ? const LinearGradient(
                        colors: [AppTheme.accent, AppTheme.primary],
                      )
                    : null,
                color: _hasText ? null : AppTheme.border,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _hasText
                    ? [
                        BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// 3. THE STREAMING EFFECT & CLEAN MARKDOWN
// --------------------------------------------------
class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  String _displayedText = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.message.isUser || widget.message.isAnimated) {
      _displayedText = widget.message.text;
    } else {
      // Start from where we left off
      _displayedText = widget.message.text.substring(
        0,
        widget.message.displayedLength,
      );
      _startStreaming();
    }
  }

  void _startStreaming() {
    // Only start if not already completed
    if (widget.message.isAnimated) {
      _displayedText = widget.message.text;
      return;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (widget.message.displayedLength < widget.message.text.length) {
        if (mounted) {
          setState(() {
            widget.message.displayedLength++;
            _displayedText = widget.message.text.substring(
              0,
              widget.message.displayedLength,
            );
          });
        }
      } else {
        widget.message.isAnimated = true;
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isUser = widget.message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accent, AppTheme.primary],
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [AppTheme.accent, AppTheme.primary],
                          )
                        : null,
                    color: isUser ? null : AppTheme.background,
                    border: isUser
                        ? null
                        : Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomRight: isUser ? const Radius.circular(0) : null,
                      bottomLeft: !isUser ? const Radius.circular(0) : null,
                    ),
                  ),
                  child: _RichTextRenderer(
                    text: _displayedText,
                    isUser: isUser,
                  ),
                ),
                if (!isUser && widget.message.isAnimated)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CopyButton(text: widget.message.text),
                  ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

// --------------------------------------------------
// 4. COPY BUTTON WIDGET
// --------------------------------------------------
class _CopyButton extends StatefulWidget {
  final String text;
  const _CopyButton({required this.text});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _copyToClipboard,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check : Icons.content_copy,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              _copied ? 'Copied!' : 'Copy',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// 5. IMPROVED MARKDOWN RENDERER (REMOVES ALL SYMBOLS)
// --------------------------------------------------
class _RichTextRenderer extends StatelessWidget {
  final String text;
  final bool isUser;

  const _RichTextRenderer({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          height: 1.5,
          color: isUser ? Colors.white : AppTheme.textPrimary,
        ),
        children: _parseMarkdown(text),
      ),
    );
  }

  List<InlineSpan> _parseMarkdown(String content) {
    List<InlineSpan> spans = [];

    // Clean content: Remove ALL markdown symbols
    String cleanContent = content;

    // Remove header symbols (##, ###, ####, etc.) at start of lines
    cleanContent = cleanContent.replaceAllMapped(
      RegExp(r'^#{1,6}\s+', multiLine: true),
      (match) => '', // Just remove the hash symbols
    );

    // Split by lines to handle line breaks properly
    final lines = cleanContent.split('\n');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      // Parse bold text (**text**)
      final RegExp boldExp = RegExp(r'\*\*(.+?)\*\*');
      int lastIndex = 0;

      for (final match in boldExp.allMatches(line)) {
        // Add normal text before bold
        if (match.start > lastIndex) {
          spans.add(TextSpan(text: line.substring(lastIndex, match.start)));
        }

        // Add bold text WITHOUT the ** symbols
        spans.add(
          TextSpan(
            text: match.group(1), // Only the text inside **, not the ** itself
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );

        lastIndex = match.end;
      }

      // Add remaining text after last bold
      if (lastIndex < line.length) {
        spans.add(TextSpan(text: line.substring(lastIndex)));
      }

      // Add newline if not the last line
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accent, AppTheme.primary],
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 60,
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
