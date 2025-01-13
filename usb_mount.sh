#!/bin/bash

logger "#### usb_mount.sh triggered by systemd"

LOG_FILE=/ppt/usb_mount.log
MOUNT_USER=user
ACTION=$1
DEVBASE=$2
DEVICE=/dev/${DEVBASE}
USB_MOUNT=$(/bin/mount |grep /bin/grep ${DEVICE} |/usr/bin/awk '{ print $3 }')
TARGET_DIR="/ppt"
TARGET_FILE="presentation.pptx"
DESTINATION="${TARGET_DIR}/${TARGET_FILE}"
MD5_FILE="${DESTINATION}.md5"

usage()
{
  echo "### usage"			>> "${LOG_FILE}"
  date						>> "${LOG_FILE}"
   echo "$0 {add|remove} sda1" 
   exit 1
}

do_find()
{
  echo "### do_find"		>> "${LOG_FILE}"
  date						>> "${LOG_FILE}"

 FILE=$(find "${USB_MOUNT}" -name ${TARGET_FILE} 2>/dev/null |head -n 1)
 if [ "${FILE}"x != "x" ]; then
	echo "found ${FILE}"				>> "${LOG_FILE}"
	#echo "ll ${TARGET_DIR} before"		>> "${LOG_FILE}"
	#ls -l ${TARGET_DIR}				>> "${LOG_FILE}"
	rm -rf ${TARGET_DIR}/.lock.*
 else
	echo "no ppt file in ${USB_MOUNT}/${TARGET_FILE}"		>> "${LOG_FILE}"
	echo "try again.."										>> "${LOG_FILE}"
        echo -n .; sleep 2
        echo .; sleep 2
        FILE=$(find "${USB_MOUNT}" -name "${TARGET_FILE}"	2>/dev/null |head -n 1)
        if [ "${FILE}"x != "x" ]; then
	  echo "now it is found ${FILE}"						>> "${LOG_FILE}"
        else
	  echo "still not found ${FILE}"						>> "${LOG_FILE}"
	fi
 fi

 if [ -f "${FILE}" ]; then
      NEW_MD5=$(md5sum ${FILE}|awk '{ print $1 }')
      echo "new md5 of ${FILE}"								>> "${LOG_FILE}"
      echo "${NEW_MD5}"										>> "${LOG_FILE}"
 else
      echo "no file at ${FILE}"								>> "${LOG_FILE}"
      NEW_MD5=""
 fi

 echo "check ${TARGET_DIR}"									>> "${LOG_FILE}"
 if [ -d "${TARGET_DIR}" ]; then
         echo "${TARGET_DIR} exists"						>> "${LOG_FILE}"
         #echo "list ${TARGET_DIR}"							>> "${LOG_FILE}"
         #ls -l ${TARGET_DIR}								>> "${LOG_FILE}"
 else
         echo "mkdir ${TARGET_DIR}"							>> "${LOG_FILE}"
	 mkdir -p ${TARGET_DIR}									&>/dev/null
 fi
 cd ${TARGET_DIR}

 TARGET_FILE="presentation.pptx"
 echo "check ${TARGET_FILE}"								>> "${LOG_FILE}"
 if [ -f "${TARGET_FILE}" ]; then
         echo "${TARGET_FILE} exists"						>> "${LOG_FILE}"
         #echo "list ${TARGET_FILE}"						>> "${LOG_FILE}"
         #ls -l ./${TARGET_FILE}							>> "${LOG_FILE}"
 else
         echo "./${TARGET_FILE} does not exist"				>> "${LOG_FILE}"
 fi

 if [ -f "${DESTINATION}" ]; then
  echo "${DESTINATION} exists"								>> "${LOG_FILE}"
  OLD_MD5=$(md5sum ${DESTINATION}|awk '{ print $1 }')
  echo "previous md5 of ${DESTINATION}"						>> "${LOG_FILE}"
  echo "${OLD_MD5}"											>> "${LOG_FILE}"
 else
  OLD_MD5=""
  echo "file ${DESTINATION} not found"						>> "${LOG_FILE}"
 fi

}

do_copy()
{
  echo "### do_copy"										>> "${LOG_FILE}"
  date														>> "${LOG_FILE}"
  if [ "${NEW_MD5}" != "${OLD_MD5}" ] ; then
	echo "need to copy because md5 not equal"				>> "${LOG_FILE}"
	cp "${FILE}" "${DESTINATION}"
	echo "copied to ${DESTINATION}"							>> "${LOG_FILE}"
	NEW_MD5=$(md5sum ${DESTINATION}|awk '{ print $1 }')
	echo "${NEW_MD5}"										> "${MD5_FILE}"
	echo "created md5 file"									>> "${LOG_FILE}"
  else
	echo "same md5"											>> "${LOG_FILE}"
  fi

  #echo "ll ${TARGET_DIR} after"							>> "${LOG_FILE}"
  #ls -l ${TARGET_DIR}										>> "${LOG_FILE}"
}

do_start()
{
  echo "### do_start"										>> "${LOG_FILE}"
  date														>> "${LOG_FILE}"
 if [ -f "${DESTINATION}" ]; then
  pkill -f "libreoffice"									&> /dev/null
  find ${TARGET_DIR} -name ".lock.*" -delete
  DISPLAYIS=$(/bin/who |/bin/grep "(:[0-9])" | head -n 1| awk '{ print $5 }' |tr -d '()')
  echo "DISPLAY is ${DISPLAYIS}"							>> "${LOG_FILE}"

  sudo -u ${MOUNT_USER}  DISPLAY=${DISPLAYIS}  XAUTHORITY=/home/${MOUNT_USER}/.Xauthority libreoffice --impress --norestore --show "${DESTINATION}" > /dev/null 2>&1 &
 else
  echo "no file at ${DESTINATION}"							>> "${LOG_FILE}"
  echo "1234"												> "${MD5_FILE}"
 fi
}

do_mount()
{
  cd ${TARGET_DIR}
  echo ""													 > ${LOG_FILE}
  echo "### do_mount"										>> "${LOG_FILE}"
  date														>> "${LOG_FILE}"
   if [[ -n ${USB_MOUNT} ]]; then
	echo "${DEVICE} is already mounted at ${USB_MOUNT}"  	>> "${LOG_FILE}"
	exit 1
   fi
   eval $(/sbin/blkid -o udev ${DEVICE})
   LABEL=${ID_FS_LABEL}
   if [[ -z "${LABEL}" ]]; then
	   LABEL=${DEVBASE}
   elif /bin/grep -q " /media/${LABEL} " /etc/mtab; then
	   LABEL+=${DEVBASE}
   fi
   USB_MOUNT="/media/${LABEL}"
   echo "${DEVICE} is mounted at ${USB_MOUNT}"				>> "${LOG_FILE}"
   /bin/mkdir -p ${USB_MOUNT}
   OPTS="rw,relatime"

   if [[ ${ID_FS_TYPE} == "vfat" ]]; then
	   OPTS+=",users,gid=1000,umask=000,shortname=mixed,utf8=1,flush"
   fi

   if ! /bin/mount -o ${OPTS} ${DEVICE} ${USB_MOUNT}; then
	echo "error mounting ${DEVICE} on ${USB_MOUNT}"			>> "${LOG_FILE}"
	/bin/rmdir ${USB_MOUNT}
	exit 1
   fi
	
   echo "mounted ${DEVICE} on ${USB_MOUNT}"					>> "${LOG_FILE}"
   do_find
   do_copy
   do_start
}

do_unmount()
{
  cd ${TARGET_DIR}
  echo ""													 > ${LOG_FILE}
  echo "### do_unmount"										>> "${LOG_FILE}"
  date														>> "${LOG_FILE}"
   if [[ -z ${USB_MOUNT} ]]; then
	echo "${DEVICE} is not mounted"							>> "${LOG_FILE}"
	#/bin/fuser -km ${USB_MOUNT}							&>/dev/null
	/bin/umount -f ${USB_MOUNT}								&>/dev/null
	/bin/umount -l ${USB_MOUNT}								&>/dev/null
	/bin/umount -l ${DEVICE}								&>/dev/null
   else
	echo "${DEVICE} is mounted"								>> "${LOG_FILE}"
	/bin/umount -l ${DEVICE}								&>/dev/null
	/bin/umount -l ${USB_MOUNT}								&>/dev/null
   fi

}

case "${ACTION}" in
	add)
	    do_mount
	    ;;
        remove)
            do_unmount
            ;;
        *)
	    usage
	    ;;
esac
