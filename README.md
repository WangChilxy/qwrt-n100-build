# Q-WRT x86_64 N100 GitHub Actions Template

This template is prepared for an Intel N100 x86_64 soft router.

Detected router info:

- Current system: iStoreOS 24.10.6
- Target: x86/64
- CPU: Intel N100
- Ethernet: Intel I226-V
- Disk: NVMe
- Current LAN IP: 192.168.100.1

## How to use

1. Create a new empty GitHub repository.
2. Upload every file in this folder to that repository.
3. Open the repository's Actions page.
4. Choose `Build Q-WRT x86_64`.
5. Click `Run workflow`.
6. Wait for it to finish.
7. Download `Q-WRT-x86_64-N100-firmware` from Artifacts.

For this machine, use the x86/64 combined image. Do not flash firmware for ARM, MTK, IPQ, or other router platforms.

