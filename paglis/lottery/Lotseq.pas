unit Lotseq;
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
(* $Header: /PAGLIS/lottery/Lotseq.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//


interface

uses
	sparselist, intlist, inifile;

type
	TLotterySequenceType = (lseqRandom, lseqRange, lseqNumbers);

	{**********************************************************************}
	TLotterySequenceList = class (TsparseList)
	public
		Function clone:TLotterySequenceList;
		procedure write_to_ini(inifile:Tinifile; Section, seq_name:string);
		procedure read_from_ini(inifile:Tinifile; Section: string);
	end;


	{**********************************************************************}
	TLotterySequence = class
	public
		seq_type:  TLotterySequenceType;
		numbers: Tintlist;
		how_many: word;
		seq_name: string;
		reuse: boolean;
		sorted: boolean;

		constructor Create;
		destructor Destroy; override;
	end;

	function get_sequence_type(astring: string) : TLotterySequenceType;
	function get_sequence_typename(num: TLotterySequenceType) : string;

implementation

uses
	classes, misclib, miscstrings, sysutils;

const
	SEQUENCE_DELIM = '|';
	SEQ_NAME_ENTRY = 'bigname';

	COUNT_ENTRY =	'count';
	TYPE_ENTRY = 'type';
	HOWMANY_ENTRY = 'howmany';
	DATA_ENTRY = 'data';
	NAME_ENTRY = 'name';
	REUSE_ENTRY = 'reuse';
	SORT_ENTRY = 'sort';

	//######################################################################
	//TLotterySequence
	//######################################################################
	constructor TLotterySequence.Create;
	begin
	  Numbers:= nil;
	  seq_name := '';
	  reuse := false;
	  sorted := false;
	end;

	//*********************************************************************
	destructor TLotterySequence.Destroy;
	begin
	  if assigned(NUmbers) then
			Numbers.free;
	  inherited Destroy
	end;

	//*********************************************************************
	function get_sequence_typename(num: TLotterySequenceType) : string;
	begin
	  CASE num OF
			lseqRandom: result := 'random';
			lseqRange: result := 'range';
			lseqNumbers:result := 'numbers';
	  END;
	end;

	//*********************************************************************
	function get_sequence_type(astring: string) : TLotterySequenceType;
	begin
			if astring = 'random' then
			begin
			  result := lseqRandom;
			  exit;
			end;

			if astring = 'range' then
			begin
			  result := lseqRange;
			  exit;
			end;

			result := lseqNumbers;
	end;


	//######################################################################
	// TLotterySequenceList
	//######################################################################

	//*********************************************************************
	Function TLotterySequenceList.clone:TLotterySequenceList;
	var
		out_list: TLotterySequenceList;
		in_obj, out_obj : TLotterySequence;
		index: longint;
	begin
		out_list := TLotterySequenceList.create(true);

		for index := fromIndex to toIndex do
		begin
			in_obj := TLotterySequence(items[index]);
			if in_obj <> nil then
			begin
				out_obj :=	TLotterySequence.create;
				if in_obj.numbers = nil then
					out_obj.numbers := nil
				else
					out_obj.numbers := in_obj.numbers.clone;

				out_obj.how_many := in_obj.how_many;
				out_obj.seq_type := in_obj.seq_type;
				out_obj.seq_name := in_obj.seq_name;
				out_obj.reuse := in_obj.reuse;
				out_obj.sorted := in_obj.sorted;
				out_list.items[index] := out_obj;
			end;
		end;

		result := out_list;
	end;


	//*********************************************************************
	procedure TLotterySequenceList.write_to_ini(inifile:Tinifile; Section, seq_name:string);
	var
		seq_string, seq_prefix: String;
		seq_no, seq_index, num_index: integer;
		seq_obj : TLotterySequence;
		numbers: Tintlist;
	begin
		seq_index := 0;

		for seq_no := FromIndex to ToIndex do
		begin
			//- - - - - - - - - - - - - - - - - - - - - - - - - -
			seq_obj := TLotterySequence(Items[seq_no]);
			if seq_obj = nil then continue;

			//- - - - - - - - - - - - - - - - - - - - - - - - - -
			seq_string := '';
			numbers := seq_obj.numbers;
			if numbers <> nil then
				for num_index:= numbers.FromIndex to numbers.toIndex do
				begin
					if num_index <> numbers.FromIndex then
						seq_string := seq_string + SEQUENCE_DELIM;
					seq_string := seq_string + inttostr( numbers.ByteValue[num_index]);
				end;

			//- - - - - - - - - - - - - - - - - - - - - - - - - -
			inc (seq_index);
			seq_prefix:= inttostr(seq_index) + '.';
			inifile.write(  section, seq_prefix + TYPE_ENTRY, integer(seq_obj.seq_type));
			inifile.write(  section, seq_prefix + HOWMANY_ENTRY, seq_obj.how_many);
			inifile.write(  section, seq_prefix + DATA_ENTRY, seq_string);
			inifile.write(  section, seq_prefix + NAME_ENTRY, seq_obj.seq_name);
			inifile.write(  section, seq_prefix + REUSE_ENTRY, seq_obj.reuse);
			inifile.write(  section, seq_prefix + SORT_ENTRY, seq_obj.sorted);

		end;
		inifile.write( SECTION, COUNT_ENTRY, seq_index);
		inifile.write( SECTION, SEQ_NAME_ENTRY, seq_name);

	end;

	//*********************************************************************
	procedure TLotterySequenceList.read_from_ini(inifile:Tinifile; Section:string);
	var
	  seq_prefix, seq_numbers, seq_num:string;
	  n_sequences, seq_no: byte;
	  seq_obj : TLotterySequence;
	  string_list: Tstringlist;
	  int_list: Tintlist;
	  index:integer;
	begin
		//--------------clear out old sequences ------
		clear;

		//--------------get each sequence in turn ------
		n_sequences := inifile.read(Section,		COUNT_ENTRY,0);
		for seq_no := 1 to n_sequences do
		begin
			seq_prefix:= inttostr(seq_no) + '.';

			seq_obj := TLotterySequence.create();
			seq_obj.seq_type  :=  TLotterySequenceType (inifile.read(  section, seq_prefix + TYPE_ENTRY, integer(lseqRandom)));
			seq_obj.how_many := inifile.read(  section, seq_prefix + HOWMANY_ENTRY,1 );
			seq_obj.reuse := inifile.read(  section, seq_prefix + REUSE_ENTRY,false );
			seq_obj.sorted := inifile.read(	section, seq_prefix + SORT_ENTRY,false );
			seq_obj.seq_name := inifile.read(  section, seq_prefix + NAME_ENTRY,'' );

			//- - - - - - - - - - - get the sequence information - - - - - - - - - - - - -
			seq_numbers :=		inifile.read(  section, seq_prefix + DATA_ENTRY , '');
			if seq_numbers = '' then
			  seq_obj.numbers := nil
			else
			  begin
				  string_list :=	 g_miscstrings.split(seq_numbers, SEQUENCE_DELIM);
				  int_list := tintlist.create;
				  for index := 1 to string_list.count do
				  begin
					  seq_num := string_list.Strings[index-1];
					  int_list.ByteValue[index-1] := strtoint(seq_num);
				  end;

				  seq_obj.numbers := int_list;
				  string_list.free;
			  end;

			//- - - - - - - - -add sequence object to prefs obj
			add( seq_obj);
	  end;
	end;


//
//####################################################################
(*
	$History: Lotseq.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/lottery
 * 
 * *****************  Version 4  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/lottery
 * added headers and footers
*)
//####################################################################
//
end.

