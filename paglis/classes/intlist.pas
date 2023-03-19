unit Intlist;
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
(* $Header: /PAGLIS/classes/intlist.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//


interface
uses
	Sysutils, simpleobjs, misclib, sparselist;

type
	EIntListError = class (Exception);

	{===================================================================}
	TIntList = Class(Tsparselist)
	private
		f_get_status:boolean;

		procedure set_byte_value( pIndex:word; pValue: Byte); 
		function get_byte_value( pIndex:word): byte;
		procedure set_word_value( pIndex:word; pValue: word);
		function get_word_value( pIndex:word): word;
		procedure set_int_value( pIndex:word; pValue: integer);
		function get_int_value( pIndex:word): integer;
		procedure set_longint_value( pIndex:word; pValue: longint);
		function get_longint_value( pIndex:word): longint;
		procedure set_real_value( pIndex:word; pValue: real);
		function get_real_value( pIndex:word): real;
		procedure set_bool_value( pIndex:word; pValue: Boolean);
		function get_bool_value(	pIndex:word): Boolean;
		procedure pr_set_value(pIndex:word; pValue:UVariant);

	public

		property FromIndex;
		property ToIndex;
		property hasobjects;

		public noExceptionOnGetError: boolean;
		property GetStatus:boolean read f_get_status;
		property ByteValue[i: word]:byte read get_byte_value write set_byte_value ;
		property WordValue[i: word]:word read get_word_value write set_word_value ;
		property LongintValue[i: word]:longint read get_longint_value write set_longint_value ;
		property RealValue[i: word]:real read get_real_value write set_real_value ;
		property BoolValue[i: word]:boolean read get_bool_value write set_bool_value ;
		property IntegerValue[i: word]:integer read get_int_value write set_int_value ;


		function clone: TIntList;
		function equals(other_list: Tintlist): boolean;
		constructor create;
	end;


implementation

	constructor TIntList.create;
    begin
    	inherited create(true);
    end;


	{####################################################################
	 properties (set)
	 ####################################################################}
	procedure TIntList.set_bool_value( pIndex:word; pValue:boolean);
	var
	  value: uVariant;
	begin
	  value.bool_value := pvalue;
	  pr_set_value(pIndex, value);
	end;

	{******************************************************************}
	procedure TIntList.set_byte_value( pIndex:word; pValue:byte);
	var
	  value: uVariant;
	begin
	  value.byte_value := pvalue;
	  pr_set_value(pIndex, value);
	end;

	{******************************************************************}
	procedure TIntList.set_word_value( pIndex:word; pValue:word);
	var
	  value: uVariant;
	begin
	  value.word_value := pvalue;
	  pr_set_value(pIndex, value);
	end;

	{******************************************************************}
	procedure TIntList.set_int_value( pIndex:word; pValue:integer);
	var
	  value: uVariant;
	begin
	  value.int_value := pvalue;
	  pr_set_value(pIndex, value);
	end;

	{******************************************************************}
	procedure TIntList.set_longint_value( pIndex:word; pValue:longint);
	var
	  value: uVariant;
	begin
	  value.longint_value := pvalue;
	  pr_set_value(pIndex, value);
	end;

	{******************************************************************}
	procedure TIntList.set_real_value( pIndex:word; pValue:real);
	var
	  value: uVariant;
	begin
	  value.real_value := pvalue;
	  pr_set_value(pIndex, value);
	end;

	{******************************************************************}
	procedure TIntList.pr_set_value(pIndex:word; pValue:UVariant);
	var
	  value: TVariant;
	begin
		value := tvariant(Items[pIndex]);
		if value =nil then
		begin
			value := TVariant.create;
			items[pIndex] := value;
		end;
		value.Data := pValue;
	end;

	{####################################################################
	 property (GET)
	 ####################################################################}
	function TIntList.get_bool_value( pIndex:word):boolean;
	var
	  value: TVariant;
	begin
		f_get_status := true;
		value := tvariant(Items[pIndex]);
		if value <> nil then
			result := value.boolValue
		else
		begin
			f_get_status := false;
			if noExceptionOnGetError then
				result := false
			else
				raise EIntListError.create( 'unable to get value (' + inttostr(pIndex) + ')');
		end;

	end;

	{******************************************************************}
	function TIntList.get_real_value( pIndex:word):real;
	var
	  value: tVariant;
	begin
	  f_get_status := true;
		value := tvariant(Items[pIndex]);
		if value <> nil then
			result := value.realValue
		else
		begin
			f_get_status := false;
			if noExceptionOnGetError then
			  result := 0.0
			else
			  raise EIntListError.create( 'unable to get value (' + inttostr(pIndex) + ')');
		end;

	end;

	{******************************************************************}
	function TIntList.get_byte_value( pIndex:word):byte;
	var
	  value: tVariant;
	begin
		f_get_status := true;
	  value := tvariant(Items[pIndex]);
	  if value <> nil then
		 result := value.byteValue
	  else
			begin
			 f_get_status := false;
			 if noExceptionOnGetError then
				  result := 0
			 else
				  raise EIntListError.create( 'unable to get value (' + inttostr(pIndex) + ')');
			end;
	end;

	{******************************************************************}
	function TIntList.get_word_value( pIndex:word):word;
	var
	  value: tVariant;
	begin
		f_get_status := true;
		value := tvariant(Items[pIndex]);
		if value <> nil then
			result := value.wordValue
		else
			begin
				f_get_status := false;
				if noExceptionOnGetError then
					result := 0
				else
					raise EIntListError.create( 'unable to get value (' + inttostr(pIndex) + ')');
			end;
	end;

	{******************************************************************}
	function TIntList.get_int_value( pIndex:word):integer;
	var
	  value: tVariant;
	begin
		f_get_status := true;
		value := tvariant(Items[pIndex]);
		if value <> nil then
			result := value.intValue
		else
			begin
				f_get_status := false;
				if noExceptionOnGetError then
					result := 0
				else
					raise EIntListError.create( 'unable to get value (' + inttostr(pIndex) + ')');
			end;
	end;

	{******************************************************************}
	function TIntList.get_longint_value( pIndex:word):longint;
	var
	  value: tVariant;
	begin
		f_get_status := true;
		value := tvariant(Items[pIndex]);
		if value <> nil then
			result := value.longValue
		else
			begin
				f_get_status := false;
				if noExceptionOnGetError then
					result := 0
				else
					raise EIntListError.create( 'unable to get value (' + inttostr(pIndex) + ')');
			end;
	end;


	{****************************************************************}
	function TIntList.clone:TIntList;
	var
		out_list: tIntlist;
		index:word;
		this_obj, clone_obj:Tvariant;
	begin
		out_list := tIntlist.create;	//new list creates copies of items

		out_list.noExceptionOnGetError := noExceptionOnGetError;
		for index := fromIndex to toIndex do
		begin
			this_obj := TVariant(items[index]);
			if (this_obj <> nil) then
			begin
				clone_obj := tvariant.create(this_obj);
				out_list.items[index] := clone_obj;
			end;//if
		end; //for

		clone :=	out_list;
	end;

	{****************************************************************}
	function TIntList.equals(other_list: Tintlist): boolean;
	var
		this_obj, other_obj: Tvariant;
		index:word;
	begin
		result := false;
		if fromindex <> other_list.fromindex then exit;
		if toindex <> other_list.toindex then exit;

		for index := fromIndex to toIndex do
		begin
			this_obj := TVariant (items[index]);
			other_obj := TVariant (other_list.items[index]);

			if (this_obj=nil) or (other_obj=nil) then
			begin
				if this_obj <> other_obj then exit;
				if (this_obj = nil) then
					continue;
			end;

			if not this_obj.equals(other_obj) then exit;


		end;

		result := true;
	end;

//
//####################################################################
(*
	$History: intlist.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/classes
 * 
 * *****************  Version 7  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/classes
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 6  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
*)
//####################################################################
//
end.


