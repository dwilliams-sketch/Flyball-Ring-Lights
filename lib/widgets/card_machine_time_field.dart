import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CardMachineDecimalFormatter extends TextInputFormatter {
  final int decimalPlaces;
  final int maxDigits;

  const CardMachineDecimalFormatter({
    this.decimalPlaces = 2,
    this.maxDigits = 6,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    if (digits.length > maxDigits) {
      digits = digits.substring(digits.length - maxDigits);
    }

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final padded = digits.padLeft(decimalPlaces + 1, '0');
    final whole = padded.substring(0, padded.length - decimalPlaces);
    final decimals = padded.substring(padded.length - decimalPlaces);
    final formatted = '$whole.$decimals';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CardMachineTimeField extends StatefulWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool allowNegative;
  final int decimalPlaces;
  final String suffixText;

  const CardMachineTimeField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.allowNegative = false,
    this.decimalPlaces = 2,
    this.suffixText = 's',
  });

  @override
  State<CardMachineTimeField> createState() => _CardMachineTimeFieldState();
}

class _CardMachineTimeFieldState extends State<CardMachineTimeField> {
  late final TextEditingController controller;
  bool negative = false;
  bool changingInternally = false;

  @override
  void initState() {
    super.initState();
    negative = widget.initialValue.trim().startsWith('-');
    controller = TextEditingController(
      text: _normaliseInitial(widget.initialValue),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String _normaliseInitial(String raw) {
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null) return '';
    return value.abs().toStringAsFixed(widget.decimalPlaces);
  }

  void _emit() {
    final text = controller.text.trim();
    if (text.isEmpty) {
      widget.onChanged('');
      return;
    }
    widget.onChanged('${negative ? '-' : ''}$text');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.allowNegative) ...[
          SizedBox(
            width: 54,
            height: 56,
            child: OutlinedButton(
              onPressed: () {
                setState(() => negative = !negative);
                _emit();
              },
              child: Text(
                negative ? '−' : '+',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              CardMachineDecimalFormatter(decimalPlaces: widget.decimalPlaces),
            ],
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.decimalPlaces == 2 ? '425 → 4.25' : '4123 → 4.123',
              suffixText: widget.suffixText,
              helperText: 'Just type the digits — the decimal moves automatically',
            ),
            onChanged: (_) {
              if (!changingInternally) _emit();
            },
          ),
        ),
      ],
    );
  }
}
