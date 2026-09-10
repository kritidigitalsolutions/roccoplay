import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:js' as js;
import 'package:flutter/material.dart';

// Keep track of registered factories to avoid duplicate registration
final Set<String> _registeredFactories = {};

Widget getWebAdView(String adClient, String adSlot) {
  final String viewID = 'adsense-display-$adSlot';

  if (!_registeredFactories.contains(viewID)) {
    ui_web.platformViewRegistry.registerViewFactory(viewID, (int viewId) {
      // Create a container div with explicit styles
      final container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.minHeight = '100px'
        ..style.textAlign = 'center'
        ..style.overflow = 'hidden';

      // Create the AdSense ins tag
      final ins = html.Element.tag('ins')
        ..className = 'adsbygoogle'
        ..style.display = 'block'
        ..dataset = {
          'adClient': adClient,
          'adSlot': adSlot,
          'adFormat': 'auto',
          'fullWidthResponsive': 'true',
        };

      container.append(ins);

      // Use a MutationObserver or a simple delay to ensure the ins is in DOM before push
      html.window.animationFrame.then((_) {
        try {
          // Trigger the push using dart:js context
          // This is the safest way to execute the push command on web
          js.context.callMethod('eval', ['(adsbygoogle = window.adsbygoogle || []).push({});']);
        } catch (e) {
          print('AdSense push error: $e');
        }
      });

      return container;
    });
    _registeredFactories.add(viewID);
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      // Ensure the parent gives some space
      double width = constraints.maxWidth > 0 ? constraints.maxWidth : 300;
      return SizedBox(
        width: width,
        height: 250, // Standard banner height fallback
        child: HtmlElementView(viewType: viewID),
      );
    },
  );
}
