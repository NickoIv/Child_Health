import 'package:web/web.dart' as web;

/// Hands a `mailto:` link to the browser.
///
/// `window.open` with `_self` rather than assigning `location.href`: on iOS
/// Safari, navigating the current document to a `mailto:` while the app is
/// running as a home-screen PWA can leave a blank page behind if no mail app
/// picks it up, and there is no back button in a PWA to get out of it.
///
/// It cannot be known from here whether a client actually opened — the
/// browser tells nobody. True means the link was handed over, which is why
/// the screen shows the address as well and never says «письмо отправлено».
Future<bool> openMail(String url) async {
  try {
    web.window.open(url, '_self');
    return true;
  } catch (_) {
    return false;
  }
}
