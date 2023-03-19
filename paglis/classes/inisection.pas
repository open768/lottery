unit inisection;

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
(* $Header: /PAGLIS/classes/inisection.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//

interface
uses
	filestream2, classes,stringhash;
type

	TIniFileSection = class(tstringhash)
	private
		c_section_name: string;
		c_inverse_hash: tstringhash;
		procedure pr_set_value(key,value:string);
		function pr_get_value(key:string):string;
		procedure pr_create_inverse_hash;
	public
		constructor create(section_name: string);
		destructor destroy; override;
		procedure write_to_file(stream:Tfilestream2);
		procedure delete_key(key:string);
		function reverse_lookup(value:string): string;

		property Values[Key:string]: string read pr_get_value write pr_set_value; default;
	 end;

implementation
uses
	sysutils, inifile, misclib;
type
	TIniFileSectionHashItem = class(Tobject)
	private
		c_Value, c_Key: string;
	public
		constructor create(key, value:string);
		property Value:string read c_value write c_value;
		property Key:string read c_key;
	end;

	 //######################################################################
	 //######################################################################
	constructor TIniFileSectionHashItem.create(key, value:string);
	begin
		inherited create;
		c_Key := key;
		c_Value := value;
   end;

	//######################################################################
	//######################################################################
	constructor TIniFileSection.create(section_name: string);
	begin
		inherited create;
		c_section_name := section_name;
		AutoFreeObjects := true;
		c_inverse_hash := nil;
	end;

	{***************************************************************************}
	 destructor TIniFileSection.destroy;
	 begin
			if assigned(c_inverse_hash) then c_inverse_hash.free;

		inherited destroy;
	 end;

	{***************************************************************************}
	function TIniFileSection.pr_get_value(key:string):string;
	var
		item: TIniFileSectionHashItem;
	begin
		item:= TIniFileSectionHashItem(objects[key]);
		if item=nil then
				result := ''
			else
				result := item.value;
	end;

	{***************************************************************************}
	procedure TIniFileSection.pr_set_value(key,value:string);
	var
		item: TIniFileSectionHashItem;
	begin
		item:= TIniFileSectionHashItem(objects[key]);
		if item = nil then
		begin
			item := TIniFileSectionHashItem.create(key,value);
			objects[key] := item;
		end;
		item.Value := value;


	  if assigned(c_inverse_hash) then
	  begin
			item := TIniFileSectionHashItem.create(value,key);
				c_inverse_hash.Objects[value] := item;
	  end;
	end;


	//***************************************************************************
	procedure TIniFileSection.write_to_file(stream:tfilestream2);
	var
		index: integer;
		key_name, key_value: string;
		keys: tstringlist;
	begin
		stream.writeln(SECTION_LH_BRACKET + c_section_name + SECTION_RH_BRACKET);
		keys := getkeys;
		for index := 1 to keys.count do
		begin
			key_name := keys.Strings[index-1];
			key_value := pr_get_value(key_name);
			stream.writeln(key_name + '=' + key_value);
		end;
		keys.Free;
		stream.writeln('');
  end;

	//***************************************************************************
	procedure TIniFileSection.delete_Key(key:string);
	begin
	  Delete(key);
		end;


	//***************************************************************************
  function TIniFileSection.reverse_lookup(value:string): string;
  var
	item: TIniFileSectionHashItem;
  begin
	 //-------- create inverse hash ---------------------
		pr_create_inverse_hash;

	 //-------- lookup ---------------------
		item := TIniFileSectionHashItem(c_inverse_hash.objects[value]);
	 if item=nil then
			result := ''
	 else
			result := item.Value;
  end;

	//***************************************************************************
	procedure TIniFileSection.pr_create_inverse_hash;
	var
		i:integer;
		key, value:string;
		item: TIniFileSectionHashItem;
		keys:tstringlist;
	begin
		if assigned(c_inverse_hash) then exit;

		//-------- create inverse hash ---------------------
		c_inverse_hash := TStringHash.create;
		c_inverse_hash.AutoFreeObjects := true;

		//-------- populate inverse hash ---------------------
		keys := getKeys;
		for i :=1 to keys.count do
		begin
			key := keys[i-1];
			value := pr_get_value(key);

			//find item - dint want to duplicate keys
			item := TIniFileSectionHashItem(c_inverse_hash.objects[value]);
			if (item = nil) then
			begin
				item := TIniFileSectionHashItem.create(value,key);
				c_inverse_hash.objects[value] := item;
			end; //if
		end; //for
		keys.Free;
	end;
	
	{################################################################################}
	{################################################################################}

  (*
		$History: inisection.pas $
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
 * 
 * *****************  Version 5  *****************
 * User: Sunil		  Date: 1/03/03    Time: 11:08p
 * Updated in $/paglis/classes
 * major rewrite to use stringhash not stringhashtrie
  *)
end.
