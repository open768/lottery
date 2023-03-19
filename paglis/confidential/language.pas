unit language;
//
//****************************************************************
//* Copyright 2003 Paglis Software
//*
//* This copyright notice must be maintained on this source file
//* and all subsequent modified versions. 
//* 
//* This source code is the intellectual property of 
//* Paglis Software and protected by Intellectual and 
//* international copyright Law.
//*
//* Contact  http://www.paglis.co.uk/
//*
(* $Header: /PAGLIS/confidential/language.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//


interface

uses
	ExtCtrls, StdCtrls, menus, controls, comctrls, Classes, forms, contnrs, resizer;
type

	//hook into window creation and localise all forms
	//dont know how to hook - must be called explicityly on forms with menus
	TLocaliser = class(TComponent)
	private
		c_resizer: TControlResizer;
		procedure pr_translate(AForm: TForm); overload;
		procedure pr_translate(poPanel: Tpanel); overload;
		procedure pr_translate(poPageControl: Tpagecontrol); overload;
		procedure pr_translate(poMenu: Tmenu); overload;
		procedure pr_translate(poMenuItem: Tmenuitem); overload;
		procedure pr_translate(poTabSheet: Ttabsheet); overload;
		procedure pr_translate(poButton: Tbutton); overload;
		procedure pr_translate(poLabel: TLabel); overload;
		procedure pr_translate(poCheckbox: TCheckbox); overload;
	public
		constructor create(Aowner:Tcomponent); override;
		destructor destroy; override;
		procedure translate(poComponent: Tcomponent);
	end;

	procedure Register;
	function LocalString( psEnglishString: string):string;

implementation
	uses tranbtn, translator, misclib;

const
	CHECKBOX_EXTRA_WIDTH=22;


//********************************************************
procedure Register;
begin
 RegisterComponents('Paglis Utils', [TLocaliser]);
end;

//********************************************************
constructor TLocaliser.create(Aowner:Tcomponent);
var
parent_form: tform;
begin
 inherited;

 //--go up the parent tree until you find a form ----
 c_resizer := TControlResizer.Create;
 parent_form := g_misclib.find_form(aowner);
 translate(parent_form);
end;

//********************************************************
destructor TLocaliser.destroy;
begin
 c_resizer.free;
 inherited;
end;


//############################################################
procedure TLocaliser.translate(poComponent: Tcomponent);
var
original, foreign:string;
begin
  //----------------------------------------------------------------------
if poComponent is Tcontrol then
	Tcontrol(poComponent).hint := LocalString(Tcontrol(poComponent).hint);

  //----------------------------------------------------------------------
	if poComponent is Tform then
	begin
		pr_translate( Tform(poComponent));
		exit
	end;

	if poComponent is Tpanel then
	begin
		pr_translate( Tpanel(poComponent));
		exit
	end;

	if poComponent is Tbutton then
	begin
		pr_translate(Tbutton(poComponent));
		exit
	end;

	if poComponent is Tlabel then
	begin
		pr_translate(Tlabel(poComponent));
		exit;
	end;

	if poComponent is TCheckBox then
	begin
		pr_translate(TCheckBox(poComponent));
		exit;
	end;

	if poComponent is Ttabsheet then
	begin
		pr_translate(ttabsheet(poComponent));
		exit
	end;

	if poComponent is Tpagecontrol then
	begin
		pr_translate(Tpagecontrol(poComponent));
		exit
	end;

	if poComponent is Tmenu then
	begin
		pr_translate(Tmenu(poComponent));
		exit;
	end;

	if poComponent is Tmenuitem then
	begin
		pr_translate(Tmenuitem(poComponent));
		exit;
	end;

	if poComponent is TMTranBtn then
	begin
		original := TMTranBtn(poComponent).caption;
		foreign := LocalString( original );
		if original <> foreign then TMTranBtn(poComponent).caption := foreign;
	  exit;
	end;

	//----------------------------------------------------------------------

end;

//********************************************************
procedure TLocaliser.pr_translate(AForm: TForm);
var
	index: integer;
	foreign:string;
begin
	for index := 1 to Aform.ControlCount do
		translate( aform.controls[index-1]);

	foreign := localstring(aform.caption);
	if aform.caption <> foreign then AForm.Caption:=foreign;
end;

//********************************************************
procedure TLocaliser.pr_translate(poCheckbox: TCheckbox);
var
	foreign :string;
	new_width:integer;
begin
	foreign := localstring(poCheckbox.caption);
	if foreign = poCheckbox.Caption then exit;	//dont progress if transaltion is same

	poCheckbox.caption := foreign;
	new_Width:=g_misclib.get_text_extent(poCheckbox.font, foreign).cx + CHECKBOX_EXTRA_WIDTH;

	c_resizer.resizeControl(poCheckbox, new_width);

end;

//********************************************************
procedure TLocaliser.pr_translate(poLabel: Tlabel);
var
	foreign :string;
begin
	foreign := localstring(poLabel.caption);
	if foreign = poLabel.Caption then exit;	//dont progress if transaltion is same

	poLabel.AutoSize := true;
	poLabel.caption := foreign;
	c_resizer.resizeControl(poLabel, poLabel.Width);
end;

//********************************************************
procedure TLocaliser.pr_translate(poPanel: Tpanel);
var
	index:integer;
	foreign :string;
begin
	for index :=1 to poPanel.ControlCount do
		translate ( poPanel.controls[index-1]);

	foreign := localstring(poPanel.caption);
	if foreign = poPanel.Caption then exit;	//dont progress if transaltion is same
	poPanel.caption := foreign;
end;

//********************************************************
procedure TLocaliser.pr_translate(poPageControl: Tpagecontrol);
var
	page_index:integer;
	page: Ttabsheet;
begin
for page_index:=1 to poPageControl.PageCount do
  begin
	page := poPageControl.pages[page_index-1];
	  translate(page);
  end;
end;

//********************************************************
procedure TLocaliser.pr_translate(poTabSheet: Ttabsheet);
var
	index: integer;
begin
	poTabSheet.caption := LocalString(poTabSheet.caption);
	for index := 1 to poTabSheet.ControlCount	do
		translate( poTabSheet.controls[index-1]);
end;

//********************************************************
procedure TLocaliser.pr_translate(poMenu: Tmenu);
var
	index:integer;
	item: tmenuitem;
begin
	for index := 1 to poMenu.Items.count do
	begin
		item := poMenu.items[index-1];
		translate(item);
	end;
end;

//********************************************************
procedure TLocaliser.pr_translate(poButton: Tbutton);
var
	foreign: string;
	new_Width:integer;
begin
	//---------change caption -----------------------------
	foreign := localstring(poButton.caption);
	if foreign = poButton.caption then exit;	//dont progress if transaltion is same
	poButton.caption := foreign;


	//---------resize and bubble up -----------------------------
	new_Width:=g_misclib.get_text_extent(poButton.font, poButton.Caption).cx + 10;
	if new_Width > poButton.Width then
		c_resizer.resizeControl(poButton, new_Width);
end;


//********************************************************
procedure TLocaliser.pr_translate(poMenuItem: Tmenuitem);
var
	index:integer;
	item: tmenuitem;
	foreign:string;
begin
	foreign := LocalString(poMenuItem.Caption);
	if foreign = poMenuItem.Caption then exit;   //dont progress if transaltion is same

	poMenuItem.caption := LocalString(poMenuItem.caption);

	for index := 1 to poMenuItem.count do
	begin
		item := poMenuitem.items[index-1];
		translate(item);
	end;
end;

//############################################################
function LocalString( psEnglishString: string):string;
begin
  result := translator.localstring(psEnglishString);
end;

//
//####################################################################
(*
	$History: language.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/confidential
 * 
 * *****************  Version 7  *****************
 * User: Sunil        Date: 19-02-03   Time: 12:55a
 * Updated in $/code/paglis/controls
 * translation correctly resizes controls 
 * 
 * *****************  Version 6  *****************
 * User: Sunil        Date: 18-02-03   Time: 6:33p
 * Updated in $/code/paglis/controls
 * added specific handlers for labels and check boxes
 * 
 * *****************  Version 5  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/controls
 * added headers and footers
*)
//####################################################################
//
end.

