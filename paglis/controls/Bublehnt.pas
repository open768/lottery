unit Bublehnt;
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
(* $Header: /PAGLIS/controls/Bublehnt.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//


interface
uses
  classes, forms, bubble;
type
  TBubbleHint = class(Tcomponent)
  private
	F_Pause: integer;
	procedure set_pause(value: integer);
  protected
  public
	constructor create(Aowner:Tcomponent); override;
  published
	property Pause: integer read F_pause write set_pause;
  end;

procedure Register;

implementation
const
  DEFAULT_PAUSE = 2000;

{################################################################}
procedure Register;
begin
  RegisterComponents('Paglis Utils', [TBubbleHint]);
end;

{*********************************************************************
	All this component does is change the hintwindowclass.
	delphi uses this to create the hint window.
 ********************************************************************}
constructor Tbubblehint.create(Aowner:Tcomponent);
begin
  inherited create(aowner);
  F_pause := DEFAULT_PAUSE;

  if not (csDesigning in ComponentState) then
  begin
	 application.hintpause := F_pause;
	 Application.ShowHint:=false;
	HintWindowClass :=TBubbleHintWindow;
	 Application.ShowHint:=true;
  end;
end;

procedure Tbubblehint.set_pause(value: integer);
begin
  if value <> F_pause then
  begin
	 F_pause := value;
	 if not (csDesigning in ComponentState) then
		begin
			Application.ShowHint:=false;
			application.hintpause := F_pause;
		Application.ShowHint:=true;
	  end;
  end;
end;

//
//####################################################################
(*
	$History: Bublehnt.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/controls
 * 
 * *****************  Version 4  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/controls
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 3  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/controls
 * added headers and footers
*)
//####################################################################
//
end.
