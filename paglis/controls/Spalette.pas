unit Spalette;
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
(* $Header: /PAGLIS/controls/Spalette.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//


interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, misclib,miscimage;

type
  TShowPalette = class(TgraphicControl)
  private
	{ Private declarations }
	F_Palette_handle:Hpalette;
	F_Canvas_handle:hdc;
	f_border, f_box_border:boolean;
	F_gap_size:byte;
	F_box_size:byte;
	F_autosize:boolean;

	n_entries : integer;
	palette_entries: T_paletteEntries;

	procedure set_palette_handle(value:Hpalette);
	procedure set_canvas_handle(value:hdc);
	procedure set_border(value:boolean);
	procedure set_box_border(value:boolean);
	procedure set_autosize(value:boolean);
	procedure set_box_size(value:byte);
	procedure set_gap_size(value:byte);

	procedure adjust_box_size;
	procedure update_palette_entries;
  protected
	{ Protected declarations }
	procedure Paint; override;
  public
	{ Public declarations }
	procedure setbounds(aleft,atop,awidth,aheight:integer); override;
	property PaletteHandle:Hpalette read f_palette_handle write set_palette_handle;
	property CanvasHandle:Hdc read f_canvas_handle write set_canvas_handle;
	constructor Create(Aowner:Tcomponent);override;

  published
	{ Published declarations }
	property Color;
	property ParentColor;
	property Border:boolean read F_border write set_border;
	property BoxBorder:boolean read F_box_border write set_box_border;
	property BoxSize:byte read f_box_size write set_box_size;
	property GapSize:byte read f_gap_size write set_gap_size;
	property AutoSize: boolean read F_autosize write set_autosize;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Paglis', [TShowPalette]);
end;

{********************************************************}
constructor TShowPalette.Create(Aowner:Tcomponent);
begin
  inherited Create(aowner);

  F_palette_handle := 0;
  f_gap_size := 2;
  F_autosize := true;
  F_box_size := 10;
  F_border := true;
  F_box_border := true;
  canvas.brush.style := bssolid;
  width := 100;
  height := 100;
end;

{********************************************************}
procedure TShowPalette.set_palette_handle(value:Hpalette);
begin
  F_palette_handle := value;
  F_canvas_handle := 0;
  update_palette_entries;
  invalidate;
end;

{********************************************************}
procedure TShowPalette.set_canvas_handle(value:hdc);
begin
  F_canvas_handle := value;
  F_palette_handle := 0;
  update_palette_entries;
  invalidate;
end;

{********************************************************}
procedure TShowPalette.set_gap_size(value:byte);
begin
  if value <> f_gap_size then
  begin
	f_gap_size := value;
	if f_autosize then adjust_box_size;
	invalidate;
  end;
end;

{********************************************************}
procedure TShowPalette.set_box_size(value:byte);
begin

  {------------ disable autosize if active and designing ---}
  if f_autosize then
	if (csDesigning in ComponentState) then
		f_autosize := false
	else
		exit;

  {---------- process property ----------------}
  if value <> f_box_size then
  begin
	f_box_size := value;
	invalidate;
  end;
end;

{********************************************************}
procedure TShowPalette.set_autosize(value:boolean);
begin
  if value <> f_autosize then
  begin
	f_autosize := value;
	if f_autosize then
	begin
	  adjust_box_size;
	  invalidate;
	end;
  end;
end;

{********************************************************}
procedure TShowPalette.set_box_border(value:boolean);
begin
  if value <> F_box_border then
  begin
	  F_box_border := value;
	  invalidate;
  end;
end;

{********************************************************}
procedure TShowPalette.set_border(value:boolean);
begin
  if value <> F_border then
  begin
	  F_border := value;
	  invalidate;
  end;
end;

{********************************************************}
procedure TShowPalette.adjust_box_size;
var
  tile_area,area: real;
  new_box_size:longint;
  rows,cols:word;
begin
  if (n_entries>0) and (width >0) and (height > 0) then
  begin
		{--------- use maths to figure it out --}
		{$IFDEF WIN32}
			area  := (width-f_gap_size-2) * (height-f_gap_size-2);
			tile_area := area / n_entries;
		{$ELSE}
			area  := float(width-f_gap_size-2) * float(height-f_gap_size-2);
			tile_area := area / float(n_entries);
		{$ENDIF}
		new_box_size := trunc(sqrt(tile_area)) - f_gap_size;

	{--------- adjust box size until it all fits-----}
	while (true) do
	begin
	  rows := (width -2) div (new_box_size + f_gap_size);
	  cols := (height -2)div (new_box_size + f_gap_size);
	  if (rows * cols) >= n_entries then
		 break
	  else
		 dec(new_box_size);
	end;

	{--------- hold it just there. ----------------}
	F_box_size := new_box_size;
  end;
end;

{********************************************************}
procedure TShowPalette.setbounds(aleft,atop,awidth,aheight:integer);
begin
  inherited setbounds(aleft,atop,awidth,aheight);
  if f_autosize then adjust_box_size;
end;

{********************************************************}
procedure TShowPalette.update_palette_entries;
begin
  if (csDesigning in ComponentState) then
	n_entries := getsystempaletteentries(canvas.handle,0,256,palette_entries)
  else
	if (f_palette_handle = 0) and (F_canvas_handle = 0) then
		exit
	else if (F_palette_handle <> 0) then
		n_entries := getpaletteentries(f_palette_handle,0,256,palette_entries)
	else
		n_entries := getsystempaletteentries(f_canvas_handle,0,256,palette_entries);

  if f_autosize then adjust_box_size;
end;

{********************************************************}
procedure TShowPalette.paint;
var
  entry: word;
  x,y:integer;
  the_colour:tcolor;
begin
  if (csDesigning in ComponentState) then
	update_palette_entries;

  {-----------draw the border----------------}
  if f_border then
	canvas.pen.style := pssolid
  else
	canvas.pen.style := psclear;
  canvas.brush.color := color;
  canvas.rectangle(0,0,width,height);

  {------draw each colour in the palette------}
  canvas.pen.style := pssolid;

  x:=1+f_gap_size; y:=1+f_gap_size;
  for entry:=1 to n_entries do
  begin
	  {- - - - - - - figure out the colour to draw - - - - - -}
	  the_colour := g_miscimage.palette_entry_to_colour( palette_entries[entry-1] );

	  {- - - - - - - draw rectangle  - - - - - -}
	  canvas.brush.color := the_colour;
	  if  f_box_border then
		 canvas.pen.color := clblack
	  else
		 canvas.pen.color := the_colour;
	  canvas.rectangle(x,y,x+F_box_size,y+F_box_size);

	  {- - - - - - - move on - - - - - -}
	  x := x+F_box_size+f_gap_size;
	  if (x+F_box_size) >= width then
	  begin
		 x := 1+f_gap_size;
		 y := y + F_box_size+f_gap_size;
	  end;
  end;
end;

//
//####################################################################
(*
	$History: Spalette.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/controls
 * 
 * *****************  Version 5  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/controls
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 4  *****************
 * User: Administrator Date: 5/05/04    Time: 23:14
 * Updated in $/code/paglis/controls
 * split out image misc and it all sort of works
 * 
 * *****************  Version 3  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/controls
 * added headers and footers
*)
//####################################################################
//
end.

