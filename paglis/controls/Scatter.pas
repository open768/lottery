unit Scatter;
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
(* $Header: /PAGLIS/controls/Scatter.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//


interface

uses
	wintypes, Messages, sysutils,Classes, Graphics, Controls,
	intgrid,realint,misclib, retained;

type
  ScatterChartTypes = (ctPoint, ctBlob, ctGrid, ctLines);

  TClickChartCellEvent = procedure(row,column:integer) of object;
  TScatterChart = class(TRetainedCanvas)
  private
	 { Private declarations }
		F_style: ScatterChartTypes;
		F_axis_colour: Tcolor;
		F_draw_axes: Boolean;
		F_click_cell:  TClickChartCellEvent;

		m_data: TIntegerGrid;
		m_painting, m_abort: Boolean;
		M_current_pair, m_mouse_position:Tpoint;
		m_cell_width, m_cell_height: RealInteger;
		m_font_width, m_font_height: Integer;
		m_max_value: integer;

		procedure set_style(value:ScatterChartTypes);
		procedure set_axis_colour(value:Tcolor);
		procedure set_draw_axes(value: Boolean);
		procedure recalculate_metrics;
		function get_cell_shape(row,col:integer):Trect;

		function get_value( row, column: integer): integer;
		procedure set_value( row, column, value:integer);
		function get_rows: integer;
		function get_columns: integer;
		function get_max_value: integer;
		function get_max_textwidth: integer;

		procedure draw_axes;
		procedure draw_cell(row,col:integer; rect:Trect);
		procedure draw_point(value:integer; rect:Trect);
		procedure draw_blob(value:integer; rect:Trect);
		procedure draw_grid(value:integer; rect:Trect);
		procedure draw_cross(x,y: integer);
		procedure draw_current_cell;
		procedure paint_crosshairs;

		procedure notify_click_cell(row,column:integer); dynamic;
	protected
		{ Protected declarations }
		procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
		procedure OnRedraw; override;
	procedure OnSetBounds; override;
		procedure OnCreate; override;
		procedure OnDestroy; override;
		procedure onPaint; override;
		procedure OnMouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
	public
		{ Public declarations }

		procedure reset;
		procedure increment( row,column: integer);
		procedure decrement( row,column: integer);
		procedure load_data(grid:TintegerGRid);
		property Value[ row, column: integer]: integer read get_value write set_value;
		property FontWidth: integer read m_font_width;

	published
		{ Published declarations }
		property Align;
		property Color;
		property enabled;
		property Font;
		property Hint;
		property ShowHint;
		property ParentColor;
		property ParentFont;
		property ParentShowHint;

		property AxisColor:Tcolor read F_axis_colour write set_axis_colour;
		property DrawAxes: Boolean read F_draw_axes write set_draw_axes;
		property Style:ScatterChartTypes read F_style write set_style;
		property OnClick: TClickChartCellEvent read F_click_cell write F_click_cell;
	end;

procedure Register;

implementation

uses
	winprocs; 
const
  DEFAULT_WIDTH= 100;
  DEFAULT_HEIGHT= 100;
  DEFAULT_STYLE = ctPoint;
	DEFAULT_AXIS_COLOUR = clBlack;
	NOT_IN_LIST = -1;
	MAX_BLOB_SIZE =15;
	BORDER = 1;
	UNSET = -666;
	TEXT_GAP = 2;
	MARKER_LENGTH = 4;

{####################################################################
 COMPONENT REGISTRATION
####################################################################}
procedure Register;
begin
  RegisterComponents('Paglis', [TScatterChart]);
end;

{####################################################################
 CONSTRUCTOR AND DESTRUCTOR
####################################################################}
procedure TScatterChart.OnCreate;
var
	i:integer;
begin
	F_style := DEFAULT_STYLE;
	F_axis_colour := DEFAULT_AXIS_COLOUR;
	F_draw_axes := false;
	m_data := TIntegerGrid.Create;
	m_data.NoExceptionOnGetError := true;
	m_abort := false;
	m_current_pair.x := UNSET;
	m_current_pair.y := UNSET;
	m_mouse_position.x := UNSET;
	m_mouse_position.y := UNSET;

	if (csDesigning in ComponentState) then
  begin
	setbounds(left,top, DEFAULT_WIDTH, DEFAULT_HEIGHT);
	for i:=1 to 10 do
	  set_value(i,i,i);
  end;
end;

{===================================================================}
procedure TScatterChart.OnDestroy;
begin
	m_abort := true;
	while m_painting do;

	{clean out the dynamic lists}
	m_data.Free;
end;

{####################################################################
 PUBLIC
####################################################################}
procedure TScatterChart.reset;
begin
	m_data.Clear;
	m_data.NoExceptionOnGetError := true;
  redraw;
end;

{===================================================================}
procedure TScatterChart.increment( row, column: integer);
begin
	if not assigned(m_data) then
		set_value(row,column,1)
	else
		set_value(row,column, get_value(row,column) +1);
end;

{===================================================================}
procedure TScatterChart.decrement( row, column: integer);
begin
  if not assigned(m_data) then
	set_value(row,column,-1)
  else
	set_value(row,column, get_value(row,column) -1);
end;

{===================================================================}
function TScatterChart.get_max_value: integer;
var
	max_value, value, row: integer;
  column, colFrom, colTo: word;
begin
	max_value :=0;

	{----------------iterate over the rows----------------}
	for row :=m_data.fromindex to m_data.toIndex do
	begin
		m_data.ColumnInfo(row, colFrom, colTo);
		for column:= colFrom to colTo do
		begin
			value := m_data.wordvalue[row,column];
			if value > max_value then
			 max_value := value;
		end;
	end;

	result := max_value;
end;


{===================================================================}
procedure TScatterChart.load_data(grid:TintegerGRid);
var
	next_draw_enabled, maxdiagonal, diagonal,row,column,data:word;
	colFrom,ColTo:word;
begin
	reset;

  {--------------- find max index -----------------------}
	colFrom := grid.FromColumnIndex;
	colTo := grid.ToColumnIndex;
	maxDiagonal := grid.toIndex;
	if colTo > maxDiagonal then maxDiagonal := colTo;

  {--------------- initialise ------------------}
	drawenabled := false;
	next_draw_enabled := grid.fromindex;
	style := ctlines;

	{--------------- work along diagonal ------------------}
	for diagonal := grid.fromIndex to	maxDiagonal do
	begin
		{- - - - - draw along row - - - - - - - - - -}
		if diagonal <= grid.toIndex then
			for column := colFrom to diagonal do
			begin
				data := grid.wordvalue[diagonal,column];
				value[diagonal,column] := data;
			end;

		{- - - - - draw along column - - - - - - - - - -}
		for row := grid.fromIndex to	grid.toIndex do
		begin
			if (row >= diagonal) then break;

			data := grid.wordvalue[row,diagonal];
			value[row,diagonal] := data;
		end;


		{draw every nth row}
		ProcessMessages;
		if diagonal= next_draw_enabled then
		begin
			drawenabled := true;
			drawenabled := false;
			if next_draw_enabled < 10 then
				next_draw_enabled := next_draw_enabled +1
			else
				next_draw_enabled := next_draw_enabled +4;
		end;
	end;

	style := ctgrid;
	drawenabled := true;
end;

{####################################################################
 PRIVATE
####################################################################}
procedure TScatterChart.recalculate_metrics;
var
	rows, columns: longint;
begin
		m_font_height := OffscreenCanvas.textheight('0');
		m_font_width := get_max_textwidth;
		m_max_value := get_max_value;

		rows := get_rows;
		if rows <=0 then exit;

		columns := get_columns;
		if columns <=0 then exit;

		{------------------recalculate cell size----------------}
		if f_draw_axes then
			begin
			 m_cell_width := int_to_realint(width - m_font_width - border) div columns;
			 m_cell_height := int_to_realint(height - m_font_height - border) div rows;
			end
		else
			begin
			 m_cell_width := int_to_realint(width ) div columns;
			 m_cell_height := int_to_realint(height) div rows;
			end;
end;

{===================================================================}
function TScatterChart.get_cell_shape(row,col:integer):Trect;
var
		real_x,real_y:realinteger;
		rect:Trect;
begin
	{-----------------------------------------------------------------}
	if F_draw_axes then
		real_y := int_to_realint(height - BORDER - m_font_height)
	else
		real_y := int_to_realint(height);

	if F_draw_axes then
		real_x := int_to_realint(m_font_width + BORDER)
	else
		real_x := 0;

	{-----------------------------------------------------------------}
	real_y := real_y - ((row-m_data.fromindex+1) * m_cell_height);
	real_x := real_x + ((col-m_data.fromColumnindex+1) * m_cell_width);

	with rect do
	begin
		left := trunc_realint(  real_x -	 m_cell_width);
		top := trunc_realint(  real_y +  m_cell_height);
		right := trunc_realint(  real_x);
		bottom := trunc_realint(	real_y);
	end;

	get_cell_shape := rect;
end;

{===================================================================}
procedure TScatterChart.OnMouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
	rel_x, rel_y: Realinteger;
begin
	//----dont go here if cells have no width
	if m_cell_width = 0 then exit;

	//---------
	if F_draw_axes and ((x < m_font_width) or (y>height-m_font_height)) then
		exit
  else
	begin
	  if F_draw_axes then
			 begin
				 rel_x := int_to_realint(x - m_font_width - border);
			rel_y := int_to_realint(height - y - border - m_font_height);
		end
	  else
		begin
				 rel_x := int_to_realint(x);
			rel_y := int_to_realint(height - y);
		end;

		m_current_pair.x := m_data.fromColumnIndex+ (rel_x div m_cell_width);
	  m_current_pair.y := m_data.fromIndex+ (rel_y div m_cell_height);
	  redraw;

	  notify_click_cell(m_current_pair.y, m_current_pair.x);
		end;
end;

{####################################################################
 MESSAGE HANDLERS
####################################################################}

{===================================================================}
procedure TScatterChart.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if F_draw_axes and ((x < m_font_width) or (y>height-m_font_height)) then
	begin
			m_mouse_position.x := UNSET;
			m_mouse_position.y := UNSET;
		end
	else
		begin
			m_mouse_position.x := x;
	  m_mouse_position.y := y;
	  paint;
	end;

end;


{===================================================================}
procedure TScatterChart.notify_click_cell(row,column:integer);
begin
   if assigned(F_click_cell) then
	  F_click_cell(row,column);
end;

{####################################################################
 PROPERTY ACCESS METHODS
####################################################################}

{===================================================================}
procedure TScatterChart.set_draw_axes(value: Boolean);
begin
  if value <> F_draw_axes then
  begin
	F_draw_axes := value;
	redraw;
  end;
end;

{===================================================================}
procedure TScatterChart.set_style(value:ScatterChartTypes);
begin
  if value <> F_style then
  begin
	F_style := value;
	redraw;
  end;
end;

{===================================================================}
procedure TScatterChart.set_axis_colour(value:Tcolor);
begin
  if value <> F_axis_colour then
  begin
	F_axis_colour := value;
	redraw;
	end;
end;

{===================================================================}
function TScatterChart.get_value( row, column: integer): integer;
begin
  if (m_data <> nil) then
		get_value := m_data.wordValue[row,column]
	else
		get_value := 0;
end;

{===================================================================}
procedure TScatterChart.set_value( row, column, value: integer);
var
	rowFrom, rowTo, colFrom, colTo:word;
  needs_recalc: Boolean;
begin

	rowFrom := m_data.fromIndex;
	rowTo := m_data.ToIndex;
	colFrom := m_data.fromColumnIndex;
	colTo := m_data.ToColumnIndex;

	m_data.wordValue[row,column] := value;

	needs_recalc := false;
	if (rowFrom <> m_data.fromIndex) then needs_recalc := true;
	if (rowTo <> m_data.ToIndex) then needs_recalc := true;
	if (colFrom <> m_data.fromColumnIndex) then needs_recalc := true;
	if (colTo <> m_data.ToColumnIndex) then needs_recalc := true;

	if needs_recalc then recalculate_metrics;
	redraw;
end;

{===================================================================}
function TScatterChart.get_rows: integer;
begin
	result := m_data.toindex - m_data.fromindex +1;
end;

{===================================================================}
function TScatterChart.get_columns: integer;
begin
	result := m_data.toColumnindex - m_data.fromColumnindex +1;
end;

{===================================================================}
function TScatterChart.get_max_textwidth: integer;
var
  row, row_width, max_width: integer;
begin
  max_width := -1;

  for row :=m_data.fromindex to m_data.toindex do
  begin
	row_width := OffscreenCanvas.textwidth( IntToStr(row));
		if row_width > max_width then
	  max_width := row_width;
  end;

  get_max_textwidth := max_width;
end;



procedure TScatterChart.OnPaint;
begin
	paint_crosshairs;
end;

{####################################################################
 PRIVATE drawing routines
####################################################################}

{---------------------------------------------------------}
procedure TScatterChart.OnSetBounds;
begin
	recalculate_metrics;
end;

{===================================================================}
procedure TScatterChart.Onredraw;
var
		row,col,rows,columns: integer;
	rect:Trect;
begin
		rows := get_rows;
		columns := get_columns;
		if ((rows=0) or (columns=0)) then exit;

		{-----------do the drawing---------------}
		for row := m_data.fromIndex to m_data.toIndex do
			for col := m_data.fromColumnIndex to m_data.toColumnIndex  do
			begin
				rect := get_cell_shape(row,col);
				draw_cell(row,col,rect);
			end;

		draw_current_cell;
		if f_draw_axes then draw_axes;

end;

{===================================================================}
procedure TScatterChart.draw_cell(row,col:integer; rect:Trect);
var
	value : integer;
begin
	value := m_data.Wordvalue[row, col];
	if value > 0 then
		case F_style of
			ctPoint:  draw_point(value,rect);
			ctBlob:	draw_blob(value,rect);
			ctGrid,ctLines:	draw_grid(value,rect);
	end;
end;

{===================================================================}
procedure TScatterChart.draw_point(value:integer; rect:Trect);
var
  x,y: integer;
begin
	with rect do
	begin
		x := (left+right) div 2;
		y := (top+bottom) div 2;
	end;
	draw_cross(x,y);
end;

{===================================================================}
procedure TScatterChart.draw_blob(value:integer; rect:Trect);
var
	value_factor: real;
	radius:integer;
	x,y:integer;
begin
	{----------------------find centre------------------------}
	with rect do
	begin
		x := (left+right) div 2;
		y := (top+bottom) div 2;
	end;

	{----------------------work out scale--------------------}
	value_factor := MAX_BLOB_SIZE / (m_max_value*2);

	{----------------draw this blob--------------------------}
	radius := round(value_factor * value);
	if radius <=1 then
		draw_cross(x,y)
	else
		with OffscreenCanvas do
		begin
			brush.style := bssolid;
			brush.color := clblack;
			pen.color := clblack;
			ellipse(x-radius,y-radius,x+radius,y+radius);
		end;
end;

{===================================================================}
procedure TScatterChart.draw_grid(value:integer; rect:Trect);
var
	gray, red: Tcolor;
begin
	red := round( $FF * (value * 1.0)/ (m_max_value * 1.0));

	gray := rgb(red,red,red);

	with OffscreenCanvas do
	begin
		pen.color := gray;
		brush.color := gray;
		if F_style=ctlines then
			brush.style := bsclear
		else
			brush.style := bsSolid;

		with rect do
			rectangle (	left,top,right,bottom);
	end;
end;

{===================================================================}
procedure TScatterChart.draw_cross(x,y: integer);
begin
	with OffscreenCanvas do
	begin
		pixels[x-1,y] := F_axis_colour;
		pixels[x+1,y] := F_axis_colour;
		pixels[x,y] := clwhite;
		pixels[x,y-1] := F_axis_colour;
		pixels[x,y+1] := F_axis_colour;
	end;
end;

{===================================================================}
procedure TScatterChart.draw_axes;
var
  row,col:integer;
  cell_x1, cell_y1, cell_x2,cell_y2, text_x, text_y: realinteger;
  text_width, text_height: realinteger;
  x,y,last_x, last_y,marker_x, marker_y: integer;
  text: string;
begin
  with OffscreenCanvas do
  begin
	pen.color := clblack;
	brush.style := bsclear;
  end;

  {--------------- draw text along the horizontal ------------}
	cell_x1 := int_to_realint(m_font_width);
  y := height - m_font_height;
  last_x := 0;
  for col := m_data.fromColumnINdex to m_data.ToColumnINdex do
  begin
	cell_x2 := cell_x1 +m_cell_width;
		text := inttostr(col);
		text_width := OffscreenCanvas.textwidth(text);
		text_x := (cell_x1 + cell_x2 - int_to_realint(text_width)) div 2;
	marker_x :=  trunc_realint(cell_x1 + cell_x2) div 2;

	x := trunc_realint(text_x);
	with OffscreenCanvas do
	  begin
	  pen.color := clgray;
	  moveto(marker_x, y);
	  lineto(marker_x, y+MARKER_LENGTH);

			if x > last_x then
	  begin
		pen.color := clblack;
		textout( x,y, text);
		last_x := x + text_width + TEXT_GAP;
	  end;
	end;
	cell_x1 := cell_x2;
	end;

  {--------------- draw text along the vertical ------------}
	cell_y1 := 0;
	cell_x1 := 0;
	cell_x2 := int_to_realint(m_font_width);
	text_height := int_to_realint(m_font_height);
	last_y := 0;

  for row := m_data.toIndex downto m_data.FromIndex do
  begin
	cell_y2 := cell_y1 + m_cell_height;
	text := inttostr(row);
	text_width := int_to_realint(OffscreenCanvas.textwidth(text));

	text_y := (cell_y1 + cell_y2 - text_height) div 2;
	text_x := (cell_x1 + cell_x2 - text_width) div 2;
	x := trunc_realint(text_x);
	y := trunc_realint(text_y);
		marker_y :=  trunc_realint(cell_y1 + cell_y2) div 2;

		with OffscreenCanvas do
		begin
			pen.color := clgray;
			moveto(m_font_width, marker_y);
			lineto(m_font_width-MARKER_LENGTH, marker_y);

			if y > last_y then
			begin
			 pen.color := clblack;
			 textout( x,y, text);
		last_y := y + m_font_height + TEXT_GAP;
	  end
	end;

	cell_y1 := cell_y2
  end;

  {--------------- draw border ----------------------------}
  with OffscreenCanvas do
  begin
	pen.color := clblack;
	pen.width := BORDER;
		moveto( m_font_width,0);
		lineto( m_font_width,height);
		moveto( 0, height-m_font_height);
	lineto( width, height-m_font_height);
  end;

end;

{===================================================================}
procedure TScatterChart.draw_current_cell;
var
  row,col:integer;
  rect: trect;
begin
	row := m_current_pair.y;
  col := m_current_pair.x;

  {----------------------------------------------------------------}
  if (row = UNSET) then exit;

	{----------------------------------------------------------------}
	rect := get_cell_shape(row,col);

	{----------------------------------------------------------------}
	with rect do
		with OffscreenCanvas do
		begin
			pen.color := clred;
			brush.color := clred;
			brush.style := bssolid;
			with rect do
				rectangle (  left,top,right,bottom);

			g_misclib.draw_3d_rectangle(OffscreenCanvas,left,top,right,bottom,true);
		end;


end;

{===================================================================}
procedure TScatterChart.paint_crosshairs;
var
  x,y: integer;
begin
	x := m_mouse_position.x;
  y := m_mouse_position.y;

  if (x <> UNSET) then
	with canvas do
	begin
	  {------------------white lines -------------------------}
	  pen.color := clwhite;
	  pen.width := 1;

			moveto(x-1,0);
	  lineto(x-1,height);
	  moveto(x+1,0);
	  lineto(x+1,height);

	  moveto(0,y-1);
	  lineto(width,y-1);
	  moveto(0,y+1);
	  lineto(width,y+1);

	  {------------------black lines -------------------------}
			pen.color := clblack;

	  moveto(x,0);
	  lineto(x,height);

	  moveto(0,y);
	  lineto(width,y);
	end;

end;



//
//####################################################################
(*
	$History: Scatter.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/controls
 * 
 * *****************  Version 6  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/controls
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 5  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/controls
 * added headers and footers
*)
//####################################################################
//
end.

