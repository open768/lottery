unit Numball;

interface

uses
	{$IFDEF WIN32}
	Math,
	{$ENDIF}
	SysUtils, WinTypes, WinProcs, Messages, Classes,  Graphics, Controls,
	Forms, vectors, Misclib, simplray;

type

	TNumberBallStyle = ( nbsPlain,	nbsLottery,	nbsLottery2,nbsLottery3,nbsShaded,nbsTiled,nbsSnooker);

	mapping_array = array[0..0] of word;
	P_mapping_array = ^mapping_array;

	TNumberBall = class(TCustomControl)
	private
		{ Private declarations }
		F_background: Tcolor;
		F_ball_colour: Tcolor;
		F_text_colour: Tcolor;
		F_text_border: byte;
		F_number: Byte;
		F_style: TNumberBallStyle;
		font_bitmap: Tbitmap;
		offscreen_bitmap: Tbitmap;
		F_working: Boolean;
		painted_on_screen: Boolean;


		normal_vec:TVector;
		pole_vec:TVector;
		equator_vec:TVector;
		pole_cross_equator_vec:TVector;
    vec_Funcs: TVectorFunctions;

    procedure set_background(value:Tcolor);
    procedure set_ball_colour(value:Tcolor);
    procedure set_text_colour(value:Tcolor);
    procedure set_text_border(value:byte);
    procedure set_style(value: TNumberBallStyle);
    procedure set_number(value:Byte);

		procedure set_the_colour;
		procedure draw_ball;
    procedure draw_offscreen_text;
    //procedure map_sphere_to_uv(point_vec:Vector; var u,v:real);

    procedure wrap_text;
    procedure wrap_text2;
    procedure wrap_text3;
    procedure tile_text;
    procedure draw_plain_ball;
    procedure draw_shaded_ball;
    procedure draw_simple_ball;
    procedure centre_text;
  protected
    { Protected declarations }
    procedure Paint; override;
  public
    { Public declarations }
    constructor Create (AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  published
    { Published declarations }
    property Background: Tcolor
        read F_background write set_background;
    property BallColor: Tcolor
        read F_ball_colour write set_ball_colour;
    property TextColor: Tcolor
        read F_text_colour write set_text_colour;
    property Style: TNumberBallStyle
        read F_style write set_style;
    property TextBorder: Byte
        read F_text_border write set_text_border;
    property Value: Byte
        read F_number write set_number;
    property Working: Boolean
        read F_working;

  end;

procedure Register;

implementation
const
	DEFAULT_COLOUR = clwhite;
	DEFAULT_BGCOLOUR = clLTgray;
	DEFAULT_TEXT_COLOUR = clblack;
	DEFAULT_NUMBER = 1;
	DEFAULT_STYLE = nbsLottery3;
	DEFAULT_TEXT_BORDER=6;
	MASK_COLOUR =1;
	COS45 = 0.70711;
	MAX_LOTTERY_NUM = 49;
	MAX_SNOOKER_NUM = 7;




{##################################################################
        STANDARD STUFF
##################################################################}
procedure Register;
begin
  RegisterComponents('Paglis', [TNumberBall]);
end;

{##################################################################
        PRIVATE
##################################################################}

{******************************************************************
******************************************************************}
procedure TNumberBall.set_style(value:TNumberBallStyle);
begin
  if (value <> F_style) and (not F_working) then
  begin

    F_style := value;

    {-----------ensure that colours and values are correct for style---}
    set_the_colour;
    case F_style of
        nbsLottery,
        nbsLottery2,
        nbsLottery3:
              if (F_number> MAX_LOTTERY_NUM) then
                F_number := MAX_LOTTERY_NUM;

        nbsSnooker:
              if (F_number> MAX_SNOOKER_NUM) then
                F_number := MAX_SNOOKER_NUM;
    end;

    {-------------------draw the damn thing------------------------}
    draw_ball;
  end;
end;

{******************************************************************
******************************************************************}
procedure TNumberBall.set_text_colour(value:Tcolor);
begin
  if (value <> F_text_colour) and (not F_working) then
  begin
    F_text_colour := value;
    draw_ball;
  end;
end;

{******************************************************************
******************************************************************}
procedure TNumberBall.set_background(value:Tcolor);
begin
  if (value <> F_background) and (not F_working) then
  begin
    F_background := value;
    draw_ball;
  end;
end;

{******************************************************************
******************************************************************}
procedure TNumberBall.set_ball_colour(value:Tcolor);
begin
  if (value <> F_Ball_colour) and (not F_working) then
  begin
    if (F_style <> nbsLottery) and
       (F_style<> nbsLottery2) and
       (F_style<> nbsSnooker) then
    begin
      F_Ball_colour := value;
      draw_ball;
    end;
  end;
end;

{******************************************************************
******************************************************************}
procedure TNumberBall.set_number(value:Byte);
begin
  if (value <> F_number) and (not F_working) then
  begin
    {--------check number is in range and set colours as apropriate----}
    case F_style of
      nbsLottery,
      nbsLottery2,
      nbsLottery3:
        if (value =0) or (value > MAX_LOTTERY_NUM) then
          exit;
      nbsSnooker:
        if (value =0) or (value > MAX_SNOOKER_NUM) then
          exit;
    end;
    F_number := value;
    set_the_colour;
    draw_ball;
  end;
end;

{******************************************************************
******************************************************************}
procedure TNumberBall.set_text_border(value:Byte);
begin
  if (value >0) and (value <> F_text_border) and (not F_working) then
  begin
    F_text_border := value;
    draw_ball;
  end;
end;

{##################################################################
        PROTECTED
##################################################################}

{******************************************************************
******************************************************************}
procedure TNumberBall.Paint;
begin
  if not painted_on_screen then
  begin
    painted_on_screen := true;
    draw_ball;
  end;

  canvas.draw(0,0,offscreen_bitmap);
end;

{##################################################################
        PRIVATE
##################################################################}
{******************************************************************
******************************************************************}
procedure TNumberBall.draw_ball;
begin
  if (not F_working) and (painted_on_screen) then
  begin
     F_working := true;

     {--------------------blank offscreen_bitmap-------------}
     with offscreen_bitmap.canvas do
     begin
       copymode := cmblackness;
       copyrect(clientrect,offscreen_bitmap.canvas,clientrect);
     end;

     {-------------draw it (will vary upon style selected)-----}
     draw_offscreen_text;
     case F_style of
           nbsPlain: draw_plain_ball;
         nbsLottery: wrap_text;
        nbsLottery2: wrap_text2;
        nbsLottery3: wrap_text3;
				 nbsShaded: draw_shaded_ball;
				  nbsTiled: tile_text;
         nbsSnooker: draw_plain_ball;
     end;

     {----force screen image to be updated----------------------}
     Invalidate;
     F_working := false;
 end;
end;

{******************************************************************
Draw the text onto the offscreen bitmap .

only fillrect retains the colour originally chosen. All others
fill rectangle with nearest solid colour.

textout also appears to draw a rectangle, but doest use fillrect
so on low colour displays get horrid outout. only way around this
is to use yet another bitmap and do bitmap ops to combine
 
******************************************************************}
procedure TNumberBall.draw_offscreen_text;
var
  text_width, text_height: integer;
  the_string: string;
  the_rect: Trect;
  textout_bitmap:Tbitmap;
begin
  the_string := inttostr(F_number);

  {text out seems to draw a rectangle first, dont want that
    so some natty bitmap manipulating routines sort it out}
  textout_bitmap := Tbitmap.create;

  {--figure out how wide the font bitmap should be----------------}
  with font_bitmap.canvas do
  begin
     text_width := textwidth(the_string);
     text_height:= textheight(the_string);
     font.color := F_text_colour;
  end;

  with font_bitmap do
  begin
    width := text_width + (F_text_border *2);
    height := text_height + (F_text_border *2);
    textout_bitmap.width := width;
    textout_bitmap.height := height;

    the_rect := rect(0,0,width,height)
  end;

  {--------------fill font bitmap with colour -------------------}
  with font_bitmap.canvas do
  begin
     brush.color := F_ball_colour;
     fillrect(the_rect);
  end;

  {--------------draw text onto temp bitmap--------------------}
  with textout_bitmap.canvas do
  begin
     brush.color := clwhite;
     font.color:= clblack;
     fillrect(rect(0,0,width,height));
     textout(F_text_border,F_text_border,the_string);
  end;

  {--------------combine both bitmaps------------------------}
  with font_bitmap.canvas do
  begin
    copymode := cmsrcand;
    copyrect( the_rect,textout_bitmap.canvas,the_rect);
  end;



  {--------------done with temp bitmap--------------------}
  textout_bitmap.free;

end;

{******************************************************************
******************************************************************}
procedure TNumberBall.set_the_colour;
begin
    case F_style of
		  nbsLottery,nbsLottery2:
          case (F_number div 10) of
              0: F_ball_colour := clwhite;
              1: F_ball_colour := $00FFFF80;        {cyan}
              2: F_ball_colour := $008080FF;        {pink}
              3: F_ball_colour := $0080FF00;        {green}
              4: F_ball_colour := $0080FFFF;        {yellow}
          end;

      nbsSnooker:
          case (value) of
              1: F_ball_colour := clred;
              2: F_ball_colour := clyellow;
              3: F_ball_colour := clgreen;
              4: F_ball_colour := $00004080;          {brown}
              5: F_ball_colour := clblue;
              6: F_ball_colour := $008080FF;          {pink}
              7: F_ball_colour := clblack;
          end
    end;
end;

{##################################################################
        drawing styles
##################################################################}
{******************************************************************
  want text to appear in center of ball,assume ball is drawn
******************************************************************}
procedure TNumberBall.centre_text;
var
  text_rect,dest_rect:Trect;
  radius,the_width,the_height:integer;
  circle_radius:integer;
  the_string: string;
begin
  the_string := inttostr(F_number);

  {--figure out how wide the font bitmap should be----------------}
  with font_bitmap.canvas do
  begin
     the_width :=  font_bitmap.width;
     the_height:=  font_bitmap.height;

     {------------------blank text bitmap-----------------------}
     copymode := cmblackness;
     text_rect := rect(0,0,the_width,the_height);
     copyrect(text_rect,font_bitmap.canvas,text_rect);

     {--------------draw text in white on black-----------------}
     brush.color:= clblack;
     font.color := clwhite;
     textout(F_text_border,F_text_border,the_string);
  end;


  {----------combine both bitmaps using XOR--------------------}
  radius := offscreen_bitmap.width div 2;
  dest_rect :=
    rect(
      radius - (the_width div 2),radius - (the_height div 2),
      radius + (the_width div 2),radius + (the_height div 2)
    );

  {----------draw a circle big enough to hold text-------------}
  circle_radius := round(sqrt(the_width*the_width + the_height*the_height)/4.0)+5;

  with offscreen_bitmap.canvas do
  begin
    ellipse(
      radius-circle_radius,radius-circle_radius,
      radius+circle_radius,radius+circle_radius);

    copymode := cmsrcinvert;
    copyrect( dest_rect,font_bitmap.canvas,text_rect);
  end;

end;


{******************************************************************
******************************************************************}
procedure TNumberBall.draw_simple_ball;
begin
  {-------blank out the background and draw mask ellipse---------}
  with offscreen_bitmap.canvas do
  begin
    brush.color := F_background;
    fillrect(rect(0,0,width,height));
    brush.color := F_ball_colour;
    pen.color := F_ball_colour;
    ellipse(0,0,width,height);
  end;

end;

{******************************************************************
******************************************************************}
procedure TNumberBall.draw_plain_ball;
begin
  draw_simple_ball;
  centre_text;
end;

{******************************************************************
 with a bit of common sense this should be easy.
 looking at a sphere from top so make use of geometry

 filling a rectangle with a non solid colour will result in dithering.
 so mapping those onto a sphere results in nasty moire patterns.
 Also drawing pixels is slow even to a background image, the less that
 can be drawn the better.

 to optimise the distortion matrix should be calculated only when
 the size of the ball changes. At the moment this recalculates the
 ball whenever something changes.

 the arctan could possibly be removed by using TVector arithmetic.  
******************************************************************}
procedure TNumberBall.wrap_text;
var
  text_width,text_height,r,l: word;
  dx,dy,dx2,dy2,y_lim,x_lim,x,y,x2,y2:word;
  xx,yy,rr: word;
  map_x,map_x2,map_y, orig_x: word;
  mapping :P_mapping_array;
  latitude,longitude:word;

  quadrant:byte;
  dx_quad,dy_quad,x_quad,y_quad:word;
  dx2_quad,dy2_quad,x2_quad,y2_quad:word;
  src_rect,dest_rect : Trect;
begin

  {-------------------various calculations-------------}
  text_width:= font_bitmap.width;
  text_height:= font_bitmap.height;
  r := (width-1) div 2;
  rr := r*r;

  {-------blank out the background and draw mask ellipse---------}
  draw_simple_ball;

  {---------precalculate mapping--------------------}
  mapping := allocmem((r+1) * sizeof(word));
  for l:=0 to r do
    mapping^[l] := round(sqrt (rr - (l*l)));

  {--work on one octant of the circle, map results-----}
  y_lim := round(r * COS(pi/4));
  y:=r;
  for dy:=0 to y_lim do
  begin
    application.processmessages;
    x_lim := round(sqrt( rr - dy*dy));
    x:= y;
    yy := dy*dy;
    for dx:= dy to x_lim do
    begin
      {---I've checked and we are definately in the octant--------}
      xx := dx*dx;
      longitude := mapping^[round(sqrt(yy+xx))];
      if dx = 0 then
        latitude := 90
      else
        latitude := round(arctan(dy/dx) *(180 / PI));

      {-------map onto font bitmap---------------------------------}
      map_x := latitude mod text_width;
      map_y := longitude mod text_height;

      if font_bitmap.canvas.pixels[map_x,map_y] = F_text_colour then
          offscreen_bitmap.canvas.pixels[x,y]:=
                font_bitmap.canvas.pixels[map_x,map_y];

      {---------------symettry to map onto octant 2----------------}
      dx2 := dy;
      dy2 := dx;
      map_x2 := (90 - latitude)  mod text_width;
      x2:= r-dx2;
      y2:= r-dy2;
      if font_bitmap.canvas.pixels[map_x2,map_y] = F_text_colour then
        offscreen_bitmap.canvas.pixels[x2,y2]:=
                font_bitmap.canvas.pixels[map_x2,map_y];

      {------use symmettry to map onto 3 other quadrants-------------}
      for quadrant := 2 to 4 do
      begin
        map_x := (map_x + 90) mod text_width;
        map_x2 := (map_x2 + 90) mod text_width;
        case quadrant of
          2: begin
               dx_quad:= dy; dy_quad:=-dx;
               dx2_quad:= dy2; dy2_quad:=-dx2;
             end;
          3: begin
               dx_quad:= dx; dy_quad:= dy;
               dx2_quad:= dx2; dy2_quad:= dy2;
             end;
          4: begin
               dx_quad:=-dy; dy_quad:= dx;
               dx2_quad:=-dy2; dy2_quad:= dx2;
             end;
        end;

        x_quad:= r+dx_quad; y_quad:= r+dy_quad;
        x2_quad:= r+dx2_quad; y2_quad:= r+dy2_quad;

        if font_bitmap.canvas.pixels[map_x,map_y] = F_text_colour then
           offscreen_bitmap.canvas.pixels[x_quad,y_quad]:=
                        font_bitmap.canvas.pixels[map_x,map_y];

        if font_bitmap.canvas.pixels[map_x2,map_y] = F_text_colour then
          offscreen_bitmap.canvas.pixels[x2_quad,y2_quad]:=
                        font_bitmap.canvas.pixels[map_x2,map_y];
      end;


      {--------------------------ok next x------------------------}
      dec(x);
    end;
    dec(y);
  end;

  {------no longer need precalculated mapping------------------}
  freemem(mapping, (r+1) * sizeof(word));

  {------------------put number in center of ball------------------}
  centre_text;

end;

{******************************************************************
 wrap text looked at a ball from above, there is an even simpler
 way if the ball is viewed from infront
******************************************************************}
procedure TNumberBall.wrap_text2;
var
  text_width,text_height,r,rr,r2: word;
  half_text_width,half_text_height: word;
  dx,dy,x,xlim:integer;
	map_x,map_y: integer;
  mapping :P_mapping_array;
  the_pixel:Tcolor;
begin

  {-------------------various calculations-------------}
  text_width:= font_bitmap.width;
  text_height:= font_bitmap.height;
  half_text_width:= text_width div 2;
  half_text_height:= text_height div 2;
  r := (width-1) div 2;
  rr := r*r;
  r2 := 2*r;

  {-------blank out the background and draw mask ellipse---------}
  draw_simple_ball;

  {---------precalculate mapping--------------------}
  mapping := allocmem((r+1) * sizeof(word));
  for x:=0 to r do
    mapping^[x] := round(sqrt (rr - (x*x)));


  {--for each column, ---------------------------------------}
  for dy:=-r to r do
  begin

    {-------x will have this limit -------------------------}
    xlim := mapping^[abs(dy)];

    {-------work out y mapping -----------------------------}
    if dy>0 then
      map_y := (r2- xlim) mod text_height
    else
      map_y :=  xlim mod text_height;
    map_y := (map_y + half_text_height) mod text_height;

    {-------each row in the limits -------------------------}
    for dx:=-xlim to xlim do
    begin
      {--------work out x mapping --------------------------}
      if dx > 0 then
        map_x := (r2- mapping^[abs(dx)]) mod text_width
      else
        map_x := mapping^[abs(dx)] mod text_width;
      map_x := (map_x + half_text_width) mod text_width;

      {--------only copy the pixels from the text of the number--}
      the_pixel := font_bitmap.canvas.pixels[map_x,map_y];
      if the_pixel= F_text_colour then
        offscreen_bitmap.canvas.pixels[r+dx,r+dy]:= the_pixel;
    end;
  end;


  {------no longer need precalculated mapping------------------}
  freemem(mapping, (r+1) * sizeof(word));

  {------------------put number in center of ball------------------}
  centre_text;

end;

{******************************************************************
raytracing technology to wrao text onto the ball convincingly
******************************************************************}
procedure TNumberBall.wrap_text3;
var
	r,rr: word;
	dx,dy,x,xlim:integer;
	mapping :P_mapping_array;
begin

	{-------------------various calculations-------------}
	r := (width-1) div 2;
  rr := r*r;

  {-------blank out the background and draw mask ellipse---------}
  draw_simple_ball;

  {---------precalculate mapping--------------------}
  mapping := allocmem((r+1) * sizeof(word));
  for x:=0 to r do
    mapping^[x] := round(sqrt (rr - (x*x)));


  {--for each column, ---------------------------------------}
	for dy:=-r to r do
  begin

    {-------x will have this limit -------------------------}
    xlim := mapping^[abs(dy)];

    {-------each row in the limits -------------------------}
    for dx:=-xlim to xlim do
    begin
    end;
  end;


  {------no longer need precalculated mapping------------------}
  freemem(mapping, (r+1) * sizeof(word));

  {------------------put number in center of ball------------------}
  centre_text;
end;

{******************************************************************
******************************************************************}
procedure TNumberBall.draw_shaded_ball;
var
  r,rr: word;
  mapping :P_mapping_array;
  x,y,z,zlim:integer;
  sphere: SphereObj;
  ray: RayObj;
  t: real;
  intersect : Tvector;
begin

  {-------------------various calculations-------------}
  r := (width-1) div 2;
  rr := r*r;

  {-------sphere and ray direction will never change ------------}
  sphere := create_sphere(0.0, 0.0, 0.0, r);
  ray.direction := vec_funcs.new_vector(-1.0, 0.0, 0.0);


  {-------blank out the background and draw mask ellipse---------}
  draw_simple_ball;

  {---------precalculate mapping--------------------}
  mapping := allocmem((r+1) * sizeof(word));
  for x:=0 to r do
    mapping^[x] := round(sqrt (rr - (x*x)));


  {--for pixel in the y plane, ---------------------------------------}
  for y:=-r to r do
  begin

    {-------only interested in pixels in the circle--------}
    zlim := mapping^[abs(y)];
    for z:=-zlim to zlim do
    begin
        {-------start of ray well beyond circle in +ve x direction----}
        ray.base := vec_funcs.new_vector(rr,y,z);

        {--------where does ray intersect sphere-----------------}
        t:= compute_t_for_sphere(sphere,ray);
        if t > 0.0 then
        begin
          intersect := project_ray(ray,t)
        end;
    end;
  end;


  {------no longer need precalculated mapping------------------}
  freemem(mapping, (r+1) * sizeof(word));

end;

{******************************************************************
******************************************************************}
procedure TNumberBall.tile_text;
var
	temp_bitmap: TBitmap;
	text_width, text_height, x,y:integer;
begin
  {-----------need another offscreen bitmap----------------}
  temp_bitmap:= Tbitmap.create;
  temp_bitmap.width := width;
  temp_bitmap.height := height;

  {-----------init----------------}
  text_width := font_bitmap.width;
  text_height := font_bitmap.height;

  {-----------tile text onto temp bitmap-------------------}
  x:= 0;
  while x < width do
  begin
    y:=0;
    while y < height do
    begin
      temp_bitmap.canvas.draw(x,y,font_bitmap);
      y:= y+ text_height;
    end;
    x:= x+ text_width;
  end;

  {---copy text bitmap into circular region on offscreen bitmap--} 
  with offscreen_bitmap.canvas do
  begin
    {- - - - - - - - - -clear bitmap- - - - - - - - - - - -  -}
    copymode := cmblackness;
    copyrect(clientrect, offscreen_bitmap.canvas, clientrect);

    {- - - - - - -white circle mask - - - - - - - - - - - - - }
    pen.color := clwhite;
    brush.color:= clwhite;
    ellipse(0,0,width,height);

    {- - - - -copy text bitmap into circle mask- - - - - - - -}
    copymode := cmSrcAnd;
    copyrect(clientrect, temp_bitmap.canvas, clientrect);
  end;

  {---fill temp bitmap with background color and draw a circle--}
  with temp_bitmap.canvas do
  begin
    brush.color:= F_background;
    fillrect(rect(0,0,width,height));

    pen.color := 0;
    brush.color:= 0;
    ellipse(0,0,width,height);
  end;

  {----merge the 2 bitmaps to get final result--}
  with offscreen_bitmap.canvas do
  begin
    copymode := cmSrcPaint;
    copyrect(clientrect, temp_bitmap.canvas, clientrect);
  end;

  {-------------------finished with temp bitmap-------------}
  temp_bitmap.destroy;
end;


{##################################################################
        PUBLIC
##################################################################}
{******************************************************************
******************************************************************}
constructor TNumberBall.Create (AOwner: TComponent);
begin
  inherited create(Aowner);
  F_number := DEFAULT_NUMBER;
  F_style := DEFAULT_STYLE;
  F_text_border := DEFAULT_TEXT_BORDER;
  F_background := DEFAULT_BGCOLOUR;
  font_bitmap:= Tbitmap.Create;
  offscreen_bitmap:= Tbitmap.Create;
  F_working := true;
	painted_on_screen := false;
	vec_Funcs:= TVectorFunctions.Create;


  {-------vectors needed, create them once for ounces of speed-----}
  normal_vec := vec_funcs.new_vector(0.0,0.0,0.0);
  pole_vec := vec_funcs.new_vector(0.0,0.0,1.0);
  equator_vec := vec_funcs.new_vector(1.0,0.0,0.0);
  pole_cross_equator_vec := vec_funcs.new_vector(1.0,0.0,0.0);
  pole_cross_equator_vec := vec_funcs.cross(pole_vec,equator_vec);
  set_the_colour;
  F_working := false;

  {-------default width and height or in design mode will end up 0 by 0-----}
  width:=50;
  height:=50;

end;

{******************************************************************
******************************************************************}
destructor TNumberBall.Destroy;
begin
	font_bitmap.free;
	offscreen_bitmap.free;
  vec_Funcs.free;
  inherited Destroy;
end;

{******************************************************************
******************************************************************}
procedure TNumberBall.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
var
   old_size, size:integer;
begin

  {--------only interested in balls bounded by a square---------}
  if Awidth > Aheight then
    size := Awidth
  else
    size := Aheight;

  {--------then they must be even numbers------------------------}
  if ((size mod 2) = 1) then
      inc(size);

  {-----------------OK go do it----------------------------------}
  old_size := width;
  inherited SetBounds( ALeft, ATop, size, size);
  if size <> old_size then
  begin
    with  offscreen_bitmap do
    begin
      width := size;
      height := size;
    end;
		draw_ball;
	end
end;

{******************************************************************
modified ALgorithm from
			 Advanced Graphics Programming using C/C++
			 Loren Heiny
			 John Wiley & Sons
			 ISBN 0-471-57159-8
			 Page 124
unfortunately this doesnt work nd Ive found a much better
way of doing it
******************************************************************}
(*
procedure TNumberBall.map_sphere_to_uv(point_vec:Vector; var u,v:real);
var
  latitude, longitude, acos, Temp:real;
begin
  normal_vec := vec_funcs.normal(point_vec);
  latitude := ArcCos (- vec_funcs.dot(normal_vec,pole_vec));

  Temp := vec_funcs.dot(equator_vec,normal_vec) / sin (latitude);
  if temp >1.0 then
    acos := 0.0
  else if temp < -1.0 then
    acos := 180
	else
    acos := arccos(temp);

  longitude :=  acos * 2 * PI;

  {----------------and finally get u,v------------------}
  v := latitude * PI;
  if  vec_funcs.dot(pole_cross_equator_vec, normal_vec) > 0 then
    u:= longitude
  else
    u:= 1.0 - longitude;

end;
*)
end.
