import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:js' as js;
import 'package:flutter/material.dart';

// Track registered factories to avoid duplicate registration
final Set<String> _registeredFactories = {};
int _adInstanceCounter = 0;

Widget getWebAdView(String adClient, String adSlot) {
  if (adClient.isEmpty || adSlot.isEmpty) {
    return const SizedBox.shrink();
  }

  final String viewID = 'adsense-display-$adSlot-${_adInstanceCounter++}';

  if (!_registeredFactories.contains(viewID)) {
    ui_web.platformViewRegistry.registerViewFactory(viewID, (int viewId) {
      final container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.minHeight = '100px'
        ..style.textAlign = 'center'
        ..style.overflow = 'hidden';

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

      // Safe push after element is attached to DOM
      html.window.animationFrame.then((_) {
        try {
          if (ins.isConnected == true && ins.dataset['adStatus'] != 'filled') {
            js.context.callMethod('eval', [
              'if (typeof adsbygoogle !== "undefined") { adsbygoogle.push({}); }'
            ]);
            ins.dataset['adStatus'] = 'filled';
          }
        } catch (_) {
          // Suppress AdSense push errors gracefully
        }
      });

      return container;
    });
    _registeredFactories.add(viewID);
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      double width = constraints.maxWidth > 0 ? constraints.maxWidth : 300;
      return SizedBox(
        width: width,
        height: 250,
        child: HtmlElementView(viewType: viewID),
      );
    },
  );
}
