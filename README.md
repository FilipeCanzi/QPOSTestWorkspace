To create the framework, the following steps were taken:
	•	A model framework was created using Xcode.
	•	The files were added to the framework.
	•	In the Build Settings section:
	    • In Import Paths, $(PROJECT_DIR)/QPOSTestFramework/QPOSFiles was added.
	    •	In Header Search Paths, $(PROJECT_DIR)/QPOSTestFramework/QPOSFiles was added.
	    •	In Other Linker Flags, -lqpos-ios-release-sdk-v3.6.7 was added.
	•	In the Build Phases section:
	    •	All headers were set to Public.
	•	In the application:
	    •	Changes were made to the ViewController file.
	    •	The key Privacy - Bluetooth Always Usage Description was added to Info.plist.
