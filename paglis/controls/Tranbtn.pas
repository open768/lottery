unit Tranbtn;

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
(* $Header: /PAGLIS/controls/Tranbtn.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//


//*BASED ON Transparent button component. 1.06. Copyright Mik 1998.
//*removed bitmap from transparent bitmap!! not needed

//Original copyright information (superceded by above)
//#The copyright notice is a joke.
//#Do anything you want with it. Consider it is yours.
//#More free components, tips, docs in Delphi Heritage Controls
//#(www.cs.monash.edu.au/~vtran)

interface

uses
	classes, wintypes, messages, controls, graphics;

type
	BStyle = (BSnone,BsNormal,BsIe,BsChevron);
	TMTranBtn = class(TGraphicControl)
	private
		f_over : Boolean;
		f_pushed : boolean;
		f_border_style : BStyle;
		f_is_transparent: Boolean;
		f_bgcolour: Tcolor;
		f_Highlitecolour: Tcolor;
		procedure WMLButtonDown(var msg: TWMLButtonDown); message WM_LBUTTONDOWN;
		procedure WMLButtonUp(var msg: TWMLButtonUp); message WM_LBUTTONUP;
		procedure mouseleave(var msg : tmessage); message cm_mouseleave;
		procedure mousein(var msg : tmessage); message cm_mouseenter;
		Procedure setborderstyle(value:Bstyle);
		procedure set_bg_colour(value:Tcolor);
		procedure set_is_transparent(value: boolean);

		procedure draw_normal;
		procedure draw_ie;
		procedure draw_bevelled;
		procedure CMFontChanged(var M:TMessage); message CM_FONTCHANGED;
		procedure CMEnabledChanged(var M: TMessage); message CM_ENABLEDCHANGED;
		 procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
	protected
		procedure Paint; override;

	public
		constructor Create(AOwner: TComponent); override;
		destructor Destroy; override;
		procedure	setAutosize;
	published
		property Enabled;
		Property OnClick;
		property OnMouseDown;
		property OnMouseMove;
		property OnMouseUp;
		property Visible;
		Property Hint;
		Property ShowHint;
		Property BorderStyle : BStyle read f_border_style write SetBorderStyle;
		Property Caption;
		Property Font;
		property parentfont;
		property BGColour: Tcolor read f_bgcolour write set_bg_colour;
		property HighlightColour: Tcolor read f_Highlitecolour write f_Highlitecolour;
		property isTransparent: boolean read f_is_transparent write set_is_transparent;
	end;

procedure Register;

implementation
uses
	sysutils, extctrls;

	//***************************************************************************
	 constructor TMTranBtn.Create(AOwner: TComponent);
	 begin
		 inherited Create(AOwner);
		 Width := 30;
		 Height := 30;
		 ControlStyle := ControlStyle - [csOpaque];
		 f_pushed := false;
		 f_border_style := BsNormal;
		 f_is_transparent := true;
		 f_Highlitecolour := clwhite;
	 end;

	//***************************************************************************
	 destructor TMTranBtn.Destroy;
	 begin
		 inherited Destroy;
	 end;


	//***************************************************************************
	 {this routine come from unit XparBmp of Michael Vincze (vincze@ti.com), I think it can be
	 optimized more. Will find time to check it again}

	//***************************************************************************
	procedure TMTranBtn.setborderstyle(value:Bstyle);
	begin
		if f_border_style <> value then
			begin
				f_border_style := value;
				Invalidate;
			end;
	end;

	//***************************************************************************
	procedure TMTranBtn.Paint;
	var
		ARect: TRect;
		text : array[0..200] of char;
		Fontheight : integer;
	begin //[.]
		//------------------------------------------------------------------
		if not enabled then
			canvas.brush.color := clDkGray
		else
			canvas.brush.color := f_bgcolour;

		if f_is_transparent then
			canvas.brush.Style := bsclear
		else
			canvas.brush.style := bssolid;

		case f_border_style of
			BsChevron:	draw_bevelled;
			BsNormal :	draw_normal;
			BsIe :		draw_IE;
		end; { case}

		//----------s--------------------------------------------------------
		if caption <> '' then //[..]
		begin
			if not enabled then
				canvas.font.color := clDkGray
			else
				canvas.font.color := font.color;

			with Canvas do	//[...]
			begin
				ARect := Rect(0,0,Width,Height);
				FontHeight := Canvas.TextHeight('W');
				Brush.Style := bsClear;
				with ARect do	//[....]
				begin
					Top := ((Bottom + Top) - FontHeight) shr 1;
					Bottom := Top + FontHeight;
					if f_pushed then
					begin
						top := top + 1;
						left := 2;
					end;
				end;	//[....]

				StrPCopy(Text, Caption);
				DrawText(Handle, Text, StrLen(Text), ARect, (DT_EXPANDTABS or DT_center));
			end; //[...]
		end; //[..]
	end; //[.]

	//***************************************************************************
	procedure TMTranBtn.mouseleave(var msg : tmessage);
	var
		rc : Trect;
	BEGIN
		if not enabled then exit;
		f_over := false;
		rc := getclientrect;
		INVALIDATE;
	END;

	//***************************************************************************
	procedure TMTranBtn.mousein(var msg : tmessage);
	BEGIN
		if not enabled then exit;
		f_over := true;
		INVALIDATE;
	END;

	//***************************************************************************
	procedure TMTranBtn.CMEnabledChanged(var M: TMessage);
	begin
		INVALIDATE;
	end;

	//***************************************************************************
	procedure TMTranBtn.CMTextChanged(var Message: TMessage);
	begin
		INVALIDATE;
	end;
	
	//***************************************************************************
	procedure TMTranBtn.CMFontChanged(var M:TMessage);
	begin
		canvas.font.assign(font);
		INVALIDATE;
	end;

	//***************************************************************************
	procedure TMTranBtn.WMLButtonDown;
	begin
		inherited;
		if not enabled then exit;

		istransparent := not istransparent;
		f_pushed := f_over;
		if f_pushed then
			invalidate;
		istransparent := not istransparent;
	end;

	//***************************************************************************
	procedure TMTranBtn.WMLButtonUp;
	begin
		inherited;
		f_pushed := false;
	end;

	//***************************************************************************
	procedure TMTranBtn.set_bg_colour(value:Tcolor);
	begin
		if (f_bgcolour <> value) or f_is_transparent then
		begin
			f_bgcolour := value;
			f_is_transparent := false;
			repaint;
		end;
	end;

	//***************************************************************************
	procedure TMTranBtn.set_is_transparent(value: boolean);
	begin
		if value <> f_is_transparent then
		begin
			f_is_transparent := value;
			repaint;
		end;
	end;

	//***************************************************************************
	procedure TMTranBtn.setAutosize;
	var
		 test_bitmap:tbitmap;
	begin
		test_bitmap := TBitmap.create;			//draws on canvas of parent.
		test_bitmap.canvas.font := font;

		width := test_bitmap.canvas.TextWidth(caption) + 20;
		height := test_bitmap.canvas.TextHeight(caption)	+ 10;
		test_bitmap.free;
	end;


	//***************************************************************************
	procedure TMTranBtn.draw_normal;
	var
		ARect: TRect;
	begin
		ARect := getclientrect;
		canvas.fillrect(arect);				//DOES NOTHING IF BRUSH IS BSCLEAR

		if f_pushed then
			frame3d(canvas, ARect ,clBtnShadow,clBtnHighlight, 1)
		else
			if f_over then
				frame3d(canvas, ARect ,clBtnHighlight,clBtnHighlight, 2)
			else
				frame3d(canvas, ARect ,clBtnHighlight,clBtnShadow, 1);
	end;

	//***************************************************************************
	procedure TMTranBtn.draw_ie;
	var
		ARect: TRect;
	begin
		ARect := getclientrect;
		canvas.fillrect(arect);				//DOES NOTHING IF BRUSH IS BSCLEAR
		if f_pushed then
			frame3d(canvas, ARect ,clBtnShadow,clBtnHighlight, 1)
		else
			if f_over then
				frame3d(canvas, ARect ,clBtnHighlight,clBtnShadow, 1);
	end;

	//***************************************************************************
	procedure TMTranBtn.draw_bevelled;
	var
		points : array[1..6] of Tpoint;
		dh:integer;
		r: trect;
	begin
		r.left := 1;
		r.top := 1;
		r.right := width-1;
		r.bottom := height-1;
		dh := ((r.bottom - r.top) div 2);
		r.bottom := r.top + 2* dh;				//ENSURE 45 DEGREE

		//---------------------build chevron shape ------------
		points[1].x := r.left +dh;		points[1].y :=r.top;
		points[2].x := r.right - dh;	points[2].y :=r.top;
		points[3].x := r.right;			points[3].y :=r.top + dh;
		points[4].x := r.right - dh;	points[4].y :=r.bottom;
		points[5].x := r.left +dh;		points[5].y :=r.bottom;
		points[6].x := r.left;			points[6].y :=r.top + dh;

		//---------------------draw shadow ------------
		canvas.pen.Width := 2;
		if enabled then	begin
			if f_over then
				canvas.pen.color := f_Highlitecolour
			else
				canvas.pen.color := clBtnshadow;
		end	else
			canvas.pen.color := clDkGray;
			
		canvas.Polygon(points);

		//---------------------draw highlight ------------
		canvas.pen.Width := 1;
		if enabled then	begin
			if f_over then
				canvas.pen.color := f_Highlitecolour
			else
				canvas.pen.color := clBtnHighlight;
		end	else
			canvas.pen.color := clSilver;
		canvas.Polygon(points);
	 end;


		//***************************************************************************
	procedure Register;
	begin
		RegisterComponents('Paglis Utils', [TMTranBtn]);
	end;

//
//####################################################################
(*
	$History: Tranbtn.pas $
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
 * User: Administrator Date: 31/05/04   Time: 23:51
 * Updated in $/code/paglis/controls
 * added  highlight colour change
 * 
 * *****************  Version 2  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/controls
 * added headers and footers
*)
//####################################################################
//
end.
