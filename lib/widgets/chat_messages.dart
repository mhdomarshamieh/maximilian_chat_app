import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:maximilian_chat_app/widgets/message_bubble.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chat messages')
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshots) {
          if (snapshots.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshots.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'no messages found',
              ),
            );
          }

          if (snapshots.hasError) {
            return const Center(
              child: Text(
                'something went wrong',
              ),
            );
          }
          final messageList = snapshots.data!.docs;
          return ListView.builder(
            reverse: true,
            padding: const EdgeInsets.only(
              bottom: 40,
              left: 13,
              right: 13,
            ),
            itemBuilder: (context, index) {
              final chatMessage = messageList[index].data();
              final nextChatMessage = index + 1 < messageList.length
                  ? messageList[index + 1].data()
                  : null;
              final currentMessageUserId = chatMessage['userId'];
              final nextMessageUserId =
                  nextChatMessage != null ? nextChatMessage['userId'] : null;

              final nextUserIsSame = currentMessageUserId == nextMessageUserId;

              if (nextUserIsSame) {
                return MessageBubble.next(
                  isMe: currentMessageUserId == authenticatedUser.uid,
                  message: chatMessage['text'],
                );
              } else {
                return MessageBubble.first(
                  userImage: chatMessage['userImage'],
                  username: chatMessage['userName'],
                  message: chatMessage['text'],
                  isMe: currentMessageUserId == authenticatedUser.uid,
                );
              }
            },
            itemCount: messageList.length,
          );
        });
  }
}
