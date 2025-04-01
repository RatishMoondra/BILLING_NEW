import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  static File? _logFile;

  factory LoggingService() {
    return _instance;
  }

  LoggingService._internal();

  Future<File> get file async {
    if (_logFile != null) return _logFile!;
    
    final directory = await getApplicationDocumentsDirectory();
    final logDir = Directory(path.join(directory.path, 'logs'));
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    
    _logFile = File(path.join(logDir.path, 'app.log'));
    return _logFile!;
  }

  String _formatLogMessage(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.toString().split('.').last.toUpperCase();
    var logMessage = '[$timestamp] [$levelStr] $message';
    
    if (error != null) {
      logMessage += '\nError: $error';
      if (error is Exception) {
        logMessage += '\nException Type: ${error.runtimeType}';
      }
    }
    
    if (stackTrace != null) {
      logMessage += '\nStackTrace:\n$stackTrace';
    }
    
    return '$logMessage\n';
  }

  Future<void> _writeLog(String message) async {
    try {
      final logFile = await file;
      await logFile.writeAsString(message, mode: FileMode.append);
    } catch (e) {
      print('Failed to write to log file: $e');
    }
  }

  Future<void> debug(String message, [Object? error, StackTrace? stackTrace]) async {
    final logMessage = _formatLogMessage(LogLevel.debug, message, error, stackTrace);
    await _writeLog(logMessage);
  }

  Future<void> info(String message, [Object? error, StackTrace? stackTrace]) async {
    final logMessage = _formatLogMessage(LogLevel.info, message, error, stackTrace);
    await _writeLog(logMessage);
  }

  Future<void> warning(String message, [Object? error, StackTrace? stackTrace]) async {
    final logMessage = _formatLogMessage(LogLevel.warning, message, error, stackTrace);
    await _writeLog(logMessage);
  }

  Future<void> error(String message, [Object? error, StackTrace? stackTrace]) async {
    final logMessage = _formatLogMessage(LogLevel.error, message, error, stackTrace);
    await _writeLog(logMessage);
  }

  Future<void> critical(String message, [Object? error, StackTrace? stackTrace]) async {
    final logMessage = _formatLogMessage(LogLevel.critical, message, error, stackTrace);
    await _writeLog(logMessage);
  }

  // Convenience methods for common logging patterns
  Future<void> logException(String message, Object error, StackTrace stackTrace) async {
    await this.error(message, error, stackTrace);
  }

  Future<void> logError(String message, [Object? error]) async {
    await this.error(message, error);
  }

  Future<void> logInfo(String message) async {
    await info(message);
  }

  Future<void> clearLogs() async {
    try {
      final logFile = await file;
      await logFile.writeAsString('');
      await info('Logs cleared');
    } catch (e) {
      print('Failed to clear logs: $e');
    }
  }
} 