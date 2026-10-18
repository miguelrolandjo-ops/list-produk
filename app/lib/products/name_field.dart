import 'package:flutter/material.dart';

/// Text field with suggestions from existing names. Typing a name that
/// is not in the list creates a new one on save.
class NameField extends StatelessWidget {
  const NameField({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.initialText = '',
    this.validator,
  });

  final String label;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String initialText;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialText),
      optionsBuilder: (value) => options.where(
        (o) => o.toLowerCase().contains(value.text.toLowerCase()),
      ),
      onSelected: onChanged,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: label,
            helperText: 'Pilih yang ada, atau ketik nama baru',
          ),
          onChanged: onChanged,
          validator: validator,
        );
      },
    );
  }
}
