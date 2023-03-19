unit SimpleObjs;
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


interface
type
  TInteger = class
  public
		intvalue:integer;
		constructor Create(value:integer);
  end;

	UVariant =
		record
			case Integer of
			 0: (real_value: real);
			 1: (int_value: integer);
			 2: (byte_value: byte);
			 3: (word_value: word);
			 4: (bool_value:boolean);
			 5: (longint_value: longint);
		end;

  TVariant = class
  private
		f_data:uvariant;
  public
		constructor create; overload;
		constructor create(obj:Tvariant);overload;
		public function equals(obj:Tvariant):boolean;
		property realValue: real read f_data.real_value write f_data.real_value;
		property intValue: integer read f_data.int_value write f_data.int_value;
		property byteValue: byte read f_data.byte_value write f_data.byte_value;
		property wordValue: word read f_data.word_value write f_data.word_value;
		property boolValue: boolean read f_data.bool_value write f_data.bool_value;
		property longValue: longint read f_data.longint_value write f_data.longint_value;
		property Data: UVariant read f_data write f_data;
  end;


implementation
	constructor TInteger.Create(value:integer);
	begin
		inherited create;
		intvalue := value;
	end;

	constructor TVariant.Create();
	begin
		inherited;
		intValue := 0;
	end;

	constructor TVariant.create(obj:Tvariant);
	begin
		create;
		f_data := obj.f_data;
	end;

	function TVariant.equals(obj:Tvariant):boolean;
	begin
		result := (realValue = obj.realValue) and (longValue = obj.longValue);
	end;
//
//####################################################################
(*
	$History: SimpleObjs.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/classes
 * 
 * *****************  Version 6  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/classes
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 5  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
*)
//####################################################################
//
end.
 