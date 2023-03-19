unit Main;

(*	  Copyright 1996,1997,1998 Sunil Gupta - sunil@magnetic.demon.co.uk *)

interface

uses
	lotseq, Bublehnt, Helper, Shwrchck, ExtCtrls, StdCtrls, Buttons, Ticket,
	Ballrack, Classes, Controls, Retained, Machine,
	lottpref, forms, comctrls, language, Tranbtn;
type
	Tfrm_picker = class(TForm)
		pnl_status: TPanel;
		timer_flasher: TTimer;
		LotteryMachine1: TLotteryMachine;
		BallRack1: TBallRack;
		ticket_receiving: TLotteryTicket;
		ticket_serving: TLotteryTicket;
		SharewareChecker1: TSharewareChecker;
		BubbleHint1: TBubbleHint;
		Localiser1: TLocaliser;
		MTranBtn1: TMTranBtn;
		btn_options: TMTranBtn;
		btn_about: TMTranBtn;
		btn_go: TMTranBtn;
    	HtmlHelp1: THtmlHelp;

		procedure btn_goClick(Sender: TObject);
		procedure LotteryMachine1SelectStart(Sender: TObject);
		procedure LotteryMachine1SelectFinish(Sender: TObject);
		procedure btn_aboutClick(Sender: TObject);
		procedure FormCreate(Sender: TObject);
		procedure timer_flasherTimer(Sender: TObject);
		procedure btn_quitClick(Sender: TObject);
		procedure btn_optionsClick(Sender: TObject);
		procedure FormDestroy(Sender: TObject);
		procedure BallRack1SortingStarted(Sender: TObject);
		procedure BallRack1SortingFinished(Sender: TObject);
		procedure FormActivate(Sender: TObject);
		procedure BallRack1Click(Sender: TObject);
		procedure updo_angleClick(Sender: TObject; Button: TUDBtnType);
		procedure LotteryMachine1ReleaseAngleChanged(Sender: TObject);
		procedure LotteryMachine1SequenceIncomplete(Sender: TObject);
		procedure LotteryMachine1AllBallsDropped(Sender: TObject);
		procedure LotteryMachine1SelectSequence(seq_number: Byte; seq_obj: TLotterySequence);
    	procedure LotteryMachine1BallEjected(Sender: TObject);
		procedure LotteryMachine1BallDropped(ball_num: Integer);
		procedure LotteryMachine1BallReactivated(ball_num: Integer);
		procedure LotteryMachine1SelectBall(ball_num: Integer);
    procedure BallRack1AddingFinished(Sender: TObject);
	private
		{ Private declarations }
		GO_CAPTION:string;
		STOP_CAPTION:string;
		M_button_state:Boolean;
		m_shown:boolean;
		m_picker_is_mute:boolean;
		M_prefs: TLotteryPrefs;
		m_times_run: integer;
		m_wait_for_ballrack_to_finish: boolean;
		m_selecting : boolean;

		procedure pr_initialise_custom_controls;
		procedure pr_remember_picked_numbers;
		procedure pr_start_go_button;
		procedure pr_make_a_sound(sound_file:string);
		procedure pr_on_finished_picking;
		procedure pr_start_picking; overload;
		procedure pr_start_picking(first_time:boolean); overload;
		procedure pr_remove_picked_numbers_from_prefs;
		procedure pr_updateCaption(p_status: Tregisterresult);
	public
	  { Public declarations }
	end;

var
	frm_picker: Tfrm_picker;

implementation

uses
	dialogs, clipbrd, sysutils, graphics,
	about,options, picked,
	misclib, misccrypt, miscencode, lottery, lottype,  globals, pickglob;

{$R *.DFM}
//*********************************************************************
procedure Tfrm_picker.btn_goClick(Sender: TObject);
begin
  if btn_go.caption = GO_CAPTION then
	 pr_start_picking
  else
	 begin
		pr_make_a_sound(PICKER_BARF_SOUND);
		pr_start_go_button;
	 end;
end;

//*********************************************************************
procedure Tfrm_picker.LotteryMachine1SelectStart(Sender: TObject);
begin
  pnl_status.caption := LocalString('#' +inttoStr(lotterymachine1.BallsToSelect) + '# Balls will be selected shortly');
  m_selecting := true;
  pr_make_a_sound(PICKER_PICKING_SOUND);
end;

//*********************************************************************
procedure Tfrm_picker.LotteryMachine1SelectFinish(Sender: TObject);
begin
	m_wait_for_ballrack_to_finish:= true;
end;

//*********************************************************************
procedure Tfrm_picker.pr_start_go_button;
begin
  ballrack1.mode := rmNone;
  lotterymachine1.running := false;
  btn_go.caption := GO_CAPTION;
  btn_go.BGColour := $00c7ffc4;
  pnl_status.caption := LocalString('Press "Go" to pick again');
  timer_flasher.enabled := true;
  btn_about.enabled := true;
  btn_options.enabled := true;
  m_selecting := false;
end;

//*********************************************************************

//*********************************************************************
procedure Tfrm_picker.FormCreate(Sender: TObject);
begin
  set_version(MAJOR_VERSION, MINOR_VERSION, LONG_PROGRAM_NAME, COPYRIGHT, URL);
  M_button_state := false;
  M_prefs := TLotteryPrefs.create;
  GO_CAPTION := LocalString('&Go');
  btn_go.Caption := GO_CAPTION;
  STOP_CAPTION := LocalString('&Stop');
  m_times_run:=0;
  m_selecting := false;
end;

//*********************************************************************
procedure Tfrm_picker.timer_flasherTimer(Sender: TObject);
begin
  if M_button_state then
  btn_go.font.color := clred
  else
  btn_go.font.color := clblack;

  M_button_state := not M_button_state;

end;

//*********************************************************************
procedure Tfrm_picker.btn_quitClick(Sender: TObject);
begin
  m_prefs.save_prefs(M_prefs.Profile);
	{release;}
  application.terminate;
  tmisclib.processmessages;
end;

//*********************************************************************
procedure Tfrm_picker.btn_aboutClick(Sender: TObject);
begin
  btn_about.Enabled := false;
  timer_flasher.enabled := false;
  if not assigned(AboutBox) then
	  Application.CreateForm(TAboutBox, AboutBox);
  Aboutbox.ShowModal;

  with sharewarechecker1 do  begin
	 SuccessAlert := false;
	 pr_updateCaption(check_registered);
  end;

  timer_flasher.enabled := true;
  btn_about.Enabled := true;
end;

//*********************************************************************
procedure Tfrm_picker.btn_optionsClick(Sender: TObject);
begin
  btn_options.Enabled := false;

  timer_flasher.enabled := false;
  if not assigned(frm_options) then
	  Application.CreateForm(Tfrm_options, frm_options);
  frm_options.ShowModal;

{---------- load prefs from disk -----------------}
  m_prefs.load_prefs(m_prefs.CurrentProfile);
  pr_initialise_custom_controls;

  {turn on cute flashing button text}
  timer_flasher.enabled := true;
  btn_options.Enabled := true ;
end;

//*********************************************************************
procedure Tfrm_picker.pr_initialise_custom_controls;
var
  space_below:integer;
begin
  {----------------get preferences-----------------------}
	m_picker_is_mute := m_prefs.mute;

  {---------------------set ticket properties ----------}
  ticket_receiving.init_from_prefs(m_prefs);
  if m_prefs.rendered then ticket_receiving.Style := LtsMarkedRendered;
  ticket_serving.init_from_prefs(m_prefs);
  ballrack1.init_from_prefs(m_prefs);
  lotterymachine1.init_from_prefs(m_prefs);

  {--------------------------------------------------------}
  {resize form if neccessary}
  space_below := clientheight - ticket_receiving.height - ticket_receiving.top - pnl_status.height;
  if space_below < ticket_receiving.top then
  begin
	  clientheight := ticket_receiving.height + (2*ticket_receiving.top) + pnl_status.height;
	  ballrack1.top := pnl_status.top  - ballrack1.height - 10;
  end;
end;


//*********************************************************************
procedure Tfrm_picker.FormDestroy(Sender: TObject);
begin
  timer_flasher.enabled := false;
  ballrack1.stop;
  lotterymachine1.stop;

  tmisclib.processmessages;
  tmisclib.stop_wav;
  if assigned(m_prefs) then m_prefs.free;
end;

//*********************************************************************
procedure Tfrm_picker.BallRack1SortingStarted(Sender: TObject);
begin
  pnl_status.caption := LocalString('Sorting numbers');
end;

//*********************************************************************
procedure Tfrm_picker.BallRack1SortingFinished(Sender: TObject);
begin
	pr_on_finished_picking;
end;

//*********************************************************************
procedure Tfrm_picker.pr_updateCaption(p_status: Tregisterresult);
begin
	case p_status of
		RegNo:
			self.Caption := localstring('Number Picker - [unregistered]');
		RegFree:
			self.Caption := localstring('Free license - happy days');
		RegYes:
			self.Caption := localstring('Number Picker - [registered to #' +  sharewarechecker1.RegisteredTo + '#]');
	end;
end;

//*********************************************************************
procedure Tfrm_picker.FormActivate(Sender: TObject);
var
  status:Tregisterresult;
begin
  if m_shown then exit;

  {------------check whether program has expired---------------}
  with sharewarechecker1 do
  begin
	 ProgramName := PROGRAM_NAME;
	 key := g_misccrypt.get_standard_cipherkey(programname);
	 SuccessAlert := false;
	 status:=check_registered;
	 if status in [regExpired, reghacked, RegHackedSerial] then begin
		AboutBox.showmodal;
		read_data(true);
		status:=check_registered;
		if status in [regExpired, reghacked,RegHackedSerial] then
		  application.terminate;
	 end;
	 pr_updateCaption(status);
  end;

	{------------use picker preferences---------------------}
	m_prefs.load_prefs(m_prefs.Profile);
	lotterymachine1.releaseangle := m_prefs.angle;
	pr_initialise_custom_controls;

  m_shown := true;
end;

//*********************************************************************

//*********************************************************************
procedure Tfrm_picker.pr_make_a_sound(sound_file:string);
begin
  if not m_picker_is_mute then
	tmisclib.play_wav(sound_file);
end;

//*********************************************************************
procedure Tfrm_picker.BallRack1Click(Sender: TObject);
var
  slot:integer;
  ball:LottoBall;
  copy_string: string;
begin

	if LotteryMachine1.Running then begin
		if not m_selecting then
			pnl_status.Caption := LocalString('Please wait until I tell you balls will be selected shortly!!!!')
		else
			LotteryMachine1.pick_now;
		exit;
	end else if ballrack1.mode <> rmNone then  begin
		pnl_status.caption := LocalString('I''m Busy !!!!');
		exit;
	end;


	//-----------if machine is not running copy numbers to clilpboard --------
	copy_string := '';
	for slot := 1 to BallRack1.nslots do begin
		ball := BallRack1.ballat[slot];
		if ball = INVALID_LOTTERY_NUMBER then continue;
		if copy_string <> '' then copy_string := copy_string + ', ';
		copy_string := copy_string + inttostr(ball);
	end;

	if copy_string = '' then
		pnl_status.caption := LocalString('No numbers picked yet!!!!')
	else  begin
		clipboard.clear;
		clipboard.astext := copy_string;
	  	pnl_status.caption := LocalString('numbers (#' + copy_string +'#) copied to paste buffer');
	end;

end;

//*********************************************************************
procedure Tfrm_picker.updo_angleClick(Sender: TObject; Button: TUDBtnType);
var
  old_angle: byte;
begin

  old_angle := lotterymachine1.releaseangle;

  if (Button = btNext) then
	  inc(old_angle)
  else
	  dec(old_angle);

  lotterymachine1.ReleaseAngle := old_angle;
  m_prefs.angle := lotterymachine1.releaseangle;
end;

//*********************************************************************
procedure Tfrm_picker.LotteryMachine1ReleaseAngleChanged(Sender: TObject);
begin
  m_prefs.angle := lotterymachine1.releaseangle;
end;


//*********************************************************************
procedure Tfrm_picker.LotteryMachine1SequenceIncomplete(Sender: TObject);
begin
  pnl_status.caption := LocalString('End of sequences reached.. too soon, continuing to pick numbers');
end;

//*********************************************************************
procedure Tfrm_picker.LotteryMachine1AllBallsDropped(Sender: TObject);
begin
  pnl_status.caption := LocalString('All available balls have been dropped. Getting ready to pick.');
end;

//*********************************************************************
procedure Tfrm_picker.LotteryMachine1SelectSequence(seq_number: Byte;
  seq_obj: TLotterySequence);
begin
  pnl_status.caption := LocalString('Sequence #' + seq_obj.seq_name + ' - ' + inttoStr(seq_number) + '# initiated');
end;

//*********************************************************************
//*********************************************************************
procedure Tfrm_picker.pr_remember_picked_numbers;
var
	index:integer;
	ball_number:LottoBall;
begin

	if not frmPicked.visible then
	begin
	  frmPicked.show;
	  frmPicked.width := width;
	  frmPicked.top := top + height;
	  frmPicked.left := left;
	end;
	frmPicked.rendered := M_prefs.rendered;

	inc(m_times_run);
	frmpicked.ballGrid1.RowCount := m_times_run;
	frmpicked.ballGrid1.colCount := BallRack1.nslots;
	frmpicked.ballGrid1.row := m_times_run-1;
	for index := 1 to BallRack1.nslots do
  begin
	ball_number := ballrack1.ballat[index];
		frmpicked.ballGrid1.cells[index-1,m_times_run-1] := inttostr(ball_number);
  end
end;

//*********************************************************************
procedure Tfrm_picker.pr_on_finished_picking;
begin
	pr_make_a_sound(PICKER_FINISHED_SOUND);
	pr_remember_picked_numbers;

	if M_prefs.keep_picking then begin
		 pnl_status.caption := LocalString('continuing to pick numbers until you click on Stop');

         //checkthere are enough balls left if removing balls
		 if (m_prefs.remove_picked_balls) then begin
			pr_remove_picked_numbers_from_prefs;
			if m_prefs.how_many_in_play <= m_prefs.select then begin
				showmessage (LocalString('not enough balls left, stopping'));
				m_prefs.reinitialise_current;
				pr_start_go_button;
				exit;
			end;
         end;

         //get going again

		 pr_start_picking(false);
	  end
	else
		pr_start_go_button;
end;

//*********************************************************************
procedure Tfrm_picker.pr_start_picking;
begin
	pr_start_picking(true);
end;

//*********************************************************************
procedure Tfrm_picker.pr_start_picking(first_time:boolean);
begin
  btn_go.hint := LocalString('Stop the machine');
  timer_flasher.enabled := false;
  ticket_receiving.clear_marks;
  m_wait_for_ballrack_to_finish := false;
  m_selecting := false;

  pr_initialise_custom_controls;

  ballrack1.reset;

  btn_go.caption := STOP_CAPTION;
  btn_go.BGColour := $00CACAFF;

  btn_about.enabled := false;
  btn_options.enabled := false;
  if first_time then
	  pnl_status.caption := LocalString('Machine is warming up')+'.....';

  lotterymachine1.running := true;
  ballrack1.mode := rmSelecting;
end;

//*********************************************************************
procedure Tfrm_picker.pr_remove_picked_numbers_from_prefs;
var
	index:integer;
	ball:LottoBall;
begin
	//-------------------------------------------------
	for index := 1 to BallRack1.nslots do
	begin
		ball:= ballrack1.BallAt[index];
		m_prefs.currentInPlay.BoolValue[ball] := false;
	end;
	pnl_status.caption := LocalString('Removed picked numbers')+'.....';
end;


procedure Tfrm_picker.LotteryMachine1BallEjected(Sender: TObject);
begin
	pnl_status.caption := LocalString('ball selected ... please wait');
	pr_make_a_sound(PICKER_EJECT_SOUND);
end;

procedure Tfrm_picker.LotteryMachine1BallDropped(ball_num: Integer);
begin
	 ticket_serving.InPlay[ball_num] := false;
end;

procedure Tfrm_picker.LotteryMachine1BallReactivated(ball_num: Integer);
begin
		ticket_serving.InPlay[ball_num] := true;
end;

procedure Tfrm_picker.LotteryMachine1SelectBall(ball_num: Integer);
var
  mesg: string;
begin
  ticket_receiving.marked[ball_num] := true;
  Ballrack1.add_ball( ball_num);
  mesg := LocalString('Picked ball number #' + inttostr(ball_num) +'#');
  if (LotteryMachine1.BallsToSelect <> LotteryMachine1.BallsSelected) then
    mesg := mesg + ', ' + LocalString('still another #' + inttostr(LotteryMachine1.BallsToSelect - LotteryMachine1.BallsSelected) + '# to go');
  pnl_status.caption := mesg;
  pr_make_a_sound(PICKER_SELECT_SOUND);
end;

procedure Tfrm_picker.BallRack1AddingFinished(Sender: TObject);
begin
	if m_wait_for_ballrack_to_finish then
	begin
		BallRack1.mode := rmnone;
		m_wait_for_ballrack_to_finish := false;
		if M_prefs.sorted then
			BallRack1.sort
		else
			pr_on_finished_picking;
	end;
end;

end.
