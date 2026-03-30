import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSearchController extends GetxController {
  var searchQuery = "".obs;
  final TextEditingController searchController = TextEditingController();

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = "";
  }
}
