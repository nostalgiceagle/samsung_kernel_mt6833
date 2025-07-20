#!/bin/bash
# equinoX Kernel Build Script (Enhanced)

# ==== COLORS ====
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
RESET="\e[0m"

# ==== CONFIG ====
TOOLCHAIN_URL="https://github.com/nostalgiceagle/toolchains"
DEFCONFIG="a13ve_defconfig"
OUTDIR="$(pwd)/out"
EQUINOX_DIR="$(pwd)/equinoX"
KERNEL_IMAGE="$OUTDIR/arch/arm64/boot/Image"
BUILD_NUMBER_FILE=".build_no"

# ==== ENV EXPORTS ====
export ARCH=arm64
export CROSS_COMPILE="$(pwd)/toolchain/toolchains-gcc-10.3.0/bin/aarch64-buildroot-linux-gnu-"
export CC="$(pwd)/toolchain/clang/host/linux-x86/clang-r383902/bin/clang"
export CLANG_TRIPLE=aarch64-linux-gnu-
export KBUILD_BUILD_HOST="$(hostname)"
export KBUILD_BUILD_USER="$(whoami)"

# ==== FUNCTIONS ====
COLOR_ECHO() { echo -e "${1}${2}${RESET}"; }

SET_TIMEZONE() {
    CURRENT_TZ=$(timedatectl | grep "Time zone" | awk '{print $3}')
    COLOR_ECHO $CYAN "==> Current timezone: $CURRENT_TZ"
    read -p "Do you want to change timezone? [y/N]: " change_tz
    if [[ "$change_tz" =~ ^[Yy]$ ]]; then
        read -p "Enter new timezone (e.g., Asia/Kolkata): " new_tz
        sudo timedatectl set-timezone "$new_tz" && CURRENT_TZ="$new_tz"
        COLOR_ECHO $GREEN "   -> Timezone set to $CURRENT_TZ"
    fi
    export TZ="$CURRENT_TZ"
}

CHECK_PACKAGES() {
    REQ_PKGS=("git" "zip" "curl" "bc" "bison" "cpio" "flex" "zstd" "make" "gcc" "g++" "clang" "timedatectl")
    MISSING_PKGS=()

    COLOR_ECHO $CYAN "==> Checking required packages..."
    for pkg in "${REQ_PKGS[@]}"; do
        if ! command -v $pkg &>/dev/null; then
            MISSING_PKGS+=("$pkg")
        fi
    done

    if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
        COLOR_ECHO $YELLOW "   -> Missing packages: ${MISSING_PKGS[*]}"
        read -p "   -> Install them now? [y/N]: " install_pkgs
        if [[ "$install_pkgs" =~ ^[Yy]$ ]]; then
            sudo apt update && sudo apt install -y ${MISSING_PKGS[*]} || exit 1
        else
            COLOR_ECHO $RED "   !! Warning: Missing packages may cause build failure."
        fi
    else
        COLOR_ECHO $GREEN "   -> All required packages are installed."
    fi
}

ASK_CORES() {
    read -p "Enter number of CPU cores for make (default: $(nproc)): " user_jobs
    JOBS=${user_jobs:-$(nproc)}
    COLOR_ECHO $BLUE "   -> Using $JOBS cores for make."
}

ASK_CLEAN_BUILD() {
    read -p "Do you want a clean build? [y/N]: " clean
    if [[ "$clean" =~ ^[Yy]$ ]]; then
        COLOR_ECHO $YELLOW "   -> Performing make clean with $JOBS cores..."
        rm -rf "$OUTDIR"
    else
        COLOR_ECHO $YELLOW "   -> Dirty build..."
    fi
}

CHECK_TOOLCHAINS() {
    COLOR_ECHO $CYAN "==> Checking toolchain..."
    if [ ! -d "$(pwd)/toolchain" ]; then
        COLOR_ECHO $YELLOW "   -> Toolchain folder not found! Cloning..."
        git clone "$TOOLCHAIN_URL" "$(pwd)/toolchain" || exit 1
    else
        COLOR_ECHO $GREEN "   -> Toolchain already present."
    fi
}

UPDATE_BUILD_NUMBER() {
    if [ ! -f "$BUILD_NUMBER_FILE" ]; then
        echo "0" > "$BUILD_NUMBER_FILE"
    fi
    BUILD_NUMBER=$(($(cat "$BUILD_NUMBER_FILE") + 1))
    echo "$BUILD_NUMBER" > "$BUILD_NUMBER_FILE"
    COLOR_ECHO $MAGENTA "==> Build number: $BUILD_NUMBER"
}

BUILD_KERNEL() {
    BUILD_START=$(date +%s)
    COLOR_ECHO $BLUE "==> Building kernel (Build No. $BUILD_NUMBER)..."
    mkdir -p "$OUTDIR"
    mkdir -p "$EQUINOX_DIR"

    make -C "$(pwd)" O="$OUTDIR" $DEFCONFIG KCFLAGS=-w || exit 1
    make -C "$(pwd)" O="$OUTDIR" KCFLAGS=-w -j"$JOBS" || exit 1

    if [ -f "$KERNEL_IMAGE" ]; then
        cp "$KERNEL_IMAGE" "$EQUINOX_DIR/Image"
        COLOR_ECHO $GREEN "==> Kernel build finished. Image copied to $EQUINOX_DIR/Image"
    else
        COLOR_ECHO $RED "!! ERROR: Kernel image not found!"
        exit 1
    fi

    BUILD_END=$(date +%s)
    BUILD_TIME=$((BUILD_END - BUILD_START))
    COLOR_ECHO $MAGENTA "==> Build completed in $((BUILD_TIME / 60)) min $((BUILD_TIME % 60)) sec."
}

PACKAGE_ZIP() {
    DEVICE_NAME=$(echo "$DEFCONFIG" | cut -d'_' -f1)
    ZIP_NAME="equinoX-${DEVICE_NAME}-BUILD-${BUILD_NUMBER}.zip"

    COLOR_ECHO $BLUE "==> Preparing AnyKernel flashable zip..."

    # Nuke old files
    rm -f "$EQUINOX_DIR/Image" "$EQUINOX_DIR/Image.gz" "$EQUINOX_DIR/dtbo.img"

    # Copy Image and dtbo if exists
    cp "$KERNEL_IMAGE" "$EQUINOX_DIR/Image" || exit 1
    if [ -f "$OUTDIR/arch/arm64/boot/dtbo.img" ]; then
        cp "$OUTDIR/arch/arm64/boot/dtbo.img" "$EQUINOX_DIR/dtbo.img"
        COLOR_ECHO $MAGENTA "   -> dtbo.img added to AnyKernel zip."
    fi

    cd "$EQUINOX_DIR" || exit 1
    zip -r9 "$ZIP_NAME" * > /dev/null
    COLOR_ECHO $GREEN "==> Flashable kernel packaged as $EQUINOX_DIR/$ZIP_NAME"
    cd - > /dev/null
}

UPLOAD_FILE() {
    DEVICE_NAME=A137x
    ZIP_NAME="equinoX-${DEVICE_NAME}-BUILD-${BUILD_NUMBER}.zip"

    read -p "Do you want to upload the build? [y/N]: " do_upload
    if [[ ! "$do_upload" =~ ^[Yy]$ ]]; then
        COLOR_ECHO $YELLOW "==> Skipping upload."
        return
    fi

    echo "Select upload method:"
    echo "1) bashupload.com (Temporary)"
    echo "2) Telegram (Requires bot setup)"
    read -p "Enter option [1/2]: " upload_choice

    if [[ "$upload_choice" == "1" ]]; then
        COLOR_ECHO $BLUE "==> Uploading to bashupload.com..."
        curl -T "$EQUINOX_DIR/$ZIP_NAME" bashupload.com
        COLOR_ECHO $GREEN "==> Upload complete."
    elif [[ "$upload_choice" == "2" ]]; then
        if [ ! -f .tg_bot_http ] || [ ! -f .tg_chat ]; then
            COLOR_ECHO $YELLOW "Telegram variables not found!"
            read -p "Enter Telegram Bot HTTP URL: " tg_bot
            echo "$tg_bot" > .tg_bot_http
            read -p "Enter Telegram Chat ID: " tg_chat
            echo "$tg_chat" > .tg_chat
        fi
        TG_BOT=$(cat .tg_bot_http)
        TG_CHAT=$(cat .tg_chat)

        COLOR_ECHO $BLUE "==> Uploading to Telegram..."
        curl -F document=@"$EQUINOX_DIR/$ZIP_NAME" \
             -F caption="Build No: $BUILD_NUMBER
Build time: $((BUILD_TIME / 60))m $((BUILD_TIME % 60))s
Timezone: $TZ
Build user: $KBUILD_BUILD_USER" \
             "$TG_BOT/sendDocument?chat_id=$TG_CHAT" \
             && COLOR_ECHO $GREEN "==> Upload complete." \
             || COLOR_ECHO $RED "!! Upload failed!"
    else
        COLOR_ECHO $RED "!! Invalid choice. Skipping upload."
    fi
}

# ==== EXECUTION ====
SET_TIMEZONE
CHECK_PACKAGES
ASK_CORES
CHECK_TOOLCHAINS
ASK_CLEAN_BUILD
UPDATE_BUILD_NUMBER
BUILD_KERNEL
PACKAGE_ZIP
UPLOAD_FILE