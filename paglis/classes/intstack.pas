unit intstack;

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
(* $Header: /PAGLIS/classes/intstack.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//

interface
uses classes;

type
	TIntStack = class(Tstringlist)
	public
		procedure Add(piValue: integer); reintroduce; 
		function Get(piIndex: integer): integer; reintroduce;
		function IndexOf(const piValue: integer): Integer; reintroduce;
		procedure DeleteValue(const piValue: integer);
		procedure AddUnique(const piValue: integer);
	end;


implementation
uses
	sysutils;

	//****************************************************************
	procedure TIntStack.Add(piValue: integer);
	begin
		inherited add( inttostr(pivalue));
	end;

	//****************************************************************
	function TIntStack.Get(piIndex: integer): integer;
	begin
		result := strtoint(inherited get(piIndex));
	end;

	//****************************************************************
	function TIntStack.IndexOf(const piValue: integer): Integer;
	begin
		result := inherited indexof(inttostr(piValue));
	end;

	//****************************************************************
	procedure TIntStack.DeleteValue(const piValue: integer);
	var
		index:integer;
	begin
		index := indexof(piValue);
		if index <> -1 then
			delete(index);
	end;

	//****************************************************************
	procedure TIntStack.AddUnique(const piValue: integer);
	var
		index:integer;
	begin
		index := indexof(piValue);
		if index = -1 then
			add(piValue);
	end;
//
//####################################################################
(*
	$History: intstack.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/classes
 * 
 * *****************  Version 4  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/classes
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 3  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
*)
//####################################################################
//
end.
