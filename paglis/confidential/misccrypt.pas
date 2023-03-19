unit misccrypt;

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
(* $Header: /PAGLIS/confidential/misccrypt.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//

interface
uses
	wintypes, reg;

type
	tMiscCrypt = class
	private
		function pr_vignere_encode(the_string,key:string;decode_it:boolean):string;
	public
		function feedback_encode(the_string,key:string;maxlen:word):string;
		function vignere_encode(the_string,key:string):string;
		function vignere_decode(the_string,key:string):string;

		function get_standard_cipherkey(program_name:string):string;
		function get_program_key(registry:Tregistry; var the_key:hkey; program_name:string):longint;
		function get_serial_number: string;
	end;
var
	g_misccrypt :tMiscCrypt;

implementation
uses
	sysutils, dialogs, miscstrings, miscencode, translator;
const
	REG_ROOT_KEY = 'Software\Paglis';
	ANYBASE_SEQUENCE = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz[]{}';


	{**********************************************************}
	function tMiscCrypt.get_standard_cipherkey(program_name:string):string;
	var
		alpha_string, out_string:string;
	begin
		{--------interleave program_name into alphabet -------------}
		if program_name = 'picker361' then
			out_string := 'A01B23C45D67E89F0GHIJKLMNOPQRSTUVWXYZ'
		else
			begin
			 alpha_string := g_miscstrings.string_sequence('a', 'z');
			 out_string := g_miscstrings.interleave_strings(alpha_string,program_name);
			end;

		get_standard_cipherkey := out_string;
	end;

  {**********************************************************}
	function tMiscCrypt.get_program_key(registry:Tregistry; var the_key:hkey; program_name:string):longint;
	begin
		result := Registry.create_key(HKEY_CURRENT_USER, REG_ROOT_KEY+'\'+program_name, the_key);
		if result <> error_success then
			showmessage( localString('unable to get program key - #' + inttostr(result) + '#'));
	end;

{*********************************************************************}
function tMiscCrypt.get_serial_number: string;
var
	VolumeSerialNumber: DWORD;
	MaximumComponentLength: DWORD;
	FileSystemFlags: DWORD;
begin
	(*
	//------------------ get drive names ----------------------
  drive_names := StrAlloc( 100);
	status := GetLogicalDriveStrings(
	100,	// size of buffer
	c_string		// address of buffer for drive strings
   );
   drive_names := passtr(c_string);
   StrDispose( c_string);
   *)
   
	//------------------ get serial number for first drive name ------------
	GetVolumeInformation(
		'C:\',
		nil,
		0,
		@VolumeSerialNumber,
		MaximumComponentLength,
		FileSystemFlags,
		nil,
		0);

  result := IntToHex(HiWord(VolumeSerialNumber), 4) +  '-' + IntToHex(LoWord(VolumeSerialNumber), 4);
end;
{**********************************************************
  this simple code is used to verify the username against
  its encrypted version.
 *********************************************************}
function tMiscCrypt.feedback_encode(the_string,key:string;maxlen:word):string;
var
   working_str, encoded_string, broken_string:string;
   index,pos1,pos2,last_pos:integer;
   key_len, cipher_len:integer;
begin
   {----------------------init-----------------------------}
   encoded_string := '';
   key_len := length(key);

   cipher_len := maxlen;
   working_str := g_miscstrings.adjust_length(the_string,cipher_len);

   {-- encode using the ASCII code of the letter. -----------------}
   last_pos := 0;
   for index:=1 to cipher_len do
   begin
	 pos1 := ord(working_str[index]);
	 pos2 := ((pos1*pos1 + last_pos) mod key_len);
	 inc(pos2);
	 last_pos:= pos2;

	 encoded_string := encoded_string + key[pos2];
   end;

   {---------------------all done ----------------}
   broken_string := g_miscstrings.break_string(encoded_string,4,'-');

   feedback_encode := broken_string;
end;

function tMiscCrypt.pr_vignere_encode(the_string,key:string; decode_it:boolean):string;
var
  index,string_length,key_length: integer;
  key_pos:integer;
  in_char, key_char, out_char:integer;
  out_string:string;
begin
  {--------------- initialisation -----------------------}
  key_length := length(key);
  string_length := length(the_string);
  out_string := '';

  {--------------- work through string -----------------------}
  for index := 1 to string_length do
  begin
	{- - - get ASCII code of character and ascii code of key character----}
	in_char := ord( the_string[index] );
	key_pos := 1 + (index-1) mod key_length;
	key_char := ord( key[ key_pos] );

	{- - - vignere, combine the two values - - - - - - }
	if decode_it then
		out_char := (in_char - key_char) mod 255
	else
		out_char := (in_char + key_char) mod 255;

	{- - - - the modulus operator doesnt work when negative - - - -}
	if (out_char < 0) then
		out_char := out_char +255;

	{- - - - add generated characters to string - - - -}
	out_string := out_string + chr(out_char);
  end;

  {-----------------ok lets have it -----------------------}
  result := out_string;
end;

{*********************************************************}
function tMiscCrypt.vignere_encode(the_string,key:string):string;
begin
  vignere_encode := pr_vignere_encode(the_string,key,false);
end;

{*********************************************************}
function tMiscCrypt.vignere_decode(the_string,key:string):string;
begin
  vignere_decode := pr_vignere_encode(the_string,key,true);
end;



initialization
	g_misccrypt := tMiscCrypt.create;

finalization
	g_misccrypt.free;


//
//####################################################################
(*
	$History: misccrypt.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/confidential
 * 
 * *****************  Version 3  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
*)
//####################################################################
//

end.
 