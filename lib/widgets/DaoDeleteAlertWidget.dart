import 'package:flutter/material.dart';
import 'package:lighthouse_pm/Theming.dart';

/// A dialog for changing the nickname of a lighthouse
class DaoDeleteAlertWidget extends StatelessWidget {
  DaoDeleteAlertWidget({
    Key? key,
    required this.title,
    required this.subTitle,
  }) : super(key: key);
  final String title;
  final String subTitle;

  @override
  Widget build(BuildContext context) {
    final theming = Theming.of(context);
    return AlertDialog(
      title: RichText(
          text: TextSpan(style: theming.bodyText, children: [
        TextSpan(text: 'Do you want to delete: '),
        TextSpan(text: '$title', style: theming.bodyTextBold),
        TextSpan(text: '?'),
      ])),
      content: RichText(
          text: TextSpan(children: [
        TextSpan(text: 'This will delete:\n'),
        TextSpan(text: '$title\n$subTitle\n', style: theming.bodyTextBold),
        TextSpan(
            text: 'from the database.\n'
                'Since this is a test page it may break stuff if you do this!'),
      ])),
      actions: [
        SimpleDialogOption(
          child: Text('No'),
          onPressed: () => Navigator.pop(context, false),
        ),
        SimpleDialogOption(
          child: Text('Yes'),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }

  /// Open a dialog with the question if the user wants to delete a database entry.
  /// `true` if the use has selected the yes option, `false` otherwise.
  static Future<bool> showCustomDialog(BuildContext context,
      {required String title, required String subTitle}) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return DaoDeleteAlertWidget(title: title, subTitle: subTitle);
        }).then((value) {
      if (value is bool) {
        return value;
      }
      return false;
    });
  }
}
