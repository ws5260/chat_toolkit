import 'package:flutter/material.dart';

abstract class MessageElement {
  const MessageElement();

  Widget toWidget(BuildContext context);

  MessageElement copyWith();
}
