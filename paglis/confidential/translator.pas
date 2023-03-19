unit translator;

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
(* $Header: /PAGLIS/confidential/translator.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//

interface
uses
	classes, inifile, sparselist;
type

	//***************************************************************************
  TTranslatorTokenType = (TttArgument, TttString);

	TTranslatorToken = class
	public
		token_type : TTranslatorTokenType;
		string_value:string;
		argument_number: integer;
	end;

	//***************************************************************************
	TTranslatorTokeniseResults = class(tsparselist)
	private
		m_lookup_string: string;
		m_arg_count: byte;
		m_args:tstringlist;
	public
		constructor Create;
		destructor destroy; override;

		procedure add_token( is_arg: boolean; buffer: string);
		function recombine_from(obj: TTranslatorTokeniseResults):string;
	published
		property LookupString: string read m_lookup_string;
		property Args: tstringlist read m_args;
	end;

	//***************************************************************************
	TTranslator = class
	private
		m_inifile: Tinifile;
		f_language_in_use: string;
		f_collecting: boolean;
		function tokenise(inString: string): TTranslatorTokeniseResults;
		function reverse_lookup(inString:string): string;
		procedure set_language_in_use(value:string);
		procedure set_collecting(value:boolean);
		function get_count: integer;
		function get_english_string(index:integer): string;
		function get_foreign_string(index:integer): string;
		procedure set_foreign_string(index:integer; value:string);
	public
		property englishString[integer:integer]:string read get_english_string;
		property foreignString[integer:integer]:string read get_foreign_string write set_foreign_string;

		function translate(original_string: string): string;
		constructor create;
		destructor destroy; override;
		function Get_Languages_List: Tstringlist;
		procedure add_language(Language_name:string);
	published
		property LanguageInUse: string read f_language_in_use write set_language_in_use;
		property Collecting: boolean read f_collecting write set_collecting;
		property Count: integer read get_count;
	end;

	//***************************************************************************
	function LocalString( english_string: string):string;
	function getTranslatorObj:TTranslator;
const
  MISSING_KEY = '*** missing english string ***';
	LANG_DEFAULT_LANG = 'DEFAULT';

implementation
uses
	sysutils, miscstrings, miscencode,inisection;
const
	LANG_INI_FILE = 'Lang.ini';
	LANG_CONFIG_SECTION = 'Config';
	LANG_COLLECTING_KEY = 'collect';
  LANG_LANGUAGE_KEY = 'language';
  LANG_LANGUAGES_SECTION = 'LANGUAGES';
  LANG_COUNT_ENTRY = 'count';
  LANG_HASH = '#';
var
	U_translator: TTranslator;

	//############################################################################
	//############################################################################
  constructor TTranslatorTokeniseResults.Create;
  begin
		inherited create(true);
		m_lookup_string := '';
	  m_arg_count := 0;
	 m_args := tstringlist.create;
  end;

	//***************************************************************************
  destructor TTranslatorTokeniseResults.destroy;
  begin
		m_args.free;
	 inherited;
  end;


	//***************************************************************************
  procedure TTranslatorTokeniseResults.add_token( is_arg: boolean; buffer: string);
  var
		token: TTranslatorToken;
	begin
		//----------- make token --------------------
		token := TTranslatorToken.create;
	 token.string_value := buffer;

		//----------- put specific info into token ------
		if is_arg then
		begin
			token.token_type := TttArgument;
			token.argument_number := m_arg_count;
			m_lookup_string := m_lookup_string +  LANG_HASH + inttostr(m_arg_count) + LANG_HASH;
			inc(m_arg_count);
			m_args.add(buffer);
		end
	else
		begin
			token.token_type := TttString;
			 m_lookup_string := m_lookup_string + buffer;
		end;

		//----------- add tokens ------
	 add( tobject( token));
  end;

	//***************************************************************************
  function TTranslatorTokeniseResults.recombine_from(obj: TTranslatorTokeniseResults):string;
  var
		combined, value: string;
	 token_index, arg_index:integer;
	 token :TTranslatorToken;
  begin
		combined :='';
		for token_index := fromindex to toindex do
		begin
			token := TTranslatorToken(items[token_index]);
			if token =nil then continue;

			case token.token_type of
				TttArgument:
				begin
					 arg_index := token.argument_number;
					 value := obj.args[arg_index];
				end;
				TttString:
					value := token.string_value;
			end;
			combined := combined + value;
	  end;
	  result := combined;
  end;
  
	//############################################################################
	//############################################################################
	constructor TTranslator.create;
	begin
		m_inifile := Tinifile.create( LANG_INI_FILE);
		f_language_in_use := m_inifile.read(	LANG_CONFIG_SECTION,	LANG_LANGUAGE_KEY,LANG_DEFAULT_LANG);
		f_collecting:= m_inifile.read(	LANG_CONFIG_SECTION,	LANG_COLLECTING_KEY,false);
	end;

	//****************************************************************
	destructor TTranslator.destroy;
	begin
		m_inifile.free;
		inherited;
	end;

	//****************************************************************
	//uses httpencode to support strnage and unicode characters.
	function TTranslator.Translate(original_string: string): string;
	var
		tokenised, lang_tokenised: TTranslatorTokeniseResults;
		trimmed: string;
		lang_string, string_id, out_string: string;
	begin
		if trim(original_string)='' then
		begin
			result := original_string;
			exit;
		end;

		//split arguments from string
	  tokenised := tokenise(original_string);
	  trimmed := trim(tokenised.LookupString);

	  trimmed := g_miscencode.HTTPEncode(trimmed);

		//reverse lookup string to get ID in default section
	  string_id := reverse_lookup(  trimmed);

		//look fo ID in m_current_section
	  lang_string:=m_inifile.read(f_language_in_use, string_id,'');
		if lang_string = '' then
	  begin
		lang_string := trimmed ;
		 if f_collecting then
			m_inifile.write(f_language_in_use, string_id,lang_string);
	  end;

	  lang_string := g_miscencode.HTTPDecode(lang_string);

		//---- recombine arguments
	  lang_string := trim(lang_string);
	  lang_tokenised := tokenise(lang_string);
	  out_string := lang_tokenised.recombine_from( tokenised);

	  //--------- free up memory
	  tokenised.free;
	  lang_tokenised.free;

		result := out_string;
	end;

	//****************************************************************
  function TTranslator.tokenise(inString: string): TTranslatorTokeniseResults;
  var
	 buffer: string;
	  in_arg: boolean;
	 index: integer;
	 ch: char;
	 tokenised :TTranslatorTokeniseResults;
  begin
		//------------- init ---------------
		buffer := '';
	 in_arg := false;
	 tokenised := TTranslatorTokeniseResults.create;

		//------------- walk buffer looking for hash ---------------
		for index := 1 to length(inString) do
	  begin
			ch := instring[index];
		if ch = lang_hash then
			 begin
						tokenised.add_token( in_arg, buffer);
					in_arg := not in_arg;
				buffer := '';
			 end
		else
			buffer := buffer + ch;
	 end;

	 tokenised.add_token( in_arg, buffer);
	 result := tokenised;
  end;


	//****************************************************************
	function TTranslator.reverse_lookup(inString:string): string;
	var
		string_id:string;
		count:integer;
	begin
		string_id := m_inifile.reverse_lookup(LANG_DEFAULT_LANG, inString);

	 if f_collecting and (string_id = '') then
	 begin
			count := get_count;
		inc(count);
			string_id := inttostr(count);
		 m_inifile.write(LANG_DEFAULT_LANG, LANG_COUNT_ENTRY,string_id);
		m_inifile.write(LANG_DEFAULT_LANG, string_id, inString);
	 end;

	 result := string_id
	end;

	//****************************************************************
	function TTranslator.Get_Languages_List: Tstringlist;
	var
		section: tinifilesection;
		section_names,languages: tstringlist;
		value, index:integer;
		key: string;
	begin
		section := m_inifile.sections[LANG_LANGUAGES_SECTION];
		languages := TStringList.create;
		
		if section <> nil then
		begin
			section_names := section.getKeys;
			for index := 1 to section_names.Count do
			begin
				key := section_names.Strings[index-1];
				value:= m_inifile.read( LANG_LANGUAGES_SECTION, key, 0);
				if value <>0 then
					languages.add(key);
			end;
			section_names.Free;
		end; //if

	  if languages.IndexOf(LANG_DEFAULT_LANG) = -1 then
			languages.add(LANG_DEFAULT_LANG);

		result := languages;
	end;


	//****************************************************************
	procedure ttranslator.add_language(Language_name:string);
	begin
	end;

	//****************************************************************
	procedure ttranslator.set_language_in_use(value:string);
	var
		lang_name:string;
	begin
		if value = f_language_in_use then exit;

		//strip out windows & sign
		lang_name := Trim(value);
		lang_name := g_miscstrings.remove_char(lang_name,'&');

		add_language(lang_name);
		m_inifile.write(LANG_CONFIG_SECTION, LANG_LANGUAGE_KEY,lang_name);
		m_inifile.write(LANG_LANGUAGES_SECTION, lang_name,true);
		f_language_in_use := lang_name;
	end;

	//****************************************************************
	procedure ttranslator.set_collecting(value:boolean);
	begin
		if value = f_collecting then exit;
		m_inifile.write(LANG_CONFIG_SECTION,LANG_COLLECTING_KEY,value);
		f_collecting := value;
	end;

	//****************************************************************
	function ttranslator.get_count: integer;
	begin
		result := m_inifile.read(LANG_DEFAULT_LANG, LANG_COUNT_ENTRY,0);
	end;

	//****************************************************************
	function ttranslator.get_english_string(index:integer): string;
	var
		raw: string;
	begin
		raw := m_inifile.read(LANG_DEFAULT_LANG, inttostr(index),MISSING_KEY	);
		result := g_miscencode.HTTPDecode(raw);
	end;

	//****************************************************************
	function ttranslator.get_foreign_string(index:integer): string;
	var
		raw: string;
		english: string;
	begin
		english := get_english_string(index);
		raw := m_inifile.read(f_language_in_use, inttostr(index),english);
		result := g_miscencode.HTTPDecode(raw);
	end;
	
	//****************************************************************
	procedure ttranslator.set_foreign_string(index:integer; value:string);
	var
		encoded:string;
	begin
		if f_language_in_use =		LANG_DEFAULT_LANG then exit;

		encoded := g_miscencode.HTTPEncode(value);
			m_inifile.write(f_language_in_use, inttostr(index),encoded);
	end;

	//############################################################################
	//############################################################################
	function getTranslatorObj:TTranslator;
	begin
		result := U_translator;
	end;

	function LocalString( english_string: string):string;
  begin
		result := U_translator.translate(english_string);
  end;



initialization
	U_translator := TTranslator.create;

finalization
	 U_translator.free;
//
//####################################################################
(*
	$History: translator.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/confidential
 * 
 * *****************  Version 9  *****************
 * User: Administrator Date: 1/01/05    Time: 11:17p
 * Updated in $/code/paglis/classes
 * parameter to create sparselist.create now mandatory
 * 
 * *****************  Version 8  *****************
 * User: Administrator Date: 10/07/03   Time: 23:44
 * Updated in $/code/paglis/classes
 * change to sparselist means should check for nil
 * 
 * *****************  Version 7  *****************
 * User: Sunil        Date: 7-04-03    Time: 11:07p
 * Updated in $/code/paglis/classes
 * added comments
 * 
 * *****************  Version 6  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
*)
//####################################################################
//
end.
