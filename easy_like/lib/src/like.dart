import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_like/easy_like.dart';
import 'package:easy_like/src/like.exception.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Support like only. Not dislike.
/// See README.md for more information.
class Like {
  static CollectionReference get col =>
      FirebaseFirestore.instance.collection('likes');

  /// original document reference. It is called 'target document reference'.
  final DocumentReference documentReference;

  /// Like document reference. The document ID is the same as the target document ID.
  DocumentReference get likeRef => col.doc(documentReference.id);
  DocumentReference get ref => likeRef;

  String? id;
  List<String> likedBy = [];

  Like({
    required this.documentReference,
    this.likedBy = const [],
    this.id,
  });

  factory Like.fromSnapshot(DocumentSnapshot snapshot) {
    return Like.fromJson(
      snapshot.data() as Map<String, dynamic>,
      snapshot.id,
    );
  }

  factory Like.fromJson(Map<String, dynamic> json, String id) {
    return Like(
      documentReference: json['documentReference'],
      likedBy: List<String>.from(json['likedBy'] ?? []),
    );
  }

  /// Like (or dislike)
  ///
  /// [uid] is the user's uid who likes (or unlikes) the document.
  ///
  /// When the user likes the document,
  ///
  /// - Add the user's uid to the likedBy list
  /// - Increase the likes count
  /// - Increaes the likes count in the document
  Future<void> like() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw LikeException('like/sign-in-required', 'User is not signed in');
    }

    final uid = currentUser.uid;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      FieldValue $likedBy;

      List<String> likedBy = [];
      final snapshot = await likeRef.get();
      if (snapshot.exists) {
        final Map<String, dynamic> data =
            snapshot.data() as Map<String, dynamic>;
        likedBy = List<String>.from(data['likedBy'] ?? []);
      }

      int $likeCount = likedBy.length;

      /// check if likedBy contains the uid, if not then it will liked.
      /// otherwise dislike
      bool isLiked = likedBy.contains(uid) == false;

      /// If isLiked then add it, else unlike it;
      if (isLiked) {
        $likedBy = FieldValue.arrayUnion([uid]);
        $likeCount++;
      } else {
        $likedBy = FieldValue.arrayRemove([uid]);
        $likeCount--;
      }

      ///
      transaction.set(
          documentReference,
          {
            'likeCount': $likeCount,
          },
          SetOptions(
            merge: true,
          ));
      final data = {
        'documentReference': documentReference,
        'likeCount': $likeCount,
        'likedBy': $likedBy,
      };
      transaction.set(
        likeRef,
        data,
        SetOptions(
          merge: true,
        ),
      );
      LikeService.instance.onLike?.call(
        like: Like.fromJson(data, likeRef.id),
        isLiked: isLiked,
      );
    });
  }
}
