# USBRestore
**Restoring the factory settings of USB flash drives**

If earlier ISO installation images were recorded on the USB flash drive, for example, through Rufus programs (GPT/EFI/Windows), or the GRUB bootloader was installed, there may be problems with the USB flash drive in the future: all of the above is not deleted even after formatting. Therefore, the flash drive may not load in televisions, set-top boxes, etc. All these devices, like the MgaRemix bootloader, require the use of native/factory flash drive parameters: dos partition, FAT32 file system.

To bring the flash drive to normal, factory parameters, a USBRestore was created. He does a forced "resuscitation" and removes all unnecessary things from the flash drive by pressing one button, returning it to the "out of the store" state:

1. Clears the partition table
2. Marks the dos partition
3. Creates a FAT32 partition
4. Formats the partition labeled USBDRIVE
5. Checks the section for errors with correction

Be careful when choosing a device from the list! The program itself determines removable devices, but their variety is great, so pay attention to the capacity (G), i.e. Gigabytes, when working.

![](https://github.com/AKotov-dev/usbrestore/blob/main/ScreenShot1.png)
