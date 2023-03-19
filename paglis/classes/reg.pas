unit reg;
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
	uses sysutils, winprocs, classes,shellapi, wintypes;

	{#########################################################################}
	type
  TRegistry = class(Tobject)
  private
  public
    procedure set_value(key_handle:hkey; keyname, value:string);
    procedure set_boolean_value(key_handle:hkey; keyname:string; value:boolean);
    procedure set_integer_value(key_handle:hkey; keyname:string; value:integer);
    Function query_value(key_handle:hkey; keyname,default:string): string;
    Function query_integer_value(key_handle:hkey; keyname:string): integer;
    Function query_boolean_value(key_handle:hkey; keyname:string): boolean;

    Function create_key(key_handle:hkey; key_name:string; var result_key:hkey):longint;
    function open_Key(key_handle:hkey; key_name:string; var result_hkey:hkey):longint;
    procedure close_key(var key_handle:hkey);
  end;

	{#########################################################################}

implementation
uses
  misclib;
const
//  BUFFER_SIZE=32767;
  KEY_SIZE=512;


{********************************************************************}
procedure Tregistry.set_boolean_value(key_handle:hkey; keyname:string; value:boolean);
begin
  if value then
    set_integer_value(key_handle, keyname, 1)
  else
    set_integer_value(key_handle, keyname, 0);
end;

{********************************************************************}
procedure Tregistry.set_integer_value(key_handle:hkey; keyname:string; value:integer);
begin
  set_value(key_handle, keyname, inttostr(value));
end;
  
{********************************************************************}
procedure Tregistry.set_value(key_handle:hkey; keyname, value:string);
var
    key_pchar, value_pchar:pchar;
begin
   key_pchar := StrAlloc(BUFSIZ);
   value_pchar := StrAlloc(BUFSIZ);

   strpcopy (key_pchar, keyname);
   strpcopy (value_pchar, value);
   RegSetValue(key_handle,key_pchar,REG_SZ,value_pchar,BUFSIZ-1);

   StrDispose(key_pchar);
   StrDispose(value_pchar);
end;

{********************************************************************}
Function Tregistry.query_integer_value(key_handle:hkey; keyname:string): integer;
begin
  query_integer_value := strtoint(query_value(key_handle, keyname,'0'));end;

{********************************************************************}
Function Tregistry.query_boolean_value(key_handle:hkey; keyname:string): boolean;
begin
   query_boolean_value := ( query_integer_value(key_handle, keyname) = 1);
end;

{********************************************************************}
Function Tregistry.query_value(key_handle:hkey; keyname,default:string): string;
var
  key_pchar, value_pchar:pchar;
  reg_result:longint;
  cb_size :longint;
begin
   key_pchar := StrAlloc(BUFSIZ);
   value_pchar := StrAlloc(BUFSIZ);

   strpcopy (key_pchar, keyname);
   cb_size := BUFSIZ-1;
   reg_result := RegQueryValue(key_handle,key_pchar,value_pchar,cb_size);
   if reg_result = ERROR_SUCCESS then
     query_value := strpas(value_pchar)
   else
     query_value := default;

   StrDispose(key_pchar);
   StrDispose(value_pchar);
end;

{********************************************************************}
Function Tregistry.create_key(key_handle:hkey; key_name:string; var result_key:hkey):longint;
var
    key_pchar:pchar;
begin
  result := Open_Key(key_handle, key_name, result_key);
  if result <> ERROR_SUCCESS then
  begin
    key_pchar := StrAlloc(BUFSIZ);
    strpcopy (key_pchar, key_name);
    result := regCreateKey(key_handle,key_pchar,result_key);
    StrDispose(key_pchar);
  end;
end;


{********************************************************************}
function Tregistry.open_Key(key_handle:hkey; key_name:string; var result_hkey:hkey):longint;
var
    key_pchar:pchar;
begin
   key_pchar := StrAlloc(BUFSIZ);

   strpcopy (key_pchar, key_name);
	 result := RegOpenKey(key_handle, key_pchar, result_hkey);
   StrDispose(key_pchar);
end;

{********************************************************************}
procedure Tregistry.close_key(var key_handle:hkey);
begin
  RegCloseKey(key_handle);
  key_handle := 0;
end;



end.
 