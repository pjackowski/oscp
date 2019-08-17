# oscp

This repository contains OSCP helper scripts.

## kali-linux-vm-rec.sh

Script starts loop to continuously capture screenshots of Kali Linux VM window. It does it every 10 seconds and saves the image to drive only when SHA1 checksum differs. This is a simple step to discard duplicates.

There are many ways to capture images, ex. video recording of VM window in the host or with VirtualBox recording feature within VM, but series of screenshots are smaller and real FPS is much less than 1 frame per second due to time delay and simple image diffing with SHA1. It also requires less CPU and disk space and working with images is simpler than working with
long video files.

Tested only in Xorg with VirtualBox and it probably doesn't work in Wayland.

```
Dependencies:
rdfind      - Script uses rdfind to delete duplicates that have slipped trough SHA1 checks
imagemagick - Screenshots are captured with imagemagick.
```
