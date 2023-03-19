unit RealInt;

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
{
  speeds up floating point operations on numbers < 2^15
  converts real to long integer and subsequent integer
  operations retain the accuracy of a float, but using
  purely integer maths.
}

interface
  uses sysutils;

  type
    RealInteger = longint;

    E_RealIntegerError =
      class(Exception)
    end;

  function trunc_realint( val:RealInteger): integer;
  function to_RealInt( val:real): RealInteger;
  function int_to_RealInt( val:integer): RealInteger;
  function realint_to_real( val: realinteger): real;


implementation
  const
    TWO_POW_16 = 65536.0;
    INT_TWO_POW_16 = 65536;
    TWO_POW_15 = 32768.0;

    SHIFTBY = 15;

  {* ----------------------------------------------------------- *}
  function int_to_RealInt( val:integer): RealInteger;
  var
    intermediate: realinteger;
  begin
    if val > INT_TWO_POW_16 then
      raise E_RealIntegerError.Create('value too big for RealInteger')
    else
      begin
        intermediate := val;
        result := intermediate shl SHIFTBY;
      end;
  end;

  {* ----------------------------------------------------------- *}
  function to_RealInt( val:real): RealInteger;
  begin
    if val > TWO_POW_16 then
      raise E_RealIntegerError.Create('value too big for RealInteger')
    else
      result := trunc(val * TWO_POW_15);
  end;

  {* ----------------------------------------------------------- *}
  function trunc_realint( val:RealInteger): integer;
  begin
      result := val shr SHIFTBY;
  end;

  {* ----------------------------------------------------------- *}
  function realint_to_real( val: realinteger): real;
  begin
      result := val / TWO_POW_15;
  end;

end.

