unit Vectors;
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

{#################################################################}
interface
uses windows, misclib;
type
	TSphere =
		record
			x,y,radius:Real;
		end;

	TVector =
		 record
			case integer of
				0: (i,j,k:real);
				1: (x,y,z:real);
		 end;


	TVectorFunctions = class
		public
			function magnitude(vec:TVector):Real;
			function magnitude_squared(vec:TVector):Real;
			function dot (vec1,vec2:TVector):Real;
			function cross (vec1,vec2:TVector):TVector;
			procedure normalise(var vec:TVector);
			function normal (vec:TVector):TVector;
			function new_vector(x,y,z:real):TVector;
			function vector_from_points(P1, p2:Tpoint):TVector;
			function copy(vec:TVector):TVector;
			function subtract(from, what:TVector):TVector;
			function add(vec1, vec2:TVector):TVector;
			function tangent(from:TVector): TVector;
			function reverse(vec:TVector):TVector;
			function multiply(vec:TVector; scale:real): TVector;
	end;


{#################################################################}
implementation

{******************************************************************
******************************************************************}
function TVectorFunctions.reverse(vec:TVector):TVector;
var
	out_vec:TVector;
begin
	out_vec.i:= -vec.i;
	out_vec.j:= -vec.j;
	out_vec.k:= -vec.k;

	result := out_vec;
end;

{******************************************************************
******************************************************************}
function TVectorFunctions.magnitude(vec:TVector):Real;
begin
	 result := sqrt( self.magnitude_squared(vec));
end;

{******************************************************************
******************************************************************}
function TVectorFunctions.magnitude_squared(vec:TVector):Real;
begin
	 result := (vec.i*vec.i) + (vec.j*vec.j) + (vec.k*vec.k);
end;

{******************************************************************
dot product of two vectors is also cosine of the angle between them
******************************************************************}
function TVectorFunctions.dot (vec1,vec2:TVector):Real;
begin
	result := (vec1.i * vec2.i) + (vec1.j *vec2.j) + (vec1.k *vec2.k);
end;

{******************************************************************
******************************************************************}
function TVectorFunctions.cross (vec1,vec2:TVector):TVector;
begin
	cross.i := (vec1.j*vec2.k) - (vec1.k*vec2.j);
	cross.j := (vec1.k*vec2.i) - (vec1.i*vec2.k);
	cross.k := (vec1.i*vec2.j) - (vec1.j*vec2.i);
end;

{******************************************************************
******************************************************************}
function TVectorFunctions.normal (vec:TVector):TVector;
var
	out_vec:TVector;
begin
	out_vec := self.copy(vec);
	normalise(out_vec);
	result := out_vec;
end;

{******************************************************************
******************************************************************}
procedure TVectorFunctions.normalise(var vec:TVector);
var
	mag:real;
begin
	mag := self.magnitude(vec);
	vec.i:= vec.i/mag;
	vec.j:= vec.j/mag;
	vec.k:= vec.k/mag;
end;

{******************************************************************
******************************************************************}
function TVectorFunctions.new_vector(x,y,z:real):TVector;
var
	out_vec:TVector;
begin
	out_vec.i:= x;
	out_vec.j:= y;
	out_vec.k:= z;

	result := out_vec;
end;

{******************************************************************
******************************************************************}
function TVectorFunctions.copy(vec:TVector):TVector;
var
	out_vec:TVector;
begin
	out_vec.i:= vec.i;
	out_vec.j:= vec.j;
	out_vec.k:= vec.k;

	result := out_vec;
end;

{******************************************************************
******************************************************************}
function TVectorFunctions.subtract(from, what:TVector):TVector;
var
	out_vec:TVector;
begin
	out_vec.i := from.i - what.i;
	out_vec.j := from.j - what.j;
	out_vec.k := from.k - what.k;

	result := out_vec;
end;

{******************************************************************
******************************************************************}
function TVectorFunctions.add(vec1, vec2:TVector):TVector;
var
	out_vec:TVector;
begin
	out_vec.i := vec1.i + vec2.i;
	out_vec.j := vec1.j + vec2.j;
	out_vec.k := vec1.k + vec2.k;

	result := out_vec;
end;

{******************************************************************
******************************************************************}
function TVectorFunctions.tangent(from:TVector): TVector;
var
	out_vec:TVector;
	old_x:real;
begin
	out_vec := self.copy(from);
	with out_vec  do
	begin
		old_x := x;
		x := y;
		y := -old_x;
	end;

	result := out_vec;
end;


{******************************************************************
******************************************************************}
function TVectorFunctions.multiply(vec:TVector; scale:real): TVector;
var
	out_vec: TVector;
begin
	out_vec.x := vec.x * scale;
	out_vec.y := vec.y * scale;
	out_vec.z := vec.z * scale;

	result := out_vec;
end;

{******************************************************************
******************************************************************}
function TVectorFunctions.vector_from_points(P1, p2:Tpoint):TVector;
var
	out_vec:TVector;
begin
	with out_vec do
	begin
		x := p2.x - p1.x;
		y := p2.y - p1.y;
		z := 0;
	end;
	Result := out_vec;
end;

end.
