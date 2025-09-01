import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class DebugHelper {
  static const String tag = 'DebugHelper';
  
  static void logError(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('🔴 ERROR: $message');
      if (error != null) print('🔴 Details: $error');
      if (stackTrace != null) print('🔴 Stack: $stackTrace');
    }
    
    developer.log(
      message,
      name: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  static void logInfo(String message) {
    if (kDebugMode) {
      print('🔵 INFO: $message');
    }
    developer.log(message, name: tag);
  }
  
  static void logWarning(String message) {
    if (kDebugMode) {
      print('🟡 WARNING: $message');
    }
    developer.log(message, name: tag);
  }
  
  static void logSuccess(String message) {
    if (kDebugMode) {
      print('🟢 SUCCESS: $message');
    }
    developer.log(message, name: tag);
  }
}
