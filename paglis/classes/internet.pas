unit internet;

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
(* $Header: /PAGLIS/classes/internet.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//
interface

type
	TMiscInternet = class
	public
		function IsConnectedToInternet(psUrl:string): Boolean;
		function get(psUrl:string): string; overload;
		function get(psUrl:string; psQueryString: string): string; overload;
		function encode(psString: string): string;
	end;

	TUrl = class
	public
		protocol, host, port: string;
		constructor create(psUrl:string);
	end;


implementation
uses
	types, wininet, misclib, miscstrings, idhttp, idexception, nmurl;


//*****************************************************************************
constructor TUrl.create(psUrl:string);
begin
	inherited create;
end;

//*****************************************************************************
function TMiscInternet.IsConnectedToInternet(psUrl:string): Boolean;
var
  dwConnectionTypes: DWORD;
  bConnected: boolean;
  ohttp: TIdHTTP;
  sResponse:string;
begin
	// first check the basics
	dwConnectionTypes :=
		INTERNET_CONNECTION_MODEM +
		INTERNET_CONNECTION_LAN +
		INTERNET_CONNECTION_PROXY;
	bConnected := InternetGetConnectedState(@dwConnectionTypes, 0);

	//now attempt to get the url - if we get something thats good
	if bConnected then 	begin
		ohttp := TIdHTTP.Create(nil);
		try
			try
				sResponse := ohttp.Get(psUrl)
			except
			   on Eidexception do  bconnected := false;
			end;
		finally
			ohttp.Free;
		end;
	end;

	result := bConnected;
end;

//*****************************************************************************
function TMiscInternet.get(psUrl:string): string;
var
	ohttp: tidhttp;
	sResponse:string;
begin
	ohttp := TIdHTTP.Create(nil);
	try
		sResponse := ohttp.Get(psUrl);
	finally
		ohttp.Free;
	end;
	result := sresponse;
end;

//*****************************************************************************
function TMiscInternet.get(psUrl:string; psQueryString: string): string;
var
	sUrl: string;
begin
	surl := psUrl + '?' + psQueryString;
	result := get(surl)
end;

//*****************************************************************************
function TMiscInternet.encode(psString: string): string;
var
	oencoder: tnmurl;
	sEncoded: string;
begin
	oencoder := tnmurl.Create(nil);
	try
		oencoder.InputString := psString;
		sEncoded := oencoder.Encode;
	finally
		oencoder.Free;
	end;
	result := sencoded;
end;

end.
