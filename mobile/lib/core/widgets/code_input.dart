/// A six-digit verification code field.
///
/// Rendered as separate boxes but driven by ONE hidden text field. Six real inputs would
/// mean six focus nodes, six paste behaviours and a fight with autofill; one field with a
/// painted representation behaves correctly with the keyboard, with paste, and with the
/// one-time-code suggestion iOS and Android offer above the keyboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'liquid_drop.dart';
import '../../l10n/l10n.dart';

class CodeInput extends StatefulWidget {
  const CodeInput({
    super.key,
    required this.onCompleted,
    this.length = 6,
    this.hasError = false,
    this.enabled = true,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final bool hasError;
  final bool enabled;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // The field is the subject of the screen, so it takes focus immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    if (value.length == widget.length) {
      widget.onCompleted(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final text = context.vocaText;
    final code = _controller.text;

    return Stack(
      children: [
        // Off-screen but focusable and pasteable.
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 1,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              // Lets the platform offer the code from the SMS or email above the keyboard.
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: widget.length,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _onChanged,
            ),
          ),
        ),
        GestureDetector(
          onTap: widget.enabled ? _focus.requestFocus : null,
          behavior: HitTestBehavior.opaque,
          child: Semantics(
            label: context.l10n.verificationCode,
            textField: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.length, (i) {
                final filled = i < code.length;
                final active = i == code.length && _focus.hasFocus;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VocaSpacing.xxs,
                    ),
                    child: SizedBox(
                      height: 56,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          GlassBead(
                            borderRadius: VocaRadius.mediumAll,
                            child: Center(
                              child: Text(
                                filled ? code[i] : '',
                                style: text.title.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          if (active || widget.hasError)
                            IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: VocaRadius.mediumAll,
                                  border: Border.all(
                                    color: widget.hasError
                                        ? colors.error
                                        : colors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
