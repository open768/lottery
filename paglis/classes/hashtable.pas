unit hashtable;

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
(* $Header: /PAGLIS/classes/hashtable.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//

//	uses fragments of code from hashtrie
// Copyright (c) 2000, Andre N Belokon, SoftLab
// Web	   http://softlab.od.ua/
// Email   support@softlab.od.ua
//written permission gained from author to use code in any way.


interface
uses windows;

type
	//hashtable which is an sparselist containing binary trees;
	THashtable = class
	private
		function pr_ROR(value:DWORD):DWORD;
	public
		function GetHash(const S: string): DWORD;
	end;


implementation

const
	ARRAY_SIZE=$FF;
	CRC32_POLYNOMIAL = $EDB88320;
type
	Ccitt32Table=array[0..ARRAY_SIZE] of DWORD;
var
	M_CCitt32Table : Ccitt32Table;


//################################################################################
// public
//################################################################################
	function THashtable.GetHash(const S: string): DWORD;
	var
		j: integer;
		hash: dword;
	begin
		hash:=$FFFFFFFF;
		for j:=1 to Length(S) do
			hash:= (((hash shr 8) and $00FFFFFF) xor (M_CCitt32Table[(hash xor byte(S[j])) and $FF]));

		hash:=pr_ROR(hash);

		Result:=hash and ARRAY_SIZE;
	end;

//################################################################################
// private
//################################################################################
	function THashtable.pr_ROR(Value: DWORD): DWORD;
	begin
	  Result:=((Value and $FF) shl 24) or ((Value shr 8) and $FFFFFF);
	end;

//################################################################################
// GLOBAL
//################################################################################
	procedure pr_Build_CRC_Table;
	var i, j: longint;
		 value: DWORD;
	begin
		for i := 0 to ARRAY_SIZE do begin
			value := i;
			for j := 8 downto 1 do
			 if ((value and 1) <> 0) then
				value := (value shr 1) xor CRC32_POLYNOMIAL
			 else
				value := value shr 1;
			M_CCitt32Table[i] := value;
		end
	end;

initialization
	pr_Build_CRC_Table;


	
  (*
		$History: hashtable.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/classes
 * 
 * *****************  Version 5  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/classes
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 4  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
 * 
 * *****************  Version 3  *****************
 * User: Sunil		  Date: 1/03/03    Time: 6:12p
 * Updated in $/paglis/classes
 * DOESNT CREATE A CCIT TABLE EVERYTIME
	*)
end.


