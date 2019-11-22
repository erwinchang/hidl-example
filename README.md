## HIDL Example

參考來源
- [Android HIDL学习（2） ---- HelloWorld][10]
- [anlory/LedHidl][11]


板端SabreSD i.mx6
bsp: imx-p9.0.0_2.2.0-ga
```
source build/envsetup.sh
lunch sabresd_6dq-userdebug
```


----------


* 1 建立server 及 clinet使用so 
* 2 產生service bin
* 3 環境修改
* 4 測試
* 5 test code

## 1 建立server 及 clinet使用so 

- 1-0
```
naruto/1.0$ tree
.
├── default
└── INaruto.hal.......新增
```

- 1-1 執行update-files.sh 產生檔案

```
android-imx-p$ cat update-files.sh 
#! /bin/bash

PACKAGE=android.hardware.naruto@1.0
LOC=hardware/interfaces/naruto/1.0/default/

hidl-gen -o $LOC -Lc++-impl -randroid.hardware:hardware/interfaces \
  -randroid.hidl:system/libhidl/transport $PACKAGE

hidl-gen -o $LOC -Landroidbp-impl -randroid.hardware:hardware/interfaces \
-randroid.hidl:system/libhidl/transport $PACKAGE
```

執行結果
```
interfaces/naruto/1.0$ tree
.
├── default
│   ├── Android.bp.......hidl-gen產生 ( -Landroidbp-impl )
│   ├── Naruto.cpp.......hidl-gen產生 (-Lc++-impl )
│   └── Naruto.h...........hidl-gen產生 (-Lc++-impl )
└── INaruto.hal
```

- 1-2 android-imx-p$ ./hardware/interfaces/update-makefiles.sh
```
interfaces/naruto$ tree
.
└── 1.0
├── Android.bp...........新增
├── default
│   ├── Android.bp
│   ├── Naruto.cpp
│   └── Naruto.h
└── INaruto.hal
```

- 1-3 修改Naruto.cpp,Naruto.h
android-imx-p$ mmm hardware/interfaces/naruto/1.0/default
```
20K 十一 22 11:09 ./vendor/lib/hw/android.hardware.naruto@1.0-impl.so..............新增 server so (vendor)
71K 十一 22 11:09 ./system/lib/android.hardware.naruto@1.0.so.............................新增 client so  (system)
```
  - android.hardware.naruto@1.0-impl.so: Naruto模块实现端的代码编译生成，binder server端
  - android.hardware.naruto@1.0.so: Naruto模块调用端的代码，binder client端
  - naruto_hal_service: 通过直通式注册binder service，暴露接口给client调用
  - android.hardware.naruto@1.0-service.rc: Android native 进程入口

![Imgur](https://i.imgur.com/47RXyis.png)

## 2  產生service bin

- service bin: /vendor/bin/hw/android.hardware.naruto@1.0-service
```
naruto/1.0$ tree
.
├── Android.bp
├── default
│   ├── Android.bp..............................................................修改
│   ├── android.hardware.naruto@1.0-service.rc.............增加
│   ├── Naruto.cpp
│   ├── Naruto.h
│   └── service.cpp.............................................................增加
└── INaruto.hal
```

- build 結果

```
android-imx-p$ mmm hardware/interfaces/naruto/1.0/default
./vendor/etc/init/android.hardware.naruto@1.0-service.rc
./vendor/bin/hw/android.hardware.naruto@1.0-service.......................新產生檔案
./vendor/lib/hw/android.hardware.naruto@1.0-impl.so
./system/lib/android.hardware.naruto@1.0.so

16K 十一 22 11:34 ./vendor/bin/hw/android.hardware.naruto@1.0-service
20K 十一 22 11:34 ./vendor/lib/hw/android.hardware.naruto@1.0-impl.so
71K 十一 22 11:34 ./system/lib/android.hardware.naruto@1.0.so
```

## 3 環境修改

### 3-1 device/fsl/imx6dq/sabresd_6dq/manifest.xml

The example below implements ```android.hardware.naruto@1.0::INaruto/default```
這邊type=device表示是安裝在vendor partition
若type=framework則是安裝在system partition
```
<manifest version="1.0" type="device"> 
<hal format="hidl"> 
<name>android.hardware.naruto</name> 
<transport>hwbinder</transport> 
<version>1.0</version> 
<interface> 
<name>INaruto</name> 
<instance>default</instance> 
</interface> 
</hal>
```
[Manifest file schema][2]

### 3-2 install package

device/fsl/imx6dq/sabresd_6dq/sabresd_6dq.mk
```
# NARUTO HAL 
PRODUCT_PACKAGES += \ 
android.hardware.naruto@1.0-impl \ 
android.hardware.naruto@1.0-service 
```

## 4 測試


- 4-1 確認檔案產生檔案是否在存

```
./vendor/etc/init/android.hardware.naruto@1.0-service.rc
./vendor/bin/hw/android.hardware.naruto@1.0-service
./vendor/lib/hw/android.hardware.naruto@1.0-impl.so
./system/lib/android.hardware.naruto@1.0.so

cat ./vendor/etc/init/android.hardware.naruto@1.0-service.rc
service naruto_hal_service /vendor/bin/hw/android.hardware.naruto@1.0-service
class hal
user system
group system
```

- 4-2 使用adb上傳檔案
```
adb shell mkdir /data/hidl
adb push vendor/bin/hw/naruto_test /data/hidl
```


- 4-3 naruto 沒有帶起來，需要手動帶起

```
1|sabresd_6dq:/data/hidl # ps -el | grep light 
4 S 1000 242 1 0 19 0 32 1719 binder_thread_read ? 00:00:00 light@2.0-servi
sabresd_6dq:/data/hidl # ps -el | grep naruto 
1|sabresd_6dq:/data/hidl #

export LD_LIBRARY_PATH=/vendor/lib/hw
/vendor/bin/hw/android.hardware.naruto@1.0-service

sabresd_6dq:/data/hidl # ./naruto_test 
Hello World, JayZhang
```



## 5 test code

```
hardware/interfaces/narutotest$ tree
.
├── Android.bp
└── client.cpp

cat Android.bp
cc_binary {
relative_install_path: "hw",
defaults: ["hidl_defaults"],
name: "naruto_test",
proprietary: true,
srcs: ["client.cpp"],

shared_libs: [
"liblog",
"libhardware",
"libhidlbase",
"libhidltransport",
"libutils",
"android.hardware.naruto@1.0",
],
}
```
參考[Android.bp][3]

build
```
android-imx-p$ mmm hardware/interfaces/narutotest
...
[100% 7/7] Install: out/target/product/sabresd_6dq/vendor/bin/hw/naruto_test
```


[1]:https://www.jianshu.com/p/ca6823b897b5
[2]:https://source.android.google.cn/devices/architecture/vintf/objects
[3]:https://github.com/anlory/LedHidl/blob/master/led_client/Android.bp


[10]:https://www.jianshu.com/p/ca6823b897b5
[11]:https://github.com/anlory/LedHidl
