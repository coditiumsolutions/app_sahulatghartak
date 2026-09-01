import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Converts a caught error into text safe to show users directly.
///
/// Network/OS-level failures (no connection, DNS failure, TLS handshake
/// failure, request timeout) throw exception types whose [Object.toString]
/// dumps raw technical/OS detail (e.g. "SocketException: Failed host lookup:
/// 'sahulatghartak.com' (OS Error: ...)"). Those are mapped to plain-language
/// messages here instead. Exceptions thrown by our own API service layer
/// (plain `Exception('...')` with an already user-facing message) pass
/// through unchanged, aside from stripping the `Exception: ` prefix.
String friendlyErrorMessage(Object error) {
  if (error is TimeoutException) {
    return 'The request took too long to respond. Please check your connection and try again.';
  }
  if (error is SocketException) {
    return 'Unable to reach the server. Please check your internet connection and try again.';
  }
  if (error is HandshakeException) {
    return 'A secure connection could not be established. Please try again.';
  }
  if (error is http.ClientException) {
    return 'Unable to reach the server. Please check your internet connection and try again.';
  }
  if (error is FormatException) {
    return 'Received an unexpected response from the server. Please try again later.';
  }
  return error.toString().replaceFirst('Exception: ', '');
}
