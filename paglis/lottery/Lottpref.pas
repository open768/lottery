unit Lottpref;

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
(* $Header: /PAGLIS/lottery/Lottpref.pas 3     5/06/05 23:33 Sunil $ *)
//****************************************************************
//

interface
uses
	classes, sysutils, misclib, lottery,lottype, lotseq, inifile, intlist, lotcolour;
type

	TLotteryPrefs = class
	private
		f_in_play: Tintlist;
		f_current_in_play: Tintlist;

		procedure pr_set_in_play(value:tintlist);
	public
		f_profile:string;
		highest_ball, select,columns, machine_columns :integer;
		sorted, rendered, random_kick, show_numbers, use_sequences: boolean;
		start_at_zero: boolean;
		keep_picking, remove_picked_balls: boolean;
		mute:boolean;
		drop_style: integer;
		angle: degree;
		sequences : TLotterySequenceList;
		Ball_colors : TLotteryBallColours;

		use_background_images: boolean;
		background_image_folder: string;
		background_speed: integer;

		property prefsInPlay:Tintlist read f_in_play write pr_set_in_play;
		property currentInPlay:Tintlist read f_current_in_play;
		property Profile:string read f_profile;

		procedure save_prefs(psProfile:string);
		procedure load_prefs(psProfile:string);

		procedure reinitialise_current;
		function how_many_in_play: integer;
		function getProfiles: TStringList;
		function CurrentProfile:string;
		constructor create;
		destructor destroy; override;
	end;


implementation
uses
	inisection;
const
	PREFS_VERSION = 2.00;

	VERSION_SECTION = 'Version';
	VERSION_ENTRY = 'lottpref';

	PREFS_SECTION = 'Preferences';
	SELECT_ENTRY = 'Select these many';
	FROM_ENTRY = 'from';
	IN_PLAY_ENTRY='in_play_v2';
	ANGLE_ENTRY = 'release angle';
	HOW_MANY_ENTRY = 'how many';
	SORTED_ENTRY = 'pick sorted';
	RENDERED_ENTRY = 'rendered';
	RANDOM_KICK_ENTRY = 'random_kick';
	DROP_STYLE_ENTRY = 'drop style';
	SHOW_NUMBERS_ENTRY = 'show_numbers';
	COLUMNS_ENTRY = 'display_columns';
	MACHINE_COLUMNS_ENTRY = 'drop_columns';
	ZERO_ENTRY = 'start_at_zero';
	MUTE_ENTRY = 'mute';
	SEQUENCE_ENTRY = 'sequence Count';
	USE_SEQUENCES_ENTRY = 'Use Sequences';
	KEEP_PICKING_ENTRY = 'keep Picking';
	REMOVE_PICKED_ENTRY = 'remove picked';
	BACKGROUND_IMAGE_ENTRY = 'background_image';
	BGIMAGE_FOLDER_ENTRY = 'background_folder';
	BGIMAGE_SPEED_ENTRY = 'background_speed';

	NUMBERS_SECTION = 'Draw Numbers';
	DRAWS_ENTRY = 'Draws';
	SEQUENCE_DELIM = '|';

	SEQUENCE_SECTION = 'Sequences';
	SEQUENCE_NAME = '--DEFAULT--';

	DEFAULT_PROFILE = 'uk';
	INIFILENAME = 'pickerprefs.ini';
	INI_CONFIG_SECTION = 'config';
	INI_PROFILES_SECTION = 'Profiles';
	INI_CURRENTPROFILE = 'profile';

//##############################################################
//* constructor
//##############################################################
constructor TLotteryPrefs.create;
begin
	f_profile := 	CurrentProfile;
	sequences := TLotterySequenceList.create(true);
	f_in_play := Tintlist.create;
	f_current_in_play := Tintlist.create;
	f_in_play.noExceptionOnGetError := true;
	f_current_in_play.noExceptionOnGetError := true;
end;

destructor TLotteryPrefs.destroy;
begin
	if assigned(f_current_in_play) then f_current_in_play.free;
	if assigned(f_in_play) then f_in_play.free;
	if assigned(sequences) then sequences.free;
end;


//##############################################################
//# IO
//##############################################################
procedure TLotteryPrefs.save_prefs(psProfile:string);
var
	numbers_in_play: String;
	ball: integer;
	inifile: tinifile;
	sSection:string;
begin
	inifile := tinifile.create( INIFILENAME);

	//------------- write which section is being used -------------
	inifile.Write(INI_PROFILES_SECTION, psProfile, '1');
	inifile.Write(INI_CONFIG_SECTION, INI_CURRENTPROFILE, psProfile);
	f_profile := psProfile;

	//------------- create numbers in play string -----------------
	numbers_in_play := '';
	for ball:=0 to MAX_LOTTERY_NUM do
		if (ball>highest_ball) or not f_in_play.boolvalue[ball] then
			numbers_in_play := numbers_in_play + '0'
		else
			numbers_in_play := numbers_in_play + '1';

	//--------------- write to ini file----------------------------
	with inifile do
	begin
		write( VERSION_SECTION, VERSION_ENTRY , PREFS_VERSION);

		sSection := psProfile + PREFS_SECTION;
		write( sSection, FROM_ENTRY ,highest_ball);
		write( sSection, SELECT_ENTRY ,select);
		write( sSection, SORTED_ENTRY ,sorted);
		write( sSection, RENDERED_ENTRY , rendered);
		write( sSection, RANDOM_KICK_ENTRY ,random_kick);
		write( sSection, SHOW_NUMBERS_ENTRY ,show_numbers);
		write( sSection, IN_PLAY_ENTRY ,numbers_in_play);
		write( sSection, COLUMNS_ENTRY, columns);
		write( sSection, ZERO_ENTRY, start_at_zero);
		write( sSection, MUTE_ENTRY, mute);
		write( sSection, DROP_STYLE_ENTRY, drop_style);
		write( sSection, ANGLE_ENTRY, angle);
		write( sSection, MACHINE_COLUMNS_ENTRY, machine_columns);
		write( sSection, USE_SEQUENCES_ENTRY, use_sequences);
		write( sSection, KEEP_PICKING_ENTRY, keep_picking);
		write( sSection, REMOVE_PICKED_ENTRY, remove_picked_balls);
		write( sSection, BACKGROUND_IMAGE_ENTRY, use_background_images);
		write( sSection, BGIMAGE_FOLDER_ENTRY, background_image_folder);
		write( sSection, BGIMAGE_SPEED_ENTRY, background_speed);
		sSection := psProfile + SEQUENCE_SECTION;
		sequences.write_to_ini( inifile , sSection,  SEQUENCE_NAME);
	end;
		//----------------- write sequences ------------
	inifile.Free;
end;


//************************************************************
procedure TLotteryPrefs.load_prefs(psProfile:string);
var
	numbers_in_play, char: String;
	ball: integer;
	inifile: tinifile;
	sSection:string;
begin
	{-----------------open the ini file--------------------------------}
	inifile := tinifile.create( INIFILENAME);

	{-----------------read the contents --------------------------------}
	with inifile do
	begin
		sSection := psProfile + PREFS_SECTION;
		highest_ball := read( sSection,	FROM_ENTRY ,MAX_UK_LOTTERY_NUM);
		select := read( sSection,  SELECT_ENTRY ,UK_NSELECT);
		sorted := read( sSection,  SORTED_ENTRY, false);
		rendered := read( sSection,	RENDERED_ENTRY, false);
		random_kick := read( sSection,  RANDOM_KICK_ENTRY, false);
		show_numbers := read( sSection,	SHOW_NUMBERS_ENTRY, false);
		columns := read(sSection, COLUMNS_ENTRY, 5);
		start_at_zero := read( sSection,  ZERO_ENTRY, false);
		mute := read( sSection,	MUTE_ENTRY, true);
		drop_style := read(sSection, DROP_STYLE_ENTRY, integer(ldsNormal));
		angle := read( sSection,  ANGLE_ENTRY, 0);
		machine_columns := read( sSection,  MACHINE_COLUMNS_ENTRY, 5);
		use_sequences := read( sSection, 		USE_SEQUENCES_ENTRY, false);
		keep_picking := read( sSection,	KEEP_PICKING_ENTRY, false);
		remove_picked_balls := read( sSection,  REMOVE_PICKED_ENTRY, false);
		use_background_images := read( sSection, BACKGROUND_IMAGE_ENTRY, false);
		background_image_folder := read( sSection, BGIMAGE_FOLDER_ENTRY, '');
		background_speed := read  (sSection, BGIMAGE_SPEED_ENTRY, 6);

		{---------------set which of the balls are not in play--------}
		numbers_in_play := read( sSection, IN_PLAY_ENTRY, '');
		f_in_play.clear;
		if numbers_in_play = '' then
			for ball := 0 to MAX_LOTTERY_NUM do
				f_in_play.boolvalue[ball] := true
		else
			 for ball := 0 to MAX_LOTTERY_NUM do
				begin
					char := numbers_in_play[ball+1];
					if (char='0') or (ball > highest_ball) then
							f_in_play.boolvalue[ball] := false
					else
							f_in_play.boolvalue[ball] := true;
				 end;
		reinitialise_current;
	end;

	if (not assigned(sequences)) then sequences:= TLotterySequenceList.create(true);
	sSection := psProfile + SEQUENCE_SECTION;
	sequences.read_from_ini( inifile , sSection);

	f_profile := psProfile;
	{------------------ close ini file----------------------}
	inifile.Free;
end;


//##############################################################
//# PUBLICS
//##############################################################
procedure TLotteryPrefs.pr_set_in_play(value:tintlist);
begin
	f_in_play.free;
	f_in_play := value.clone;
	reinitialise_current
end;

//************************************************************
function TLotteryPrefs.CurrentProfile:string;
var
	oinifile: Tinifile;
begin
	oinifile := Tinifile.Create(INIFILENAME);
	result := oinifile.read(INI_CONFIG_SECTION, INI_CURRENTPROFILE, DEFAULT_PROFILE);
	oinifile.Free;
end;

//##############################################################
//# PUBLICS
//##############################################################
function TLotteryPrefs.getProfiles: TStringList;
var
	oinifile: Tinifile;
	oList: TStringList;
	oSection : Tinifilesection;
begin
	oinifile := Tinifile.Create(INIFILENAME);
	oSection := oinifile.sections[INI_PROFILES_SECTION];

	if osection = nil then begin
		olist := TStringList.Create;
		oList.Add('uk');
	end else
		olist := oSection.getKeys;
	result := olist;

	oinifile.Free;
end;

//************************************************************
procedure TLotteryPrefs.reinitialise_current;
begin
	f_current_in_play.free;
	f_current_in_play := f_in_play.clone;
end;

//************************************************************
function TLotteryPrefs.how_many_in_play: integer;
var
	how_many, ball:integer;
begin
		how_many := 0;
		for ball := currentInPlay.fromindex to currentInPlay.toindex do
			if currentInPlay.BoolValue[ball] then
				inc(how_many);
		result := how_many;
end;

//
//####################################################################
(*
	$History: Lottpref.pas $
 * 
 * *****************  Version 3  *****************
 * User: Sunil        Date: 5/06/05    Time: 23:33
 * Updated in $/PAGLIS/lottery
 * added background speed as a preference
 * 
 * *****************  Version 2  *****************
 * User: Sunil        Date: 2/06/05    Time: 0:32
 * Updated in $/PAGLIS/lottery
 * added background_image folder
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/lottery
 * 
 * *****************  Version 5  *****************
 * User: Administrator Date: 8/06/04    Time: 23:49
 * Updated in $/code/paglis/lottery
 * saving and loading profiles
 * 
 * *****************  Version 4  *****************
 * User: Administrator Date: 7/06/04    Time: 16:57
 * Updated in $/code/paglis/lottery
 * select current config
 * 
 * *****************  Version 3  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/lottery
 * added headers and footers
*)
//####################################################################
//
end.

