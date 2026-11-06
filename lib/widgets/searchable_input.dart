import 'dart:math' as math;
import 'package:flutter/material.dart';

class SearchableInput extends StatefulWidget {
  final TextEditingController controller;
  final List<String> options;
  final String label, hint;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  const SearchableInput(
      {super.key,
      required this.controller,
      required this.options,
      required this.label,
      required this.hint,
      this.onChanged,
      this.validator});
  @override
  State<SearchableInput> createState() => _SearchableInputState();
}

class _SearchableInputState extends State<SearchableInput> {
  final _focus = FocusNode();
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawAutocomplete<String>(
        textEditingController: widget.controller,
        focusNode: _focus,
        optionsBuilder: (value) => value.text.trim().isEmpty
            ? const Iterable<String>.empty()
            : widget.options
                .where((o) =>
                    o.toLowerCase().contains(value.text.toLowerCase()) ||
                    o
                        .toLowerCase()
                        .replaceAll(RegExp(r'[^a-z0-9]'), '')
                        .contains(value.text
                            .toLowerCase()
                            .replaceAll(RegExp(r'[^a-z0-9]'), '')))
                .take(25),
        onSelected: widget.onChanged,
        fieldViewBuilder: (context, controller, focus, submit) => TextFormField(
            controller: controller,
            focusNode: focus,
            onChanged: widget.onChanged,
            validator: widget.validator,
            decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                suffixIcon: const Icon(Icons.search, size: 18))),
        optionsViewBuilder: (context, select, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                    width: math.min(380, MediaQuery.sizeOf(context).width - 64),
                    height: math.min(220, options.length * 56.0),
                    child: ListView(
                        padding: EdgeInsets.zero,
                        children: options
                            .map((o) => ListTile(
                                title: Text(o,
                                    style: const TextStyle(fontSize: 13)),
                                onTap: () => select(o)))
                            .toList())))),
      );
}
