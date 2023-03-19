unit MemInfo;
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
(* $Header: /PAGLIS/controls/MemInfo.pas 1     14/02/05 22:16 Sunil $ *)
//****************************************************************
//


interface

uses
	Windows, classes, extctrls;
type
	TMemInfo = class(Tcomponent)
	private
	  { Private declarations }
	  m_mem_data: memorystatus;
	  m_last_checked: tdatetime;
	  F_Updated: TNotifyEvent;
	  f_time_interval: byte;
	  f_auto_Update : boolean;
	  m_timer: TTimer;
	  
	  procedure notify_updated;
	  procedure set_auto_update(value: boolean);
	  procedure onTick(Sender: TObject);

	  function get_memory_Load: dword;
	  function get_total_physical: dword;
	  function get_avail_physical: dword;
	  function get_total_page_file: dword;
	  function get_avail_page_file: dword;
	  function get_total_virtual: dword;
	  function get_avail_virtual: dword;
	protected
	  { Protected declarations }
	public
	  { Public declarations }
	  constructor Create(AOwner: Tcomponent); override;
	  destructor Destroy; override;
	  procedure update; overload;
	  procedure update(force: boolean); overload;
	published
	  { Published declarations }
	  property MemoryLoad: dword  read get_memory_Load;			// percent of memory in use
	  property TotalPhysical: dword  read get_total_physical; // bytes of physical memory
	  property AvailPhysical: dword  read get_avail_physical;	   // free physical memory bytes
	  property TotalPageFile: dword  read get_total_page_file; // bytes of paging file
	  property AvailPageFile: dword  read get_avail_page_file; // free bytes of paging file
	  property TotalVirtual:		dword  read get_total_virtual;  // user bytes of address space
	  property AvailVirtual:		dword  read get_avail_virtual;  // free user bytes
	  property TimeInterval: byte read f_time_interval write f_time_interval;
	  property AutoUpdate: Boolean read f_auto_update write set_auto_update;
	  property OnUpdated: TNotifyEvent read F_Updated write F_Updated;
	end;

procedure Register;

implementation
uses sysutils;

//#######################################################
//#
//#######################################################
procedure Register;
begin
	RegisterComponents('Paglis', [TMemInfo]);
end;

//#######################################################
//#
//#######################################################
constructor TMemInfo.Create(AOwner: Tcomponent);
begin
	inherited create(AOwner);
	m_last_checked := 0;
	f_time_interval := 5;				// default to 5 secs between checking.
	f_auto_Update := false;
	F_Updated := nil;
	m_timer := nil;
end;

destructor TMemInfo.Destroy;
begin
	inherited Destroy;
	if assigned(	m_timer ) then
	begin
		m_timer.enabled := false;
		m_timer.free;
	end;
end;

procedure TMemInfo.onTick(Sender: TObject);
begin
	m_timer.enabled := false;
	update;
	m_timer.enabled := true;
end;


//**************************************************
procedure TMemInfo.notify_updated;
begin
	if assigned(F_Updated) then
		F_Updated(self);
end;

//#######################################################
//#
//#######################################################
procedure TMemInfo.update;
begin
	update(false);
end;

procedure TMemInfo.update(force:boolean);
var
	needs_checking: Boolean;
	timenow, difftime: Tdatetime;
	n_secs: real;
begin
	timenow := now;
	needs_checking := force or (m_last_checked = 0) ;
	
	if not needs_checking then
	begin
		difftime := timenow - m_last_checked;
		n_secs := frac(difftime) * 24 * 60 * 60;
		needs_checking := (n_secs >= f_time_interval);
	end;

	if needs_checking then
	begin
		m_mem_data.dwLength :=0;
		GlobalMemoryStatus(m_mem_data);
		m_last_checked := 	timenow;
		notify_updated;
	end;
end;

//#######################################################
//#
//#######################################################
function TMemInfo.get_memory_Load: dword;
begin
	update;
	result := m_mem_data.dwMemoryLoad;
end;

//**************************************************
function TMemInfo.get_total_physical: dword;
begin
	update;
	result := m_mem_data.dwTotalPhys;
end;

//**************************************************
function TMemInfo.get_avail_physical: dword;
begin
	update;
	result := m_mem_data.dwAvailPhys;
end;

//**************************************************
function TMemInfo.get_total_page_file: dword;
begin
	update;
	result := m_mem_data.dwTotalPageFile;
end;

//**************************************************
function TMemInfo.get_avail_page_file: dword;
begin
	update;
	result := m_mem_data.dwAvailPageFile;
end;

//**************************************************
function TMemInfo.get_total_virtual: dword;
begin
	update;
	result := m_mem_data.dwTotalVirtual;
end;

//**************************************************
function TMemInfo.get_avail_virtual: dword;
begin
	update;
	result := m_mem_data.dwAvailVirtual;
end;

//**************************************************
procedure TMemInfo.set_auto_update(value: boolean);
begin
	if value = f_auto_Update then exit;

	f_auto_Update := value;
	if (csDesigning in ComponentState) then exit;
	
	if not f_auto_Update then
		m_timer.enabled := false
	else
		begin
			if not assigned(m_timer) then m_timer := TTimer.create(Owner);
			m_timer.Interval := f_time_interval;
			m_timer.OnTimer := OnTick;
			m_timer.enabled := true;
		end;

end;


//
//####################################################################
(*
	$History: MemInfo.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/controls
 * 
 * *****************  Version 3  *****************
 * User: Administrator Date: 13/01/05   Time: 11:50p
 * Updated in $/code/paglis/controls
 * added copyright headers giving a free license for non commercial use
 * 
 * *****************  Version 2  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/controls
 * added headers and footers
*)
//####################################################################
//
end.

