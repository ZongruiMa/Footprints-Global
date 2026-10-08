# Install on your own iPhone from Windows

Requires iOS 17+, a data-capable USB cable, your Apple account, and compatible
Apple device services on Windows. You do not need to own a Mac to use an
unsigned build produced by GitHub Actions.

1. Download the artifact from a successful **Build iPhone App** run. Extract
   `Footprints.ipa`. A source ZIP is not an installable iPhone package.
2. Follow the current [official AltStore Windows setup](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows)
   for iTunes, iCloud and AltServer. Do not uninstall existing sync software
   without checking that guide's compatibility requirements.
3. Connect and unlock your iPhone and trust the computer when iOS asks.
4. In the AltServer tray menu, install AltStore, then import the IPA in
   AltStore; alternatively use AltServer's Shift-menu **Sideload .ipa** if
   available. Select your own iPhone and the extracted IPA.
5. Enter credentials only in the signing tool's own dialog. Never send them
   to an issue, chat, or repository. Follow iOS prompts to trust your developer
   profile and enable Developer Mode if required.
6. Open Footprints. Choose a language in Settings. Photo permission is optional:
   you can mark the map and write notes first, then select photos to classify.

See [official AltServer release notes](https://faq.altstore.io/release-notes/altserver)
for direct sideloading and [AltStore getting started](https://faq.altstore.io/altstore-classic/your-altstore)
for signing expiry and refresh. Apps signed with a free account normally expire
after seven days and must be refreshed. Keep the same signing identity and
update in place to retain records. **Do not delete the app before updating**;
uninstalling removes notes and imported copies, and this version has no export.

## Photos

Settings offers two routes: request library access, or explicitly choose files
through Apple's photo picker. iOS “Private Access” describes the picker route;
it is not full-library access. The app can only automatically scan the library
after the system grants read access. Selected files can still be classified
locally if they contain GPS. iCloud originals may need a download by iOS.

If a system permission prompt fails to appear, use **Choose photos to classify**
and report the app/iOS version plus the local Diagnostics status. Do not reset
all system privacy settings or supply personal photo files as a workaround.
This preview does not claim to fix every OS-level authorization problem.

## 简体中文速查

从构建成功的 Actions 页面下载安装包，解压取得 `Footprints.ipa`。
按上面的官方教程设置 AltServer，连接并信任自己的 iPhone，再用自己的
Apple 账号签名安装。免费签名通常需要每七天续签；更新时不要先卸载。

设置中可选择语言和照片导入方式。“私密访问”只允许读取主动选择的文件，
不等于整个相册授权。可使用“选择照片并自动归类”；照片原文件需要包含 GPS。
缺少位置的照片进入待归类，可手动指定地区。不要为此还原整个手机的隐私设置。
