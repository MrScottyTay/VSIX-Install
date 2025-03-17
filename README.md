# VSIX-Install
A Bash Script to download VSIX files from Microsoft VS Marketplace and Install them into VS Code or Codium

Should work for MS VS Code, VS Code OSS and Codium (but currently only tested with Codium).

This solution was devised since the VS Marketplace website removed the button to download VSIX files, which made getting extensions from the marketplace for Codium a pain. 
You can download and install the extension with either the VS Marketplace URL ```https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools``` or the extension name ```ms-vscode.cpptools```.

It will also determine what dependencies the extension has and gets them as well.

By default it will download VSIX files to your Downloads folder but will delete them after installation.
You change the download directory with ```--dir={path/to/download}``` and choose to keep the files with ```-k```.
You can choose to not install them and just download them only with ```-d``` (will always keep, since deletion is done after installation), and force a redownload and/or install with ```-f```

#### "Installation"
Download the script and place it whereever you want it to be and make it executable.
```
sudo chmod +x vsix-install.sh
```
#### Usage Example
```
./vsix-install.sh [-d] [-k] [-f] <VS Marketplace URL or Extension Name> [--dir=path/to/vsix-downloads-folder]
```
