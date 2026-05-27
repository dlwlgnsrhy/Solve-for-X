import 'dart:core';

/// Model representing the result of the Korean Civil Act Article 1060 legal formalities validation.
class LegalValidationResult {
  final bool hasName;
  final bool hasSignature;
  final bool hasDate;
  final bool hasAddress;
  final String? matchedName;
  final String? matchedSignature;
  final String? matchedDate;
  final String? matchedAddress;

  LegalValidationResult({
    required this.hasName,
    required this.hasSignature,
    required this.hasDate,
    required this.hasAddress,
    this.matchedName,
    this.matchedSignature,
    this.matchedDate,
    this.matchedAddress,
  });

  /// The will is legally valid under Article 1060/1066 only if all 4 key requirements are met.
  bool get isFullyValid => hasName && hasSignature && hasDate && hasAddress;
}

class LegalValidator {
  /// Regular expressions and pattern matching for the 4 core legal requirements.
  
  // 1. Testator Name: Matches common introductory phrases, labels, or exact author inclusion.
  static final RegExp _koreanNameRegex = RegExp(
    r'(?:유언자|성명|이름|나|본인)\s*(?:은|는|이|:|가)?\s*([가-힣]{2,5})',
    caseSensitive: false,
  );
  static final RegExp _englishNameRegex = RegExp(
    r'(?:I|testator|Testator|Name|name)\s*(?:is|:|,)?\s*([a-zA-Z\s]{2,20})',
    caseSensitive: false,
  );

  // 2. Signature / Seal: Matches explicit indicators like (인), [인], (서명), (seal), (signature), or verbs like 서명함/날인함.
  static final RegExp _signatureRegex = RegExp(
    r'(\((?:인|서명|seal|signature)\)|\[(?:인|서명|seal|signature)\]|날인|서명함|\b(?:seal|signature|signed|signed by)\b)',
    caseSensitive: false,
  );

  // 3. Specific Date: Must include year, month, and day (e.g. 2026년 05월 27일, 2026.05.27, May 27, 2026, 2026-05-27)
  static final RegExp _koreanDateRegex = RegExp(
    r'(\d{2,4}\s*년\s*\d{1,2}\s*월\s*\d{1,2}\s*일)',
    caseSensitive: false,
  );
  static final RegExp _dotDateRegex = RegExp(
    r'(\d{4}[\.\-/]\s*\d{1,2}[\.\-/]\s*\d{1,2})',
    caseSensitive: false,
  );
  static final RegExp _englishDateRegex = RegExp(
    r'((?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{1,2}(?:st|nd|rd|th)?,?\s+\d{4})',
    caseSensitive: false,
  );
  static final RegExp _englishDateAltRegex = RegExp(
    r'(\d{1,2}(?:st|nd|rd|th)?\s+(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?,?\s+\d{4})',
    caseSensitive: false,
  );

  // 4. Physical Address: Matches postal markers, words like "Address", or typical address patterns in Korean and English.
  static final RegExp _addressLabelRegex = RegExp(
    r'(?:주소|Address|address|Addr)\s*:\s*([가-힣a-zA-Z0-9\s,\-\(\)#\.]+)',
    caseSensitive: false,
  );
  static final RegExp _koreanAddressRegex = RegExp(
    r'([가-힣]+(?:시|도)\s+[가-힣]+(?:시|군|구)(?:\s+[가-힣0-9]+(?:동|읍|면|리|로|길|번지|길|아파트|빌라))?)',
    caseSensitive: false,
  );
  static final RegExp _englishAddressRegex = RegExp(
    r'(\d+\s+[a-zA-Z0-9\s\.,]{3,}\s+(?:Street|St|Road|Rd|Avenue|Ave|Drive|Dr|Lane|Ln|Court|Ct|Circle|Cir|Boulevard|Blvd|City|State|Zip|Apt|Apartment|Suite|Ste)\b)',
    caseSensitive: false,
  );

  /// Validates the holographic will text against the 4 core legal requirements.
  /// Context-aware validation checks the provided [author] if it's not a generic anonymous value.
  static LegalValidationResult validate(String content, {String? author}) {
    final sanitizedContent = content.trim();

    // 1. Validate Testator Name
    bool hasName = false;
    String? matchedName;

    // Check Korean/English pattern
    final koNameMatch = _koreanNameRegex.firstMatch(sanitizedContent);
    if (koNameMatch != null) {
      hasName = true;
      matchedName = koNameMatch.group(0);
    } else {
      final enNameMatch = _englishNameRegex.firstMatch(sanitizedContent);
      if (enNameMatch != null) {
        hasName = true;
        matchedName = enNameMatch.group(0);
      }
    }

    // Context check: if a real author is provided, and it's written in the content, it satisfies the name requirement
    if (author != null && author.isNotEmpty) {
      final isAnon = author == '익명' || author == 'Anonymous' || author.toLowerCase() == 'anonymous';
      if (!isAnon && sanitizedContent.contains(author)) {
        hasName = true;
        matchedName = matchedName ?? author;
      }
    }

    // 2. Validate Signature / Seal
    bool hasSignature = false;
    String? matchedSignature;
    final sigMatch = _signatureRegex.firstMatch(sanitizedContent);
    if (sigMatch != null) {
      hasSignature = true;
      matchedSignature = sigMatch.group(0);
    }
    // Also context check: if author exists, verify it matches signature patterns
    if (author != null && author.isNotEmpty) {
      final isAnon = author == '익명' || author == 'Anonymous' || author.toLowerCase() == 'anonymous';
      if (!isAnon && (sanitizedContent.contains('$author (인)') || 
                      sanitizedContent.contains('$author(인)') || 
                      sanitizedContent.contains('$author (서명)') ||
                      sanitizedContent.contains('$author(서명)') ||
                      sanitizedContent.contains('$author (Seal)') ||
                      sanitizedContent.contains('$author (Signature)'))) {
        hasSignature = true;
        matchedSignature = matchedSignature ?? '$author (인)';
      }
    }

    // 3. Validate Date
    bool hasDate = false;
    String? matchedDate;
    final koDateMatch = _koreanDateRegex.firstMatch(sanitizedContent);
    final dotDateMatch = _dotDateRegex.firstMatch(sanitizedContent);
    final enDateMatch = _englishDateRegex.firstMatch(sanitizedContent);
    final enDateAltMatch = _englishDateAltRegex.firstMatch(sanitizedContent);

    if (koDateMatch != null) {
      hasDate = true;
      matchedDate = koDateMatch.group(0);
    } else if (dotDateMatch != null) {
      hasDate = true;
      matchedDate = dotDateMatch.group(0);
    } else if (enDateMatch != null) {
      hasDate = true;
      matchedDate = enDateMatch.group(0);
    } else if (enDateAltMatch != null) {
      hasDate = true;
      matchedDate = enDateAltMatch.group(0);
    }

    // 4. Validate Physical Address
    bool hasAddress = false;
    String? matchedAddress;
    final addrLabelMatch = _addressLabelRegex.firstMatch(sanitizedContent);
    final koAddrMatch = _koreanAddressRegex.firstMatch(sanitizedContent);
    final enAddrMatch = _englishAddressRegex.firstMatch(sanitizedContent);

    if (addrLabelMatch != null) {
      hasAddress = true;
      matchedAddress = addrLabelMatch.group(0);
    } else if (koAddrMatch != null) {
      hasAddress = true;
      matchedAddress = koAddrMatch.group(0);
    } else if (enAddrMatch != null) {
      hasAddress = true;
      matchedAddress = enAddrMatch.group(0);
    }

    return LegalValidationResult(
      hasName: hasName,
      hasSignature: hasSignature,
      hasDate: hasDate,
      hasAddress: hasAddress,
      matchedName: matchedName,
      matchedSignature: matchedSignature,
      matchedDate: matchedDate,
      matchedAddress: matchedAddress,
    );
  }
}
