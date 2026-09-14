import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:js' as js;
import 'package:flutter/material.dart';

// Keep track of registered factories to avoid duplicate registration
final Set<String> _registeredFactories = {};

Widget getWebAdView(String adClient, String adSlot) {
  return const SizedBox.shrink();
}
