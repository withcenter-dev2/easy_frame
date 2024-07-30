import 'dart:async';
import 'package:easy_helpers/easy_helpers.dart';
import 'package:easy_storage/easy_storage.dart';
import 'package:easychat/easychat.dart';
import 'package:easyuser/easyuser.dart';
import 'package:flutter/material.dart';

class ChatRoomInputBox extends StatefulWidget {
  const ChatRoomInputBox({
    super.key,
    this.room,
    this.afterAccept,
  });

  final ChatRoom? room;
  final Function(BuildContext context, ChatRoom updatedRoom)? afterAccept;

  @override
  State<ChatRoomInputBox> createState() => _ChatRoomInputBoxState();
}

class _ChatRoomInputBoxState extends State<ChatRoomInputBox> {
  final TextEditingController controller = TextEditingController();

  bool submitable = false;
  double? uploadProgress;

  ChatRoom? room;
  StreamSubscription? roomSubscription;

  prepareRoom() {
    room = widget.room;
    roomSubscription?.cancel();
    roomSubscription = room?.ref.snapshots().listen((snapshot) {
      room = ChatRoom.fromSnapshot(snapshot);
    });
  }

  @override
  void initState() {
    super.initState();
    prepareRoom();
  }

  @override
  void didUpdateWidget(covariant ChatRoomInputBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    prepareRoom();
  }

  @override
  void dispose() {
    controller.dispose();
    roomSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ImageUploadIconButton(
                onUpload: (url) async {
                  uploadProgress = 0;
                  setState(() {});
                  await sendMessage(photoUrl: url);
                },
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    if (submitable == value.isNotEmpty) return;
                    setState(() => submitable = value.isNotEmpty);
                  },
                  onSubmitted: (value) {
                    sendMessage(text: value);
                  },
                ),
              ),
              IconButton(
                onPressed: () =>
                    submitable ? sendMessage(text: controller.text) : null,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future sendMessage({String? photoUrl, String? text}) async {
    if (room == null) {
      throw 'chat-room/room-not-ready Either room is not ready or room is set as null.';
    }
    if ((text ?? "").isEmpty && (photoUrl == null || photoUrl.isEmpty)) return;
    await shouldAcceptInvitation();
    List<Future> futures = [
      ChatMessage.create(
        roomId: room!.id,
        text: text,
        url: photoUrl,
      ),
      room!.updateUnreadUsers(
        lastMessageText: text,
        lastMessageUrl: photoUrl,
      ),
    ];
    if (text != null) controller.clear();
    setState(() => submitable = false);
    await Future.wait(futures);
  }

  shouldAcceptInvitation() async {
    if (room == null) return;
    if (room!.userUids.contains(my.uid)) return;
    if (room!.invitedUsers.contains(my.uid) || room!.group) {
      // await room!.acceptInvitation();
      await room!.join();
      room!.invitedUsers.remove(my.uid);
      if (widget.afterAccept == null) return;
      final updatedRoom = await ChatRoom.get(room!.id);
      if (updatedRoom == null) return;
      if (!mounted) return;
      widget.afterAccept?.call(context, updatedRoom);
      return;
    }

    throw "chat-room/uninvited-chat You can only send a message to a chat room where you are a member or an invited user.";
  }
}
