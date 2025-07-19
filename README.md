# Galaxy A13 5G Kernel

> [!NOTE]
> Feel free to FORK or create PR.

> [!NOTE]
> Make sure you have build tools/packages installed, else it won't compile properly.

## Looking for linux readme?
- [Click here](https://github.com/nostalgiceagle/samsung_kernel_mt6833/blob/OneUI7/README)

## To compile:
- git clone --depth=1 https://github.com/nostalgiceagle/samsung_kernel_mt6833
- cd samsung_kernel_mt6833
- ./build_kernel.sh (with sudo)


### Features [To be added/Implemented] 
    [✅️ = Done | ❌️ = Not done yet]
- Bootable with OneUI7 ✅️
- Upstreamed to 4.19.222 (as of now)✅️
- TEO CPUIDLE Governor ❌️
- Dex TouchPad [SEC_TOUCHPAD] ❌️
- Less-Debugs ❌️
- KernelSU-Next with SUSFS ❌️
- Maybe more in future

### About this Repository:
- I think it will be good to inform that this Repository is moved from https://github.com/nostalgiceagle/android_kernel_samsung_mt6833 . You may think why? So basically the old one had many junk stuffs making repo big in size, so removed the previous commit history and toolchain in hope to make the repository size as smaller as possible. Old commits are in another repository. If you want, you can check them. The changes are here but history isn't. I hope you understand 🤞.
