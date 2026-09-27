// Fixtures for mobile-kotlin.yaml
fun save(prefs: SharedPreferences, token: String, theme: String, webView: WebView) {
    // ruleid: va-android-token-in-shared-preferences
    prefs.edit().putString("auth_token", token).apply()
    // ok: va-android-token-in-shared-preferences
    prefs.edit().putString("theme", theme).apply()
    // ruleid: va-android-webview-file-access
    webView.settings.allowUniversalAccessFromFileURLs = true
    // ok: va-android-webview-file-access
    webView.settings.allowFileAccess = false
}
