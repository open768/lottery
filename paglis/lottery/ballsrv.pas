unit BallSrv;

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
(* $Header: /PAGLIS/lottery/ballsrv.pas 2     21/02/05 18:47 Sunil $ *)
//****************************************************************
//

interface
 uses lottype,misclib, lottpref, intlist;

type
	TBallServer = class
	private
		M_sorted_balls : Tintlist;
		M_active_balls: Tintlist;
		M_n_available: byte;
		m_reset_before_get_ball: boolean;

		m_current_ball: byte;

		F_Drop_style: TLotteryDropStyle;
		f_start_at_zero: boolean;
		f_columns: byte;
		f_max_number: byte;

		procedure set_drop_style(value: TLotteryDropStyle);
		procedure set_start_at_zero(value: Boolean);
		procedure set_columns(value:byte);
		procedure set_max_number(value:byte);

		procedure p_sort_random(start_ball:byte);
		procedure P_sort_highestFirst(start_ball:byte);
		procedure p_sort_columns(start_ball:byte);
		procedure p_sort_columnsSnake(start_ball:byte);
		procedure p_sort_normal(start_ball:byte);
	public
		procedure init_from_prefs(prefs:TLotteryPrefs);
		procedure init_from_flags(flags: Tintlist);
		function get_ball: integer;
		procedure reset;

		constructor Create;
	destructor destroy; override;

		property DropStyle: TLotteryDropStyle read F_Drop_style write set_drop_style;
		property StartAtZero: Boolean read f_start_at_zero write set_start_at_zero;
		property Columns: Byte read f_columns write set_columns;
		property MaxNumber: byte read f_max_number write set_max_number;
	end;

implementation

{##################################################################}
{#																						#}
{##################################################################}
constructor TBallServer.Create;
begin
	F_Drop_style:= ldsNormal;
	f_start_at_zero:=false;
	f_max_number := MAX_UK_LOTTERY_NUM;
	f_columns := 5;
	M_active_balls := tINtlist.create;
	M_active_balls.noExceptionOnGetError := true;
	M_sorted_balls := tINtlist.create;
	M_sorted_balls.noExceptionOnGetError := true;

	m_reset_before_get_ball := true;
end;

destructor TBallServer.destroy;
begin
	M_active_balls.free;
	M_sorted_balls.free;
  inherited destroy;
end;

{##################################################################}
{#																						#}
{##################################################################}
procedure  TBallServer.init_from_prefs(prefs:TLotteryPrefs);
begin
	with prefs do
	begin
		f_max_number := highest_ball;
		f_columns := columns;
		M_active_balls.free;
		M_active_balls := currentInPlay.clone;
		f_start_at_zero := start_at_zero;
		F_Drop_style := TLotteryDropStyle(drop_style);
	end;
	m_reset_before_get_ball := true;
end;

{********************************************************************}
procedure TBallServer.init_from_flags(flags: Tintlist);
begin
	M_active_balls.free;
	M_active_balls := flags.clone;
	m_reset_before_get_ball := true;
end;

{********************************************************************}
function  TBallServer.get_ball:integer;
begin
	if m_reset_before_get_ball then
	begin
		reset;
		m_reset_before_get_ball := false;
	end;

	{--------------------- --------------------------}
	if  M_n_available <=0 then
	begin
		get_ball := -1;
		exit;
	end;

	{--------------------- --------------------------}
	get_ball := M_sorted_balls.bytevalue[m_current_ball];
	inc(m_current_ball);
	dec(M_n_available);

end;

{********************************************************************}
procedure TBallServer.reset;
var
	start_ball: byte;
begin
	if f_start_at_zero then
		start_ball := 0
	else
		start_ball := 1;


	m_sorted_Balls.clear;

	case F_Drop_style of
		ldsRandom:				p_sort_random(start_ball);
		ldsHighestFirst:		P_sort_highestFirst(start_ball);
		ldsColumns:			p_sort_columns(start_ball);
		ldsColumnsSnake:		p_sort_columnsSnake(start_ball);
		else						p_sort_normal(start_ball);
	end;

	m_current_ball :=0;
end;

{##################################################################}
{#																						#}
{##################################################################}
procedure TBallServer.set_drop_style(value: TLotteryDropStyle);
begin
	if ( value <> F_Drop_style) then
	begin
		F_Drop_style := value;
		m_reset_before_get_ball := true;
	end;
end;

{********************************************************************}
procedure TBallServer.set_start_at_zero(value: Boolean);
begin
	if ( value <> f_start_at_zero) then
	begin
		f_start_at_zero := value;
		m_reset_before_get_ball := true;
	end;
end;

{********************************************************************}
procedure TBallServer.set_columns(value:byte);
begin
	if ( value <> f_columns) then
	begin
		f_columns := value;
		m_reset_before_get_ball := true;
	end;
end;

{********************************************************************}
procedure TBallServer.set_max_number(value:byte);
begin
	if ( value <> f_max_number) then
	begin
		f_max_number := value;
		m_reset_before_get_ball := true;
	end;
end;

{##################################################################}
{#																						#}
{##################################################################}
procedure TBallServer.P_sort_highestFirst(start_ball:byte);
var
	index:byte;
begin
	M_n_available := 0;
	for index := f_max_number downto start_ball do
		if M_active_balls.boolvalue[index] then
		begin
			m_sorted_balls.bytevalue[ M_n_available] := index;
			inc(M_n_available);
		end;
end;

{********************************************************************}
procedure TBallServer.p_sort_normal(start_ball:byte);
var
	index:byte;
begin
	M_n_available := 0;
	for index := start_ball to f_max_number do
		if M_active_balls.boolvalue[index] then
		begin
			m_sorted_balls.bytevalue[ M_n_available] := index;
			inc(M_n_available);
		end;
end;

{********************************************************************}
procedure TBallServer.p_sort_random(start_ball:byte);
var
	index, ball_index: byte;
	active_index: word;
	n_active, active_counter: byte;
	active_copy: Tintlist;
begin
	randomize;
	M_n_available := 0;
	active_copy:= m_active_balls.clone;

	{---------------- how many are actually active --------}
	n_active := 0;
	for index := start_ball to f_max_number do
		if active_copy.boolvalue[index] then
			inc(n_active);

	{-------- for each active ball---- now generate a random sequence -----------}
	for index := n_active downto 1 do
	begin
		active_index := random(index-1) +1;
		{- - - -	find active ball and mark - - - -}

		active_counter := 0;
		for ball_index := start_ball to f_max_number do
			if active_copy.boolvalue[ball_index]  then
			begin
				inc(active_counter);
				if active_counter = active_index then
				begin
					active_copy.boolvalue[ball_index] := false;
					m_sorted_balls.bytevalue[ M_n_available] := ball_index;
					inc(M_n_available);
				end;
			end;
	end;

	active_copy.free;
	M_n_available := M_n_available;


end;

{********************************************************************}
procedure TBallServer.p_sort_columns(start_ball:byte);
var
	ball_index:byte;
	n_balls, rows, row, col, increment:integer;
begin
	M_n_available := 0;

	{---------- calculate rows -------------------------}
	n_balls := (f_max_number - start_ball) +1;
	rows :=  n_balls div f_columns;
	if n_balls mod f_columns <> 0 then inc(rows);

	{---------- columns -------------------------}
	for col := 0 to f_columns-1 do
		for row := rows-1 downto 0 do
		begin
			increment := ( row * f_columns) + col;
			ball_index := start_ball + increment;
			if (ball_index >=start_ball) and (ball_index <=f_max_number) then
				if M_active_balls.boolvalue[ball_index] then
		 begin
					m_sorted_balls.bytevalue[ M_n_available] := ball_index;
					inc(M_n_available);
				end;
		end;
end;

{********************************************************************}
procedure TBallServer.p_sort_columnsSnake(start_ball:byte);
var
	ball_index:byte;
	n_balls, rows, actual_row, row, col, increment, direction:integer;
begin
	M_n_available := 0;

	{---------- calculate rows -------------------------}
	n_balls := (f_max_number - start_ball) +1;
	rows :=  n_balls div f_columns;
	if n_balls mod f_columns <> 0 then inc(rows);
	direction := -1;

	{---------- snake -------------------------}
	for col := 0 to f_columns-1 do
	begin
		for row := rows-1 downto 0 do
		begin
			if direction = 1 then
				actual_row := rows - row -1
			else
				actual_row := row;

			increment := ( actual_row * f_columns) + col;
			ball_index := start_ball + increment;
			if (ball_index >=start_ball) and (ball_index <=f_max_number) then
				if M_active_balls.boolvalue[ball_index] then
				begin
					m_sorted_balls.bytevalue[ M_n_available] := ball_index;
					inc(M_n_available);
				end;
		end;

		{- - - - - reverse direction each column - - - - - - }
		direction := -direction;
	end;
end;

//
//####################################################################
(*
	$History: ballsrv.pas $
 * 
 * *****************  Version 2  *****************
 * User: Sunil        Date: 21/02/05   Time: 18:47
 * Updated in $/PAGLIS/lottery
 * memory leak removed
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

