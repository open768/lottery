unit filestream2;

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
(* $Header: /PAGLIS/classes/filestream2.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//

interface
uses
	classes;
type
	TFilestream2 = class(Tfilestream)
	public
		function write(astring:string):longint; overload;
		function writeln(astring:string):longint;
	end;
implementation
uses
	misclib;

	//**************************************************************
	function TFilestream2.write(astring:string):longint;
	begin
		result := inherited write(pchar(astring)^, length(astring));
	end;

	//**************************************************************
	function TFilestream2.writeln(astring:string):longint;
	begin
		result := write( astring + CRLF);
	end;


//
//####################################################################
(*
	$History: filestream2.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/classes
 * 
 * *****************  Version 2  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/classes
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 1  *****************
 * User: Administrator Date: 5/12/04    Time: 5:10p
 * Created in $/code/paglis/classes
 * 
 * *****************  Version 5  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/ebookclasses
 * added headers and footers
*)
//####################################################################
//
end.
 