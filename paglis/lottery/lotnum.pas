unit lotnum;
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
(* $Header: /PAGLIS/lottery/lotnum.pas 5     12/06/05 22:41 Sunil $ *)
//****************************************************************
//


interface
	uses lotrules, sysutils,classes,intgrid, inifile,lottype, intlist, lotnumdata;
type
	TLotteryNumbersEvent = procedure(row:word) of object;
	TLotteryNUmbersException = Class(Exception);

	TLotteryNumbers = class(TLotteryNumberData)
	private
		f_rules: string;
		f_bonus_count: word;
		f_sections, f_captions: TstringList;
		f_draw_rules: TLotteryRules;
		f_processed_row_event: TLotteryNumbersEvent;
		f_Minimum_Match_To_Win: integer;
		f_DataFile:string;
		f_columns:byte;
		f_bonus_overlaps: boolean;
		f_url:String;
		f_get_status: boolean;
		f_sort_bonus: boolean;


		function pr_get_current_set_name:string;

		procedure pr_set_set_name(psValue:string);
		procedure pr_get_set_names;
		function pr_get_draw_date( draw_num: word): TdateTime;

		procedure pr_notify_processed_row(row:word);
		function pr_compare_bitmap_rows(grid:TintegerGrid; draw1,draw2:word): word;
		function pr_get_draw_bitmap( draw_number:word): Tintlist;
		function pr_getSetName:string;
	public

		constructor Create;
		destructor Destroy; override;

		function get_frequencies:TIntList;
		function get_occurances(DrawInterval:byte; SameColumn:Boolean): TIntegerGrid;
		function get_all_draw_matches: TIntegerGrid;

		function get_draw(draw_number:word; include_bonus:Boolean):Tintlist;
		function get_sum(draw_number:word):word;
		function get_average(draw_number:word):real;
		function get_mean(draw_number:word):real;
		function get_non_bonus_count: word;
		function get_how_many_draws: word;
		procedure count_even_odds(draw_number:word; var evens, odds:word);
		procedure load;
		procedure save;
		function get_draw_num(date_string: string): word; overload;
		function get_draw_num(draw_date:tdatetime):word; overload;


		property DrawDate[ draw_number:word]: TdateTime read	pr_get_draw_date;
		property Numbers;
		property StartNumber;
		property EndNumber;
		property LastDraw;
		property HowManyDraws: word read get_how_many_draws;
		property SetName: string read pr_getSetName write pr_set_set_name;
		property SetNames: TStringList read f_sections;
		property Captions:Tstringlist read  f_captions;
		property NonBonusCount: word read get_non_bonus_count;
		property BonusCount:word read f_bonus_count;
		property DataFile:string read f_DataFile write f_DataFile;
		property OnProcessedRow: TLotteryNumbersEvent read f_processed_row_event write f_processed_row_event;
		property MinumumMatchToWin: integer read f_Minimum_Match_To_Win write f_Minimum_Match_To_Win;
		property TicketColumns:byte read f_columns;
		property NInDraw;
		property BonusOverlaps: boolean read f_bonus_overlaps;
		property FirstDraw;
		property URL:string read f_url;
		property GetStatus:boolean read f_get_status;
		property SortBonus: boolean read f_sort_bonus;
	end;

implementation
uses
	inisection, misclib,  miscstrings, translator;

const
	DEFAULT_COLUMNS = 5;
	LOTNUM_INI_FNAME = 'LOTNUM3.INI';
	LOTNUM_SETINGS_SECTION = 'settings';
	LOTNUM_DEFAULT_ENTRY = 'default';
	LOTNUM_NAMES_SECTION = 'number sets';

	LOTNUM_HOW_MANY_ENTRY = 'how many';
	LOTNUM_START_NUMBER_ENTRY = 'number start';
	LOTNUM_END_NUMBER_ENTRY = 'number end';
	LOTNUM_CAPTIONS_ENTRY = 'captions';
	LOTNUM_DEFAULT_SETNAME =  'UK Lottery';
	LOTNUM_DRAWDATE_RULES = 'draw date rules';
	LOTNUM_BONUS_ENTRY = 'bonus';
	LOTNUM_BONUS_OVERLAPS_ENTRY = 'bonus overLaps';
	LOTNUM_MATCH_TO_WIN = 'matches to win';
	LOTNUM_DATAFILE_ENTRY = 'Locator';
	LOTNUM_FIRST_DRAW_ENTRY = 'first_draw';
	LOTNUM_URL_ENTRY = 'url';
	LOTNUM_COLUMNS_ENTRY = 'columns';
	LOTNUM_SORT_BONUS_ENTRY = 'sortbonus';
	LOTNUM_NUMBERS_IN_DB_ENTRY = 'numindb';
	DATA_IN_THIS_FILE = 'this';

	

//######################################################################
//######################################################################
constructor TLotteryNumbers.Create;
begin
	inherited create;

	f_captions := Tstringlist.create;
	f_draw_rules := TLotteryRules.create;
	f_Minimum_Match_To_Win := 3;
	f_DataFile := DATA_IN_THIS_FILE;
	f_columns:=DEFAULT_COLUMNS;
	f_bonus_overlaps := false;
	f_url := '';

	//-----------------------------------------
	pr_get_set_names;
	name :=	pr_get_current_set_name;
	clear;
	load;
	f_get_status := true;
end;

//**********************************************************************
destructor TLotteryNumbers.Destroy;
begin
	if assigned (f_sections) then	f_sections.free;
	if assigned(f_captions) then f_captions.free;
	if assigned(f_draw_rules) then f_draw_rules.free;

	inherited destroy;
end;


//**********************************************************************
function TLotteryNumbers.get_draw(draw_number:word; include_bonus: boolean):Tintlist;
var
	list: Tintlist;
	index, end_index:integer;
begin
	list := TintList.create;
	end_index := NInDraw ;
	if not include_bonus then
		end_index := NInDraw - f_bonus_count;

	for index := 1 to end_index do
		list.bytevalue[index] := Numbers[draw_number, index];
	result := list;
end;


//**********************************************************************
function TLotteryNumbers.pr_get_draw_bitmap( draw_number:word): Tintlist;
var
	draw, draw_bitmap: Tintlist;
	index, bmp_slot, bmp_bit: integer;
	number:byte;
	bit_template, bit_result: word;
  listvalue, newValue:word;

begin
	draw_bitmap := TIntlist.create;
		draw_bitmap.noExceptionOnGetError := true;

	draw := get_draw(draw_number,false);

	//----------------------------------------------------------------
	for index :=draw.fromIndex to draw.toIndex do
	begin
		number := draw.byteValue[index];
		bmp_slot := number div 16;
		bmp_bit := number mod 16;

		bit_template := 1;
		bit_result := bit_template shl bmp_bit;
		listvalue :=draw_bitmap.wordvalue[bmp_slot];
		newValue := listvalue or bit_result;

		draw_bitmap.wordvalue[bmp_slot] := newValue ;
	end;


	//----------------------------------------------------------------
	draw.free;
	result := draw_bitmap
end;


//**********************************************************************
function TLotteryNumbers.pr_get_draw_date( draw_num: word): TdateTime;
begin
	result := f_draw_rules.get_draw_date( draw_num);
end;

//**********************************************************************
function TLotteryNumbers.get_draw_num( date_string: string): Word;
begin
	result := f_draw_rules.get_draw_number( date_string);
end;

//**********************************************************************
function TLotteryNumbers.get_draw_num( draw_date: TdateTime ): word;
begin
	result := f_draw_rules.get_draw_number_from_date( draw_date);
end;


function TLotteryNumbers.get_non_bonus_count: word;
begin
	result := NInDraw - f_bonus_count;
end;

//######################################################################
//######################################################################
procedure TLotteryNumbers.load;
var
	ini_file: TIniFile;
	captions:string;
begin
	//------------------initialise--------------------------
	clear;

	ini_file := Tinifile.create(LOTNUM_INI_FNAME);
	try
		try
			with ini_file do
			begin
				f_DataFile := read(SetName, LOTNUM_DATAFILE_ENTRY, DATA_IN_THIS_FILE );
				if f_DataFile <> DATA_IN_THIS_FILE then
				begin
					ini_file.Free;
					ini_file := Tinifile.create(f_DataFile);
				end;

				EndNumber := read(setname, LOTNUM_END_NUMBER_ENTRY, 49 );
				startNumber := read(SetName, LOTNUM_START_NUMBER_ENTRY, 1 );
				nindraw  := read(SetName, LOTNUM_HOW_MANY_ENTRY, MAX_DRAWN_BALLS );
				captions := read(SetName, LOTNUM_CAPTIONS_ENTRY, '' );
				if assigned(f_captions) then f_captions.free;
				f_captions := g_miscstrings.split(captions, ',');
				f_rules := read(SetName, LOTNUM_DRAWDATE_RULES, '');
				f_draw_rules.parse_rules(f_rules);
				f_bonus_count := read(SetName, LOTNUM_BONUS_ENTRY, 0 );;
				f_bonus_overlaps := read(SetName, LOTNUM_BONUS_OVERLAPS_ENTRY, false);
				f_Minimum_Match_To_Win := read( SetName, LOTNUM_MATCH_TO_WIN,3);
				f_columns := read(SetName, LOTNUM_COLUMNS_ENTRY, DEFAULT_COLUMNS );
				FirstRecordedDraw := read(SetName, LOTNUM_FIRST_DRAW_ENTRY, 1 );
				f_url := read (SetName, LOTNUM_URL_ENTRY, '');
				f_sort_bonus := read (SetName, LOTNUM_SORT_BONUS_ENTRY, true );
				NumbersInDb := read (SetName, LOTNUM_NUMBERS_IN_DB_ENTRY, false );

				pt_load_from_ini(ini_file);
			end;
		except
			g_misclib.alert(LocalString('error in ini file - unable to load all numbers'));
			raise;
			exit;
		end;

	finally
		//------------------throw away resources-----------------
		ini_file.Free;
	end;
end;

//**********************************************************************
procedure TLotteryNumbers.save;
var
  ini_file: Tinifile;
	packed_captions:string;
begin
	ini_file := Tinifile.create(LOTNUM_INI_FNAME);

	with ini_file do
	begin
		Delete_Section(SetName);

		//write where the data is located
		write(SetName, LOTNUM_DATAFILE_ENTRY, f_DataFile );
		if f_DataFile <> DATA_IN_THIS_FILE then
		begin
			ini_file.Free;
			ini_file := Tinifile.create(f_DataFile);
			Delete_Section(SetName);
		end;

		//write meta information
		write(SetName, LOTNUM_END_NUMBER_ENTRY, EndNumber );
		write(SetName, LOTNUM_START_NUMBER_ENTRY, startnumber );
		write(SetName, LOTNUM_HOW_MANY_ENTRY, nindraw );
		packed_captions := g_miscstrings.join(f_captions, ',');
		write(SetName, LOTNUM_CAPTIONS_ENTRY, packed_captions );
		write(SetName, LOTNUM_DRAWDATE_RULES, f_rules );
		write(SetName, LOTNUM_BONUS_ENTRY, f_bonus_count);
		write(SetName, LOTNUM_MATCH_TO_WIN, f_Minimum_Match_To_Win);
		write(SetName, LOTNUM_COLUMNS_ENTRY, f_columns);
		write(SetName, LOTNUM_BONUS_OVERLAPS_ENTRY, f_bonus_overlaps);
		write(SetName, LOTNUM_FIRST_DRAW_ENTRY, FirstRecordedDraw );
		write(SetName, LOTNUM_URL_ENTRY, f_url );
		write(SetName, LOTNUM_SORT_BONUS_ENTRY, f_sort_bonus );
		write(SetName, LOTNUM_NUMBERS_IN_DB_ENTRY, numbersinDb );

		//--------------write out the numbers in database --------------
		pt_save_to_ini(ini_file);
  end;
  ini_file.free;
end;

//**********************************************************************
Procedure TLotteryNumbers.pr_set_set_name(psValue:string);
var
	ini_file:Tinifile;
begin
	if (psValue <> Name) then
	begin
		psValue := g_miscstrings.make_alphanumeric(psValue);

		ini_file := Tinifile.create(LOTNUM_INI_FNAME);
		ini_file.write(LOTNUM_SETINGS_SECTION, LOTNUM_DEFAULT_ENTRY, psValue);
		ini_file.free;

		Name := psValue;
		clear;
		load;
	end;

end;

//**********************************************************************
Procedure TLotteryNumbers.pr_get_set_names;
var
	ini_file: TIniFile;
  names_section: TIniFileSection;
  names:tstringlist;
begin
	//----------- clear existing f_sections ---------
	if assigned(f_sections) then
		f_sections.clear
	else
		f_sections := TStringLIst.Create;

	//-----------load sections -----------------------
	ini_file := Tinifile.create(LOTNUM_INI_FNAME);
	names_section := ini_file.sections[LOTNUM_NAMES_SECTION];
	names := names_section.getkeys;
	f_sections.AddStrings( names);
	names.free;
	ini_file.free;
end;


//**********************************************************************
function TLotteryNumbers.pr_get_current_set_name:string;
var
	ini_file: TIniFile;
begin
	ini_file := Tinifile.create(LOTNUM_INI_FNAME);
	result := ini_file.read(LOTNUM_SETINGS_SECTION, LOTNUM_DEFAULT_ENTRY, LOTNUM_DEFAULT_SETNAME);
	ini_file.free;
end;


//######################################################################
//######################################################################

//**********************************************************************
function TLotteryNumbers.get_frequencies:TIntList;
var
	frequencies :TIntList;
	number,col:byte;
	row, current:word;
begin
	current := 0;

	frequencies := TIntList.create;
	frequencies.noExceptionOnGetError := true;

	for row:= FirstDraw to LastDraw do
	begin
		for col := 1 to NInDraw do
		begin
			number := Numbers[row,col];
			frequencies.Wordvalue[number] := frequencies.wordvalue[number] +1;
			inc(current);
		end;
		pr_notify_processed_row(current);
	end;

	result :=   frequencies;
end;


//**********************************************************************
function TLotteryNumbers.get_occurances(DrawInterval:byte; SameColumn:Boolean): TIntegerGrid;
var
	col1, col2, num1, num2, tmp:byte;
	occurances:TIntegerGrid;
	draw1, draw2, last_value:word;
begin
	if SameColumn and (DrawInterval=0) then
	begin
		raise TLotteryNUmbersException.Create('Cant get Occurances for same draw when lookig in same column');
	end;


	occurances := TIntegerGrid.create ;
	occurances.NoExceptionOnGetError := true;

	//work through numbers , populating scatter chart
	for draw1:= FirstDraw to LastDraw do //.
	begin
		//-------get next draw number - abort if off end
		draw2 := draw1 + DrawInterval;
		if draw2 > Lastdraw then break;

		//-------get and process pairs ---------
		for col1:=1 to NInDraw do  //..
		begin
			num1 := Numbers[draw1,col1];
			if not f_get_status then continue;

			if SameColumn then //...
				//only need to process same column
				begin
				  num2 := Numbers[draw2,col1];
				  if not f_get_status then continue;

				  last_value := occurances.wordValue[num1, num2];
				  if not occurances.Status then last_value :=0;
				  occurances.wordValue[num1, num2] := last_value+1;
				end
			else 			  //...
				//process other numbers in draw.
				for col2:= 1 to nInDraw do
				begin
					//- - - - - - - - if draw numbers are same dont repeat columns - - - - - -
					if (draw2=draw1) and (col2<=col1) then continue;

					//- - - - - - - - get the 2nd number - - - - - -
					num2 := Numbers[draw2,col2];
					if not f_get_status then continue;

					//- - with same draw number, sort - - - - - - - - - - - -
					if (draw2=draw1)  and (num2 > num1) then //....
					begin
					 tmp := num2;
					 num2 := num1;
					 num1 := tmp;
					end;

					//- - store - - - - - - - - - - - -
					occurances.wordValue[num1, num2] := occurances.wordValue[num1, num2] +1;
				end;   //...
		end; //..

		pr_notify_processed_row(draw1);
	end; //.

	result := occurances;
end;

//**********************************************************************
procedure TLotteryNumbers.pr_notify_processed_row(row:word);
begin
	 if assigned(f_processed_row_event) then
			f_processed_row_event(row);
end;


//**********************************************************************
function TLotteryNumbers.get_all_draw_matches: TIntegerGrid;
var
	draw, draw2, index, n_matches:word;
	DrawBitmap: TintList;
	raw_results, results: TintegerGrid;
	oldValue: word;
begin
	//---------- build bitmap for fast searching for each row and store----------
	raw_results := TintegerGrid.create;
	for draw:= FirstDraw to LastDraw do //.
	begin
		DrawBitmap:= pr_get_draw_bitmap(draw);
		for index := DrawBitmap.fromINdex to DrawBitmap.toINdex do
			raw_results.wordvalue[draw, index] := DrawBitmap.wordValue[index];
		DrawBitmap.free;
		pr_notify_processed_row(draw);
	end;

	raw_results.NoExceptionOnGetError := true;

	//--------- compare each bitmap with every other row ... slow!!!
	results := TintegerGrid.Create;
	results.NoExceptionOnGetError := true;
	for draw:= FirstDraw to LastDraw do //.
	begin
		for draw2:= FirstDraw to LastDraw do //..
		begin
			n_matches := pr_compare_bitmap_rows(raw_results, draw,draw2);
			oldValue := results.wordValue[draw, n_matches];
			inc(oldValue); 
			results.wordValue[draw, n_matches] := oldvalue;
		end;

		pr_notify_processed_row(draw);
	end;

	//-------------------------------------------------------
	raw_results.free;

	result := results;
end;


//**********************************************************************
function TLotteryNumbers.pr_compare_bitmap_rows(grid:TintegerGrid; draw1,draw2:word): word;
var
	col, bmp1, bmp2, bmp3:word;
	matches: word;
begin
	matches := 0;

	for col := grid.fromcolumnindex to grid.tocolumnindex do
	begin
		bmp1 := grid.wordvalue[draw1, col];
		bmp2 := grid.wordvalue[draw2, col];
		bmp3 := bmp1 and bmp2;
		while bmp3 >0 do
		begin
			if (bmp3 and 1) = 1 then
				inc (matches);
			bmp3 := bmp3 shr 1;
		end;
	end;

	result := matches

end;


//**********************************************************************
function TLotteryNumbers.get_sum(draw_number:word):word;
var
	col, sum:word;
  number:byte;
begin
	sum := 0;
	for col := 1 to nInDraw do
	begin
		number := Numbers[draw_number,col];
	sum  := sum + number;
	end;
  result := sum;
end;

//**********************************************************************
function TLotteryNumbers.get_average(draw_number:word):real;
var
	sum:word;
begin
	sum := get_sum(draw_number);
	result := sum /nInDraw;
end;

//**********************************************************************
function TLotteryNumbers.get_mean(draw_number:word):real;
var
	number:byte;
  col:word;
  squared:longint;
begin
	squared := 0;
	for col := 1 to nInDraw do
	begin
		number := Numbers[draw_number,col];
		squared := squared + ( number * number);
	end;
	result := sqrt(squared/nInDraw);
end;

//**********************************************************************
function TLotteryNumbers.get_how_many_draws: word;
begin
	result := LastDraw - FirstDraw + 1;
end;

//**********************************************************************
procedure TLotteryNumbers.count_even_odds(draw_number:word; var evens, odds:word);
var
	col:word;
	number:byte;
begin
	odds:=0;
	evens :=0;

	for col := 1 to nInDraw do
	begin
		number := Numbers[draw_number,col];
		if (number mod 2) = 0 then
			inc (evens)
		else
			inc (odds);
	end;
end;

//**********************************************************************
function TLotteryNumbers.pr_getSetName:string;
begin
	result := name;
end;

//
//####################################################################
(*
	$History: lotnum.pas $
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
 * User: Sunil        Date: 19/02/05   Time: 11:39
 * Updated in $/PAGLIS/lottery
 * split out data part
 *
 * *****************  Version 2  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:45
 * Updated in $/PAGLIS/lottery
 * added skeleton code to convert numbers in database
 * 
 * *****************  Version 18  *****************
 * User: Administrator Date: 9/05/04    Time: 0:12
 * Updated in $/code/paglis/lottery
 * started splitting out into database code
 * 
 * *****************  Version 15  *****************
 * User: Sunil        Date: 7-04-03    Time: 11:07p
 * Updated in $/code/paglis/lottery
 * uses result o return a value
 * 
 * *****************  Version 14  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/lottery
 * added headers and footers
*)
//####################################################################
//
end.



