unit Intgrid;
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
(* $Header: /PAGLIS/classes/intgrid.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//


interface
uses
	sparselist, Sysutils, misclib, intlist;

type
	{===================================================================}
	EIntegerGridError = class (Exception);

	{===================================================================}
	TIntegerGrid = Class(TsparseList)
	private
		F_From_column_index, F_to_column_index:word;
		f_status:boolean;

		procedure set_FromTo_Column_Index(pValue:word);
		procedure set_byte_value( pRow,pCol:word; pValue: Byte);
		function get_byte_value( pRow,pCol:word): byte;
		procedure set_word_value( pRow,pCol:word; pValue: word);
		function get_word_value( pRow,pCol:word): word;
		procedure set_int_value( pRow,pCol:word; pValue: integer);
		function get_int_value( pRow,pCol:word): integer;
		procedure set_real_value( pRow,pCol:word; pValue: real);
		function get_real_value( pRow,pCol:word): real;

		function get_rows: word;
		function get_columns( pRow:word): word;
		function get_row(pRow:word; CreateRow:Boolean): TIntList;
		function get_row_data(row:word): Tintlist;

	protected
		procedure pt_Onclear; override;
	public
		NoExceptionOnGetError: boolean;
		constructor Create;
	procedure ColumnInFo(pRow:word; var colFrom, colTo:word);

		property ByteValue[row, col: word]:byte read get_byte_value write set_byte_value ;
		property WordValue[row, col: word]:word read get_word_value write set_word_value ;
		property RealValue[row, col: word]:real read get_real_value write set_real_value ;
		property IntegerValue[row, col: word]:integer read get_int_value write set_int_value ;

		property Rows: word read get_rows;
		property Row[row:word]: Tintlist read get_row_data;
		property Columns[Row:word]: word read get_columns;
		property FromColumnIndex: word read F_From_column_index;
		property ToColumnIndex: word read F_to_column_index;
		property FromIndex;
		property ToIndex;
		property Status: boolean read f_status;
	end;


implementation

{####################################################################
 constructors and destructors
 ####################################################################}
constructor TIntegerGrid.Create;
begin
	inherited Create(true);

	NoExceptionOnGetError := false;
	f_status := true;
	F_From_column_index := 999;
	F_to_column_index:= 0;
end;



{####################################################################
 property (SET)
 ####################################################################}
procedure TIntegerGrid.set_byte_value( pRow,pCol:word; pValue:byte);
var
	row: TIntList;
begin
	row := get_row(pRow, true);
	row.ByteValue[pcol] := pValue;
	set_FromTo_Column_Index(pcol);
end;

{******************************************************************}
procedure TIntegerGrid.set_word_value( pRow,pCol:word; pValue:word);
var
	row: TIntList;
begin
	row := get_row(pRow, true);
	row.WordValue[pcol] := pValue;
	set_FromTo_Column_Index(pcol);
end;

{******************************************************************}
procedure TIntegerGrid.set_int_value( pRow,pCol:word; pValue:integer);
var
	row: TIntList;
begin
	row := get_row(pRow, true);
	row.IntegerValue[pcol] := pValue;
	set_FromTo_Column_Index(pcol);
end;

{******************************************************************}
procedure TIntegerGrid.set_real_value( pRow,pCol:word; pValue:real);
var
	row: TIntList;
begin
	row := get_row(pRow, true);
	row.RealValue[pcol] := pValue;
	set_FromTo_Column_Index(pcol);
end;

{####################################################################
 property (GET)
 ####################################################################}
function TIntegerGrid.get_real_value( pRow,pCol:word):real;
var
	row: TIntList;
begin
	row := get_row(pRow, false);
	if row <> nil then
		begin
			row.noExceptionOnGetError := NoExceptionOnGetError;
			result := row.realvalue[pcol];
			f_status := row.GetStatus;
		end
	else
		result := 0.0;
end;

{******************************************************************}
function TIntegerGrid.get_byte_value( pRow,pCol:word):byte;
var
	row: TIntList;
begin
	row := get_row(pRow, false);
	if row <> nil then
		begin
			row.noExceptionOnGetError := NoExceptionOnGetError;
			result := row.Bytevalue[pcol];
			f_status := row.GetStatus;
		end
	else
		result := 0;
end;

{******************************************************************}
function TIntegerGrid.get_word_value( pRow,pCol:word):word;
var
	row: TIntList;
begin
	row := get_row(pRow, false);
	if row <> nil then
		begin
			row.noExceptionOnGetError := NoExceptionOnGetError;
			result := row.Wordvalue[pcol];
			f_status := row.GetStatus;
		end
	else
		result := 0;
end;

{******************************************************************}
function TIntegerGrid.get_int_value( pRow,pCol:word):integer;
var
	row: TIntList;
begin
	row := get_row(pRow, false);
	if row <> nil then
		begin
			row.noExceptionOnGetError := NoExceptionOnGetError;
			result := row.Integervalue[pcol];
			f_status := row.GetStatus;
		end
	else
		result := 0;
end;


{******************************************************************}
function TIntegerGrid.get_row_data(row:word): Tintlist;
begin
	result := get_row(row,false);
end;

{####################################################################
 publics
 ####################################################################}

{******************************************************************}
procedure TIntegerGrid.ColumnInFo(pRow:word; var colFrom, colTo:word);
var
	row:TIntList;
begin
	row := get_row(prow, false);
	if row = nil then
		begin
			colFrom := 1;
			colTo := 0;
		end
	else
		begin
			colFrom := row.fromINdex;
			colTo := row.ToINdex;
		end;
end;

{******************************************************************}
function TIntegerGrid.get_rows: word;
begin
	result := count;
end;

{******************************************************************}
function TIntegerGrid.get_columns( prow:word): word;
var
	row:TIntList;
begin
	result := 0;
	if prow < count then
	begin
		row := get_row(prow, false);
		if row <> nil then
			result := row.count;
	end;
end;

{******************************************************************}
function TIntegerGrid.get_row(pRow:word; CreateRow:Boolean): TIntList;
var
	obj: TIntList;
begin
	obj := tintlist(items[pRow]);
	if (obj = nil) and (createRow) then
	begin
		obj := TIntList.Create;
		items[pRow] := obj;
	end;

	result := obj;
end;


{******************************************************************}
procedure TIntegerGrid.set_FromTo_Column_Index(pValue:word);
begin
	if pValue < F_From_column_index then
		F_From_column_index := pValue;

	if pValue > F_To_column_index then
		F_To_column_index := pValue;
end;

{******************************************************************}
procedure TIntegerGrid.pt_Onclear;
begin
	F_From_column_index := 999;
	F_to_column_index:= 0;
end;

//
//####################################################################
(*
	$History: intgrid.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/classes
 * 
 * *****************  Version 6  *****************
 * User: Administrator Date: 13/01/05   Time: 11:58p
 * Updated in $/code/paglis/classes
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
*)
//####################################################################
//
end.

