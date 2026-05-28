import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../services/database_service.dart';
import 'note_detail_page.dart';
import 'graph_page.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({Key? key}) : super(key: key);

  @override
  _JournalPageState createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  List<Map<String, dynamic>> _memos = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Modal editing variables
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  String _editCategory = 'Personal';
  bool _editIsLocked = false;
  String? _editingMemoId;

  // PIN validation variable for secure notes
  final TextEditingController _pinVerifyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMemos();
  }

  Future<void> _loadMemos() async {
    setState(() => _isLoading = true);
    final list = await DatabaseService.getMemos();
    setState(() {
      _memos = list;
      _isLoading = false;
    });
  }

  void _saveOrUpdateMemo() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out the title and content.')),
      );
      return;
    }

    final id = _editingMemoId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = "${months[now.month - 1]} ${now.day}, ${now.year}";

    final memo = {
      'id': id,
      'title': _titleController.text,
      'content': _contentController.text,
      'date': dateStr,
      'category': _editCategory,
      'tags': _tagsController.text,
      'isPinned': false,
      'isLocked': _editIsLocked,
    };

    if (_editingMemoId == null) {
      await DatabaseService.addMemo(memo);
    } else {
      await DatabaseService.updateMemo(memo);
    }

    _titleController.clear();
    _contentController.clear();
    _tagsController.clear();
    _editingMemoId = null;

    Navigator.pop(context);
    _loadMemos();
  }

  void _deleteMemo(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConfig.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Purge Memo?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to completely expunge "$title" from your dynamic secure physical memory? This is irreversible.', style: GoogleFonts.outfit(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.secondaryColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Expunge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deleteMemo(id, title);
      _loadMemos();
    }
  }

  void _showMemoEditorSheet([Map<String, dynamic>? existingMemo]) {
    if (existingMemo != null) {
      _editingMemoId = existingMemo['id'];
      _titleController.text = existingMemo['title'] ?? '';
      _contentController.text = existingMemo['content'] ?? '';
      _tagsController.text = existingMemo['tags'] ?? '';
      _editCategory = existingMemo['category'] ?? 'Personal';
      _editIsLocked = existingMemo['isLocked'] ?? false;
    } else {
      _editingMemoId = null;
      _titleController.clear();
      _contentController.clear();
      _tagsController.clear();
      _editCategory = 'Personal';
      _editIsLocked = false;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConfig.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConfig.borderRadius)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _editingMemoId == null ? "Forge Sovereign Memo" : "Reforge Mindful Memo",
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.secondaryColor),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Memo Title',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: AppConfig.cardColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _editCategory,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: AppConfig.cardColor,
                            ),
                            items: ['Personal', 'Work', 'Secrets', 'Idea']
                                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: GoogleFonts.outfit(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => _editCategory = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppConfig.cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _editIsLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                                color: _editIsLocked ? AppConfig.primaryColor : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text("Encrypt Note", style: GoogleFonts.outfit(fontSize: 12)),
                              Switch(
                                value: _editIsLocked,
                                activeColor: AppConfig.primaryColor,
                                onChanged: (val) {
                                  setModalState(() => _editIsLocked = val);
                                },
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        hintText: 'Tags (e.g. Work, Secret, Daily)',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: AppConfig.cardColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: 'Log your dynamic private thoughts here...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: AppConfig.cardColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveOrUpdateMemo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _editingMemoId == null ? 'Lock Sanctuary Memo' : 'Secure Memo Reforge',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _verifyPinAndOpenMemo(Map<String, dynamic> memo) async {
    final correctPin = await DatabaseService.getMasterPin();
    _pinVerifyController.clear();

    final unlocked = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConfig.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock, color: AppConfig.primaryColor),
            const SizedBox(width: 8),
            Text('Biometric PIN Required', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter master security PIN to decrypt and authorize access to this safe note.', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
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
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
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
            child: Text('Decrypt', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (unlocked == true) {
      await DatabaseService.addSentinelLog('Security Decrypt', 'Access granted to Locked Memo: "${memo['title']}"', status: 'SUCCESS');
      _showMemoEditorSheet(memo);
    } else {
      await DatabaseService.addSentinelLog('Intrusion Warning', 'Failed attempt to open Locked Memo: "${memo['title']}"', status: 'WARNING');
    }
  }

  List<Map<String, dynamic>> _getFilteredMemos() {
    return _memos.where((memo) {
      final matchesSearch = (memo['title'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (memo['content'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesCategory = _selectedCategory == 'All' || memo['category'] == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredMemos();

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Safe Memos Vault',
          style: GoogleFonts.outfit(color: AppConfig.secondaryColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.hub_rounded, color: AppConfig.primaryColor),
            tooltip: 'Mind Graph View',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GraphPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConfig.paddingCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                hintText: 'Search private sandboxed memos...',
                hintStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: AppConfig.cardColor,
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
            const SizedBox(height: 12),
            
            // Category Slider
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['All', 'Personal', 'Work', 'Secrets', 'Idea'].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
                      selected: isSelected,
                      selectedColor: AppConfig.primaryColor,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : AppConfig.secondaryColor),
                      onSelected: (selected) {
                        setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              'ALL LOCAL MEMOS',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppConfig.secondaryColor.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 8),

            // Memos List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppConfig.primaryColor))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('No sovereign memos found offline.', style: GoogleFonts.outfit(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final isLocked = item['isLocked'] == true;
                            
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NoteDetailPage(
                                      memo: item,
                                      onModified: _loadMemos,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppConfig.cardColor,
                                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.015),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(item['date'] ?? '', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 11)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppConfig.primaryColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            item['category'] ?? 'General',
                                            style: GoogleFonts.outfit(fontSize: 10, color: AppConfig.primaryColor, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        if (isLocked)
                                          const Padding(
                                            padding: EdgeInsets.only(right: 6.0),
                                            child: Icon(Icons.lock_rounded, color: AppConfig.primaryColor, size: 16),
                                          ),
                                        Expanded(
                                          child: Text(
                                            item['title'] ?? '',
                                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.secondaryColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isLocked ? '••••••••••••••••••••••••••••••••' : (item['content'] ?? ''),
                                      style: GoogleFonts.outfit(fontSize: 13, height: 1.4, color: AppConfig.secondaryColor.withOpacity(0.8)),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Tags
                                        Text(
                                          item['tags'] != null && (item['tags'] as String).isNotEmpty
                                              ? (item['tags'] as String).split(',').map((t) => '#${t.trim()}').join(' ')
                                              : '',
                                          style: GoogleFonts.outfit(fontSize: 11, color: AppConfig.primaryColor.withOpacity(0.8), fontWeight: FontWeight.w600),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_rounded, color: Colors.grey, size: 18),
                                              onPressed: () {
                                                if (isLocked) {
                                                  _verifyPinAndOpenMemo(item);
                                                } else {
                                                  _showMemoEditorSheet(item);
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete_forever_rounded, color: Colors.red.shade300, size: 18),
                                              onPressed: () => _deleteMemo(item['id'], item['title']),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppConfig.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _showMemoEditorSheet(),
        child: const Icon(Icons.add_comment_rounded, color: Colors.white),
      ),
    );
  }
}