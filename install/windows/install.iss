; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "Http Inspector"
#define MyAppVersion "0.5"
#define MyAppPublisher "Skorobogatko Alexei"
#define MyAppURL "https://github.com/skoro/http_inspector"
#define MyAppExeName "http-inspector.exe"

; WIN32 or WIN64 is passed via command line compiler.
; Please see build-release.bat file.
#ifdef WIN32
  #define PLATFORM "i386-win32"
  #define OS_ARCH "win32"
#endif

#ifdef WIN64
  #define PLATFORM "x86_64-win64"
  #define OS_ARCH "win64"
#endif

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{75AD4AEA-89FC-4770-BF56-85BF203F76F7}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\..\dist
OutputBaseFilename=http-inspector-setup-{#MyAppVersion}-{#OS_ARCH}
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\bin\{#PLATFORM}\http-inspector.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "openssl_{#OS_ARCH}\libeay32.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "openssl_{#OS_ARCH}\ssleay32.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "openssl_{#OS_ARCH}\HashInfo.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "OpenSSL License.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\docs\curl.txt"; DestDir: "{app}"; Flags: ignoreversion
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{commonprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

