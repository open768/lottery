unit Misclib;
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
(* $Header: /PAGLIS/classes/misclib.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//

interface
uses
	windows, extctrls, sysutils, wintypes, winprocs, classes, graphics,forms,
  dialogs,shellapi,grids, inifile, mmsystem, jpeg, controls, contnrs,stringhash;
const
	BUFSIZ=100;
	TABCHAR=Chr(9);
	CRLF = ''+ chr(13) + chr(10) ;
	NULL = #0;
	BM = $4D42;  {Bitmap type identifier}
	HEX_STRING = '0123456789ABCDEF';
type
	radian = real;
	degree = 0..360;
	percentage = 0..100;
	ByteArray = array[0..0] of byte;
	PByteArray = ^ByteArray;
	IntArray = array [0..0] of Integer;
	PIntArray= ^IntArray;
	RealArray = array [0..0] of real;
	PRealArray= ^RealArray;
	T_paletteEntries = array[0..255] of TpaletteEntry;
	P_paletteEntries = ^T_paletteEntries;
	ResourceError = class (Exception);
	PaletteError = class (Exception);
	SetChar = set of char;

	TIntPoint =
		record
			x,y:integer
		end;


	EnumWavPlay = (wpSync, wpAsync, wpLoop);
const
	MAX_BITMAP_COLOURS = 256;
	PALETTE_DATA_SIZE = SizeOf(TLogPalette)+SizeOf(T_paletteEntries);
	PATH_SEPARATOR='\';


type
	TMisclib = class
	private
		c_default_browser:string;
		function pr_get_default_browser:string;
	public
		constructor create;
		function get_named_string_resource( resource_name: String):string;
		function get_string_resource( resource_id: Integer):string;
		function get_date_resource(resource_id: Integer): TDateTime;
		function clone_bitmap(aBitmap:tbitmap): Tbitmap;
		procedure exclaim(msg:string);
		procedure alert( a_string:string);
		procedure DEBUG( mesg:string);
		function get_text_extent(afont:tfont; aString:string): tsize;
		function dec_radian(old_angle,decrement:radian):radian;
		function dec_degree(old_angle,decrement:degree):degree;
		function degree_to_radian(value:degree):radian;
		function inc_radian(old_angle,increment:radian):radian;
		function inc_degree(old_angle,increment:degree):degree;
		function sign(value:integer) :integer;
		function swap16(value:Word): Word;
		procedure get_numbers( a_string:string; var numbers: array of integer); overload;
		procedure get_numbers( a_pchar:pchar; var numbers: array of integer); overload;
		procedure shift_up_in_grid( grid:TStringGrid);
		procedure shift_down_in_grid(grid:TStringGrid);
		function extract_tokens(entry, delimiter: string; var tokens: array of string): integer;
		procedure draw_3d_rectangle(canvas: Tcanvas; x1,y1,x2,y2:integer; raised:boolean);
		procedure show_modal_form(FormClass: TFormClass; var Reference);
		procedure show_form(FormClass: TFormClass; var Reference);
		procedure close_the_form (var Reference);
		function in_design_mode(Obj: Tcomponent): boolean;
		function ControlIsDecoration(ocontrol:tcontrol): boolean;
		function get_program_pathname: string;
		procedure sleep( milliseconds: longint);
		procedure play_wav(wav_name:string); overload;
		procedure play_wav(wav_name:string;synchronous:boolean); overload;
		procedure play_wav(wav_name:string;playMode: EnumWavPlay); overload;
		procedure stop_wav;
		function time_difference(start_time,end_time:Tdatetime): longint;
		procedure launch_url(const ps_URL:string; pb_is_file_url:boolean);
		function set_scrollbar_range(handle: hwnd; sbar,max,actual:integer): integer;
		function set_scrollbar_pos(handle: hwnd; sbar,scroll_pos:integer): integer;
		function get_scrollbar_pos(handle: hwnd; sbar:integer): integer;
		function RectIsContainedByRect( candidate, container: trect ): boolean;
		function find_form(Acomponent: Tcomponent): tform;
		function get_child_controls(poControl:Tcontrol):Tobjectlist;
		function is_Container(poControl:Tcontrol):boolean;
	end;

	procedure ProcessMessages;
var
	g_sound_muted: boolean;
	g_misclib : tmisclib;


implementation
uses
	miscstrings, shape2, stdctrls, comctrls,strutils;
const
	UNBOUND_LENGTH = -1;
	ORD_A = ord('a');
var
	m_graphic: tbitmap;



//##########################################################################
constructor Tmisclib.create;
begin
	inherited;
	c_default_browser := '';
end;

//##########################################################################
function Tmisclib.pr_get_default_browser:string;
var
	tmp_path, exename:string;
	buffer:pchar;
begin
	//create a tmp file if it doesnt exist
	tmp_path := get_program_pathname + 'temp.htm';
	if not FileExists('tmp_path') then
		FileCreate(tmp_path);

	//find executable
	buffer := stralloc(256);
	try
		findexecutable ('temp.htm', nil, buffer);
		ExeName := strpas(buffer);
	finally
		strdispose(buffer);
	end;

   //ok
	result := exename;
end;

//**************************************************************************
function Tmisclib.degree_to_radian(value:degree):radian;
begin
	degree_to_radian := value * (Pi/180);
end;

//**************************************************************************
function Tmisclib.inc_radian(old_angle,increment:radian):radian;
var
	new_angle:radian;
begin
	new_angle:= old_angle + increment;
	if new_angle > 2*PI then
		new_angle := new_angle - 2*PI;

	inc_radian := new_angle;
end;

//**************************************************************************
function Tmisclib.inc_degree(old_angle,increment:degree):degree;
var
	new_angle:integer;
begin
	new_angle:= old_angle + increment;
	if new_angle > 360 then
		new_angle := new_angle - 360;

	inc_degree := new_angle;
end;

//**************************************************************************
function Tmisclib.dec_radian(old_angle,decrement:radian):radian;
var
	new_angle:radian;
begin
	new_angle:= old_angle - decrement;
	if new_angle < 0.0 then
		new_angle := new_angle + 2*PI;

   dec_radian := new_angle;
end;

{************************************************************}
function Tmisclib.dec_degree(old_angle,decrement:degree):degree;
var
   new_angle:integer;
begin
   new_angle:= old_angle - decrement;
   if new_angle < 0 then
	  new_angle := new_angle + 360;

   dec_degree := new_angle;
end;

{************************************************************}
function Tmisclib.sign(value:integer) :integer;
begin
  if value >= 0 then
	sign:=1
  else
	sign:=-1;
end;

{************************************************************}
function Tmisclib.swap16(value:Word):word;
var
  lo, hi: word;
begin
  lo := LoByte(value);
  hi := HiByte(value);

  result := (lo * $100) + hi;
end;




//*********************************************************************
procedure Tmisclib.alert( a_string:string);
begin
	messagedlg (a_string, mtInformation, [mbok], 0);
end;

procedure Tmisclib.DEBUG( mesg:string);
begin
	showmessage(mesg);
end;

//*********************************************************************
function Tmisclib.get_text_extent(afont:tfont; aString:string): tsize;
var
	out_size: SIZE;
begin
	m_graphic.canvas.font.name := afont.name;
	m_graphic.canvas.font.size := afont.size;
   out_size := m_graphic.canvas.textextent(astring);
		result := out_size;
end;


{************************************************************}
function Tmisclib.get_string_resource( resource_id: Integer):string;
var
  value_pchar: Pchar;
  n_bytes:Integer;
begin

  {-------------- load resource into prepared buffer -----------------}
  value_pchar := stralloc( BUFSIZ);
  n_bytes := LoadString(Hinstance, resource_id, value_pchar, BUFSIZ);

  if n_bytes = 0 then
	begin
	  strdispose(value_pchar);
		raise ResourceError.Create('Error loading resource ' +  IntToStr(resource_id));
	end;

  {---------------- convert buffer and free resources ----------------}
  result := strPas(value_pchar);
  strdispose(value_pchar);
end;

{************************************************************}
function Tmisclib.get_date_resource(resource_id: Integer): TDateTime;
var
  buffer, temp_buffer, ptr:pchar;
  day,month,year:Integer;
begin
  {-----------------------allocate resources for strings----}
  buffer := stralloc( BUFSIZ);
  temp_buffer := stralloc( 5);
  LoadString(Hinstance, resource_id, buffer, BUFSIZ);

  {-----------------------convert data---------------------}
  ptr := buffer;
  StrLCopy(temp_buffer, ptr,2);
  day := StrToInt(StrPas(temp_buffer));

  ptr := ptr +3;
  StrLCopy(temp_buffer, ptr,2);
  month := StrToInt(StrPas(temp_buffer));

  ptr := ptr +3;
  StrLCopy(temp_buffer, ptr,4);
  year := StrToInt(StrPas(temp_buffer));

  {-----------------------free resources and return-------------------}
  strdispose(buffer);
  strdispose(temp_buffer);
  result := EncodeDate(year,month,day);

end;

{************************************************************
this doesnt work yet. bugger knows why.
 ************************************************************}
function Tmisclib.get_named_string_resource( resource_name: String):string;
var
  resource_name_pchar,value_pchar: Pchar;
  resource_handle, resource_data:Thandle;
  resource_pointer: Pointer;
  resource_size:LongInt;
begin
  {----------------get resource handle--------------------------------}
  resource_name_pchar := g_miscstrings.passtr(resource_name);
  resource_handle := FindResource(Hinstance,resource_name_pchar,RT_STRING);
  strdispose(resource_name_pchar);
  if resource_handle = 0 then
	  raise ResourceError.Create('No such resource ' +	resource_name);

  {----------------copy resource into a string--------------------}
  resource_size := SizeofResource(Hinstance, resource_handle);
  value_pchar := stralloc( resource_size+1);
  resource_data :=	LoadResource(HInstance, resource_handle);
  resource_pointer :=  LockResource(resource_data);
  StrLCopy(value_pchar,  resource_pointer, resource_size);

  FreeResource(resource_data);
  strdispose(value_pchar);
end;


{****************************************************************}
procedure Tmisclib.draw_3d_rectangle(canvas: Tcanvas; x1,y1,x2,y2:integer; raised:boolean);
	var inner_colour, outer_colour: tcolor;
  var rect:Trect;
begin
	{--------------------------select colours---------------------}
	if raised then
		begin
			inner_colour := clwhite;
			outer_colour := clblack;
		end
	else
		begin
			outer_colour := clwhite;
			inner_colour := clblack;
		end;

	with rect do
	begin
		left := x1;
		top := y1;
		right := x2;
		bottom := y2
	end;
	Frame3D(Canvas, rect, inner_colour, outer_colour, 1);
end;

{*********************************************************************}
procedure Tmisclib.play_wav(wav_name:string);
begin
	play_wav(wav_name, false);
end;

{*********************************************************************}
procedure Tmisclib.play_wav(wav_name:string;synchronous:boolean);
var
	playmode: EnumWavPlay;
begin
	if synchronous then
		playmode :=  wpSync
	else
		playmode := wpasync;
	play_wav(wav_name, playmode);
end;

{*********************************************************************}
procedure Tmisclib.play_wav(wav_name:string;playMode: EnumWavPlay);
var
   wav_pchar: Pchar;
   flag: integer;
begin
	if g_sound_muted then exit;
	wav_pchar := g_miscstrings.passtr(wav_name);

	flag := snd_sync;
	case playmode of
		wpSync: flag := snd_sync;
		wpAsync: flag := snd_async;
		wpLoop:  flag := snd_loop + snd_async;
	end;
	
	if (waveoutgetnumdevs > 0) then
		sndplaysound( wav_pchar , flag + SND_NODEFAULT)
end;


{*********************************************************************}
procedure Tmisclib.stop_wav;
begin
	sndplaysound( nil, SND_SYNC );
end;

{*********************************************************************}
procedure Tmisclib.exclaim(msg:string);
begin
  messagedlg( msg,mtinformation,[mbok],0);
end;




{************************************************************}
procedure Tmisclib.shift_up_in_grid( grid:TStringGrid);
var
  last_row, row, col: integer;
begin
  last_row := grid.rowcount -1;

  if grid.row <> last_row then
  begin
	{--------------move it on up-------------------}
	for row :=grid.row to last_row -1 do
	  for col := 1 to grid.colCount do
		grid.cells[col-1, row] := grid.cells[col-1,row+1];

	{--- clear last row , it is duplicate----------}
	for col := 1 to grid.colCount do
	  grid.cells[col-1, last_row] := '';
  end;
end;

{****************************************************************}
procedure Tmisclib.shift_down_in_grid(grid:TStringGrid);
var
  last_row, row, col: integer;
begin
  last_row := grid.rowcount -1;
  if grid.row <> last_row then
  begin
	{--- move it on down -----}
	for row := last_row downto grid.row+1 do
	  for col := 1 to grid.colcount  do
		grid.cells[col-1, row] := grid.cells[col-1,row-1];

	{-----clear current row, its duplicate------}
	row := grid.row;
	for col := 1 to grid.colcount	do
	  grid.cells[col-1, row] := '';

  end;
end;

{****************************************************************}
function Tmisclib.get_program_pathname: string;
var
  exename, outstring: string;
  index: integer;
begin
  {-----------initialise----------------------------}
  exename := Application.exename;
  outstring := '';

  {-------------work backwards through string--------}
  for index:=length(exename) downto 1 do
	if exename[index] = '\' then
	begin
	  outstring := copy(exename, 1, index);
	  break;
	end;

  {--------------set return value---------------------}
  get_program_pathname := outstring;
end;

{****************************************************************
 a pretty naff way of sleeping. cant find an alternative though
****************************************************************}
procedure Tmisclib.sleep( milliseconds:longint);
var
  target :tdatetime;
  sec,msec:word;
begin
  msec := milliseconds mod 1000;
  sec := milliseconds div 1000;
  target := time + encodetime(0,0,sec,msec);

  while (time < target) do
	application.processmessages;
end;

{****************************************************************}
procedure Tmisclib.show_modal_form(FormClass: TFormClass; var Reference);
begin
  if not assigned(Tform(reference)) then
	  Application.createForm(formclass, Tform(reference));
  tform(reference).showmodal;
end;

{****************************************************************}
procedure Tmisclib.close_the_form (var Reference);
var
	the_form:Tform;
begin
	the_form := Tform(Reference);
	if assigned(the_form) then
	begin
		the_form.close;
		the_form.free;
		Tform(Reference) := nil;
	end;
end;

{****************************************************************}
procedure Tmisclib.show_form(FormClass: TFormClass; var Reference);
begin
	if not assigned(Tform(reference)) then
			Application.createForm(formclass, Tform(reference));

	if tform(reference).windowstate = wsminimized then
		tform(reference).windowstate := wsnormal;

	tform(reference).show;
end;


{*********************************************************************}
function Tmisclib.time_difference(start_time,end_time:Tdatetime): longint;
var
	h1,m1,s1,ms1,h2,m2,s2,ms2: word;
	lh1,lm1,ls1,lms1,lh2,lm2,ls2,lms2: longint;
	dh,dm,ds,dms:longint;
begin
	decodetime(start_time, h1, m1, s1, ms1);
	decodetime(end_time, h2, m2, s2, ms2);

	lh1:= h1;lm1:=m1;ls1:=s1;lms1:=ms1;lh2:=h2;lm2:=m2;ls2:=s2;lms2:=ms2;

	dms := lms2-lms1;
	ds :=ls2-ls1;
	dm := lm2-lm1;
	dh := lh2-lh1;

  time_difference := dms + 1000 *( ds + 60 *(dm + 60 * dh));
end;


{*********************************************************************}
procedure ProcessMessages;
begin
  if not application.terminated then
	 Application.ProcessMessages;
end;


{*********************************************************************}
function Tmisclib.in_design_mode(Obj: Tcomponent): boolean;
begin
	result := (csDesigning in obj.ComponentState)
end;


{*********************************************************************}
function Tmisclib.set_scrollbar_range(handle: hwnd; sbar,max,actual:integer): integer;
var
	 scroll_struct: scrollinfo;
begin
	 with scroll_struct do
	 begin
			 cbSize := sizeof(scroll_struct);
			 fMask := SIF_RANGE or SIF_PAGE;
			 nMin := 0;
			 nMax := max;
			 nPage := actual;
	 end;
	 result :=SetScrollInfo (handle, sbar, scroll_struct, true);
end;

{*********************************************************************}
function Tmisclib.set_scrollbar_pos(handle: hwnd; sbar,scroll_pos:integer): integer;
var
	 scroll_struct: scrollinfo;
begin
	 with scroll_struct do
	 begin
			 cbSize := sizeof(scroll_struct);
			 fMask := SIF_POS ;
			 npos := scroll_pos;
	 end;
	 result :=SetScrollInfo (handle, sbar, scroll_struct, true);
end;

{*********************************************************************}
function Tmisclib.get_scrollbar_pos(handle: hwnd; sbar:integer): integer;
begin
	result := GetScrollPos(		handle,		sbar);
end;


{*********************************************************************}
function Tmisclib.RectIsContainedByRect( candidate, container: trect ): boolean;
begin
	result := false;

	if ptinrect(container, candidate.topleft) then
		if ptinrect(container, candidate.bottomright) then
			result := true;
end;

{*********************************************************************}
function Tmisclib.find_form(Acomponent: Tcomponent): tform;
begin
   if Acomponent is Tform then
   begin
	  result := Tform(Acomponent);
	  exit
   end;

   result := find_form( Acomponent.Owner);
end;

function Tmisclib.clone_bitmap(aBitmap:tbitmap): Tbitmap;
var
	out_bitmap: Tbitmap;
begin
	out_bitmap := tbitmap.create;
	out_bitmap.width := aBitmap.width;
	out_bitmap.height := aBitmap.height;
	out_bitmap.canvas.draw(0,0,abitmap);
	result := out_bitmap;
end;


//************************************************************
procedure Tmisclib.get_numbers( a_string:string; var numbers: array of integer);
var
	a_pchar: pchar;
begin
	a_pchar := g_miscstrings.PasStr(a_string);
	get_numbers(a_pchar, numbers);
	StrDispose(a_pchar);
end;

//************************************************************
procedure Tmisclib.get_numbers( a_pchar:pchar;	var numbers: array of integer);
var
  digit_ptr, end_ptr, current:pchar;
  temp_str: pchar;
  index:integer;
  n_digits:byte;
begin
  //initialise everything to zero
  for index := low(numbers) to high(numbers) do
	numbers[index] := 0;
  current := a_pchar;
  end_ptr := StrEnd(a_pchar);


  index := low(numbers);
  while  (index <= high(numbers)) do
  begin
	//- - - - - -find next digit- - - - - -
	digit_ptr := g_miscstrings.next_digit(current);
	if (digit_ptr = nil) then
	  break;

	//- - - - - -convert into an integer and store- - - - - -
	n_digits := g_miscstrings.how_many_digits(digit_ptr);
	temp_str := stralloc( 1+ n_digits);
	StrLCopy(temp_str, digit_ptr,n_digits);
	temp_str[n_digits] := NULL;
	numbers[index] := StrToInt(strpas(temp_str));
	StrDispose(temp_str);

	//- - - - - -move along two characters- - - - - -
	current := digit_ptr+n_digits;
	if current > end_ptr then
	  break;
	inc(index);
  end;
end;

//****************************************************************
function Tmisclib.extract_tokens(entry, delimiter: string; var tokens: array of string): integer;
var
  n_tokens, index, delim_pos, rhs_length: integer;
  rhs, the_string: string;
begin
  //------------------------initialise---------------------
  n_tokens := 0;
  the_string := entry;
  for index := low(tokens) to high(tokens) do
	 tokens[index] := '';
  index := low(tokens);

  //----------search for and extract tokens---------------
  while (index <=high(tokens) ) do
  begin
	delim_pos := pos( delimiter, the_string);
	if delim_pos = 0 then	break;

	//- - - - - - -get lhs- - - - - - - - - - - - - - - -
	if delim_pos > 1 then
	begin
	  tokens[index] := copy(the_string, 1, delim_pos-1);
		inc (index);
	  inc(n_tokens);
	end;

	//- - - - - - -get rhs- - - - - - - - - - - - - - - -
	rhs_length := length(the_string) - delim_pos ;
	if rhs_length > 0 then
	  begin
		rhs := copy(the_string,  delim_pos+1, rhs_length);
		the_string := rhs;
	  end
	else
	  begin
		the_string := '';
		break;
	  end;
  end;

  if (index < high(tokens)) and (the_string <> '') then
  begin
	 tokens[index] := the_string;
	 inc (n_tokens);
  end;
  result := n_tokens;
end;

//****************************************************************
procedure tmisclib.launch_url(const ps_url:string; pb_is_file_url:boolean);
var
	buffer:pchar;
	url:string;
begin

	//get the default browser
	if c_default_browser = '' then
	begin
		c_default_browser := pr_get_default_browser;
		if c_default_browser = '' then c_default_browser := 'iexplore.exe';
	end;

	//for a file url, make sure it exists
	url := ps_URL;
	if pb_is_file_url then
	begin
		if (not fileexists(url)) then
		begin
			url := g_misclib.get_program_pathname + url;
			if not FileExists(url) then
			begin
				raise exception.Create('unable to find file ' + url);
				exit;
			end;
		end;

		//make a proper filename
		url := g_miscstrings.makeProperFilename(url);
        url := StringReplace(url, '\','/',[rfReplaceAll]);
		url := 'file://' + url;
	end;


   //launch the darned thing
	buffer := g_miscstrings.passtr(c_default_browser + ' ' + url);
	try
		winexec(buffer,SW_SHOWNORMAL);
	finally
		strdispose(buffer);
	end;
end;


//****************************************************************
function tmisclib.ControlisDecoration(ocontrol:tcontrol): boolean;
begin
	result := true;
	if ocontrol is tshape then exit;
	if ocontrol is tshape2 then exit;
	if ocontrol is tbevel then exit;

	result := false;
end;


//****************************************************************
function tmisclib.get_child_controls(poControl:Tcontrol):Tobjectlist;
var
	oControls : TObjectList;
	oPanel: Tpanel;
	oForm:Tform;
	oTabSheet : TTabSheet;
	index:integer;
begin
	//------------- check that it is a known container -----------
	if not is_Container(poControl) then
	begin
		result := nil;
		exit;
	end;

	//----------------------------------------------
	ocontrols := TObjectList.Create(false);
	if poControl is Tpanel then
	begin
		oPanel := tpanel(poControl);
		for index := 1 to oPanel.ControlCount do
			oControls.Add( oPanel.Controls[index-1]);
	end
	else if poControl is Tform then
	begin
		oForm := TForm(poControl);
		for index := 1 to oForm.ControlCount do
			oControls.Add( oForm.Controls[index-1]);
	end
	else if poControl is TTabSheet then
	begin
		oTabSheet := TTabSheet(poControl);
		for index := 1 to oTabSheet.ControlCount do
			oControls.Add( oTabSheet.Controls[index-1]);
	end;

	result := oControls;
end;

//****************************************************************
function tmisclib.is_Container(poControl:Tcontrol):boolean;
begin
	result := true;

	if poControl is tform then exit;
	if poControl is tpanel then exit;
	if poControl is ttabsheet then exit;
	if poControl is tgroupbox then exit;
	if poControl is TRadioGroup then exit;

	result := false;
end;




//##########################################################################
initialization
	g_sound_muted := false;
	m_graphic := tbitmap.create;
	m_graphic.width := 100;
	m_graphic.height := 100;
	g_misclib := tmisclib.Create;


finalization
	m_graphic.free;
	g_misclib.Free;

//
//####################################################################
(*
	$History: misclib.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/classes
 * 
 * *****************  Version 23  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/classes
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 22  *****************
 * User: Administrator Date: 23/05/04   Time: 16:55
 * Updated in $/code/paglis/classes
 * rendered remembered balls
 * 
 * *****************  Version 21  *****************
 * User: Administrator Date: 5/05/04    Time: 23:14
 * Updated in $/code/paglis/classes
 * split out image misc and it all sort of works
 * 
 * *****************  Version 20  *****************
 * User: Administrator Date: 4/05/04    Time: 23:50
 * Updated in $/code/paglis/classes
 * added functions to read jpegs from resource files
 * 
 * *****************  Version 19  *****************
 * User: Sunil        Date: 6-04-03    Time: 11:27p
 * Updated in $/code/paglis/classes
 * corrected bug in get_colour_depth
 * 
 * *****************  Version 18  *****************
 * User: Sunil        Date: 22-02-03   Time: 5:35p
 * Updated in $/code/paglis/classes
 * xtra debugging added
 * 
 * *****************  Version 17  *****************
 * User: Sunil        Date: 18-02-03   Time: 6:34p
 * Updated in $/code/paglis/classes
 * some more useful utility functions
 * 
 * *****************  Version 16  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
*)
//####################################################################
//
end.

