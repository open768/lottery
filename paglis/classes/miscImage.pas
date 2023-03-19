unit miscImage;
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

interface
uses
	windows, extctrls, sysutils, classes, graphics, jpeg, misclib;
type
	TMiscImageLib = class
	private
		function pr_same_palette_entries(var entry1,entry2:TpaletteEntry):boolean;
	public
		constructor create;
		function make_bitmap_from_resource(resource_name: string):TBitmap;
		function make_bitmap_from_file(pathname:string): Tbitmap;
		function clone_bitmap(aBitmap:tbitmap): Tbitmap;
		procedure convert_bitmap(src: Timage );
		function load_jpeg(filename:string): Tbitmap;
		function load_jpeg_from_resource(psResourceName:string):Tbitmap;
		function make_picture_list: tstringlist; overload;
		function make_picture_list(psPath:string): tstringlist;overload;
		procedure make_picture_list(psPath:string;alist:tstringlist);	overload;
		function get_bitmap_colours(bitmap:tbitmap; var logical_palette: pLogPalette):integer;
		procedure set_palette_entry( var logical_palette: PlogPalette; index:integer; the_colour:tcolor);
		procedure rebuild_bitmap_palette(bitmap:tbitmap);
		procedure free_logical_palette(var logical_palette:PLogPalette);
		function create_logical_palette:PLogPalette;
		procedure trim_bitmap_palette( bitmap:tbitmap);
		function palette_entry_to_colour (entry:tpaletteentry):tcolor;
		function get_optimised_palette(bitmap:tbitmap):PLogPalette;
		function get_midway_colour(colour1: Tcolor; colour2: Tcolor): Tcolor;
		function get_dimmer_colour(colour: Tcolor; decrement:word): Tcolor;
		function get_colour_depth: integer;
		function jpegToBitmap(poJpeg: Tjpegimage):Tbitmap;
		procedure free_image_resources(poBmp: Tbitmap);
	end;
var
	g_miscimage : TMiscImageLib;
	
implementation
uses
	miscstrings;



//##########################################################################
constructor TMiscImageLib.create;
begin
	inherited;
end;

{************************************************************
from delphi TI2947
 ************************************************************}
function TMiscImageLib.make_bitmap_from_resource(resource_name: string):TBitmap;
var
	Bmp: TBitmap;
begin
	Bmp := TBitmap.Create;
	bmp.LoadFromResourceName(HInstance,resource_name);
	result := bmp;
end;

//************************************************************
function TMiscImageLib.make_bitmap_from_file(pathname:string): Tbitmap;
var
	Bmp: TBitmap;
	w: integer;
begin
	w := 50;
	Bmp := TBitmap.Create;
	try
		bmp.LoadFromfile(pathname);
	except
		on efopenerror do
			with bmp.canvas do
			begin
				bmp.width := w;
				bmp.height := w;
				brush.color := clwhite;
				brush.style := bssolid;
				rectangle(1,1,w,w);
				pen.color := clred;
				pen.width := 4;
				moveto(1,1);
				lineto(w,w);
				moveto(1, w);
				lineto(w,1);
			end;
	end;
	result := bmp;
end;

//****************************************************************
procedure TMiscImageLib.free_image_resources(poBmp: Tbitmap);
begin
	poBmp.Dormant;
	pobmp.freeimage;
	pobmp.ReleaseHandle;
end;

//****************************************************************
//http://wall.riscom.net/books/delphi/del_tis/TI3334.html
function TMiscImageLib.load_jpeg_from_resource(psResourceName : string):TBitmap;
var
  hResource : THandle;
  oStream : TMemoryStream;
  pResource    : PByte;
  iSize   : Longint;
  oJPG : TJPEGImage;
  oBitmap: 	TBitmap;
begin
	hResource := FindResource(HInstance,PChar(psResourceName),RT_RCDATA);
	if hResource = 0 then
		g_misclib.alert('FindResource failed. '+SysErrorMessage(GetLastError))
	else begin
		iSize := SizeOfResource(HInstance,hResource);
		hResource := LoadResource(HInstance,hResource);
		if hResource = 0 then
			g_misclib.alert('LoadResource failed. '+  SysErrorMessage(GetLastError))
		else begin
			pResource := LockResource(hResource);
			if pResource = nil then
			  g_misclib.alert('LockResource failed. '+	SysErrorMessage(GetLastError))
			else begin
				//- - - - - create a memory stream for the resource to be read from - - -
				oStream := TMemoryStream.Create;
				with oStream do
				begin
					Write(pResource^,iSize);
					UnLockResource(hResource);
					Seek(0,soFromBeginning);
				end;

				//- - - - - - read JPEG resource - - - - - - - - - - - - - - - - - - - -
				oJPG := TJPEGImage.Create;
				ojpg.LoadFromStream(oStream);
				oStream.Free;

				//- - - - - - - convert to bitmap - - - - - - - - - - - - - - - - - - -
				obitmap := jpegToBitmap(oJPG);
				oJPG.Free;
				result := obitmap;
			end;
			FreeResource(hResource);
		end
  end;

end;

//****************************************************************
function TMiscImageLib.jpegToBitmap(poJpeg: Tjpegimage):Tbitmap;
var
	bmp: Tbitmap;
	MyFormat : Word;
	AData: THandle;
	APalette : hpalette;
begin
	bmp := tbitmap.create;
	bmp.width := poJpeg.width;
	bmp.height := poJpeg.height;

	APalette := 0;
	myformat := EnumClipboardFormats(0);
	poJpeg.SaveToClipboardFormat(MyFormat,AData,APalette);
	bmp.loadfromClipboardFormat(MyFormat,AData,APalette);

	result := bmp;
end;

//******************************************************************
function TMiscImageLib.load_jpeg(filename:string): Tbitmap;
var
	jpg : Tjpegimage;
	bmp: Tbitmap;
begin
	jpg := Tjpegimage.create;
	jpg.loadfromfile(filename);
	bmp := jpegToBitmap(jpg);
	jpg.free;

	result := bmp;
end;

//******************************************************************
procedure TMiscImageLib.convert_bitmap(src: Timage );
var
	dest: graphics.tbitmap;
	Arect: windows.Trect;
	agraphic: Tgraphic;
	MyFormat : Word;
	AData: THandle;
	APalette : hpalette;
begin
	dest := graphics.tbitmap.create();
	arect := src.clientrect;
	dest.width := src.width;
	dest.height := src.width;

	agraphic:=src.picture.graphic;
	APalette := 0;
	myformat := EnumClipboardFormats(0);
	agraphic.SaveToClipboardFormat(MyFormat,AData,APalette);
	dest.LoadFromClipboardFormat(myformat,adata,apalette);

	src.Picture := nil;
	src.Canvas.StretchDraw(src.clientrect,dest);

	dest.free;
end;

//******************************************************************
function TMiscImageLib.make_picture_list: tstringlist;
begin
	result := make_picture_list(g_misclib.get_program_pathname);
end;

//******************************************************************
function TMiscImageLib.make_picture_list(psPath:string): tstringlist;
var
	list: Tstringlist;
begin
	list := Tstringlist.create;
	make_picture_list(pspath,list);
	result:= list;
end;

//******************************************************************
procedure TMiscImageLib.make_picture_list(psPath:string;alist:tstringlist);
var
	filename, pattern, left, right: string;
	success: integer;
	search_obj: tsearchrec;
begin
	pattern := pspath;
	if (g_miscstrings.right_string(pattern,1) <> '\') then
		pattern := pattern + '\';
	pattern := pattern + '*.*';
	success := SysUtils.FindFirst(pattern, faAnyFile	,search_obj);
	if success <> 0 then exit;

	//------------------------------------------------------------------------
	while true do begin
		// process_directories
		if (search_obj.Attr and faDirectory) >0 then begin
			if (search_obj.Name = '.') or (search_obj.Name = '..') then
			else
			  make_picture_list(pspath + search_obj.name + '\', alist);
		end else begin
			// ignore non jpgs
			g_miscstrings.split_string(search_obj.Name, '.', left,right);
			if (uppercase(right) = 'JPG' )then begin
				filename := pspath + search_obj.Name;
				alist.add(filename);
			end;
		end;

		success := findnext(search_obj);
		if success <> 0 then break;
	end;
end;




function TMiscImageLib.clone_bitmap(aBitmap:tbitmap): Tbitmap;
var
	out_bitmap: Tbitmap;
begin
	out_bitmap := tbitmap.create;
	out_bitmap.width := aBitmap.width;
	out_bitmap.height := aBitmap.height;
	out_bitmap.canvas.draw(0,0,abitmap);
	result := out_bitmap;
end;

{*********************************************************************}
procedure TMiscImageLib.set_palette_entry( var logical_palette: PlogPalette; index:integer; the_colour:tcolor);
var
  red,blue,green:longint;
begin
  if (index <0) or (index>255) then
	raise PaletteError.create('Attempted to set out of range palette entry');

  {------------------- continue ---------------------------}
  red	:= (the_colour and $FF);
  green := (the_colour and $FF00) shr $8;
  blue	:= (the_colour and $FF0000) shr $10;

  {$R-}
  with logical_palette^.palpalentry[Index] do
  begin
	peRed := red;
	pegreen := green;
	peblue := blue;
	peflags := 0;
  end;
  {$R+}
end;

{*********************************************************************}
function TMiscImageLib.palette_entry_to_colour (entry:tpaletteentry):tcolor;
var
  the_colour:tcolor;
  red,blue,green:longint;
begin
  with entry do
  begin
	red := longint(pered);
	green := longint(pegreen) shl $8;
	blue := longint(peblue) shl $10;
	the_colour := red + green + blue;
  end;

  palette_entry_to_colour := the_colour;
end;


{*********************************************************************}
function TMiscImageLib.get_bitmap_colours(bitmap:tbitmap; var logical_palette: pLogPalette):integer;
var
  colours: array[1..MAX_BITMAP_COLOURS] of Tcolor;
  n_colours:word;
  x,y,index:integer;
  pixel_colour:Tcolor;
  found:boolean;
begin
  n_colours := 0;

  { step 1 -=-=-=-=-=- walk pixels =-=-=-=-=-=-=-=-=-=-=-=}
  for x := 0 to bitmap.width-1 do
  begin
	for y := 0 to bitmap.height-1 do
	begin
		{- - - - - get colour - - - - }
		pixel_colour := bitmap.canvas.pixels[x,y];

		{- - - - - is it there? - - - - }
		found := false;
		for index := 1 to n_colours do
		 if colours[index] = pixel_colour then
		 begin
			 found := true;
			 break;
		 end;

		{- - - - -	yup, its there - - - - }
		if found then continue;

		{- - - - -	nope, its not there - - - - }
		inc(n_colours);
		colours[n_colours] := pixel_colour;
	end; {for y}

	{--------------only interested in first 256 colours----}
	if n_colours >= MAX_BITMAP_COLOURS then break
  end; {for x}


  for index := 1 to n_colours do
	set_palette_entry(Logical_Palette,index-1,colours[index]);

  get_bitmap_colours :=  n_colours;
end;

{*********************************************************************}
procedure TMiscImageLib.rebuild_bitmap_palette(bitmap:tbitmap);
var
  logical_palette : PLogPalette;
begin
  logical_palette := get_optimised_palette(bitmap);
  bitmap.releasepalette;
  bitmap.palette := CreatePalette(logical_palette^);
  Free_logical_palette(logical_palette);
end;


{*********************************************************************}
procedure TMiscImageLib.trim_bitmap_palette( bitmap:tbitmap);
var
  in_palette,out_palette:	T_paletteEntries;
  in_entries, out_entries,in_index,out_index :word;
  found:boolean;
  logical_palette:Plogpalette;
begin
  {-----------------get palette entries-------------------------------}
  in_entries := getpaletteentries(bitmap.palette,0,256,in_palette);
  if in_entries = 0 then
  begin
	rebuild_bitmap_palette(bitmap);
	exit;
  end;
  out_entries := 0;

  {-----------------check each palette entry to see if its repeated----}
  for in_index := 1 to in_entries do
  begin
	found := false;

	{- - - - - - - -  did we find it? - - - - - - - - - }
	for out_index := out_entries downto 1 do
		if pr_same_palette_entries(out_palette[out_index-1],in_palette[in_index-1]) then
		begin
		 found := true;
		 break;
		end;

	{- - - - - - - -  nope, add it - - - - - - - - }
	if not found then
	begin
	  inc(out_entries);
	  out_palette[out_entries-1] := in_palette[in_index-1];
	end;
  end; {for in_index}

  {-----------updatepalette------------------------------}
  if (out_entries > 0) and (out_entries <> in_entries) then
  begin
	{- - - - - - -create logical palette- - - - - - - - - - - -}
	logical_palette := create_logical_palette;
	logical_palette^.palnumentries := out_entries;

	{- - - - - - -populate - - - - - - - - - - - -}
	with logical_palette^ do
	begin
		palnumentries := out_entries;
		move(out_entries,palpalentry, out_entries * sizeof(TPaletteEntry));
	end;

	{- - - - - -apply new palette- - - - - - - - - - - }
	bitmap.releasepalette;
	bitmap.palette := CreatePalette(logical_palette^);

	{- - - - - -clean up- - - - - - - - - - - }
	free_logical_palette(logical_palette);
  end;
end;

{*********************************************************************}
function TMiscImageLib.pr_same_palette_entries(var entry1,entry2:TpaletteEntry):boolean;
begin
  result := (entry1.pered = entry2.pered) and
			 (entry1.peblue = entry2.peblue) and
			 (entry1.pegreen = entry2.pegreen);
end;

{*********************************************************************}
function TMiscImageLib.create_logical_palette:PLogPalette;
var
  logical_palette: PLogPalette;
  index :integer;
begin

  getmem(logical_palette, PALETTE_DATA_SIZE);

  {-------initialise with an all black palette;---------------}
  with logical_palette^ do
  begin
	palVersion := $300;
	palNumEntries := 256;
  end;

  For index := 0 to 255 do
	set_palette_entry(logical_palette,index,clblack);

  {-----------return or GPF -----------------------------}
  create_logical_palette :=  logical_palette;
end;

{*********************************************************************}
procedure TMiscImageLib.free_logical_palette(var logical_palette:PLogPalette);
begin
  freemem(logical_palette, PALETTE_DATA_SIZE);
  logical_palette := nil;
end;


{*********************************************************************}
function TMiscImageLib.get_optimised_palette(bitmap:tbitmap):PLogPalette;
var
  n_colours:byte;
  logical_palette:PLogPalette;
begin
  logical_palette := create_logical_palette;
	n_colours := get_bitmap_colours(bitmap,logical_palette);
  logical_palette^.palNumEntries := n_colours;
  get_optimised_palette := logical_palette;
end;

{*********************************************************************}
function TMiscImageLib.get_midway_colour(colour1: Tcolor; colour2: Tcolor): Tcolor;
var
	rgb1,rgb2: longint;
	r1,r2,b1,b2,g1,g2:word;
begin
	rgb1 := colortorgb(colour1);
	rgb2 := colortorgb(colour2);
	r1 := getRvalue(rgb1);
	r2 := getRvalue(rgb2);
	g1 := getGvalue(rgb1);
	g2 := getGvalue(rgb2);
	b1 := getBvalue(rgb1);
	b2 := getBvalue(rgb2);

	result := rgb( (r1+r2) div 2, (g1+g2) div 2, (b1+b2) div 2);
end;

{*********************************************************************}
function TMiscImageLib.get_dimmer_colour(colour: Tcolor; decrement:word): Tcolor;
var
	rgb1: longint;
	r1,b1,g1: word;
begin
	rgb1 := colortorgb(colour);
	r1 := getRvalue(rgb1);
	g1 := getGvalue(rgb1);
	b1 := getBvalue(rgb1);

	result := rgb( r1-decrement,g1-decrement,b1-decrement);
end;

//************************************************************
function TMiscImageLib.get_colour_depth: integer;
begin
	result := GetDeviceCaps( GetDc( GetDesktopWindow), BITSPIXEL);
end;


//##########################################################################
initialization
	g_miscimage := TMiscImageLib.Create;


finalization
	g_miscimage.Free;

//
//####################################################################
(*
	$History: miscImage.pas $
 * 
 * *****************  Version 3  *****************
 * User: Sunil        Date: 6/06/05    Time: 0:24
 * Updated in $/PAGLIS/classes
 * corrected logic for changed picture list
 * 
 * *****************  Version 2  *****************
 * User: Sunil        Date: 21/02/05   Time: 22:27
 * Updated in $/PAGLIS/classes
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/classes
 * 
 * *****************  Version 2  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/classes
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 1  *****************
 * User: Administrator Date: 5/12/04    Time: 5:10p
 * Created in $/code/paglis/classes
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

