import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ChatInputField extends StatefulWidget {
  const ChatInputField({super.key});

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: const Color(0xFF000000).withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/smile_3x.png',
            scale: 3,
          ),
          const Gap(20),
          Expanded(
              child: TextFormField(
            controller: _textEditingController,
            decoration: InputDecoration(
              hintText: 'Reply...',
              hintStyle: TextStyle(
                color: const Color(0xFF0D082C).withOpacity(0.6),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          )),
          GestureDetector(
            onTap: () {
              if (_textEditingController.text.isNotEmpty) {
                _textEditingController.clear();
              }
            },
            child: Image.asset('assets/images/send_3x.png', scale: 3),
          )
        ],
      ),
    );
  }
}
