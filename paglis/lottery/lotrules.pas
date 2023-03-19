unit Lotrules;
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
(* $Header: /PAGLIS/lottery/lotrules.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//


interface
	uses classes, sysutils;

const
	LOTRUL_MAX_RULES = 30;
type
	TLotteryRulesDate = record
		ruleDate: Tdatetime;
		dayFlags: array[1..7] of boolean;
	end;

	TLotteryRules = class (Tobject)
	private
		f_rules: array [1..LOTRUL_MAX_RULES] of TLotteryRulesDate;
		F_rules_count: integer;
		procedure clear_rules;

	public
		procedure parse_rules( rules: string);
		function get_draw_number( date_string: string): Word;
		function get_draw_number_from_date( draw_date: TdateTime ): word;
		function get_draw_date( draw_num:integer):TdateTime;
		function get_starting_Date: TDateTime;

		constructor Create;
		property Count: integer read F_rules_count;
		property StartingDate: TdateTime read get_starting_Date;
	end;

implementation
uses
	misclib, miscstrings;

{########################################################}
{########################################################}
constructor TLotteryRules.Create;
begin
  clear_rules;
end;


{########################################################}
{########################################################}
procedure TLotteryRules.parse_rules(rules: string);
var
	Split_strings, split_days: Tstringlist;
	rule_index, day_index:integer;
	raw_rule, date_bit, days_bit, day_abbrev:string;
	rule:TLotteryRulesDate ;
begin
	{----------------------------------------------------------------}
	clear_rules;

	{----------------------------------------------------------------}
	Split_strings := g_miscstrings.split (rules, '|');
	for rule_index := 1 to Split_strings.count do
	begin
		rule.dayFlags[1] := false;
		rule.dayFlags[2] := false;
		rule.dayFlags[3] := false;
		rule.dayFlags[4] := false;
		rule.dayFlags[5] := false;
		rule.dayFlags[6] := false;
		rule.dayFlags[7] := false;

		{- - - - - - - - - split rule into date and days - - - - - - - }
		raw_rule := Split_strings.Strings[rule_index-1];
		g_miscstrings.split_string(raw_rule, ':', date_bit, days_bit);
		rule.ruleDate := g_miscstrings.string_to_date(date_bit);

		if days_bit='' then
			begin
				day_index := DayOfWeek(rule.ruleDate);
				rule.dayFlags[day_index] := true;
			end
		else
			begin
				split_days:= g_miscstrings.split (days_bit, ',');
				for day_index := 1 to split_days.count do
				begin
					day_abbrev := split_days.strings[ day_index  -1];

					if day_abbrev =		'mo' then
					begin
						rule.dayFlags[2] := true;
						continue;
					end;
					if day_abbrev =		'tu' then
					begin
						rule.dayFlags[3] := true;
						continue;
					end;
					if day_abbrev =		'we' then
					begin
						rule.dayFlags[4] := true;
						continue;
					end;
					if day_abbrev =		'th' then
					begin
						rule.dayFlags[5] := true;
						continue;
					end;
					if day_abbrev =		'fr' then
					begin
						rule.dayFlags[6] := true;
						continue;
					end;
					if day_abbrev =		'sa' then
					begin
						rule.dayFlags[7] := true;
						continue;
					end;
					if day_abbrev =		'su' then
					begin
						rule.dayFlags[1] := true;
						continue;
					end;
				end;
			split_days.free;
		end;

		{- - - - - - - - - - - save rule - - - - - - - - - - - - - - - }
		f_rules[rule_index] := rule;

	end;

	{----------------------------------------------------------------}
	F_rules_count := Split_strings.count;

	{----------------------------------------------------------------}
	Split_strings.free;
end;

{************************************************************}
function TLotteryRules.get_draw_date( draw_num:integer): Tdatetime;
var
	next_date, out_date:tdatetime;
	rule_index, current_draw, day: integer;
	has_next_date, found: boolean;
	rule:TLotteryRulesDate ;
begin
	rule_index := 1;
  current_draw := 0;
	found := false;
	out_date :=0;
	next_date := 0;

	{----------- outer loop is rules ---------------------------}
	while not found do
	begin
		{---------------------------------------------------------}
		rule :=  f_rules[rule_index];

		{---------------------------------------------------------}
		has_next_date := (rule_index < F_rules_count);
		if (has_next_date) then
			next_date := f_rules[ rule_index+1].ruledate;

		{---------------------------------------------------------}
		out_date := rule.ruleDate;
		day := dayofweek(  out_date);

		{----------- inner loop is days ---------------------------}
		while true do
		begin
			{- - - - - - - - - - - - - - - - - - - - - - - - - - }
			if (rule.dayFlags[day]) then
			begin
				inc (current_draw);
				if (current_draw = draw_num) then
				begin
					found := true;
					break;
				end;
			end;

			{- - - - - - - - - - - - - - - - - - - - - - - - - - -}
			out_date := out_date  + 1.0;
			inc (day);
			if day=8 then day:=1;
			if has_next_date and (out_date >=  next_date) then break;
		end;

		{---------------------------------------------------------}
		inc (rule_index);
	end;

	result := out_date;

end;


{########################################################}
{########################################################}
procedure TLotteryRules.clear_rules;
var
	rule_index:integer;
	empty_rule : TLotteryRulesDate;
begin
	F_rules_count := 0;

	with empty_rule do
	begin
		ruleDate := 0;
		dayFlags[1] := false;
		dayFlags[2] := false;
		dayFlags[3] := false;
		dayFlags[4] := false;
		dayFlags[5] := false;
		dayFlags[6] := false;
		dayFlags[7] := false;
	end;

	for rule_index :=1 to LOTRUL_MAX_RULES do
		f_rules[rule_index] := empty_rule;
end;

{************************************************************}
function TLotteryRules.get_starting_Date:Tdatetime;
begin
	get_starting_Date := f_rules[1].ruledate;
end;

{************************************************************}
function TLotteryRules.get_draw_number( date_string: string): Word;
var
	draw_date:tdatetime;
begin
	draw_date := strtodate(date_string);
	result :=	get_draw_number_from_date(draw_date);
end;

{************************************************************}
function TLotteryRules.get_draw_number_from_date( draw_date: TdateTime ): word;
var
	the_date, next_date:tdatetime;
	rule_index, current_draw, day: integer;
	has_next_date, found: boolean;
	rule:TLotteryRulesDate ;
begin
	rule_index := 1;
  current_draw := 0;
	found := false;
	next_date :=0; 

	{----------- outer loop is rules ---------------------------}
	while not found do
	begin
		{---------------------------------------------------------}
		rule :=  f_rules[rule_index];

		{---------------------------------------------------------}
		has_next_date := (rule_index < count);
		if (has_next_date) then
			next_date := f_rules[ rule_index+1].ruledate;

		{---------------------------------------------------------}
		the_date := rule.ruleDate;
		day := dayofweek(  the_date);

		{----------- inner loop is days ---------------------------}
		while true do
		begin
			{- - - - - - - - - - - - - - - - - - - - - - - - - - }
			if (rule.dayFlags[day]) then
			begin
				inc (current_draw);
				if (draw_date <= the_date) then
				begin
					found := true;
					break;
				end;
			end;

			{- - - - - - - - - - - - - - - - - - - - - - - - - - -}
			the_date := the_date  + 1.0;
			inc (day);
			if day=8 then day:=1;
			if has_next_date and (the_date >=  next_date) then break;
		end;

		{---------------------------------------------------------}
	inc (rule_index);
	end;

	//---------- return the last draw on or before the date
	result := current_draw;
end;

//
//####################################################################
(*
	$History: lotrules.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/lottery
 * 
 * *****************  Version 6  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/lottery
 * added headers and footers
*)
//####################################################################
//
end.

