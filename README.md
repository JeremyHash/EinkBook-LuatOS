# EinkBook-LuatOS

### 介绍
使用LuatOS-ESP32制作一个电纸书

#### 效果展示
![](https://cdn.openluat-luatcommunity.openluat.com/images/20220313202435046_IMG_20220310_154336.jpg)

### 硬件
+ 合宙ESP32-C3开发板
+ MODEL_1in54 墨水屏

### 软件
+ LuatOS-ESP32
+ GoFrame

### 部署方法

#### 服务端
+ 将想要阅读的小说放到`Server\books`目录下（目前仅支持txt格式）
+ 开启小说服务端程序
```bat
cd Server
windows:
    ./run.bat
linux or macos:
    ./run.sh
```

#### 电纸书
使用LuaTools将Scripts目录下所有文件烧录到ESP32-C3模块中

### 电纸书使用方法
使用BOOT键(GPIO 9)作为功能按键
+ 单击：下一个
+ 双击：上一个
+ 长按：进入/退出