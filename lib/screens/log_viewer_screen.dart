import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/logging_service.dart';
import '../config/env_config.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final LoggingService _logger = LoggingService();
  String _logContent = '';
  bool _isLoading = true;
  final Set<LogLevel> _selectedLevels = {
    LogLevel.error,
    LogLevel.critical,
    LogLevel.info,
    LogLevel.warning,
    LogLevel.debug,
  };

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final file = await _logger.file;
      if (await file.exists()) {
        final content = await file.readAsString();
        setState(() {
          _logContent = content;
          _isLoading = false;
        });
      } else {
        setState(() {
          _logContent = 'No logs found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _logContent = 'Error loading logs: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _copyLogs() async {
    try {
      await Clipboard.setData(ClipboardData(text: _logContent));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs copied to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error copying logs: $e')),
        );
      }
    }
  }

  Future<void> _shareLogs() async {
    try {
      final file = await _logger.file;
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: '${EnvConfig.appName} Logs',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No logs available to share')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing logs: $e')),
        );
      }
    }
  }

  Future<void> _clearLogs() async {
    try {
      await _logger.clearLogs();
      await _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs cleared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing logs: $e')),
        );
      }
    }
  }

  Future<void> _showClearConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Are you sure you want to clear all logs? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _clearLogs();
    }
  }

  Widget _buildLogFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('ERROR'),
            selected: _selectedLevels.contains(LogLevel.error),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedLevels.add(LogLevel.error);
                } else {
                  _selectedLevels.remove(LogLevel.error);
                }
              });
            },
            backgroundColor: Colors.red.withValues(alpha: (0.1 * 255)),
            selectedColor: Colors.red.withValues(alpha: (0.2 * 255)),
            labelStyle: TextStyle(
              color: _selectedLevels.contains(LogLevel.error) ? Colors.red : null,
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('CRITICAL'),
            selected: _selectedLevels.contains(LogLevel.critical),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedLevels.add(LogLevel.critical);
                } else {
                  _selectedLevels.remove(LogLevel.critical);
                }
              });
            },
            backgroundColor: Colors.purple.withValues(alpha: (0.1 * 255)),
            selectedColor: Colors.purple.withValues(alpha: (0.2 * 255)),
            labelStyle: TextStyle(
              color: _selectedLevels.contains(LogLevel.critical) ? Colors.purple : null,
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('INFO'),
            selected: _selectedLevels.contains(LogLevel.info),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedLevels.add(LogLevel.info);
                } else {
                  _selectedLevels.remove(LogLevel.info);
                }
              });
            },
            backgroundColor: Colors.blue.withValues(alpha: (0.1 * 255)),
            selectedColor: Colors.blue.withValues(alpha: (0.2 * 255)),
            labelStyle: TextStyle(
              color: _selectedLevels.contains(LogLevel.info) ? Colors.blue : null,
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('WARNING'),
            selected: _selectedLevels.contains(LogLevel.warning),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedLevels.add(LogLevel.warning);
                } else {
                  _selectedLevels.remove(LogLevel.warning);
                }
              });
            },
            backgroundColor: Colors.orange.withValues(alpha: (0.1 * 255)),
            selectedColor: Colors.orange.withValues(alpha: (0.2 * 255)),
            labelStyle: TextStyle(
              color: _selectedLevels.contains(LogLevel.warning) ? Colors.orange : null,
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('DEBUG'),
            selected: _selectedLevels.contains(LogLevel.debug),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedLevels.add(LogLevel.debug);
                } else {
                  _selectedLevels.remove(LogLevel.debug);
                }
              });
            },
            backgroundColor: Colors.grey.withValues(alpha: (0.1 * 255)),
            selectedColor: Colors.grey.withValues(alpha: (0.1 * 255)),
            labelStyle: TextStyle(
              color: _selectedLevels.contains(LogLevel.debug) ? Colors.grey : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogContent() {
    final lines = _logContent.split('\n');
    return ListView.builder(
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        Color textColor = Colors.black;
        LogLevel? lineLevel;
        
        if (line.contains('[DEBUG]')) {
          textColor = Colors.grey;
          lineLevel = LogLevel.debug;
        } else if (line.contains('[INFO]')) {
          textColor = Colors.blue;
          lineLevel = LogLevel.info;
        } else if (line.contains('[WARNING]')) {
          textColor = Colors.orange;
          lineLevel = LogLevel.warning;
        } else if (line.contains('[ERROR]')) {
          textColor = Colors.red;
          lineLevel = LogLevel.error;
        } else if (line.contains('[CRITICAL]')) {
          textColor = Colors.purple;
          lineLevel = LogLevel.critical;
        }

        if (lineLevel != null && !_selectedLevels.contains(lineLevel)) {
          return const SizedBox.shrink();
        }

        return SelectableText(
          line,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: textColor,
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogs,
            tooltip: 'Copy Logs',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareLogs,
            tooltip: 'Share Logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showClearConfirmation,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildLogFilters(),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildLogContent(),
          ),
        ],
      ),
    );
  }
} 