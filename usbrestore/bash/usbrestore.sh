#!/bin/bash

#---
#Заводская флешка (FAT32)
#Реанимация флешек перед установкой загрузчика MgaRemix
#---

clear
#Проверка привилегий root
if [ "$EUID" -ne "0" ]; then read -p "Root privileges are required! Enter - Exit..."; exit; fi

#Сбрасываем атрибуты и определяем стиль шрифта
tput sgr0; color='\e[1m'; ncolor='\e[0m'

echo -e "${color}Removable devices:${ncolor}\n---"
#Получение блочных устройств
dev=$(lsblk -ld | cut -f1 -d" " | tail -n +2)

for i in $dev; do
if [[ $(cat /sys/block/$i/removable) -eq 1 ]]; then
echo "/dev/$(lsblk -ld | grep $i | awk '{print $1,$4}')"
fi;
done

#Выбор устройства и демонтаж
echo; read -r -p "Enter the usb drive device (example - /dev/sdc): " usb
[[ -z $usb ]] && exit || read -p "All data on $usb will be destroyed! [Enter-Continue] [Ctrl+C-Cancel]"

umount -l $usb ${usb}1 ${usb}2 ${usb}3 ${usb}4 2>/dev/null
#Заполняем нулями и синхронизируем кеш
echo -e "${color}Clearing the partition table...${ncolor}" && \
dd if=/dev/zero of=$usb count=512 && sync && \
#Создаём раздел ${usb}1 (0B - W95 FAT32) (0C - W95 FAT32 LBA)
#Принудительно устанавливаем тип раздела MBR (если GPT)
#parted $usb mklabel msdos --script && \
echo -e "${color}Creating a dos partition label...${ncolor}" && \
echo 'label: dos' | sfdisk $usb && \
echo -e "${color}Creating a FAT32 partition...${ncolor}" && \
echo 'start=2048, type=0C, bootable' | sfdisk $usb && \
#Форматируем и проверяем раздел ${usb}1
echo -e "${color}Formatting the partition ${usb}1 in FAT32...${ncolor}" && \
mkfs.fat -v -F32 -n "USBDRIVE" ${usb}1 && \
echo -e "${color}Checking the partition ${usb}1...${ncolor}" && \
fsck.fat -a -w -v ${usb}1 && sync && \
echo -e "\nOk, the operation was completed successfully..."
