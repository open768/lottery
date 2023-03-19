unit Ballrack_spinner;

interface
uses
	types, graphics;

type
	TBallRackSpinner = class
	private
		c_circle_mask, c_inverted_mask, c_circle_coloured, c_scratch: Tbitmap;
		c_indesignmode:boolean;
		c_circle_rect:Trect;
		f_diameter: integer;
		f_colour: tcolor;
		c_rotation_angle:integer;
		procedure pr_set_diameter(piValue: integer);
		procedure pr_set_color(prValue:tcolor);
	public

		constructor create(pbIndesignMode: boolean);
		destructor destroy; override;
		procedure draw_onto(poCanvas: TCanvas; piX,piY:integer);

		property colour: TColor read f_colour write pr_set_color;
		property Diameter: integer read f_diameter write pr_set_diameter;
	end;

implementation

uses
	ballrack, sine, lottery;

const
	ANGLE_INCREMENT =15;


//############################################################
//############################################################
constructor TBallRackSpinner.create(pbIndesignMode: boolean);
begin
	inherited create;
	clear_sine_cache;
	if not pbIndesignMode then
	begin
		c_circle_mask := Tbitmap.Create;
		c_circle_coloured := Tbitmap.Create;
		c_scratch := Tbitmap.Create;
		c_inverted_mask := tbitmap.Create;
	end;

   f_diameter := 0;
	c_indesignmode := pbIndesignMode;
	c_rotation_angle :=0;
end;

//*****************************************************************
destructor TBallRackSpinner.destroy;
begin
	if not c_indesignmode then
	begin
		c_circle_mask.free;
		c_circle_coloured.free;
		c_scratch.free;
		c_inverted_mask.free;
	end;
	inherited;
end;

//*****************************************************************
procedure TBallRackSpinner.pr_set_color(prValue:tcolor);
begin
	if prValue = f_colour then exit;
	f_colour := prValue;
end;

//*****************************************************************
procedure TBallRackSpinner.pr_set_diameter(piValue: integer);
begin
	if piValue = f_diameter then exit;
	f_diameter := piValue;
	if c_indesignmode then exit;

	with c_circle_rect do
	begin
		left := 0;  right := f_diameter;
		top := 0; bottom:= f_diameter;
	end;

	//resize bitmaps
	c_circle_mask.width := f_diameter;
	c_circle_mask.height:= f_diameter;

	c_circle_coloured.width := f_diameter;
	c_circle_coloured.height:= f_diameter;

	c_scratch.width := f_diameter;
	c_scratch.height:= f_diameter;

	c_inverted_mask.width := f_diameter;
	c_inverted_mask.height:= f_diameter;

	//redraw the mask
	with c_circle_mask.canvas do
	begin
		brush.color := clwhite;
		brush.style := bsSolid;
		pen.color := clwhite;
		fillrect(c_circle_rect);

		pen.color := clblack;
		brush.color := clblack;
		ellipse(0,0,f_diameter, f_diameter);
	end;

end;

//*****************************************************************
procedure TBallRackSpinner.draw_onto(poCanvas: TCanvas; piX,piY:integer);
var
  spoke_angle, next_spoke_angle :real;
  angle1,angle2,angle3, deflection: real;
  spoke_triangle: array[1..3] of tpoint;
  spoke: integer;
  half_diameter: integer;
begin
	half_diameter := f_Diameter div 2;

  {-----------------animated ball doesnt sit in one spot, its centre keeps tumbling---------}
  angle1 := c_rotation_angle;
  angle2 := 2.0* c_rotation_angle;
  angle3 := 1.5* c_rotation_angle;

  deflection :=  (the_sine(angle1) + the_cos(angle2) + the_sine(angle3)) /3.0;

  spoke_triangle[1].x := half_diameter + round(  the_cos(angle1) * half_diameter * deflection  );
  spoke_triangle[1].y := half_diameter + round(  the_sine(angle1) * half_diameter * deflection	);

  //-----------------draw 5 spoked ball centred on cx,cy-----
  //---------------each spoke has a triangular area ---------
  spoke_angle := c_rotation_angle;
  spoke_triangle[2].x := spoke_triangle[1].x + round(f_Diameter * the_cos(spoke_angle));
  spoke_triangle[2].y := spoke_triangle[1].y + round(f_Diameter * the_sine(spoke_angle));

  for spoke:=0 to 4 do
  begin
	 {- - - - - END POINT OF SPOKE - - - - - - - - - - - - - - - - -}
	 next_spoke_angle := spoke_angle + 72;
	 spoke_triangle[3].x := spoke_triangle[1].x+ round(  f_Diameter * the_cos(next_spoke_angle)  );
	 spoke_triangle[3].y := spoke_triangle[1].y + round(  f_Diameter * the_sine(next_spoke_angle)	);

	 {- - - - - DRAW A POLYGON- - - - - - - - - - - - - - - - - -}
	 with c_circle_coloured.canvas do
	 begin
		brush.style := bsSolid;
		brush.color := lottery_ball_colour( 1+ 10*spoke);
		pen.color := brush.color;

		PolyGon( spoke_triangle);
	 end;

	 {- - STARTING OPINT FOR NEXT POLYGON IS CURRENT POINT - - -}
	 spoke_triangle[2] := spoke_triangle[3];
	 spoke_angle := next_spoke_angle;
  end;

  //**1** ----------------- draw from coloured circle into masked area 
  with c_scratch.canvas do
  begin
	 {- - - - - - - - - copy mask to scratch area- - - - - - - - - - - - - -}
	 copymode := cmSrcCopy;
	 draw(0,0,c_circle_mask);

	 {- - - - - - - - - merge coloured ball - - - - -}
	 copymode := cmSrcPaint;
	 copyrect(c_circle_rect, c_circle_coloured.canvas, c_circle_rect);
  end;

  {- - - - - - -copy masked image onto offscreenbitmap- - - - - - - - -}
  with poCanvas do
  begin
	 copymode := cmSrcCopy;
	 draw(piX,piY,c_scratch);
  end;

  //**2** ----------------- draw the background into the inverse of the mask
  with c_scratch.canvas do
  begin
	 {- - - - - - - copy mask again - - - - - - - - - - - - - -}
	 copymode := cmSrcCopy;
	 draw(0,0,c_circle_mask);

	 {- - - - - - - invert mask - - - - - - - - - - - - - -}
	 copymode := cmPatInvert;
	 draw(0,0,c_circle_mask);
  end;

  {- - - - - - - - draw background - - - }
  with c_circle_coloured.canvas do
  begin
	 brush.color := f_colour;
	 fillrect(c_circle_rect);
  end;

  with c_scratch.canvas do
  begin
	 {- - - - - - - - merge rectangle with mask- - - }
	 copymode := cmSrcPaint;
	 draw(0,0,c_circle_coloured);
  end;

  //**3** ----------------- joint the two together and it is complete
  with poCanvas do
  begin
	 {- - - - - - - - merge onto offscreen_bitmp- - - }
	 copymode := cmSrcAnd;
	 draw(piX,piY,c_scratch);
  end;

  {---------------------next time step;---------------------}
  c_rotation_angle := c_rotation_angle +  ANGLE_INCREMENT;
  if (c_rotation_angle >= 360) then c_rotation_angle := 0;
end;


end.
 