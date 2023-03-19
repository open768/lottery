unit Progres2;
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
(* $Header: /PAGLIS/controls/Progres2.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//


interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, misclib;

type
  TProgressBarOrientation = (poHorizontal, poVertical);
  TProgressBarStyle = (pbSolid, pbBars, pbDial);

  TProgressBar2 = class(TGraphicControl)
  private
	{ Private declarations }
	F_min_value, F_max_value, F_value : longint;
	F_percent: percentage;
	F_style : TProgressBarStyle;
	F_orientation: TProgressBarOrientation;
	F_border_colour, F_Fill_colour: Tcolor;
	offscreen_bitmap: Tbitmap;
	F_bar_size : Byte;

	procedure set_fill_colour(value: Tcolor);
	procedure set_border_colour(value: Tcolor);
		procedure set_value(value: longint);
		procedure set_min_value(value: longint);
	procedure set_max_value(value: longint);
	procedure set_percent(value: percentage);
	procedure set_orientation(value: TProgressBarOrientation);
	procedure set_style(value: TProgressBarStyle);
	procedure set_bar_size(value: byte);

	procedure redraw;
	procedure draw_Hsolid;
	procedure draw_Hbars;
	procedure draw_dial;
	procedure draw_Vsolid;
	procedure draw_Vbars;

	procedure CMFontChanged(var M:TMessage); message CM_FONTCHANGED;
	procedure CMColorChanged(var M:TMessage); message CM_COLORCHANGED;

  protected
	{ Protected declarations }
	procedure Paint; override;

  public
	{ Public declarations }
	procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
	constructor Create (AOwner: TComponent); override;
	destructor Destroy; override;

  published
	{ Published declarations }
	property ParentColor;
	property Color;					  {background colour}
	property ParentFont;
	property Font;
	property align;

	property BarSize: byte read F_bar_size write set_bar_size;
	property BorderColour: Tcolor read F_border_colour write set_border_colour;
	property FillColour:Tcolor read F_fill_colour write set_fill_colour;
		property MinValue: longint read F_min_value write set_min_value;
		property MaxValue: longint read F_max_value write set_max_value;
	property Value: longint read F_value write set_value;
	property Percent: percentage read F_percent write set_percent;
	property Orientation: TProgressBarOrientation read F_orientation write set_orientation;
	property Style: TProgressBarStyle read F_style write set_style;

  end;

procedure Register;

implementation
const
  DEFAULT_BAR_SIZE = 10;
  DEFAULT_WIDTH = 100;
  DEFAULT_HEIGHT = 30;
  DEFAULT_STYLE = pbSolid;
  DEFAULT_ORIENTATION = poHorizontal;
  DEFAULT_FILL_COLOUR = clblue;
  FILLET_RADIUS = 4;

{*********************************************************************
 COMPONENT REGISTRATION
*********************************************************************}
procedure Register;
begin
  RegisterComponents('Paglis', [TProgressbar2]);
end;

{*********************************************************************
 PUBLIC
*********************************************************************}
constructor TProgressbar2.Create (AOwner: TComponent);
begin
  inherited Create(AOwner);

  offscreen_bitmap := Tbitmap.Create;		{offscreen bitmap}
  F_style := DEFAULT_STYLE;
  F_orientation := DEFAULT_ORIENTATION;
  F_value := 0;
  F_min_value := 0;
  F_max_value := 100;
  F_Fill_colour := DEFAULT_FILL_COLOUR;
  F_bar_size := DEFAULT_BAR_SIZE;

  setbounds(left,top, DEFAULT_WIDTH, DEFAULT_HEIGHT);
end;

{===================================================================}
destructor TProgressbar2.Destroy;
begin
  {offscreen bitmp no longer needed}
  if assigned(offscreen_bitmap) then
	offscreen_bitmap.Free;
  inherited Destroy;
end;

{===================================================================}
procedure TProgressbar2.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds( ALeft, ATop, AWidth, AHeight);
  offscreen_bitmap.width := AWidth;
  offscreen_bitmap.height := AHeight;

  if Parent<> nil then redraw;
end;

{*********************************************************************
 property_access
*********************************************************************}
procedure TProgressbar2.set_fill_colour(value: Tcolor);
begin
  if value <> F_Fill_colour then
  begin
	F_Fill_colour := value;
	redraw;
  end;
end;

{===================================================================}
procedure TProgressbar2.set_bar_size(value: byte);
begin
  if value <> F_bar_size then
  begin
	F_bar_size := value;
	redraw;
  end;
end;

{===================================================================}
procedure TProgressbar2.set_border_colour(value: Tcolor);
begin
  if value <> F_border_colour then
  begin
	F_border_colour := value;
	redraw;
  end;
end;

{===================================================================}
procedure TProgressbar2.set_min_value(value: longint);
begin
  if value <> F_min_value then
  begin
	F_min_value := value;
	redraw;
  end;
end;

{===================================================================}
procedure TProgressbar2.set_value(value: longint);
var
  new_percentage: Percentage;
begin
  if (value <> F_value) and (value <= F_Max_value) and (value >= F_min_value) then
  begin
	F_value := value;
	new_percentage := round( (F_value - F_min_value)/(F_max_value - F_min_value) * 100.0) ;
	if new_percentage <> F_percent then
	begin
	  F_percent := new_percentage;
	  redraw;
	end;
  end;
end;

{===================================================================}
procedure TProgressbar2.set_max_value(value: longint);
begin
  if value <> F_max_value then
  begin
	F_max_value := value;
	if F_value > F_max_value then
	  F_value := F_max_value;
	redraw;
  end;
end;

{===================================================================}
procedure TProgressbar2.set_percent(value: percentage);
begin
  if value <> F_percent then
  begin
	F_percent := value;
	F_value := F_min_value + round((F_max_value - F_min_value) * (F_percent/100));
	redraw;
  end;
end;

{===================================================================}
procedure TProgressbar2.set_orientation(value: TProgressBarOrientation);
begin
  if value <> F_orientation then
  begin
	F_orientation := value;
	redraw;
  end;
end;

{===================================================================}
procedure TProgressbar2.set_style(value: TProgressBarStyle);
begin
  if value <> F_style then
  begin
	F_style := value;
	redraw;
  end;
end;

{*********************************************************************
 Painting
*********************************************************************}
procedure TProgressbar2.Paint;
begin
  try
	canvas.draw(1,1, offscreen_bitmap);
  except
  end;
end;

{===================================================================}
procedure TProgressbar2.redraw;
begin
  {-----------clear the offscreen bitmap---------------}
  with offscreen_bitmap.canvas do
  begin
	pen.color := self.color;
	brush.color := color;
	brush.style := bsSolid;
	rectangle(0, 0, self.width -1, self.height -1);
  end;

  {draw the percentge}
  case F_orientation of
	poHorizontal:
	case F_style of
	  pbSolid: draw_Hsolid;
	  pbBars: draw_Hbars;
	  pbDial: draw_dial;
	end;

	poVertical:
	case F_style of
	  pbSolid: draw_Vsolid;
	  pbBars: draw_Vbars;
	  pbDial: draw_dial;
	end;
 end;

  {draw the border}
  with offscreen_bitmap.canvas do
  begin
	  pen.color := F_border_colour;
	  brush.style := bsClear;
	  rectangle(0, 0, self.width -1, self.height -1);
  end;

  Paint;
end;

{===================================================================}
procedure TProgressbar2.draw_Hsolid;
var
  bar_width, other_width: integer;
  font_x, font_y, font_width, font_height: integer;
  font_string: string;
begin
  {--------------------draw the bar--------------------------}
  bar_width := Round( F_percent/100  * width);
  other_width := width - bar_width;

  with offscreen_bitmap.canvas do
  begin
	pen.color :=  F_Fill_colour;
	brush.color := F_Fill_colour;
	brush.style := bsSolid;
	rectangle(0,0, bar_width, height);
  end;

  {--------------------draw the text--------------------------}
  font_string := intToStr(F_percent) + '%';
  with offscreen_bitmap.canvas do
  begin
	font_width := TextWidth(font_string);
	font_height := TextHeight(font_string);
  end;

  { dont draw text if it wont fit}
  if (font_width >= bar_width) and (font_width >= other_width) then exit;
  if (font_height >= height) then exit;

  { draw text }
  with offscreen_bitmap.canvas do
  begin
	font_y := (height - font_height) div 2;
	if (font_width > bar_width) then
	  begin
		font_x := bar_width + ((other_width - font_width) div 2);
		font.color := not color;
		brush.style := bsClear; 
	  end
	else
	  begin
		font_x := (bar_width - font_width) div 2;
		font.color := not F_fill_colour;
	  end;

	textOut(font_x, font_y, font_string);
  end;

end;

{===================================================================}
procedure TProgressbar2.draw_VSolid;
var
  bar_height, other_height: integer;
  font_x, font_y, font_width, font_height: integer;
  font_string: string;
begin
  {--------------------draw the bar--------------------------}
  bar_height := Round( F_percent/100  * height);
  other_height := height - bar_height;

  with offscreen_bitmap.canvas do
  begin
	pen.color :=  F_Fill_colour;
	brush.color := F_Fill_colour;
	brush.style := bsSolid;
	rectangle(0,0, width, bar_height);
  end;

  {--------------------draw the text--------------------------}
  font_string := intToStr(F_percent) + '%';
  with offscreen_bitmap.canvas do
  begin
	font_width := TextWidth(font_string);
	font_height := TextHeight(font_string);
  end;

  { dont draw text if it wont fit}
  if (font_height >= bar_height) and (font_height >= other_height) then exit;
  if (font_width >= width) then exit;

  { draw text }
  with offscreen_bitmap.canvas do
  begin
	font_x := (width - font_width) div 2;
	if (font_height > bar_height) then
	  begin
		font_y := bar_height + ((other_height - font_height) div 2);
		font.color := not color;
		brush.style := bsClear; 
	  end
	else
	  begin
		font_y := (bar_height - font_height) div 2;
		font.color := not F_fill_colour;
	  end;

	textOut(font_x, font_y, font_string);
  end;

end;

{===================================================================}
procedure TProgressbar2.draw_Vbars;
var
  bar_height, bar_top, other_height: integer;
  font_x, font_y, font_width, font_height: integer;
  font_string: string;
begin
  {--------------------draw the bars--------------------------}
  bar_height := Round( F_percent/100  * height);
  other_height := height - bar_height;

  with offscreen_bitmap.canvas do
  begin
	pen.color :=  F_Fill_colour;
	brush.color := F_Fill_colour;
	brush.style := bsSolid;

	bar_top := bar_height;
	while bar_top > 0 do
	begin
	  Roundrect(2, bar_top-F_bar_size, width-2, bar_top, FILLET_RADIUS, FILLET_RADIUS);
	  bar_top := bar_top - F_bar_size- 3;
	end;
  end;

  {--------------------draw the text--------------------------}
  font_string := intToStr(F_percent) + '%';
  with offscreen_bitmap.canvas do
  begin
	font_width := TextWidth(font_string);
	font_height := TextHeight(font_string);
  end;

  { dont draw text if it wont fit}
  if (font_height >= other_height) or (font_width >= width) then exit;

  { draw text }
  with offscreen_bitmap.canvas do
  begin
	font_x := (width - font_width) div 2;
	font_y := bar_height + ((other_height - font_height) div 2);
	font.color := not color;
	brush.style := bsClear;

	textOut(font_x, font_y, font_string);
  end;

end;

{===================================================================}
procedure TProgressbar2.draw_Hbars;
var
  bar_width, bar_right, other_width: integer;
  font_x, font_y, font_width, font_height: integer;
  font_string: string;
begin
  {--------------------draw the bars--------------------------}
  bar_width := Round( F_percent/100  * width);
  other_width := width - bar_width;

  with offscreen_bitmap.canvas do
  begin
	pen.color :=  F_Fill_colour;
	brush.color := F_Fill_colour;
	brush.style := bsSolid;

	bar_right := bar_width;
	while bar_right > 0 do
	begin
	  Roundrect(bar_right - F_bar_size, 2 , bar_right, height -2, FILLET_RADIUS, FILLET_RADIUS);
	  bar_right := bar_right - F_bar_size- 3;
	end;
  end;

  {--------------------draw the text--------------------------}
  font_string := intToStr(F_percent) + '%';
  with offscreen_bitmap.canvas do
  begin
	font_width := TextWidth(font_string);
	font_height := TextHeight(font_string);
  end;

  { dont draw text if it wont fit}
  if (font_width >= other_width) or (font_height >= height) then exit;

  { draw text }
  with offscreen_bitmap.canvas do
  begin
	font_y := (height - font_height) div 2;
	font_x := bar_width + ((other_width - font_width) div 2);
	font.color := not color;
	brush.style := bsClear;

	textOut(font_x, font_y, font_string);
  end;

end;

{===================================================================}
procedure TProgressbar2.draw_dial;
begin
end;

{*********************************************************************
 handle CM events
*********************************************************************}
procedure TProgressbar2.CMColorChanged(var M:TMessage);
begin
	redraw;
	inherited
end;

procedure TProgressbar2.CMFontChanged(var M:TMessage);
begin
	offscreen_bitmap.canvas.font.assign(font);
	redraw;
	inherited
end;

//
//####################################################################
(*
	$History: Progres2.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/controls
 * 
 * *****************  Version 3  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/controls
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 2  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/controls
 * added headers and footers
*)
//####################################################################
//
end.

