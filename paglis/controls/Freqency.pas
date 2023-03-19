unit Freqency;
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
(* $Header: /PAGLIS/controls/Freqency.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//


interface

uses
	classes, controls, forms, graphics, retained, intlist;
type
  ChartTypes = (ctBar, ctPie, ctGraph,ctVertGraph);

	TClickColumnEvent = procedure(column:integer) of object;

	TFrequencyChart = class(TRetainedCanvas)
	private
		{ Private declarations }
		F_style: ChartTypes;
		F_axis_colour: Tcolor;
		F_Filled: boolean;
		F_Font_Height: word;
		F_click_Column: TClickColumnEvent;
		f_draw_x_on_graph: boolean;
		f_highlighted_column: integer;
		m_list: Tintlist;

		procedure pr_set_style(value:ChartTypes);
		procedure pr_set_axis_colour(value:Tcolor);
		procedure pr_set_filled(value:Boolean);
		procedure set_font_height(value: word);

		function get_value( key: integer): integer;
		procedure set_value( key: integer; value:integer);
		procedure free_list;
		function get_max_value: integer;
		function get_sum: integer;
		function get_fromindex: word;
		function get_toindex: word;

		procedure pr_draw_pie;
		procedure pr_draw_bars;
		procedure pr_draw_graph;
		procedure pr_draw_vert_graph;
		procedure pr_draw_resampled_graph;
		procedure pr_draw_axes;
		procedure pr_draw_vert_axes;
		function brush_colour(element:integer): Tcolor;
		procedure set_highlighted_column(col: integer);

		procedure notify_click_column(column:integer); dynamic;

  protected
	 { Protected declarations }
		procedure OnMouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
		procedure Onredraw; override;
		procedure OnCreate; override;
		procedure OnDestroy; override;

	public
		{ Public declarations }
		procedure reset;
		procedure increment( key: integer);
		procedure decrement( key: integer);
		property value[ key: integer]: integer read get_value write set_value;
		property FromIndex: word read get_fromindex;
		property ToINdex: word read get_toindex;

	published
	 { Published declarations }
		property Font;
		property Align;
		property FontHeight: word read F_Font_height write set_font_height;
		property Filled: Boolean read F_filled write pr_set_filled;
		property Hint;
		property ShowHint;
		property ParentColor;
		property ParentFont;
		property Color;
		property DrawEnabled;
		property AxisColor:Tcolor read F_axis_colour write pr_set_axis_colour;
		property Style:ChartTypes read F_style write pr_set_style;
		property OnClick: TClickColumnEvent read F_click_Column write F_click_Column;
		property XOnGraph:boolean read f_draw_x_on_graph write f_draw_x_on_graph;
		property HighlightedColumn: integer read f_highlighted_column write set_highlighted_column;
  end;

procedure Register;

implementation
uses
  SysUtils, WinTypes, WinProcs, Messages, 
  Dialogs, misclib, realint, math;
const
  DEFAULT_FILLED= true;
  DEFAULT_WIDTH= 100;
  DEFAULT_HEIGHT= 100;
  DEFAULT_STYLE = ctBar;
  DEFAULT_AXIS_COLOUR = clBlack;
  NOT_IN_LIST = -1;
  DEFAULT_FONT_HEIGHT = 7;
  GAP_AROUND_TEXT = 2;
  NUMBER_STRING = '0123456789';
  MIN_BAR_WIDTH = 2.0;

{################################################################
 # COMPONENT REGISTRATION
 ################################################################}
procedure Register;
begin
	RegisterComponents('Paglis', [TFrequencyChart]);
end;

{################################################################
 # PUBLIC
 ################################################################}
procedure TFrequencyChart.OnCreate;
var
  item: integer;
begin
	F_style := DEFAULT_STYLE;
	F_axis_colour := DEFAULT_AXIS_COLOUR;
	F_filled := DEFAULT_FILLED;
	F_font_height := DEFAULT_FONT_HEIGHT;
	f_highlighted_column := NOT_IN_LIST;
	f_draw_x_on_graph:= false;
	
	{no memory allocated yet}
	m_list := Tintlist.create;
	m_list.noExceptionOnGetError := true;

	{default size when designing}
	if indesignmode then
	begin
		setbounds(left,top, DEFAULT_WIDTH, DEFAULT_HEIGHT);
		for item:=1 to 10 do
			set_value(item,item);
	end;
end;

{************************************************************}

procedure TFrequencyChart.OnDestroy;
begin
	{clean out the dynamic lists}
	m_list.free;
end;

{################################################################
 # PROPERTY ACCESS METHODS
 ################################################################}
function TFrequencyChart.get_value( key: integer): integer;
begin
	result := m_list.integerValue[key];
end;

{************************************************************}
function TFrequencyChart.get_max_value: integer;
var
  max_value, value: integer;
  element: integer;
begin
  max_value := 1;

  for element:= m_list.fromindex to m_list.toindex do
	begin
	value := m_list.integerValue[element];
	if value > max_value then
	  max_value := value;
  end;

  result := max_value;
end;

{************************************************************}
function TFrequencyChart.get_sum: integer;
var
	sum, element:integer;
begin
	sum := 0;
	for element := m_list.fromindex to m_list.toindex do
		sum := sum + m_list.integerValue[element];
	result := sum;
end;

{************************************************************}
procedure TFrequencyChart.set_value( key: integer; value:integer);
begin
	m_list.integerValue[key] := value;
	redraw;
end;

{************************************************************}
procedure TFrequencyChart.pr_set_filled(value:Boolean);
begin
	if value <> F_Filled then
	begin
		F_Filled := value;
		redraw;
	end;
end;

{************************************************************}
procedure TFrequencyChart.set_font_height(value:word);
begin
	if value <> F_font_height then
	begin
		F_font_height := value;
		redraw;
	end;
end;

{************************************************************}
procedure TFrequencyChart.pr_set_style(value:ChartTypes);
begin
	if value <> F_style then
	begin
		F_style := value;
	redraw;
  end;
end;

{************************************************************}
procedure TFrequencyChart.pr_set_axis_colour(value:Tcolor);
begin
  if value <> F_axis_colour then
  begin
		F_axis_colour := value;
		redraw;
	end;
end;


{************************************************************}
function  TFrequencyChart.get_fromindex: word;
begin
	get_fromindex := m_list.fromINdex;
end;

{************************************************************}
function TFrequencyChart.get_toindex: word;
begin
	get_toindex := m_list.toINdex;
end;

{################################################################
 # PRIVATE drawing routines
 ################################################################}
procedure TFrequencyChart.Onredraw;
begin
	{-----------do the drawing---------------}
	if m_list.hasobjects then
  begin
	with OffscreenCanvas do
	begin
	  pen.color := F_axis_colour;
	  if F_Filled then
		brush.style := bsSolid
	  else
		brush.style := bsClear;
	end;

	case F_style of
		ctBar:	begin pr_draw_bars; pr_draw_axes; end;
		ctGraph:	begin pr_draw_graph; pr_draw_axes; end;
		ctVertGraph:	begin pr_draw_vert_graph; pr_draw_vert_axes; end;
		ctPie:	pr_draw_pie;
		end;
	end;

end;

{************************************************************}
procedure TFrequencyChart.pr_draw_pie;
var
	rect_x1, rect_x2, rect_y1, rect_y2: integer;
	x_origin, y_origin:integer;
	diameter, radius, element: integer;
	pie_x1, pie_x2, pie_y1, pie_y2: integer;
	sum : integer;
	angle: radian;
begin
	{----------------------initialise----------------------}
	diameter := min(width,height);
	radius := diameter div 2;

	x_origin := width div 2;
	y_origin := height div 2;
	rect_x1 := x_origin - radius;
	rect_y1 := y_origin - radius;
	rect_x2 := rect_x1 + diameter;
	rect_y2 := rect_y1 + diameter;

	pie_x1 := x_origin + radius;
	pie_y1 := y_origin;

	sum := get_sum;

	{------------work out angle of each pie segment----------}
	for element := m_list.fromindex to m_list.toindex	do
	begin
		angle := (m_list.integerValue[element]/sum) * 2.0 * PI;
		pie_x2 := x_origin + round(radius * cos(angle));
		pie_y2 := y_origin + round(radius * sin(angle));

		with OffscreenCanvas do
		begin
			  if F_Filled then
				 brush.color := brush_colour(element)
			else
			pen.color := brush_colour(element);

			pie( rect_x1, rect_y1, rect_x2, rect_y2, pie_x1, pie_y1, pie_x2, pie_y2);
		end;				{with}

		{- - - - -last angle is start angle for next segment- - - - - }
		pie_x1 := pie_x2;
		pie_y1 := pie_y2;
	end;		   {for}

end;

{************************************************************}
procedure TFrequencyChart.pr_draw_bars;
var
  bar_height: real;
  bar_width,  bar_right : realinteger;
  column, x1 ,last_x,x2, y1, y2, xt, max_val: integer;
  percentage_height : real;
  bottom_bit: integer;
  caption : string;
  brush_style : Tbrushstyle;
begin
  {----------------------- initialise ---------------------------}
  if  m_list.count =1 then
		bar_width := width-2
  else
		bar_width := to_RealInt( (width - 2) / m_list.count) ;

  max_val := get_max_value;
  bar_right := to_RealInt(1.0);
  last_x := 0;

  x1 := 1;
  bottom_bit := OffscreenCanvas.textheight(NUMBER_STRING) + GAP_AROUND_TEXT;
  y1 := height- bottom_bit;

  {----------------------- draw each bar -------------------------}
  for column := m_list.fromindex to m_list.toIndex do
  begin
	percentage_height :=  m_list.integerValue[column]/max_val;
		bar_height :=  percentage_height * (height - bottom_bit - 2);
		bar_right := bar_right + bar_width;

	x2 := trunc_realint(bar_right);
	y2 := y1 - round(bar_height);

	with OffscreenCanvas do
	begin
	  brush.color := brush_colour(column);
	  if F_Filled then
		brush_style := bsSolid
	  else
		brush_style := bsclear;

	  {- - - - - - - - - - -draw the bar in appropriate colour- - - }
	  brush.style := brush_style;
	  pen.color := brush_colour(column);
	  rectangle(x1, y1, x2, y2);

	  if (column = F_highlighted_column) then
			begin
			 pen.color := clblack;
		moveto (x1,y1);
		lineto (x2,y2);
		moveto (x2,y1);
		lineto (x1,y2);
	  end;

	  {- - - - - - - - -and the caption - - - - - - - -}
	  font.size := f_font_height;
	  font.color := clblack;
	  pen.color := clblack;
	  if column = F_highlighted_column then
		begin
			brush.color := clwhite;
			brush.style := bssolid;
		end
	  else
		brush.style := bsClear;


			caption := inttostr(column);
			xt := x1 + (x2 - x1 - TextWidth(caption)) div 2;

			if (xt > last_x) or	(column = f_highlighted_column) then
			begin
			 textout( xt,y1,caption);
			 last_x := xt + textwidth(caption) + GAP_AROUND_TEXT;
			end;
		end;

		x1 := x2;
	end;
end;

//************************************************************
// This resamples the data
//TODO has weird results , need to display hi and low points for bar.
//************************************************************
procedure TFrequencyChart.pr_draw_resampled_graph;
var
	n_bars: integer;
	riCount, riInterval, riIndex: RealInteger;
	iBarIndex, iResampledIndex, iBetweenIndex, iBetweenValue, iLastResampIndex,ilow,ihigh,iResampledValue: integer;
	bar_width, fHiHeight,fLowHeight, bar_right: real;
	iY,iXmid ,iMaxChartValue: integer;
begin
	n_bars := width;
	riCount := int_to_realint(m_list.count);
	riInterval := riCount div n_bars;

	riIndex :=0;
	iMaxChartValue := get_max_value;
	bar_right := 1.0;
	bar_width := (width - 2) / n_bars;
	iLastResampIndex := 0;

	for iBarIndex := 1 to n_bars do
	begin
		//-------get resampling point ----------------------------
		iResampledIndex := trunc_realint(riIndex);
		iResampledValue := m_list.integerValue[iResampledIndex];

		//-------get maximum and minimum between this and last point
		ihigh := iResampledValue;
		ilow := iResampledValue;
		for iBetweenIndex := iLastResampIndex to iResampledIndex do begin
			iBetweenValue := m_list.integerValue[iBetweenIndex];
			if iBetweenValue > ihigh then ihigh := iBetweenValue;
			if iBetweenValue < ilow then ilow := iBetweenValue;
		end;
		iLastResampIndex := iResampledIndex;

		//-------draw line indicating hi and low values------------
		ixmid := round(bar_right - (bar_width/2));
		fLowHeight := (height - 2) *(ilow/iMaxChartValue);
		fHiHeight :=  (height - 2) *(ihigh/iMaxChartValue);
		iy := height - round(fLowHeight);
		OffscreenCanvas.moveto(ixmid, iy);
		iy := height - round(fHiHeight);
		OffscreenCanvas.lineto(ixmid,iy);

		{--------------------------------------------------------}
		bar_right := bar_right + bar_width;
		riIndex := riIndex + riInterval;
	end;
end;

{************************************************************
 * This doesnt resamples the data
 ************************************************************}
procedure TFrequencyChart.pr_draw_graph;
var
	bar_width, bar_height, bar_right: real;
	element, x1, x2, y1, y2, max_val: integer;
	point_x, point_y, last_x, last_y: integer;
	percentage_height: real;
	resample: Boolean;
begin
	{----------------------- initialise ---------------------------}
	bar_width := (width - 2) / m_list.count;
	resample := ( bar_width < MIN_BAR_WIDTH);
	if (resample) then
	begin
		pr_draw_resampled_graph;
		exit;
	end;

	max_val := get_max_value;
	bar_right := 1.0;

	x1 := 1;
	y1 := height;
	last_x := 0;
	last_y := 0;

	{----------------------- draw each point -------------------------}
	for element := m_list.fromindex to m_list.toINdex do
	begin
		percentage_height :=	m_list.integerValue[element]/max_val;
		bar_height :=  percentage_height * (height - 2);

		bar_right := bar_right + bar_width;
		x2 := round(bar_right);
		y2 := y1 - round(bar_height);
		point_x := (x2 + x1) div 2;
		point_y := y2;

		with OffscreenCanvas do
		begin
			{---------------------------------------------------------------}
			if element > m_list.fromindex then
			begin
				moveto(last_x, last_y);
				lineto(point_x, point_y);
			end;

			{---------------------------------------------------------------}
			if f_draw_x_on_graph then
			begin
				MoveTo(point_x-3, point_y-3);
				LineTo(point_x+3, point_y+3);
				MoveTo(point_x+3, point_y-3);
				LineTo(point_x-3, point_y+3);
			end;
		end;

		x1 := x2;
		last_x := point_x;
		last_y := point_y;
	end;

end;

{************************************************************}
procedure TFrequencyChart.pr_draw_vert_graph;
var
	bar_height: real;
	point:tpoint;
	element, max_val: integer;
	percentage_width: real;
	resample: Boolean;
	real_y:real;
begin
	{----------------------- initialise ---------------------------}
	bar_height := (Height - 2) / m_list.count;   //fixed number of bars

   //-----------if bar width too small resample
	resample := ( bar_height < MIN_BAR_WIDTH);
	if (resample) then
	begin
		pr_draw_resampled_graph;	//Todo
		exit;
	end;

	//--------------continue initialising
	max_val := get_max_value;
	real_y := height - bar_height /2;
	OffscreenCanvas.MoveTo(0,height);

	{----------------------- draw each point -------------------------}
	for element := m_list.fromindex to m_list.toINdex do
	begin
		//-------- size of bar
		percentage_width :=  m_list.integerValue[element]/max_val;
		point.x :=  round(percentage_width * (width - 2));

		//paint it
		with OffscreenCanvas do
		begin
			{---------------------------------------------------------------}
			point.y := round(real_y);
			lineto(point.x, point.y);

			{---------------------------------------------------------------}
			if f_draw_x_on_graph then
			begin
				MoveTo(point.x-3, point.y-3);
				LineTo(point.x+3, point.y+3);
				MoveTo(point.x+3, point.y-3);
				LineTo(point.x-3, point.y+3);
			end;
		end;

		real_y := real_y - bar_height; 
	end;

end;

{************************************************************}
procedure TFrequencyChart.pr_draw_axes;
var
  max_val: integer;
  division_height, division_y : real;
  divisions, division, y: integer;
  old_pen_mode: TPenMode;
begin
  with	OffscreenCanvas do
  begin
	 pen.color := F_axis_colour;
	 moveto (0, height);
	 lineto (width,height);
  end;

  {----------------------- draw scale lines -------------------------}
  if m_list.count = 0 then exit;

  max_val := get_max_value;
  if max_val < 10 then
	 divisions := max_val
  else if max_val < 40 then
	 divisions := max_val div 2
  else
	 divisions := max_val div 10;

  division_height := height / divisions;
  division_y := division_height;

  with	 OffscreenCanvas do
  begin
	 old_pen_mode := pen.mode;
	 pen.mode := pmNotXor;
	 pen.color := self.color;
  end;

  for division:=1 to divisions do
  begin
	 y := round(division_y);
	 with	OffscreenCanvas do
	 begin
		moveto(0,y);
		lineto(width,y);
	 end;
	 division_y := division_y + division_height;
  end;
	OffscreenCanvas.pen.mode := old_pen_mode;

end;

{************************************************************}
procedure TFrequencyChart.pr_draw_vert_axes;
var
  max_val: integer;
  division_width, division_x : real;
  divisions, division, x: integer;
  old_pen_mode: TPenMode;
begin
  with	OffscreenCanvas do
  begin
	pen.color := F_axis_colour;
	moveto (0, height);
	lineto (width,height);
  end;

  {----------------------- draw scale lines -------------------------}
  if m_list.count = 0 then exit;

  //--------figure out how to draw divisions
  max_val := get_max_value;
  if max_val < 10 then
	divisions := max_val
  else if max_val < 40 then
	divisions := max_val div 2
  else
	divisions := max_val div 10;

  division_width := width / divisions;
  division_x := division_width;

  //-------change colour
  with	 OffscreenCanvas do
  begin
	old_pen_mode := pen.mode;
	pen.mode := pmNotXor;
	pen.color := self.color;
  end;

  //------------draw lines
  for division:=1 to divisions do
  begin
	 x := round(division_x);
	 with	OffscreenCanvas do
	 begin
		moveto(x,0);
		lineto(x,height);
	 end;
	 division_x := division_x + division_width;
  end;

  //-----------restore colour
	OffscreenCanvas.pen.mode := old_pen_mode;

end;

{################################################################
 # PRIVATE
 ################################################################}
procedure TFrequencyChart.reset;
begin
	free_list;
	f_highlighted_column := NOT_IN_LIST;
	redraw;
end;

{************************************************************}
procedure TFrequencyChart.increment( key: integer);
begin
  set_value(key, get_value(key) +1 )
end;

{************************************************************}
procedure TFrequencyChart.decrement( key: integer);
var
  previous: integer;
begin
  previous := get_value(key);
	if previous >0 then
		set_value(key, previous-1);
end;

procedure TFrequencyChart.free_list;
begin
	if (m_list = nil) then exit;
	m_list.clear;
end;


{************************************************************}
function TFrequencyChart.brush_colour(element:integer): Tcolor;
var
  index: Tcolor;
begin
  index := element mod 4;
  case index of
	0:	result := clred;
	1:	result := clgreen;
	2:	result := clblue;
	else  result := clwhite;
  end;
end;


{************************************************************}
procedure TFrequencyChart.OnMouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
	bar_width : real;
	column: integer;
begin
	if (F_style = ctbar) and (m_list.count >0)then
  begin
	bar_width := (width - 2) / (m_list.count);
		column := m_list.fromindex + trunc( x/bar_width);
		f_highlighted_column := column;

		redraw;
		notify_click_column(column);
	end;
end;

{************************************************************}
procedure TFrequencyChart.notify_click_column(column:integer);
begin
	if assigned(F_click_column) then
		F_click_column(column);
end;

procedure TFrequencyChart.set_highlighted_column(col: integer);
begin
	if col <> f_highlighted_column then
		if (col >= fromindex) and (col <= toindex) then
		begin
			f_highlighted_column := col;
			redraw;
		end;
end;

//
//####################################################################
(*
	$History: Freqency.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/controls
 * 
 * *****************  Version 12  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/controls
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 11  *****************
 * User: Administrator Date: 9/01/05    Time: 5:30p
 * Updated in $/code/paglis/controls
 * fixed drawing of resampled graph
 * 
 * *****************  Version 10  *****************
 * User: Administrator Date: 6/01/05    Time: 7:36p
 * Updated in $/code/paglis/controls
 * corrected CARB fluff
 * 
 * *****************  Version 8  *****************
 * User: Administrator Date: 2/01/05    Time: 6:19p
 * Updated in $/code/paglis/controls
 * updated to reflect change to tsparselist
 * 
 * *****************  Version 7  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/controls
 * added headers and footers
*)
//####################################################################
//
end.