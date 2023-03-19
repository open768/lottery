unit Rolonum;
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
(* $Header: /PAGLIS/controls/Rolonum.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//


interface

uses
  wintypes, Sysutils, ExtCtrls, Graphics, Controls,
  Classes, Messages,  misclib, dialogs, retained;

const
  MAX_DIGITS = 8;
type
  RollingStyle=(RollStyleInstant, RollStyleIncremental);
  RollingDirection=(RollDirectionUp, RollDirectionDown);

  DigitDetails =
	record
	  number, next_number, target_number, position:integer;
	  direction: RollingDirection;
	end;

  TRoloNumber = class(TRetainedCanvas)
  private
	{ Private declarations }
	F_NDigits: integer;
	F_value, F_target_value: LongInt;
	F_text_colour: TColor;
	F_style: RollingStyle;
	F_alarm: TNotifyEvent;
	F_3d_text: boolean;

	digits: array [ 1..MAX_DIGITS] of DigitDetails;

	rendered_numbers: Tbitmap;
	char_width, char_height: integer;
	display_increment: integer;
	number_increment: longint;
	common_direction:RollingDirection; 

	procedure set_ndigits(value:integer);
	procedure set_value(value:longint);
	procedure set_target_value(value:longint);
	procedure set_text_colour(value:Tcolor);
	procedure set_style(value:RollingStyle);
	procedure set_3d_text(value:Boolean);

	procedure update_prerendered_fonts;
	procedure draw_digits(number, next_number, position, offscreen_x: integer);
	procedure notify_alarm;
	procedure move_all_digits;
	procedure move_end_digit;
	function numbers_match: boolean;
	procedure set_direction_and_positions;
	procedure set_value_digits( value: longint);
	procedure set_target_digits( value: longint);


  protected
	{ Protected declarations }
	procedure OnCreate; override;
	procedure OnDestroy; override;
	procedure OnAnimationTick; override;
	procedure OnRedraw; override;
	procedure OnFontChanged; override;
	procedure OnColorChanged; override;
	procedure OnBorderWidthChanged; override;

  published
	{ Published declarations }
	property Color;			property ParentColor;
	property Hint;			property ShowHint;
	property Font;			property ParentFont;
	property BorderVisible; property BorderColour;
	property BorderWidth;	property AnimationInterval;

	property Text3D: Boolean read F_3D_text write set_3D_text;
	property Style: RollingStyle read F_style write set_style;
	property NDigits: integer read F_NDigits write set_ndigits;
	property TextColor: Tcolor read F_text_colour write set_text_colour;
	property Value: longint read F_value write set_value;
	property TargetValue: longint read F_target_value write set_target_value;
	property OnAlarm: TNotifyEvent read F_alarm write F_alarm;
  end;

procedure Register;

implementation
uses
	math;
const
  DEFAULT_DIGITS = 3;
  DEFAULT_BG_COLOUR = clBlack;
  DEFAULT_TEXT_COLOUR = clWhite;
  DEFAULT_STYLE = RollStyleIncremental;
  DEFAULT_3D_TEXT = true;

{############################################################
 #			STANDARD STUFF
 ############################################################}
procedure Register;
begin
  RegisterComponents('Paglis lottery', [TRoloNumber]);
end;

{############################################################
#		   PROPERTY
############################################################}
procedure TRoloNumber.set_3d_text(value:Boolean);
var
  new_width, new_height: integer;
begin
  if ( value <> F_3D_text) and (not AnimationRunning) then
  begin
	F_3D_text := value;
	update_prerendered_fonts;
	new_width := ((BorderWidth*2) + char_width) * F_NDigits;
	new_height := (BorderWidth*2) + char_height;
	Resize_Component(left,top,new_width, new_height);
  end;
end;

{*************************************************************}
procedure TRoloNumber.set_ndigits(value:integer);
var
  new_width :integer;
begin
  if (F_NDigits <> value) and (value>0) and (value <= MAX_DIGITS) and (not AnimationRunning) then
  begin
	F_NDigits := value;
	new_width := ((BorderWidth*2) + char_width) * F_NDigits;
	Resize_Component(left,top,new_width, height);
  end;
end;

{*************************************************************}
procedure TRoloNumber.set_target_value(value:longint);
begin
  if (value <> f_target_value )  then
  begin
	f_target_value := value;
	set_target_digits(F_target_value);
	set_direction_and_positions;
	redraw;
  end;
end;

{*************************************************************}
procedure TRoloNumber.set_value(value:longint);
begin
  if (f_value <> value) then
  begin
	f_value := value;
	set_value_digits(F_value);
	set_direction_and_positions;
	redraw;
  end;
end;

{*************************************************************}
procedure TRoloNumber.set_text_colour(value:Tcolor);
begin
  F_text_colour := value;
  update_prerendered_fonts;
  redraw;
end;

{*************************************************************}
procedure TRoloNumber.set_style(value:RollingStyle);
var
  num: longInt;
begin
  if (value <> F_style) and ( not AnimationRunning) then
  begin
	F_style := value;
	{-----------------------------------------------------------
	fool component into thinking that both number and next number
	style have changed
	------------------------------------------------------------}
	num := F_value;
	F_value := 0;
	set_value(num);

	num := F_target_value;
	F_target_value := 0;
	set_target_value(num);
  end;
end;

{############################################################
#		   PRIVATE COMPONENT STUFF
############################################################}
procedure TRoloNumber.set_direction_and_positions;
var
  digit: integer;
begin
  {--------precalculate the common direction------------------------}
  if (F_style = RollStyleIncremental) then
	if F_target_value > F_value then
	  begin
		common_direction := RollDirectionDown;
		number_increment := (F_target_value - F_value) div 15;
		if (number_increment = 0) then number_increment := 1;
	  end
	else
	  begin
		common_direction := RollDirectionUp;
		number_increment := (F_target_value - F_value) div 15;
		if (number_increment = 0) then number_increment := -1;
	  end;

  {---------------------set direction------------------------}
  for digit :=1 to F_NDigits do
	with digits[digit] do
		if	(target_number > number) or
			((F_style = RollStyleIncremental) and ( common_direction=RollDirectionDown)) then
			begin
			direction := RollDirectionDown;
			position := char_height;
			next_number := number +1;
			end
		else
			begin
			direction := RollDirectionUp;
			position := 0;
			next_number := number -1;
			end;
end;

{*************************************************************}
procedure TRoloNumber.update_prerendered_fonts;
var
	current_width, max_width, x, dx, digit: Integer;
	digit_widths: array[0..9] of integer;
	saved_pen_colour: Tcolor;
begin
	{--------copy font information into offscreen canvas--------}
	rendered_numbers.canvas.font.assign(Font);

	{------------figure out how big biggest character is--------}
	max_width := -1;
	for digit := 0 to 9 do
	begin
	  current_width := rendered_numbers.canvas.textWidth( IntToStr(digit));
	  digit_widths[digit] := current_width;
	  max_width := max(max_width, current_width);
	end;

	{--------------set object variables-------------------------}
	char_width := max_width;
	char_height := rendered_numbers.canvas.textHeight('0123456789');
	if (F_3D_text) then
	begin
	  char_width := char_width +2;
	  char_height := char_height +2;
	end;

	{- - - - - - - - - - - - resize font canvas - - - - - - - - - }
	rendered_numbers.width := 10 * char_width;
	rendered_numbers.height := char_height;

	{- - - - - - - - - - -clear canvas- - - - - - - - - - - - - }
	with rendered_numbers.canvas do
	begin
	  brush.color := Color;
	  brush.style := bsSolid;
	  saved_pen_colour:= pen.color;
	  pen.color := Color;
	  rectangle(0,0, rendered_numbers.width, rendered_numbers.height);
	  pen.color := saved_pen_colour;
	  brush.style := bsClear;
	end;

	{- - - - - - - - - - -draw digits- - - - - - - - - - - - - }
	x := 0;
	for digit := 0 to 9 do
	begin
	  dx := (char_width - digit_widths[digit]) div 2;

	  with rendered_numbers.canvas do
		if (F_3D_text) then
			begin
			font.color := clwhite;
			textOut(x +dx, 0, intToStr(digit));

			font.color := clblack;
			textOut(x +dx+2, 2, intToStr(digit));

			font.color := F_text_colour;
			textOut(x +dx+1, 1, intToStr(digit));
			end
		else
			begin
			font.color := F_text_colour;
			textOut(x +dx, 0, intToStr(digit));
			end;

	  x := x + char_width;
	end;

	display_increment := char_height div 5;
end;

{*************************************************************}
procedure TRoloNumber.OnFontChanged;
var
  new_width, new_height: integer;
begin
  update_prerendered_fonts;
  new_width := ((BorderWidth*2) + char_width) * F_NDigits;
  new_height := (BorderWidth*2) + char_height;
  Resize_Component(left,top,new_width, new_height);
end;

{*************************************************************}
procedure TRoloNumber.OnColorChanged;
begin
  update_prerendered_fonts;
end;

{*************************************************************}
procedure TRoloNumber.OnBorderWidthChanged;
var
  new_width, new_height: integer;
begin
  new_width := ((BorderWidth*2) + char_width) * F_NDigits;
  new_height := (BorderWidth*2) + char_height;
  Resize_Component(left,top,new_width, new_height);
end;


{############################################################
 #		 what it looks like
 ############################################################}
{*************************************************************}
procedure TRoloNumber.OnAnimationTick;
begin
	{------------------move digits along-----------------------}
	if F_style = RollStyleInstant then
	  move_all_digits
	else
	  move_end_digit;

	{------------------draw the numbers------------------------}
	redraw;

	{------------------all done?------------------------}
	if numbers_match then
	begin
		 stop;
		 notify_alarm;
	end;
end;

{*************************************************************}
procedure TRoloNumber.OnRedraw;
var
  offscreen_x, digit, digit_width, digit_height:integer;
begin
  digit_width := char_width + 2*BorderWidth;
  digit_height := char_height + 2*BorderWidth;
  offscreen_x := width - digit_width;

  {----------------------------------------------------------------}
  for digit:=1 to F_NDigits do
  begin
	{--------------and the rectangle to fit behind text------}
	if borderVisible then
	  with offscreenCanvas do
	  begin
		 brush.style := bsclear;
		pen.color := bordercolour;
		rectangle( offscreen_x, 0, offscreen_x+digit_width, digit_height);
	  end;

	{--------------draw digits------}
	with digits[digit] do
	  if direction = RollDirectionUp then
		draw_digits( next_number,number, position, offscreen_x)
	  else
		draw_digits(number, next_number, position, offscreen_x);

	{-------now then move along, or you'll be arrested---------}
	offscreen_x  := offscreen_x - digit_width;
  end;
end;

{*************************************************************}
procedure TRoloNumber.draw_digits(number, next_number, position, offscreen_x: integer);
var
  font_rect, out_rect: Trect;
begin
  {--------------draw bottom bit of next number digit----------}
  with font_rect do
  begin
	left := next_number * char_width;
	right := left + char_width;
	top := position;
	bottom := char_height;
  end;

  with out_rect do
  begin
	left := offscreen_x + BorderWidth;
	right := left + char_width;
	top := BorderWidth;
	bottom := top + char_height - position;
  end;
  offscreenCanvas.Copyrect( out_rect, rendered_numbers.canvas, font_rect);

  {--------------draw top bit of number digit----------------}
  with font_rect do
  begin
	left := number * char_width;
	right := left + char_width;
	top := 0;
	bottom := position;
  end;

  with out_rect do
  begin
	left := offscreen_x + BorderWidth;
	right := left + char_width;
	top := BorderWidth + char_height - position;
	bottom := BorderWidth + char_height;
  end;
  offscreenCanvas.Copyrect( out_rect, rendered_numbers.canvas, font_rect);
end;

{############################################################
 #			PUBLIC COMPONENT STUFF
 ############################################################}
procedure TRoloNumber.OnCreate;
var
  digit: integer;
  new_width, new_height: integer;
begin
  ComponentIsAnimated:=true;
  ComponentCanBeResized := false;

  {----------------------default things---------------------}
  F_NDigits :=	DEFAULT_DIGITS;
  F_text_colour := DEFAULT_BG_COLOUR;
  F_style := RollStyleInstant;
  F_3D_text := DEFAULT_3D_TEXT;

  {----------------------allocate memory---------------------}
  rendered_numbers := TBitmap.create;

  {-----------------set initial size-------------------------}
  update_prerendered_fonts;
  new_width := ((BorderWidth*2) + char_width) * F_NDigits;
  new_height := char_height + (BorderWidth*2);
  Resize_Component(left,top,new_width, new_height);

  {--------------initialise digit details-------------------}
  Randomize;
  F_value  := 0;
  F_target_value  := 0;
  for digit := 1 to MAX_DIGITS do
	with digits[digit] do
	begin
	  number := 0;
	  next_number := 0;
	  position:= random(char_height);
	end;
  redraw;
end;

{*************************************************************}
procedure TRoloNumber.OnDestroy;
begin
  if assigned(rendered_numbers) then rendered_numbers.free;
end;


{****** when the target number has been reached there is an event **********}
procedure TRoloNumber.notify_alarm;
begin
   if assigned(F_alarm) then
	  F_alarm(self);
end;

{*************************************************************}
procedure TRoloNumber.move_all_digits;
var
  digit: integer;
begin
  for digit :=1 to F_NDigits do
	with digits[digit] do
	  if (number <> target_number) then
		if direction = RollDirectionUp then
			begin
			position := position + display_increment;
			if position >= char_height then
			begin
			  position := 0;
			  number := next_number;
			  next_number := next_number -1;
			end;
			end
		else
			begin
			position := position - display_increment;
			if position <= 0 then
			begin
			  position := char_height;
			  number := next_number;
			  next_number := next_number +1;
			end;
			end;	{if direction}
end;

{*************************************************************}
procedure TRoloNumber.move_end_digit;
begin
  F_value := F_value + number_increment;
  if (common_direction = RollDirectionUp) and (F_value < F_target_value) then
	F_value := F_target_value;

  if (common_direction = RollDirectionDown) and (F_value > F_target_value) then
	F_value := F_target_value;

  set_value_digits(F_value);
end;

{*************************************************************}
function TRoloNumber.numbers_match: boolean;
var
  digit, count: integer;
begin
  count := 0;

  {--------------------count which digits are the same------}
  for digit := 1 to F_Ndigits do
	with digits[digit] do
	  if (number = target_number) then
		inc(count);

  numbers_match :=	( count = F_Ndigits);
end;

{*************************************************************}
procedure TRoloNumber.set_value_digits( value: longint);
var
  remainder, remaining: longint;
  digit: integer;
begin
  remaining := value;
  for digit := 1 to F_NDigits do
  begin
	remainder := remaining mod 10;
	digits[digit].number := remainder;
	remaining := remaining div 10;
  end;
end;

{*************************************************************}
procedure TRoloNumber.set_target_digits( value: longint);
var
  remainder, remaining: longint;
  digit: integer;
begin
  remaining := value;
  for digit := 1 to F_NDigits do
  begin
	remainder := remaining mod 10;
	digits[digit].target_number := remainder;
	remaining := remaining div 10;
  end;
end;

//
//####################################################################
(*
	$History: Rolonum.pas $
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
