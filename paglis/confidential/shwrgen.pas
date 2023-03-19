unit Shwrgen;
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
(* $Header: /PAGLIS/confidential/shwrgen.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//


interface

uses
	{$ifdef WIN32}
	Windows,
	{$endif}
	Classes,sysutils,shellapi,inifile,reg;
type
	ESharewareGenerator = class (Exception);

	{######################################################################}
	TSharewareGenerator = class(TComponent)
	private
	  F_Applications: Tstringlist;
	  key_ini_file: Tinifile;
	  F_application_name: String;
	  registry: Tregistry;

	  {----------------------------------------------------------------------}
	  procedure get_applications;
	  procedure remember_current_application;
	  function get_unused_keys:longint;
	  procedure use_keys(n_keys:longint);
	  function get_used_keys:longint;
	  function get_bought_keys:longint;
	  procedure set_bought_keys(total_keys:longint);
	public
		property Applications: TStringList read F_applications;
		property UnusedKeys: longint read get_unused_keys;
		constructor create(Aowner:Tcomponent); override;
		destructor Destroy; override;

		function buy_keys(key:string):boolean;
		function generate_buy_string(total:longint): string;

		function generate_password(username:string; cipher_length:integer; serial_number:string):string;
	published
		property ApplicationName: String read F_application_name write F_application_name;
	end;

	function get_encoded_password(ps_user_name:string; ps_serial_num:string; ps_cipher:string; pi_cipher_length:integer):string; OVERLOAD;
	function get_encoded_password(ps_user_name:string; ps_cipher:string; pi_cipher_length:integer):string; overload;
	function get_web_password(ps_user_name:string; ps_cipher:string; pi_cipher_length:integer):string;


	{######################################################################}
	procedure Register;

implementation
uses
	inisection, SHWRCHCK, misclib,miscencode,misccrypt, miscstrings;
const
  REG_PAD_DELIM = '()';
  REG_PADDED_LEN = 25;
  REG_CHUNK_SEPARATOR = '-';
	REG_DATE_FORMAT = 'ddmmyyyy';
  REG_DATE_SEPARATOR = '~';
	CHUNK_LENGTH = 4;

	REG_BOUGHT_KEYS_KEY = 'Banana';
	REG_USED_KEYS_KEY = 'Mango';

	KEY_INI_FILENAME = 'shwrkeys.ini';
	KEY_APPLICATIONS_SECTION = 'applications';
	KEY_EXPIRES_IN_DAYS = 3;

  NO_MORE_KEYS_MESSAGE = 'You''ve used all available keys - You need to buy more keys from Sunil';
	OLD_KEY_MESSAGE = 'This key is no longer valid as it has expired.';
	GEN_KEY_MESSAGE = 'Error generating key.';


	{######################################################################}
	procedure Register;
	begin
		RegisterComponents('Paglis Utils', [TSharewareGenerator]);
	end;



	//######################################################################
	//######################################################################
  constructor TSharewareGenerator.create(Aowner:Tcomponent);
  begin
	 inherited create(aowner);

	 if not (csDesigning in ComponentState) then
	 begin
		 key_ini_file := Tinifile.create(KEY_INI_FILENAME);
		 registry := TRegistry.create;
		 F_applications := TStringlist.create;
		 get_applications;
	 end;

  end;

  {**********************************************************}
  destructor TSharewareGenerator.Destroy;
  begin
	if assigned(F_applications) then F_applications.free;
	if assigned(registry) then registry.free;

	inherited Destroy;
  end;

	//######################################################################
	//######################################################################
{*** populate list of  known applications ************************}
  procedure TSharewareGenerator.get_applications;
  var
		 section: TIniFileSection;
  begin
	 F_applications.clear;
	 section := key_ini_file.sections[KEY_APPLICATIONS_SECTION];
	 if (section <> nil) then
	 begin
		 F_Applications.free;
		 F_Applications := section.getKeys;
	 end;
  end;

  {**********************************************************}
  procedure TSharewareGenerator.remember_current_application;
  var
	index:integer;
  begin
	index := F_applications.indexof(F_application_name);
	if (index = -1) then
	  f_applications.add(F_application_name);
  end;

  {*********************************************************}
  function TSharewareGenerator.get_unused_keys:longint;
  var
	total_keys, used_keys:longint;
  begin
	total_keys := get_bought_keys;
	used_keys := get_used_keys;

	if used_keys < total_keys then
	  result := total_keys - used_keys
	else
	  result := 0;
  end;

  {*********************************************************}
  function TSharewareGenerator.get_used_keys:longint;
  var
	program_hkey:HKEY;
	encrypted_used, decrypted_used, used: string;
  begin

	 {----------- get information from registry ----------------}
	 g_misccrypt.get_program_key(registry, program_hkey, F_application_name);
	encrypted_used := registry.query_value(program_hkey, REG_USED_KEYS_KEY,'');
	registry.close_key(program_hkey);
	get_used_keys := 0;

	{----------------------------------------------------------}
	if encrypted_used <> '' then
	  begin
		 {- - - - - - - - - - decrypt - - - - - - - }
		 decrypted_used := g_misccrypt.vignere_decode( encrypted_used, F_application_name);
			used := g_miscstrings.get_delimited_string(decrypted_used,REG_PAD_DELIM);
		 if used <> '' then  get_used_keys := strtoint(used);
	  end;

  end;

  {*********************************************************}
  procedure TSharewareGenerator.use_keys(n_keys:longint);
  var
	used_keys:longint;
	program_hkey:hkey;
	delimited, padded, encoded: string;
  begin
	used_keys := get_used_keys + n_keys;

	delimited := REG_PAD_DELIM + inttostr(used_keys) + REG_PAD_DELIM;
	 padded := g_miscstrings.random_pad_string(delimited,REG_PADDED_LEN);
	 encoded := g_misccrypt.vignere_encode(padded, F_application_name);

	g_misccrypt.get_program_key(registry, program_hkey,F_application_name);
	registry.set_value(program_hkey, REG_USED_KEYS_KEY,encoded);
	registry.close_key(program_hkey);
  end;

  {*********************************************************}
  function TSharewareGenerator.buy_keys(key:string):boolean;
  var
	hex_key, vignere_key, padded_key, stripped_key:string;
	num_part, date_part:string;
	old_shortdate_format:string;
	total_keys:longint;
	dd,mm,yy:word;
	key_date, now_date, diff_date:tdatetime;
  begin
	 hex_key := g_miscstrings.remove_char(key, REG_CHUNK_SEPARATOR);
	 vignere_key := g_miscencode.hex_to_string(hex_key);
	 padded_key := g_misccrypt.vignere_decode(vignere_key,f_application_name);
	stripped_key := g_miscstrings.unpad_string(padded_key, REG_PAD_DELIM);

	if stripped_key = '' then
		buy_keys := false
	else
		begin
		old_shortdate_format := shortdateformat;
		shortdateformat := reg_date_format;

		{----------- check that key hasnt expired ------------------}
		g_miscstrings.split_string(stripped_key, REG_DATE_SEPARATOR, num_part, date_part);
			dd := strtoint( g_miscstrings.left_string(date_part,2));
			mm := strtoint( g_miscstrings.mid_string(date_part,3,2));
			yy := strtoint( g_miscstrings.right_string(date_part,4));
		key_date := encodedate(yy,mm,dd);
		now_date := now;
		if now_date < key_date then  raise ESharewareGenerator.Create(OLD_KEY_MESSAGE);
		diff_date := now_date - key_date;
		if diff_date > KEY_EXPIRES_IN_DAYS then
			raise ESharewareGenerator.Create(OLD_KEY_MESSAGE);

		{----------- carry on mcduff ------------------}
		total_keys := strtoint(num_part);
		set_bought_keys(total_keys);
		remember_current_application;
		buy_keys := true;

		shortdateformat := old_shortdate_format;
	  end;
  end;

  {*********************************************************}
  function TSharewareGenerator.generate_buy_string(total:longint): string;
  var
	num_key, hex_key, vignere_key, padded_key:string;
	num_key2, hex_key2, vignere_key2, padded_key2:string;
	out_string:string;
  begin
	num_key := inttostr(total) + REG_DATE_SEPARATOR + formatdatetime(REG_DATE_FORMAT,now);
	padded_key := g_miscstrings.pad_string(num_key,reg_pad_delim,REG_PADDED_LEN);
	 vignere_key := g_misccrypt.vignere_encode(padded_key, f_application_name);
	 hex_key := g_miscencode.hex_encode(vignere_key);
	out_string := g_miscstrings.break_string(hex_key,CHUNK_LENGTH,REG_CHUNK_SEPARATOR);

	{---------- and test -------------}
	 hex_key2 := g_miscstrings.remove_char(out_string, REG_CHUNK_SEPARATOR);
	 if hex_key <> hex_key2 then
		raise ESharewareGenerator.Create(GEN_KEY_MESSAGE  + '- hex key different');

	vignere_key2 := g_miscencode.hex_to_string(hex_key2);
	if vignere_key <> vignere_key2 then
		raise ESharewareGenerator.Create(GEN_KEY_MESSAGE + '- vignere key different');

	 padded_key2 := g_misccrypt.vignere_decode(vignere_key2,f_application_name);
	 if padded_key2 <> padded_key then
		 raise ESharewareGenerator.Create(GEN_KEY_MESSAGE + '- padded key different');

	num_key2 := g_miscstrings.unpad_string(padded_key2, REG_PAD_DELIM);
	if num_key2 <> num_key then
		raise ESharewareGenerator.Create(GEN_KEY_MESSAGE + '- number key different');


	generate_buy_string := out_string;

	remember_current_application;
  end;

  {*********************************************************}
  function TSharewareGenerator.get_bought_keys:longint;
  var
	num_key, hex_key, vignere_key, padded_key:string;
  begin
	get_bought_keys := 0;

	hex_key := key_ini_file.read(KEY_APPLICATIONS_SECTION,f_application_name,'');
	if (hex_key <> '') then
	begin
		vignere_key := g_miscencode.hex_to_string(hex_key);
		padded_key := g_misccrypt.vignere_decode(vignere_key,f_application_name);
		num_key := g_miscstrings.unpad_string(padded_key, REG_PAD_DELIM);
		if num_key <> '' then get_bought_keys := strtoint(num_key);
	  end;
  end;

  {*********************************************************}
  procedure TSharewareGenerator.set_bought_keys(total_keys:longint);
  var
	 num_key, hex_key, vignere_key, padded_key:string;
  begin
	 num_key := inttostr(total_keys);
	 padded_key := g_miscstrings.pad_string(num_key,reg_pad_delim,REG_PADDED_LEN);
	 vignere_key := g_misccrypt.vignere_encode(padded_key, f_application_name);
	 hex_key := g_miscencode.hex_encode(vignere_key);
	 key_ini_file.write(KEY_APPLICATIONS_SECTION,f_application_name,hex_key);

	 get_bought_keys;
  end;

  {**********************************************************}
  function TSharewareGenerator.generate_password(username:string; cipher_length:integer; serial_number:string):string;
  var
	 cipher_key, key:string;
	 keys_remaining:integer;
  begin
	 {--- Check to see if this person has been seen before -------}
	 key := key_ini_file.read(f_application_name,username,'');
	 if (key = '') then
	 begin
		keys_remaining := get_unused_keys;
		if keys_remaining = 0 then
			raise ESharewareGenerator.Create(NO_MORE_KEYS_MESSAGE)
		else
			begin
			 cipher_key := g_misccrypt.get_standard_cipherkey( f_application_name);
			 key := get_encoded_password(username,serial_number,cipher_key, cipher_length);
			 key_ini_file.write(f_application_name,username,key);
			 use_keys(1);
			end;
	 end;

	 {-----------return the key ----------------------------------}
	 generate_password := key;
  end;

	{*************************************************************}
	function get_encoded_password(ps_user_name:string; ps_serial_num:string; ps_cipher:string; pi_cipher_length:integer):string;
	var
		password:string;
	begin
		password :=g_misccrypt.feedback_encode(ps_user_name ,ps_serial_num,pi_cipher_length);
		result := get_encoded_password(password ,ps_cipher,pi_cipher_length);
	end;

	{*************************************************************}
	function get_encoded_password(ps_user_name:string; ps_cipher:string; pi_cipher_length:integer):string;
	begin
		result :=g_misccrypt.feedback_encode(ps_user_name ,ps_cipher,pi_cipher_length);
	end;

	{*************************************************************}
	function get_web_password(ps_user_name:string; ps_cipher:string; pi_cipher_length:integer):string;
	var
		sEncoded: string;
	begin
		sEncoded :=g_misccrypt.feedback_encode(ps_user_name ,ps_cipher,pi_cipher_length);
		result :=g_misccrypt.feedback_encode(sEncoded ,ps_cipher,pi_cipher_length);
	end;
//
//####################################################################
(*
	$History: shwrgen.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/confidential
 * 
 * *****************  Version 7  *****************
 * User: Administrator Date: 22/09/04   Time: 11:30p
 * Updated in $/code/paglis/controls
 * added fuction to get same password as for web
 * 
 * *****************  Version 6  *****************
 * User: Administrator Date: 24/04/04   Time: 14:40
 * Updated in $/code/paglis/controls
 * 
 * *****************  Version 5  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/controls
 * added headers and footers
*)
//####################################################################
//
end.

