unit miscEncode;

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
(* $Header: /PAGLIS/classes/miscEncode.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//

interface
uses
	wintypes, reg;

type
	tMiscEncode = class
    private
		function pr_anybase_decode(const encoded: string; bits_to_move:byte): longint;
		function pr_anybase_encode(number:longint;bits_to_move:byte;mask:byte):string;
	public
		function hex_encode(a_string:string):string; overload;
		function hex_to_string(hex_string:string):string;
		function hex_to_int(hex_string:string):longint;
		function binary_string(number:longint):string;
		function HTTPEncode(const Astr:string): string;
		function HTTPDecode(const Astr:string): string;

		function hex(number:longint):string;
		function hex64(number:longint):string;
		function dehex64(encoded: string):longint;
		function get_serial_number: string;

	end;
var
	g_miscencode :tMiscEncode;

implementation
uses
	sysutils, dialogs, miscstrings, translator;
const
	REG_ROOT_KEY = 'Software\Paglis';
	ANYBASE_SEQUENCE = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz[]{}';


//*********************************************************************
function tMiscEncode.pr_anybase_decode(const encoded: string; bits_to_move:byte): longint;
var
	index:integer;
	accumulator, ch_pos: longint;
	ch: char;
begin
	accumulator := 0;

	for index := 1 to length(encoded) do
	begin
		ch := encoded[index];
		accumulator :=accumulator shl bits_to_move;
		ch_pos := pos(ch, ANYBASE_SEQUENCE) -1;
		accumulator := accumulator or ch_pos;
	end;
	result := accumulator;
end;

function tMiscEncode.pr_anybase_encode(number:longint;bits_to_move:byte;mask:byte):string;
var
	tmp,pos: longint;
	fragment , sequence_copy:string;
	out_string:string;
begin
	out_string :='';
	if number = 0 then
		out_string := '0';

	sequence_copy := ANYBASE_SEQUENCE;

	tmp := number;
	while tmp >0 do
	begin
		pos := (tmp and mask) +1;
		fragment :=  sequence_copy[pos];
		out_string :=   fragment+ out_string;
		tmp := tmp shr bits_to_move;
	end;

	result := out_string ;
end;

//*********************************************************************
function tMiscEncode.binary_string(number:longint):string;
begin
	result := pr_anybase_encode(number,1,1);
end;

//*********************************************************************
function tMiscEncode.hex(number:longint):string;
begin
	result := pr_anybase_encode(number,4,15);
end;

function tMiscEncode.hex64(number:longint):string;
begin
	result := pr_anybase_encode(number,6,63);
end;

function tMiscEncode.dehex64(encoded: string):longint;
begin
	result := pr_anybase_decode(encoded,6);
end;

//*********************************************************************
function tMiscEncode.hex_encode(a_string:string):string;
var
	string_length, index:integer;
	char_code:byte;
	out_string, hex_code:string;
begin
  //--------------------initialise------------------------
  out_string := '';
	string_length := length(a_string);

  //-------- walk through input string turning to hex-----
  for index := 1 to string_length do
  begin
	  char_code := ord ( a_string[index]);
	  hex_code := hex(char_code) ;
	 hex_code := g_miscstrings.left_pad_string(hex_code,'0',2);
	  out_string := out_string + hex_code;
	end;

  result := out_string;
end;

//*********************************************************************
function tMiscEncode.hex_to_string(hex_string:string):string;
var
  string_length, char_code, n_codes, code_index, pos:integer;
  tuple,out_string:string;
begin
  //--------------------initialise------------------------
  out_string := '';
  string_length := length(hex_string);
  n_codes := string_length div 2;

  //-------- walk through input string turning to hex-----
  for code_index := 1 to n_codes  do
  begin
	 pos := (2*code_index) -1;
	 tuple := hex_string[pos] + hex_string[pos+1];
	 char_code := hex_to_int(tuple);
	 out_string := out_string + chr(char_code);
  end;

  hex_to_string := out_string;
end;

//*********************************************************************
function tMiscEncode.hex_to_int(hex_string:string):longint;
var
  upper_string:string;
  hex_char:char;
  string_length, hex_code,index:integer;
	out_value:longint;
begin
	//------------ initialise --------------
	upper_string := uppercase(hex_string);
	string_length := length(hex_string);
	out_value := 0;

	//------------ work through string --------------
	for index := 1 to string_length do
	begin
	  hex_char := upper_string[index];
	  hex_code := pos(hex_char, ANYBASE_SEQUENCE)-1;
	  out_value := out_value shl 4;
	  out_value := out_value or  hex_code;
	end;

  hex_to_int := out_value;
end;

//*********************************************************************
function tMiscEncode.HTTPDecode(const AStr: string): string;
 var
  p:integer;
  buf:string;
 begin
  result := '';
  p := 1;
  while p <= length(Astr) do
   begin
	case Astr[p] of
	 '+':buf := buf + ' ';
	 '%':begin
			{ is the next char a % too? then insert one %	 }
			if astr[p+1] = '%' then
			 begin
			inc(p);
			buf := buf + '%';
			 end
			else
			 begin
			buf := buf + chr(hex_to_int(astr[p+1]+astr[p+2]));
			p := p + 2;
			 end;
			{ otherwise, it sould be a hex number, calc the  }
			{ value and add a char with that ASCII to result }
			{ we should make HEX to INT }
		 end;
	 else
	  buf := buf + AStr[p];
	end; { of CASE }
	inc(p);
   end;
		result := buf;
 end;

//*********************************************************************
function tMiscEncode.HTTPEncode(const AStr: String): string;
var
	i:byte;
	hex_string,buf:string;
begin
  buf := '';
	for i := 1 to length(AStr) do
  begin
	case AStr[i] of
		'0', '1'..'9', '.', 'A'..'Z', 'a'..'z', ':':
			buf := buf + AStr[i];	{ alphanumerics are ok }
			'%':
			buf := buf + '%%'; { % becomes %%			 }
		' ':
				buf := buf + ' ';	{ + becomes space	   }
			else	{ invalid char, encode it }
			begin
				hex_string := hex(ord(AStr[i]));
				   buf := buf + '%' + g_miscstrings.left_pad_string(hex_string,'0',2);
			 end;
	 end; { of CASE }
  end;
  result := buf;
end;
{*********************************************************************}
function tMiscEncode.get_serial_number: string;
var
	VolumeSerialNumber: DWORD;
	MaximumComponentLength: DWORD;
	FileSystemFlags: DWORD;
begin
	(*
	//------------------ get drive names ----------------------
  drive_names := StrAlloc( 100);
	status := GetLogicalDriveStrings(
	100,	// size of buffer
	c_string		// address of buffer for drive strings
   );
   drive_names := passtr(c_string);
   StrDispose( c_string);
   *)
   
	//------------------ get serial number for first drive name ------------
	GetVolumeInformation(
		'C:\',
		nil,
		0,
		@VolumeSerialNumber,
		MaximumComponentLength,
		FileSystemFlags,
		nil,
		0);

  result := IntToHex(HiWord(VolumeSerialNumber), 4) +  '-' + IntToHex(LoWord(VolumeSerialNumber), 4);
end;

initialization
	g_miscencode := tMiscEncode.create;

finalization
	g_miscencode.free;


//
//####################################################################
(*
	$History: miscEncode.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/classes
 * 
 * *****************  Version 3  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
*)
//####################################################################
//

end.
 