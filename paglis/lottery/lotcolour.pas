unit lotcolour;

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
(* $Header: /PAGLIS/lottery/lotcolour.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//

interface
uses
	graphics, sparselist;
type
	TLotteryBallColourResult = class
		colour:Tcolor;
		bmp: Tbitmap;
		constructor create;
		destructor destroy; override;
	end;

	TLotteryBallColours = class
	private
		m_data: TSparseList;
		m_invalid_colour : TLotteryBallColourResult;
		function p_getItem(index:integer): TLotteryBallColourResult;
		function p_getColour(index:integer): Tcolor;
		procedure p_setColour(index:integer; Acolour: Tcolor);
		procedure p_set_invalid_colour(aColour:Tcolor);
		function p_get_invalid_colour:tcolor;
		function p_make_item(aColour:Tcolor):TLotteryBallColourResult;
		function p_make_coloured_bitmap(acolour:tcolor):tbitmap;
		procedure p_reset;
		procedure p_set_default_colours;
	public
		property List:TSparseList read m_data;
		property Colour[index:integer]: Tcolor read p_getColour write p_setColour;
		property item[index:integer]:TLotteryBallColourResult read p_getItem; default;
		property InvalidColour: Tcolor read p_get_invalid_colour write p_set_invalid_colour;
		property InvalidItem: TLotteryBallColourResult read m_invalid_colour;
		procedure Clear;
		constructor create;
		destructor destroy; override;
	end;


implementation
uses
	classes, windows,misclib,miscimage,miscencode,extctrls,realint, inifile, inisection, sysutils,
  stringhash;
var
	m_gray_ball: graphics.Tbitmap;
const
	CL_WHITE = clwhite;
	CL_CYAN = $FFFF80; 	  {cyan}
	CL_PINK = $8080FF; 	  {pink}
	CL_GREEN = $80FF00;	  {green}
	CL_YELLOW = $80FFFF;		{yellow}
	CL_PURPLE = $CF47F5;		{purply}
	GRAY_RESNAME = 'GRAY';
	COLOR_GRAY_VALUE = 150;
	INI_FILE = 'lottColours.ini';
	BAD_SECTION = 'bad';
	BAD_COLOUR_KEY = 'colours';
	GAMES_SECTION = 'games';
	GAME_KEY = 'game';

	//##############################################################################
	//# TLotteryBallColourResult
	//##############################################################################
	constructor TLotteryBallColourResult.create;
	begin
		inherited;
		bmp:= nil;
	end;

	//*******************************************************************************
	destructor TLotteryBallColourResult.destroy;
	begin
		if assigned(bmp) then bmp.free;
		inherited;
	end;

	//##############################################################################
	//# publics
	//##############################################################################
	constructor TLotteryBallColours.create;
	begin
		inherited;
		m_data:= TSparseList.create(true);
		m_invalid_colour := nil;
		//-----------------------------------------
		p_reset;
	end;

	//*******************************************************************************
	destructor TLotteryBallColours.destroy;
	begin
		m_data.free;
		m_invalid_colour.free;
		inherited;
	end;

	//##############################################################################
	//# privates
	//##############################################################################
	procedure TLotteryBallColours.p_reset;
	var
		ini:Tinifile;
		section:TIniFileSection;
		colour_section_name, string_key, string_value: string;
		key:integer;
		colour_value:tcolor;
		keys:Tstringlist;
		index:integer;
	begin
		clear;

		ini := Tinifile.create(INI_file);

		string_value := ini.read( BAD_SECTION, BAD_COLOUR_KEY, g_miscencode.hex(cl_purple));
		InvalidColour := g_miscencode.hex_to_int(string_value);

		colour_section_name := ini.read( games_SECTION, GAME_KEY, '');
		if colour_section_name= ''  then
			p_set_default_colours
		else
			begin
				section := ini.sections[colour_section_name];
				keys := section.getKeys;
				for index := 1 to keys.count do
				begin
					string_key := keys[index-1];
					string_value := section.Values[string_key];

					key := strtoint(string_key);
					colour_value := g_miscencode.hex_to_int(string_value);
					Colour[key]:= colour_value;
				end;
				keys.Free;
			end;
		ini.free;
	end;

	//*******************************************************************************
	function TLotteryBallColours.p_getColour(index:integer): Tcolor;
	var
		obj: TLotteryBallColourResult;
	begin
		obj := TLotteryBallColourResult(m_data.items[index]);
		if obj = nil then obj := m_invalid_colour;
		result := obj.colour;
	end;

	//*******************************************************************************
	procedure TLotteryBallColours.p_setColour(index:integer; Acolour: Tcolor);
	var
		obj: TLotteryBallColourResult;
	begin
		obj := p_make_item(acolour);
		m_data.items[index] := obj;
	end;

	//*******************************************************************************
	function TLotteryBallColours.p_getItem(index:integer): TLotteryBallColourResult;
	var
		counter: integer;
		obj: TLotteryBallColourResult;
	begin
		obj := nil;
		
		if index < m_data.fromindex then
			obj := m_invalid_colour;

		if (obj = nil) and (index >= m_data.toindex) then
			obj := TLotteryBallColourResult(m_data.items[m_data.toindex]);

		for counter := index downto m_data.fromindex do
		begin
			obj := TLotteryBallColourResult(m_data.items[counter]);
			if obj <> nil then
				break;
		end;

		if obj = nil then
			obj := m_invalid_colour;
			
		result := obj;
	end;

	//*******************************************************************************
	function TLotteryBallColours.p_get_invalid_colour:tcolor;
	begin
		result := m_invalid_colour.colour;
	end;

	//*******************************************************************************
	procedure TLotteryBallColours.p_set_invalid_colour(aColour:Tcolor);
	begin
		if assigned(m_invalid_colour) then
		begin
			if m_invalid_colour.colour = acolour then exit;
			m_invalid_colour.free;
		end;
		
		m_invalid_colour := p_make_item(acolour);
	end;

	//*******************************************************************************
	function TLotteryBallColours.p_make_coloured_bitmap(acolour:tcolor):graphics.tbitmap;
	var
		bmp: graphics.Tbitmap;
		map: array[0..255] of Tcolor;
		dr,dg,db, r_2, g_2, b_2: RealInteger;
		x,y, r,g,b, dColor, index: integer;
		this_colour: tcolor;

	begin
		//--------------- make bitmap -------------------------------------
		bmp := graphics.tbitmap.create;
		bmp.width := m_gray_ball.width;
		bmp.height := m_gray_ball.height;

		//--------------- make color map --- white -> colour --------------
		// uses linear mapping, perhaps whoudl use sinusoidal
		r := getrvalue(acolour);
		g := getgvalue(acolour);
		b := getbvalue(acolour);
		dColor := 255 - COLOR_GRAY_VALUE;
		dr := int_to_realint(r-255) div dColor;
		dg := int_to_realint(g-255) div dColor;
		db := int_to_realint(b-255) div dColor;

		r_2 := int_to_realint(r);
		g_2 := int_to_realint(g);
		b_2 := int_to_realint(b);
		for index := 254 downto COLOR_GRAY_VALUE do
		begin
			r_2 := r_2 + dr;
			g_2 := g_2 + dg;
			b_2 := b_2 + db;
			r := trunc_realint(r_2);
			g := trunc_realint(g_2);
			b := trunc_realint(b_2);
			map[index] := rgb(r,g,b);
		end;


		//--------------- make color map --- colour -> black --------------
		r := getrvalue(acolour);
		g := getgvalue(acolour);
		b := getbvalue(acolour);
		dr := int_to_realint(r) div COLOR_GRAY_VALUE;
		dg := int_to_realint(g) div COLOR_GRAY_VALUE;
		db := int_to_realint(b) div COLOR_GRAY_VALUE;

		r_2 := int_to_realint(r);
		g_2 := int_to_realint(g);
		b_2 := int_to_realint(b);
		for index := COLOR_GRAY_VALUE -1 downto 1 do
		begin
			r_2 := r_2 - dr;
			g_2 := g_2 - dg;
			b_2 := b_2 - db;
			r := trunc_realint(r_2);
			g := trunc_realint(g_2);
			b := trunc_realint(b_2);
			map[index] := rgb(r,g,b);
		end;

		//--------------- make sure that colour is actually there --------
		map[255] := clwhite;
		map[0] := clblack;
		map[COLOR_GRAY_VALUE] := acolour;

		//---------------apply color map----------------------------------
		for x := 1 to m_gray_ball.width do
			for y := 1 to m_gray_ball.height do
			begin
				//- - - - - - color on gray ball - - - - - - - - - - -	-
				this_colour := m_gray_ball.canvas.pixels[x,y];
				r := getrvalue(this_colour);
				g := getgvalue(this_colour);
				b := getbvalue(this_colour);
				
				//- - - - - - gray index  - - - - - - - - - - -  -
				index := (r+g+b) div 3;

				//- - - - - - - apply color - - - - - - - - - - - - 
				bmp.canvas.pixels[x,y] := map[index];
			end;

		//---------------all done ----------------------------------------

		result := bmp;
	end;

	//*******************************************************************************
	function TLotteryBallColours.p_make_item(aColour:Tcolor):TLotteryBallColourResult;
	var
		item : TLotteryBallColourResult;
	begin
		item := TLotteryBallColourResult.create;
		item.colour := aColour;
		item.bmp := p_make_coloured_bitmap(acolour);
		result := item;
	end;

	//*******************************************************************************
	procedure TLotteryBallColours.p_set_default_colours;
	begin
		Colour[1] := CL_WHITE;
		Colour[10]:= CL_CYAN;
		Colour[20]:= CL_PINK;
		Colour[30]:= CL_GREEN;
		Colour[40]:= CL_YELLOW;
		Colour[50]:= CL_PURPLE;
		InvalidColour:= cl_purple;
	end;

	//##############################################################################
	//# publics
	//##############################################################################
	procedure TLotteryBallColours.Clear;
	begin
		m_data.clear;
	end;

	//##############################################################################
	//# publics
	//##############################################################################
	procedure p_load_gray_bitmap;
	begin
		//m_gray_ball := g_miscimage.load_jpeg_from_resource(GRAY_RESNAME);
		m_gray_ball:= g_miscimage.load_jpeg( g_misclib.get_program_pathname + 'gray.jpg');
	end;

	//*******************************************************************************
	procedure p_free_gray_bitmap;
	begin
		m_gray_ball.free;
	end;

initialization
	p_load_gray_bitmap;
finalization
	p_free_gray_bitmap;
//
//####################################################################
(*
	$History: lotcolour.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/lottery
 * 
 * *****************  Version 7  *****************
 * User: Administrator Date: 5/05/04    Time: 23:14
 * Updated in $/code/paglis/lottery
 * split out image misc and it all sort of works
 * 
 * *****************  Version 6  *****************
 * User: Administrator Date: 4/05/04    Time: 23:50
 * Updated in $/code/paglis/lottery
 * no longer uses filename - reads gray ball from resource
 * 
 * *****************  Version 5  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/lottery
 * added headers and footers
*)
//####################################################################
//
end.
