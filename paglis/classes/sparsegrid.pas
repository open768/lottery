unit sparsegrid;

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
(* $Header: /PAGLIS/classes/sparsegrid.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//

interface
uses sparselist;

type

	TSparseGrid = class(Tsparselist)
	private
		f_colFromIndex, f_coltoindex:longint;
		function pr_get_cell(piRow,piCol:longint): Tobject;
		procedure pr_set_cell(piRow,piCol:longint; poCell: Tobject);
		function prGetRowFromIndex:longint ;
		function prGetRowToIndex:longint ;
	public
		property Cells[row,col:longint]:Tobject read pr_get_cell write pr_set_cell; default;
		property rowFromIndex:longint read prGetRowFromIndex;
		property rowToIndex: longint read prGetRowToIndex;
		property colFromIndex:longint read f_colFromIndex;
		property colToIndex:longint read f_coltoindex;

		constructor create;
	end;

implementation
	//*******************************************************************************
	constructor TSparseGrid.create;
	begin
		inherited create(true);
		f_colFromIndex := 0;
		f_coltoindex := 0;
	end;

	//*******************************************************************************
	function TSparseGrid.pr_get_cell(piRow,piCol:longint): Tobject;
	var
		oCell: Tobject;
		oRow: TSparseList;
	begin
		ocell := nil;
		
		oRow := tsparselist( items[pirow] );
		if assigned(orow) then
			ocell := orow.Items[picol];

		result := oCell;
	end;

	//*******************************************************************************
	procedure TSparseGrid.pr_set_cell(piRow,piCol:longint; poCell: Tobject);
	var
		oRow: TSparseList;
	begin
		oRow := tsparselist( items[pirow] );
		if not assigned(orow) then begin
			oRow := TSparseList.create(true);
			items[piRow] := oRow;
		end;

		if picol > f_coltoindex then f_coltoindex := piCol;
		if picol < f_colfromindex then f_colfromindex := piCol;

		orow.Items[picol] := poCell;
	end;

	//*******************************************************************************
	function TSparseGrid.prGetRowFromIndex:longint ;
	begin
		result := FromIndex;
	end;

	//*******************************************************************************
	function TSparseGrid.prGetRowToIndex:longint ;
	begin
		result := toIndex;
	end;
//
//#################################################################
(*
	$History: sparsegrid.pas $
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
 * User: Administrator Date: 1/01/05    Time: 11:17p
 * Updated in $/code/paglis/classes
 * parameter to create sparselist.create now mandatory
 * 
 * *****************  Version 2  *****************
 * User: Administrator Date: 5/12/04    Time: 5:36p
 * Updated in $/code/paglis/classes
 * added properties
 * 
 * *****************  Version 1  *****************
 * User: Administrator Date: 5/12/04    Time: 5:10p
 * Created in $/code/paglis/classes
*)
//#################################################################
//

end.

