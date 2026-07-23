class ContentModel {
  final String id;
  final String title;
  final String description;
  final List<String> genre;
  final int releaseYear;
  final String? duration;
  final String language;
  final String poster;
  final String banner;
  final String? videoUrl;
  final String? trailerUrl;
  final bool isPremium;
  final double rating;
  final List<Cast>? cast;
  final List<String> category;
  final String slug;
  final String contentType;
  final bool isComingSoon;
  final bool isTrending;
  final String? releaseDate;
  final bool isPublished;
  final List<Season>? seasons;

  ContentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    required this.releaseYear,
    this.duration,
    required this.language,
    required this.poster,
    required this.banner,
    this.videoUrl,
    this.trailerUrl,
    required this.isPremium,
    required this.rating,
    this.cast,
    required this.category,
    required this.slug,
    required this.contentType,
    this.isComingSoon = false,
    this.isTrending = false,
    this.releaseDate,
    this.isPublished = true,
    this.seasons,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      genre: List<String>.from(json['genre'] ?? []),
      releaseYear: json['releaseYear'] ?? 0,
      duration: json['duration'],
      language: json['language'] ?? '',
      poster: json['poster'] ?? '',
      banner: json['banner'] ?? '',
      videoUrl: json['videoUrl'],
      trailerUrl: json['trailerUrl'],
      isPremium: json['isPremium'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      cast: json['cast'] != null
          ? List<Cast>.from(json['cast'].map((x) => Cast.fromJson(x)))
          : null,
      category: List<String>.from(json['category'] ?? []),
      slug: json['slug'] ?? '',
      contentType: json['type'] ?? '',
      isComingSoon: json['isComingSoon'] ?? false,
      isTrending: json['isTrending'] ?? false,
      releaseDate: json['releaseDate'],
      isPublished: json['isPublished'] ?? true,
      seasons: json['seasons'] != null
          ? List<Season>.from(json['seasons'].map((x) => Season.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'genre': genre,
      'releaseYear': releaseYear,
      'duration': duration,
      'language': language,
      'poster': poster,
      'banner': banner,
      'videoUrl': videoUrl,
      'trailerUrl': trailerUrl,
      'isPremium': isPremium,
      'rating': rating,
      'cast': cast?.map((e) => e.toJson()).toList(),
      'category': category,
      'slug': slug,
      'contentType': contentType,
      'isComingSoon': isComingSoon,
      'isTrending': isTrending,
      'releaseDate': releaseDate,
      'isPublished': isPublished,
      'seasons': seasons?.map((e) => e.toJson()).toList(),
    };
  }
}

class Season {
  final int seasonNumber;
  final List<Episode> episodes;

  Season({required this.seasonNumber, required this.episodes});

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      seasonNumber: json['seasonNumber'] ?? 0,
      episodes: json['episodes'] != null
          ? List<Episode>.from(json['episodes'].map((x) => Episode.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seasonNumber': seasonNumber,
      'episodes': episodes.map((e) => e.toJson()).toList(),
    };
  }
}

class Episode {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnail;
  final String? duration;
  final int episodeNumber;

  Episode({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnail,
    this.duration,
    required this.episodeNumber,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      duration: json['duration'],
      episodeNumber: json['episodeNumber'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnail': thumbnail,
      'duration': duration,
      'episodeNumber': episodeNumber,
    };
  }
}

class Cast {
  final String name;
  final String image;
  final String id;

  Cast({
    required this.name,
    required this.image,
    required this.id,
  });

  factory Cast.fromJson(Map<String, dynamic> json) {
    return Cast(
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      id: json['_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'image': image,
    };
  }
}
