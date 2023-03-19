unit Shape2;
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
(* $Header: /PAGLIS/controls/Shape2.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//


interface

uses
	SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
	Forms, Dialogs,misclib;

type
	TShape2Type = (s2Square, s2Rectangle, s2RoundRect, s2RoundSquare, s2Triangle, s2Circle, s2Ellipse, s2Regular, s2Irregular);
	TTriangleType = (ttupright, ttright, ttleft, ttdown);
	TPointArray = array [0..0] of Tpoint;
	PPointArray = ^TPointArray;
	EShape2Exception = class(exception);

  TShape2 = class(Tcustomcontrol)
  private
	{ Private declarations }
	F_style : TShape2Type;
	F_filled : Boolean;
	F_pen_colour, F_fill_colour, F_Shadow_colour: Tcolor;
	F_pen_thickness:byte;
	F_fillet_radius: byte;
	F_regular_sides:byte;
	F_border_width: byte;
	F_triangle_style: TTriangleType;
		F_Shadow_depth: byte;
		f_caption: string;
	regular_points: PPointArray;
	regular_points_size:longint;

	procedure set_style(value:TShape2Type);
	procedure set_pen_colour(value:TColor);
	procedure set_fill_colour(value:TColor);
	procedure set_shadow_colour(value:TColor);
	procedure set_shadow_depth(value:byte);
	procedure set_filled(value : boolean);
	procedure set_fillet_radius(value:byte);
	procedure set_regular_sides(value:byte);
	procedure set_pen_thickness(value:byte);
	procedure set_border_width(value:byte);
		procedure set_triangle_style(value:TTriangleType);
		procedure set_caption(value:string);
	procedure draw_triangle(x1,y1,x2,y2,xc,yc:integer);
	procedure draw_regular_shape( xc,yc,w,h:integer);
	procedure draw_shape(
				x1,y1,x2,y2:integer;
						 pen_colour, fill_colour:Tcolor);
		function get_radius:longint;
		function get_centre_point: TintPoint;
		procedure set_centre_point(value:TintPoint);
  protected
	{ Protected declarations }
	procedure Paint; override;
	public
		{ Public declarations }
		constructor Create (AOwner: TComponent); override;
		destructor Destroy; override;
		property CentrePoint: TintPoint read get_centre_point write set_centre_point;
  published
	{ Published declarations }
	property ParentColor;
		property Align;

		property BorderWidth:byte read f_border_width write set_border_width;
	property Style:TShape2Type read F_style write set_style;
	property PenColor: Tcolor read F_pen_Colour write set_pen_colour;
	property FillColor: Tcolor read F_fill_Colour write set_fill_colour;
	property ShadowColor: Tcolor read F_shadow_Colour write set_shadow_colour;
	property ShadowDepth: Byte read F_shadow_depth write set_shadow_depth;
	property TriangleStyle: TTriangleType read F_triangle_style write set_triangle_style;
	property PenThickness: byte read F_pen_thickness write set_pen_thickness;
	property RegularSides: byte read F_regular_sides write set_regular_sides;
	property Filled: boolean read F_Filled write set_filled;
		property FilletRadius: byte read F_fillet_radius write set_fillet_radius;
		property Caption: string read f_caption write set_caption;
		property Radius: longint read get_radius;
		property font;
		property ParentFont;

		property onMouseUp;
		property onMouseDown;
		property onMouseMove;
	end;

procedure Register;

implementation
uses
	math;
const
	DEFAULT_SHAPE = s2Rectangle;
  DEFAULT_PEN_COLOUR = clblack;
  DEFAULT_FILL_COLOUR = clwhite;
  DEFAULT_PEN_THICKNESS = 1;
  DEFAULT_TRIANGLE_STYLE = ttupright;
  DEFAULT_FILLET_RADIUS = 10;
  DEFAULT_REGULAR_SIDES = 5;

{####################################################################}
procedure Register;
begin
  RegisterComponents('Paglis', [TShape2]);
end;

{####################################################################}
constructor Tshape2.Create (AOwner: TComponent);
begin
  inherited Create(Aowner);

	f_caption := Name;
  F_style := DEFAULT_SHAPE;
  F_triangle_style := DEFAULT_TRIANGLE_STYLE;
  F_pen_Colour := DEFAULT_PEN_COLOUR;
  F_fill_Colour := DEFAULT_FILL_COLOUR;
  F_pen_thickness := DEFAULT_PEN_THICKNESS;
  F_Filled := true;
  f_fillet_radius:= default_fillet_radius;
  F_Shadow_depth := 0;
  F_shadow_colour := clblack;
  width := 100;
  height:=100;

  F_regular_sides := DEFAULT_REGULAR_SIDES;
	regular_points_size := F_regular_sides * sizeof(Tpoint);
	{$ifdef win32}
	getmem(regular_points, regular_points_size) ;
	{$else}
	regular_points := allocmem(regular_points_size) ;
	{$endif}

end;

{********************************************************************}
destructor Tshape2.Destroy;
begin
  freemem(regular_points,regular_points_size);
  inherited destroy;
end;

{####################################################################}
procedure Tshape2.set_style(value:TShape2Type);
begin
  if F_style <> value then
  begin
	F_style := value;
	invalidate;
  end;
end;

{********************************************************************}
procedure Tshape2.set_pen_colour(value:TColor);
begin
  if value <> F_pen_colour then
  begin
	F_pen_colour := value;
	invalidate;
  end;
end;

{********************************************************************}
procedure Tshape2.set_fill_colour(value:TColor);
begin
  if value <> F_fill_colour then
  begin
	F_fill_colour := value;
	invalidate;
  end;
end;

{********************************************************************}
procedure Tshape2.set_shadow_colour(value:TColor);
begin
  if value <> F_shadow_colour then
  begin
	F_shadow_colour := value;
	invalidate;
  end;
end;

{********************************************************************}
procedure Tshape2.set_shadow_depth(value:byte);
begin
  if value <> F_shadow_depth then
  begin
	F_shadow_depth := value;
	invalidate;
  end;
end;

{********************************************************************}
procedure Tshape2.set_fillet_radius(value:byte);
begin
  if value <> F_fillet_radius then
  begin
	F_fillet_radius := value;
	if f_style = s2roundrect then invalidate;
  end;
end;

{********************************************************************}
procedure Tshape2.set_regular_sides(value:byte);
var
  newsize: longint;
begin
  if (value <> F_regular_sides) and (value > 2)then
  begin
	F_regular_sides := value;
	  newsize := F_regular_sides * sizeof(Tpoint);
	  {$IFDEF win32}
			reallocmem( regular_points	,newsize);
	  {$ELSE}
			regular_points := reallocmem( regular_points  ,regular_points_size, newsize);
	  {$endif}
	regular_points_size := newsize;
	if (f_style = s2Regular) or (f_style= s2Irregular) then invalidate;
  end;
end;

{********************************************************************}
procedure Tshape2.set_triangle_style(value:TTriangleType);
begin
  if value <> F_triangle_style then
  begin
	F_triangle_style := value;
	if F_style = s2Triangle then	invalidate;
  end;
end;

{********************************************************************}
procedure Tshape2.set_pen_thickness(value:byte);
begin
  if value <> F_pen_thickness then
  begin
	F_pen_thickness := value;
	invalidate;
  end;
end;

{********************************************************************}
procedure Tshape2.set_filled(value : boolean);
begin
  if value <> f_filled then
  begin
	f_filled := value;
	invalidate;
  end;
end;

{********************************************************************}
procedure Tshape2.set_border_width(value:byte);
begin
  if value <> F_border_width then
  begin
	F_border_width := value;
	invalidate;
  end;
end;

procedure Tshape2.set_caption(value:string);
begin
	if (value <> f_caption) then
	begin
		f_caption := value;
		invalidate;
	end;
end;

{####################################################################}
procedure Tshape2.Paint;
var
  x1,y1,x2,y2,total_border:integer;
begin
  {-----------------------------------------------------}
  total_border := f_border_width + (F_pen_thickness div 2);
  x1:=total_border;
  y1:=total_border;
	x2 := width - total_border - F_shadow_depth;
  y2 := height - total_border - F_shadow_depth;

  {-----------------------------------------------------}
  with canvas do
  begin
	if F_filled then
	  brush.style := bssolid
	else
	  brush.style := bsClear;
	pen.width := F_pen_thickness;
  end;

  if F_shadow_depth > 0 then
  begin
	draw_shape(
	  x1+F_shadow_depth, y1+F_shadow_depth,
	  x2+F_shadow_depth, y2+F_shadow_depth,
	  F_shadow_colour, F_shadow_colour);
  end;

	draw_shape( x1, y1, x2, y2, f_pen_colour, f_fill_colour);
	canvas.TextOut((x1+x2-canvas.Textwidth(f_caption))div 2, (y1 +y2-canvas.TextHeight(f_caption)) div 2, f_caption);
end;

{********************************************************************}
procedure Tshape2.draw_shape(
	x1,y1,x2,y2:integer;
  pen_colour, fill_colour:Tcolor);
var
  dx,dy:integer;
  sqr_x1,sqr_y1,sqr_x2,sqr_y2:integer;
  xc,yc, min_dimension :integer;
begin
  {-------------------establish bounds------------------}
  xc := (x1+x2) div 2;
  yc := (y1+y2) div 2;
  dx := (x2 - x1) div 2;
  dy := (y2 - y1) div 2;
  min_dimension := min(dx,dy);
  sqr_x1:= xc-min_dimension;
  sqr_y1 := yc - min_dimension;
  sqr_x2 :=xc+min_dimension;
  sqr_y2 := yc + min_dimension;

  {-------------------set colours------------------}
  with canvas do
  begin
	pen.color := pen_colour;
	brush.color := fill_colour;
  end;

  {----------------draw------------------------------}
  with canvas do
	case f_style of
	  s2Square: rectangle(sqr_x1, sqr_y1, sqr_x2 ,sqr_y2);
	  s2Rectangle:rectangle(x1,y1,x2,y2);
	  s2RoundRect:Roundrect(x1,y1,x2,y2,F_fillet_radius, f_fillet_radius);
	  s2RoundSquare: Roundrect( sqr_x1, sqr_y1, sqr_x2 ,sqr_y2,F_fillet_radius, f_fillet_radius);
	  s2Triangle: draw_triangle(x1,y1,x2,y2,xc,yc);
	  s2Circle: ellipse(sqr_x1, sqr_y1, sqr_x2 ,sqr_y2);
	  s2Ellipse: ellipse(x1,y1,x2,y2);
	  s2irRegular: draw_regular_shape(xc, yc, dx ,dy);
	  s2regular: draw_regular_shape(xc,yc,min_dimension,min_dimension);
	end;
end;

{********************************************************************}
procedure Tshape2.draw_triangle(x1,y1,x2,y2,xc,yc:integer);
var
  triangle : array[1..3] of Tpoint;
begin
  case F_triangle_style of
	ttupright:
	  begin
		triangle[1].x := x1;	triangle[1].y :=y2;
		triangle[2].x := x2;	triangle[2].y :=y2;
		triangle[3].x := xc;	triangle[3].y :=y1;
	  end;

	ttleft:
	  begin
		triangle[1].x := x2;	triangle[1].y :=y1;
		triangle[2].x := x2;	triangle[2].y :=y2;
		triangle[3].x := x1;	triangle[3].y :=yc;
	  end;

	ttright:
	  begin
		triangle[1].x := x1;	triangle[1].y :=y2;
		triangle[2].x := x1;	triangle[2].y :=y1;
		triangle[3].x := x2;	triangle[3].y :=yc;
	  end;

	ttdown:
			begin
			 triangle[1].x := x1;  triangle[1].y :=y1;
			 triangle[2].x := x2;  triangle[2].y :=y1;
			 triangle[3].x := xc;  triangle[3].y :=y2;
			end;
	end;
	canvas.polygon(triangle);
end;

{********************************************************************}
procedure Tshape2.draw_regular_shape( xc,yc,w,h:integer);
var
	angle_increment, the_angle: degree;
	side_x, side_y, the_radian: real;
	side,x,y: integer;
begin
	angle_increment := 360 div F_regular_sides;
	regular_points^[0].x := xc;
	regular_points^[0].y := yc-h;

	the_angle := 0;
	for side :=2 to F_regular_sides do
	begin
		the_angle := the_angle + angle_increment;
		the_radian := g_misclib.degree_to_radian(the_angle);
		side_x := w * sin(the_radian);
		side_y := h * cos(the_radian);
		x := xc + round(side_x);
		y := yc - round(side_y);
		regular_points^[side -1].x := x;
		regular_points^[side -1].y := y;
	end;

	polygon(canvas.handle,regular_points^,F_regular_sides);
end;

{********************************************************************}
function Tshape2.get_radius:longint;
begin
	if not (csDesigning in ComponentState) then
		if (Style <> s2Circle) then
			raise EShape2Exception.Create('radius only applies to circle');
			
	result := width div 2;
end;

{********************************************************************}
function Tshape2.get_centre_point: TintPoint;
var
	aPoint: TintPoint;
begin
	aPoint.x := left + (width div 2);
	aPoint.y := top + (height div 2);
	result := apoint;
end;

{********************************************************************}
procedure Tshape2.set_centre_point(value:TintPoint);
var
	oldMousemove:TMouseMoveEvent;
begin
	//canvas.Pixels[value.x,value.y] := clBlack;
	oldMousemove := onMouseMove;
	onMouseMove := nil;
	left := value.x - (width div 2);
	top := value.y - (height div 2);
	onMouseMove := oldMousemove;
end;

//
//####################################################################
(*
	$History: Shape2.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/controls
 * 
 * *****************  Version 4  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/controls
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 3  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/controls
 * added headers and footers
*)
//####################################################################
//
end.

