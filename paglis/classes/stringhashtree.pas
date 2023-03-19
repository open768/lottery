unit stringhashtree;

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
(* $Header: /PAGLIS/classes/stringhashtree.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//

interface
 uses Windows,classes, hashtable;

 type
	TStringHash = class
	private
		f_auto_free_objects: boolean;
		function pr_Get_keys: Tstringlist;
		function pr_Get(key: string): TObject;
		procedure pr_Put(key: string; thing: TObject);
	public
		property AutoFreeObjects: Boolean read f_auto_free_objects write f_auto_free_objects;
		property Objects[key:String]: TObject read pr_Get write pr_Put;
		property Keys: Tstringlist read pr_Get_keys;
		procedure delete(const key:string);
	end;

//IMPLEMENTATION
implementation
var
  M_HASH : THashtable;

	//
	function TStringHash.pr_Get(key: string): TObject;
	var
		hashID: Dword;
	begin
		hashID := M_HASH.GetHash(key);
		result := nil;
	end;

	//
	procedure TStringHash.pr_Put(key: string; thing: Tobject);
	var
		hashID: Dword;
	begin
		hashID := M_HASH.GetHash(key);
		hashID := hashID;
	end;

	//
	procedure TStringHash.delete(const key:string);
	var
		hashID: Dword;
	begin
		hashID := M_HASH.GetHash(key);
	end;

	//
	function TStringHash.pr_Get_keys: Tstringlist;
	begin
		result := nil;
	end;

initialization
  M_HASH := THashtable.Create;


finalization
  M_HASH.Free;
//
//####################################################################
(*
	$History: stringhashtree.pas $
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
