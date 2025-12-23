import 'package:flutter/material.dart';

/// ElderlyDropdown is an accessible dropdown widget designed for elderly users
class ElderlyDropdown<T> extends StatefulWidget {
  final String label;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? Function(T?)? validator;

  const ElderlyDropdown({
    Key? key,
    required this.label,
    required this.items,
    this.value,
    this.onChanged,
    this.hint,
    this.validator,
  }) : super(key: key);

  @override
  State<ElderlyDropdown<T>> createState() => _ElderlyDropdownState<T>();
}

class _ElderlyDropdownState<T> extends State<ElderlyDropdown<T>> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _isFocused ? Colors.blue : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        FormField<T>(
          validator: widget.validator,
          builder: (FormFieldState<T> state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<T>(
                  value: widget.value,
                  focusNode: _focusNode,
                  items: widget.items,
                  onChanged: (T? newValue) {
                    state.didChange(newValue);
                    widget.onChanged?.call(newValue);
                  },
                  hint: widget.hint != null ? Text(widget.hint!) : null,
                  isExpanded: true,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.errorText ?? '',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
