unit sparseobjlist;

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
(* $Header: /PAGLIS/classes/sparseobjlist.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//


//this class will be redundant when sparselist removes all pointers
interface
uses classes,sparselist,objtree;

type
	TsparseObjList = class(TsparseList)
	end;


implementation


	//###########################################################
	(*
		$History: sparseobjlist.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/classes
 * 
 * *****************  Version 7  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/classes
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 6  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
 * 
 * *****************  Version 5  *****************
 * User: Sunil		  Date: 1/05/03    Time: 11:17p
 * Updated in $/paglis/classes
 * removed pointers from sparselist
 * 
 * *****************  Version 4  *****************
 * User: Sunil		  Date: 1/03/03    Time: 5:44p
 * Updated in $/paglis/classes
 * renamed to be sparseobjlist
	 *
	 * *****************  Version 3  *****************
	 * User: Sunil 	   Date: 1/03/03	Time: 5:37p
	 * Updated in $/paglis/classes
	 * added sourcesafe headers
	*)
end.

