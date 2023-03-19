unit objtree;

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
(* $Header: /PAGLIS/classes/objtree.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//


interface
uses classes;
type
	TobjTree = class
	private
		fs_key:string;
		fo_value:TObject;
		cb_deleted, cb_auto_free_objs, cb_initialised: boolean;
		co_left,co_right : TobjTree;

		function pr_get_object(ps_key:string):Tobject;
		procedure pr_set_object(ps_key:string; po_obj: tobject);
		function pr_get_object_from(ps_key:string; po_tree:tobjtree): tobject;
		procedure pr_set_object_on(ps_key:string; po_obj: tobject; var po_tree: TobjTree);
	public
		constructor create; overload;
		constructor create(pb_auto_free_Objs: boolean); overload;
		constructor create(pb_auto_free_Objs: boolean; ps_Key: string; po_obj: Tobject); overload;
		destructor Destroy; override;
		procedure Keys(po_list: Tstringlist);
		procedure deleteKey(ps_key:string);
		property Objects[key:string]: Tobject read pr_get_object write pr_set_object;
		property Key:String read fs_key;
		property Value:Tobject read fo_value;
	end;

implementation
	uses sysutils,math;

	//###########################################################
	//constructor destructor
	//###########################################################
	destructor TobjTree.destroy;
	begin
		if (co_left <> nil) then
		begin
			co_left.Free;
			co_left := nil;
		end;

		if (co_right <> nil) then
		begin
			co_right.Free;
			co_right := nil;
		end;

		if (cb_auto_free_objs) then
			if (fo_value <> nil) then
			begin
				fo_value.Free;
				fo_value := nil;
			end;

		cb_deleted := true;
		inherited Destroy;
	end;

	//***********************************************************
	constructor TobjTree.create();
	begin
		create(false);
	end;

	//***********************************************************
	constructor TobjTree.create(pb_auto_free_Objs: boolean);
	begin
		create(pb_auto_free_Objs,'',nil);
	end;

	//***********************************************************
	constructor TobjTree.create(pb_auto_free_Objs: boolean; ps_Key: string; po_obj: Tobject);
	begin
		inherited create;
		
		fs_key:= ps_Key;
		fo_value:= po_obj;
		cb_deleted:=false;
		co_left:=nil;
		co_right :=nil;
		cb_auto_free_objs := pb_auto_free_Objs;
		cb_initialised := (ps_key<>	''); 
	end;

	//###########################################################
	//# public
	//###########################################################
	procedure TobjTree.Keys(po_list: Tstringlist);
	begin
		if (co_left <> nil) then
			co_left.Keys(po_list);
		po_list.add(fs_key);
		if (co_right <> nil) then
			co_right.Keys(po_list);
	end;

	//***********************************************************
	procedure TobjTree.deleteKey(ps_key:string);
	begin
		//TODO
		//get the node
		//remember its left and right subnodes
		//delete the node from its parent
		//add left and right back
		//remove from list of known keys
	end;
	
	//###########################################################
	//# private
	//###########################################################
	function TobjTree.pr_get_object(ps_key:string):Tobject;
	var
		i_sign: TValueSign;
	begin
		result := nil;
		i_sign := Sign(CompareStr(ps_key, fs_key));
		case i_sign of
			0:	result := fo_value;
			-1: result := pr_get_object_from(ps_key, co_left);
			1: result := pr_get_object_from(ps_key, co_right);
		end;

	end;

	//***********************************************************
	function TobjTree.pr_get_object_from(ps_key:string; po_tree:tobjtree): tobject;
	begin
		result := nil;
		if (po_tree <> nil) then
			result := po_tree.Objects[ps_key];
	end;

	//***********************************************************
	procedure TobjTree.pr_set_object_on(ps_key:string; po_obj: tobject; var po_tree: TobjTree);
	begin
		if (po_tree = nil) then
			po_tree := TobjTree.create(cb_auto_free_objs,ps_key, po_obj)
		else
			po_tree.Objects[ps_key] := po_obj;
	end;

	//***********************************************************
	procedure TobjTree.pr_set_object(ps_key:string; po_obj: tobject);
	var
		i_sign: TValueSign;
	begin
		i_sign := Sign(CompareStr(ps_key, fs_key));

		//-------------------------------------------
		if (i_sign = 0) or (not cb_initialised) then
		begin
			if (not cb_initialised) then
			begin
				fs_key := ps_key;
				cb_initialised := true;
			end;

			if (fo_value <> nil) and (cb_auto_free_objs) then
			begin
				fo_value.Free;
				fo_value := nil;
			end;

			fo_value := po_obj;

			exit;
		end;

		//------------ left or right
		case i_sign of
			0:; //handled above
			-1:	pr_set_object_on(ps_key, po_obj, co_left);
			1:		pr_set_object_on(ps_key, po_obj, co_right);
		end;
	end;
(*
	$History: objtree.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/classes
 * 
 * *****************  Version 9  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/classes
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 8  *****************
 * User: Administrator Date: 23/05/04   Time: 16:55
 * Updated in $/code/paglis/classes
 * rendered remembered balls
 * 
 * *****************  Version 7  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
 * 
 * *****************  Version 6  *****************
 * User: Sunil		  Date: 1/03/03    Time: 6:12p
 * Updated in $/paglis/classes
 * ADDED COMMENTS AND METHOD TO GET KEYS
 * 
 * *****************  Version 5  *****************
 * User: Sunil		  Date: 1/02/03    Time: 11:00p
 * Updated in $/paglis/classes
 * first working version
 * 
 * *****************  Version 4  *****************
 * User: Sunil		  Date: 1/02/03    Time: 7:03p
 * Updated in $/paglis/classes
 * moved sourcesafe history to bottom
 *
 * *****************  Version 3  *****************
 * User: Sunil		  Date: 1/02/03    Time: 6:59p
 * Updated in $/paglis/classes
 * added new constructor
*)
end.


