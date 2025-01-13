#!/bin/bash

DESTDIR="/ppt"
TARGET_FILE="presentation.pptx"
DESTINATION="${DESTDIR}/${TARGET_FILE}"
LOG_FILE="${DESTDIR}/auto_ppt.log"
MOUNT_USER=user

logger "### auto_ppt.sh triggered"

if [ -d "${DESTDIR}" ]; then
  echo "${DESTDIR} exists"
else 
  echo "mkdir ${DESTDIR}"
  mkdir -p ${DESTDIR} 										&>/dev/null
fi

cd ${DESTDIR}
echo "" 								 > ${LOG_FILE}
echo "### auto_ppt.sh triggered"		>> "${LOG_FILE}"
date									>> "${LOG_FILE}"

if [ "${USER}" != "${MOUNT_USER}" ]; then
  echo "be ${MOUNT_USER}"
  echo "be ${MOUNT_USER}"				>> "${LOG_FILE}"
  echo "can not start libreoffice"		>> "${LOG_FILE}"
  exit 1
else 
  echo "you are ${MOUNT_USER}"			>> "${LOG_FILE}"
fi

if [ -f "${DESTINATION}" ]; then
  echo "### starting libreoffice"		>> "${LOG_FILE}"
  echo "${DESTINATION} exists"			>> "${LOG_FILE}"
  pkill -f "libreoffice"									&> /dev/null
  find ${DESTDIR} -name ".~lock.*" -delete					&>/dev/null
  libreoffice --impress --show --norestore ${DESTINATION}	&> /dev/null &
else
  echo "can not start libreoffice"		>> "${LOG_FILE}"
  echo "${DESTINATION} does not exist"	>> "${LOG_FILE}"
fi
