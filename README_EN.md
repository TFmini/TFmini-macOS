# TFmini-macOS

Connect TFmini to macOS via USB-serial adaptor. Xcode 9, Swift 4 and ORSSerialPort are used for development.

---
## Install USB-Serial Adaptor Driver  

There are several kinds of commonly used USB-serial adaptors: [CH341](http://www.wch.cn/download/CH341SER_MAC_ZIP.html), [CP210X](https://www.silabs.com/products/development-tools/software/usb-to-uart-bridge-vcp-drivers), [PL2303](http://www.prolific.com.tw/US/ShowProduct.aspx?p_id=229&pcid=41), [FT232](http://www.ftdichip.com/Drivers/VCP.htm). Uers can download drivers for macOS in these links. We use the driver of CP2104 as example. Connect TFmini to macOS after the installation is finished: 
![TFmini-macOS](/Assets/TFmini-macOS.jpg) 

--- 
## Create New Xcode9/Swift4 Project
  
Create new Cocoa App project and named to TFmini. DO NOT check option Storyboard.  

Close the project and open a macOS console. Create Podfile to the directory of TFmini Xcode project and open it with text editor:
```
touch Podfile
open -a TextEdit Podfile
```

Add following code: 
```
target "TFmini"
pod "ORSSerialPort"
```
The string after target is the name of project. Save the content and close.  

Use Cocoapods to import:
```
pod install
```

Close the console after finished. Open the .xcworkspace file which is under the directory of the project. Click the little yellow exclamation mark on the top and update the recommended configuration.

Manually add OC to Swift bridging header: TFmini-Bridging-Header.h, within which the TFmini is the name of project. The content is:
```
#import "ORSSerialPort.h"
#import "ORSSerialPortManager.h"
```

Select {project name} -> {project name under Targets} -> Build Setting -> Swift Compiler - General -> Objective-C Bridging Header, double click blank space at the right, fill with following code and press ENTER: 
```
$(PROJECT_DIR)/$(PROJECT_NAME)/$(PROJECT_NAME)-Bridging-Header.h
```
Shown as figure:  
![BuildSetting](/Assets/BuildSetting.jpg) 

Create a new TFmini class, inherited from NSObject.

Add an Object to XIB file, select the created TFmini class at the Class Tab of Identity Inspector, thus we associate the object to TFmini class:
![AddObject](/Assets/AddObject.jpg) 

Add Label, Pop Up Button, Push Button, TextView and other controls to the View of Window and add some constraint. Set Window minimum size to, for example, 480*360:
![Window](/Assets/Window.jpg)  

Associate the Open Button and TextView to TFmini and associate Open Button click event. Note that NSTextView needs to be click 3 times to select, carefully do not select ScrollView or ClipView:
```
    @IBOutlet weak var openCloseButton: NSButton!
    @IBOutlet var receivedDataTextView: NSTextView!
    
    @IBAction func openOrClosePort(_ sender: Any) {
    }
```
Add the rest of code, mainly is the realization of ORSSerialPortDelegate and NSUserNotificationCenterDelegate.

The @objc dynamic is necessary for later Binding.

The TFmini data decoding is processed by func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data). The buffer will be cleared if received more than 10000 frames.

Please reference to the project source files.

Next step is Binding. 

The Binding of serial port name tab:  
![](/Assets/serialBinding.jpg) 

The Binding of baud rate tab:
![](/Assets/baudrateBinding.jpg)  

The Binding of Open button, make sure it is not valid when no serial port is selected:
![](/Assets/openBinding.jpg)  

Configuration is done. Run the program and select serial port name SLAB_USBtoUART, set baud rate to 115200. There may appear error message when open:
```
SerialPort SLAB_USBtoUART encountered an error: Error Domain=NSPOSIXErrorDomain Code=1 "Operation not permitted" UserInfo={NSFilePath=/dev/cu.SLAB_USBtoUART, NSLocalizedDescription=Operation not permitted}
``` 

Modify the {project name}.entitlements file, add com.apple.security.device.serial and set value to YES. If want to upload the application to AppStore, this is necessary:
![](/Assets/entitlement.jpg)

Ensure Team is available:
![](/Assets/team.jpg)

Select {project name} -> {project name under Target} -> Capbilities, and then turn on Keychain Sharing.

Run again, and it should work: 
![](/Assets/TFminiGUI.jpg) 

The left is the received 9 bytes of hexadecimal numbers, and the right is the decoded real distance in centimeters.
