#!/bin/bash
set -e

# ============================================================
# Whisky Intel Edition — Complete Build Script
# Builds a self-contained .app with bundled Wine for Intel Mac
# Uses swiftc directly — NO Xcode or SwiftPM needed!
# Only requires: Command Line Tools + Homebrew
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/.build-intel"
APP_DIR="$BUILD_DIR/Whisky.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX13.3.sdk"
TARGET="x86_64-apple-macosx13.0"
SWIFTC_FLAGS="-O -sdk $SDK -target $TARGET -suppress-warnings"

# Wine version to bundle (Gcenx Intel builds)
WINE_VERSION="11.10"
WINE_URL="https://github.com/Gcenx/macOS_Wine_builds/releases/download/${WINE_VERSION}/wine-devel-${WINE_VERSION}-osx64.tar.xz"

echo "============================================"
echo "  Whisky Intel Edition — Build System"
echo "  Target: macOS 13.x+ (Intel x86_64)"
echo "  Compiler: swiftc (direct, no SPM)"
echo "============================================"
echo ""

# ----------------------------------------------------------
# Step 0: Verify toolchain
# ----------------------------------------------------------
echo "[Step 0] Checking toolchain..."
if ! command -v swiftc &>/dev/null; then
    echo "  ✗ swiftc not found. Install Command Line Tools: xcode-select --install"
    exit 1
fi
echo "  ✓ $(swiftc --version | head -1)"

if [ ! -d "$SDK" ]; then
    echo "  ✗ SDK not found at $SDK"
    # Try to find any available SDK
    SDK=$(ls -d /Library/Developer/CommandLineTools/SDKs/MacOSX*.sdk 2>/dev/null | grep -v '\.sdk$' | tail -1)
    if [ -z "$SDK" ]; then
        SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
    fi
    echo "  → Using SDK: $SDK"
    SWIFTC_FLAGS="-O -sdk $SDK -target $TARGET -suppress-warnings"
fi
echo "  ✓ SDK: $SDK"

# ----------------------------------------------------------
# Step 1: Install dependencies
# ----------------------------------------------------------
echo ""
echo "[Step 1] Checking dependencies..."

# Ensure Homebrew is in PATH
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

if ! command -v brew &>/dev/null; then
    echo "  ✗ Homebrew not found. Please install: https://brew.sh"
    exit 1
fi

if ! command -v cabextract &>/dev/null; then
    echo "  → Installing cabextract..."
    HOMEBREW_NO_AUTO_UPDATE=1 brew install cabextract 2>&1 | tail -3 || echo "  ⚠ cabextract install failed (winetricks may not work, but app will build)"
fi
if command -v cabextract &>/dev/null; then
    echo "  ✓ cabextract: $(which cabextract)"
else
    echo "  ⚠ cabextract not available — winetricks may have limited functionality"
fi

# ----------------------------------------------------------
# Step 2: Fetch SemanticVersion dependency
# ----------------------------------------------------------
echo ""
echo "[Step 2] Fetching SemanticVersion dependency..."
DEPS_DIR="$BUILD_DIR/deps"
SV_DIR="$DEPS_DIR/SemanticVersion"

if [ ! -d "$SV_DIR" ]; then
    mkdir -p "$DEPS_DIR"
    echo "  → Cloning SemanticVersion..."
    git clone --depth 1 https://github.com/SwiftPackageIndex/SemanticVersion.git "$SV_DIR" 2>&1 | tail -2
    echo "  ✓ SemanticVersion cloned"
else
    echo "  ✓ SemanticVersion cached"
fi

# Find SemanticVersion source files
SV_SOURCES=$(find "$SV_DIR/Sources" -name "*.swift" 2>/dev/null)
if [ -z "$SV_SOURCES" ]; then
    echo "  ✗ SemanticVersion sources not found"
    exit 1
fi
echo "  ✓ Found $(echo "$SV_SOURCES" | wc -l | tr -d ' ') SemanticVersion source files"

# ----------------------------------------------------------
# Step 3: Compile WhiskyKit + SemanticVersion
# ----------------------------------------------------------
echo ""
echo "[Step 3] Compiling WhiskyKit..."
MODULES_DIR="$BUILD_DIR/modules"
OBJECTS_DIR="$BUILD_DIR/objects"
mkdir -p "$MODULES_DIR" "$OBJECTS_DIR"

# 3a: Compile SemanticVersion into a module
echo "  → Compiling SemanticVersion module..."
SV_SRC_FILES=$(find "$SV_DIR/Sources" -name "*.swift" | tr '\n' ' ')
swiftc $SWIFTC_FLAGS \
    -module-name SemanticVersion \
    -emit-module -emit-module-path "$MODULES_DIR/SemanticVersion.swiftmodule" \
    -emit-library -o "$OBJECTS_DIR/libSemanticVersion.dylib" \
    $SV_SRC_FILES 2>&1
echo "  ✓ SemanticVersion module compiled"

# 3b: Compile WhiskyKit
echo "  → Compiling WhiskyKit module..."
WHISKYKIT_SOURCES=$(find "$SCRIPT_DIR/WhiskyKit/Sources/WhiskyKit" -name "*.swift" | tr '\n' ' ')
swiftc $SWIFTC_FLAGS \
    -module-name WhiskyKit \
    -I "$MODULES_DIR" -L "$OBJECTS_DIR" -lSemanticVersion \
    -emit-module -emit-module-path "$MODULES_DIR/WhiskyKit.swiftmodule" \
    -emit-library -o "$OBJECTS_DIR/libWhiskyKit.dylib" \
    $WHISKYKIT_SOURCES 2>&1
echo "  ✓ WhiskyKit module compiled"

# ----------------------------------------------------------
# Step 4: Compile Whisky app
# ----------------------------------------------------------
echo ""
echo "[Step 4] Compiling Whisky app..."

# Gather all Whisky app Swift sources (excluding deleted SparkleView)
# Quote each path in the response file so spaces in dir names work
WHISKY_FILELIST="$BUILD_DIR/whisky_filelist.txt"
find "$SCRIPT_DIR/Whisky" -name "*.swift" ! -name "SparkleView.swift" | \
    while IFS= read -r f; do echo "\"$f\""; done > "$WHISKY_FILELIST"

swiftc $SWIFTC_FLAGS \
    -module-name Whisky \
    -I "$MODULES_DIR" -L "$OBJECTS_DIR" -lSemanticVersion -lWhiskyKit \
    -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
    -o "$OBJECTS_DIR/Whisky" \
    @"$WHISKY_FILELIST" 2>&1

echo "  ✓ Whisky binary compiled"
echo "  ✓ $(file "$OBJECTS_DIR/Whisky" | cut -d: -f2)"

# ----------------------------------------------------------
# Step 5: Download Intel Wine
# ----------------------------------------------------------
echo ""
echo "[Step 5] Downloading Intel Wine ${WINE_VERSION}..."
WINE_CACHE="$BUILD_DIR/wine-cache"
WINE_TAR="$WINE_CACHE/wine-devel-${WINE_VERSION}-osx64.tar.xz"
WINE_EXTRACT="$WINE_CACHE/wine-extracted"

mkdir -p "$WINE_CACHE"

if [ ! -f "$WINE_TAR" ]; then
    echo "  → Downloading from GitHub (Gcenx builds)..."
    curl -L --progress-bar -o "$WINE_TAR" "$WINE_URL"
    echo "  ✓ Downloaded $(du -h "$WINE_TAR" | cut -f1) Wine archive"
else
    echo "  ✓ Using cached Wine archive"
fi

if [ ! -d "$WINE_EXTRACT" ]; then
    echo "  → Extracting Wine..."
    mkdir -p "$WINE_EXTRACT"
    tar -xf "$WINE_TAR" -C "$WINE_EXTRACT" 2>&1
    echo "  ✓ Wine extracted"
else
    echo "  ✓ Wine already extracted"
fi

# Find the actual Wine directory inside the extracted archive
# Wine is packaged as "Wine Devel.app/Contents/Resources/wine/"
WINE_DIR=$(find "$WINE_EXTRACT" -path "*/Contents/Resources/wine" -type d | head -1)
if [ -z "$WINE_DIR" ]; then
    echo "  ✗ Could not find Wine directory in extracted archive"
    ls -la "$WINE_EXTRACT"
    exit 1
fi
echo "  ✓ Wine root: $WINE_DIR"

# ----------------------------------------------------------
# Step 6: Assemble .app bundle
# ----------------------------------------------------------
echo ""
echo "[Step 6] Assembling Whisky.app bundle..."

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$CONTENTS_DIR/Frameworks"

# Copy binary
cp "$OBJECTS_DIR/Whisky" "$MACOS_DIR/Whisky"

# Copy dylibs into Frameworks
cp "$OBJECTS_DIR/libSemanticVersion.dylib" "$CONTENTS_DIR/Frameworks/"
cp "$OBJECTS_DIR/libWhiskyKit.dylib" "$CONTENTS_DIR/Frameworks/"

# Fix dylib rpaths
install_name_tool -change "$OBJECTS_DIR/libSemanticVersion.dylib" \
    "@rpath/libSemanticVersion.dylib" "$MACOS_DIR/Whisky" 2>/dev/null || true
install_name_tool -change "$OBJECTS_DIR/libWhiskyKit.dylib" \
    "@rpath/libWhiskyKit.dylib" "$MACOS_DIR/Whisky" 2>/dev/null || true
install_name_tool -change "$OBJECTS_DIR/libSemanticVersion.dylib" \
    "@rpath/libSemanticVersion.dylib" "$CONTENTS_DIR/Frameworks/libWhiskyKit.dylib" 2>/dev/null || true

# Bundle Wine
WINE_BUNDLE_DIR="$RESOURCES_DIR/Wine"
mkdir -p "$WINE_BUNDLE_DIR"
cp -R "$WINE_DIR"/* "$WINE_BUNDLE_DIR/"
echo "  ✓ Wine bundled ($(du -sh "$WINE_BUNDLE_DIR" | cut -f1))"

# Bundle localization strings
EN_LPROJ="$RESOURCES_DIR/en.lproj"
mkdir -p "$EN_LPROJ"
if [ -f "$SCRIPT_DIR/Whisky/Resources/en.lproj/Localizable.strings" ]; then
    cp "$SCRIPT_DIR/Whisky/Resources/en.lproj/Localizable.strings" "$EN_LPROJ/"
    echo "  ✓ Localization strings bundled"
else
    echo "  ⚠ Localizable.strings not found"
fi

# Copy winetricks and cabextract
if command -v winetricks &>/dev/null; then
    cp "$(which winetricks)" "$WINE_BUNDLE_DIR/winetricks" 2>/dev/null || true
fi
if command -v cabextract &>/dev/null; then
    cp "$(which cabextract)" "$WINE_BUNDLE_DIR/cabextract" 2>/dev/null || true
fi

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << 'INFOPLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>Whisky</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>com.whisky.intel</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Whisky</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>2.4.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>CFBundleDocumentTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeName</key>
			<string>Microsoft Executable</string>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>LSItemContentTypes</key>
			<array>
				<string>com.microsoft.windows-executable</string>
			</array>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>Microsoft MSI Installer</string>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>LSItemContentTypes</key>
			<array>
				<string>com.microsoft.msi-installer</string>
			</array>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>Microsoft Batch File</string>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>LSHandlerRank</key>
			<string>Owner</string>
			<key>LSItemContentTypes</key>
			<array>
				<string>com.microsoft.bat</string>
			</array>
		</dict>
	</array>
	<key>UTExportedTypeDeclarations</key>
	<array>
		<dict>
			<key>UTTypeConformsTo</key>
			<array>
				<string>public.data</string>
			</array>
			<key>UTTypeDescription</key>
			<string>Microsoft MSI Installer</string>
			<key>UTTypeIdentifier</key>
			<string>com.microsoft.msi-installer</string>
			<key>UTTypeTagSpecification</key>
			<dict>
				<key>public.filename-extension</key>
				<array>
					<string>msi</string>
				</array>
			</dict>
		</dict>
		<dict>
			<key>UTTypeConformsTo</key>
			<array>
				<string>public.data</string>
			</array>
			<key>UTTypeDescription</key>
			<string>Microsoft Batch File</string>
			<key>UTTypeIdentifier</key>
			<string>com.microsoft.bat</string>
			<key>UTTypeTagSpecification</key>
			<dict>
				<key>public.filename-extension</key>
				<array>
					<string>bat</string>
				</array>
			</dict>
		</dict>
	</array>
</dict>
</plist>
INFOPLIST
echo "  ✓ Info.plist created"

# Create entitlements
cat > "$BUILD_DIR/entitlements.plist" << 'ENTITLEMENTS'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.automation.apple-events</key>
	<true/>
	<key>com.apple.security.cs.allow-unsigned-executable-memory</key>
	<true/>
	<key>com.apple.security.cs.disable-library-validation</key>
	<true/>
	<key>com.apple.security.device.audio-input</key>
	<true/>
	<key>com.apple.security.device.camera</key>
	<true/>
</dict>
</plist>
ENTITLEMENTS

# Ad-hoc code sign
echo "  → Code signing..."
codesign --force --deep -s - --entitlements "$BUILD_DIR/entitlements.plist" "$APP_DIR" 2>&1
echo "  ✓ Code signed (ad-hoc)"

# ----------------------------------------------------------
# Done!
# ----------------------------------------------------------
echo ""
echo "============================================"
echo "  ✓ BUILD COMPLETE!"
echo "============================================"
echo ""
echo "  App:  $APP_DIR"
echo "  Size: $(du -sh "$APP_DIR" | cut -f1)"
echo ""
echo "  To run:"
echo "    open \"$APP_DIR\""
echo ""
echo "  To install:"
echo "    cp -R \"$APP_DIR\" /Applications/"
echo ""
echo "============================================"
