class WatchlistResponseModel {
  final String message;
  final WatchlistData data;

  WatchlistResponseModel({
    required this.message,
    required this.data,
  });

  factory WatchlistResponseModel.fromJson(Map<String, dynamic> json) {
    return WatchlistResponseModel(
      message: json['message'],
      data: WatchlistData.fromJson(json['data']),
    );
  }
}

class WatchlistData {
  final String id;
  final String user;
  final String movie;

  WatchlistData({
    required this.id,
    required this.user,
    required this.movie,
  });

  factory WatchlistData.fromJson(Map<String, dynamic> json) {
    return WatchlistData(
      id: json['_id'],
      user: json['user'],
      movie: json['movie'],
    );
  }
}
