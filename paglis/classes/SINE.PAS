unit Sine;
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

{**************************************************************}
interface
uses
  misclib;

  procedure clear_sine_cache;
  function the_sine(degree:real): real;
  function the_cos(degree:real): real;

{**************************************************************}
implementation
const
  BAD_VALUE=-10.0;
var
  sine_cache : array [0..360] of real;
  cos_cache : array [0..360] of real;

{-------------------------------------------------------------}
procedure clear_sine_cache;
var
  angle:word;
begin
  for angle := 0 to 360 do
  begin
    sine_cache[angle] := BAD_VALUE;
    cos_cache[angle] := BAD_VALUE;
  end;
end;

{-------------------------------------------------------------}
function the_sine(degree:real): real;
var
  nearest_degree: integer;
  outval:real;
begin
  nearest_degree:= trunc(degree) mod 361;
  outval := sine_cache[nearest_degree];

  if outval = BAD_VALUE then
  begin
    sine_cache[nearest_degree] := sin(degree *3.124/180);
    outval := sine_cache[nearest_degree];
  end;

  result := outval;
end;

{-------------------------------------------------------------}
function the_cos(degree:real): real;
var
  nearest_degree: integer;
  outval:real;
begin
  nearest_degree:= trunc(degree) mod 361;
  outval := cos_cache[nearest_degree];

  if outval = BAD_VALUE then
  begin
    cos_cache[nearest_degree] := cos(degree *3.124/180);
    outval := cos_cache[nearest_degree];
  end;

  result := outval;
end;

end.
