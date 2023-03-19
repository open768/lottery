unit transform;

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
interface
uses
	misclib, dialogs;

type
	TTransform = class
		private
			m_matrix :array[1..2,1..2] of double;
			m_origin: TIntPoint;
		public
			reversed: boolean;

			constructor create;
			procedure init_degrees( angle:integer);
			procedure init_radians( angle:double);
			procedure init_sin_cos(s,c:double);
			procedure move_origin_to(apoint:TIntPoint);

			function convert(x,y:integer):TIntPoint;
			function convert_point( aPoint:TIntPoint): TIntPoint;
			procedure test;
	end;

implementation

	//********************************************************************
	constructor TTransform.create;
	begin
		m_origin.x := 0;
		m_origin.y := 0;
		reversed := false;
	end;

	//********************************************************************
	procedure TTransform.init_degrees( angle:integer);
	var
		radians: double;
	begin
		radians := (2.0 * PI * angle)/360.0;
		init_radians(radians);
	end;

	//********************************************************************
	procedure TTransform.init_radians( angle:double);
	var
		s,c: double;
	begin
		s := sin(angle);
		c := cos(angle);
		init_sin_cos(s,c);
	end;

	//********************************************************************
	procedure TTransform.init_sin_cos(s,c:double);
	begin
		m_matrix[1,1] := c;
		m_matrix[2,2] := c;
		if (reversed) then
			begin
				m_matrix[1,2]:= s;
				m_matrix[2,1]:= -s;
			end
		else
			begin
				m_matrix[1,2]:= -s;
				m_matrix[2,1]:= s;
			end
	end;

	//********************************************************************
	function TTransform.convert_point( aPoint:TIntPoint): TIntPoint;
	begin
		result := convert(apoint.x,apoint.y);
	end;

	//********************************************************************
	function TTransform.convert(x,y:integer):TIntPoint;
	var
		retval: TIntPoint;
	begin

		if not reversed then
		begin
			x := x - m_origin.x;
			y := y - m_origin.y;
		end;

		retval.x := round((m_matrix[1,1] * x) + (m_matrix[2,1] * y) );
		retval.y := round((m_matrix[1,2] * x) + (m_matrix[2,2] * y) );

		if reversed then
		begin
			retval.x := retval.x + m_origin.x;
			retval.y := retval.y + m_origin.y;
		end;

		result := retval;
	end;

	//********************************************************************
	procedure TTransform.move_origin_to(apoint:TIntPoint);
	begin
		m_origin.x := - apoint.x;
		m_origin.y := - apoint.y;
	end;


	//####################################################################
	//		TESTING
	//####################################################################
	procedure TTransform.test;
	var
		angle,x1,y1: integer;
		forward_trans, reverse_trans: TTransform;
		p1,p2: tIntpoint;
	begin
		angle := round( 360 * random);
		x1 := round( 1000 * random);
		y1 := round( 1000 * random);

		forward_trans := TTransform.create;
		forward_trans.init_degrees(angle);
		reverse_trans := TTransform.create;
		reverse_trans.reversed := true;
		reverse_trans.init_degrees(angle);

		p1 := forward_trans.convert(x1,y1);
		p2 := reverse_trans.convert(p1.x,p1.y);

		forward_trans.free;
		reverse_trans.free;

		if ((x1 <> p2.x) or (y1 <> p2.y)) then
			showmessage('**** Transform failed ****')
		else
			showmessage('Transform OK');

	end;

end.
 