#!/bin/bash
#                 _        _                   
#         _______| |____  / |_________         
#        / |  ____  __/|  |  ________/         
#       / /| |__ | | | |__| |__| |_| |         
#      / /_|  __|| |_|  __   __|    _/         
#     / ___| |___|   / |  | |__| |\ \          
#    /_/   |______\_/|_/  /_____\| \_\         
#
#      AetherAura Kernel Build Script 
#         Coded by CaelestisZ @2020
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
clear
# Init Fields
AE_VERSION=FleurCannon
AE_DATE=$(date +%Y%m%d)
AE_TOOLCHAIN=/home/caelestisz/AndroidBuilds/Toolchains/linaro-4.8/bin/arm-eabi-
AE_DIR=$(pwd)
# Init Methods
CLEAN_SOURCE()
{
	make clean
	make mrproper
	rm -r -f $AE_DIR/output
}
BUILD_ZIMAGE()
{
	echo "----------------------------------------------"
	echo "Building zImage for $AE_VARIANT..."
	echo " "
	export ARCH=arm
	export CROSS_COMPILE=$AE_TOOLCHAIN
	export LOCALVERSION=-AetherAura-$AE_VERSION-$AE_VARIANT-$AE_DATE
	mkdir output
	make -C $AE_DIR -j5 O=output aether_msm8916_defconfig VARIANT_DEFCONFIG=$AE_DEFCON SELINUX_DEFCONFIG=aether_selinux_defconfig
	make -C $AE_DIR -j5 O=output
	mkdir $AE_DIR/AETHER/build/system/lib/modules/pronto
	cp $AE_DIR/output/drivers/staging/prima/wlan.ko $AE_DIR/AETHER/build/system/lib/modules/pronto/pronto_wlan.ko
	cp $AE_DIR/output/arch/arm/oprofile/oprofile.ko $AE_DIR/AETHER/build/system/lib/modules/oprofile.ko
	cp $AE_DIR/output/crypto/ansi_cprng.ko $AE_DIR/AETHER/build/system/lib/modules/ansi_cprng.ko
	cp $AE_DIR/output/drivers/gator/gator.ko $AE_DIR/AETHER/build/system/lib/modules/gator.ko
	cp $AE_DIR/output/drivers/input/evbug.ko $AE_DIR/AETHER/build/system/lib/modules/evbug.ko
	cp $AE_DIR/output/drivers/mmc/card/mmc_test.ko $AE_DIR/AETHER/build/system/lib/modules/mmc_test.ko
	cp $AE_DIR/output/drivers/spi/spidev.ko $AE_DIR/AETHER/build/system/lib/modules/spidev.ko
	echo " "
}
BUILD_DTB()
{
	echo "----------------------------------------------"
	echo "Building dtb for $AE_VARIANT..."
	echo " "
	$AE_DIR/tools/dtbTool -o $AE_DIR/AETHER/dtb.img $AE_DIR/output/arch/arm/boot/dts/
	echo " "
}
PACK_IMG()
{
	echo "----------------------------------------------"
	echo "Packing boot.img for $AE_VARIANT..."
	echo " "
	mkdir -p $AE_DIR/AETHER/tools/aik/ramdisk
	mkdir -p $AE_DIR/AETHER/tools/aik/split_img
	cp -rf $AE_DIR/AETHER/ramdisk/common/ramdisk/* $AE_DIR/AETHER/tools/aik/ramdisk
	cp -rf $AE_DIR/AETHER/ramdisk/common/split_img/* $AE_DIR/AETHER/tools/aik/split_img
	mv $AE_DIR/output/arch/arm/boot/zImage $AE_DIR/AETHER/tools/aik/split_img/boot.img-zImage
	mv $AE_DIR/AETHER/dtb.img $AE_DIR/AETHER/tools/aik/split_img/boot.img-dtb
	$AE_DIR/AETHER/tools/aik/repackimg.sh
	mv $AE_DIR/AETHER/tools/aik/image-new.img $AE_DIR/AETHER/build/boot.img
	$AE_DIR/AETHER/tools/aik/cleanup.sh
	echo " "
}
PACK_ZIP()
{
	echo "----------------------------------------------"
	echo "Packing flashable zip for $AE_VARIANT..."
	echo " "
	cd AETHER/build
	zip -r AetherAura_$AE_VERSION-$AE_VARIANT-$AE_DATE.zip *
	rm -r boot.img
	rm -r system/lib/modules/*
	cd ..
	cd ..
	mv AETHER/build/AetherAura_$AE_VERSION-$AE_VARIANT-$AE_DATE.zip AETHER/final/AetherAura_$AE_VERSION-$AE_VARIANT-$AE_DATE.zip
	echo " "
	echo "Final builds at /final"
	echo "----------------------------------------------"
	echo " "
}
PACK_FORTUNA3G()
{
    echo "----------------------------------------------"
    echo "Starting build for fortuna3g variants."
    echo "----------------------------------------------"
    echo "Cleaning up source..."
    echo " "
    CLEAN_SOURCE
    echo " "
    echo "----------------------------------------------"
    echo "Starting fortuna3g kernel build..."
    AE_VARIANT=fortuna3g
    AE_DEFCON=aether_msm8916_fortuna3g_defconfig
    BUILD_ZIMAGE
    BUILD_DTB
    PACK_IMG
    PACK_ZIP    
}
PACK_FORTUNA3GDTV()
{
    echo "----------------------------------------------"
    echo "Starting build for fortuna3gdtv variants."
    echo "----------------------------------------------"
    echo "Cleaning up source..."
    echo " "
    CLEAN_SOURCE
    echo " "
    echo "----------------------------------------------"
    echo "Starting fortuna3gdtv kernel build..."
    AE_VARIANT=fortuna3gdtv
    AE_DEFCON=aether_msm8916_fortuna3gdtv_defconfig
    BUILD_ZIMAGE
    BUILD_DTB
    PACK_IMG
    PACK_ZIP
}
PACK_FORTUNAVE3G()
{
    echo "----------------------------------------------"
    echo "Starting build for fortunave3g variants."
    echo "----------------------------------------------"
    echo "Cleaning up source..."
    echo " "
    CLEAN_SOURCE
    echo " "
    echo "----------------------------------------------"
    echo "Starting fortunave3g kernel build..."
    AE_VARIANT=fortunave3g
    AE_DEFCON=aether_msm8916_fortunave3g_defconfig
    BUILD_ZIMAGE
    BUILD_DTB
    PACK_IMG
    PACK_ZIP
}
PACK_FORTUNALTEDX()
{
    echo "----------------------------------------------"
    echo "Starting build for fortunaltedx variants."
    echo "----------------------------------------------"
    echo "Cleaning up source..."
    echo " "
    CLEAN_SOURCE
    echo " "
    echo "----------------------------------------------"
    echo "Starting fortunaltedx kernel build..."
    AE_VARIANT=fortunaltedx
    AE_DEFCON=aether_msm8916_fortunaltedx_defconfig
    BUILD_ZIMAGE
    BUILD_DTB
    PACK_IMG
    PACK_ZIP
}
PACK_GPRIMELTEXX()
{
    echo "----------------------------------------------"
    echo "Starting build for gprimeltexx variants."
    echo "----------------------------------------------"
    echo "Cleaning up source..."
    echo " "
    CLEAN_SOURCE
    echo " "
    echo "----------------------------------------------"
    echo "Starting gprimeltexx kernel build..."
    AE_VARIANT=gprimeltexx
    AE_DEFCON=aether_msm8916_gprimeltexx_defconfig
    BUILD_ZIMAGE
    BUILD_DTB
    PACK_IMG
    PACK_ZIP
}
# Main Menu
clear
echo "                  _        _                  "
echo "          _______| |____  / |_________        "
echo "         / |  ____  __/|  |  ________/        "
echo "        / /| |__ | | | |__| |__| |_| |        "
echo "       / /_|  __|| |_|  __   __|    _/        "
echo "      / ___| |___|   / |  | |__| |\ \         "
echo "     /_/   |______\_/|_/  /_____\| \_\        "
echo "                                              "
echo "     AetherAura $AE_VERSION Build Script      "
echo "             Coded by CaelestisZ              "
echo "                                              "
PS3='Please select your option (1-7): '
menuvar=("fortuna3g" "fortuna3gdtv" "fortunave3g" "fortunaltedx" "gprimeltexx" "build all" "Exit")
select menuvar in "${menuvar[@]}"
do
    case $menuvar in
        "fortuna3g")
            clear
            PACK_FORTUNA3G
            read -n1 -r key
            break
            ;;
        "fortuna3gdtv")
            clear
            PACK_FORTUNA3GDTV
            read -n1 -r key
            break
            ;;
        "fortunave3g")
            clear
            PACK_FORTUNAVE3G
            read -n1 -r key
            break
            ;;
        "fortunaltedx")
            clear
            PACK_FORTUNALTEDX
            read -n1 -r key
            break
            ;;
        "gprimeltexx")
            clear
            PACK_GPRIMELTEXX
            read -n1 -r key
            break
            ;;
        "build all")
            clear
            echo "----------------------------------------------"
            echo "Starting build for all supported variants."
            PACK_FORTUNA3G
            clear
            PACK_FORTUNA3GDTV
            clear
            PACK_FORTUNALTEDX
            clear
            PACK_FORTUNAVE3G
            clear
            PACK_GPRIMELTEXX
            read -n1 -r key
            break
            ;;
        "Exit")
            break
            ;;
        *) echo Invalid option.;;
    esac
done

