unit Popup2;
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
(* $Header: /PAGLIS/controls/POPUP2.PAS 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//


interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, Menus;

type
  TPopupMenu2 = class(TPopupMenu)
  private
	{ Private declarations }
  protected
	{ Protected declarations }
  public
	{ Public declarations }
  published
	{ Published declarations }
	property Alignment;
	property AutoPopup;
	property HelpContext;
	property items;
	property name;
	property tag;
	property Onpopup;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Paglis', [TPopupMenu2]);
end;

//
//####################################################################
(*
	$History: POPUP2.PAS $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/controls
 * 
 * *****************  Version 3  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/controls
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 2  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/controls
 * added headers and footers
*)
//####################################################################
//
end.

