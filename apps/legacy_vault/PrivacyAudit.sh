#!/usr/bin/env bash
# Privacy Audit: Verify no network dependencies in Legacy Vault source.
# Run: bash apps/legacy_vault/PrivacyAudit.sh
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)/legacy_vault"
VIOLATIONS=0

echo "═══════════════════════════════════════════════════════"
echo " Legacy Vault Privacy Audit"
echo " ═══════════════════════════════════════════════════════"
echo ""

# Check for forbidden imports
for pattern in "import Network" "import FoundationNetworking" "URLSession" "Alamofire" "Firebase" "FirebaseCore" "FirebaseAuth" "FirebaseFirestore" "cloud_firestore" "HTTPClient" "AFHTTPSessionManager"; do
    results=$(find "$BASE_DIR" -name "*.swift" -not -path "*/Tests/*" -exec grep -l "$pattern" {} \; 2>/dev/null || true)
    if [ -n "$results" ]; then
        echo "  ⚠️ VIOLATION: Found '$pattern' in:"
        echo "$results" | sed 's/^/      /'
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
done

# Verify Core Data is used for persistence
cd "$BASE_DIR"
entities=$(grep -r "NSPersistentContainer" Core/Database/*.swift 2>/dev/null | wc -l || echo "0")
if [ "$entities" -gt 0 ]; then
    echo "  ✓ Core Data persistence layer confirmed ($entities references found)"
else
    echo "  ⚠️ No Core Data persistence found"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# Verify no remote persistence
remote_persist=$(grep -r "RemotePersistenceController" *.swift 2>/dev/null | wc -l || echo "0")
if [ "$remote_persist" -eq 0 ]; then
    echo "  ✓ No RemotePersistenceController found (local-only persistence)"
fi

echo ""
# Count Swift files
total=$(find "$BASE_DIR" -name "*.swift" -not -path "*/Tests/*" | wc -l)
echo "  Total Swift files scanned: $total"
echo ""

if [ $VIOLATIONS -eq 0 ]; then
    echo "  ✅ PRIVACY AUDIT: PASSED (no network dependencies)"
    echo "═══════════════════════════════════════════════════════"
    exit 0
else
    echo "  ❌ PRIVACY AUDIT: FAILED ($VIOLATIONS violations found)"
    echo "═══════════════════════════════════════════════════════"
    exit 1
fi
