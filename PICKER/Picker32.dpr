program picker32;

uses
  Forms,
  Main in 'code\Main.pas' {frm_picker},
  options in 'code\options.pas' {frm_options},
  picked in 'code\picked.pas' {frmPicked},
  About in '..\COMMON\About.pas' {AboutBox},
  Pickglob in 'code\Pickglob.pas',
  memcheck;

{$R *.RES}

begin
	//MemChk;
  Application.Initialize;
  Application.CreateForm(Tfrm_picker, frm_picker);
  Application.CreateForm(Tfrm_options, frm_options);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.CreateForm(TfrmPicked, frmPicked);
  Application.Run;
end.
