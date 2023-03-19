unit Buffered;
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
uses
	classes;

Type
	TBufferedFileStream = Class(TmemoryStream)
	public
		constructor Create(const FileName: string);
	end;

implementation
	//to be implemented

	constructor TBufferedFileStream.Create(const FileName: string);
	begin
      inherited create;
		LoadFromFile(FileName);
	end;

end.

