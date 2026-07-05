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

bool isLineWebView() {
  return html.window.navigator.userAgent.toLowerCase().contains('line/');
}

/// LINE 專用：把當前網址加上 ?openExternalBrowser=1 再導過去，
/// LINE 內建瀏覽器會改用系統預設瀏覽器（Safari/Chrome）重開，
/// Google OAuth 才能正常運作。
///
/// 已帶該參數時直接 return，避免跳轉沒外開時造成無限迴圈。
void maybeRedirectToExternalBrowser() {
  final uri = Uri.base;
  if (uri.queryParameters['openExternalBrowser'] == '1') return;
  final params = Map<String, String>.from(uri.queryParameters);
  params['openExternalBrowser'] = '1';
  html.window.location.replace(uri.replace(queryParameters: params).toString());
}
