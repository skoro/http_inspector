
include ./source/version.inc
PROJECT=source/http_inspector.lpr
LAZBUILD?=lazbuild
LINUXDEPLOY?=linuxdeploy-x86_64.AppImage
APP=http-inspector
APPDIR=AppDir
WIDGET=gtk

all:
	@echo ""
	@echo "Current app version is ${APP_VER}"
	@echo ""
	@echo "Select target:"
	@echo ""
	@echo "  linux32          Compile for Linux i386 with GTK2 widget set"
	@echo "  linux32-debug    Compile for Linux i386 with GTK2 and debug info"
	@echo "  linux64          Compile for Linux amd64 with GTK2 widget set"
	@echo "  linux64-debug    Compile for Linux amd64 with GTK2 and debug info"
	@echo "  linux64-qt       Compile for Linux amd64 with QT widget set"
	@echo "  linux64-qt-debug Compile for Linux amd64 with QT and debug info"
	@echo "  linuxarm         Compile for Linux ARM"
	@echo "  linuxarm-debug   Compile for Linux ARM with debug info"
	@echo "  linux-all        Compile for the targets: 32, 64, gtk"
	@echo "  linux-qt         Compile binaries, deb package for QT"
	@echo "  deb-linux32      Create a debian package for i386"
	@echo "  deb-linux64      Create a debian package for amd64"
	@echo "  deb-linux64-qt   Create a debian package for amd64 with QT"
	@echo "  deb-linuxarm     Create a debian package for ARM"
	@echo "  deb-all          Create debian package for the targets: 32, 64, gtk"
	@echo "  bin-linux32      Create a binary app archive for i386"
	@echo "  bin-linux64      Create a binary app archive for amd64"
	@echo "  bin-linux64-qt   Create a binary app archive for amd64 and QT"
	@echo "  bin-linuxarm     Create a binary app archive for ARM"
	@echo "  bin-all          Create binary app archives for the targets: 32, 64, gtk"
	@echo "  appimage         Create an AppImage bundle"
	@echo "  appimage-qt      Create an AppImage with QT"
	@echo ""

clean: clean-build

clean-build:
	rm -rf bin build

clean-backup:
	rm -rf source/backup

clean-appdir:
	rm -rf $(APPDIR)

.PHONY: linux32 linux64-debug deb-linux32 bin-linux32 linux-arch-32 \
	linux64 linux64-debug deb-linux64 bin-linux64 linux-arch-64 \
	linux64-qt linux64-qt-debug deb-linux64-qt bin-linux64-qt \
	linuxarm linuxarm-debug deb-linuxarm bin-linuxarm linux-arch-arm \
	os-linux release-mode debug-mode bin build \
	deb-package linux-all deb-all bin-all appimage

linux-all:
	make linux32
	make linux64
	make linuxarm
deb-all:
	make deb-linux32
	make deb-linux64
	make deb-linuxarm
bin-all:
	make bin-linux32
	make bin-linux64
	make bin-linuxarm
linux-qt:
	make linux64-qt
	make bin-linux64-qt
	make deb-linux64-qt

linux32: linux-arch-32 release-mode build
linux32-debug: linux-arch-32 debug-mode build
deb-linux32: linux32 deb-package
bin-linux32: linux32 bin-package

linux64: linux-arch-64 release-mode build
linux64-qt: linux-arch-64 release-mode-qt build
linux64-debug: linux-arch-64 debug-mode build
linux64-qt-debug: linux-arch-64 debug-mode-qt build
deb-linux64: linux64 deb-package
deb-linux64-qt: WIDGET := qt5
deb-linux64-qt: linux64-qt deb-package
bin-linux64: linux64 bin-package
bin-linux64-qt: WIDGET := qt5
bin-linux64-qt: linux64-qt bin-package

linuxarm: linux-arch-arm release-mode build
linuxarm-debug: linux-arch-arm debug-mode build
deb-linuxarm: linuxarm deb-package
bin-linuxarm: linuxarm bin-package

os-linux:
	$(eval OS=linux)
linux-arch-32: os-linux
	$(eval CPU=i386)
linux-arch-64: os-linux
	$(eval CPU=x86_64)
linux-arch-arm: os-linux
	$(eval CPU=arm)
release-mode:
	$(eval BUILD_MODE=Release)
release-mode-qt:
	$(eval BUILD_MODE="Release QT5")
debug-mode:
	$(eval BUILD_MODE=Debug)
debug-mode-qt:
	$(eval BUILD_MODE="Debug QT5")
bin:
	$(eval BIN=./bin/$(CPU)-$(OS)/$(APP))
build: bin $(BIN)
	$(LAZBUILD) --os=$(OS) --cpu=$(CPU) --build-mode=$(BUILD_MODE) $(PROJECT)

deb-package: mkdist
	( cd ./install/debian && ./create-deb.sh $(CPU) $(WIDGET) )

bin-package: mkdist
	$(eval DIST=./dist/$(APP)_$(APP_VER)-$(OS)-$(CPU)-$(WIDGET)-bin)
	rm -f $(DIST)
	cp ./bin/$(CPU)-$(OS)/$(APP) $(DIST)
	chmod +x $(DIST)
	gzip $(DIST)

mkdist:
	mkdir -p ./dist

appimage-qt: WIDGET := qt5
appimage-qt: linux64-qt $(APPDIR) Http_Inspector-x86_64.AppImage
appimage: linux64 $(APPDIR) Http_Inspector-x86_64.AppImage
$(APPDIR):
	mkdir -p $(APPDIR)/usr/bin
	cp bin/x86_64-linux/http-inspector $(APPDIR)/usr/bin/$(APP)
Http_Inspector-x86_64.AppImage: mkdist
	$(LINUXDEPLOY) --appdir=$(APPDIR) \
		--desktop-file=./resources/http-inspector.desktop \
		--icon-file=./resources/icons/http-inspector.png \
		--output appimage
	mv Http_Inspector-x86_64.AppImage ./dist/$(APP)-$(APP_VER)-$(WIDGET).AppImage
	rm -rf $(APPDIR)
