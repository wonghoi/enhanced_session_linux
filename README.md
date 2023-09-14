# enhanced_session_linux
Windows Guest on Hyper-V works out of the box with sound, but not for Linux.
This script sets up the Ubuntu guest for similar out of the box experience

Blog post explaining the science of this script so you can adapt if dependencies change:
https://wonghoi.humgar.com/blog/2023/09/13/getting-sound-to-work-ubuntu-vm-guests-for-hyper-v/

I confirmed that it works for a fresh install of Ubuntu 23.04 with Cinnamon VM
as of 2023-09-14, specifically on Ubuntu Cinnamon Remix.

## One-liner if you trust me
```
wget https://raw.githubusercontent.com/wonghoi/enhanced_session_linux/main/setup_enhanced_session.sh -O - | sh
```

Otherwise inspect the code and its dependencies for shenanigans, chmod +x to make the downloaded file executable, and run it



