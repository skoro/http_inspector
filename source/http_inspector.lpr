program http_inspector;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  cmem,
  {$ENDIF}
  Forms, sysutils, Interfaces, main, options, cmdline,
  tachartlazaruspkg // Don't remove! Chart initialization.
  ;

{$R *.res}

begin
  Application.Title := 'HTTP request inspector';
  RequireDerivedFormResource := True;
  Application.Initialize;

  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TOptionsForm, OptionsForm);

  try
     HandleCommandLine;
  except
    on E: Exception do begin
      WriteLn(Format('%s: %s', [ExtractFileName(Application.ExeName), E.Message]));
      Application.Terminate;
      Exit;
    end;
  end;

  Form1.ApplyOptions;
  Application.Run;
end.

