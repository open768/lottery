unit Bubble;
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
(* $Header: /PAGLIS/classes/bubble.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//


interface
uses
	 SysUtils, wintypes, WinProcs, Messages, Classes,
	 Graphics, Controls,extctrls,dialogs,forms;
type
  TBubbleHintWindow = class(THintWindow)
  private
	offscreen_bitmap: TBitmap;
	bubble_timer: TTimer;
	can_display_hint: boolean;
	last_mouse_pos: Tpoint;
	tick_counter:integer;
	procedure Ontick(Sender:Tobject);
  protected
	procedure Paint;override;
	procedure CreateParams(var Params: TCreateParams);override;
  public
	constructor Create(AOwner:TComponent);override;
	destructor Destroy;override;
	procedure ActivateHint(Rect: TRect; const AHint: string);override;
	function IsHintMsg(var Msg: TMsg): Boolean; override;
  published
end;


implementation
const
	HINT_PADDING = 3;
	SHADOW_DEPTH =5;
	SHADOW_COLOUR = clgray;
	DISPLAY_TICK_COUNT = 3;
	HINT_HEIGHT_FUDGE = 4;
{################################################################}
constructor TBubbleHintWindow.Create(AOwner:TComponent);
begin
	inherited Create(AOwner);

	RegisterClass(TTimer);

	//-----------stuff from danhint----------------
	ControlStyle:=ControlStyle-[csOpaque];
	with Canvas do begin
		Brush.Style			 :=bsClear;
		Brush.Color			 :=clBackground;
	end;

  	//----------create off screen bitmap ----------
	offscreen_bitmap := Tbitmap.Create;
	can_display_hint := true;
	bubble_timer := TTimer.create(self);
	bubble_timer.ontimer := Ontick;

	tick_counter := 0;
end;

{*************************************************************}
destructor TBubbleHintWindow.Destroy;
begin
 	offscreen_bitmap.Free;
	bubble_timer.free;
	inherited Destroy;
end;

{################################################################}
function TBubbleHintWindow.IsHintMsg(var Msg: TMsg): Boolean;
var
	mouse_pos: Tpoint;
begin
	{------------ reset if the hint can be displayed on a mousemove ---}
	if not can_display_hint then
		if (msg.Message = WM_MOUSEMOVE) then
		begin
			getCursorPos(mouse_pos);
			if (mouse_pos.x <> last_mouse_pos.x) or
				(mouse_pos.y <> last_mouse_pos.y) then
					can_display_hint := true;
		end;

	{------------ use default behaviour --------}
	ishintmsg := inherited ishintmsg(msg);

end;

{**************** our tip window doesnt have a border *************}
procedure TBubbleHintWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.style := Params.style - WS_BORDER;
end;

{################################################################}
{paint bubble into mem bitmap which allready contains the
captured background}
procedure TBubbleHintWindow.Paint;
var
  outline: array[1..7] of Tpoint;
  shadow: array[1..7] of Tpoint;
  text_width, text_height: integer;
  vertex: integer;
  x,y: integer;
  outline_region, shadow_region: Hrgn;
  screen_rect: Trect;
begin
  {-------- determine points for speech bubble polygon --------}
  with offscreen_bitmap.canvas do
  begin
	text_height := textheight(caption);
	text_width := textwidth(caption);
  end;

  outline[7].x := 0;		 outline[7].y := 0;
  outline[1].x := 0;		 outline[1].y := 0;
  outline[2].x := text_width + 2*HINT_PADDING;	 outline[2].y := 0;
  outline[3].x := outline[2].x;   outline[3].y := text_height +2 * HINT_PADDING;
  outline[4].x := offscreen_bitmap.width; outline[4].y := offscreen_bitmap.height;
  outline[5].x := outline[3].x - text_height; outline[5].y := outline[3].y;
  outline[6].x := 0; outline[6].y := outline[5].y;

  {------------ and the shadow, tail concides----------------------}
  for vertex := 1 to 7 do
  begin
	shadow[vertex].x := outline[vertex].x + SHADOW_DEPTH;
	shadow[vertex].y := outline[vertex].y + SHADOW_DEPTH;
  end;
  shadow[4].x := outline[4].x;
  shadow[4].y := outline[4].y;

  {------------------paint hint background----------------------------}
  with offscreen_bitmap.canvas do
  begin
	pen.color := clblack;
	pen.width := 1;
	brush.color := color;
	brush.style := bssolid;
	polygon(outline);
  end;

  {-------------------paint text-----------------------------------}
  with offscreen_bitmap.canvas do
  begin
	font.color := clblack;
	brush.style := bsclear;
	textout( HINT_PADDING, HINT_PADDING , caption);
  end;


  {------------------shadow-----------------------------}
  {Draw Shadow of the Hint Rect}
  outline_region := CreatePolygonRgn(outline,7,WINDING);
  shadow_region := CreatePolygonRgn(shadow,7,WINDING);
  for x := 1 to width do
	for y := 1 to height do
	  if (odd(x) = odd(y)) and PtInRegion(shadow_region,x,y) and not PtInRegion(outline_region,x,y) then
		offscreen_bitmap.Canvas.Pixels[X,Y]:=SHADOW_COLOUR;
  deleteobject(outline_region);
  deleteobject(shadow_region);

  {blit to screen}
  with canvas do
  begin
	CopyMode:=cmSrcCopy;
	screen_rect := ClientRect;
	screen_rect.Right := offscreen_bitmap.Width;
	screen_rect.Bottom := offscreen_bitmap.Height;
	CopyRect(screen_rect,offscreen_bitmap.Canvas,screen_rect);
  end;
end;


{*************************************************************}
{ called when the hint is to appear, for transparent windows, this is a
  great time to capture the area behind where the hint is to appear.}
procedure TBubbleHintWindow.ActivateHint(Rect: TRect; const AHint: string);
var
	hint_height, hint_width: integer;
	cursor: tpoint;
	ScreenDC :HDC;
	display_rect: trect;
begin
	if not can_display_hint then
		exit;

	//------adjust offscreen bitmap to be big enough to fit text -------------
	with offscreen_bitmap.canvas do
	begin
		hint_height := 2 * (textheight(ahint) + HINT_PADDING) + SHADOW_DEPTH ;
		hint_width := textwidth(ahint) + 2*HINT_PADDING + textheight(ahint) div 2;
	end;
	offscreen_bitmap.width := hint_width;
	offscreen_bitmap.height := hint_height + HINT_HEIGHT_FUDGE;

	 {----to where the mouse is, technically delphi doesnt like this-----------}
	 getcursorpos(cursor);
	 with display_rect do
	 begin
	   right := cursor.x;
	   bottom :=  cursor.y;
	   left := right - hint_width;
	   top := bottom - hint_height;
	 end;

	 {----move window so that it doesnt fall off edge of screen--------------}
	with display_rect do begin
		if left < 0 then begin
			left := 0;
			right :=	left + hint_width;
		end;
		if top < 0 then begin
			top := 0;
			bottom :=	top + hint_height;
		end;
	end;

	{-----grab underlying screen----------------------------------------}
	ScreenDC:=CreateDC('DISPLAY',nil,nil,nil);
	BitBlt(offscreen_bitmap.Canvas.Handle,0,0,offscreen_bitmap.width,offscreen_bitmap.height,ScreenDC,display_rect.left,display_rect.top,SRCCOPY);
	DeleteDC(ScreenDC);

	{--------------and the rest-----------------}
	inherited activatehint(display_rect, ahint);

	{--------------start the timer-----------------}
	bubble_timer.enabled := true;
	tick_counter := 0;
end;

{*************************************************************}
procedure TBubbleHintWindow.Ontick(Sender:Tobject);
begin
	bubble_timer.enabled := false;
	tick_counter := tick_counter +1;

	if tick_counter >= DISPLAY_TICK_COUNT then
		begin
			can_display_hint := false;
			getCursorPos(last_mouse_pos);
			application.cancelhint;
		end
	else
		bubble_timer.enabled := true;

end;

//
//####################################################################
(*
	$History: bubble.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/classes
 * 
 * *****************  Version 6  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/classes
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 5  *****************
 * User: Administrator Date: 9/06/04    Time: 19:22
 * Updated in $/code/paglis/classes
 * fudged bubble help
 * 
 * *****************  Version 4  *****************
 * User: Administrator Date: 4/06/04    Time: 0:04
 * Updated in $/code/paglis/classes
 * formatting adjusted
 * 
 * *****************  Version 3  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
*)
//####################################################################
//
end.



