import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../homePages/mainHomepage.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text("Watchlist",
          style: TextStyle(
            color: AppColors.white
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              /// 🔵 Circle Plus Icon
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade700,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  size: 50,
                  color: AppColors.white,
                ),
              ),

              const SizedBox(height: 30),

              /// Title Text
              const Text(
                "No Watchlist Added Yet",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              /// Subtitle Text
              const Text(
                "Adding to Watchlist is a great way to make sure you always have something to watch.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              /// Start Adding Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context)=>MainHomePage()
                   ),
                   );
                  },
                  child: const Text(
                    "Start Adding",
                    style: TextStyle(
                      color:AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
