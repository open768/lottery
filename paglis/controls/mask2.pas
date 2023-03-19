unit mask2;

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
(* $Header: /PAGLIS/controls/mask2.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//

interface

uses
  SysUtils, Classes, Controls, StdCtrls, Mask;

type
  tmaskEdit2 = class(tmaskEdit)
  private
	{ Private declarations }
	f_hexOnly: boolean;
  protected
	{ Protected declarations }
  public
	{ Public declarations }
	procedure validateEdit; override;
  published
	{ Published declarations }
	property hexOnly: boolean read f_hexOnly write f_hexOnly ;
  end;

procedure Register;

implementation

uses miscstrings;

procedure Register;
begin
  RegisterComponents('Paglis CA', [tmaskEdit2]);
end;

//****************************************************************
procedure tmaskEdit2.validateEdit;
var
	ipos:integer;
	ch: char;
begin
	//---------------- do usual checks ----------------------
	inherited validateEdit;

    //---------------- check for hex ------------------------ 
	if not modified then exit;
	if f_hexOnly then
		for ipos := 1 to length(text) do begin
			ch := text[ipos];
			if not g_miscstrings.is_hex(ch) then begin
				setfocus;
				SetCursor(ipos-1);
			end;
		end;
end;
//
//#################################################################
(*
	$History: mask2.pas $
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
 * User: Administrator Date: 3/12/04    Time: 11:37p
 * Updated in $/code/paglis/controls
*)
//#################################################################
//

end.
