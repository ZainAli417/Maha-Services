import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:job_portal/main.dart';

// --------------------------------------------------
// CONSTANT COLORS
// --------------------------------------------------
class AppColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color white = Colors.white;
  static const Color paleWhite = Color(0xFFF5F5F5);

  // Opacity variations of primary
  static Color primaryLight = primary.withOpacity(0.2);
  static Color primaryMedium = primary.withOpacity(0.3);
  static Color primaryDark = primary.withOpacity(0.8);
}

// --------------------------------------------------
// MODEL CLASS FOR A CHAT MESSAGE
// --------------------------------------------------
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, {this.isUser = false});
}

// --------------------------------------------------
// SERVICE TO INTERACT WITH THE GEMINI API
// --------------------------------------------------
class GeminiService {
  // 🚨 WARNING: Do NOT hardcode your API key in production apps.
  static const String _model = 'gemini-2.5-flash-lite';
  static final String _endpoint =
     // 'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key==';
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key==${Env.geminiApiKey}';

  static Future<String> generateContent(String prompt) async {
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ],
      "systemInstruction": {
        "parts": [
          {
            "text":
            "You are an expert Military and Defense Sector Recruiter AI assistant for creating Job Descriptions (JDs)"
                "1.  **Output Format**: The final job description must start with a concise introductory paragraph, followed by bulleted lists for 'Key Responsibilities' and 'Qualifications'. Use Markdown for bolding section titles."
          }
        ]
      }
    });

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return decodedResponse['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return "Sorry, I couldn't connect to the server. Please check the API key and endpoint. Error: ${response.body}";
      }
    } catch (e) {
      return "An error occurred: $e";
    }
  }
}

// --------------------------------------------------
// GEMINI CHAT WIDGET
// --------------------------------------------------
class GeminiChatWidget extends StatefulWidget {
  const GeminiChatWidget({super.key});

  @override
  State<GeminiChatWidget> createState() => _GeminiChatWidgetState();
}

class _GeminiChatWidgetState extends State<GeminiChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Initial bot prompt
    _messages.add(
      ChatMessage(
        "Hello! I'm here to help you build a **job description**. To start, please tell me the **job role** you are hiring for.",
      ),
    );
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    final botResponse = await GeminiService.generateContent(text);

    setState(() {
      _messages.add(ChatMessage(botResponse));
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyToClipboard(String text) {
    String cleanText = text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1');

    Clipboard.setData(ClipboardData(text: cleanText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied to clipboard!',
          style: GoogleFonts.montserrat(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85, // adjust as needed
        height: MediaQuery.of(context).size.height * 0.9, // adjust as needed
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppColors.primary.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header (no rounding on header itself)
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primaryLight,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome_mosaic_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Job Description',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,              // slightly thinner
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Chat list
            Expanded(
              child: Container(
                color: Colors.white, // use offWhite here
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _buildMessageBubble(
                        ChatMessage("....", isUser: false),
                      );
                    }
                    final message = _messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
            ),

            // Input area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final alignment =
    message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start;
    final bubbleColor = message.isUser ? AppColors.primary : AppColors.white;
    final textColor = message.isUser ? AppColors.white : Colors.black87;

    final avatar = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        message.isUser ? Icons.person_outline_rounded : Icons.auto_awesome_rounded,
        color: AppColors.primary,
        size: 18,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) avatar,
          if (!message.isUser) const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment:
              message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: message.isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: message.isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: message.isUser
                            ? AppColors.primary.withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: message.text == "...."
                      ? const _TypingIndicator()
                      : _SelectableRichTextParser(
                    text: message.text,
                    style: GoogleFonts.montserrat(
                      color: textColor,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                if (!message.isUser && message.text != "....") ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CopyButton(
                        onPressed: () => _copyToClipboard(message.text),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 12),
          if (message.isUser) avatar,
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.primaryLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLight, width: 1),
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _sendMessage(),
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: GoogleFonts.montserrat(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _sendMessage,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// COPY BUTTON WIDGET
// --------------------------------------------------
class _CopyButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CopyButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryMedium, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Copy',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// TYPING INDICATOR
// --------------------------------------------------
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            double opacity = 0.4;
            double progress = (_controller.value * 3) % 3;

            if (progress >= index && progress < index + 1) {
              opacity = 0.4 + (0.6 * (progress - index));
            } else if (progress >= index + 1 && progress < index + 2) {
              opacity = 1.0 - (0.6 * (progress - index - 1));
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// --------------------------------------------------
// RICH TEXT PARSER FOR MARKDOWN STYLES
// --------------------------------------------------
class _SelectableRichTextParser extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _SelectableRichTextParser({required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final spans = _parseText(text);
    return SelectableText.rich(
      TextSpan(
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          height: 1.5,
        ).merge(style),
        children: spans,
      ),
      cursorColor: AppColors.primary,
      selectionControls: MaterialTextSelectionControls(),
    );
  }

  List<TextSpan> _parseText(String text) {
    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(r'(\*\*.*?\*\*|\*.*?\*)');

    text.splitMapJoin(
      regExp,
      onMatch: (Match match) {
        final part = match.group(0)!;
        if (part.startsWith('**') && part.endsWith('**')) {
          spans.add(TextSpan(
            text: part.substring(2, part.length - 2),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ));
        } else if (part.startsWith('*') && part.endsWith('*')) {
          spans.add(TextSpan(
            text: part.substring(1, part.length - 1),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ));
        }
        return '';
      },
      onNonMatch: (String segment) {
        spans.add(TextSpan(text: segment));
        return '';
      },
    );
    return spans;
  }
}
