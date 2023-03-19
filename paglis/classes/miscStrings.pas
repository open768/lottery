unit miscStrings;

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
(* $Header: /PAGLIS/classes/miscStrings.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//

interface
uses
	stdctrls,classes;
type
	EnumCharType= (ctNone, ctChar, ctNumeric, ctSpace, ctApostrophe, ctPunct);

	TMiscStrings = class
		procedure split(joined:string; delim:char; list:tstringlist); overload;
		function split(joined:string; delim:char ):Tstringlist; overload;
		function split_words(joined:string):Tstringlist;
		function join( list:Tstringlist; delim:char): string;
		function next_digit(a_string:pchar):pchar;
		function how_many_digits(a_pchar: pchar): byte;
	
		function read_a_line(var handle: textfile): string;
		function read_file(const filename:string):string;
		function read_file_stream(const filename:string):string;		
		function right_string(a_string:string; count:integer):string;
		function left_string(a_string:string; count:integer):string;
		function mid_string(a_string:string; start,count:integer):string;
		function val(a_string:string):integer;
		function get_delimited_string(astring,delim:string):string;
		function random_pad_string(astring:string; out_length:integer):string;
		function string_to_date(astring:string):tDatetime;
		function date_to_string(aDate:tDatetime):string;
		procedure strCatPas( dest:Pchar; astring:string);

		function trim(a_string:string):string;

		function instr(sub_string, a_string :string):integer; overload;
		function instr(sub_string, a_string :string; start:integer):integer;overload;
		function instr(sub_string, a_string :string; start:integer; ignoreCase:boolean):integer;overload;

		function to_string_end(a_string:string; start:integer):string;
		procedure split_string(a_string:string; delim: char; var left_bit, right_bit:string);
		function adjust_length(the_string:string;maxlen:integer): string;
		function pad_string(a_string,delim:string; out_length:integer):string;
		function unpad_string(a_string,delim:string ):string;
		function random_string(out_len:integer; exclude:string): string;
		function break_string(a_string:string; chunk_length:integer; delim:char):string;
		function remove_char(a_string:string; delim:char):string;
		function interleave_strings(a_string,b_string:string):string;
		function string_sequence(start_char, end_char:char):string;
		function fill_string(n_copies:word; char:string):string;
		function left_pad_string(a_string,delim:string; out_length:integer):string;
		function strip_html(const Astr:string):string; overload;
		function strip_html(const Astr:string; var in_tag:boolean):string; overload;
		function collapse_spaces(const Astr:string):string;
		function make_alphanumeric(const psValue: string):string;
		//function Format(const Format: string; const list:Tstringlist): string; overload;

		function is_digit(a_char: char): Boolean;
		function is_alpha(ch:char): boolean;
		function is_numeric(ch: char): boolean;
		function is_alphanumeric(ch:char):boolean;
		function is_punct(ch:char):boolean;
		function is_apostrophe(ch:char):boolean;
		function is_space(ch:char):boolean;
		function is_hex(ch:char): boolean;
		function get_char_type(ch:char): enumCharType;

		function PasStr( a_string: string): Pchar;
		function makeProperFilename(psFilename:string):string;
		procedure selectInList(poLIst:tcombobox; psItem:string); overload;
	end;
var
	g_miscstrings: TMiscStrings;

implementation
uses
	sysutils,math,misclib, faststrings;

//*********************************************************************
function TMiscStrings.read_a_line(var handle: textfile): string;
var
  line: string;
begin
  line := '';

  while (line = '') and not Eof(handle) do
  begin
	readln(handle, line);
	line := trim(line);
  end;

  read_a_line := line;
end;

//*********************************************************************
//this doesnt actually work - why not
function TMiscStrings.read_file_stream(const filename:string):string;
VAR
	stream: TMemoryStream;
	out_string: string;
	stream_size: int64;
begin
	//----------------------------------------------------------
	stream := TMemoryStream.Create;
	try
		stream.LoadFromFile(filename);
	except
		stream.Free;
		raise;
		exit;
	end;

	stream_size := stream.Size;

	//----------read from stream into string
	out_string := '';
	SetString(out_string, PChar(stream.memory),stream_size);
	stream.free;

	// -----------output
	result := out_string;
end;

//*********************************************************************
function TMiscStrings.read_file(const filename:string):string;
VAR
	aFile: textfile;
	line,out_string, proper_filename: string;
begin

	proper_filename := filename;
	if pos('\',proper_filename) = 0 then
		proper_filename := g_misclib.get_program_pathname +  proper_filename;

	if not FileExists(proper_filename) then
	begin
		raise Exception.Create('file '+ proper_filename +' does not exist');
		exit;
	end;

	AssignFile(aFile, proper_filename);
	try
		reset(aFile);
	except
		raise Exception.Create('file exists, unable to open file');
	end;

	try
		out_string:='';
		while not eof(aFile) do
		begin
			Readln(afile, line);
			out_string := out_string + line +#10;
		end;
	finally
		CloseFile(aFile);
	end;

	// -----------output
	result := out_string;
end;

//*********************************************************************
function TMiscStrings.right_string(a_string:string; count:integer):string;
var
  string_length:integer;
  string_bit:string;
begin
  string_length := length(a_string);
  if count > string_length then
	string_bit := a_string
  else
	string_bit := copy(a_string, string_length-count+1,count);

  right_string := string_bit;
end;

//*********************************************************************
function TMiscStrings.mid_string(a_string:string; start,count:integer):string;
begin
  mid_string := copy(a_string,start,count);
end;


//*********************************************************************
function TMiscStrings.fill_string(n_copies:word; char:string):string;
var
	out_string:string;
  index:integer;
begin
	out_string := '';
	for index := 1 to n_copies do
		out_string := out_string + char;
	fill_string := out_string;
end;


//*********************************************************************
function TMiscStrings.left_string(a_string:string; count:integer):string;
var
  string_length:integer;
begin
  string_length := length(a_string);
  if count > string_length then
	left_string := a_string
  else
	left_string := copy(a_string,1,count)
end;

//*********************************************************************
function TMiscStrings.to_string_end(a_string:string; start:integer):string;
var
  string_length:integer;
begin
  string_length := length(a_string);
  to_string_end := copy(a_string, start, string_length - start +1);
end;

//*********************************************************************
	function TMiscStrings.instr(sub_string, a_string :string):integer;
	begin
		result := instr(sub_string, a_string, 1, false);
	end;

//************************************************************
function TMiscStrings.instr(sub_string, a_string :string; start:integer):integer;
begin
	result := instr(sub_string, a_string, start, false);
end;

{$IFDEF MSWINDOWS}
	//wont port to CLX - uses assembler behind the scenes
	function TMiscStrings.instr(sub_string, a_string :string; start:integer; ignoreCase:boolean):integer;
	begin
		result := SmartPos( sub_string, a_string, not ignoreCase,start, true);
	end;
{$ENDIF}

//*********************************************************************
procedure TMiscStrings.split_string(a_string:string; delim: char; var left_bit, right_bit:string);
var
  delim_pos :integer;
begin
  delim_pos := pos(delim,a_string);

  if delim_pos = 0 then
	begin
	  left_bit := a_string;
	  right_bit := '';
	end
  else if delim_pos = 1 then
	begin
		left_bit := '';
	  right_bit := to_string_end(a_string,2);
	end
  else if delim_pos=length(a_string) then
	begin
	  left_bit := copy(a_string,1,length(a_string)-1);
	  right_bit := '';
	end
  else
	begin
	  left_bit := left_string(a_string, delim_pos-1);
	  right_bit := to_string_end(a_string,delim_pos+1);
	end;
end;

//************************************************************
function TMiscStrings.trim(a_string:string):string;
var
  out_string:string;
  start_pos, end_pos, index: integer;
begin
  out_string:= '';

	start_pos := -1;
	end_pos := length(a_string);


  for index:=1 to length(a_string) do
	 if not is_space(a_string[index]) then
	 begin
		start_pos := index;
		break;
	 end;

  if start_pos <> -1 then
  begin
		for index := length(a_string) downto 1 do
		if not is_space(a_string[index]) then
		begin
		 end_pos := index;
		 break;
		end;

	 out_string := copy(a_string, start_pos, 1+ (end_pos - start_pos));
  end;

  result := out_string;
end;

//************************************************************
function TMiscStrings.PasStr( a_string: string): Pchar;
var
  c_string: Pchar;
begin
  c_string := StrAlloc( length(a_string) +1);
  StrPcopy(c_string, a_string);
  PasStr := c_string;
end;

//************************************************************
function TMiscStrings.next_digit(a_string:pchar):pchar;
var
  end_ptr: Pchar;
  digit_ptr: pchar;
  found: boolean;
begin
  end_ptr := StrEnd(a_string);
  digit_ptr := a_string;
  found := false;

  while (digit_ptr < end_ptr) do
  begin
	 if is_digit(digit_ptr^) then
	begin
	  found := true;
	  break;
	end;
	digit_ptr := digit_ptr +1;
  end;

  if found then
	result := digit_ptr
  else
	result := nil;
end;

//************************************************************
function TMiscStrings.how_many_digits(a_pchar: pchar): byte;
var
  n_digits: byte;
  current_ptr: pchar;
begin
  current_ptr := a_pchar;
  n_digits := 0;
  while ( (current_ptr^ <> NULL) and is_digit(current_ptr^) ) do
  begin
	inc(n_digits);
	current_ptr := current_ptr +1;
  end;

  result := n_digits;
end;

//**********************************************************
function TMiscStrings.adjust_length(the_string:string;maxlen:integer): string;
var
	out_string:string;
	index,len, index2:integer;
begin
  //----------make sure input string is the right length-----
  len := length(the_string);
  if len < maxlen then
	begin
	  out_string := the_string;
	  index2 := 1;
	  for index := 1 to (maxlen - len) do
	  begin
		out_string := out_string + the_string[index2];
		inc(index2);
		if (index2 > len) then
			index2 := 1;
	  end;
	end
  else if len > maxlen then
	out_string := copy(the_string,1,maxlen)
  else
	out_string := the_string ;

	//----------all done here-----------------------------------
	adjust_length := out_string;
end;

//*********************************************************************
procedure TMiscStrings.split(joined:string; delim:char; list:tstringlist); 
VAR
  last_delim_pos, delim_pos, bit_length, strlen:integer;
	string_bit:string;
begin
	last_delim_pos := 0;
	strlen := length(joined);

	while true do
	begin
		//- - - - - - - - - - - - - - - - - - - - - - - - -
		delim_pos := instr(delim,joined,last_delim_pos+1);
		if delim_pos = 0 then
			begin
				bit_length :=  strlen - last_delim_pos;
				string_bit := right_string( joined, bit_length);
				last_delim_pos := strlen;
			end
			else
			begin
				bit_length :=  delim_pos - last_delim_pos-1;
				string_bit := mid_string(joined, last_delim_pos +1, bit_length);
				last_delim_pos := delim_pos;
			end;

		//- - - - - - - - - - - - - - - - - - - - - - - - -
		list.add(string_bit);
		if last_delim_pos >= strlen then
			break;
	end;
end;

//*********************************************************************
function TMiscStrings.split(joined:string; delim:char):Tstringlist;
var
	list:tstringlist;
begin
	list := TStringList.Create;
	split(joined,delim,list);
	result := list;
end;

//*********************************************************************
// *go through buffer
//*********************************************************************
function TMiscStrings.split_words(joined:string):Tstringlist;
var
	buffer:string;
	out_list: tstringlist;
	last_type, char_type: EnumCharType;
	strlen, index:word;
	ch:char;
	bProceed : Boolean;
begin
	//------------------------------------------------------------------
	last_type := ctNone;
	out_list := tstringlist.create;
	buffer := '';
	strlen := length(joined);

	//------------------------------------------------------------------
	for index := 1 to strlen do
	begin
		//- - - - - get char - - - - - - - - - - - -
		ch := joined[index];
		char_type:= get_char_type(ch);

		//- - - - - has char type changed? - - - - - - - - - - - -
		if buffer <> '' then
			if last_type <> ctnone then
				if char_type <> last_type then
				begin
					bproceed := true;
					
					case last_type of
						ctChar:
							if char_type in [ctNumeric,ctApostrophe] then
								bProceed := false;
						ctNumeric:
							if char_type in [ctchar,ctApostrophe] then
								bProceed := false;
						ctApostrophe:
							if char_type in [ctchar] then
								bProceed := false;
					end;

					if bproceed then
					begin
						if trim(buffer) <> '' then
							out_list.add(   buffer);
						buffer := '';
					end;
				end;

		//- - - - - append char  - - - - - - - - - - - -
		buffer := buffer + ch;
		last_type := char_type;					//remember char type
	end;

	//------------------------------------------------------------------
	if buffer <> '' then
		out_list.add(   buffer);
	result := out_list;
end;

//*********************************************************************
function TMiscStrings.join( list:Tstringlist; delim:char): string;
var
  joined:string;
  index:integer;
begin
	joined := '';
	for index := 1 to list.count do
	begin
		if index > 1 then
			joined := joined + delim;
		joined := joined + list[index-1];
  end;

  join := joined;
end;

//*********************************************************************
function TMiscStrings.val(a_string:string):integer;
var
  strlen, index:integer;
  num_string:string;
  ch:char;
begin
  num_string :=  '';
  strlen := length(a_string);

  for index := 1 to strlen do
  begin
	ch := a_string[index];
	 if is_digit(ch) then num_string := num_string + ch;
  end;

  if num_string = '' then
	val := 0
  else
	val := strtoint(num_string);
end;

//*********************************************************************
function TMiscStrings.get_delimited_string(astring,delim:string):string;
var
  delim_len:integer;
  start_pos,end_pos:integer;
begin
  result := '';
  delim_len := length(delim);
  start_pos := instr(delim, astring,1);

  if start_pos >0 then
  begin
	start_pos := start_pos + delim_len;
	end_pos := instr(delim, astring,start_pos);
	if end_pos >0 then result := mid_string(astring, start_pos , end_pos - start_pos);
  end;
end;

//*********************************************************************
function TMiscStrings.random_pad_string(astring:string; out_length:integer):string;
var
  in_length, pad_length, index, random_number:integer;
  pad_string: string;
begin
  randomize;
  in_length := length(astring);
  pad_length := out_length - in_length;
  pad_string := '';

  for index := 1 to pad_length do
  begin
	random_number := 1 + random(24) + ord('A');
	pad_string := pad_string + chr(random_number);
  end;

  random_pad_string := pad_string + astring;
end;

//************************************************************
function TMiscStrings.string_to_date(astring:string):tDatetime;
var
	splitDate:Tstringlist;
	year, month, day: integer;
begin
	splitDate := split(astring, '-');
	if splitDate.Count < 3 then
	begin
		splitDate.free;
		raise Exception.create('Bad Date :' + astring);
	end;

	try
		year := strtoint(splitDate.strings[2]);
		month:= strtoint(splitDate.strings[1]);
		day  := strtoint(splitDate.strings[0]);

		//------------- got the goods, get out -----------------------
		result := EncodeDate(year,month,day);
	finally
		splitDate.free;
	end;

end;

//*********************************************************************
function TMiscStrings.date_to_string(aDate:tDatetime):string;
var
	year, month, day: word;
begin
	decodedate(aDate, year, month, day);
	date_to_string := inttostr(day) + '-' + inttostr(month) + '-' + inttostr(year);
end;


//*********************************************************************
procedure TMiscStrings.strCatPas( dest:Pchar; astring:string);
var
	s:pchar;
begin
	S := passtr(astring);
	strcat( dest,s);
  strdispose(s);
end;

//*********************************************************************
function TMiscStrings.left_pad_string(a_string,delim:string; out_length:integer):string;
var
	left_bit:string;
	diff:integer;
begin
	diff := out_length - length(a_string);
	left_bit := fill_string(diff, delim);
  left_pad_string := left_bit + a_string;
end;

//*********************************************************************
function TMiscStrings.pad_string(a_string,delim:string; out_length:integer):string;
var
  out_string, left_bit, right_bit:string;
  in_len, delim_in_len, delim_len, diff_len, left_len, right_len:integer;
begin
  //-----------------------------------------------------------------
	in_len := length(a_string);
  delim_len := length(delim);
  delim_in_len :=  in_len + (2*delim_len);

  //-----------------------------------------------------------------
  if ( delim_in_len >= out_length ) then
	out_string := a_string
  else
	begin
		diff_len := (out_length - in_len - 2*delim_len);
		left_len := diff_len div 2;
		right_len := diff_len - left_len;

		left_bit := random_string(left_len, delim);
		 right_bit := random_string(right_len, delim);

		out_string := left_bit + delim + a_string + delim + right_bit;
	 end;

  //-----------------------------------------------------------------
  pad_string := out_string;
end;

//*********************************************************************
function TMiscStrings.unpad_string(a_string,delim:string ):string;
var
  pos1,pos2, diff,delim_len:integer;
  out_string: string;
begin
  //--------------------------------------------------------
	delim_len := length(delim);
  pos1 := pos(delim,a_string);
  pos2 := instr(delim, a_string, pos1+delim_len);

  //--------------------------------------------------------
  if (pos1>0) and (pos2>0) then
	begin
	  diff := pos2 - (pos1 +delim_len);
	  out_string := mid_string(a_string,  pos1+delim_len, diff);
	end
  else
	out_string := '';

  //--------------------------------------------------------
  unpad_string := out_string

end;

//*********************************************************************
function TMiscStrings.random_string(out_len:integer; exclude:string): string;
var
  index,exclude_pos, char_code:integer;
  the_char: char;
  out_string: string;
begin
  //--------------------------------------------------------
  randomize;
  out_string := '';

  //--------------------------------------------------------
  for index := 1 to out_len do
	while true do
	begin
		char_code := random(255);
		the_char := chr(char_code);
		 exclude_pos := pos(the_char, exclude);
		if exclude_pos = 0 then
		begin
		 out_string := out_string + the_char;
		 break;
		end;
	end;

  //--------------------------------------------------------
  random_string := out_string;
end;  

//*********************************************************************
function TMiscStrings.break_string(a_string:string; chunk_length:integer; delim:char):string;
var
  index,in_len:integer;
  out_string:string;
begin
  out_string := '';
	in_len := length(a_string);

  for index := 1 to in_len do
  begin
	out_string := out_string + a_string[index];
	 if (index < in_len) then
	  if (index mod chunk_length) = 0 then
		out_string := out_string + delim;
  end;

  break_string := out_string;
end;

//*********************************************************************
function TMiscStrings.remove_char(a_string:string; delim:char):string;
var
  index,in_len:integer;
  out_string:string;
  the_char: char;
begin
  out_string := '';
  in_len := length(a_string);

  for index := 1 to in_len do
  begin
	the_char := a_string[index];
	if the_char <> delim then out_string := out_string + the_char;
  end;

  remove_char := out_string;
end;

//*********************************************************************
function TMiscStrings.interleave_strings(a_string,b_string:string):string;
var
  length_a, length_b, interleave_length:integer;
  index, index_a, index_b:integer;
  out_string: string;
begin
  length_a := length(a_string);
  length_b := length(b_string);
  interleave_length := max(length_a, length_b);

  out_string := '';
  for index := 1 to interleave_length do
  begin
	index_a := 1+ ((index-1) mod length_a);
		index_b := 1+ ((index-1) mod length_b);
		out_string := out_string + a_string[index_a] + b_string[index_b];
	end;
	interleave_strings := out_string;
end;

//*********************************************************************
function TMiscStrings.string_sequence(start_char, end_char:char):string;
var
  out_string:string;
  start_code, end_code, the_code:integer;
begin
  //---------------------------------------------------------------
  out_string := '';
  start_code := ord(start_char);
  end_code := ord(end_char);
  if start_code > end_code then
  begin
	start_code := end_code;
	 end_code := ord(start_char);
  end;

  //---------------------------------------------------------------
  for the_code := start_code to end_code do
	 out_string := out_string + chr(the_code);

  //---------------------------------------------------------------
  string_sequence := out_string;
end;


//*********************************************************************
function TMiscStrings.strip_html(const Astr:string):string;
var
	in_tag: boolean;
begin
	in_tag := false;
	result := strip_html(astr, in_tag);
end;

//*********************************************************************
function TMiscStrings.strip_html(const Astr:string; var in_tag:boolean):string; 
var
	out_string:string;
	ch:char;
	in_amp, skip_this: boolean;

	index:word;
begin
	in_amp := false;
	out_string := '';

	for index := 1 to length(astr) do
	begin
		skip_this := false;
		
		ch := astr[index];
		case ch of
			'<' : in_tag := true;
			'>' :
				begin
					in_tag := false;
					skip_this := true;
				end;
			'&' : if not in_tag then in_amp := true;
			';' :
				if in_amp then
				begin
					in_amp := false;
					skip_this := true;
				end;
		end;

		if in_tag then continue;
		if in_amp then continue;
		if skip_this then continue;

		out_string := out_string + ch;
	end;

	result := out_string;
end;

//*********************************************************************
function TMiscStrings.make_alphanumeric(const psValue: string):string;
var
	sOutStr: string;
	iIndex:integer;
	cChar: Char;
begin
	sOutStr := '';
	for iIndex := 1 to length(psValue) do
	begin
		cChar := psValue[iindex];
		if is_alphanumeric(cChar) or is_space(cChar) then
			sOutStr := sOutStr + cChar;
	end;

	result := sOutStr;
end;

//*********************************************************************
function TMiscStrings.collapse_spaces(const Astr:string):string;
var
	out_string: string;
	ch: char;
	was_space: boolean;
	index:word;
begin
	was_space := false;
	out_string := '';
	
	for index := 1 to length(astr) do
	begin
		ch := astr[index];
		if is_space(ch) then
		begin
			was_space := true;
			continue;
		end;
		
		if was_space then
		begin
			out_string := out_string + ' ';
			was_space := false;
		end;

		out_string := out_string + ch;
	end;

	result :=out_string;
end;
//*********************************************************************
function TMiscStrings.is_alpha(ch:char): boolean;
begin
	case ch of
		'a'..'z', 'A'..'Z':
			result := true;
		else
			result := false;
	end;
end;

//*********************************************************************
function TMiscStrings.is_hex(ch:char): boolean;
begin
	case ch of
		'a'..'f', 'A'..'F', '0' .. '9':
			result := true;
		else
			result := false;
	end;
end;

//*********************************************************************
function TMiscStrings.is_numeric(ch: char): boolean;
begin
	case ch of
		'0'..'9', '-', '.', ',':
			result := true;
		else
			result := false;
	end;
end;

//*********************************************************************
function TMiscStrings.is_alphanumeric(ch:char):boolean;
begin
	result := ( is_alpha(ch) or is_numeric(ch));
end;

//*********************************************************************
function TMiscStrings.is_apostrophe(ch:char):boolean;
begin
	case ch of
		'''','`':
			result := true;
		else
			result := false;
	end;
end;

//*********************************************************************
function TMiscStrings.is_punct(ch:char):boolean;
begin
	case ch of
		'.',';',':',',','(',')','[',']','{','}','"','''':
			result := true;
		else
			result := false;
	end;
end;

//*********************************************************************
function TMiscStrings.is_space(ch:char):boolean;
begin
	case ch of
		' ','	',chr(10),chr(13):
			result := true;
		else
			result := false;
	end;
end;

//************************************************************
function TMiscStrings.is_digit(a_char: char): Boolean;
begin
  result := (a_char >= '0') and (a_char <= '9');
end;


//************************************************************
function TMiscStrings.get_char_type(ch:char): enumCharType;
begin
	if is_space(ch) then result := ctspace
	else if is_alpha(ch) then result := ctchar
	else if ch = '''' then result := ctApostrophe
	else if is_punct(ch) then result := ctPunct
	else if is_digit(ch) then result := ctNumeric
	else result :=ctnone;;
end;

//************************************************************
function TMiscStrings.makeProperFilename(psFilename:string):string;
var
	sFirst2chars, sFilename: string;
begin
	//does it start with a UNC or a drivename?
	sFirst2chars := left_string(psFilename,2);
	if (sFirst2chars = '//') or (sFirst2chars[1]=':') then
		sFilename := psFilename
	else
		sFilename := g_misclib.get_program_pathname + psFilename;

	// ok all done
	result := sFilename;
end;

//************************************************************
procedure TMiscStrings.selectInList(poList:tcombobox; psItem:string);
begin
	poList.ItemIndex := poList.items.indexof(psItem);
end;

//############################################################
//#
//############################################################
initialization
	g_miscstrings := TMiscStrings.create;
finalization
	g_miscstrings.free;

//
//####################################################################
(*
	$History: miscStrings.pas $
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
 * User: Administrator Date: 3/12/04    Time: 11:29p
 * Updated in $/code/paglis/classes
 * added is_hex
 * 
 * *****************  Version 7  *****************
 * User: Administrator Date: 8/06/04    Time: 14:56
 * Updated in $/code/paglis/classes
 * selects an item in the list
 * 
 * *****************  Version 6  *****************
 * User: Sunil        Date: 15-03-03   Time: 12:35p
 * Updated in $/code/paglis/classes
 * added overloaded split function
 * 
 * *****************  Version 5  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
*)
//####################################################################
//
end.
