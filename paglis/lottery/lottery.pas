unit Lottery;
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
(* $Header: /PAGLIS/lottery/lottery.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//

interface
uses
	winprocs,wintypes,graphics,forms,dialogs,shellapi,sysutils,misclib,
	inifile,classes, progres2, lotnum, lottype;

	{ $X+ }

	function dim_lottery_ball_colour(ball_number:byte):Tcolor;
	function lottery_ball_colour(ball_number:byte):Tcolor; overload;
	function lottery_ball_colour(ball_number:TLottBallType):Tcolor; overload;
	function lottery_ball(ball_number:byte):TLottBallType;

	procedure load_number_data;
	procedure free_number_data;

	procedure set_lottery_progress(control:TProgressBar2);
var
	g_number_data: TLotteryNumbers;


implementation
const
	CL_WHITE = clwhite;
	CL_CYAN = $00FFFF80;		{cyan}
	CL_PINK = $008080FF;		{pink}
	CL_GREEN = $0080FF00;		 {green}
	CL_YELLOW = $0080FFFF;		  {yellow}
	CL_PURPLE = $00F0CAA6;				{purply}
	CL_DIM_WHITE = $00efefe7;		 {cyan}
	CL_DIM_CYAN = $00efefa5;		{cyan}
	CL_DIM_PINK = $00efdeef;		{pink}
	CL_DIM_GREEN = $00deefde;		 {green}
	CL_DIM_YELLOW = $00deefef;		  {yellow}
	CL_DIM_PURPLE = $00deceef;				{purply}

var
	 progressbar : TProgressBar2;



//#######################################################################################
//# func
//#######################################################################################
{-----------------------------------------------------------------}
procedure set_lottery_progress(control:TProgressBar2);
begin
  progressbar := control;
end;

{-----------------------------------------------------------------}
function lottery_ball(ball_number:byte):TLottBallType;
begin
  case (ball_number div 10) of
	0: lottery_ball := Ball_White;
	1: lottery_ball := Ball_Blue;		{cyan}
	2: lottery_ball := Ball_red;		{pink}
	  3: lottery_ball := Ball_Green;		 {green}
	4: lottery_ball := Ball_Yellow;		 {yellow}
  else
	lottery_ball := Ball_Purple;	 {purple}
  end;

  if ball_number = 0 then lottery_ball := ball_purple;
end;

{-----------------------------------------------------------------}
function lottery_ball_colour(ball_number:byte):Tcolor;
begin
	case (ball_number div 10) of
	  0: result := cl_white;
	  1: result := CL_CYAN;		{cyan}
	  2: result := CL_PINK;		{pink}
	3: result := CL_GREEN;		  {green}
	  4: result := CL_YELLOW;		  {yellow}
	else
	result:= CL_PURPLE;			   {purply}
	end;

  if ball_number = 0 then result := CL_PURPLE;
end;

{-----------------------------------------------------------------}
function lottery_ball_colour(ball_number:TLottBallType):Tcolor;
begin
	case ball_number of
		Ball_White: result := CL_WHITE;
		Ball_Flash: result := clFuchsia;
		Ball_red: result := CL_PINK;
		Ball_Blue: result := CL_CYAN;
		Ball_Green: result := CL_GREEN;
		Ball_Yellow: result := CL_YELLOW;
		Ball_black: result := CLblack;
		else
			result := CL_PURPLE;
	end;
end;

{-----------------------------------------------------------------}
function dim_lottery_ball_colour(ball_number:byte):Tcolor;
begin
  case (ball_number div 10) of
	0: dim_lottery_ball_colour := cl_dim_white;			 {white}
	1: dim_lottery_ball_colour := CL_DIM_CYAN;
	2: dim_lottery_ball_colour := CL_DIM_PINK;
	3: dim_lottery_ball_colour := CL_DIM_GREEN;
	4: dim_lottery_ball_colour := CL_DIM_YELLOW;
  else
	dim_lottery_ball_colour:= CL_DIM_PURPLE;
  end;

	if ball_number = 0 then dim_lottery_ball_colour := CL_DIM_PURPLE;
end;

//#######################################################################################
//# io
//#######################################################################################
procedure load_number_data;
begin
  if not assigned(g_number_data) then
  begin
	g_number_data := TLotteryNumbers.Create;
  end;
end;


{*********************************************************************}
procedure free_number_data;
begin
  if assigned(g_number_data) then
  begin
	g_number_data.free;
	  g_number_data := nil;
	end;
end;

//
//####################################################################
(*
	$History: lottery.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/lottery
 * 
 * *****************  Version 3  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/lottery
 * added headers and footers
*)
//####################################################################
//
end.
