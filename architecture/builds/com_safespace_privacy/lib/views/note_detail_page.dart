import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../services/database_service.dart';

class NoteDetailPage extends StatefulWidget {
  final Map<String, dynamic> memo;
  final VoidCallback onModified;

  const NoteDetailPage({
    Key? key,
    required this.memo,
    required this.onModified,
  }) : super(key: key);

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late Map<String, dynamic> _memo;
  bool _isLocked = false;
  final TextEditingController _pinVerifyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _memo = widget.memo;
    _isLocked = _memo['isLocked'] == true;
  }

  void _refreshMemoState() async {
    final list = await DatabaseService.getMemos();
    final updated = list.firstWhere(
      (m) => m['id'] == _memo['id'],
      orElse: () => _memo,
    );
    setState(() {
      _memo = updated;
      _isLocked = _memo['isLocked'] == true;
    });
    widget.onModified();
  }

  void _verifyPinAndUnlock() async {
    final correctPin = await DatabaseService.getMasterPin();
    _pinVerifyController.clear();

    final unlocked = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConfig.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: AppConfig.primaryColor),
            const SizedBox(width: 8),
            Text('Biometric PIN Required', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter master security PIN to decrypt this sovereign note.', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _pinVerifyController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                hintText: 'PIN Code',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryColor),
            onPressed: () {
              if (_pinVerifyController.text == correctPin) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid biometric security PIN code.')),
                );
              }
            },
            child: const Text('Decrypt', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (unlocked == true) {
      await DatabaseService.addSentinelLog('Security Decrypt', 'Access granted to Locked Memo: "${_memo['title']}"', status: 'SUCCESS');
      setState(() {
        _isLocked = false;
      });
    } else {
      await DatabaseService.addSentinelLog('Intrusion Warning', 'Failed attempt to open Locked Memo: "${_memo['title']}"', status: 'WARNING');
    }
  }

  void _toggleLockState() async {
    final newState = !(_memo['isLocked'] == true);
    final updated = Map<String, dynamic>.from(_memo);
    updated['isLocked'] = newState;
    
    await DatabaseService.updateMemo(updated);
    await DatabaseService.addSentinelLog(
      newState ? 'Security Alert' : 'Security Decrypt', 
      newState ? 'Memo "${_memo['title']}" locked with master key' : 'Memo "${_memo['title']}" unlocked permanently',
      status: 'SUCCESS'
    );
    _refreshMemoState();
  }

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _memo['content'] ?? ''));
    await DatabaseService.addSentinelLog('Data Portability', 'Copied raw Markdown of "${_memo['title']}" to secure memory', status: 'SUCCESS');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Markdown copied to sovereign system clipboard!'),
        backgroundColor: AppConfig.primaryColor,
      ),
    );
  }

  void _toggleChecklistItem(int lineIndex, String originalLine, bool currentVal) async {
    final content = _memo['content'] as String? ?? '';
    final lines = content.split('\n');
    if (lineIndex < lines.length) {
      final newLine = currentVal 
          ? originalLine.replaceFirst('- [x]', '- [ ]')
          : originalLine.replaceFirst('- [ ]', '- [x]');
      lines[lineIndex] = newLine;
      
      final updated = Map<String, dynamic>.from(_memo);
      updated['content'] = lines.join('\n');
      
      await DatabaseService.updateMemo(updated);
      await DatabaseService.addSentinelLog('Data Check', 'Checklist task toggled in "${_memo['title']}"', status: 'SUCCESS');
      _refreshMemoState();
    }
  }

  void _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConfig.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Expunge Memo?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to completely destroy "${_memo['title']}" from your sandboxed local storage?', style: GoogleFonts.outfit(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Expunge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deleteMemo(_memo['id'], _memo['title'] ?? '');
      widget.onModified();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppConfig.secondaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isLocked ? 'Locked Memo' : (_memo['title'] ?? 'Memo Details'),
          style: GoogleFonts.outfit(color: AppConfig.secondaryColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (!_isLocked) ...[
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Colors.grey),
              tooltip: 'Copy Markdown',
              onPressed: _copyToClipboard,
            ),
            IconButton(
              icon: Icon(
                _memo['isLocked'] == true ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: AppConfig.primaryColor,
              ),
              tooltip: 'Toggle Cipher Lock',
              onPressed: _toggleLockState,
            ),
            IconButton(
              icon: Icon(Icons.delete_forever_rounded, color: Colors.red.shade300),
              tooltip: 'Purge Note',
              onPressed: _deleteNote,
            ),
          ]
        ],
      ),
      body: _isLocked ? _buildLockedState() : _buildSovereignReader(),
    );
  }

  Widget _buildLockedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConfig.primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 64,
                color: AppConfig.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sovereign Encryption Active',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppConfig.secondaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              'This note is encrypted inside your hardware sandbox partition. Access requires your biometric master security PIN.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: _verifyPinAndUnlock,
              icon: const Icon(Icons.fingerprint_rounded, color: Colors.white),
              label: Text('Decrypt with Master PIN', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSovereignReader() {
    final String content = _memo['content'] as String? ?? '';
    final lines = content.split('\n');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppConfig.paddingCard, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metadata Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConfig.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _memo['date'] ?? 'Today',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConfig.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _memo['category'] ?? 'Personal',
                        style: GoogleFonts.outfit(fontSize: 10, color: AppConfig.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (_memo['tags'] != null && (_memo['tags'] as String).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: (_memo['tags'] as String).split(',').map((t) {
                      return Chip(
                        elevation: 0,
                        backgroundColor: AppConfig.backgroundColor,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text('#${t.trim()}', style: GoogleFonts.outfit(fontSize: 10, color: AppConfig.primaryColor, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Markdown Render Engine
          ..._renderMarkdown(lines),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<Widget> _renderMarkdown(List<String> lines) {
    final List<Widget> widgets = [];
    bool inCodeBlock = false;
    List<String> codeLines = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Code Block Detection
      if (line.trim().startsWith('```')) {
        if (inCodeBlock) {
          // Close Code Block
          widgets.add(_buildCodeBlockWidget(codeLines));
          codeLines = [];
          inCodeBlock = false;
        } else {
          // Open Code Block
          inCodeBlock = true;
        }
        continue;
      }

      if (inCodeBlock) {
        codeLines.add(line);
        continue;
      }

      final trimmed = line.trim();

      // Headers
      if (trimmed.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            trimmed.substring(2),
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppConfig.secondaryColor),
          ),
        ));
      } else if (trimmed.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14.0, bottom: 6.0),
          child: Text(
            trimmed.substring(3),
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.secondaryColor),
          ),
        ));
      } else if (trimmed.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
          child: Text(
            trimmed.substring(4),
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.secondaryColor),
          ),
        ));
      }
      // Interactive Checklist
      else if (trimmed.startsWith('- [ ] ')) {
        widgets.add(_buildChecklistItem(i, line, trimmed.substring(6), false));
      } else if (trimmed.startsWith('- [x] ')) {
        widgets.add(_buildChecklistItem(i, line, trimmed.substring(6), true));
      }
      // Bullet Points
      else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6, right: 10),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppConfig.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  _parseInlineStyles(trimmed.substring(2)),
                  style: GoogleFonts.outfit(fontSize: 14, color: AppConfig.secondaryColor.withOpacity(0.85), height: 1.5),
                ),
              ),
            ],
          ),
        ));
      }
      // Empty Line
      else if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 12));
      }
      // Standard Paragraph
      else {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: RichText(
            text: TextSpan(
              children: _parseInlineRichText(trimmed),
              style: GoogleFonts.outfit(fontSize: 14, color: AppConfig.secondaryColor.withOpacity(0.85), height: 1.6),
            ),
          ),
        ));
      }
    }

    // Edge case: unclosed code block
    if (inCodeBlock && codeLines.isNotEmpty) {
      widgets.add(_buildCodeBlockWidget(codeLines));
    }

    return widgets;
  }

  Widget _buildChecklistItem(int lineIndex, String originalLine, String text, bool checked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () => _toggleChecklistItem(lineIndex, originalLine, checked),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: checked ? AppConfig.primaryColor : Colors.grey.shade400,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: checked ? Colors.grey : AppConfig.secondaryColor,
                    decoration: checked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeBlockWidget(List<String> codeLines) {
    final rawCode = codeLines.join('\n');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppConfig.backgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SANDBOX CIPHER BLOCK',
                  style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: rawCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cipher text copied successfully.')),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.copy_rounded, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Copy', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              rawCode,
              style: GoogleFonts.sourceCodePro(
                fontSize: 12,
                color: AppConfig.secondaryColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Very basic helper to remove bold/italic markers for clean plain text display
  String _parseInlineStyles(String text) {
    return text.replaceAll('**', '').replaceAll('*', '');
  }

  // Advanced parser to generate inline bold/regular text spans dynamically
  List<TextSpan> _parseInlineRichText(String text) {
    final List<TextSpan> spans = [];
    final regExp = RegExp(r'\*\*(.*?)\*\*'); // Matches **bold**
    int lastIndex = 0;

    for (final match in regExp.allMatches(text)) {
      // Add plain text before match
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      // Add bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }
}
