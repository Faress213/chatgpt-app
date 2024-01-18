import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:chatgptapp/constants.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _openAI = OpenAI.instance.build(
    token: OPENAI_API_KEY,
    baseOption: HttpSetup(
      receiveTimeout: const Duration(
        seconds: 5,
      ),
    ),
    enableLog: true,
  );

  final ChatUser _currentUser =
      ChatUser(id: '1', firstName: 'Fares', lastName: 'Karam');

  final ChatUser _gptChatUser =
      ChatUser(id: '2', firstName: 'Chat', lastName: 'GPT');

  final List<ChatMessage> _messages = <ChatMessage>[];
  final List<ChatUser> _typingUsers = <ChatUser>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(
          0,
          166,
          126,
          1,
        ),
        title: const Text(
          'GPT Chat',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: DashChat(
          messageListOptions: const MessageListOptions(),
          currentUser: _currentUser,
          typingUsers: _typingUsers,
          messageOptions: const MessageOptions(
            currentUserContainerColor: Colors.blue,
            containerColor: Color.fromRGBO(
              0,
              166,
              126,
              1,
            ),
            textColor: Colors.white,
          ),
          onSend: (ChatMessage m) {
          
                getChatResponse(m);
          },
          messages: _messages),
    );
  }

  Future<void> getChatResponse(ChatMessage m) async {
    setState(() async{
      if (_typingUsers.length ==0) {
        _messages.insert(0, m);
        _typingUsers.add(_gptChatUser);
        setState(() {
          
        });
          List<Messages> messagesHistory = _messages.reversed.map((m) {
      if (m.user == _currentUser) {
        return Messages(role: Role.user, content: m.text);
      } else {
        return Messages(role: Role.assistant, content: m.text);
      }
    }).toList();
    final request = ChatCompleteText(
      model: GptTurbo0301ChatModel(),
      messages: messagesHistory,
      maxToken: 500,
    );
    dynamic response;
    try {
      response = await _openAI.onChatCompletion(request: request);
    } catch (e) {
      bool result = await InternetConnection().hasInternetAccess;

      result
          ? {
              snackbar('Problem in Response Please Try Again '),
              messagesHistory.remove(messagesHistory)
            }
          : ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No Internet Connection'),
              duration: Duration(seconds: 1),
            ));
      Future.delayed(const Duration(seconds: 1), () {
        _typingUsers.length = 0;
        setState(() {});
      });
    }
    for (var element in response!.choices) {
      if (element.message != null) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
                user: _gptChatUser,
                createdAt: DateTime.now(),
                text: element.message!.content),
          );
        });
      }
    }

    setState(() {
      _typingUsers.remove(_gptChatUser);
    });
      } else {
        snackbar('Please wait for the response');
      }
    });
  
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> snackbar(
      String text) {
    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      duration: Duration(seconds: 1),
    ));
  }
}
