unit lottrender;
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
(* $Header: /PAGLIS/lottery/lottrender.pas 2     21/02/05 22:32 Sunil $ *)
//****************************************************************

// TODO - rework to cache all the ball graphics.  

interface
uses
	wintypes,graphics, lottype, sparselist;
type
	TRenderedBallsDetails = class(Tsparselist)
		bad_ball, flash_ball, black_ball: tbitmap;
		constructor create(pb_owns_objects:boolean);
		destructor destroy; override;
	end;

	TRenderedBalls = class
	private
		c_diameter_is_set:boolean;
		f_diameter: integer;
		f_rendered: boolean;
		c_rendered: TRenderedBallsDetails;
		c_mask: tbitmap;
		c_mask_rect:trect;
		F_max_numbers: byte;

		procedure pr_render_ball(poSource,poBitmap:tbitmap; poBallColour:Tcolor);
		procedure pr_update_rendered_balls();
		procedure pr_set_diameter(piDiameter: integer);
		procedure pr_draw_mask();
		procedure pr_set_max_numbers(piValue: byte);
		procedure pr_set_rendered(pbValue: boolean);
	public
		property Diameter: integer read f_diameter write pr_set_diameter;
		property MaxNumbers:byte	read F_max_numbers	write pr_set_max_numbers;
		property Rendered: boolean read f_rendered write pr_set_rendered;

		constructor create;
		destructor destroy; override;

		procedure blit_ball(
			ball_num: byte;
			const target_canvas: Tcanvas;
			target_rect:trect	); overload;
		procedure blit_ball(
			ball_num: byte;
			const target_canvas: Tcanvas;
			target_rect:trect;
			ball_type:TLottBallType); overload;
	end;

implementation
	uses
		intlist, misclib,miscimage, lottery, lotcolour;
	var
		m_fullsize_bitmaps: TRenderedBallsDetails;
		m_ball_colours: TLotteryBallColours;
	const
		INVISIBLE_COLOUR = 	$ABCDEF;

	//######################################################################
	//#
	//######################################################################
	constructor TRenderedBallsDetails.create(pb_owns_objects:boolean);
	begin
		inherited create(pb_owns_objects);
		flash_ball := nil;
		black_ball := nil;
	end;

	destructor TRenderedBallsDetails.destroy;
	begin
		if assigned(flash_ball) then flash_ball.free;
		if assigned(black_ball) then black_ball.free;
		inherited;
	end;

	//######################################################################
	//#
	//######################################################################
	 constructor TRenderedBalls.create;
	 begin
		inherited;
		c_diameter_is_set := false;
		c_mask := tbitmap.create;
		c_rendered := TRenderedBallsDetails.create(true);
		F_max_numbers := MAX_UK_LOTTERY_NUM;
		f_rendered := false;
	 end;

	 //*********************************************************************
	 destructor TRenderedBalls.destroy;
	 begin
		c_mask.free;
		c_rendered.free;
		inherited;
	 end;

	//######################################################################
	 procedure TRenderedBalls.pr_draw_mask();
	  begin
			{-------------adjust the c_mask bitmap ------------}
			c_mask.width := f_diameter;
			c_mask.height := f_diameter;

			{-------------draw the c_mask ------------}
			with c_mask_rect do
			begin
			  top :=0;
			  left :=0;
			  right := f_diameter;
			  bottom := f_diameter;
			end;

			with  c_mask.canvas do
			begin
			  pen.Style := psClear;
			  brush.color := INVISIBLE_COLOUR;
			  fillrect(c_mask_rect);
			  brush.color := clwhite;
			  ellipse(0,0,f_diameter,f_diameter);
			end;
			c_mask.TransparentColor := clwhite;
			c_mask.Transparent := true;
	 end;

	 //*********************************************************************
	 procedure TRenderedBalls.pr_render_ball(poSource,poBitmap:tbitmap; poBallColour:Tcolor);
	 begin
			poBitmap.width := f_diameter;
			poBitmap.height := f_diameter;

			//-------------------- fill background with invisible colour ---------------
			with poBitmap.canvas do	begin
				brush.style := bsSolid;
				brush.color := INVISIBLE_COLOUR;
				pen.Style := psClear;
				FillRect(c_mask_rect);
			end;

			//---------------- draw the foreground ------------------------------------
			if f_rendered then	begin
				poBitmap.canvas.stretchdraw(c_mask_rect,poSource);
				poBitmap.Canvas.Draw(0,0,c_mask);   		//draw mask ontop
			end	else
				with poBitmap.canvas do	begin
					brush.color := poBallColour;
					ellipse(c_mask_rect.left,c_mask_rect.top, c_mask_rect.right, c_mask_rect.bottom);
				end;

		//make bitmap transparent
		poBitmap.TransparentColor := INVISIBLE_COLOUR;
		pobitmap.Transparent := true;
	 end;


	//*********************************************************************
	procedure TRenderedBalls.pr_set_rendered(pbValue: boolean);
	begin
		if pbValue = f_rendered then exit;
		f_rendered := pbValue;
		pr_update_rendered_balls;
	end;

	//*********************************************************************
	procedure TRenderedBalls.pr_set_max_numbers(piValue: byte);
	begin
		if F_max_numbers = piValue then exit;
		F_max_numbers := piValue;
	end;

	//*********************************************************************
	procedure TRenderedBalls.pr_set_diameter(piDiameter: integer);
	begin
		if c_diameter_is_set and (piDiameter = f_diameter) then exit;
		f_diameter := piDiameter;
		c_diameter_is_set := true;
		pr_update_rendered_balls;
	end;

	//*********************************************************************
	procedure TRenderedBalls.pr_update_rendered_balls();
	var
		index: integer;
		full_size: TLotteryBallColourResult;
		rendered:tbitmap;
	begin
		//---------------- first the mask ---------------------------------
		 pr_draw_mask();

		 //------------------- render all the balls that have been defined -----------
		 for index := m_ball_colours.list.fromindex to m_ball_colours.list.toindex do
		 begin
		 	//------ get full size bitmap 
			full_size := TLotteryBallColourResult(m_ball_colours[index]);
			if full_size = nil then continue;

			//---------- ensure that an output bitmap is present ---
			rendered := tbitmap(c_rendered.Items[index]);
			if rendered = nil then
			begin
				rendered := tbitmap.create;
				c_rendered.items[index] := rendered;
			end;

			//---------- draw full size bitmap onto it ---------------------------
			pr_render_ball(full_size.bmp, rendered , full_size.colour);
		 end;

		 //------------------- render the flash and black balls --------
		 if c_rendered.flash_ball = nil then c_rendered.flash_ball := tbitmap.create;
		 pr_render_ball(m_fullsize_bitmaps.flash_ball, c_rendered.flash_ball , clred);

		 if c_rendered.black_ball = nil then c_rendered.black_ball := tbitmap.create;
		 pr_render_ball(m_fullsize_bitmaps.black_ball, c_rendered.black_ball , clblack);

		 if c_rendered.bad_ball = nil then c_rendered.bad_ball := tbitmap.create;
		 pr_render_ball(m_fullsize_bitmaps.bad_ball, c_rendered.bad_ball ,  m_ball_colours.InvalidColour);

	 end;

	//######################################################################
	 procedure TRenderedBalls.blit_ball(
		 ball_num: byte;
		 const target_canvas: Tcanvas;
		 target_rect:trect	 );
	 var
		ball_type: TLottBallType;
	 begin
		ball_type := lottery_ball(ball_num);
		blit_ball(ball_num,target_canvas,target_rect,ball_type)
	 end;

	//*********************************************************************
	procedure TRenderedBalls.blit_ball(
		 ball_num: byte;
		 const target_canvas: Tcanvas;
		 target_rect:trect; ball_type:TLottBallType );
	var
		src: tbitmap;
		index:integer;
	begin
		src := nil;

		//-------------- find the ball  -------------------------
		case ball_type of	//[.]
			ball_flash:
				src := c_rendered.flash_ball;
			ball_black:
				src := c_rendered.black_ball;
			else
				begin		//[..]
					if ball_num < c_rendered.fromindex then
						src := c_rendered.bad_ball;

					if (src = nil) and (ball_num >= c_rendered.toindex) then
						src := tbitmap(c_rendered.items[c_rendered.toindex])
					else
						for index := ball_num downto c_rendered.fromindex do
						begin
							src := tbitmap(c_rendered.items[index]);
							if src <> nil then
								break;
						end;
				end;		//[..]
		 end;		//[.]

		 //--------------- draw the ball --------------------------------
		 if src<>nil then
			target_canvas.Draw(target_rect.Left,target_rect.Top,src);

	 end;

	 //*********************************************************************

	//######################################################################
	//#
	//######################################################################
	procedure C_load_ball_bitmaps;
	var
		app_path:string;
		index:integer;
		obj: TLotteryBallColourResult;
	begin
		m_ball_colours:= TLotteryBallColours.create;
		m_fullsize_bitmaps := TRenderedBallsDetails.create(false);

		app_path := g_misclib.get_program_pathname;

      //load full size bitmaps from disk
		m_fullsize_bitmaps.flash_ball := g_miscimage.make_bitmap_from_file( app_path+ 'flash.bmp');
		m_fullsize_bitmaps.black_ball := g_miscimage.make_bitmap_from_file( app_path+ 'black.bmp');
		m_fullsize_bitmaps.bad_ball := g_miscimage.clone_bitmap(m_ball_colours.InvalidItem.bmp);

		//reference the precreated coloured balls - no need to take a copy
		for index := m_ball_colours.List.FromIndex to m_ball_colours.List.toIndex do
		begin
			obj := TLotteryBallColourResult(m_ball_colours[index]);
			if obj <> nil then
				m_fullsize_bitmaps.Items[index] := obj.bmp;
		end;
	end;

	{*********************************************************************}
	procedure C_free_ball_bitmaps;
	begin
		m_ball_colours.free;
		m_fullsize_bitmaps.free;
	end;


initialization
	c_load_ball_bitmaps;
finalization
	c_free_ball_bitmaps;
//
//####################################################################
(*
	$History: lottrender.pas $
 * 
 * *****************  Version 2  *****************
 * User: Sunil        Date: 21/02/05   Time: 22:32
 * Updated in $/PAGLIS/lottery
 * removed redundant code - still have to find memory leak
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/lottery
 * 
 * *****************  Version 15  *****************
 * User: Administrator Date: 9/06/04    Time: 21:40
 * Updated in $/code/paglis/lottery
 * removed fudge for black ball
 * 
 * *****************  Version 14  *****************
 * User: Administrator Date: 9/06/04    Time: 21:36
 * Updated in $/code/paglis/lottery
 * simplified calls used to render balls - 6:1 reduction
 * 
 * *****************  Version 13  *****************
 * User: Administrator Date: 5/05/04    Time: 23:14
 * Updated in $/code/paglis/lottery
 * split out image misc and it all sort of works
 * 
 * *****************  Version 12  *****************
 * User: Administrator Date: 29/04/04   Time: 0:09
 * Updated in $/code/paglis/lottery
 * balls drawn transparently to be more efficient! 
 * black balls not drawn transparently yet.
 * 
 * *****************  Version 10  *****************
 * User: Admin        Date: 3/05/03    Time: 2:09
 * Updated in $/code/paglis/lottery
 *
 * *****************  Version 9  *****************
 * User: Sunil        Date: 17-04-03   Time: 10:26p
 * Updated in $/code/paglis/lottery
 * made a copy of blit_ball private
 * 
 * *****************  Version 8  *****************
 * User: Sunil        Date: 15-04-03   Time: 12:34a
 * Updated in $/code/paglis/lottery
 * changed the way rendered balls are drawn, still some improvements to
 * make yet.
 *
 * *****************  Version 7  *****************
 * User: Sunil        Date: 12-04-03   Time: 12:05p
 * Updated in $/code/paglis/lottery
 * renamed functions to be more cohesive, applied coding standards
 * 
 * *****************  Version 6  *****************
 * User: Sunil        Date: 12-04-03   Time: 11:49a
 * Updated in $/code/paglis/lottery
 * changed behaviour of rendered balls, uses propoerties instead of
 * passing stuff in.
 * 
 * *****************  Version 5  *****************
 * User: Sunil        Date: 7-04-03    Time: 11:31p
 * Updated in $/code/paglis/lottery
 * added sparselist for caching balls -
 * fixed redundant code
 * 
 * *****************  Version 4  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/lottery
 * added headers and footers
*)
//####################################################################
//
end.
