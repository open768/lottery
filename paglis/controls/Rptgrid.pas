unit Rptgrid;
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
(* $Header: /PAGLIS/controls/Rptgrid.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//


interface

uses
	SysUtils, WinProcs, Classes, Graphics, Controls,
	Forms, Grids, misclib,miscimage;

type
	{Trepeatgrid -
			draws red rectngles around rectangles
			that repeat over consecutive rows }

	TRepeatGrid = class(TStringGrid)
	private
		{ Private declarations }
		procedure check_for_duplicates(
			how_many:longint; rect_color:tcolor; arow,acol: longint; arect:Trect;
			var has_duplicates:boolean);
		procedure highlite_rectangle(p_Row: longint;p_rect:trect; p_rect_colour: tcolor );
		function isCellSelected(arow,acol:longint):boolean;
  protected
	{ Protected declarations }
	procedure DrawCell(ACol, ARow: Longint; ARect: TRect; AState: TGridDrawState); override;
  public
	{ Public declarations }
  published
	{ Published declarations }
  end;

procedure Register;

implementation
const
  RED = $00ccccff;
  BLUE = $00ffffcc;
  GREEN = $00ccffcc;
	SILVER = $00ccffff;

procedure Register;
begin
  RegisterComponents('Paglis', [TRepeatGrid]);
end;

{===================================================================}
procedure TRepeatGrid.DrawCell(ACol, ARow: Longint; ARect: TRect; AState: TGridDrawState);
var
	this_text:string;
  has_dupl:boolean;
begin
		{and draw rectangles around data that is duplicated over previous rows}
		has_dupl := false;
		this_text := cells[acol,arow];
		if (acol >= fixedcols) and (arow > fixedrows) and (this_text <> '') then
		begin
			if arow>(fixedrows+3) then check_for_duplicates(4, silver, arow, acol, arect, has_dupl);
			if arow>(fixedrows+2) then check_for_duplicates(3, green,  arow, acol, arect, has_dupl);
			if arow>(fixedrows+1) then check_for_duplicates(2, blue,   arow, acol, arect, has_dupl);
			if arow>fixedrows	  then check_for_duplicates(1, red,	arow, acol, arect, has_dupl);
		end;

		{--------------drw the text-------------------}
		with canvas do
		begin
			brush.style:=bsclear;
			if (isCellSelected(arow,acol)) and (acol >= fixedcols)	then
				begin
					if (has_dupl) then
						font.color := clblue
					else
						font.color := clsilver;
				end
			else
				font.color := clblack;
			textout(arect.left+2, arect.top+2, this_text);

			if (isCellSelected(arow,acol) and has_dupl) then
			 with arect do
				rectangle(left,top,right,bottom)

	end;

end;

{===================================================================}
procedure TRepeatGrid.check_for_duplicates(
					how_many:longint;
					rect_color:tcolor;
					arow,acol: longint;
					arect:Trect;
					var has_duplicates:boolean);
var
  col,last_row: longint;
  this_text: string;
begin
  this_text := cells[acol,arow];
  last_row := arow-how_many;

  for col:=fixedcols to ColCount-1 do
	if cells[col,last_row] = this_text then
		begin
	  highlite_rectangle(arow,arect,rect_color);
			has_duplicates := true;
			break;
	end;
end;

{===================================================================}
procedure TRepeatGrid.highlite_rectangle(p_row: longint; p_Rect:trect; p_rect_colour: tcolor);
var
  old_colour: Tcolor;
	old_style : TBrushStyle;
		cell_colour: tColor;
begin
  with canvas do
	begin
		//--------------- save old colour --------------------- 
		old_colour := Pen.color;
		old_style := Brush.Style;

		//--------------- set new new colour ---------------------
		cell_colour := p_rect_colour;
		if self.Row = p_row then
			cell_colour :=  g_miscimage.get_dimmer_colour(p_rect_colour, 35);


		//--------------- draw with new colour ---------------------
		pen.color := cell_colour ;
		brush.color := cell_colour ;
		brush.style := bsSolid;
		Rectangle(p_rect.left, p_rect.top, p_rect.right, p_rect.bottom);

		//--------------- restore old colour ---------------------
		Pen.color := old_colour;
	brush.style := old_style;
  end; {with}
end;

function TRepeatGrid.isCellSelected(arow,acol:longint):boolean;
begin
	with selection do
		isCellSelected := (arow <= bottom) and (arow >= top) and (acol <=right) and (acol >= left);
end;

//
//####################################################################
(*
	$History: Rptgrid.pas $
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
