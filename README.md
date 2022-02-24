# TOC

# EinkBook-LuatOS

### 介绍
使用LuatOS-ESP32制作一个电纸书

#### 效果展示
<video src="./assets/EinkBook-LuatOS.mp4" controls="controls"></video>

### 硬件
+ ESP32-C3
+ MODEL_1in54 墨水屏

### 软件
+ LuatOS-ESP32
+ GoFrame

### 部署方法

#### 服务端
开启小说服务端程序
```bat
./run.bat
```

#### 电纸书
使用LuaTools将Scripts目录下所有文件烧录到ESP32-C3模块中

### 电纸书使用方法
使用BOOT键(GPIO 9)作为功能按键
+ 单击：下一个
+ 双击：上一个
+ 长按：进入/退出