/// Base URL for the nollanet /media/ proxy route.
/// The backend at nolla.net proxies Azure Blob content through this path,
/// so relative paths returned by the API (e.g. "photos-thumbs/stem.jpg")
/// should be prefixed with this base to form a valid URL.
const kMediaBaseUrl = 'https://nolla.net/media/';

/// Resolves a URL that may be relative or absolute.
///
/// - Returns `null` if [url] is null.
/// - Returns the URL as-is if it already starts with `http://` or `https://`.
/// - Prefixes with [kMediaBaseUrl] if it looks like a relative path
///   (i.e. non-empty and not starting with a scheme).
/// - Returns the URL as-is for anything else (defensive fallback).
String? resolveMediaUrl(String? url) {
  if (url == null) return null;
  if (url.isEmpty) return url;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  // Treat anything else as a relative path against the /media/ route.
  return kMediaBaseUrl + url;
}
