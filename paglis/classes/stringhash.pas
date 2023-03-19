unit stringhash;
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
(* $Header: /PAGLIS/classes/stringhash.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//


//INTERFACE
interface
 uses Windows,classes, hashtable, sparseobjlist, objtree,sysutils;

 type
	TStringHash = class
	private
		f_auto_free_objects: boolean;
		c_buckets: tSparseObjlist;

		function pr_Get(ps_key: string): TObject;
		procedure pr_Put(ps_key: string; po_value: TObject);
		function pr_get_tree(ps_key:string): TobjTree; overload;
		function pr_get_tree(ps_key:string; pb_create:boolean): TobjTree; overload;
	public
		constructor Create;
		destructor  Destroy; override;
		property AutoFreeObjects: Boolean read f_auto_free_objects write f_auto_free_objects;
		property Objects[key:String]: TObject read pr_Get write pr_Put;
		function getKeys: Tstringlist;
		procedure delete(const ps_key:string);
		function exists(const ps_key:string): boolean;
	end;

//IMPLEMENTATION
implementation

uses sparselist;
var
  M_HASH : THashtable;

	//################################################################################
	// CONSTRUCTORS
	//################################################################################
	destructor  TStringHash.Destroy();
	begin
		c_buckets.free;
		inherited Destroy;
	end;

	//********************************************************************************
	constructor TStringHash.Create();
	begin
		inherited create;
		c_buckets := TsparseObjlist.Create(true);
	end;

	//################################################################################
	// PUBLIC
	//################################################################################
	procedure TStringHash.delete(const ps_key:string);
	var
		tree: TobjTree;
	begin
		tree := pr_get_tree(ps_key,false);
		tree.deleteKey(ps_key);
		//todo
	end;

	//################################################################################
	// PRIVATE
	//################################################################################
	function TStringHash.pr_Get(ps_key: string): TObject;
	var
		tree: TobjTree;
	begin
		// get the tree in which our key has been stored;
		tree := pr_get_tree(ps_key);

		// return value at leaf node;
		result := nil;
		if tree <> nil then
			result := tobjtree(tree.Objects[ps_key]);
	end;

	//********************************************************************************
	procedure TStringHash.pr_Put(ps_key: string; po_value: Tobject);
	var
		tree: TobjTree;
	begin
		tree := pr_get_tree(ps_key,true);
		tree.Objects[ps_key] := po_value;
	end;

	//********************************************************************************
	function TStringHash.getKeys: Tstringlist;
	var
		list: TStringList;
		index: longint;
		tree: TobjTree;
	begin
		list := TStringList.Create;
		list.Sorted := true;

		for index := c_buckets.FromIndex to c_buckets.ToIndex do
		begin
			tree := tobjtree(c_buckets.items[index]);
			if (tree <> nil) then
				tree.keys(list);
		end; //for
		result := list;
	end;

	//********************************************************************************
	function TStringHash.pr_get_tree(ps_key:string): TobjTree;
	begin
		result  := pr_get_tree(ps_key,false);
	end;

	//********************************************************************************
	function TStringHash.pr_get_tree(ps_key:string; pb_create:boolean): TobjTree;
	var
		bucketID: Dword;
		tree: TobjTree;
	begin
		//--------get the bucket which contains the hashtree
		bucketID := M_HASH.GetHash(ps_key);
		tree := tobjtree( c_buckets.Items[bucketID]);
		if (tree = nil) and pb_create then
		begin
			tree := TobjTree.create(true);
			c_buckets.Items[bucketID] := tree;
		end;

		result := tree;
	end;

	function TStringHash.exists(const ps_key:string): boolean;
	begin
	end;
//################################################################################
// GLOBAL
//################################################################################
initialization
  M_HASH := THashtable.Create;

finalization
  M_HASH.Free;

  (*
		$History: stringhash.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/classes
 * 
 * *****************  Version 13  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/classes
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 12  *****************
 * User: Administrator Date: 1/01/05    Time: 11:17p
 * Updated in $/code/paglis/classes
 * parameter to create sparselist.create now mandatory
 * 
 * *****************  Version 11  *****************
 * User: Administrator Date: 23/05/04   Time: 16:55
 * Updated in $/code/paglis/classes
 * rendered remembered balls
 * 
 * *****************  Version 10  *****************
 * User: Administrator Date: 9/05/04    Time: 23:54
 * Updated in $/code/paglis/classes
 * renamed a function for consistency
 * 
 * *****************  Version 8  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
 * 
 * *****************  Version 7  *****************
 * User: Sunil		  Date: 2-02-03    Time: 1:26a
 * Updated in $/code/paglis/classes
 * all working again top hole!
 * 
 * *****************  Version 6  *****************
 * User: Sunil		  Date: 9-01-03    Time: 4:34p
 * Updated in $/paglis/classes
 * hashtree returns a sorted list of keys
 * 
 * *****************  Version 5  *****************
 * User: Sunil		  Date: 1/05/03    Time: 11:17p
 * Updated in $/paglis/classes
 * removed pointers from sparselist
 * 
 * *****************  Version 4  *****************
 * User: Sunil		  Date: 1/03/03    Time: 11:07p
 * Updated in $/paglis/classes
 * renamed keys->getkeys
 * 
 * *****************  Version 3  *****************
 * User: Sunil		  Date: 1/03/03    Time: 6:13p
 * Updated in $/paglis/classes
 * ADDED METHOD TO GET KEYS
	*)
end.


