unit About;

interface

uses WinTypes, WinProcs, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, Dialogs, misclib,sysutils,globals, Shwrchck, ExtCtrls, language,
  Helper, Tranbtn;

type
  TAboutBox = class(TForm)
	Panel1: TPanel;
	ProgramIcon: TImage;
	lbl_ProductName: TLabel;
	Version: TLabel;
    lbl_copyright: TLabel;
	pnl_info: TPanel;
	Memo1: TMemo;
	pnl_register: TPanel;
	Label2: TLabel;
    txt_email: TEdit;
	SharewareChecker1: TSharewareChecker;
	Memo2: TMemo;
	lbl_details: TLabel;
    Localiser1: TLocaliser;
    btn_register: TMTranBtn;
    btn_ok: TMTranBtn;
    btn_buy: TMTranBtn;
    btn_url: TMTranBtn;
    Label1: TLabel;
	procedure pnl_registerResize(Sender: TObject);
	procedure btn_okClick(Sender: TObject);
	procedure FormActivate(Sender: TObject);
	procedure btn_registerClick(Sender: TObject);
	procedure pnl_infoResize(Sender: TObject);
	procedure FormCreate(Sender: TObject);
	procedure btn_buyClick(Sender: TObject);
	procedure ProgramIconClick(Sender: TObject);
	procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure btn_urlClick(Sender: TObject);
  private
	{ Private declarations }
	gang_counter: integer;
	key_pressed: boolean;
	activated: boolean;
	m_test_counter:integer;

	procedure do_gang_screen;
	procedure show_license;
  public
	{ Public declarations }
  end;

var
  AboutBox: TAboutBox;

implementation
uses
	miscencode, misccrypt, miscstrings,shellapi;

{$R *.DFM}

procedure TAboutBox.pnl_registerResize(Sender: TObject);
begin
  memo1.SetBounds(4,4,pnl_info.width-8,pnl_info.height-8);
end;

procedure TAboutBox.btn_okClick(Sender: TObject);
begin
	gang_counter := 0;
  close;
end;

procedure TAboutBox.FormActivate(Sender: TObject);
var
  result:boolean;
  major: integer;
  minor, name, sCopyright, sUrl: string;
begin
  m_test_counter := 0;
  if activated then exit;

  get_version(major,minor,name, sCopyright, sUrl);
  lbl_copyright.Caption := LocalString(sCopyright);
  btn_url.Caption := sUrl;
  version.caption := LocalString('Version #' + IntToStr(major) + '.' + minor +'#');
  lbl_ProductName.caption := name;

  with sharewarechecker1 do
  begin
	programName := program_name;
	key := g_misccrypt.get_standard_cipherkey(program_name);
	result := is_registered;
	lbl_details.caption := TheMessage;
  end;

  if (result) then show_license;
  activated := true;
end;

procedure TaboutBox.show_license;
begin
	pnl_register.visible := false;
	memo1.visible := false;
	memo2.visible := true;
end;

procedure TAboutBox.btn_registerClick(Sender: TObject);
begin
  with sharewarechecker1 do
  begin
	webregister(txt_email.text);
	lbl_details.caption := TheMessage;
	if is_registered then
	  show_license;
  end;
end;

procedure TAboutBox.pnl_infoResize(Sender: TObject);
begin
   memo1.setbounds(4,4,pnl_info.width-8,pnl_info.height-8);
end;

procedure TAboutBox.FormCreate(Sender: TObject);
begin
  gang_counter := 0;
  activated := false;
  if SharewareChecker1.isFree then begin
    btn_buy.Visible := false;
    pnl_register.Visible := false;
  end;
end;

procedure TAboutBox.btn_buyClick(Sender: TObject);
begin
  gang_counter := gang_counter +5;
	if (gang_counter > 16) then
	begin
		do_gang_screen;
	exit;
	end;

	try
		tmisclib.launch_url('register.htm',true);
	except
		showmessage(LocalString(' Hey, I couldn''t find the register web file'));
	end;
end;

procedure TAboutBox.ProgramIconClick(Sender: TObject);
begin
	m_test_counter := 1;
	gang_counter := gang_counter + 2;
	if (gang_counter > 16) then do_gang_screen;
end;

procedure TAboutBox.do_gang_screen;
var
	index: integer;
begin
	{-------------------make all controls invisible------}
	for index := 1 to componentcount do
		if components[index-1] is tcontrol then
			tcontrol(components[index-1]).visible := false;
	tmisclib.processmessages;
	key_pressed:= false;

	{--------display rude credits until a key is pressed-----}
	showmessage(LocalString('sorry credits screen not yet developed'));
	while not key_pressed do
	begin
		{animate_gang_screen;}
		tmisclib.processmessages;
	end;

	{-------------------make all controls visible------}
	for index := 1 to componentcount do
		if components[index-1] is tcontrol then
			tcontrol(components[index-1]).visible := true;
end;

procedure TAboutBox.FormKeyPress(Sender: TObject; var Key: Char);
begin
	key_pressed := true;
end;

procedure TAboutBox.btn_urlClick(Sender: TObject);
begin
	tmisclib.launch_url( btn_url.Caption, false);
end;

end.
