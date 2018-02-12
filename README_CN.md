# TFmini-macOS
用USB转串口连接TFmini和macOS. 基于Xcode 9, Swift 4, ORSSerialPort开发. 

---
## 安装USB转串口驱动  
常用的USB转串口芯片有 [CH341](http://www.wch.cn/download/CH341SER_MAC_ZIP.html), [CP210X](https://www.silabs.com/products/development-tools/software/usb-to-uart-bridge-vcp-drivers), [PL2303](http://www.prolific.com.tw/US/ShowProduct.aspx?p_id=229&pcid=41), [FT232](http://www.ftdichip.com/Drivers/VCP.htm)等, 点击相应的名称下载macOS驱动并安装. 我这里使用的是CP2104. 安装完成后连接TFmini到macOS: 
![TFmini-macOS](/Assets/TFmini-macOS.jpg) 

--- 
## 新建Xcode9/Swift4工程  
新建Cocoa App工程, 命名为TFmini, 不勾选Storyboard.  

关闭工程, 打开macOS终端, 切换到TFmini Xcode工程目录, 创建Podfile, 然后用文本编辑打开:  
```
touch Podfile
open -a TextEdit Podfile
```

填入以下代码: 
```
target "TFmini"
pod "ORSSerialPort"
```
其中target后面是工程名, 保存关闭.  

使用Cocoapods导入: 
```
pod install
```

完成后关闭终端, 打开工程目录下的 .xcworkspace 文件.  点击顶部的黄色小叹号, 更新到推荐的设置.  

手动添加OC到Swift的桥接文件: TFmini-Bridging-Header.h, 其中SerialGUI是工程名, 内容为: 
```
#import "ORSSerialPort.h"
#import "ORSSerialPortManager.h"
```

依次点击 工程名 -> Targets下的工程名 -> Build Setting -> Swift Compiler -General -> Objective-C Bridging Header, 双击右侧空白处, 填入以下代码后回车: 
```
$(PROJECT_DIR)/$(PROJECT_NAME)/$(PROJECT_NAME)-Bridging-Header.h
```
如图所示:  
![BuildSetting](/Assets/BuildSetting.jpg) 

新建一个TFmini类, 继承于NSObject.  

然后在XIB文件中加入一个 Object, 在Identity Inspector中的Class, 选择刚刚创建的SerialGUI类, 这样, 就可以关联对象到TFmini类中了: 
![AddObject](/Assets/AddObject.jpg) 

拖Label, Pop Up Button, Push Button, TextView各种控件到Window的View中, 给控件添加一些约束, 并设置Window的最小尺寸为480*360: 
![Window](/Assets/Window.jpg)  

关联Open按钮和TextView接收框到TFmini中, 关联Open按钮的点击事件, 注意 NSTextView, 需要连点3下才能选中, 别拖成ScrollView或者ClipView了: 
```
    @IBOutlet weak var openCloseButton: NSButton!
    @IBOutlet var receivedDataTextView: NSTextView!
    
    @IBAction func openOrClosePort(_ sender: Any) {
    }
```
把其余的代码添加进来, 主要是 ORSSerialPortDelegate, NSUserNotificationCenterDelegate的一些实现.  
变量前的 @objc dynamic 是后面的Binding必须的.  
TFmini的数据解析在 func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) 中, 数据接收超过10000帧, 会清空缓存.  
参考工程源文件. 

接下来就是Binding了.  

串口弹出按钮的Binding:  
![](/Assets/serialBinding.jpg) 

波特率弹出按钮的Binding: 
![](/Assets/baudrateBinding.jpg)  

打开关闭按钮的Binding, 保证没有串口时不可被选中: 
![](/Assets/openBinding.jpg)  

设置完毕, 运行, 串口号选择SLAB_USBtoUART, 波特率选择115200, open报错:  
```
SerialPort SLAB_USBtoUART encountered an error: Error Domain=NSPOSIXErrorDomain Code=1 "Operation not permitted" UserInfo={NSFilePath=/dev/cu.SLAB_USBtoUART, NSLocalizedDescription=Operation not permitted}
``` 

修改 工程名.entitlements, 增加 com.apple.security.device.serial, 设为YES, 如果想要应用上传到AppStore, 这个是必须的:  
![](/Assets/entitlement.jpg)

确保Team有效: 
![](/Assets/team.jpg)

依次点击工程名 -> Targets下的工程名 -> Capbilities -> Keychain Sharing -> 打开开关.  

再次运行, 就可以了:  
![](/Assets/TFminiGUI.jpg) 
左边是原始的9字节十六进制数, 右边是计算出来的实际距离值, 单位cm. 