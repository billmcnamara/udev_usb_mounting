# ppt_kiosk_display_on_lubuntu

This is a repo to detect the insertion of a USB drive, and act on it.

Basically, I have a simple lubuntu deployment on a NUC whos only job in life is to display a PPT.

The update of the PPT is done by inserting a USB drive and udev add/remove tasks.

The PPT is launched in libreoffice on startup in ro mode following update via a ~user/.config/autostart/ entry.

# Howto
copy the content of this repo to /ppt/
then ./install.sh to set up the tasks/files
