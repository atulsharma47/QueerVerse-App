import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String bio;
  final String pronouns;
  final String orientation;
  final String gender;
  final String location;
  final String profileImage;
  final List<String> photos;
  final List<String> lookingFor;
  final List<String> interests;
  final String relationshipStatus;
  final String smokingStatus;
  final String drinkingStatus;
  final String prideStatus;
  final bool isPremium;
  final bool isEmailVerified;
  final bool isPhotoVerified;
  final bool isIdVerified;
  final bool isOnline;
  final Timestamp? lastSeen;
  final List<String> followers;
  final List<String> following;
  final bool isAdmin;
  final List<String> likedBy;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.bio,
    required this.pronouns,
    required this.orientation,
    required this.gender,
    required this.location,
    required this.profileImage,
    required this.photos,
    required this.lookingFor,
    required this.interests,
    required this.relationshipStatus,
    required this.smokingStatus,
    required this.drinkingStatus,
    required this.prideStatus,
    required this.isPremium,
    required this.isEmailVerified,
    required this.isPhotoVerified,
    required this.isIdVerified,
    required this.isOnline,
    this.lastSeen,
    required this.followers,
    required this.following,
    required this.isAdmin,
    this.likedBy = const [],
  });

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      name: d['name'] ?? 'New User',
      email: d['email'] ?? '',
      bio: d['bio'] ?? '',
      pronouns: d['pronouns'] ?? '',
      orientation: d['orientation'] ?? '',
      gender: d['gender'] ?? '',
      location: d['location'] ?? '',
      profileImage: d['profileImage'] ?? '',
      photos: List<String>.from(d['photos'] ?? []),
      lookingFor: List<String>.from(d['lookingFor'] ?? []),
      interests: List<String>.from(d['interests'] ?? []),
      relationshipStatus: d['relationshipStatus'] ?? '',
      smokingStatus: d['smokingStatus'] ?? '',
      drinkingStatus: d['drinkingStatus'] ?? '',
      prideStatus: d['prideStatus'] ?? '',
      isPremium: d['isPremium'] ?? false,
      isEmailVerified: d['isEmailVerified'] ?? false,
      isPhotoVerified: d['isPhotoVerified'] ?? false,
      isIdVerified: d['isIdVerified'] ?? false,
      isOnline: d['isOnline'] ?? false,
      lastSeen: d['lastSeen'] as Timestamp?,
      followers: List<String>.from(d['followers'] ?? []),
      following: List<String>.from(d['following'] ?? []),
      isAdmin: d['isAdmin'] ?? false,
      likedBy: List<String>.from(d['likedBy'] ?? []),
    );
  }

  /// True once photo or ID verification has gone through — used for the
  /// verified badge on the search card.
  bool get isVerified => isPhotoVerified || isIdVerified;

  /// Rough profile-completion score (0.0–1.0) for the strength bar.
  double get profileCompletion {
    const total = 9;
    int filled = 0;
    if (name.isNotEmpty) filled++;
    if (bio.isNotEmpty) filled++;
    if (pronouns.isNotEmpty) filled++;
    if (orientation.isNotEmpty) filled++;
    if (profileImage.isNotEmpty) filled++;
    if (photos.isNotEmpty) filled++;
    if (lookingFor.isNotEmpty) filled++;
    if (interests.isNotEmpty) filled++;
    if (relationshipStatus.isNotEmpty) filled++;
    return filled / total;
  }
}
