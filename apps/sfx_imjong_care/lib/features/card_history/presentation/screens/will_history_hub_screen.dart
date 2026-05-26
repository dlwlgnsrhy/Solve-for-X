import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sfx_imjong_care/core/services/app_storage.dart';
import 'package:sfx_imjong_care/core/theme/card_template.dart';
import 'package:sfx_imjong_care/features/will_input/domain/entities/will_card.dart';
import 'package:sfx_imjong_care/features/will_input/presentation/screens/will_input_screen.dart';

class WillHistoryHubScreen extends StatefulWidget {
  const WillHistoryHubScreen({super.key});

  @override
  State<WillHistoryHubScreen> createState() => _WillHistoryHubScreenState();
}

class _WillHistoryHubScreenState extends State<WillHistoryHubScreen> {
  String _selectedFilter = 'all'; // all, neon, sunset, ocean, aurora
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  CardTemplate _parseTemplate(String name) {
    switch (name.toLowerCase()) {
      case 'neon':
        return CardTemplate.neon;
      case 'sunset':
        return CardTemplate.sunset;
      case 'ocean':
        return CardTemplate.ocean;
      case 'aurora':
        return CardTemplate.aurora;
      default:
        return CardTemplate.neon;
    }
  }

  String _formatDate(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final month = dt.month.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$month/$day $hour:$minute';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070C),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildSearchAndFilters(),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: AppStorage.getCardHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
                      ),
                    );
                  }

                  // Robust SRE safety check: query failure or empty DB
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final history = snapshot.data!;
                  
                  // Apply template filters and search queries
                  final filteredHistory = history.where((entry) {
                    final templateStr = (entry['template'] as String? ?? 'neon').toLowerCase();
                    final nameStr = (entry['name'] as String? ?? '').toLowerCase();
                    final willStr = (entry['will'] as String? ?? '').toLowerCase();
                    
                    final matchesFilter = _selectedFilter == 'all' || templateStr == _selectedFilter;
                    final matchesSearch = _searchQuery.isEmpty ||
                        nameStr.contains(_searchQuery) ||
                        willStr.contains(_searchQuery);
                    
                    return matchesFilter && matchesSearch;
                  }).toList();

                  if (filteredHistory.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final entry = filteredHistory[index];
                      // Find actual index in global history for deletion logic
                      final globalIndex = history.indexOf(entry);
                      
                      final card = WillCard(
                        name: entry['name'] as String? ?? '',
                        values: List<String>.from(entry['values'] as List? ?? []),
                        will: entry['will'] as String? ?? '',
                      );
                      final template = _parseTemplate(entry['template'] as String? ?? 'neon');
                      final timestamp = entry['timestamp'] as String? ?? '';

                      return _GridCardItem(
                        card: card,
                        template: template,
                        timestamp: _formatDate(timestamp),
                        onTap: () {
                          // Secure routing to editor with target card details loaded
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WillInputScreen(editCard: card),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        onLongPress: () => _showDeleteConfirmDialog(context, card.name, globalIndex),
                      ).animate().scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      ).fadeIn(duration: const Duration(milliseconds: 250));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              const Text(
                'WILL ARCHIVE',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '이곳에 당신의 소중한 가치를 보관합니다.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF888899),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF00FF88),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Search Field
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF131320),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF888899), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      hintText: '작성자명 또는 유언 키워드 검색',
                      hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF555566),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    child: const Icon(Icons.close, color: Color(0xFF888899), size: 16),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'all', const Color(0xFF00FF88)),
                _buildFilterChip('NEON', 'neon', const Color(0xFF00FF88)),
                _buildFilterChip('SUNSET', 'sunset', const Color(0xFFFF00AA)),
                _buildFilterChip('OCEAN', 'ocean', const Color(0xFF00DDFF)),
                _buildFilterChip('AURORA', 'aurora', const Color(0xFFAA00FF)),
                _buildFilterChip('POSTCARD', 'creamPostcard', const Color(0xFF8C7E70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color accent) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? accent.withValues(alpha: 0.15) : const Color(0xFF101018),
          border: Border.all(
            color: isSelected ? accent : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isSelected ? accent : const Color(0xFF888899),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 16),
          const Text(
            '보관함이 비어 있습니다',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '첫 번째 유서 카드를 만들고 보관해 보세요.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF555566),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WillInputScreen(),
                ),
              ).then((_) => setState(() {}));
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              '유서 작성하기',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF88),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400));
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 48,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 16),
          const Text(
            '검색 결과가 없습니다',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF666677),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, String name, int globalIndex) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: const Color(0xFF131320),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFF0055), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF0055).withValues(alpha: 0.25),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'CARD DELETE / 카드 삭제',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 14,
                    color: const Color(0xFFFF0055),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text(
                  '$name 님의 유서 카드를 보관소에서 정말 삭제하시겠습니까?',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFFCCCCCC),
                    height: 1.5,
                  ),
                ),
              ),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        '취소',
                        style: TextStyle(color: Color(0xFF888899)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await AppStorage.deleteCardFromHistory(globalIndex);
                        setState(() {});
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '카드가 삭제되었습니다.',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                            ),
                            backgroundColor: Color(0xFFFF0055),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF0055),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '삭제',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridCardItem extends StatelessWidget {
  final WillCard card;
  final CardTemplate template;
  final String timestamp;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _GridCardItem({
    required this.card,
    required this.template,
    required this.timestamp,
    required this.onTap,
    required this.onLongPress,
  });

  bool get isCream => template == CardTemplate.creamPostcard;
  Color get primaryTextColor => isCream ? const Color(0xFF594F45) : Colors.white;
  Color get secondaryTextColor => isCream ? const Color(0xBB594F45) : const Color(0xFFCCCCCC);
  Color get dividerColor => isCream ? const Color(0x22594F45) : Colors.white.withValues(alpha: 0.1);

  TextStyle getKoreanStyle({required double fontSize, required FontWeight fontWeight, double? height, FontStyle? fontStyle}) {
    if (isCream) {
      return GoogleFonts.notoSerifKr(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: primaryTextColor,
        height: height,
        fontStyle: fontStyle,
      );
    }
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: primaryTextColor,
      height: height,
      fontStyle: fontStyle,
    );
  }

  TextStyle getEnglishStyle({required double fontSize, required FontWeight fontWeight, double? letterSpacing, Color? customColor}) {
    if (isCream) {
      return GoogleFonts.cormorantGaramond(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: customColor ?? template.accentColor,
        letterSpacing: letterSpacing,
      );
    }
    return TextStyle(
      fontFamily: 'Orbitron',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: customColor ?? template.accentColor,
      letterSpacing: letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: template.gradientColors,
          ),
          border: Border.all(
            color: template.borderColor.withValues(alpha: isCream ? 0.4 : 0.5),
            width: 1.5,
          ),
          boxShadow: isCream
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: template.accentColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: icon + name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      template.icon,
                      color: template.accentColor,
                      size: 14,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          card.name,
                          style: getKoreanStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 0.5,
                  color: dividerColor,
                ),
                const SizedBox(height: 10),
                // Values (first 2 values)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...card.values.take(2).map((val) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: template.accentColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  val,
                                  style: getKoreanStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 6),
                      // Will snippet
                      Expanded(
                        child: Text(
                          card.will,
                          style: getKoreanStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 0.5,
                  color: dividerColor,
                ),
                const SizedBox(height: 8),
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timestamp,
                      style: isCream
                          ? GoogleFonts.cormorantGaramond(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: secondaryTextColor.withValues(alpha: 0.8),
                            )
                          : const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 8,
                              color: Color(0xFF666677),
                            ),
                    ),
                    Text(
                      template.name.split('/')[0].trim(),
                      style: getEnglishStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
