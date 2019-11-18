# Script starts loop to continuously capture screenshots of Kali Linux
# VM window. It does it every 10 seconds and saves the image to drive only
# when SHA1 checksum differs. This is a simple step to discard duplicates.

# There are many ways to capture images, ex. video recording of VM window
# in the host or with VirtualBox recording feature within VM, but series of
# screenshots are smaller and real FPS is much less than 1 frame per second
# due to time delay and simple image diffing with SHA1. It also requires less
# CPU and disk space and working with images is simpler than working with
# long video files.

# Disable gnome date indicator with extension to reduce the number of images:
# https://extensions.gnome.org/extension/1110/hide-clock/

# Terminal cursor blinking in Kali is disabled by default, so it doesn't
# blink, but if it blinks for you I recommend to disable it to reduce
# captured images. It might be worth to disable blinking text in terminal
# at all, but I haven't noticed it causing issues. The mouse cursor isn't recorded.
# Some text editors might have blinking cursors and will produce more similar
# screen captures.

# Tested only in Xorg with VirtualBox, it probably doesn't work in Wayland.

# Dependencies:
# rdfind      - Script uses rdfind to delete duplicates that have slipped
#               trough SHA1 checks, but usually, there are very little duplicates.
# imagemagick - Screenshots are captured with imagemagick.

# ===

# capture frequency
DELAY=10s
COUNTER=0
DEDUP_COUNTER=100

# screenshots directory
TMP_DIR=/tmp
TARGET_DIR=$HOME/oscp-kali-linux-rec
FILE_PREFIX=kali

# image format
# note: there are different quality params for various formats supported by IM
IMAGE_FORMAT=jpg

# id of window with Kali VM
KALI_VM_WIN_STR1=virtualbox
KALI_VM_WIN_STR2=kali-linux
KALI_VM_WIN_ID=$(xwininfo -root -tree | grep -i -e "$KALI_VM_WIN_STR1" | grep -i -e "$KALI_VM_WIN_STR2" | grep -Eo '0x[a-z0-9]+' | head -n 1)

if [ -z "$KALI_VM_WIN_ID" ]; then
  echo "[!] Can't find Kali Linux VM window, exiting."
  exit 1
fi

echo "[*] Writing screenshots to: $TARGET_DIR"
echo "[*] Kali Linux VM windows id: $KALI_VM_WIN_ID"
echo "[*] File format: $IMAGE_FORMAT"
echo "[*] Frequency: $DELAY"

while true
do
  # concatenate paths and create file name
  DATE=$(date +"%Y-%m-%d")
  DATE_TIME=$(date +"%Y-%m-%d_%H:%M:%S")
  DIR_PATH=$TARGET_DIR/$DATE
  FILE_NAME=$FILE_PREFIX-$DATE_TIME.$IMAGE_FORMAT
  FULL_PATH=$DIR_PATH/$FILE_NAME
  FULL_TMP_PATH=$TMP_DIR/$FILE_NAME

  # create target directory
  if [ ! -d "$DIR_PATH" ]; then
    echo "[*] Created: $DIR_PATH"
    mkdir -p $DIR_PATH
  fi

  # check for existing files
  if [ "$COUNTER" -eq 0 ]; then
    FILES_COUNT=$(ls -At $DIR_PATH | wc -l)
    echo "[*] Files in $DATE: $FILES_COUNT"
  fi

  # grab most recent file for comparison
  MOST_RECENT_FILE=$(ls -At $DIR_PATH | head -n 1)

  # check if VM window still exists
  KALI_VM_WIN_ID_CHECK=$(xwininfo -root -tree | grep -e $KALI_VM_WIN_ID)
  if [ -z "$KALI_VM_WIN_ID_CHECK" ]; then
    echo "[!] Can't find Kali Linux VM window."
    notify-send 'Kali Linux screenshot' "Can't find Kali Linux VM window." -u normal
    
    # secondary delay  
    COUNTER=$((COUNTER+1))
    sleep $DELAY;
    continue
  fi

  # use imagemagick to capture screen without writing to disk, write file to tmpfs
  # (memory) instead, ex. /tmp or /run/user/1000
  import -quality 90 -silent -window $KALI_VM_WIN_ID $FULL_TMP_PATH 

  # check for recent duplicate with SHA1
  if [ -n "$MOST_RECENT_FILE" ]; then
    SHA1_MOST_RECENT=$(sha1sum $DIR_PATH/$MOST_RECENT_FILE | cut -c-40)
    SHA1_NEW=$(sha1sum $FULL_TMP_PATH | cut -c-40)
    
    # check hashes and remove new duplicate
    if [ "$SHA1_NEW" == "$SHA1_MOST_RECENT" ]; then
      echo "[-] Skipping [$COUNTER]..."
      rm $FULL_TMP_PATH
    else
      echo "[+] Captured: $FILE_NAME"
      mv $FULL_TMP_PATH $FULL_PATH
    fi
  else
    echo "[+] Captured: $FILE_NAME"
    mv $FULL_TMP_PATH $FULL_PATH
  fi

  # occasionally dedup all files
  if [[ ! "$COUNTER" -eq 0 && "$((COUNTER % DEDUP_COUNTER))" -eq "0" ]]; then
    DEDUP_RESULT=$(rdfind -deleteduplicates true -makeresultsfile false $DIR_PATH | grep -e 'Deleted [0-9]* files\.')
    echo "[*] Deduplicating $DATE, ${DEDUP_RESULT,,}"
  fi 

  # main delay  
  COUNTER=$((COUNTER+1))
  sleep $DELAY;
done
