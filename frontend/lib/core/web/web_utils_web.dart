// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

const _tokenKey = 'rr_lp_token';

/// Store [token] in localStorage then navigate the browser to the
/// standalone Load-Provider portal (native HTML — no Flutter canvas).
void redirectToLoadProvider(String token) {
  html.window.localStorage[_tokenKey] = token;
  html.window.location.assign('/load-provider/');
}

/// Read the token that Flutter placed before the redirect.
String? readLoadProviderToken() =>
    html.window.localStorage[_tokenKey];

/// Remove the token from localStorage (on logout).
void clearLoadProviderToken() =>
    html.window.localStorage.remove(_tokenKey);
