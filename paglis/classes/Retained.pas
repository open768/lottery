unit Retained;
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


interface

uses
  SysUtils, WinProcs, Messages, Classes, Graphics, Controls,extctrls;

type
  RetainedError = class (Exception);
  TRetainedCanvas = class(tcustomcontrol)
  private
	{ Private declarations }
		F_Component_Can_Be_Resized: Boolean;
		F_component_is_animated: Boolean;
		F_draw_enabled: Boolean;
		F_resize_allowed: Boolean;
		m_delayed_resize: boolean;
		m_delayed_resize_shape: Tpoint;
		F_clear_on_redraw: boolean;
		F_offscreen_canvas, F_transient_canvas: Tcanvas;
		C_offscreen_bitmap, C_transient_bitmap: Tbitmap;
		F_border_colour: Tcolor;
		F_border_visible: Boolean;
		F_border_width:Byte;
		F_running: Boolean;
		F_animation_interval: word;
		m_InRedraw: boolean;
		f_MaxHeight: word;
		m_mouseDown_pos: Tpoint;
		m_mouse_isDown: boolean;
		m_mouse_in_drag: boolean;
		f_minimum_width: integer;
		f_minimum_height: integer;

		C_stop_animation:boolean;
		C_animation_timer: TTimer;
		C_mousedown_time: TDateTime;

		procedure Tick(sender:Tobject);

		procedure set_draw_enabled(value: Boolean);
		procedure set_border_colour(value: Tcolor);
		procedure set_border_visible(value: Boolean);
		procedure set_border_width(value: Byte);
		procedure set_animation_interval(value: Word);
		procedure set_component_is_animated(value:Boolean);
		procedure set_running(value:Boolean);
		procedure set_max_height(value:word);

		procedure CMFontChanged(var M:TMessage); message CM_FONTCHANGED;
		procedure CMColorChanged(var M:TMessage); message CM_COLORCHANGED;
		procedure CMEnabledChanged(var M: TMessage); message CM_ENABLEDCHANGED;

		procedure end_animation;
	protected
		{ Protected declarations }

		procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
		procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
		procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
		procedure Paint; override;
		procedure Resize_Component(ALeft, ATop, AWidth, AHeight: Integer);
		procedure SetParent(AParent: TWinControl);override;
		procedure redraw;

		procedure OnRedraw; virtual;  abstract;
		procedure OnColorChanged; virtual;
		procedure OnBorderWidthChanged; virtual;
		procedure OnSetbounds; virtual;
		procedure OnFontChanged; virtual;
		procedure OnAnimationStart; virtual;
		procedure OnAnimationTick; virtual;
		procedure OnAnimationEnd; virtual;
		procedure OnCreate; virtual;
		procedure OnDestroy; virtual;
		procedure onPaint; virtual;
		procedure onMouseDragStart(downPos:Tpoint); virtual;
		procedure onMouseDrag(Shift: TShiftState; currentPos, downPos: Tpoint); virtual;
		procedure OnMouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;
		procedure onMouseDragEnd(pos:Tpoint); virtual;

		property ComponentIsAnimated:Boolean read F_component_is_animated write set_component_is_animated;
		property ComponentCanBeResized:Boolean read F_Component_Can_Be_Resized write F_Component_Can_Be_Resized;
		property OffscreenCanvas: TCanvas read F_offscreen_canvas;
		property TransientCanvas: TCanvas read F_transient_canvas;
		property Running: Boolean read F_running write set_running;
	public
		{ Public declarations }
		function inDesignMode:boolean;
		procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
		constructor Create (AOwner: TComponent); override;
		destructor Destroy; override;
		procedure start;
		procedure stop;
		procedure step;

	published
		{ Published declarations }
		property Hint;
		property ParentShowHint;
		property ShowHint;
		property Font;
		property ParentFont;
		property ParentColor;
		property Color;
		property BorderColour: Tcolor read F_border_colour write set_border_colour;
		property BorderVisible: Boolean read F_border_visible write set_border_visible;
		property BorderWidth: Byte read F_border_width write set_border_width;
		property ClearOnRedraw: Boolean read F_clear_on_redraw write F_clear_on_redraw;

		property DrawEnabled: Boolean read F_draw_enabled write set_draw_enabled;
		property ResizeEnabled: Boolean read F_resize_allowed write F_resize_allowed;

		property AnimationRunning: Boolean read F_running;
		property AnimationInterval: Word read F_animation_interval write set_animation_interval;
		property AnimatedComponent:Boolean read F_component_is_animated;
		property MaxHeight: word read f_MaxHeight write set_max_height;
		property MinimumWidth: integer write f_minimum_width;
		property MinimumHeight: integer write f_minimum_height;
	end;

implementation
uses
	misclib;
const
	DEFAULT_ANIMATION_INTERVAL = 83;
	DEFAULT_BORDER_COLOUR = clblack;
	MOUSECLICK_WINDOW = 250;

//#####################################################################################
//# main
//#####################################################################################
constructor TRetainedCanvas.Create (AOwner: TComponent);
begin
	inherited Create(AOwner);

	{----------------timer stuff  ---------------------------}
	RegisterClass(TTimer);
	C_animation_timer := nil;
	F_running := false;
	F_animation_interval:=DEFAULT_ANIMATION_INTERVAL;	  {25 fps}
	C_stop_animation:= false;
	m_InRedraw := false;
	m_mouse_in_drag := false;
	f_maxHeight := 0;
	m_delayed_resize := false;
	f_minimum_width := 0;
	f_minimum_height := 0;

	{------------- now thats over, lets get to it -----------------------}
	F_component_can_be_resized := true;
	C_offscreen_bitmap := Tbitmap.Create;	   {offscreen bitmap}
	F_offscreen_canvas := C_offscreen_bitmap.canvas;

	C_transient_bitmap := nil;
	F_transient_canvas := nil;

	F_draw_enabled := true;
	F_resize_allowed := true;
	F_border_colour := DEFAULT_BORDER_COLOUR;
	F_border_visible:= true;
	F_clear_on_redraw := true;
	m_mouse_isDown := false;
	OnCreate;
end;

{********************************************************************}
destructor TRetainedCanvas.Destroy;
begin
  {------------- stop animation -----------------------}
  if assigned(C_animation_timer) then
  begin
	stop;
	ProcessMessages;
	C_animation_timer.enabled := false;
	C_animation_timer.free;
	C_animation_timer := nil;
  end;

  {offscreen bitmaps no longer needed}
  if assigned(C_offscreen_bitmap) then
	C_offscreen_bitmap.Free;

  if assigned(C_transient_bitmap) then
	C_transient_bitmap.Free;

  OnDestroy;
  inherited Destroy;
end;

{#########################################################################
 # VIRTUALS to be overridden by subclasses
 #########################################################################}
 procedure TRetainedCanvas.OnColorChanged;
 begin
 end;

{*****************************************************************}
 procedure TRetainedCanvas.onMouseDragStart(downPos:Tpoint);
 begin
 end;

{*****************************************************************}
 procedure TRetainedCanvas.OnMouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 begin
 end;

 {*****************************************************************}
 procedure TRetainedCanvas.onMouseDrag(Shift: TShiftState; currentPos, downPos: Tpoint);
 begin
 end;

 {*****************************************************************}
 procedure TRetainedCanvas.onMouseDragEnd(pos:Tpoint); 
 begin
 end;

{*****************************************************************}
 procedure TRetainedCanvas.OnCreate;
 begin
 end;

{*****************************************************************}
 procedure TRetainedCanvas.OnDestroy;
 begin
 end;

{*****************************************************************}
 procedure TRetainedCanvas.OnSetbounds;
 begin
  {size changed - do any calculations before a redraw}
 end;

{*****************************************************************}
 procedure TRetainedCanvas.OnFontChanged;
 begin
  {font changed - do any calculations before a redraw}
 end;

{*****************************************************************}
 procedure TRetainedCanvas.OnAnimationStart;
 begin
 end;

{*****************************************************************}
procedure TRetainedCanvas.OnBorderWidthChanged;
begin
end;

{*****************************************************************}
procedure TRetainedCanvas.onPaint;
begin
end;

{#########################################################################
 # Events
 #########################################################################}
procedure TRetainedCanvas.CMFontChanged(var M:TMessage);
begin
	F_offscreen_canvas.font.assign(font);
	if assigned(F_transient_canvas) then
		F_transient_canvas.font.assign(font);

	OnFontChanged;
	redraw;
	inherited
end;

{*****************************************************************}
procedure TRetainedCanvas.CMColorChanged(var M:TMessage);
begin
	OnColorChanged;
	redraw;
	inherited
end;

{*****************************************************************}
procedure TRetainedCanvas.CMEnabledChanged(var M:TMessage);
begin
	redraw;
	inherited
end;
{*****************************************************************}
procedure TRetainedCanvas.set_draw_enabled(value: Boolean);
begin
  if value <> F_draw_enabled then
	begin
	F_draw_enabled := value;
	redraw;
	end;
end;

{*****************************************************************}
procedure TRetainedCanvas.set_border_colour(value: Tcolor);
begin
  if value <> F_border_colour then
  begin
	F_border_colour := value;
	redraw;
  end;
end;

{*****************************************************************}
procedure TRetainedCanvas.set_border_width(value: byte);
begin
	if value <> F_border_width then
  begin
	F_border_width := value;
	OnBorderWidthChanged;
	redraw;
  end;
end;

{*****************************************************************}
procedure TRetainedCanvas.set_border_visible(value: boolean);
begin
  if value <> F_border_visible then
  begin
	F_border_visible := value;
		redraw;
  end;
end;


{*****************************************************************}
function TRetainedCanvas.inDesignMode:boolean;
begin
  result := g_misclib.in_design_mode(self);
end;

{#########################################################################
 #
 #########################################################################}
{*****************************************************************}
procedure TRetainedCanvas.SetParent(AParent: TWinControl);
begin
	inherited SetParent(Aparent);
end;

{*****************************************************************}
procedure TRetainedCanvas.set_max_height(value:word);
begin
	if value <> f_maxHeight then
	begin
		f_maxheight  := value;
		if (f_maxheight>0) and (height > f_maxheight) then
			height := f_maxheight;
	end;
end;


{*****************************************************************}
procedure TRetainedCanvas.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
	if (not F_component_can_be_resized) and indesignmode then
	begin
		awidth := width;
		aheight := height;
	end;

	if (f_maxheight>0) and (aheight>f_maxheight) then
		aheight := f_maxheight;

	if (AWidth< f_minimum_width) then AWidth := f_minimum_width;
	if (AHeight< f_minimum_height) then AHeight := f_minimum_height;

	Resize_Component(aleft,atop,awidth,aheight);
end;

{*****************************************************************}
procedure TRetainedCanvas.Resize_Component(aleft,atop,awidth,aheight:integer);
begin
	if (self.parent <> nil) then
	begin	 {.}

		if (awidth>0) and (aheight>0) then
		begin

			if (F_running) then
			begin
					m_delayed_resize_shape.x := aWidth;
					m_delayed_resize_shape.y := aHeight;
					m_delayed_resize := true;
					exit;
			end;
			if (not F_resize_allowed) then exit;

			C_offscreen_bitmap.width := AWidth;
			C_offscreen_bitmap.height := AHeight;

			if assigned(C_transient_bitmap) then
			begin	{..}
					C_transient_bitmap.width := AWidth;
				C_transient_bitmap.height := AHeight;
			end;   {..}
		end;
	end; {.}

	{--------------------------------------------------------}
	inherited SetBounds( ALeft, ATop, AWidth, AHeight);

	{--------------------------------------------------------}
	if (self.parent <> nil) then
	begin
		OnSetBounds;
		redraw;
	end;
end;


{*****************************************************************}
procedure TRetainedCanvas.Paint;
begin
		if F_draw_enabled and (parent <> nil) and visible then
		begin
			canvas.draw(0,0, C_offscreen_bitmap);
			onPaint;
		end;
end;

{*****************************************************************}
procedure TRetainedCanvas.redraw;
begin
	if (parent=nil) or (not F_draw_enabled) then
	exit;

  {-----------clear the offscreen bitmap---------------}
  if F_clear_on_redraw then
	with F_offscreen_canvas do
	 begin
	  pen.color := self.color;
	  brush.color := self.color;
	  brush.style := bsSolid;
	  rectangle(0, 0, self.width, self.height);
	end;

	{---draw body of control--------------------------}
	m_InRedraw := true;
	try
		OnRedraw;
	finally
		m_InRedraw := false;
	end;


  {--------------draw border last -------------------}
  if F_border_visible then
	  with F_offscreen_canvas do
	begin
		brush.style := bsclear;
		 pen.color := F_border_colour;
		pen.width := 1;
		rectangle(0,0,width, height);
	end;

  {-------------------paint to screen---------------}
  paint;
end;

{*****************************************************************}
procedure TRetainedCanvas.MouseMove(Shift: TShiftState; X, Y: Integer);
var
	mouse_pos: Tpoint;
begin
	inherited;
	if inDesignMode then exit;
	if not m_mouse_isDown then exit;
	if m_InRedraw then exit;

	mouse_pos.x := x;
	mouse_pos.y := y;

	if not m_mouse_in_drag then
	begin
		onMouseDragStart(mouse_pos);
		m_mouse_in_drag := true;
	end;
	onMouseDrag(Shift, mouse_pos, m_mouseDown_pos);
end;

{*****************************************************************}
procedure TRetainedCanvas.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
	inherited;
	if inDesignMode then exit;
	if m_InRedraw then exit;
	m_mouse_isDown := true;
	m_mouseDown_pos.x := x;
	m_mouseDown_pos.y := y;
	C_mousedown_time := Time;
end;

{*****************************************************************}
procedure TRetainedCanvas.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
	elapsed_time: longint;
	now: TDateTime;
	pos:tpoint;

begin
	inherited;
	if inDesignMode then exit;

	if m_InRedraw then exit;
	pos.x := x;
	pos.y := y;

	now := time;
	elapsed_time:= g_misclib.time_difference(C_mousedown_time, now);
	if not indesignmode and (elapsed_time <= MOUSECLICK_WINDOW) then
		 OnMouseClick( button,shift,x,y)
	else
		if m_mouse_in_drag then
			onMouseDragEnd(pos);
		//else
			//onMouseUp(X,Y);
			
	m_mouse_isDown := false;
	m_mouse_in_drag := false;
end;

//#####################################################################################
//# ANIM
//#####################################################################################
{*****************************************************************}
 procedure TRetainedCanvas.OnAnimationTick;
 begin
 end;

{*****************************************************************}
procedure TRetainedCanvas.OnAnimationEnd;
begin
end;

{*****************************************************************}
procedure TRetainedCanvas.step;
begin
	OnAnimationTick;
	ProcessMessages;
	paint;
end;


{*****************************************************************}
procedure TRetainedCanvas.set_animation_interval(value: Word);
begin
  if value <> F_animation_interval then
  begin
	F_animation_interval := value;
	if F_running then	//if running change interval, otherwise interval will be set before running 		
	begin
		C_animation_timer.enabled := false;
		C_animation_timer.interval := F_animation_interval;
		C_animation_timer.enabled := true;
	end;

  end;
end;


{*****************************************************************}
procedure TRetainedCanvas.set_component_is_animated(value: Boolean);
begin
  if value <> F_component_is_animated then
  begin {.}
	F_component_is_animated := value;

	{------ dont do anything more unless application is running for real ----}
	if (csDesigning in ComponentState) then exit;

	{-- create timer and transient canvas if necessary---}
	if (not assigned(C_animation_timer)) and F_component_is_animated then
	begin {..}
		C_animation_timer := Ttimer.Create(Owner);
		with C_animation_timer do
			begin {...}
			enabled := false;
			Ontimer := tick;
		end; {...}

		C_transient_bitmap := Tbitmap.Create;	 {offscreen bitmap}
		C_transient_bitmap.width := width;
			C_transient_bitmap.height := height;
		F_transient_canvas := C_transient_bitmap.canvas;

	end;{..}

  end;{.}

end;

{*****************************************************************}
procedure TRetainedCanvas.set_running(value: Boolean);
begin
	if value = F_running then exit;

	if value then
		start
	else
		stop;
end;

{#########################################################################
 #
 #########################################################################}
procedure TRetainedCanvas.start;
begin
  {---- exit if not running for real, ----------------------------}
  {---- or component is not declared as being animated -----------}
  {---- or allready running---------------------------------------}
  if (csDesigning in ComponentState) then exit;
  if not ComponentIsAnimated then exit;
  if F_running then exit;

  {- - first tick coming up ------------}
  OnAnimationStart;
	ProcessMessages;

  {- - start up the ticker - - - - - - - }
  F_running := true;
  C_stop_animation := false;
  with C_animation_timer do
  begin {.}
	interval := F_animation_interval;
	enabled := true;
  end;	{.}

  ProcessMessages;
end;

{*****************************************************************}
{no way to stop timer , so set a flag that the tick method will act on}
procedure TRetainedCanvas.stop;
begin
	f_running := false;
	C_stop_animation := true;
end;

{*****************************************************************}
procedure TRetainedCanvas.end_animation;
begin
	F_running := false;
	C_stop_animation := false;
	OnAnimationEnd;
	redraw;
	canvas.draw(0,0, C_offscreen_bitmap);
	ProcessMessages;
end;


{#########################################################################
 #
 #########################################################################}
procedure TRetainedCanvas.Tick(sender:Tobject);
var
	Old_Timer_State:Boolean;
	was_running: boolean;
begin
	Old_Timer_State := C_animation_timer.enabled;
	C_animation_timer.enabled := false;

	if not F_running then exit;

	{---------- draw static background onto transient bitmap ---------------}
	if not C_stop_animation then
  begin
	  F_transient_canvas.draw(0,0, C_offscreen_bitmap);
	ProcessMessages;
  end;

  {------ allow the component to do its stuff onto the transient bitmap---}
  if not C_stop_animation then
	begin
	OnAnimationTick;
	  ProcessMessages;
  end;

	{---------- blit transient bitmap to screen  ---------------------------}
  if not C_stop_animation then
  begin
		canvas.draw(0,0, C_transient_bitmap);
		ProcessMessages;
	end;

	{------------ perform any delayed resize -------------------------------}
	if m_delayed_resize then
	begin
		was_running := f_running;
		f_running := false;

		setBounds(left,top,  m_delayed_resize_shape.x, m_delayed_resize_shape.y);

		m_delayed_resize := false;
		f_running := was_running;
	end;

  {--- restart timer or tell component that animation has ceased. --------}
	if C_stop_animation then
	  end_animation
	else
	  C_animation_timer.enabled := Old_Timer_State;
end;

//
//####################################################################
(*
	$History: Retained.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/classes
 * 
 * *****************  Version 7  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/classes
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 6  *****************
 * User: Administrator Date: 1/01/05    Time: 11:17p
 * Updated in $/code/paglis/classes
 * parameter to create sparselist.create now mandatory
 * 
 * *****************  Version 5  *****************
 * User: Administrator Date: 6/05/04    Time: 22:37
 * Updated in $/code/paglis/classes
 * sets f_running to false on stopping
 * 
 * *****************  Version 4  *****************
 * User: Administrator Date: 5/08/03    Time: 0:17
 * Updated in $/code/paglis/classes
 * bugfix - drew transient bitmap on stopping, now fudged to update to
 * correct bitmap
 * 
 * *****************  Version 3  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
*)
//####################################################################
//

end.
