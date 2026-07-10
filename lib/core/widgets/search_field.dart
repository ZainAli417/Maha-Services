import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A debounced search input with a clear button.
///
/// [onChanged] fires after [debounce] of inactivity so list filtering does not
/// run on every keystroke.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.onChanged,
    this.hint = 'Search…',
    this.controller,
    this.debounce = const Duration(milliseconds: 300),
  });

  final ValueChanged<String> onChanged;
  final String hint;
  final TextEditingController? controller;
  final Duration debounce;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => widget.onChanged(value));
    setState(() {}); // refresh clear-button visibility
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon:
            const Icon(Icons.search_rounded, color: AppColors.textFaint),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textFaint),
                onPressed: () {
                  _controller.clear();
                  _debounce?.cancel();
                  widget.onChanged('');
                  setState(() {});
                },
              ),
        isDense: true,
      ),
    );
  }
}
