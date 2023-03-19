unit Helper;
//
//****************************************************************
//* Copyright 2004 Paglis Software
//*
//* This source code is the intellectual property of 
//* Paglis Software and protected by Intellectual and 
//* international copyright Law.
//*
//* A free license is provided to use this code for any non commercial purpose
//* on the understanding that this copyright message must be retained
//* on all derivatives of the code and any risk or consequences of using this
//* code is the responsibility solely of the person using this code
//*
//* Contact  http://www.paglis.co.uk/
//*
//****************************************************************
//*
(* $Header: /PAGLIS/controls/Helper.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//


interface
uses
	shellapi,winprocs,wintypes,sysutils,classes,forms,dialogs;
type
	THtmlHelp = class(Tcomponent)
	private
		f_HelpSection: string;
		procedure set_HelpSection( psHelpSection:string);
	public
		constructor create(aowner:tcomponent); override;
	published
		Property HelpSection: string read f_HelpSection write set_HelpSection;
	end;

procedure Register;

implementation
uses
	translator, miscstrings,inifile,misclib,D6OnHelpFix ;
type
	THtmlHelpEngine=class
	private
		f_inifile:Tinifile;
		f_location:string;
	public
		c_HelpSection:string;
		constructor create;
		destructor destroy; override;
		function HtmlOnHelp(Command: Word; Data: Longint;	var CallHelp: Boolean): Boolean;
	end;
var
	m_helper: THtmlHelpEngine;
const
	HELPINI='help.ini';
	INFO_SECTION = 'info';
	RELATIVE_PATH_KEY = 'location';
	CONTENTS_KEY = 'contents';

//################################################################
procedure Register;
begin
	RegisterComponents('Paglis Utils', [THtmlHelp]);
end;

//################################################################
procedure THtmlHelp.set_HelpSection( psHelpSection:string);
begin
	f_HelpSection := psHelpSection;
	if (m_helper <> nil) then
		m_helper.c_HelpSection := psHelpSection;
end;

//*********************************************************************
constructor THtmlHelp.create(aowner:tcomponent); 
begin
	inherited create(aowner);

	if not (csDesigning in ComponentState)then
		if aowner <> nil then
			if m_helper=nil then
				begin
					// init d6
					FixDelphiHelp;
					
					//
					m_helper := THtmlHelpEngine.Create;
					Application.OnHelp := m_helper.HtmlOnHelp;
				end;

end;

//################################################################
constructor THtmlHelpengine.create;
begin
	inherited;
	f_inifile := nil;
	f_location :='';
end;

//*********************************************************************
destructor THtmlHelpengine.destroy;
begin
	if Assigned(f_inifile) then f_inifile.Free;
	inherited;
end;

//*********************************************************************
function THtmlHelpengine.HtmlOnHelp(Command: Word; Data: Longint;	var CallHelp: Boolean): Boolean;
var
	sUrl: string;
begin
	//-------------- dont want to use winhelp thankyou --------------
	result := true;
	CallHelp := false;
	if not (command  in [HELP_CONTEXT, HELP_INDEX, HELP_CONTENTS]) then exit;

	//------------look for help.ini file
	if not assigned(f_inifile) then
	begin
		f_inifile := Tinifile.Create(HELPINI);

		//- - - - - correct if elsewhere - - - - - - -
		f_location := f_inifile.read(INFO_SECTION,RELATIVE_PATH_KEY,'');
		if (f_location <> '') then
		begin
			f_inifile.Free;
			f_inifile := Tinifile.Create(f_location + HELPINI);
		end;
	end;

	//------------lookup help data in inifile
	if command= HELP_CONTEXT then
		sURl := f_inifile.read(c_HelpSection, inttostr(Data), '');
	if sUrl = '' then
		sURl := f_inifile.read(INFO_SECTION, CONTENTS_KEY, 'index.htm');
	sUrl := f_location + sUrl;

 

	//------------ fire off browser -------------------
	try
		g_misclib.launch_url(sUrl, true);
	except
		g_misclib.alert(
			localstring('unable to file help file: #' + sUrl + '#') +
			crlf +
			localstring('application may not have been installed correctly'));
	end;

end;

//################################################################

initialization
	m_helper := nil;
finalization

	Application.OnHelp := nil;
	if m_helper <> nil then
	begin
		m_helper.Free;
		m_helper := nil;
	end;
//
//####################################################################
(*
	$History: Helper.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/controls
 * 
 * *****************  Version 11  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/controls
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 10  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/controls
 * added headers and footers
*)
//####################################################################
//
end.





