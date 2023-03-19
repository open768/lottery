unit Inifile;

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
(* $Header: /PAGLIS/classes/Inifile.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//

interface

uses classes,sysutils, stringhash, inisection;

type
	EBadIniData = class(Exception);

	Tinifile = class(TStringHash)
	private
		m_file_has_been_read: boolean;
		m_file_has_been_written_to,m_in_read_file: boolean;
		m_filename: string;

		procedure pr_read_file;
		procedure pr_write_file;
		function pr_read_section(ps_section_name:string):TIniFileSection;
		function pr_read(ps_section_name:string; ps_key:string; ps_default:string):string;
		procedure pr_Write(ps_section_name:string; ps_key:string; ps_value:string);
	public
		constructor Create(filename:string);
		destructor Destroy; override;

		function reverse_lookup(section_name, value:string):string;

		function read(section_name:string; key:string; default:boolean):boolean; overload;
		function read(section_name:string; key:string; default:string):string; overload;
		function read(section_name:string; key:string; default:Longint):longint; overload;
		function read(section_name:string; key:string ):Tstringlist; overload;
		function read_date(section_name:string; key:string): TdateTime;

		procedure Write(section_name:string; key:string; value:boolean);	 overload;
		procedure Write(section_name:string; key:string; value:string); overload;
		procedure Write(section_name:string; key:string; value:Longint); overload;
		procedure write(section_name:string; key:string; value:real); overload;
		procedure write_date(section_name:string; key:string; value:TdateTime); overload;
		procedure Delete_Key(section_name:string; key:string);
		procedure Delete_Section(section_name:string);

		property filename:string read m_filename;
		property sections[section_name:string]:TIniFileSection read pr_read_section; 
	end;

	const
	  SECTION_LH_BRACKET = '[';
	  SECTION_RH_BRACKET = ']';

implementation
	uses
	  forms,filestream2, miscstrings, misclib;
	const
	  LINE_COMMENT1= ';';
	  LINE_COMMENT2= '/';
	  LINE_COMMENT3= '!';

	//################################################################################
	//#
	//################################################################################
	constructor Tinifile.Create(filename:string);
	begin
	  inherited Create;
	  AutoFreeObjects := true;
	  m_file_has_been_read := false;
	  m_file_has_been_written_to:= false;
	  m_in_read_file := false;
	  
	  if pos('\',filename) = 0 then
			m_filename := g_misclib.get_program_pathname +	filename
	  else
			m_filename := filename;
	end;

	{***************************************************************************}
	destructor Tinifile.Destroy;
	begin
	  pr_write_file;
	  inherited destroy;
	end;

	//################################################################################
	//#
	//################################################################################
	function Tinifile.read(section_name:string; key:string; default:boolean):boolean;
	var
	  string_bool: string;
	begin
	  string_bool := pr_read( section_name, key, '');
	  if (string_bool = '1') then
			result := true
	  else if (string_bool = '0') then
			result := false
	  else
			result := default;
	end;

	{***************************************************************************}
	function Tinifile.read(section_name:string; key:string; default:Longint):longint;
	var
	  string_num: string;
	begin
	  string_num := pr_read( section_name, key, inttostr(default));
	  try
		result := strtoint(string_num);
	  except
		on exception do result := default;
	  end;
	end;

	{***************************************************************************}
	function Tinifile.read_Date(section_name:string; key:string):TdateTime;
	var
	  string_date: string;
	begin
	  {------------ read string -----------------------------------}
	  string_date := pr_read(section_name, key, '');
	  if (string_date = '') then
			raise EBadIniData.create('missing Date key:' + key);
	  read_Date := g_miscstrings.string_to_date(string_date);
	end;

	//***************************************************************************
	function Tinifile.read(section_name:string; key:string ):Tstringlist;
	var
		string_value:string;
		out_list: Tstringlist;
	begin
		string_value := pr_read(section_name, key, '');

		if string_value <> '' then
			out_list := g_miscstrings.split(string_value,',')
		else
			out_list := Tstringlist.create;

		result := out_list;
	end;

	//***************************************************************************
	function Tinifile.read(section_name:string; key:string; default:string):string;
	begin
		result := pr_read(section_name,key,default);
	end;
	

	//***************************************************************************
	//***************************************************************************
	procedure Tinifile.Write(section_name:string; key:string; value:boolean);
	begin
	  if value then
			Write(section_name,key,'1')
	  else
			Write(section_name,key,'0');
	end;

	{***************************************************************************}
	procedure Tinifile.Write(section_name:string; key:string; value:Longint);
	begin
	  pr_write(section_name,key, inttostr(value));
	end;

	{***************************************************************************}
	procedure Tinifile.Write_date(section_name:string; key:string; value:TdateTime);
	var
	  date_string: string;
	begin
	  date_string := g_miscstrings.date_to_string(value);
	  pr_write(section_name,key, date_string);
	end;

	{***************************************************************************}
	procedure Tinifile.write(section_name:string; key:string; value:real);
	var
	  real_string: string;
	begin
	  real_string := FloatToStr(value);
	  pr_write(section_name,key, real_string);
	end;


	{***************************************************************************}
	procedure Tinifile.Write(section_name:string; key:string; value:string);
	begin
	  pr_write(section_name,key,value);
	end;


	//***************************************************************************
	//***************************************************************************
	procedure Tinifile.Delete_Key(section_name:string; key:string);
	var
	  oSection: TIniFileSection;
	begin
	  pr_read_file;
	  oSection := tinifilesection(objects[section_name]);
	  if oSection = nil then exit;
	  oSection.Delete_Key(key);
	end;

	{***************************************************************************}
	procedure Tinifile.Delete_Section(section_name:string);
	begin
	  pr_read_file;
	  delete(section_name);
	end;


	//***************************************************************************
	//***************************************************************************
  function Tinifile.reverse_lookup(section_name, value:string):string;
  var
	section: TIniFileSection;
  begin
	//----------------- locate section -------------------------------------
	section := pr_read_section(section_name);
	  if section = nil then
	  begin
		result := '';
			exit;
	  end;

	//----------------- reverse_lookup in section-------------------------------------
	  result := section.reverse_lookup(value);
  end;

	//###########################################################################
	//#
	//###########################################################################

	procedure Tinifile.pr_Write(ps_section_name:string; ps_key:string; ps_value:string);
	var
	  oSection: TIniFileSection;
	begin
	  pr_read_file;
	  oSection := tinifilesection(objects[ps_section_name]);
	  if oSection = nil then
	  begin
			oSection := TIniFileSection.create(ps_section_name);
			objects[ps_section_name] := oSection;
	  end;

	  osection[ps_key] := ps_value;
	  m_file_has_been_written_to:= not m_in_read_file;
	end;

	//***************************************************************************
	function Tinifile.pr_read(ps_section_name:string; ps_key:string; ps_default:string):string;
	var
	  oSection: TIniFileSection;
	  outval: string;
	begin
	  pr_read_file;
	  oSection := tinifilesection(objects[ps_section_name]);
	  outval :='';
	  if oSection <> nil then
		outval := oSection[ps_key];

	  if outval = '' then
		outval := ps_default;

	  result := outval;
	end;

	//***************************************************************************
	function Tinifile.pr_read_section(ps_section_name:string):TIniFileSection;
	begin
		pr_read_file;
		result :=  tinifilesection(objects[ps_section_name]);
	end;

	//***************************************************************************
	procedure Tinifile.pr_read_file;
	var
	  F: TextFile;
	  index:integer;
	  line, key, value, section_name:string;
	  bFileOk: boolean;
	begin
	  if m_file_has_been_read then exit;
	  if m_in_read_file then exit;
	  m_in_read_file := true;

	  //read all the lines from the ini file

	  AssignFile(F, m_filename);	{ File selected in dialog box }
	  bFileOk := FileExists(m_filename);

	  //--------------------------------------------------------
	  if bFileOk then
			try
			  reset( F) ;
			except
			  on einouterror  do  bFileOk := false;
			end;

	  //--------------------------------------------------------
	  if bFileOk then
			try
			  while not eof(f) do
			  begin
				  Readln(F, line);
				  line := trim(line);

				  // ----------- skip blank lines ---------------------
				  if length(line) = 0 then continue;

				  // ----------- skip comments ------------------------
				  if (line[1] = LINE_COMMENT1) or (line[1] = LINE_COMMENT2)  or (line[1] = LINE_COMMENT3) then	continue;

				  //------------ is this a section identifier ---------
				  if line[1] = SECTION_LH_BRACKET  then
				  begin
					  if line[ length(line)] <> SECTION_RH_BRACKET  then
							raise EBadIniData.create('bad section identifier: ' + line);

					  section_name  := g_miscstrings.mid_string(line,2,length(line)-2);
					  continue;
				  end;

				  //------------- must be a key value, chekc validity ------------
				  index := pos('=', line);
					  if index = 0 then
					  raise EBadIniData.create('bad key value: ' + line);

				  g_miscstrings.split_string(line, '=', key, value);
				  write(section_name,key,value);
			  end;
			finally
			  CloseFile(F);
			end;

	  //update flag
	  m_in_read_file := false;
	  m_file_has_been_read := true;
	end;

	{***************************************************************************}
	procedure Tinifile.pr_write_file;
	var
	  stream: TFilestream2;
	  keys: tstringlist;
	  key_index:integer;
	  section: TIniFileSection;
	  section_name: string;
	begin
		if not m_file_has_been_read then exit;
		if not m_file_has_been_written_to then exit;
		 //write out the ini file

		try
			stream := tfilestream2.create(m_filename, fmCreate or fmOpenWrite);
		except
			on efcreateerror do
				begin
					g_misclib.alert('fatal error: read only ini file ' + m_filename);
					application.terminate;
					exit;
				end;
		end;

	  keys := getKeys;
	  try

		for key_index := 1 to keys.Count do
		begin
			section_name := keys.Strings[key_index-1];
			section := Tinifilesection(Objects[section_name]);
			section.write_to_file(stream);
		end;

	  finally
			if (keys <> nil) then keys.Free;
			stream.free;
	  end;

	  //all done;
	  m_file_has_been_written_to  := false;
	end;


	{################################################################################}
	{################################################################################}

  (*
		$History: Inifile.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/classes
 * 
 * *****************  Version 10  *****************
 * User: Administrator Date: 17/01/05   Time: 11:16p
 * Updated in $/code/paglis/classes
 * memory leak fixed
 * 
 * *****************  Version 9  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/classes
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 8  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
 * 
 * *****************  Version 7  *****************
 * User: Sunil		  Date: 9-01-03    Time: 12:14p
 * Updated in $/paglis/classes
 * split misclib into three OO libraries
 * 
 * *****************  Version 6  *****************
 * User: Sunil		  Date: 1/06/03    Time: 12:14a
 * Updated in $/paglis/classes
 * removed pointers from sparselist - all works AOK
 * 
 * *****************  Version 5  *****************
 * User: Sunil		  Date: 1/04/03    Time: 5:47p
 * Updated in $/paglis/classes
 * lottery programs working again
 * 
 * *****************  Version 4  *****************
 * User: Sunil		  Date: 1/03/03    Time: 11:21p
 * Updated in $/paglis/classes
 * stopped a stack overflow
 * 
 * *****************  Version 3  *****************
 * User: Sunil		  Date: 1/03/03    Time: 11:08p
 * Updated in $/paglis/classes
 * major rewrite to use stringhash not stringhashtrie
  *)
end.

