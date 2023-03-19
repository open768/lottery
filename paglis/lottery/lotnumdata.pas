unit lotnumdata;
//
//****************************************************************
//* Copyright 2003 Paglis Software
//*
//* This copyright notice must be maintained on this source file
//* and all subsequent modified versions.
//*
//* This source code is the intellectual property of
//* Paglis Software and protected by Intellectual and
//* international copyright Law.
//*
//* Contact  http://www.paglis.co.uk/
//*
(* $Header: /PAGLIS/lottery/lotnumdata.pas 5     12/06/05 22:41 Sunil $ *)
//****************************************************************
//

interface

uses
	intgrid, inifile, sysutils;
type
	TLotteryNumberDataException = Class(Exception);

	TLotteryNumberData = class
	private
		c_draw_numbers: TIntegerGrid;
		f_get_status: boolean;
		f_Start_Number, f_End_Number: byte;
		f_N_in_draw: integer;
		f_last_draw:word;
		f_first_recorded_draw: word;
		f_numbers_in_db: boolean;
		f_name: string;
		c_current_draw: word;

		procedure pr_set_number(piDraw:word; piPosition,piValue:byte);
		function pr_get_number(piDraw:word; piPosition:byte): byte;
		function pr_pack_draw_to_string(draw_num:word):string;
	public
		constructor Create;
		destructor Destroy; override;
		procedure clear;

	protected
		property Numbers[draw: word; position:byte]:byte read pr_get_number write pr_set_number;
		property StartNumber: byte read f_Start_Number write f_Start_Number;
		property EndNumber: byte read f_End_Number write f_End_Number;
		property LastDraw: word read f_last_draw;
		property NInDraw: integer read f_N_in_draw write f_N_in_draw;
		property FirstDraw: word read f_first_recorded_draw;
		property NumbersInDb: boolean read f_numbers_in_db write f_numbers_in_db;
		property FirstRecordedDraw: word read f_first_recorded_draw write f_first_recorded_draw;
		property Name: string read f_name write f_name;

		procedure pt_load_from_ini(poIni: Tinifile);
		procedure pt_save_to_ini(poIni: Tinifile);

	end;
const
	LOTNUMDATA_NUMBER_SECTION_SUFFIX = ' Numbers';

implementation
uses
	miscstrings, classes, misclib, language;
const
	LOTNUM_PACKING_DELIMITER = ' ';
	LOTNUM_DB_DRAW_FIELD = 'DrawNum';
	LOTNUM_DB_DATA_FIELD_PREFIX = 'DrawNum';
	LOTNUM_DB_FILEEXTENSION = '.pdb';


//######################################################################
//######################################################################
constructor TLotteryNumberData.Create;
begin
	inherited create;

	c_draw_numbers := TintegerGrid.create;
	c_draw_numbers.NoExceptionOnGetError := true;
	c_current_draw:=0;
end;

//
destructor TLotteryNumberData.Destroy;
begin
	c_draw_numbers.free;
	inherited destroy;
end;

//######################################################################
//# INI data routines
//######################################################################
function TLotteryNumberData.pr_pack_draw_to_string(draw_num:word):string;
var
  col:integer;
  num:byte;
  packed_string:string;
begin
  packed_string := '';
  for col := 1 to f_n_in_draw do
  begin
	 num := numbers[draw_num,col];
	 if f_get_status then
		packed_string := packed_string + inttostr(num) + LOTNUM_PACKING_DELIMITER;
	end;

	result := packed_string;
end;

//**********************************************************************
procedure TLotteryNumberData.pt_save_to_ini(poIni: Tinifile);
var
	sSection, sPacked:string;
	iDraw: word;
begin
	sSection:= f_name + LOTNUMDATA_NUMBER_SECTION_SUFFIX;
	for iDraw := f_first_recorded_draw to f_last_draw do
	begin
		sPacked := pr_pack_draw_to_string(iDraw);
		poini.write(sSection, inttostr(idraw), sPacked);
	end;
end;

//**********************************************************************
procedure TLotteryNumberData.pt_load_from_ini(poIni: Tinifile);
var
	draw_num, col, ball_value:integer;
	drawn,entry: string;
	oList:TstringList;
	sNumber_section: string;
begin
	//------ read all numbers should check that there are no gaps ----------
	sNumber_section := f_name + LOTNUMDATA_NUMBER_SECTION_SUFFIX;
	draw_num := f_first_recorded_draw;

	while true do
	begin
		//- - - - read entry- - - - - -  -
		drawn := poIni.read(snumber_section, inttostr(draw_num), '' );
		if drawn = '' then
		begin
			if draw_num = f_first_recorded_draw then
				g_misclib.alert(LocalString('unable to read details of first draw: #' + inttostr(draw_num) + '#'));
			exit;
		end;

		try
			oList := g_miscstrings.split(drawn, LOTNUM_PACKING_DELIMITER);
			for col := 1 to olist.count do
			begin
				entry := oList.strings[col-1];
				ball_value := strtoint(entry);
				if (ball_value>=StartNumber) and (ball_value <= EndNumber) then
					Numbers[draw_num,col] := ball_value;
			end;
			oList.free;
		except
			g_misclib.alert(LocalString('error converting entry #' + inttostr(draw_num) + '#'));
			exit;
		end;

		//- - - - - - - - - - next entry - - - - - - - - - - -
		inc(draw_num);
	end;	//for

	f_last_draw := draw_num-1;
end;


//######################################################################
//######################################################################
function TLotteryNumberData.pr_get_number(piDraw:word; piPosition:byte): byte;
begin
	result := c_draw_numbers.ByteValue[piDraw,piPosition];
	f_get_status := c_draw_numbers.Status;
end;

//**********************************************************************
procedure TLotteryNumberData.pr_set_number(piDraw:word; piPosition,piValue:byte);
begin
	c_draw_numbers.Bytevalue[piDraw,piPosition] := piValue;
	if piValue < f_start_number then f_start_number	 := piValue;
	if piValue > f_end_number then f_end_number	:= piValue;
  if piPosition > f_n_in_draw then f_n_in_draw  := piPosition;

	if piDraw > f_last_draw then
		f_last_draw := piDraw;
end;

//**********************************************************************
procedure TLotteryNumberData.clear;
begin
	c_draw_numbers.clear;
	f_End_Number := 0;
	f_start_number := 255;
	f_n_in_draw := 0;
	f_last_draw :=0;
end;




//####################################################################
(*
	$History: lotnumdata.pas $
 * 
 * *****************  Version 5  *****************
 * User: Sunil        Date: 12/06/05   Time: 22:41
 * Updated in $/PAGLIS/lottery
 * 
 * *****************  Version 4  *****************
 * User: Sunil        Date: 5/06/05    Time: 1:25
 * Updated in $/PAGLIS/lottery
 * 
 * *****************  Version 3  *****************
 * User: Sunil        Date: 19/02/05   Time: 21:56
 * Updated in $/PAGLIS/lottery
 * checks for database file existence;
 * 
 * *****************  Version 2  *****************
 * User: Sunil        Date: 19/02/05   Time: 11:54
 * Updated in $/PAGLIS/lottery
 * uses sqlmemtable but still not working from database
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 19/02/05   Time: 11:33
 * Created in $/PAGLIS/lottery
*)
//####################################################################
//

end.
