unit sparselist;

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
(* $Header: /PAGLIS/classes/sparselist.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//


//alternative to tobjectlist, uses arrays for faster access to list items
//uses buckets of tobject pointers which are only allocated when something
//is placed in the bucket. Tlist uses a continguous block of memory. The buckets
//here are allocated separately so allocate small chunks of memory.
interface
	uses contnrs,sysutils;
const
	SPARSELIST_ARRAY_SIZE = 200;
type
	ESparseListError = class (Exception);

	RLastAccessed = record
		exists: boolean;
		index: longint;
		depth: integer;
		Obj: tobject;
	end;

	TSparseList = class
	private
		c_data: array[0..SPARSELIST_ARRAY_SIZE-1] of tobject;
		f_fromIndex, f_toIndex:longint;
		c_owns_objects:boolean;
		c_next : TSparseList;
		c_last_Accessed: RLastAccessed;

		function pr_get(pi_index:longint):tobject;
		procedure pr_set(pi_index:longint; po_obj:tobject);
		procedure pr_init;
		function pr_get_count:longint;
	protected
		function pt_get(pi_depth: integer; pl_index: longint): tobject;
		function pt_set(pi_depth: integer; pl_index: longint; po_obj:tobject):boolean;
		procedure pt_OnClear; virtual;
		procedure pt_OnDestroyItem; virtual;
	public
		constructor create(pb_owns_objects:boolean); 
		destructor destroy;override;
		function add(obj:Tobject):longint;
		procedure clear;
		function get_non_nil_index(non_nil_index: longint):longint;
		procedure delete_non_nil(delete_index: longint);


		property Items[index:longint]:Tobject read pr_get write pr_set; default;
		property FromIndex: longint read f_fromIndex;
		property ToIndex: longint read f_toIndex;
		property hasObjects: boolean read c_last_Accessed.exists;
		property Count:longint read pr_get_count;
	end;

implementation

	//################################################################################
	// CONSTRUCTORS
	//################################################################################
	//********************************************************************************
	constructor TSparseList.create(pb_owns_objects:boolean);
	begin
		inherited create;
		c_owns_objects := pb_owns_objects;
		pr_init;
	end;

	//********************************************************************************
	destructor TSparseList.destroy;
	begin
		clear;
		inherited;
	end;

	//################################################################################
	// PUBLICS
	//################################################################################
	function TSparseList.add(obj:tobject): longint;
	begin
		Items[f_toIndex+1] := obj;
		result := f_toIndex;
	end;

	//********************************************************************************
	procedure TSparseList.clear;
	var
		index:Longint;
		obj: tobject;
	begin
		if assigned(c_next) then begin
			c_next.Free;
			c_next := nil;
		end;

		if (hasobjects) then
			if (c_owns_objects) then
				for index := 0 to SPARSELIST_ARRAY_SIZE-1 do
				begin
					obj := c_data[index];
					if obj <> nil then begin
						obj.Free;
						c_data[index] := nil;
					end;
				end;
		pt_OnClear;
		pr_init;
	end;

	//################################################################################
	// PRIVATES
	//################################################################################
	procedure TSparseList.pr_init;
	var
		index:longint;
	begin
		f_fromIndex := 0;
		f_toIndex := 0;
		c_next := nil;
		c_last_Accessed.Obj := nil;
		c_last_Accessed.exists := false;

		for index := 0 to SPARSELIST_ARRAY_SIZE-1 do
			c_data[index] := nil;
	end;

	//********************************************************************************
	function TSparseList.pr_get(pi_index:longint):tobject;
	begin
		if not hasobjects then
			result := nil
		else
			result := pt_get( pi_index div SPARSELIST_ARRAY_SIZE, pi_index mod SPARSELIST_ARRAY_SIZE);
	end;

	//********************************************************************************
	procedure TSparseList.pr_set(pi_index:longint; po_obj:tobject);
	var
		added, wasfirst:boolean;
	begin
		wasfirst := not hasObjects;		//was this the first

		added := pt_set( pi_index div SPARSELIST_ARRAY_SIZE, pi_index mod SPARSELIST_ARRAY_SIZE, po_obj);
		if added then
		begin
			if wasfirst then begin
				f_fromIndex := pi_index;
				f_toIndex := pi_index;
			end else begin
				if pi_index < f_fromIndex then f_fromIndex := pi_index;
				if pi_index > f_toIndex then f_toIndex := pi_index;
			end;
		end;
	end;


	//################################################################################
	// protected
	//################################################################################
	procedure TSparseList.pt_OnDestroyItem;
	begin
	end;

	//********************************************************************************
	procedure TSparseList.pt_OnClear;
	begin
	end;

	//********************************************************************************
	function TSparseList.pt_get(pi_depth: integer; pl_index: longint): tobject;
	var
		obj: tobject;
	begin
		//was there a cached item - if not empty list.
		if (not hasobjects)then
		begin
			result := nil;
			exit;
		end;

		//get the cached item
		if (hasobjects and (pl_index=c_last_Accessed.index) and(pi_depth = c_last_Accessed.depth) ) then
		begin
			result := c_last_Accessed.Obj;
			exit;
		end;

		//find item in appropriate chunk 
		if (pi_depth = 0) then
			obj := c_data[pl_index]
		else
			begin
				if c_next = nil then
					obj := nil
				else
					obj := c_next.pt_get(pi_depth-1,pl_index);
			end;

		//remember the last accessed item
		c_last_Accessed.Obj := obj;
		c_last_accessed.index := pl_index;
		c_last_accessed.depth := pi_depth;
		c_last_Accessed.exists := true;

		//----------------------------------------------
		result := obj;
	end;


	//********************************************************************************
	function TSparseList.pt_set(pi_depth: integer; pl_index: longint; po_obj:tobject):boolean;
	var
		existing: tobject;
		added:boolean;
	begin
		added := false;
		//remember the last accessed for read cache
		c_last_Accessed.exists := true;
		c_last_accessed.Obj := po_obj;
		c_last_accessed.index := pl_index;
		c_last_accessed.depth := pi_depth;


		//add to this chunk
		if pi_depth = 0 then
			begin
				existing := c_data[pl_index];
				if (existing <> nil) and c_owns_objects then begin
					existing.free;
					c_data[pl_index] := nil;
				end	else
					added := true;
				c_data[pl_index] := po_obj;
			end
		else
			begin
				if c_next = nil then c_next := TSparseList.create(c_owns_objects);
				added := c_next.pt_set(pi_depth-1, pl_index, po_obj);
			end;

		result := added;
	end;


	{********************************************************}
	function TSparseList.get_non_nil_index(non_nil_index: longint):longint;
	var
		counter,item_index:longint;
	  item:pointer;
	begin
		counter := 0;
		for item_index := fromIndex to toINdex do
	  begin
		item := items[item_index];
			if item <> nil then
			begin
			if counter = non_nil_index then
			  begin
				  result := item_index;
				exit;
			  end;
			  inc( counter);
			end;
	  end;

	  raise ESparseListError.Create('non_nil item not found')
	end;

	//*******************************************************}
	procedure TSparseList.delete_non_nil(delete_index: longint);
	var
		item_index:longint;
	begin
		item_index := get_non_nil_index(delete_index);



	  items[item_index] := nil;
	  if items[item_index] <> nil then
		raise ESparseListError.Create('delete_non_nil failed: pointer non nil');
	end;

	//*******************************************************}
	function TSparseList.pr_get_count:longint;
	begin
		result := 0;
		if not hasobjects then exit;

		result := f_toIndex - f_fromIndex +1; 
	end;

	
	(*
		$History: sparselist.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/classes
 * 
 * *****************  Version 11  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/classes
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 10  *****************
 * User: Administrator Date: 2/01/05    Time: 10:13a
 * Updated in $/code/paglis/classes
 * fixing memory leaks
 * 
 * *****************  Version 9  *****************
 * User: Administrator Date: 1/01/05    Time: 11:17p
 * Updated in $/code/paglis/classes
 * parameter to create sparselist.create now mandatory
 * 
 * *****************  Version 8  *****************
 * User: Administrator Date: 6/12/04    Time: 11:47p
 * Updated in $/code/paglis/classes
 * reuses peoperty hasObjects
 * 
 * *****************  Version 7  *****************
 * User: Admin        Date: 16/06/03   Time: 22:51
 * Updated in $/code/paglis/classes
 * 
 * *****************  Version 6  *****************
 * User: Sunil        Date: 7-04-03    Time: 11:06p
 * Updated in $/code/paglis/classes
 * added comment
 * 
 * *****************  Version 5  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
 * 
 * *****************  Version 4  *****************
 * User: Sunil		  Date: 25-01-03   Time: 11:28p
 * Updated in $/paglis/classes
 * count was returned incorrectly
 * 
 * *****************  Version 3  *****************
 * User: Sunil		  Date: 1/06/03    Time: 12:14a
 * Updated in $/paglis/classes
 * removed pointers from sparselist - all works AOK
 *
 * *****************  Version 2  *****************
 * User: Sunil		  Date: 1/05/03    Time: 11:17p
 * Updated in $/paglis/classes
 * removed pointers from sparselist
	*)

end.



