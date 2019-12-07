This repository is deprecated! Please use ![Rio](https://github.com/skoro/rio)
----

## HTTP request inspector

A crossplatform desktop tool for inspecting http requests.
The application allows you to send http requests GET, POST, PUT, etc and
analyse its responses.

### Screenshots

Main window

![Main window](https://raw.githubusercontent.com/skoro/http_inspector/master/docs/screenshots/Screenshot_0.4-xfce-json.png)

Vertical layout and filtered JSON

![Vertical layout](https://raw.githubusercontent.com/skoro/http_inspector/master/docs/screenshots/Screenshot_0.4-xfce-hor_layout_filtered.png)

Windows

![Windows](https://raw.githubusercontent.com/skoro/http_inspector/master/docs/screenshots/Screenshot_0.4-win-json-tree.png)

Formatted JSON

![Formatted JSON](https://raw.githubusercontent.com/skoro/http_inspector/master/docs/screenshots/Screenshot_0.4-win-json-formatted.png)

### Compile from sources

For compiling from sources you will need the following requirements:
- [Lazarus](http://www.lazarus-ide.org/) 1.8
- [FreePascal](https://www.freepascal.org/) 3.0.4
- **Qt5Pas** for Qt5 widget set, can be installed by `sudo apt install libqt5pas1`
  on Ubuntu

Before compiling the application you will have to install a components package
`components/rest_explorer`. In Lazarus from the main menu
`Package / Open package file (.lpk)...` open the file
`components/rest_explorer/rest_explorer.lpk` and then compile and install the
package.
Please ensure that the package *TAChart* is also installed.

On Linux you can compile and create the install package (deb) by Makefile.
For example:
- `make linux32` for compiling a release binary for i386
- `make linux64` or for amd64
- `make linux64-qt` for compiling a release with Qt5 widget set
- `make deb-linux32` creates a deb package for i386
- `make appimage` creates AppImage binary (only amd64)

For more targets see output of `make`.

Refer to `install/windows/Readme.txt` for information how to compile on
Windows and to create Windows binary installers.

### Notes for Windows

The HTTPS requests require the OpenSSL DLLs to be on the system. These DLLs
you can get from https://indy.fulgan.com/SSL/ or from "install/windows"
directory. Put these DLLs along compiled exe binary.

Setup distributions already have these OpenSSL DLLs.
