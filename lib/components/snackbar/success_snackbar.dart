import 'package:flutter/material.dart';
import 'package:park_in_web/components/theme/color_scheme.dart';

void successSnackbar(BuildContext context, String message, double width) {
  final snackBar = SnackBar(
    elevation: 0,
    width: width,
    behavior: SnackBarBehavior.floating,
    backgroundColor: blackColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    content: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: successColor,
          size: 28,
        ),
        const SizedBox(
          width: 8,
        ),
        Flexible(
          child: Text(
            message,
            style: const TextStyle(
              color: whiteColor,
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
