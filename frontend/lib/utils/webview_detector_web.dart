import 'dart:html' as html;

bool isInWebView() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  // Android WebView
  if (ua.contains('; wv)')) return true;
  // Facebook, Instagram, LINE, Twitter, WeChat in-app browsers
  if (ua.contains('fban') || ua.contains('fbav') || ua.contains('fb_iab')) return true;
  if (ua.contains('instagram')) return true;
  if (ua.contains('line/')) return true;
  if (ua.contains('twitter')) return true;
  if (ua.contains('micromessenger')) return true;
  // iOS in-app browsers: has iPhone/iPad but missing Safari token
  if (ua.contains('iphone') && !ua.contains('safari')) return true;
  if (ua.contains('ipad') && !ua.contains('safari')) return true;
  return false;
}
