#!/bin/bash

if [ "${USER}" != "root" ]; then
  echo "be root"
  exit 1
else 
  echo "you are root"
fi

echo "service"
cp usb_mount@.service /etc/systemd/system/usb_mount@.service
chmod a+rx /etc/systemd/system/usb_mount@.service

echo "script"
cp usb_mount.sh /usr/local/bin/usb_mount.sh
chmod a+rx /usr/local/bin/usb_mount.sh

echo "autostart"
mkdir ~/.config/autostart/ &> /dev/null
cat > ~/.config/autostart/ppt.desktop << "EOC"
[Desktop Entry]
Type=Application
Exec=/bin/bash /ppt/auto_ppt.sh
X-GNOME-Autostart-enabled=true
EOC
chmod a+r ~/.config/autostart/ppt.desktop

cat > /ppt/auto_ppt.sh << "EOAS"
#!/bin/bash

DESTDIR="/ppt"
TARGET_FILE="presentation.pptx"
DESTINATION="${DESTDIR}/${TARGET_FILE}"
LOG_FILE="${DESTDIR}/auto_ppt.log"
MOUNT_USER=user


logger "usb_ppt.sh triggered"

if [ -d "${DESTDIR}" ]; then
  echo "${DESTDIR} exists"
else 
  echo "mkdir ${DESTDIR}"
  mkdir -p ${DESTDIR} &>/dev/null
fi

cd ${DESTDIR}
echo "" > ${LOG_FILE}
echo "#### usb_ppt.sh triggered" >> "${LOG_FILE}"
date				 >> "${LOG_FILE}"

if [ "${USER}" != "${MOUNT_USER}" ]; then
  echo "be ${MOUNT_USER}"
  echo "be ${MOUNT_USER}"	    >> "${LOG_FILE}"
  echo "can not start libreoffice"  >> "${LOG_FILE}"
  exit 1
else 
  echo "you are ${MOUNT_USER}"	 >> "${LOG_FILE}"
fi

if [ -f "${DESTINATION}" ]; then
  echo "### starting libreoffice"       >> "${LOG_FILE}"
  echo "${DESTINATION} exists"          >> "${LOG_FILE}"
  pkill -f "libreoffice" &> /dev/null
  find ${DESTDIR} -name ".~lock.*" -delete &>/dev/null
  libreoffice --impress --show --norestore ${DESTINATION} &> /dev/null &
else
  echo "can not start libreoffice"	>> "${LOG_FILE}"
  echo "${DESTINATION} does not exist"  >> "${LOG_FILE}"
fi
EOAS
chmod a+rx /ppt/auto_ppt.sh

echo "udev"
cat > /etc/udev/rules.d/99-local.rules << "EOR"
KERNEL=="sd[a-z][0-9]", SUBSYSTEMS=="usb", ACTION=="add", RUN+="/bin/systemctl start usb_mount@%k.service"
KERNEL=="sd[a-z][0-9]", SUBSYSTEMS=="usb", ACTION=="remove", RUN+="/bin/systemctl stop usb_mount@%k.service"
EOR
chmod +r /etc/udev/rules.d/99-local.rules

echo "control"
udevadm control -l debug
udevadm control --reload-rules
echo "reload"
systemctl daemon-reload



