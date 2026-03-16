import 'package:flutter/material.dart';
import 'package:roccoplay/modules/auth/signInPage.dart';
import 'package:roccoplay/modules/videoPlayer/video_player.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme/app_colors.dart';
import '../popUp/age_popup.dart';
import 'cast_crewPage.dart';
import '../premium/goPremium.dart';

class DramaDetailsPage extends StatefulWidget {
  final bool isSignedIn;

  const DramaDetailsPage({super.key, required this.isSignedIn});

  @override
  State<DramaDetailsPage> createState() => _DramaDetailsPageState();
}

class _DramaDetailsPageState extends State<DramaDetailsPage> {
  bool isWatchlist = false;
  bool isLiked = false;
  bool isDisliked = false;

  // Actor data
  final List<Map<String, String>> cast = [
    {'name': 'Shahid Kapoor', 'image': 'assets/images/Shahid_Kapoor.jpg'},
    {'name': 'Saru khan', 'image': 'assets/images/srk.jpeg'},
    {'name': 'Alia bhatta', 'image': 'assets/images/alia.jpeg'},
    {'name': 'Katarina', 'image': 'assets/images/katarina.jpeg'},
    {'name': 'Salman', 'image': 'assets/images/salman.jpeg'},
    {'name': 'Ranvir', 'image': 'assets/images/ranvir.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 Top Banner Image
            Stack(
              children: [
                Image.asset(
                  "assets/images/farzi.jpg",
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                /// 🔙 Back Button
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                /// 🎬 Watch Trailer Button (Right Bottom)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      final bool? isOver18 = await showDialog<bool>(
                        context: context,
                        builder: (context) => const AgeRestrictionPopup(),
                      );

                      if (isOver18 == true) {
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PremiumVideoPlayerPage(
                                videoUrl: 'assets/videos/asur1.mp4',
                                title: 'Farzi Series Part 1',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.play_arrow, color: AppColors.white),
                    label: const Text(
                      "Watch Trailer",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            /// 🎬 Series Name
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "The Farzi",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 6),

            /// 📅 Date • Language • Duration
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "2024 • Hindi • 2h 10m",
                style: TextStyle(color: AppColors.white, fontSize: 14),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔐 Sign In Button (Only if not signed in)
            if (!widget.isSignedIn)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignInPage()),
                    );
                  },
                  child: const Text(
                    "Sign In to Watch",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

            if (widget.isSignedIn)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    if (widget.isSignedIn) {
                      // User is logged in → Go Premium Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GoPremiumPage(),
                        ),
                      );
                    } else {
                      // User not logged in → Go Sign In
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignInPage(),
                        ),
                      );
                    }
                  },
                  child: Text(
                    widget.isSignedIn
                        ? "Subscribe to Watch"
                        : "Sign In to Watch",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            const SizedBox(height: 12),

            /// ⬇ Download Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  showSubscriptionDialog(context);
                },
                child: const Text(
                  "Download",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 📝 Description
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "This historical drama follows the story of a warrior "
                "who fights to reclaim his homeland. Full of action, emotion, "
                "and powerful storytelling.",
                style: TextStyle(color: Colors.white70),
              ),
            ),

            const SizedBox(height: 20),

            /// ⭐ Action Buttons Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _actionButton(
                    icon: isWatchlist ? Icons.bookmark : Icons.bookmark_border,
                    label: "Watchlist",
                    onTap: () {
                      setState(() {
                        isWatchlist = !isWatchlist;
                      });
                    },
                  ),

                  _actionButton(
                    icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    label: "Like",
                    onTap: () {
                      setState(() {
                        isLiked = !isLiked;
                        isDisliked = false;
                      });
                    },
                  ),

                  _actionButton(
                    icon: isDisliked
                        ? Icons.thumb_down
                        : Icons.thumb_down_outlined,
                    label: "Dislike",
                    onTap: () {
                      setState(() {
                        isDisliked = !isDisliked;
                        isLiked = false;
                      });
                    },
                  ),

                  _actionButton(
                    icon: Icons.share,
                    label: "Share",
                    onTap: () {
                      Share.share(
                        "Check out this amazing movie on RoccoPlay App 🎬🔥",
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            /// 🎭 Cast & Crew
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Cast & Crew",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: cast.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CastDetailsPage(
                            castName: cast[index]['name']!,
                            castImage: cast[index]['image']!,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: AssetImage(cast[index]['image']!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // const SizedBox(height: 25),

            /// ❤️ You May Also Like
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "You May Also Like",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 8,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        "assets/images/asur.webp",
                        width: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void showSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Subscription Required",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  "You need a subscription to download this video.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel"),
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonColor,
                        ),
                        onPressed: () {
                          Navigator.pop(context);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GoPremiumPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Explore Plan",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
