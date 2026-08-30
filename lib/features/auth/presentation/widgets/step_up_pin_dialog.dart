import 'package:flutter/material.dart';

import 'pin_keypad.dart';

Future<bool> confirmStepUpPin(BuildContext context) async {
  var pin = '';
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Confirm with PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('•' * pin.length, key: const Key('step_up_dots')),
                PinKeypad(
                  onDigit: (d) {
                    if (pin.length >= 4) {
                      return;
                    }
                    setState(() => pin += d);
                    if (pin.length == 4) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  onBackspace: () {
                    if (pin.isEmpty) {
                      return;
                    }
                    setState(() => pin = pin.substring(0, pin.length - 1));
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
  return result ?? false;
}
