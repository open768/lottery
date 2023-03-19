unit scroller;

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
	uses classes, controls, forms, graphics, messages, sysutils, misclib;
type
	//########################################################################
	//# Scolling control.
	//# keeps page in memory and simply copies the appropriate bits
	//# of the page onto the screen - very simple but does the trick
	//# ****cant be used for unlimited sized bitmaps *****
	//#######################################################################
	TScrollingControlError = class(Exception);

	//TScrollingControl = class (TScrollingWinControl)
	TScrollingControl = class (TCustomControl)
	private
		{ Private declarations }
		f_draw_cross: boolean;
		m_offscreen_page: Tbitmap;
		F_virtual_width, F_virtual_height: integer;
		f_has_horiz_scrollbar, f_has_vert_scrollbar : boolean;
		f_scroll_percentage: percentage;
		f_viewport_topleft: TIntPoint;

		function get_Horiz_Scrollbar_Pos: integer;
		function get_Vert_Scrollbar_Pos: integer;
		procedure set_Horiz_Scrollbar_Pos(value:integer);
		procedure set_vert_Scrollbar_Pos(value:integer);
		procedure set_virtual_width(value: integer);
		procedure set_virtual_height(value: integer);

		procedure CMEnabledChanged(var M: TMessage); message CM_ENABLEDCHANGED;
		procedure WMHScroll(var ScrollData: TwmScroll); message wm_hscroll;
		procedure WMVScroll(var ScrollData: TwmScroll); message wm_vscroll;
		procedure OnScroll;

		procedure set_has_horiz_scrollbar(value: boolean);
		procedure set_has_vert_scrollbar(value: boolean);
		procedure update_Scrollbars;
	protected
		{ Protected declarations }
		procedure OnRedraw(aCanvas: TCanvas); virtual; abstract;
		procedure CreateParams(var Params: TCreateParams); override;
		procedure Paint; override;
		procedure redraw;
	public
		{ Public declarations }
		constructor Create(aOwner:TComponent); override;
		destructor Destroy; override;
		procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;

		property hasHorizScrollbar: boolean read f_has_horiz_scrollbar write set_has_horiz_scrollbar;
		property hasVertScrollbar: boolean read f_has_vert_scrollbar write set_has_vert_scrollbar;
		property drawCross: boolean read f_draw_cross write f_draw_cross;
	published
		{ Published declarations }
		property Align;
		property Hint;
		property ParentShowHint;
		property ShowHint;
		property Font;
		property ParentFont;
		property ParentColor;
		property Color;
		property Enabled;
		property VirtualWidth:Integer read f_virtual_width write set_virtual_width;
		property VirtualHeight:integer read f_virtual_height write set_virtual_height;
		property ScrollIncrementPercentage: percentage read f_scroll_percentage write f_scroll_percentage;
		property HorizScrollbarPos: integer read get_Horiz_Scrollbar_Pos write set_Horiz_Scrollbar_Pos;
		property VertScrollbarPos: integer read get_Vert_Scrollbar_Pos write set_vert_scrollbar_pos;
	end;


implementation
uses
	math, windows, dialogs ;
const
	DEAFAULT_ScrollIncrementPercentage = 20;

	//########################################################################
	//#
	//########################################################################
	constructor TScrollingControl.Create(AOwner: TComponent);
	begin
		inherited Create(AOwner);
		//------- create bitmaps ----------------------
		m_offscreen_page := graphics.Tbitmap.create;
		f_draw_cross := false;

		//--------- no scrollbar --------------------------
		f_has_horiz_scrollbar := false;
		f_has_vert_scrollbar := false;
		width := 100; height := 100;
		VirtualWidth := 100; VirtualHeight := 100;
		f_scroll_percentage := DEAFAULT_ScrollIncrementPercentage;
		f_viewport_topleft.x :=0;
		f_viewport_topleft.y := 0;

	end;

	//**********************************************************************
	destructor TScrollingControl.Destroy;
	begin
	  //------- destroy bitmaps ----------------------
	  m_offscreen_page.free;
		
	  //---------------------------------------------
	  inherited Destroy;
	end;


	//########################################################################
	//# properties
	//########################################################################
	procedure TScrollingControl.set_virtual_width(value: integer);
	begin
		if value = F_virtual_width then exit;

		f_virtual_width := value;
		hasHorizScrollbar := (F_virtual_width > width);
		m_offscreen_page.width := value;
		update_Scrollbars;
		redraw;
	end;

	//**********************************************************************
	procedure TScrollingControl.set_virtual_height(value: integer);
	begin
		if value = F_virtual_height then exit;
		f_virtual_height := value;
		m_offscreen_page.height := value;
		hasVertScrollbar := (F_virtual_height > Height);
		update_Scrollbars;
		redraw;
	end;


	//**********************************************************************
	procedure TScrollingControl.set_has_horiz_scrollbar(value: boolean);
	begin
		if value = f_has_horiz_scrollbar then exit;
		f_has_horiz_scrollbar := true;
		recreatewnd;
	end;

	//**********************************************************************
	procedure TScrollingControl.set_has_vert_scrollbar(value: boolean);
	begin
		if value = f_has_vert_scrollbar then exit;
		f_has_vert_scrollbar := true;
		recreatewnd;
	end;

	//**********************************************************************
	function TScrollingControl.get_Horiz_Scrollbar_Pos: integer;
	begin
		result := g_misclib.get_scrollbar_pos(handle, sb_horz);
	end;

	//**********************************************************************
	function TScrollingControl.get_Vert_Scrollbar_Pos: integer;
	begin
		result := g_misclib.get_scrollbar_pos(handle, sb_vert);
	end;

	//**********************************************************************
	procedure TScrollingControl.set_Horiz_Scrollbar_Pos(value:integer);
	begin
		g_misclib.set_scrollbar_pos(handle,sb_horz, value);
		paint;
	end;

	//**********************************************************************
	procedure TScrollingControl.set_vert_Scrollbar_Pos(value:integer);
	begin
		g_misclib.set_scrollbar_pos(handle,sb_vert, value);
		paint;
	end;

	//########################################################################
	//# messages
	//########################################################################
	procedure TScrollingControl.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
	begin
		inherited;
		update_Scrollbars;
	end;

	//**********************************************************************
	procedure TScrollingControl.WMHScroll(var ScrollData: TwmScroll);
	var
		apiscrollpos, scrollpos: integer;
	begin
		if g_misclib.in_design_mode(self) then exit;

		scrollpos := scrolldata.pos;
		apiscrollpos:=get_Horiz_Scrollbar_Pos; 
		//-------------------------------------------------------

		case ScrollData.ScrollCode of
			SB_BOTTOM:
				scrollpos := F_virtual_width;
			SB_LINELEFT:
				scrollpos := max(0,apiscrollpos - width * f_scroll_percentage div 100);
			SB_LINERIGHT:
				scrollpos := min(F_virtual_width,apiscrollpos + width * f_scroll_percentage div 100);
			SB_PAGELEFT:
				scrollpos := max(0,apiscrollpos - width);
			SB_PAGERIGHT:
				scrollpos := min(F_virtual_width,apiscrollpos + width);
			SB_TOP:
				scrollpos := width;
			sb_endscroll:
				exit;
		end;
			
		g_misclib.set_scrollbar_pos(handle, sb_HORZ, scrollpos);
		onscroll;
	end;

	//**********************************************************************
	procedure TScrollingControl.WMVScroll(var ScrollData: TwmScroll);
	var
		apiscrollpos, scrollpos: integer;
	begin
		if g_misclib.in_design_mode(self) then exit;
		//-------------------------------------------------------
		scrollpos := scrolldata.pos;
		apiscrollpos:=get_Vert_Scrollbar_Pos;

		//-------------------------------------------------------
		case ScrollData.ScrollCode of
			SB_BOTTOM:
				scrollpos := f_virtual_height;
			SB_LINEUP:
				scrollpos := max(0,apiscrollpos - height * f_scroll_percentage div 100);
			SB_LINEDOWN:
				scrollpos := min(F_virtual_height,apiscrollpos + height * f_scroll_percentage div 100);
			SB_PAGEUP:
				scrollpos := max(0,apiscrollpos - height);
			SB_PAGEDOWN:
				scrollpos := min(F_virtual_height,apiscrollpos + height);
			SB_TOP:
				scrollpos := 0;
			sb_endscroll:
				exit;
		end;
		g_misclib.set_scrollbar_pos(handle, SB_VERT, scrollpos);
		onscroll;
end;


	//**********************************************************************
	procedure TScrollingControl.CMEnabledChanged(var M: TMessage);
	begin
		redraw;
		paint;
	end;


	//########################################################################
	//# privates
	//########################################################################

	//**********************************************************************
	procedure TScrollingControl.Onscroll;
	begin
		paint;
	end;


	//**********************************************************************
	procedure TScrollingControl.CreateParams(var Params: TCreateParams);
	begin
	  inherited CreateParams(Params);
	  with Params do
	  begin
			if f_has_vert_scrollbar	then style := Style or WS_VSCROLL;
			if f_has_horiz_scrollbar  then Style := Style or WS_HSCROLL;
	  end;
	end;

	//**********************************************************************
	procedure TScrollingControl.update_Scrollbars;
	begin
		if width < F_virtual_width then
			hasHorizScrollbar := true;

		if f_has_horiz_scrollbar then
			g_misclib.set_scrollbar_range( handle, sb_horz, f_virtual_width, width);

		if height< F_virtual_height then
			hasVertScrollbar := true;
		if f_has_vert_scrollbar then
			g_misclib.set_scrollbar_range( handle, sb_vert, f_virtual_height, height);
	end;

	//**********************************************************************
	procedure TScrollingControl.Paint;
	begin
		if parent = nil then exit;
		canvas.draw(-HorizScrollbarPos,-VertScrollbarPos,m_offscreen_page);
	end;

	//**********************************************************************
	procedure TScrollingControl.redraw;
	var
		r:trect;
	begin
		//------------ draw a cross mark on bitmap -------------------------
		with r do
		begin
			left := 0; top :=0;
			bottom := F_virtual_height; right := F_virtual_width;
		end;
		
		if f_draw_cross then
			with m_offscreen_page.canvas do
			begin
				brush.color := clwhite;
				brush.style := bssolid;
				fillrect(r);

				pen.color := clred;
				moveto(0,0);
				lineto(F_virtual_width,F_virtual_height);
				moveto(F_virtual_width,0);
				lineto(0,F_virtual_height);
			end;
		
		//--------- call virtual method to put something useful in ---------
		OnRedraw(m_offscreen_page.canvas);
	end;

//
//####################################################################
(*
	$History: scroller.pas $
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
