# VSIX-Install
A Bash Script to download VSIX files from Microsoft VS Marketplace and Install them into VS Code or Codium

Should work for MS VS Code, VS Code OSS and Codium (but currently only tested with Codium).

This solution was devised since the VS Marketplace website removed the button to download VSIX files, which made getting extensions from the marketplace for Codium a pain. 
You can download and install the extension with either the VS Marketplace URL ```https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools``` or the extension name ```ms-vscode.cpptools```.

It will also determine what dependencies the extension has and gets them as well.

By default it will download VSIX files to your Downloads folder but will delete them after installation.
You change the download directory with ```--dir={path/to/download}``` and choose to keep the files with ```-k```.
You can choose to not install them and just download them only with ```-d``` (will always keep, since deletion is done after installation), and force a redownload and/or install with ```-f```

### "Installation"
Download the script and place it whereever you want it to be and make it executable.
```
sudo chmod +x vsix-install.sh
```
#### Usage Example
```
./vsix-install.sh [-d] [-k] [-f] <VS Marketplace URL or Extension Name> [--dir=path/to/vsix-downloads-folder]
```

### How the Downloading works (or how to do it yourself)
If you just want to know how to download the VSIX files yourself without running this script, or are on an OS that can't run Bash scripts, this is how to do it.

Split the Extension name into two parts, the part before the period `.` and the part after. Then create a URL replacing the sections with either one of those parts with the following:

```
https://{firstPart}.gallery.vsassets.io/_apis/public/gallery/publisher/{firstPart}/extension/{secondPart}/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage
```

For example to download the VSIX for `ms-vscode.cpptools`, you will create a URL that looks like:
```
https://ms-vscode.gallery.vsassets.io/_apis/public/gallery/publisher/ms-vscode/extension/cpptools/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage
```

if you need a specific version replace `latest` with that version number.
