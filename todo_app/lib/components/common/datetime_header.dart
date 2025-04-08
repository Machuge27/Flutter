import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeHeader extends StatelessWidget {
  final Color? textColor;
  final double? fontSize;

  const DateTimeHeader({
    super.key,
    this.textColor,
    this.fontSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: fontSize! * 0.8,
                color: textColor ?? Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, MMMM d').format(now),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: fontSize! * 0.8,
                color: textColor ?? Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('h:mm a').format(now),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}