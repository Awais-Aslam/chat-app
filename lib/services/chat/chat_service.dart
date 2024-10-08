import 'package:chat_app/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  // get the instance of fire store & auth
  final FirebaseFirestore fireStore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // get user stream
  /*
  List<Map<String, dynamic>>
  [
    {
      "email" : "test@gmail.com",
      "id" : "..."
    },
    {
      "email" : "test@gmail.com",
      "id" : "..."
    }
  ]
  */
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return fireStore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // go through each user
        final user = doc.data();

        // return user
        return user;
      }).toList();
    });
  }

// send message
  Future<void> sendMessage(String receiverId, String message) async {
    // get current user info
    final String currentUserID = auth.currentUser!.uid;
    final String currentUserEmail = auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // create a new message
    final Message newMessage = Message(
      message: message,
      receiverID: receiverId,
      senderEmail: currentUserEmail,
      senderID: currentUserID,
      timeStamp: timestamp,
    );

    // construct a chat room id for the two users (sorted to ensure uniqueness)
    List<String> ids = [currentUserID, receiverId];
    ids.sort(); // sort the ids (this ensure the Chat room id is same for any 2 people)
    String chatRoomID = ids.join('_');

    // get messages
    await fireStore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .add(newMessage.toMap());
  }

  // get messages
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    List<String> id = [userID, otherUserID];
    id.sort(); // sort the ids (this ensure the Chat room id is same for any 2 people)
    String chatRoomID = id.join('_');

    // get messages
    return  fireStore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .orderBy('timeStamp', descending: false)
        .snapshots();
  }
}
