import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

enum FeedFilter { all, following, nearby, trending, friends }

class FeedProvider extends ChangeNotifier {
  FeedFilter _filter = FeedFilter.all;
  FeedFilter get filter => _filter;

  void setFilter(FeedFilter f) {
    if (_filter == f) return;
    _filter = f;
    notifyListeners();
  }

  Stream<List<PostModel>> get postsStream {
    switch (_filter) {
      case FeedFilter.following:
        return PostService.followingPosts();
      // Nearby / trending / friends require geo or extra queries –
      // fall back to allPosts until those are implemented.
      default:
        return PostService.allPosts();
    }
  }
}
