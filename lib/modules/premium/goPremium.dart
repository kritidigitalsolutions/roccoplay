import 'package:flutter/material.dart';
import 'package:roccoplay/modules/auth/signInPage.dart';
import 'package:roccoplay/modules/premium/paymentPage.dart';
import '../../app/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/expendable_plan_card.dart';
import '../popUp/promo_code_popup.dart';
import '../popUp/redeem_voucher_page.dart';
import '../homePages/mainHomepage.dart';


class GoPremiumPage extends StatefulWidget {
  @override
  _GoPremiumPageState createState() => _GoPremiumPageState();
}

class _GoPremiumPageState extends State<GoPremiumPage> {
  int selectedPlanIndex = 0;
  bool isUserLoggedIn = false;
  // String selectedLanguage = "English";
  String selectedPrice = "₹999";


  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isUserLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [

            /// 🔹 Top Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  /// Back Icon
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: AppColors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MainHomePage()),
                      );
                    },
                  ),

                  /// Language Section
                  // Row(
                  //   children: [
                  //     Text("Your Language: ",
                  //         style: TextStyle(color: AppColors.white)),
                  //     Text(
                  //       selectedLanguage,
                  //       style: TextStyle(
                  //           color: AppColors.white,
                  //           fontWeight: FontWeight.bold),
                  //     ),
                  //     SizedBox(width: 5),
                  //     GestureDetector(
                  //       onTap: _showLanguagePopup,
                  //       child: Icon(Icons.language,
                  //           color: AppColors.white),
                  //     ),
                  //   ],
                  // )
                ],
              ),
            ),

            SizedBox(height: 20),

            /// 🔹 Upgrade Text
            Text(
              "Upgrade Your Plan for More Benefits",
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20),

            ///  Custom Plan Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(child: _buildPlanButton("Yearly", 0)),
                  Expanded(child: _buildPlanButton("Monthly", 1)),
                  Expanded(child: _buildPlanButton("Others", 2)),
                ],
              ),
            ),

            /// 🔹 Plans According To Selection
            Expanded(
              child: buildPlanList(
                selectedPlanIndex == 0
                    ? "Yearly"
                    : selectedPlanIndex == 1
                    ? "Monthly"
                    : "Others",
              ),
            ),

            /// 🔴 Sign In / Purchase Button
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                  ),
                  onPressed: () {
                    if (isUserLoggedIn) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => PaymentBottomSheet(),
                        );

                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SignInPage()),
                      );
                    }
                  },
                  child: Text(
                    isUserLoggedIn
                        ? "Continue with $selectedPrice"
                        : "Sign In",
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                ),
              ),
            ),

            /// 🔹 Bottom 50%-50%
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (isUserLoggedIn) {
                        _showApplyPromoPopup();
                      } else {
                        _showSignInPopup();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.borderColor),
                          right:
                          BorderSide(color: AppColors.borderColor),
                        ),
                      ),
                      child: Text("Apply Promo Code",
                          style:
                          TextStyle(color: AppColors.white)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (isUserLoggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RedeemVoucherPage(),
                          ),
                        );
                      } else {
                        _showSignInPopup();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.borderColor),
                        ),
                      ),
                      child: Text("Apply Prepaid Pin",
                          style:
                          TextStyle(color: AppColors.white)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// 🔴 Plan Button UI
  Widget _buildPlanButton(String text, int index) {
    bool isSelected = selectedPlanIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlanIndex = index;
        });
      },
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.buttonColor
              : Colors.grey[850],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 🔹 Plan List
  Widget buildPlanList(String type) {
    return ListView(
      padding: EdgeInsets.all(15),
      children: [
        ExpandablePlanCard(
          title: "Gold $type",
          price: "₹999",
          duration: type == "Yearly" ? "/ Year" : "/ Month",
        ),
      ],
    );
  }

  /// 🔹 Language Popup
  // void _showLanguagePopup() {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         backgroundColor: Colors.black,
  //         title: Text("Select Language",
  //             style: TextStyle(color: Colors.white)),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             _languageOption("Punjabi"),
  //             _languageOption("Bhojpuri"),
  //             _languageOption("Haryanvi"),
  //             _languageOption("All"),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  // Widget _languageOption(String language) {
  //   return ListTile(
  //     title: Text(language,
  //         style: TextStyle(color: Colors.white)),
  //     onTap: () {
  //       setState(() {
  //         selectedLanguage = language;
  //       });
  //       Navigator.pop(context);
  //     },
  //   );
  // }

  /// 🔹 Sign In Required Popup
  void _showSignInPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text("Sign In Required",
              style: TextStyle(color: AppColors.white)),
          content: Text(
            "Please sign in to complete the payment.",
            style: TextStyle(color: AppColors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel",
                  style: TextStyle(color: AppColors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SignInPage()),
                );
              },
              child: Text("Sign In",
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );
  }
  void _showApplyPromoPopup() {
    showDialog(
      context: context,
      builder: (context) => const ApplyPromoPopup(),
    );
  }
}
