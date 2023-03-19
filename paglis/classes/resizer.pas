unit resizer;
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
	controls, contnrs, types, forms;
type
	RRectAndAssociated = record
		rect: Trect;
		Associated_control: Tcontrol;
	end;

	TControlResizer = class
		public
			procedure resizeControl( poControl: Tcontrol; piWidth: integer);
			procedure resizeContainertoFitControls( poControl: Tcontrol);
		private
			function pr_check_overlapping_controls(poContainer: Tcontrol): integer; overload;
			function pr_check_overlapping_controls(poControls: TobjectList): integer; overload;
			function pr_getBoundsAndAssocControl(poControl: Tcontrol; poControls: TobjectList): RRectAndAssociated;
	end;

implementation
uses
	misclib, miscstrings, math, extctrls, comctrls, stdctrls;
const
	LABEL_PREFIX = 'lbl_';
	CONTROL_GAP = 2;

//********************************************************
function prLeftSortControls(Item1, Item2: Pointer):integer;
var
	control1, control2:tcontrol;
begin
	control1 := tcontrol(item1);
	control2 := tcontrol(item2);

	if control1.Left = control2.left then
		result := 0
	else
		begin
			if control1.Left > control2.Left then
				result := 1
			else
				result := -1;
		end;
end;

//***********************************************************
procedure TControlResizer.resizeControl(poControl: Tcontrol; piWidth: integer);
var
	oparent: Tcontrol;
begin
		//---------resize the control ----------------
	if pocontrol.ClientWidth <= piWidth then
		poControl.ClientWidth := piWidth;


	//---------- find parent and resize --------------
	oparent := poControl.parent;
	if oparent = nil then exit;

	//------ check overlapping controls in the parent
	pr_check_overlapping_controls(oparent);

	//caccade size change to parent
	resizeContainertoFitControls(oparent);
end;

//***********************************************************
procedure TControlResizer.resizeContainertoFitControls( poControl: Tcontrol);
var
	rect:trect;
	oControls:TObjectList;
	index, overall_width, diff: integer;
	oControl, oParent:Tcontrol;
begin
	if not g_misclib.is_Container(pocontrol) then exit;

	//---------get max size of controls------
	rect.Left := 0;
	rect.Top := 0;
	rect.Right := 0;
	rect.Bottom := 0;

	oControls := g_misclib.get_child_controls(poControl);
	for index := 1 to oControls.Count do
	begin
		oControl := tcontrol( oControls.Items[index-1]);
		UnionRect(rect,rect,oControl.BoundsRect);
	end;
	oControls.Free;
	overall_width := rect.Right;
	overall_width:= overall_width + (pocontrol.Width-poControl.ClientWidth);

	//---------jump tab sheets ----------------
	if poControl is TTabSheet then
	begin
		overall_width := overall_width + pocontrol.Parent.Width - pocontrol.Width;
		pocontrol := poControl.Parent;
	end;

	//---------resize the control ----------------
	if poControl.ClientWidth< overall_width then
	begin
		if poControl.Align in [alclient,albottom,altop] then
			begin
				diff := overall_width - poControl.ClientWidth;
				while poControl.Align in [alclient,albottom,altop] do
				begin
					diff := diff +  poControl.Width - poControl.ClientWidth ;
					poControl := poControl.Parent;
				end;
				poControl.Width := poControl.Width + diff;
			end
		else if	poControl.Align in [alright, alleft] then
			begin
				diff := overall_width - pocontrol.Width;
				pocontrol.Width := overall_width;
				pocontrol.Parent.Width := pocontrol.Parent.Width + diff;
			end
		else
			pocontrol.Width := overall_width;
	end;

	//---------- find parent and resize --------------
	oparent := poControl.parent;
	if oparent = nil then exit;

	resizeContainertoFitControls(oParent);

end;

//############################################################
function TControlResizer.pr_check_overlapping_controls(poControls: TobjectList): integer;
var
	control_index, next_control_index, right:integer;
	oControl, oNextControl: Tcontrol;
	rect1, rect2: RRectAndAssociated;
	tmp_rect:trect;
begin
	right := 0;

	for control_index :=1 to poControls.Count do
	begin
		ocontrol := tcontrol( poControls.Items[control_index-1]);
		if g_misclib.ControlisDecoration(ocontrol) then continue;

		rect1 := pr_getBoundsAndAssocControl(ocontrol, pocontrols);
		right := max(right, rect1.rect.Right);


		//check this control with next control
		for next_control_index := control_index+1 to poControls.Count do
		begin
			oNextControl := tcontrol( poControls.Items[next_control_index-1]);
			if g_misclib.ControlisDecoration(oNextControl) then continue;

			//dont process is associatecontrol is the next control
			if oNextControl = rect1.Associated_control then continue;

			//get the bounds
			rect2 := pr_getBoundsAndAssocControl(oNextControl,pocontrols);

			//does next control overlap - move it
			if IntersectRect(tmp_rect, rect1.rect,rect2.rect) then
			begin
				oNextControl.Left := rect1.rect.Right;
				if rect2.Associated_control <> nil then
					rect2.Associated_control.left := oNextControl.left;
			end;

			//update
			rect2 := pr_getBoundsAndAssocControl(oNextControl, pocontrols);
			right := max(right, rect2.rect.Right);
		end;
	end;

	result := right;
end;


//********************************************************
function TControlResizer.pr_check_overlapping_controls(poContainer: Tcontrol): integer;
var
	oControls: TobjectList;
begin
	result := poContainer.Width;

	if not g_misclib.is_Container(poContainer) then	exit;

	//------------------actually do it ------------------------
	oControls := g_misclib.get_child_controls(poContainer);
	if oControls.Count >0 then
	begin
		oControls.Sort(prLeftSortControls);
		result := pr_check_overlapping_controls(ocontrols);
	end;

	if oControls <> nil then  oControls.Free;
end;

//********************************************************
function TControlResizer.pr_getBoundsAndAssocControl(poControl: Tcontrol;poControls: TobjectList): RRectAndAssociated;
var
	rRect: RRectAndAssociated;
	controlname,assoccontrol_name: string;
	oAssocControl, ocontrol:tcontrol;
	index, left:integer;
	out_rect: trect;
begin
	//----------get rect
	rRect.rect := poControl.BoundsRect;
	rRect.Associated_control := nil;

	//--------- get associated control  name ------------
	controlname := poControl.Name;
	assoccontrol_name := '';
	if poControl is tlabel then
		begin
			if pos(LABEL_PREFIX,controlname) = 1 then
				assoccontrol_name := g_miscstrings.right_string(controlname, length(controlname) - length(LABEL_PREFIX));
		end
	else
		assoccontrol_name := LABEL_PREFIX + controlname;

	//-----------get associated control ---------------
	if assoccontrol_name <> '' then
	begin
		//-------get control ----------------------------
		oAssocControl := nil;
		for index := 1 to poControls.Count do
		begin
			ocontrol := tcontrol(poControls[index-1]);
			if ocontrol.Name = assoccontrol_name then
			begin
				oAssocControl := ocontrol;
				break;
			end;
		end;

		if oAssocControl <> nil then
		begin
			//-----if associate control not lined up, do so now.
			left := max( poControl.Left, oAssocControl.Left);
			poControl.left := left;
			oAssocControl.left := left;

			//-----adjust rect to include associated control
			unionrect(out_rect, pocontrol.boundsrect, oAssocControl.boundsrect);

			rRect.rect := out_rect;
			rRect.Associated_control :=  oAssocControl;
		end;
	end;

	//-----------all done ----------------------------
	rRect.rect.Right := rRect.rect.Right + CONTROL_GAP;
	result := rRect;
end;


//
//####################################################################
(*
	$History: resizer.pas $
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
 * User: Sunil        Date: 19-02-03   Time: 12:11p
 * Updated in $/code/paglis/classes
 * control resizing by resizer works well
 * 
 * *****************  Version 5  *****************
 * User: Sunil        Date: 19-02-03   Time: 12:38a
 * Updated in $/code/paglis/classes
 * checkpoint
 * 
 * *****************  Version 4  *****************
 * User: Sunil        Date: 18-02-03   Time: 6:33p
 * Updated in $/code/paglis/classes
 * checkpoint
 * 
 * *****************  Version 3  *****************
 * User: Sunil        Date: 18-02-03   Time: 1:26p
 * Updated in $/code/paglis/classes
 * moves controls and associated labels together
 *
 * *****************  Version 2  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/classes
 * added headers and footers
*)
//####################################################################
//
end.

