#! /bin/bash
# https://www.jianshu.com/p/ca6823b897b5
# https://github.com/anlory/LedHidl

PACKAGE=android.hardware.naruto@1.0
LOC=hardware/interfaces/naruto/1.0/default/

hidl-gen -o $LOC -Lc++-impl -randroid.hardware:hardware/interfaces \
    -randroid.hidl:system/libhidl/transport $PACKAGE

hidl-gen -o $LOC -Landroidbp-impl -randroid.hardware:hardware/interfaces \
    -randroid.hidl:system/libhidl/transport $PACKAGE
