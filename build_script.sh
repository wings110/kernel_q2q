#!/bin/bash

## DEVICE STUFF
DEVICE_HARDWARE="sm8350"
DEVICE_MODEL="$1"
ZIP_DIR="$(pwd)/AnyKernel3"
MOD_DIR="$ZIP_DIR/modules/vendor/lib/modules"
K_MOD_DIR="$(pwd)/out/modules"

# Enviorment Variables
SRC_DIR=$(pwd)
TC_DIR=$(pwd)/clang
JOBS="$(nproc --all)"
MAKE_PARAMS="-j$JOBS -C $SRC_DIR O=$SRC_DIR/out ARCH=arm64 CC=clang CLANG_TRIPLE=$TC_DIR/bin/aarch64-linux-gnu- LLVM=1 CROSS_COMPILE=$TC_DIR/bin/llvm-"
export PATH="$TC_DIR/bin:$PATH"

if [ "$DEVICE_MODEL" == "SM-F926N" ]; then
	DEVICE_NAME="q2q"
	DEFCONFIG=vendor/q2q_kor_singlex_defconfig
elif [ "$DEVICE_MODEL" == "SM-G9960" ]; then
	DEVICE_NAME="t2q"
	DEFCONFIG=vendor/t2q_chn_hkx_defconfig
else
	echo "Config not found"
	exit
fi

# Check if KSU flag is provided
if [[ "$*" == *"--ksu"* ]]; then
	KSU="true"
else
	KSU="false"
fi

# Check the value of KSU
if [ "$KSU" == "true" ]; then
	ZIP_NAME="Lavender_KSU_"$DEVICE_NAME"_"$DEVICE_MODEL"_"$(date +%d%m%y-%H%M)""
	if [ -d "KernelSU" ]; then
		echo "KernelSU exists"
	else
		echo "KernelSU not found !"
		echo "Fetching ...."
		curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s v0.9.5
	fi
elif [ "$KSU" == "false" ]; then
	echo "KSU disabled"
	ZIP_NAME="Lavender_"$DEVICE_NAME"_"$DEVICE_MODEL"_"$(date +%d%m%y-%H%M)""
	if [ -d "KernelSU" ]; then
		git reset HEAD --hard
	fi
fi

make $MAKE_PARAMS $DEFCONFIG
make $MAKE_PARAMS
make $MAKE_PARAMS INSTALL_MOD_PATH=modules INSTALL_MOD_STRIP=1 modules_install

if [ -d "AnyKernel3" ]; then
	cd AnyKernel3
	git reset HEAD --hard
	cd ..
	if [ -d "AnyKernel3/modules" ]; then
		rm -rf AnyKernel3/modules/
		mkdir AnyKernel3/modules/
		mkdir AnyKernel3/modules/vendor/
		mkdir AnyKernel3/modules/vendor/lib
		mkdir AnyKernel3/modules/vendor/lib/modules/
	else
		mkdir AnyKernel3/modules/
		mkdir AnyKernel3/modules/vendor/
		mkdir AnyKernel3/modules/vendor/lib
		mkdir AnyKernel3/modules/vendor/lib/modules/
	fi
	find "$(pwd)/out/modules" -type f -iname "*.ko" -exec cp -r {} ./AnyKernel3/modules/vendor/lib/modules/ \;
	cp ./out/arch/arm64/boot/Image ./AnyKernel3/
	cp ./out/arch/arm64/boot/dtbo.img ./AnyKernel3/
	cd AnyKernel3
	rm -rf Lavender*
	zip -r9 $ZIP_NAME . -x '*.git*' '*patch*' '*ramdisk*' 'LICENSE' 'README.md'
	cd ..
else
	git clone https://github.com/LucasBlackLu/AnyKernel3 -b samsung
	if [ -d "AnyKernel3/modules" ]; then
		rm -rf AnyKernel3/modules/
		mkdir AnyKernel3/modules/
		mkdir AnyKernel3/modules/vendor/
		mkdir AnyKernel3/modules/vendor/lib
		mkdir AnyKernel3/modules/vendor/lib/modules/
	else
		mkdir AnyKernel3/modules/
		mkdir AnyKernel3/modules/vendor/
		mkdir AnyKernel3/modules/vendor/lib
		mkdir AnyKernel3/modules/vendor/lib/modules/
	fi
	find "$(pwd)/out/modules" -type f -iname "*.ko" -exec cp -r {} ./AnyKernel3/modules/vendor/lib/modules/ \;
	cp ./out/arch/arm64/boot/Image ./AnyKernel3/
	cp ./out/arch/arm64/boot/dtbo.img ./AnyKernel3/
	cd AnyKernel3
	rm -rf Lavender*
	zip -r9 $ZIP_NAME . -x '*.git*' '*patch*' '*ramdisk*' 'LICENSE' 'README.md'
	cd ..
fi