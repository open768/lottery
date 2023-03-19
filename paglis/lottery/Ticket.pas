unit Ticket;

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
(* $Header: /PAGLIS/lottery/Ticket.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//


interface

uses
	extctrls, SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
	Forms, Dialogs,lottype, lottrender, lottpref, intlist, intstack, realint,retained;
type
	TClickNumberEvent = procedure(number:byte; bonus:boolean) of object;
	LotteryTicketStyle=(LtsNumbers, LtsColouredNumbers, LtsCircles, LtsColouredBalls, LtsCamelot, LtsRendered, LtsMarkedRendered);
	LotteryTicketHideStyle=(LthsHide, LthsCross, LthsGrey, LthsGreyAndCross);
	ELotteryTicket = class (Exception);

	TLotteryTicket = class(TRetainedCanvas)
	private
		// Private declarations
		f_bonus_stack, f_number_stack: tintstack; 
		f_start_at_zero: boolean;
		f_start_number: byte;
		f_auto_resize: boolean;
		f_click: tclicknumberevent;
		f_display_style: lotteryticketstyle;
		f_marked, f_bonus_marked, f_in_play, f_drawn, f_guessed: tintlist;
		f_max_numbers: word;
		f_max_highlighted: byte;
		f_max_bonus_highlighted: byte;
		f_bonus_overlaps_numbers: boolean;
		f_columns: byte;
		f_n_in_play: byte;
		f_hide_style:  lotterytickethidestyle;
		f_enable_animation:boolean;
		f_enable_bonus: boolean;
		f_bonus_colour: tcolor;
		f_bonus_text_colour: tcolor;
		f_mark_on_click: boolean;
		f_camelot_line_thickness: byte;
		f_camelot_line_colour: tcolor;
		f_camelot_cellspacing: byte;
		f_text_enabled: boolean;
		f_locked:boolean;
		f_mark_checking_enabled:boolean;

		m_rendered_balls:trenderedballs;
		m_cell_width, m_cell_height: realinteger;
		m_n_marked, m_n_bonus_marked, m_n_guessed:byte;
		n_rows: byte;
		minimum_cell_width: byte;
		minimum_cell_height: byte;
		is_text_enabled: boolean;
		draw_one_number: boolean;
		the_one_number: byte;
	  
		guessed_visible: boolean;

		//set properties
		procedure set_display_style(value: LotteryTicketStyle);
		procedure set_max_numbers(value:word);
		procedure set_max_highlighted(value:byte);
		procedure set_columns(value:byte);
		procedure set_bonus_mark(number: LottoBall; value:boolean);
		procedure set_mark(number: LottoBall; value:boolean);
		procedure set_guessed(number: LottoBall; value:boolean);
		procedure set_hide_style(value:LotteryTicketHideStyle);
		procedure set_start_at_zero(value:boolean);

		function get_mark(index: LottoBall):boolean;
		function get_bonus_mark(index: LottoBall):boolean;
		function get_guessed(index: LottoBall):boolean;
		procedure set_in_play(index: LottoBall; value:boolean);
		function get_in_play(index: LottoBall):boolean;
		procedure recalculate_rows;
		procedure set_enable_bonus(value: boolean);
		procedure set_enable_animation(value: boolean);
		procedure set_locked(value: boolean);
		procedure set_camelot_cellspacing(value: byte);
		procedure set_camelot_line_thickness(value: byte);
		procedure set_camelot_line_colour(value: Tcolor);
		procedure set_bonus_colour(value: Tcolor);
		procedure set_bonus_text_colour(value: Tcolor);
		procedure set_mark_on_click(value: Boolean);
		procedure set_text_enabled(value: boolean);
		procedure set_max_Bonus_Highlighted(value:byte);

		//other functions
		procedure draw_LtsColouredNumbers(number:LottoBall; x1,y1,x2,y2:integer);
		procedure draw_LtsColouredBalls(number:LottoBall; x1,y1,x2,y2:integer; rendered:boolean);
		procedure draw_LtsCamelot(number:LottoBall; x1,y1,x2,y2:integer);
		procedure draw_LtsNumbers(number:LottoBall; x1,y1,x2,y2:integer);
		procedure draw_text(number:LottoBall; x1,y1,x2,y2:integer);
		procedure draw_guess_mark(number:LottoBall; x1,y1,x2,y2:integer);
		procedure draw_mark(number:LottoBall; x1,y1,x2,y2:integer);

		procedure set_number_colours(number:byte);
		procedure notify_ball_clicked(number:LottoBall; bonus:Boolean);
		procedure set_minimum_cell_metrics;
		procedure draw_a_number(number:LottoBall);
		function adjust_font_size: Boolean;
		procedure update_n_in_play;

	protected
		// Protected declarations 
		procedure OnRedraw; override;
		procedure OnFontChanged; override;
		procedure OnSetBounds; override;
		procedure OnAnimationTick; override;
		procedure OnAnimationStart; override;
		procedure OnMouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
		procedure OnCreate; override;
		procedure OnDestroy; override;

	public
		// Public declarations 
		procedure clear_marks;
		procedure reset;
		procedure set_all_in_play;
		function get_numbers_in_play: Tintlist;
		procedure set_numbers_in_play(flags:Tintlist);
		procedure init_from_prefs( prefs: TLotteryPrefs);
		function get_marked_numbers: TIntList;

		property InPlay[index: LottoBall]:boolean	read get_in_play write set_in_play;
		property Marked[index: LottoBall]:boolean	read get_mark write set_mark;
		property BonusMarked[index: LottoBall]:boolean  read get_bonus_mark write set_bonus_mark;
		property Guessed[index: LottoBall]:boolean  read get_guessed write set_guessed;
		property NInPlay: byte read F_n_in_play;
		property NMarked: byte read M_n_marked;
		property NBonusMarked: byte read M_n_bonus_marked;
		property MarkedStack: TIntStack read f_number_stack;
		property BonusStack: TIntStack read f_bonus_stack;

	published
		// Published declarations
		property ParentColor;
		property Color;
		property ParentFont;
		property Font;
		property ParentShowHint;
		property ShowHint;
		property Hint;
		property Enabled;
		property Align;
		property MaxHeight;

		property AutoResize: Boolean read F_auto_resize write F_auto_resize;
		property Locked: Boolean read F_locked write set_locked;
		property BonusColour: Tcolor read F_Bonus_colour write set_bonus_colour;
		property BonusTextColour: Tcolor read F_Bonus_text_colour write set_bonus_text_colour;
		property MaxBonusHighlighted: byte read F_Max_Bonus_Highlighted write set_max_Bonus_Highlighted;
		property CamelotCellspacing: byte read F_camelot_cellspacing write set_camelot_cellspacing;
		property CamelotLineColor: Tcolor read F_camelot_line_Colour write set_camelot_line_Colour;
		property CamelotLineThickness: byte read F_camelot_line_thickness write set_camelot_line_thickness;
		property Columns: byte read F_columns write set_columns;
		property EnableAnimation: Boolean read F_enable_animation write set_enable_animation;
		property EnableBonus: Boolean read F_enable_bonus write set_enable_bonus;
		property HideStyle: LotteryTicketHideStyle read F_Hide_Style write set_hide_style;
		property MarkOnClick: boolean read F_mark_on_click write set_mark_on_click;
		property MarkCheckingEnabled:boolean read f_mark_checking_enabled write f_mark_checking_enabled;

		property MaxHighlighted: Byte read F_max_highlighted write set_max_highlighted;
		property MaxNumbers: word read F_max_numbers write set_max_numbers;
		property StartNumber: byte read f_start_number;
		property OnClick: TClickNumberEvent read F_Click write F_Click;
		property TextEnabled: Boolean read F_text_enabled write set_text_enabled;
		property Style: LotteryTicketStyle read F_Display_style write set_display_style;
		property StartAtZero: Boolean read F_start_at_zero write set_start_at_zero;
		property Rows: byte read n_rows;
		property BonusOverlapsNumbers: Boolean read f_Bonus_Overlaps_numbers write f_Bonus_Overlaps_numbers;
	end;

procedure Register;

implementation
	uses
		lottery, misclib, math;
	const
		 DEFAULT_START_AT_ZERO = false;
		 DEFAULT_AUTO_RESIZE = false;
		 DEFAULT_MINIMUM_CELL_WIDTH = 20;
		 DEFAULT_MINIMUM_CELL_HEIGHT = 20;
		 DEFAULT_CELL_SPACING = 3;
		 MINIMUM_CELL_BORDER_HEIGHT = 2;
		 MINIMUM_CELL_BORDER_WIDTH = 2;
		 DEFAULT_MAX_HIGHLIGHTED =6;
		 DEFAULT_MAX_BONUS_HIGHLIGHTED = 1;
		 DEFAULT_LINE_THICKNESS = 2;
		 DEFAULT_LINE_COLOUR = clred;
		 DEFAULT_MAX_NUMBERS =MAX_UK_LOTTERY_NUM;
		 DEFAULT_BONUS_COLOUR = clblue;
		 DEFAULT_BONUS_TEXT_COLOUR = clwhite;
		 MIN_IN_PLAY =7;	   //one greater than the minimum number of balls

		 DEFAULT_COLUMNS=5;
		 MIN_COLUMNS = 3;
		 MAX_COLUMNS = 10;

		 TICK_TIME_INTERVAL = 500; //ms


//##############################################################
//# 		STANDARD STUFF
//##############################################################
procedure Register;
begin
  RegisterComponents('Paglis lottery', [TLotteryTicket]);
end;

//#####################################################################################
//# main
//#####################################################################################
//*******************************************************************
procedure TLotteryTicket.OnFontChanged;
begin
	  set_minimum_cell_metrics;
end;

//*******************************************************************
procedure TLotteryTicket.onSetBounds;
var
  w,h,diameter:integer;
begin
  if n_rows=0 then exit;
  if f_columns = 0 then exit;
  
  m_cell_width := to_realint(Width /F_columns);
  m_cell_height := to_realint(Height /n_rows);

  if parent <> nil then
	set_minimum_cell_metrics;

  //---------resize mask rectangles and draw masks----------------
  w := trunc_realint(m_cell_width);
  h := trunc_realint(m_cell_height);
  diameter := min(w,h);

  //--------- draw mask and balls at correct sizes ----------------
	m_rendered_balls.Diameter := diameter;

end;

//*******************************************************************
procedure TLotteryTicket.OnCreate;
begin
  m_rendered_balls := TRenderedBalls.create;
	draw_one_number := false;

	F_marked := tintlist.create;
	F_in_play := tintlist.create;
	F_drawn := tintlist.create;
	F_guessed := tintlist.create;
	f_bonus_marked := tintlist.create;

	f_bonus_marked.noExceptionOnGetError := true;
	f_marked.noExceptionOnGetError := true;
	F_in_play.noExceptionOnGetError := true;
	F_drawn.noExceptionOnGetError := true;
	F_guessed.noExceptionOnGetError := true;


	f_start_at_zero := DEFAULT_START_AT_ZERO;
	if f_start_at_zero then
		f_start_number := 0
	else
		f_start_number :=1;

	F_auto_resize := DEFAULT_AUTO_RESIZE;
	f_Mark_Checking_Enabled := true;
	F_text_enabled := true;
	is_text_enabled := true;
	F_camelot_cellspacing := DEFAULT_CELL_SPACING;
	minimum_cell_width := DEFAULT_MINIMUM_CELL_WIDTH;
	minimum_cell_height := DEFAULT_MINIMUM_CELL_HEIGHT;
	m_n_marked := 0;
	m_n_bonus_marked := 0;
	f_Bonus_Overlaps_numbers := false;
	F_max_highlighted := DEFAULT_MAX_HIGHLIGHTED;
	F_Max_Bonus_Highlighted := DEFAULT_MAX_BONUS_HIGHLIGHTED;
	F_camelot_line_thickness := DEFAULT_LINE_THICKNESS;
	F_camelot_line_colour := DEFAULT_LINE_COLOUR;
  F_max_numbers := MAX_LOTTERY_NUM;
  F_Display_style := LtsColouredBalls;
  F_Hide_Style:= LthsHide;
  F_mark_on_click := true;
  F_enable_bonus:= true;
  f_bonus_colour:= DEFAULT_BONUS_COLOUR;
  f_bonus_text_colour:= DEFAULT_BONUS_TEXT_COLOUR;
  bordervisible := false;
  set_all_in_play;
	guessed_visible := true;

  F_columns := DEFAULT_COLUMNS;
  recalculate_rows;
  setbounds(left,top, F_Columns * MINIMUM_CELL_WIDTH, n_rows * MINIMUM_CELL_HEIGHT);
  F_enable_animation := false;
  AnimationInterval := TICK_TIME_INTERVAL;
  ComponentIsAnimated := TRUE;

  f_bonus_stack := TIntStack.Create;
  f_number_stack := TIntStack.Create;
end;

//*******************************************************************
procedure TLotteryTicket.OnDestroy;
begin
	m_rendered_balls.free;

	if assigned(F_marked) then F_marked.free;
	if assigned(F_in_play) then F_in_play.free;
	if assigned(F_drawn) then F_drawn.free;
	if assigned(F_guessed) then F_guessed.free;
	if assigned(f_bonus_marked) then f_bonus_marked.free;
	f_bonus_stack.Free;
	f_number_stack.Free;
end;

//###################################################################
// # PUBLIC METHODS
// ###################################################################
function TLotteryTicket.get_numbers_in_play:tintlist;
begin
	result := F_in_play
end;

//*******************************************************************
procedure TLotteryTicket.set_numbers_in_play( flags:tintlist);
var
  number:byte;
begin
	reset;
  for number := flags.fromindex to flags.toindex do
	 Inplay[number] := flags.boolvalue[number];
  redraw;
end;

//*******************************************************************
procedure TLotteryTicket.reset;
begin
  set_all_in_play;
	clear_marks;
	redraw;
end;

//*******************************************************************
procedure TLotteryTicket.set_all_in_play;
var
	number:byte;
begin
	for number:=0 to MAX_LOTTERY_NUM do
			Inplay[number] := true;
end;

//*******************************************************************
procedure TLotteryTicket.clear_marks;
begin
	//--------------disable timer---------------------
	if not indesignmode and AnimationRunning then
		stop;

	//------------ clear all marks---------------------
	F_marked.clear;
	f_bonus_marked.clear;
	m_n_marked:=0;
	m_n_bonus_marked := 0;
	m_n_guessed := 0;
	guessed_visible := true;
	f_bonus_stack.Clear;
	f_number_stack.Clear;

   //---------------------------------------------------
	redraw;
end;

//#####################################################################################
//# props
//#####################################################################################
procedure TLotteryTicket.set_hide_style(value:LotteryTicketHideStyle);
begin
	if F_hide_style <> value then
  begin
	f_hide_style := value;
	redraw;
  end;
end;

//*******************************************************************
procedure TLotteryTicket.set_camelot_line_colour(value: Tcolor);
begin
  if value <> F_camelot_line_colour then
  begin
	F_camelot_line_colour := value;
	redraw;
  end;
end;

//*******************************************************************
procedure TLotteryTicket.set_camelot_line_thickness(value: byte);
begin
  if (value >0) and (value <> F_camelot_line_thickness) then
  begin
	F_camelot_line_thickness := value;
	  redraw;
  end;
end;

//*******************************************************************
procedure TLotteryTicket.set_text_enabled(value: boolean);
begin
	if value <> f_text_enabled then
	begin
	  f_text_enabled := value;
	  is_text_enabled := value;
	  redraw;
	end;
end;

//*******************************************************************
procedure TLotteryTicket.set_locked(value: boolean);
begin
	if value <> F_locked then
	begin
	  f_locked := value;
	  redraw;
	end;
end;


//*******************************************************************
procedure TLotteryTicket.set_camelot_cellspacing(value: byte);
begin
  if (value >0) and (value <> F_camelot_cellspacing) then
  begin
	F_camelot_cellspacing := value;
	redraw;
  end;
end;

//*******************************************************************
procedure TLotteryTicket.set_max_highlighted(value:byte);
begin
  if (value > F_n_in_play) then exit;

  if (value <> F_max_highlighted) then
  begin
	F_max_highlighted := value;
	clear_marks;
  end;
end;

//*******************************************************************
procedure TLotteryTicket.set_start_at_zero(value:boolean);
begin
  if value <> f_start_at_zero then
  begin
	//----------------- sanity check -----------------------------
	if not value and (F_n_in_play <= F_max_highlighted) then exit;

	//-----------okey dokey, continue-----------------------------
		f_start_at_zero := value;
		if f_start_at_zero then
			f_start_number := 0
		else
			f_start_number := 1;

	InPlay[0] := f_start_at_zero;
	recalculate_rows;
	redraw;
  end;
end;

//*******************************************************************
procedure TLotteryTicket.set_columns(value:byte);
begin
  if (value <> F_columns) and (value >= MIN_COLUMNS) and ( value <= MAX_COLUMNS) then
  begin
	F_columns := value;
	recalculate_rows;
  end;
end;

//*******************************************************************
procedure TLotteryTicket.set_max_numbers(value:word);
var
  check_in_play:word;
begin
  //--------proceed--------------------------------------
  if (value <> F_max_numbers) then
  begin

	//-----------sanity_check-----------------------------
	if value > MAX_LOTTERY_NUM then   value := MAX_LOTTERY_NUM;

	check_in_play := value;
	  if f_start_at_zero then inc(check_in_play);
	if check_in_play < f_max_highlighted then	exit;

	//-----------------------------------------------------
	F_max_numbers := value;
	recalculate_rows;
	clear_marks;

	//-------update how many balls are actually in play-------
	update_n_in_play;
	redraw;
  end;
end;

//-------------how shoul it be displayed?-----------------------
procedure TLotteryTicket.set_display_style(value:LotteryTicketStyle);
begin
  if value <> F_Display_style then
  begin
	F_Display_style := value;
	m_rendered_balls.Rendered := (value in [LtsRendered, LtsMarkedRendered]);
	  redraw;
  end;
end;

//*******************************************************************
procedure TLotteryTicket.set_enable_animation(value: boolean);
begin
  if value <> F_enable_animation then
  begin //.
	F_enable_animation := value;
	if not InDesignMode then
	begin //..
			if not F_enable_animation then
			 stop
			else if (m_n_guessed > 0) then
			 start;
		end; //..
	end; //.
end;

//*******************************************************************
procedure TLotteryTicket.set_enable_bonus(value: boolean);
begin
	if value <> F_enable_bonus then
	begin
		F_enable_bonus := value;
		redraw;
	end;
end;

//*******************************************************************
procedure TLotteryTicket.set_bonus_colour(value: Tcolor);
begin
  if value <> F_bonus_colour then
  begin
	F_bonus_colour := value;
	redraw;
  end;
end;

//*******************************************************************
procedure TLotteryTicket.set_bonus_text_colour(value: Tcolor);
begin
  if value <> f_bonus_text_colour then
  begin
	f_bonus_text_colour := value;
	redraw;
  end;
end;

//*******************************************************************
procedure TLotteryTicket.set_mark_on_click(value: Boolean);
begin
  if value <> F_mark_on_click then
  begin
	F_mark_on_click := value;
  end;
end;

//*******************************************************************
procedure TLotteryTicket.set_bonus_mark(number:LottoBall ; value:boolean);
begin
  //------------------------basic error checking---------------------
  if (number = INVALID_LOTTERY_NUMBER) or (number > f_max_numbers) then exit;
  if (number=0) and (not F_start_at_zero) then exit;

  //-----------only proceed if number is different ----------------
	if (value <> F_bonus_marked.boolvalue[number]) then
	begin
		//- - - - - - - - update number of marked things- - - - - - - - - - - 
		if value then
			begin
				if f_Mark_Checking_Enabled and (m_n_bonus_marked >= F_Max_Bonus_Highlighted) then
					Exit
				else
					begin //unmark number
						inc(m_n_bonus_marked);
						f_bonus_stack.AddUnique(number);
					end;
			end
		else
			begin	//mark number
				dec(m_n_bonus_marked);
				f_bonus_stack.DeleteValue(number);
			end;

		//- - - - - - - - update mark- - - - - - - - - - - 
		F_bonus_marked.boolValue[number] := value;
		draw_a_number(number);
	end;
end;

//*******************************************************************
procedure TLotteryTicket.set_mark(number:LottoBall ; value:boolean);
begin
	//------------------------basic error checking---------------------
	if (number = INVALID_LOTTERY_NUMBER) or (number > f_max_numbers) then exit;
	if (number=0) and (not F_start_at_zero) then exit;

	//-----------only proceed if number is different ----------------
	if (value = F_marked.boolvalue[number]) then exit;

	//- - - - - - - - update number of marked things- - - - - - - - - - -
	if value then
		if f_Mark_Checking_Enabled and (m_n_marked >= F_max_highlighted ) then
			Exit
		else
			begin
				inc(m_n_marked);
				f_number_stack.AddUnique(number);
			end
	else
		begin
			dec(m_n_marked);
			f_number_stack.DeleteValue(number);
		end;

		//- - - - - - - - update mark- - - - - - - - - - - 
	F_marked.boolValue[number] := value;
	draw_a_number(number);
end;

//*******************************************************************
procedure TLotteryTicket.set_guessed(number:LottoBall ; value:boolean);
begin
	if (number<=F_max_numbers) and (value <> F_guessed.boolvalue[number]) then
	begin
		F_guessed.boolvalue[number] := value;
		draw_a_number(number);

	if value then
			inc(m_n_guessed)
		else
		dec(m_n_guessed);

	//------------------ blinkety blink---------------------------
	if not InDesignMode then
	  if f_enable_animation then
		if m_n_guessed > 0 then
			 start
		else
			  stop;
  end;
end;

//----------------------get cell value-----------------------
function TLotteryTicket.get_mark(index: LottoBall):boolean;
begin
	result :=	F_marked.boolvalue[index];
end;

function TLotteryTicket.get_bonus_mark(index: LottoBall):boolean;
begin
	result :=	F_bonus_marked.boolvalue[index];
end;

//*******************************************************
function TLotteryTicket.get_guessed(index: LottoBall):boolean;
begin
	result := F_guessed.boolValue[index];
end;

//----------------------get cell value-----------------------
function TLotteryTicket.get_in_play(index: LottoBall):boolean;
begin
	result := F_in_play.boolValue[index];
end;

//*******************************************************************
procedure TLotteryTicket.set_in_play(index: LottoBall; value:Boolean);
begin
  //----------------------basic checking ---------------------------
  if (index>F_max_numbers) then exit;

  //----------------------only act is something is different--------
	if value <> F_in_play.boolValue[index] then
	begin
	  //- - - - - - - - - - - - - - - - - - - - - - - - - 
	  if value then
		Inc(F_n_in_play)
	  else
		if f_Mark_Checking_Enabled and (F_n_in_play <= (F_max_highlighted +1)) then
			exit
		else
			Dec(F_n_in_play);

	  //- - - - - - - - - - - - - - - - - - - - - - - - - 
	  F_in_play.boolValue[index] := value;
	  draw_a_number(index);
	end;
end;


//*******************************************************************
procedure TLotteryTicket.init_from_prefs( prefs: TLotteryPrefs);
begin
	drawEnabled := false;
	set_numbers_in_play(prefs.currentInPlay);
	maxHighlighted := prefs.select;
	MaxNumbers := prefs.highest_ball;
	drawEnabled := true;
	columns := prefs.columns;
	startAtZero := prefs.start_at_zero;

	if prefs.rendered then
		style := ltsrendered
	else
		style := ltsColouredBalls;

end;

//*******************************************************************
function TLotteryTicket.get_marked_numbers: Tintlist;
var
	list: TintList;
	number:byte;
begin
	list := Tintlist.create;
	for number := 0 to F_max_numbers do
		if marked[number] then
			list.bytevalue[ list.count] := number;

	result := list;
end;


//*******************************************************************
procedure TLotteryTicket.set_max_Bonus_Highlighted( value: byte);
begin
	if (F_Max_Bonus_Highlighted <> value) then
	begin
		F_Max_Bonus_Highlighted := value;
		f_bonus_marked.clear;
		redraw;
	end;
end;


//#####################################################################################
//# draw
//#####################################################################################

//*******************************************************************
procedure TLotteryTicket.OnRedraw;
var
  row,col:integer;
  x1,y1,x2,y2: realinteger;
  tmp_x, tmp_y:realinteger;
  number: byte;
begin
  //-----------------------init------------------------------------
  number := 0;
  if not F_start_at_zero then inc(number);

  //--------------- draw each cell---------------------------------
  for row:=1 to n_rows do
  begin //.
	tmp_y := m_cell_height *(row -1);
	y1:= trunc_realint(tmp_y);
	y2:= trunc_realint(tmp_y + m_cell_height);

	for col := 1 to F_columns do
	begin	//..
		 if (number >F_max_numbers) then	exit;

	  //-------------------figure out number that should be drawn -----
	  tmp_x := m_cell_width *(col -1);
	  x1:= trunc_realint(tmp_x);
	  x2:= trunc_realint(tmp_x + m_cell_width);

	  //-------------if only drawing one number do it -----------------
	  if (draw_one_number) then
		if (number <> the_one_number) then
			begin
			 inc(number);
			 continue;
			end
		else
			//-----------------------backing rectangle----------------
			with offscreenCanvas do
			begin //...
					pen.color:=color;
					brush.color:=color;
					brush.style:=bssolid;
					rectangle(x1,y1,x2,y2);

					if not enabled then
					begin
						pen.color:=clgray;
						brush.color:=clgray;
					end;
				 end; //...

	  //---------the ball ----------------------------------------
	  set_number_colours(number);

	  case F_display_style of //...
			LtsColouredNumbers: draw_LtsColouredNumbers(number, x1,y1,x2,y2);
			LtsColouredBalls:   draw_LtsColouredBalls(number, x1,y1,x2,y2,false);
			LtsCamelot:		   draw_LtsCamelot(number, x1,y1,x2,y2);
			LtsNumbers:		   draw_Ltsnumbers(number, x1,y1,x2,y2);
			LtsCircles:		   draw_LtsColouredBalls(number, x1,y1,x2,y2,false);
			LtsRendered, LtsMarkedRendered:
									draw_LtsColouredBalls(number, x1,y1,x2,y2,true)
		 end; //...
		 yield;

		 //-------------------------------------------------
		 if marked[number] then
		 begin //...
			draw_mark(number,x1,y1,x2,y2);
			yield;
		 end; //...
		 
		 //-------------------------------------------------
		 if F_guessed.boolValue[number] then
		 begin //...
			draw_guess_mark(number,x1,y1,x2,y2);
			yield;
		 end; //...

		 //-------------------------------------------------
		 if is_text_enabled then
		 begin //...
			draw_text(number,x1,y1,x2,y2);
		yield;
	  end; //...

	  //---set up for next number ------------
	  inc (number);
	end; //..

	if (number >F_max_numbers) then  exit;
  end; //.
end;

//*******************************************************************
procedure TLotteryTicket.draw_LtsColouredNumbers(number:LottoBall; x1,y1,x2,y2:integer);
begin
  offscreenCanvas.rectangle(x1, y1, x2, y2);
end;

//*******************************************************************
procedure TLotteryTicket.draw_LtsColouredBalls(number:LottoBall; x1,y1,x2,y2:integer; rendered: boolean);
var
	dx,dy, diameter: integer;
	ball_rect : Trect;
	ball_type : TLottBallType;
begin
  //--------find maximum dimeter that the cell allows------
	dy := y2-y1;
	dx := x2-x1;
  if dy < dx then
	diameter := dy
  else
	diameter := dx;

  //--------get ball information ------
  ball_type := lottery_ball(number);
  with ball_rect do
  begin
	left := (x1+x2 -diameter) div 2;
	top := (y1+y2 -diameter) div 2;
	right := left + diameter;
	bottom := top + diameter;
  end;

  //-------- draw ball into circle------
	m_rendered_balls.blit_ball(number, offscreenCanvas, ball_rect,ball_type)
end;

//*******************************************************************
procedure TLotteryTicket.draw_LtsCamelot(number:LottoBall; x1,y1,x2,y2:integer);
var
  save_colour: Tcolor;
  save_width: integer;
  box_x1, box_x2, box_y1, box_y2, dy, dthick: integer;
  points: array[1..4] of Tpoint;
begin
  //- - - - - - - - drw white backing rectangle - - - - - - 
  with offscreenCanvas do
  begin
	save_colour := pen.color;
	pen.color := brush.color;

	box_x1 := x1+F_camelot_cellspacing;
	box_y1 := y1+F_camelot_cellspacing;
	box_x2 := x2-F_camelot_cellspacing;
	  box_y2 := y2-F_camelot_cellspacing;
	rectangle(box_x1,box_y1,box_x2,box_y2);

	  pen.color := save_colour;

	//- - - - - - - - draw [] above and below- - - - - - - - -
	save_width := pen.width;
	pen.width :=F_camelot_line_thickness;
	dthick := F_camelot_line_thickness div 2;
	box_x1 := box_x1+dthick;
	box_y1 := box_y1+dthick;
	box_x2 := box_x2-dthick;
	box_y2 := box_y2-dthick;

	dy := (box_y2-box_y1) div 3;
	points[1].x := box_x1;	   points[1].y := box_y1+dy;
	points[2].x := box_x1;	   points[2].y := box_y1;
	points[3].x := box_x2;	   points[3].y := box_y1;
	points[4].x := box_x2;	   points[4].y := box_y1+dy;
	polyline(points);

	points[1].x := box_x1;	   points[1].y := box_y2 - dy;
	points[2].x := box_x1;	   points[2].y := box_y2;
	points[3].x := box_x2;	   points[3].y := box_y2;
		points[4].x := box_x2;	 points[4].y := box_y2 - dy;
		polyline(points);

		pen.width :=save_width;
	end;
end;

//*******************************************************************
procedure TLotteryTicket.draw_LtsNumbers(number:LottoBall; x1,y1,x2,y2:integer);
begin
  offscreenCanvas.rectangle(x1, y1, x2, y2);
end;

//*******************************************************************
procedure TLotteryTicket.set_number_colours(number:byte);
var
	isBonus: Boolean;
begin
	isBonus := F_enable_bonus and f_bonus_marked.boolValue[number];

	with offscreenCanvas do
	begin
		pen.width := 1;
		if F_marked.boolValue[number] and isBonus then
			begin
			 pen.color:=clblue;
			 pen.width := 4;
			 brush.color:=clblack;
			end
		else if F_marked.boolValue[number] then
			begin
			 pen.color:=clblack;
			 brush.color:=clblack;
			end
		else if isBonus then
	  begin
		pen.color := F_bonus_colour;
		brush.color := F_bonus_colour;
	  end //if
	else
	  begin
		font.color:=clblack;
		case F_display_style of
				 LtsRendered:
			begin
					pen.color:=Color;
			brush.color:=dim_lottery_ball_colour(number);
			end;

			LtsColouredNumbers,LtsColouredBalls:
			begin
			pen.color:=clblack;
			brush.color:=lottery_ball_colour(number);
			end;

			LtsCamelot:
			begin
			pen.color:=F_camelot_line_colour;
			brush.color:=clwhite;
			end;

			LtsNumbers, LtsCircles:
			begin
					pen.color:=clblack;
					brush.color:=clwhite;
				 end;
			 end; //case
			end; //else

			if not enabled then
			begin
			 pen.color:=clgray;
			 brush.color:=clgray;
			end;

		end; //with
end;

//*******************************************************************
procedure TLotteryTicket.draw_text(number:LottoBall; x1,y1,x2,y2:integer);
var
  number_in_play: boolean;
  the_text:string;
  text_width, text_height: integer;
  text_x, text_y: integer;
  save_colour, alt_font_colour, text_colour: Tcolor;
begin

  number_in_play := F_in_play.boolvalue[number];

  with offscreenCanvas do
  begin
	if	number_in_play or ( (not number_in_play) and (F_hide_style <> lthsHide)) then
	begin
	  //-------------locate the text ---------------------------------
	  the_text := inttostr(number);
	  text_width := TextWidth(the_text);
	  text_height := TextHeight(the_text);

	  text_x := (x1 + x2 - text_width) div 2;
	  text_y := (y1 + y2 - text_height) div 2;

	  //-------------figure out font colours --------
	  brush.style:=bsclear;
	  alt_font_colour := clwhite;

	  if (not enabled) and (not F_locked)then
		text_colour:=clSilver
	  else if (not number_in_play) and ((f_hide_style=LthsGrey) or (f_hide_style=LthsGreyAndCross)) then
		text_colour:=clSilver
	  else if F_marked.boolvalue[number] then
		begin
			text_colour := clwhite;
			alt_font_colour := clblack;
		end
	  else if( F_enable_bonus and f_bonus_marked.boolValue[number]) then
		text_colour := F_bonus_text_colour
	  else
			text_colour := clblack;

	  //-------------draw text	--------
		 if f_marked.boolvalue[number] then
			begin
				 font.color := text_colour;
				 textout(text_x+1, text_y+1, the_text);
				 font.color := alt_font_colour;
				 textout(text_x, text_y, the_text);
			end
		 else
			begin
				if Style = ltsrendered then
				begin
					 font.color := clsilver;
					 textout(text_x-1, text_y-1, the_text);
				end;
				font.color := text_colour;
				textout(text_x, text_y, the_text);
			end;

	  //-------------cross out numbers that are not in play--------------
	  if (not number_in_play) and ((f_hide_style=LthsCross) or (f_hide_style=LthsGreyAndCross)) then
	  begin
			save_colour := pen.color;
			pen.color:=clred;

			moveto(x1+1, y1+1);
			lineto(x2-1, y2-1);
			moveto(x1+1, y2-1);
			lineto(x2-1, y1+1);

			pen.color :=save_colour;
	  end; //if
	end; //if
  end; //width
end;

//*******************************************************************
procedure TLotteryTicket.draw_a_number(number:LottoBall);
begin

	//----------------------------------------------
	draw_one_number:= true;
	ClearOnRedraw := false;
	try

	  the_one_number:= number;
	  Redraw;
	finally
	  ClearOnRedraw := true;
	  draw_one_number:= false;
	end;
end;

//*******************************************************************
procedure TLotteryTicket.draw_mark(number:LottoBall; x1,y1,x2,y2:integer);
var
	dx,dy, diameter: integer;
	ball_rect : Trect;
begin
  //--------find maximum dimeter that the cell allows------
	dy := y2-y1;
	dx := x2-x1;
  if dy < dx then
	diameter := dy
  else
	diameter := dx;

  //--------get ball information ------
	with ball_rect do
	begin
	  left := (x1+x2 -diameter) div 2;
	  top := (y1+y2 -diameter) div 2;
	  right := left + diameter;
	  bottom := top + diameter;
	end;

	//-------- draw ball into circle------
	m_rendered_balls.blit_ball(number, offscreenCanvas, ball_rect,Ball_black)
end;

//*******************************************************************
procedure TLotteryTicket.draw_guess_mark(number:LottoBall; x1,y1,x2,y2:integer);
var
  old_pen_width: integer;
  old_colour: Tcolor;
  old_fill_style: Tbrushstyle;
begin
	with offscreenCanvas do
	begin
		//--------------------- save state --------------------------
		old_pen_width := pen.width;
		old_colour := pen.color;
		old_fill_style := brush.style;

		//--------------------- just do it. --------------------------
		brush.style := bsclear;
		pen.width := 2;

		if guessed_visible then
		begin
		 if f_marked.boolvalue[number] or f_bonus_marked.boolValue[number]then
			 begin
			 if f_bonus_marked.boolValue[number] then
				pen.color := clred
			 else
				pen.color := clgreen;

			 brush.style := bssolid;
			 brush.color := clgreen;
			 end
		 else // if f_marked
			 pen.color := clred;

		 rectangle(x1+1,y1+1,x2-1,y2-1);
		end; // if guessed_visible

		//--------------------- restore state --------------------------
		pen.width := old_pen_width;
		pen.color := old_colour;
		brush.color := old_colour;
		brush.style := old_fill_style;
	end; //with
end;

//*******************************************************************
procedure TLotteryTicket.OnAnimationTick;
var
  ball_num:byte;
begin
  guessed_visible := not guessed_visible;
  for ball_num:=0 to MAX_LOTTERY_NUM do
	if f_guessed.boolvalue[ball_num] and ( f_marked.boolvalue[ball_num] or f_bonus_marked.boolValue[ball_num])then
		draw_a_number(ball_num);
end;

//*******************************************************************
procedure TLotteryTicket.OnAnimationStart;
begin
	if m_n_guessed = 0 then stop;
end;

//#####################################################################################
//# private
//#####################################################################################

//************************************************************
//	tell the world that I've clicked a number
// ************************************************************
procedure TLotteryTicket.notify_ball_clicked(number:LottoBall; bonus:boolean);
begin
	 if assigned(F_click) then
		 F_click(number,bonus);
end;

//*******************************************************************
procedure TLotteryTicket.recalculate_rows;
var
	 how_many_numbers:byte;
begin
	//---------- figure out how many rows there should be -------
	how_many_numbers := f_max_numbers;
	if f_start_at_zero then inc(how_many_numbers);

  n_rows := how_many_numbers div F_columns;
  if (how_many_numbers mod F_columns) >0 then inc(n_rows);

	 //-----------------and update display ---------------------
	if F_auto_resize then
		setbounds(left,top, trunc_realint(F_columns * m_cell_width), trunc_realint(n_rows*m_cell_height))
	 else
		setbounds(left,top, width,height);
end;


//*******************************************************************
procedure TLotteryTicket.set_minimum_cell_metrics;
var
	 current_cell_width, current_cell_height: integer;
begin
	 if F_text_enabled then
		begin
			//-----restore font size-------------------------------------
			offscreenCanvas.font.size := canvas.font.size;

			//--------- figure out how small cell can be ----------------
			minimum_cell_height :=  offscreenCanvas.textheight('1') +(MINIMUM_CELL_BORDER_HEIGHT*2);
			minimum_cell_width := offscreenCanvas.textwidth('99')  +(MINIMUM_CELL_BORDER_width*2);

			//--------- chek that the text fits -------------------------
			current_cell_width := width div F_Columns;
			current_cell_height := height div n_rows;

			if (current_cell_width < minimum_cell_width) or (current_cell_height < minimum_cell_height)	then
			  is_text_enabled := adjust_font_size
			else
			  is_text_enabled := F_text_enabled;
		end
	 else
		begin
			minimum_cell_height :=  2;
			minimum_cell_width := 2;
		end;
end;

//*******************************************************************
//	* attempt to resize the font until the text fits -
//	* err when I get round to it
//	*******************************************************************
function TlotteryTicket.adjust_font_size: Boolean;
VAR
	font_size, m_cell_width, text_width : integer;
	resize_worked: Boolean;
begin
	 //------------be pessimistic ------------------------
	 resize_worked := false;
	 m_cell_width := width div F_Columns;

	 //------------reduce font size until it works ------------------------
	 for font_size := (canvas.font.size -1) downto 3 do
	 begin
		offscreenCanvas.font.size := font_size;
		text_width := offscreenCanvas.textwidth('99')  +(MINIMUM_CELL_BORDER_width*2);
		if  text_width <=  m_cell_width then
		begin
			resize_worked := true;
			break;
		end;
	 end;

	 //---------------retore font -----------------------
	 if not resize_worked then offscreenCanvas.font.size := canvas.font.size;

	 //---------------tell the world and rejoice ------------------
	 result := resize_worked;

end;


//*******************************************************************
procedure TlotteryTicket.update_n_in_play;
var
   start_at, num:integer;
begin
		F_n_in_play := 0;
	if F_start_at_zero then
		start_at := 0
	else
		start_at := 1;

	for num :=start_at to	F_max_numbers do
	  if F_in_play.boolvalue[num] then
		inc(F_n_in_play);
end;

//#####################################################################################
//# interact
//#####################################################################################
procedure TLotteryTicket.OnMouseclick(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
	row,col:integer;
	number:byte;

begin
	//-------------must call the superclass--------------------------
	if F_locked then exit;
	if not enabled then exit;

  //-----------------which cell -----------------------------------
  row:=  int_to_realint(y) div m_cell_height;
  col:=  int_to_realint(X) div m_cell_width;

  if (row >= n_rows) then  row:= n_rows-1;
  if (col >= F_columns) then  col:= F_columns-1;

  number := row*F_columns + col;
  if not f_start_at_zero then inc(number);

  //-----------------check if number is in range -----------------
  if (number <= F_max_numbers) then
  begin
	//- - - - - - - - if mark on click then doit - - - - - - - - 
		if f_mark_on_click and (button = mbleft) then
		begin
			if (ssShift in shift) then  //shiftclick is for bonus
				 begin
					if (not f_Bonus_Overlaps_numbers) then
						Marked[number] := false;
					BonusMarked[number] := not BonusMarked[number];
				 end
			else
				begin
					if (not f_Bonus_Overlaps_numbers) then
						BonusMarked[number] := false;
					Marked[number] := not Marked[number];
				end;
		end; //f_mark_on_click

	 //- - - - - - - - if shifted, clicked on a bonus - - - - - - -
	if (ssShift in shift) then
	  notify_ball_clicked(number,true)
	else
	  notify_ball_clicked(number,false);
  end;
end;


//
//####################################################################
(*
	$History: Ticket.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/lottery
 * 
 * *****************  Version 7  *****************
 * User: Administrator Date: 5/08/03    Time: 10:38
 * Updated in $/code/paglis/lottery
 * changed data type for lotteryballs
 * 
 * *****************  Version 6  *****************
 * User: Sunil        Date: 15-04-03   Time: 12:34a
 * Updated in $/code/paglis/lottery
 * changed the way rendered balls are drawn, still some improvements to
 * make yet.
 * 
 * *****************  Version 5  *****************
 * User: Sunil        Date: 12-04-03   Time: 11:49a
 * Updated in $/code/paglis/lottery
 * changed behaviour of rendered balls, uses propoerties instead of
 * passing stuff in.
 * 
 * *****************  Version 4  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/lottery
 * added headers and footers
*)
//####################################################################
//
end.
