import 'dart:async';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

import 'package:flutter/material.dart';
import 'package:mybot/messages.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Messages> _messages = [];
  ChatGPT? chatGPT;
  bool _isImageSearch = false;
  bool _istyping = false;

  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();

    chatGPT = ChatGPT.instance
        .builder("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");
  }

  @override
  void dispose() {
    chatGPT!.genImgClose();
    _subscription?.cancel();

    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    Messages message =
        Messages(text: _controller.text, sender: "user", isImage: false);

    setState(() {
      _messages.insert(0, message);
      _istyping = true;
    });

    _controller.clear();

    //calling chatGPT
    if (_isImageSearch) {
      final request = GenerateImage(message.text, 1, size: "256x256");

      _subscription = chatGPT!
          .generateImageStream(request)
          .asBroadcastStream()
          .listen((response) {
        insertNewData(response!.data!.last!.url!, isImage: true);
      });
    } else {
      final request = CompleteReq(
          prompt: message.text, model: kTranslateModelV3, max_tokens: 200);

      _subscription = chatGPT!
          .builder("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",
              orgId: "")
          .onCompleteStream(request: request)
          .listen((response) {
        insertNewData(response!.choices[0].text, isImage: false);
      });
    }
  }

  void insertNewData(String response, {bool isImage = false}) {
    Messages botMessage = Messages(
      text: response,
      sender: "DOST",
      isImage: isImage,
    );

    setState(() {
      _istyping = false;
      _messages.insert(0, botMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        "SATHI",
        style: TextStyle(fontWeight: FontWeight.w400),
      )),
      body: Column(
        children: [
          Flexible(
            child: ListView.builder(
              itemCount: _messages.length,
              reverse: true,
              itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(8.0), child: _messages[index]),
            ),
          ),
          const Divider(
            color: Colors.grey,
            thickness: 0.5,
          ),
          _istyping ? LinearProgressIndicator() : Container(),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (value) => _sendMessage(),
                    decoration: const InputDecoration.collapsed(
                        hintText: "How can I help you?"),
                  ),
                )),
                ButtonBar(children: [
                  IconButton(
                      onPressed: () {
                        _isImageSearch = false;
                        _sendMessage();
                      },
                      icon: Icon(
                        Icons.send,
                        color: Theme.of(context).primaryColor,
                      )),
                ]),
              ],
            ),
          )
        ],
      ),
    );
  }
}
