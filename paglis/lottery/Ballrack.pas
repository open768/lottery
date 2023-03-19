unit Ballrack;

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
(* $Header: /PAGLIS/lottery/Ballrack.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************

//
// TODO simplify - remove stupid notion of slots and replace with sparselist
//

interface
{$X+}
uses
	controls, types, Classes, Graphics,
	lottery,lottrender,lottype,misclib,sine,retained, lottpref, ballrack_spinner,
	sparselist;

type
  //###########  data holder#############################################}
	BallRackStyle = (brPlain,brRendered);
	RackMode = ( rmSelecting, rmAdding, rmSorting, rmNone);

	RBallRack_Slot = record
		slot, value: byte;
		location: Tpoint;
	end;

	RBallRack_MarkerInfo = record
	 Colour_Off: Tcolor;
	 Colour_Lit: Tcolor;
	 height:integer;
	 width:integer;
	end;

	TBallInfoList = class(tsparselist)
	end;

  //##########################################################################
  //Animated component showing a rack of balls. Balls roll in right to left.
  //The right most position spins when blls are being selected. When balls
  //have rolled into place, a placemarker lights up. when all balls have
  //been selected, they are sorted into ascending order
  //##########################################################################}
  TBallRack = class(TRetainedCanvas)
  private
	 { Private declarations }
		F_NSlots:integer;
		F_rack_mode, previous_rack_mode: RackMode;
		F_Sorting_finished: TNotifyEvent;
		F_Adding_finished:TNotifyEvent;
		F_style: BallRackStyle;
		c_markerInfo: RballRack_Markerinfo;

		c_rendered_balls:TRenderedBalls;
		c_rolling_ball: TBallRackSpinner;

		slot_details: array [1..MAX_LOTTERY_NUM] of RBallRack_Slot;
		ball_diameter: integer;
		anim_time_step: integer;
		slot_to_add_to: byte;
		ball_being_added: RBallRack_Slot;
		cell_width :real;
		top_of_balls:integer;
		slot_being_sorted: byte;
		c_current_sort: array[1..2] of RBallRack_Slot;

		procedure pr_update_ball_things;
		procedure pr_on_tick_Selecting;
		procedure pr_on_tick_Adding;
		procedure pr_on_tick_Sorting;

		procedure draw_rack;
		procedure set_slots( value : integer);
		procedure set_marker_colour_off( value : Tcolor);
		procedure set_marker_colour_lit( value : Tcolor);
		procedure set_marker_height( value : integer);
		procedure set_marker_width( value : integer);
		procedure set_rack_mode(value: RackMode);
		procedure set_style(value: BallRackStyle);

		function get_ball( slot:byte): byte;
		procedure set_ball( slot:byte; value:byte);
		procedure pr_draw_rolling_ball;
		procedure move_added_ball;
		procedure draw_a_ball(the_canvas:Tcanvas; ball_num:byte; x,y:integer);

		procedure init_slots_to_swap;
		function  finished_current_sorting: boolean;
		procedure move_sorted_balls;
		procedure draw_sorted_balls;
		procedure sort_quickly;
		procedure notify_sorting_finished;
		procedure notify_adding_finished;
		procedure update_swapped_balls;
		function get_min_slot(start_slot:byte): byte;

  protected
	{ Protected declarations }
	procedure OnRedraw; override;
	procedure OnSetbounds; override;
	procedure OnAnimationTick; override;
	procedure OnAnimationEnd; override;
	procedure OnColorChanged; override;

  public
	{ Public declarations }
	constructor Create (AOwner: TComponent); override;
	destructor Destroy;  override;
	procedure add_ball(value:byte);
	procedure reset;
	property BallAt[index: byte]:byte read get_ball write set_ball;
	procedure init_from_prefs(prefs: TLotteryPrefs);
	procedure sort;

  published
	 property Font;
	 property ParentFont;
	 property ParentShowHint;
	 property Hint;
	 property ShowHint;
	 property BorderColour;
	 property BorderVisible;
	 property ParentColor;
	 property Color;

	 { Published declarations }
	 property NSlots: integer read F_NSlots write set_slots;
	 property MarkerColourOff: Tcolor read c_markerInfo.colour_off write set_marker_colour_off;
	 property MarkerColourLit: Tcolor read c_markerInfo.colour_lit write set_marker_colour_lit;
	 property MarkerHeight: integer read c_markerInfo.height write set_marker_height;
	 property MarkerWidth: integer read c_markerInfo.width write set_marker_width;
	 property Mode: RackMode read F_rack_mode write set_rack_mode;
	 property Style: BallRackStyle read F_style write set_style;
	 property OnClick;
	 property OnSortingFinished: TNotifyEvent
		 read F_Sorting_finished write F_Sorting_finished;
	 property OnAddingFinished: TNotifyEvent
		 read F_Adding_finished write F_Adding_finished;
  end;

procedure Register;

implementation
uses
	sysutils, forms, math;
const
	TICK_INTERVAL = 11; {milliseconds}
	SORTING_TICK_INTERVAL = 25;
	DEFAULT_ARROW_HEIGHT = 7; {milliseconds}
	DEFAULT_SLOTS = UK_NSELECT;
	DEFAULT_MARKER_COLOUR_OFF = clGray;
	DEFAULT_MARKER_COLOUR_LIT = $0080FFFF;
	DEFAULT_MARKER_HEIGHT = 5;
	DEFAULT_MARKER_WIDTH = 9;
	MINIMUM_WIDTH =200;
	MINIMUM_HEIGHT=50;
	ANGLE_INCREMENT =15;
	Y_MOVE_INCREMENT=2;
	X_MOVE_INCREMENT=5;
	DEFAULT_STYLE = brPLain;
    INVALID_LOTTERY_NUMBER=201;

//############################################################
//          STANDARD STUFF
//############################################################
procedure Register;
begin
	RegisterComponents('Paglis lottery', [TBallRack]);
end;

//############################################################
//# main
//############################################################
constructor TBallRack.Create (AOwner: TComponent);
begin
	inherited Create (AOwner);
	c_rolling_ball := TBallRackSpinner.create(inDesignMode);

	//--------------no drawing yet------------------------------
	c_rendered_balls := TRenderedBalls.create;
	ComponentIsAnimated := true;

	//--------------initialise----------------------------------
	clear_sine_cache;
	anim_time_step := 0;    {increments mod 360}
	F_NSlots := 0;
	c_markerInfo.width :=   DEFAULT_MARKER_WIDTH;
	c_markerInfo.colour_off := DEFAULT_MARKER_COLOUR_OFF;
	c_markerInfo.colour_lit := DEFAULT_MARKER_COLOUR_LIT;
	F_rack_mode := rmNone;
	F_style := DEFAULT_STYLE;

	setBounds(left,top,MINIMUM_WIDTH, MINIMUM_HEIGHT);

	set_marker_height(DEFAULT_MARKER_HEIGHT);
	set_slots(DEFAULT_SLOTS);



  //--------------Ok everything is set up------------------------------
end;

//****************************************************************
//ensure that everything is shut down properly
//****************************************************************
destructor TBallRack.Destroy;
begin
	stop;
	application.ProcessMessages;

	c_rolling_ball.free;

	c_rendered_balls.free;
	inherited destroy;
end;

//############################################################
//# execute
//############################################################
procedure TBallRack.OnAnimationTick;
begin
  //-------do whatever -----------------------------------
  case F_rack_mode of
	rmSelecting: pr_on_tick_Selecting;
	  rmAdding: pr_on_tick_Adding;
    rmSorting:  pr_on_tick_Sorting;
  end;
end;

//***************************************************************
procedure TBallRack.OnAnimationEnd;
begin
  case previous_rack_mode of
	 rmAdding:
      slot_details[slot_to_add_to].value := ball_being_added.value;
    rmSorting:
       begin
          sort_quickly;
          notify_sorting_finished;
       end;
  end;

  previous_rack_mode := rmnone;
end;

//***************************************************************
procedure TBallRack.pr_on_tick_Selecting;
begin
  pr_draw_rolling_ball;
end;

//***************************************************************
procedure TBallRack.pr_on_tick_Adding;
begin
  move_added_ball;

  //-------------if still adding, draw--------------
  if (f_rack_mode <> rmadding) then
	notify_adding_finished
  else
	with ball_being_added do
	  draw_a_ball( transientcanvas, value, location.x, location.y);

end;

//***************************************************************
procedure TBallRack.pr_on_tick_Sorting;
begin
  //-------------------------------------------
  draw_rack;

  //-------------------------------------------
  if slot_being_sorted = INVALID_LOTTERY_NUMBER then
    init_slots_to_swap
  else if finished_current_sorting then
    begin
      update_swapped_balls;
      init_slots_to_swap;
    end
  else
    begin
      move_sorted_balls;
      draw_sorted_balls;
    end;

  //-------------------------------------------
  if slot_being_sorted = INVALID_LOTTERY_NUMBER then
    set_rack_mode(rmNone);

end;

//############################################################
//# props
//############################################################
procedure TBallRack.set_rack_mode(value: RackMode);
begin
	if indesignmode then exit;

  //-----------------------------------------------------
  if (value <> F_rack_mode) then
  begin {.}
    previous_rack_mode := F_rack_mode;
    F_rack_mode := value;

    //-----------------------------------------------------
    if f_rack_mode = rmNone then
       stop
    else
       begin {..}
         case F_rack_mode of  {...}
			rmSelecting:
				animationinterval := TICK_INTERVAL;
			rmAdding:
				animationinterval := TICK_INTERVAL;
			rmSorting:
				begin
					animationinterval := SORTING_TICK_INTERVAL;
					slot_being_sorted := INVALID_LOTTERY_NUMBER;
				end;
			end;{...}
		 start;
       end;{..}
  end;{.}
end;

//***************************************************************
procedure TBallRack.set_style( value:BallRackStyle);
begin
  if value <> F_style then
  begin
	 F_style := value;
	 c_rendered_balls.Rendered := (value =brRendered);
    redraw;
  end;
end;

//***************************************************************
procedure TBallRack.set_ball( slot:byte; value:byte);
begin
  if slot > F_NSlots then
    set_slots(slot);
  slot_details[slot].value := value;
  redraw;
end;

//***************************************************************
procedure TBallRack.set_marker_width( value : integer);
begin
  if value <> c_markerInfo.width then
  begin
    c_markerInfo.width := value;
    redraw;
  end;
end;

//***************************************************************
procedure TBallRack.set_marker_height( value : integer);
begin
  if value <> c_markerInfo.height then
  begin
    c_markerInfo.height := value;
    pr_update_ball_things;
    redraw;
  end;
end;

//***************************************************************
procedure TBallRack.set_marker_colour_off( value : Tcolor);
begin
  if value <> c_markerInfo.colour_off then
  begin
    c_markerInfo.colour_off := value;
	redraw;
  end;
end;

//***************************************************************
procedure TBallRack.set_marker_colour_lit( value : Tcolor);
begin
  if value <> c_markerInfo.colour_lit then
  begin
    c_markerInfo.colour_lit := value;
    redraw;
  end;
end;

//***************************************************************
procedure TBallRack.set_slots( value : integer);
var
  i : integer;
begin
  if (not animationrunning) and (value <> F_NSlots) and (value>0) and (value < MAX_LOTTERY_NUM)then
  begin
    F_NSlots := value;

    for i:=1 to (F_NSlots) do
      slot_details[i].value := INVALID_LOTTERY_NUMBER;

    pr_update_ball_things;
    redraw;
  end;

end;

//############################################################
//# override virtual methods
//############################################################}
//***************************************************************
procedure TBallRack.OnColorChanged;
begin
	c_rolling_ball.colour := color;
end;

//***************************************************************
procedure TBallRack.OnRedraw;
begin
  draw_rack;
end;

//***************************************************************
procedure TBallRack.OnSetBounds;
begin
  if (width < minimum_width) or (height < minimum_height) then
  begin
	SetBounds( Left, Top, minimum_width, minimum_height);
	exit;
  end;

  pr_update_ball_things;
end;

//############################################################
//# events
//############################################################
procedure TBallRack.notify_adding_finished;
begin
	 if assigned(F_adding_finished) then
		  F_adding_finished(self);
end;

//***************************************************************
procedure TBallRack.notify_sorting_finished;
begin
	 if assigned(F_Sorting_finished) then
		  F_Sorting_finished(self);
end;


//############################################################
//# load properties in one big go
//############################################################
procedure TBallRack.init_from_prefs(prefs: TLotteryPrefs);
begin
	Nslots := prefs.select;

	if prefs.rendered then
		style := brRendered
	else
		style := brPlain;
end;

//############################################################
//# paint
//############################################################
procedure TBallRack.pr_draw_rolling_ball;
var
	cell_x, cell_y: integer;
begin
  cell_x := (width - round(cell_width) -2)  + (round(cell_width) - ball_diameter) div 2;
  cell_y := c_markerInfo.height + (height - c_markerInfo.height - ball_diameter) div 2;

  c_rolling_ball.draw_onto(OffscreenCanvas,cell_x,cell_y);

end;

//***************************************************************
procedure TBallRack.draw_rack;
var
  i,dx ,cell_x, half_cell_width:integer;
  x1,x2,x3, xe,ye: integer;
  real_x: real;
  state: boolean;
  ball_num: integer;
begin
  with offscreenCanvas do
  begin
	 //---------------draw state-----------------------
	 half_cell_width := round(cell_width) div 2;
	 dx := ( round(cell_width) - c_markerInfo.width) div 2;
	  real_x := 0.0;
	 state := false;

		if indesignmode then  state := false;

	 for i:=1 to (F_NSlots ) do
	 begin

		// - - - - - - -figure out where marker goes - - - - - - - 
		cell_x := round(real_x);
		x1 := cell_x +dx;
		x2 := x1 + c_markerInfo.width;
		x3 := cell_x + half_cell_width;

		// - - - - - - -set marker colour - - - - - - - - - - - - - 
		  if indesignmode then
		  state := not state
		else
		  state := slot_details[i].value <> INVALID_LOTTERY_NUMBER;

		if (state) then
		  brush.color := c_markerInfo.colour_lit
		else
		  brush.color := c_markerInfo.colour_off;

		// - - - - - - - - - - - draw marker - - - - - - - - - - - - - 
		pen.color := clblack;
		brush.style := bsSolid;
		PolyGon( [Point(x1,0), Point(x2,0), Point(x3,c_markerInfo.height), Point(x1,0)]);

		// - - - - - - -draw the ball (if any)- - - - - }
		if indesignmode then
			ball_num := random(MAX_UK_LOTTERY_NUM)
      else
        ball_num := slot_details[i].value;

      with slot_details[i].location do
      begin
        xe := x;
        ye := y;
      end;

      if (ball_num <> INVALID_LOTTERY_NUMBER) then
        draw_a_ball(OffscreenCanvas,ball_num,xe,ye);

      // - - - - - - - - - - next - - - - - - - - - - }
      real_x := real_x + cell_width;
    end;

  end;
end;

//***************************************************************
procedure TBallRack.draw_a_ball(the_canvas:Tcanvas; ball_num:byte; x,y:integer);
var
  xt,yt, text_width, text_height:integer;
  text:string;
  ball_type: TLottBallType;
  ball_rect:trect;
begin

  //------------figure out information about ball-----------
  ball_type:=lottery_ball(ball_num);
  with ball_rect do
  begin
    left := x;
    top:= y;
    right := left + ball_diameter;
    bottom := top + ball_diameter;
  end;

  //------------draw it-----------
  case F_style of
    brRendered:
		 c_rendered_balls.blit_ball(ball_num, the_canvas,ball_rect,ball_type);

	  else
		 c_rendered_balls.blit_ball(ball_num, the_canvas,ball_rect,ball_type);

	end;

  //------------------draw the text-----------
  text:= inttostr(ball_num);
  with the_canvas do
  begin
    text_width:= TextWidth(text);
    text_height:= TextHeight(text);

	 yt := y + (ball_diameter - text_height) div 2;
    xt := x + (ball_diameter - text_width) div 2;

    brush.style := bsClear;
    if F_style = brRendered then
    begin
      font.color := clwhite;
      textout(xt-1,yt-1,text);
      font.color := clgray;
      textout(xt+1,yt+1,text);
    end;

    font.color := clblack;
    textout(xt,yt,text);

  end;
end;

//*********************************************************
procedure TBallRack.draw_sorted_balls;
begin
  with c_current_sort[1] do 
    draw_a_ball(transientCanvas,value, location.x, location.y);
  with c_current_sort[2] do
	draw_a_ball(transientCanvas,value, location.x, location.y);
end;


//############################################################
//# misc
//############################################################
procedure TBallRack.sort;
begin
	set_rack_mode(rmSorting);
end;

function TBallRack.get_ball( slot:byte): byte;
begin
	if (slot > F_NSlots) then
	  result := INVALID_LOTTERY_NUMBER
	else
	  result := slot_details[slot].value;
end;

//***************************************************************
procedure TBallRack.add_ball( value:byte);
var
	slot :byte;
begin
	//-------if allready adding  ball, speed thatone up--------
	if (F_rack_mode=rmAdding) then
	  begin
		 slot_details[slot_to_add_to].value := ball_being_added.value;
      redraw;
    end;

  //-------- which slot is being added to-------------------
  ball_being_added.value := value;
  for slot:=1 to f_Nslots do
    if slot_details[slot].value = INVALID_LOTTERY_NUMBER then
    begin
		slot_to_add_to := slot;
      break;
    end;

  //--------------togggle the flag to add a ball----------
  set_rack_mode(rmAdding);
  ball_being_added.location.x := width-ball_diameter;
  ball_being_added.location.y := 0;
end;

//***************************************************************
procedure TBallRack.reset;
var
  i:integer;
begin
  for i:=1 to F_NSlots do
    slot_details[i].value := INVALID_LOTTERY_NUMBER;

  redraw;
end;


//***************************************************************
procedure TBallRack.move_added_ball;
begin
  with ball_being_added.location do
    if y < top_of_balls then
      y := y + Y_MOVE_INCREMENT
    else if x > slot_details[slot_to_add_to].location.x then
      x := x - X_MOVE_INCREMENT
    else
      begin
        slot_details[slot_to_add_to].value := ball_being_added.value;
        redraw;

        if (slot_to_add_to = F_nslots) then {last slot}
		  	 set_rack_mode(rmnone)
		  else
			 set_rack_mode(rmSelecting);
      end;
end;

//############################################################
//		  MISC PRIVATE STUFF
//############################################################
procedure TBallRack.pr_update_ball_things;
var
  height_remaining: integer;
  slot:byte;
  real_x :real;
  dx,dy:integer;
begin

  cell_width := width / (F_NSlots +1);

	//------------ recalculate the ball size -------------------
  height_remaining := height - c_markerInfo.height;
  ball_diameter := min(round(cell_width),height_remaining-2);
  c_rolling_ball.Diameter := ball_diameter;

  //----------------- pre render balls --------------
  c_rendered_balls.Diameter := ball_diameter;

  //----------------- update positions of balls --------------
  dx := (round(cell_width) - ball_diameter) div 2;
  dy := ( height + c_markerInfo.height - ball_diameter ) div 2;
  top_of_balls := dy;
  real_x :=0.0;

  for slot:=1 to f_Nslots do
  begin
    with slot_details[slot].location do
	begin
	  x := round(real_x) + dx;
	  y := dy;
	end;
	real_x := real_x + cell_width;
  end;
end;

//############################################################
//  SORTING
//############################################################}
procedure TBallRack.sort_quickly;
var
  slot, min_slot, tmp_value :byte;
begin
  for slot := 1 to f_Nslots do
  begin
    //--------------------------------------
    min_slot := get_min_slot(slot);

    //--------------------------------------
	  if slot <> min_slot then
    begin
      tmp_value := slot_details[slot].value;
      slot_details[slot].value := slot_details[min_slot].value;
      slot_details[min_slot].value := tmp_value;
    end;
  end;
end;

//*********************************************************
procedure TBallRack.init_slots_to_swap;
var
  the_slot, min_slot:byte;
begin
  slot_being_sorted := INVALID_LOTTERY_NUMBER;

  //-----------------------------------------------------------
  for the_slot := 1 to f_nslots do
  begin
    min_slot := get_min_slot(the_slot);
    if min_slot <> the_slot then
    begin
      with slot_details[the_slot] do
		 begin
        c_current_sort[1].slot:= min_slot;
        c_current_sort[1].value:= value;
        c_current_sort[1].location.x := location.x;
        c_current_sort[1].location.y := location.y;
      end;

      with slot_details[min_slot] do
      begin
        c_current_sort[2].slot:= the_slot;
        c_current_sort[2].value:= value;
        c_current_sort[2].location.x := location.x;
        c_current_sort[2].location.y := location.y;
      end;

      slot_being_sorted:= the_slot;
      exit
    end;
  end;
end;

//*********************************************************
function  TBallRack.finished_current_sorting: boolean;
var
  slot:byte;
  x1_now, x1_wanted, x2_now, x2_wanted: integer;
begin
  x1_now := c_current_sort[1].location.x;
  slot := c_current_sort[1].slot;
  x1_wanted := slot_details[slot].location.x;

  x2_now := c_current_sort[2].location.x;
  slot := c_current_sort[2].slot;
  x2_wanted := slot_details[slot].location.x;

  finished_current_sorting := (x1_now >= x1_wanted) and (x2_now <= x2_wanted);

end;

//*********************************************************
procedure TBallRack.move_sorted_balls;
begin
  with c_current_sort[1] do
    if location.x < slot_details[slot].location.x then
      location.x := location.x  + X_MOVE_INCREMENT;

	with c_current_sort[2] do
    if location.x > slot_details[slot].location.x then
      location.x := location.x  -X_MOVE_INCREMENT;
end;

//*********************************************************
function TBallRack.get_min_slot(start_slot:byte): byte;
var
  min_value, min_slot, check_slot, check_value:byte;
begin
  //--------------------------------------
  min_value := slot_details[start_slot].value;
  min_slot := start_slot;

  //--------------------------------------
  for check_slot := start_slot+1 to f_Nslots do
  begin
      check_value := slot_details[check_slot].value;
      if check_value < min_value then
      begin
        min_slot := check_slot;
        min_value := check_value;
      end;
	end;

  //--------------------------------------
  get_min_slot := min_slot;
end;

//*********************************************************
procedure TBallRack.update_swapped_balls;
var
  slot_from, slot_to, tmp_value:byte;
begin
  slot_from := c_current_sort[1].slot;
  slot_to := c_current_sort[2].slot;

  tmp_value := slot_details[slot_from].value;
  slot_details[slot_from].value := slot_details[slot_to].value;
  slot_details[slot_to].value := tmp_value;

  redraw;
end;

//
//####################################################################
(*
	$History: Ballrack.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/lottery
 * 
 * *****************  Version 15  *****************
 * User: Administrator Date: 7/06/04    Time: 10:43
 * Updated in $/code/paglis/lottery
 * reformatted
 * 
 * *****************  Version 14  *****************
 * User: Administrator Date: 8/05/04    Time: 22:57
 * Updated in $/code/paglis/lottery
 * debugged
 * 
 * *****************  Version 13  *****************
 * User: Administrator Date: 4/05/04    Time: 23:11
 * Updated in $/code/paglis/lottery
 * ballrack notifies when animation is complete. fixes timing problem
 * where ballrack hadnt finished adding the ball.
 * 
 * *****************  Version 12  *****************
 * User: Administrator Date: 28/04/04   Time: 23:11
 * Updated in $/code/paglis/lottery
 * completed move of rollingball.
 *
 * *****************  Version 10  *****************
 * User: Administrator Date: 26/04/04   Time: 17:14
 * Updated in $/code/paglis/lottery
 * 
 * *****************  Version 9  *****************
 * User: Sunil        Date: 6/05/03    Time: 23:56
 * Updated in $/code/paglis/lottery
 * still some way to go.
 * 
 * *****************  Version 8  *****************
 * User: Sunil        Date: 6/05/03    Time: 23:39
 * Updated in $/code/paglis/lottery
 * gradual refinement process
 * 
 * *****************  Version 7  *****************
 * User: Sunil        Date: 6/05/03    Time: 23:14
 * Updated in $/code/paglis/lottery
 * reduced number of things in uses clause
 * 
 * *****************  Version 6  *****************
 * User: Sunil        Date: 6/05/03    Time: 0:25
 * Updated in $/code/paglis/lottery
 * removed automatic sorting 
 *
 * *****************  Version 5  *****************
 * User: Sunil        Date: 4/05/03    Time: 23:45
 * Updated in $/code/paglis/lottery
 * 
 * *****************  Version 4  *****************
 * User: Sunil        Date: 3/05/03    Time: 23:00
 * Updated in $/code/paglis/lottery
*)
//####################################################################
//
end.

