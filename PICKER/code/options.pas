unit options;

//
//****************************************************************
//* Copyright 2003 Paglis Software
//*
//* This copyright notice must be maintained on this source file
//* and all subsequent modified versions. 
//* 
//* This source code is the intellectual property of 
//* Paglis Software and protected by Intellectual and 
//* international copyright Law.
//*
//* Contact  http://www.paglis.co.uk/
//*
(* $Header: F:\sunil\projects\cvs/DELPHI/projects/LOTTERY/PICKER/code/options.pas,v 1.9 2008/08/01 22:28:07 sunil Exp $ *)
//****************************************************************
//
interface

uses
	ComCtrls, Shwrchck, StdCtrls, Ticket, Retained, Rolonum, Controls,
	 ExtCtrls, Tabnotbk, Classes, Buttons,
	forms, dialogs, lottpref, language, Tranbtn, Shape2, Helper, PaglisTrackBar;


type                  
  Tfrm_options = class(TForm)
    SharewareChecker1: TSharewareChecker;
    Localiser1: TLocaliser;
    page_selection: TPageControl;
	Selection: TTabSheet;
	Options: TTabSheet;
    TAB_Sequences: TTabSheet;
    chk_rendered: TCheckBox;
    chk_sorted: TCheckBox;
    chk_random_kick: TCheckBox;
    chk_mute: TCheckBox;
    chk_show_numbers: TCheckBox;
	Label5: TLabel;
    Label6: TLabel;
    ticket_selection: TLotteryTicket;
	txt_num: TEdit;
    lbl_no: TLabel;
    chk_keep_picking: TCheckBox;
    chk_remove_picked_balls: TCheckBox;
    Panel1: TPanel;
    btn_reset: TMTranBtn;
    MTranBtn1: TMTranBtn;
    Panel3: TPanel;
	lbl_lstHowMany: TLabel;
	lbl_lstType: TLabel;
    lbl_chk_seq_Reuse: TLabel;
    lbl_txt_seq_name: TLabel;
    lbl_chk_seq_sort: TLabel;
    lstHowMany: TComboBox;
    lstType: TComboBox;
    chk_seq_Reuse: TCheckBox;
    txt_seq_name: TEdit;
    chk_seq_sort: TCheckBox;
    ticket_sequences: TLotteryTicket;
    lbl_copyseq: TLabel;
    Panel2: TPanel;
    btnDelete: TBitBtn;
    lstRulez: TListBox;
    btnAdd: TButton;
    btn_replace: TButton;
    chk_sequences: TCheckBox;
    btn_cancel: TMTranBtn;
    btn_evens: TMTranBtn;
	btn_odds: TMTranBtn;
    btn_all: TMTranBtn;
    btn_min: TMTranBtn;
    btn_max: TMTranBtn;
    Panel4: TPanel;
    lbl_machine_cols: TLabel;
    Panel5: TPanel;
	lst_dropstyle: TComboBox;
    Panel7: TPanel;
    chk_backdrop: TCheckBox;
    Panel8: TPanel;
    Label7: TLabel;
    lst_language: TComboBox;
	Label2: TLabel;
	txt_bg_folder: TEdit;
    btn_img_folder: TMTranBtn;
    Label3: TLabel;
    Label4: TLabel;
    Label8: TLabel;
    Label1: TLabel;
    chk_pick_when_dropped: TCheckBox;
	chk_include_zero: TCheckBox;
    Label9: TLabel;
    Panel6: TPanel;
    btn_save_prefs: TMTranBtn;
    lst_profiles: TComboBox;
    track_ticket_columns: TPaglisTrackBar;
    track_anim_interval: TPaglisTrackBar;
    track_ball_size: TPaglisTrackBar;
    track_gap_after_selection: TPaglisTrackBar;
    track_pick_window: TPaglisTrackBar;
    track_upto: TPaglisTrackBar;
    track_machine_columns: TPaglisTrackBar;
    track_image_speed: TPaglisTrackBar;
    track_select: TPaglisTrackBar;
    lblGravity: TLabel;
    track_gravity: TPaglisTrackBar;
    chk_randomness: TCheckBox;
    procedure btn_okClick(Sender: TObject);
    procedure btn_resetClick(Sender: TObject);
    procedure ticket_selectionClick(number: Byte; bonus:boolean);
    procedure btn_evensClick(Sender: TObject);
    procedure btn_oddsClick(Sender: TObject);
    procedure btn_minClick(Sender: TObject);
    procedure btn_maxClick(Sender: TObject);
	procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormActivate(Sender: TObject);
    procedure chk_renderedClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure chk_include_zeroClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
	procedure FormDestroy(Sender: TObject);
    procedure lstTypeChange(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure lstRulezClick(Sender: TObject);
    procedure btn_replaceClick(Sender: TObject);
    procedure chk_SequencesClick(Sender: TObject);
    procedure lst_languageClick(Sender: TObject);
    procedure btn_cancelClick(Sender: TObject);
    procedure btn_allClick(Sender: TObject);
    procedure btn_save_prefsClick(Sender: TObject);
    procedure lst_profilesClick(Sender: TObject);
	procedure btn_img_folderClick(Sender: TObject);
    procedure track_selectChange(Sender: TObject);
    procedure track_uptoChange(Sender: TObject);
	procedure track_ticket_columnsChange(Sender: TObject);
    procedure track_gap_after_selectionChange(Sender: TObject);
    procedure track_pick_windowChange(Sender: TObject);

	private
		{ Private declarations }
		activated:boolean;
		m_prefs: TlotteryPrefs;

		procedure save_prefs;
      	procedure  display_sequences;
		procedure display_languages;
		procedure pr_update_controls;
		procedure do_add(replace: Boolean);
	public
		{ Public declarations }
  end;

var
  frm_options: Tfrm_options;

implementation
    {$WARN UNIT_PLATFORM OFF} 
	uses
	  lotseq,
	  filectrl, sysutils, wintypes, misclib, miscstrings, miscimage, misccrypt, miscencode, globals, translator;

	{$R *.DFM}
	//************************************************************************
	procedure Tfrm_options.btn_okClick(Sender: TObject);
	begin
	  save_prefs;
	  close;
	end;

	//************************************************************************
	procedure Tfrm_options.btn_resetClick(Sender: TObject);
	begin
	  FormActivate(sender);
	end;

	//************************************************************************
	procedure Tfrm_options.ticket_selectionClick(number: Byte; bonus:boolean);
	begin
	  ticket_selection.InPlay[number] := not ticket_selection.InPlay[number];
	end;

	//************************************************************************
	procedure Tfrm_options.btn_evensClick(Sender: TObject);
	var
	  number:byte;
	begin
	  for number := 1 to track_upto.position do
		 if (number mod 2) = 0 then
			ticket_selection.InPlay[number] := false;
	end;

	//************************************************************************
	procedure Tfrm_options.btn_oddsClick(Sender: TObject);
	var
	  number:byte;
	begin
	  for number := 1 to track_upto.position do
		 if (number mod 2) = 1 then
			ticket_selection.InPlay[number] := false;
	end;

	//************************************************************************
	procedure Tfrm_options.btn_minClick(Sender: TObject);
	var
	  value,number:integer;
	begin
	  try
		 value := strtoint(txt_num.text);
		 if (value>0) and (value <50) then
			 for number:=value-1 downto 1 do
			  ticket_selection.InPlay[number] := false;
	  except
		  on  EConvertError do
			txt_num.clear;
	  end;
	end;

	//************************************************************************
	procedure Tfrm_options.btn_maxClick(Sender: TObject);
	var
	  value,number:integer;
	begin
	  try
		 value := strtoint(txt_num.text);
		 if (value>0) and (value <50) then
			 for number:=value+1 to track_upto.position do
			  ticket_selection.InPlay[number] := false;
	  except
		  on EConvertError do
			 txt_num.clear;
	  end;
	end;

	//************************************************************************
	procedure Tfrm_options.FormClose(Sender: TObject; var Action: TCloseAction);
	begin
	  activated := false;
	end;

	//************************************************************************
	procedure Tfrm_options.FormActivate(Sender: TObject);
	begin
	  {read preferences}
	  pr_update_controls;
	end;

	//************************************************************************
	procedure tfrm_options.pr_update_controls;
	var
		ostrings: tstrings;
	begin
	  activated := false;

      //populate listbox with available profiles
      ostrings := m_prefs.getProfiles;
      lst_profiles.Clear;
      lst_profiles.Items.AddStrings(ostrings);
      ostrings.Free;

      //populate options form
	  with m_prefs do
	  begin
		tmiscstrings.selectInList(lst_profiles, profile);
		ticket_selection.MaxHighlighted := select;
		ticket_selection.MaxNumbers := highest_ball;
		ticket_selection.StartAtZero := start_at_zero;
		ticket_selection.set_numbers_in_play(currentInPlay);
		ticket_selection.columns := columns;
		chk_include_zero.checked:= start_at_zero;

		track_select.Position := select;

		track_upto.Position := highest_ball;

		track_ticket_columns.Position := columns;

		track_machine_columns.Position := machine_columns;

		track_anim_interval.Position := animation_interval;

		track_gap_after_selection.Position := min_selection_time;

		track_pick_window.Position := max_selection_time;
		chk_pick_when_dropped.Checked := pick_when_all_dropped;

		chk_sorted.checked := sorted;
		chk_rendered.checked := rendered;
		chk_random_kick.checked := random_kick;
		chk_mute.checked := mute;
		chk_show_numbers.checked:=show_numbers;
		lst_dropstyle.itemindex := drop_style;
		chk_Sequences.Checked := use_sequences;
		TAB_Sequences.Enabled := use_sequences;

		chk_keep_picking.checked := keep_picking ;
		chk_remove_picked_balls.checked := remove_picked_balls ;

		chk_backdrop.checked := use_background_images;
		txt_bg_folder.Text := background_image_folder;
		track_image_speed.Position := background_speed;
		track_ball_size.Position := ball_size;
        track_gravity.Position := trunc(gravity * 10.0);
        chk_randomness.Checked := randomness;

	  end;

	  display_sequences;
	  display_languages;

	  activated := true;
	end;

	//************************************************************************
	procedure Tfrm_options.chk_renderedClick(Sender: TObject);
	var
	  bitsperpixel:integer;
	  response:longint;
	begin
	  if activated and chk_rendered.checked then
	  begin
		  bitsperpixel := tmiscimagelib.get_colour_depth;

		 if bitsperpixel < 8   then
		 begin
			response :=
				messagedlg(
				 LocalString('You dont seem to have enough colours for rendered balls.')+CRLF+
				 LocalString('Continue anyway?'),
				 mtconfirmation,
				 [mbno,mbyes],
				 0
			  );
			if response <> mryes then
			  chk_rendered.checked := false;
		 end;
	  end;
	end;

	//************************************************************************
	procedure Tfrm_options.FormCreate(Sender: TObject);
	var
	  status : TregisterResult;
	begin
		with sharewarechecker1 do
		 begin
			ProgramName := PROGRAM_NAME;
			key := g_misccrypt.get_standard_cipherkey(programname);
			quiet := true;
			status:= Check_registered;
		 end;

		 if status = regexpired then
		 begin
			chk_sorted.enabled := false;
			chk_rendered.enabled := false;
			chk_sorted.checked := false;
			chk_rendered.checked := false;

			chk_sorted.hint := LocalString('Only available to registered users');
			 chk_rendered.hint := chk_sorted.hint;
		 end;

		 m_prefs := TLotteryPrefs.Create;
		 m_prefs.load_prefs(m_prefs.Profile);
	end;

	//************************************************************************
	procedure Tfrm_options.save_prefs;
	begin
	  with m_prefs do
	  begin
		use_background_images := chk_backdrop.checked;
		background_image_folder := txt_bg_folder.Text;
		background_speed := track_image_speed.Position;

		keep_picking := chk_keep_picking.checked;
		remove_picked_balls:= chk_remove_picked_balls.checked;

		use_sequences := chk_Sequences.Checked;
		select := track_select.Position;
		highest_ball := ticket_selection.MaxNumbers;
		prefsInPlay := ticket_selection.get_numbers_in_play;
		sorted := chk_sorted.checked;
		rendered := chk_rendered.checked;
		random_kick := chk_random_kick.checked;
		show_numbers := chk_show_numbers.checked;
		columns := ticket_selection.columns;
		use_sequences := chk_Sequences.Checked;
		start_at_zero := chk_include_zero.checked;
		mute := chk_mute.checked;
		machine_columns := track_machine_columns.position;
		animation_interval := track_anim_interval.Position;
		min_selection_time := track_gap_after_selection.Position;
		max_selection_time := track_pick_window.Position;
		pick_when_all_dropped := chk_pick_when_dropped.Checked;
		ball_size := track_ball_size.Position;
        gravity := track_gravity.Position /10;
        randomness := chk_randomness.Checked;

		if lst_dropstyle.itemindex = -1 then
			drop_style := 0
		else
			drop_style := lst_dropstyle.itemindex;
	  end;
	  m_prefs.save_prefs(lst_profiles.Text);
	end;


	//************************************************************************
	procedure Tfrm_options.chk_include_zeroClick(Sender: TObject);
	begin
	  if not chk_include_zero.checked then
		  if (ticket_selection.nInplay -1) <= ticket_selection.maxHighlighted then
		  begin
			  chk_include_zero.checked := true;
				exit;
			end;
	  ticket_selection.startatzero := chk_include_zero.checked;
	  ticket_sequences.startatzero := chk_include_zero.checked;
	end;


	//************************************************************************
	procedure Tfrm_options.lstTypeChange(Sender: TObject);
	var
	  seq_type:TLotterySequenceType;
	begin
	  //------------- clear out any pre existing marks ----------
	  ticket_sequences.clear_marks;

	  //------------- enable ticket as appropriate ----------
	  seq_type := get_sequence_type(lsttype.Text);
	  case seq_type of
		  lseqRandom:
				  ticket_sequences.Enabled := false;
		  lseqRange:
			  begin
				  ticket_sequences.Enabled := true;
				  ticket_sequences.MarkOnClick := true;
				  ticket_sequences.MaxHighlighted := 2;
				  ticket_sequences.MarkCheckingEnabled := true;
			  end;
		  lseqNumbers:
			  begin
				  ticket_sequences.Enabled := true;
				  ticket_sequences.MarkOnClick := true;
				  ticket_sequences.MarkCheckingEnabled := false;
			  end;
	  end;
	end;

	//************************************************************************
	procedure Tfrm_options.btnAddClick(Sender: TObject);
	begin
	  do_add(false)
	end;


	//************************************************************************
	procedure Tfrm_options.FormDestroy(Sender: TObject);
	begin
	  m_prefs.free;
	end;


	//************************************************************************
	procedure Tfrm_options.btnDeleteClick(Sender: TObject);
	begin
	  //------------ensure that something is selected -----
	  if lstRulez.ItemIndex   =-1 then
	  begin
		  tmisclib.alert(LocalString('Nothing selected to delete'));
		  exit;
	  end;

	  m_prefs.sequences.delete_non_nil( lstRulez.ItemIndex);
	  lstrulez.Items.Delete(lstRulez.ItemIndex);

	  //--------------------------------------------------------
	  if lstRulez.items.Count = 0 then
		  btn_replace.enabled := false;

	end;

	//************************************************************************
	procedure Tfrm_options.display_sequences;
	var
	  index: integer;
	  seq_obj: TLotterySequence;
	  seq_type_name: string;
	begin
	  lstRulez.Items.Clear;
	  for index:= m_prefs.sequences.FromIndex to m_prefs.sequences.toIndex do
	  begin
		  seq_obj:=TLotterySequence(m_prefs.sequences.items[index]);
			if seq_obj = nil then continue;

		  seq_type_name := get_sequence_typename(seq_obj.seq_type);
			lstrulez.items.Add( seq_obj.seq_name + ' - ' + inttostr(seq_obj.how_many) + ' ' + seq_type_name);
	  end;

	end;

	procedure Tfrm_options.lstRulezClick(Sender: TObject);
	var
	  seq_obj: TLotterySequence;
	  num_index, obj_index, item_index: longint;
	  seq_type_name: string;
	begin
	  btn_replace.enabled := true;
  
	  // -------------- get item from data structure -------------------
	  obj_index := m_prefs.sequences.get_non_nil_index(lstrulez.itemindex);
	  seq_obj := TLotterySequence(m_prefs.sequences.items[ obj_index]);
	  seq_type_name := get_sequence_typename(seq_obj.seq_type);

	  //--------------- update things on screen ------------------------
	  item_index := lsttype.items.IndexOf( seq_type_name);
	  lsttype.itemindex := item_index;
	  lsttype.onChange(self);

	  lstHowMany.ItemIndex := seq_obj.how_many -1;
	  txt_seq_name.text := seq_obj.seq_name;
	  chk_seq_Reuse.Checked := seq_obj.reuse;
	  chk_seq_sort.Checked := seq_obj.sorted;

	  if seq_obj.seq_type = lseqRandom then exit;

	  with seq_obj.numbers do
		 for num_index := FromIndex to toIndex do
		  ticket_sequences.Marked[ ByteValue[ num_index]] := true;

	end;


	procedure Tfrm_options.btn_replaceClick(Sender: TObject);
	begin
	  do_add(true);
	end;

	//************************************************************************
	procedure Tfrm_options.do_add(replace: Boolean);
	var
	  seq_obj: TLotterySequence;
	  seq_name, seq_count, seq_type_name: string;
	  seq_type:TLotterySequenceType;
	  howMany: word;
	  index:integer;
	begin
	  //----------- validate things -----
	  seq_count := lstHowMany.Text;
	  if seq_count = '' then
	  begin
		  tmisclib.alert (LocalString('Please select how many balls in this sequence'));
		  exit;
	  end;
	  howmany := strtoint(seq_count);

	  seq_type_name := lstType.Text;
	  if seq_type_name = '' then
	  begin
		  tmisclib.alert (LocalString('PLease select a sequence type'));
		  exit;
	  end;

	  if replace and (lstRulez.ItemIndex = -1)then
	  begin
		  tmisclib.alert (LocalString('Please select an item to replace'));
		  exit;
	  end;
  
	  //----------- get name to put into list, append in case statement below ----------
	  seq_name :=  lstHowMany.text + ' ' + seq_type_name;

	  //----------- validation ------------------------------
	  seq_type := get_sequence_type(seq_type_name);
	  case seq_type of
		  lseqRange:
			  if ticket_sequences.NMarked <2 then
			  begin
				  tmisclib.alert (LocalString('Please select the two numbers that mark your range'));
				  exit;
			  end;

		  lseqNumbers:
			  if ticket_sequences.NMarked <= howmany then
			  begin
				  tmisclib.alert (LocalString('You must select more numbers'));
				  exit;
			  end;
	  end;

	  //----------- create a sequence object and add to prefs object -----
	  seq_obj := TLotterySequence.create;
	  seq_obj.Seq_Type := seq_type;
	  seq_obj.how_many := strtoint(lstHowMany.text);
	  seq_obj.numbers  := ticket_sequences.get_marked_numbers;
	  seq_obj.reuse := chk_seq_reuse.checked;
	  seq_obj.sorted := chk_seq_sort.Checked;
	  seq_obj.seq_name := txt_seq_name.text;

	  if replace then
		  begin
			 index := m_prefs.sequences.get_non_nil_index( lstRulez.ItemIndex);
			  lstRulez.Items[lstRulez.ItemIndex] := seq_name;
			  m_prefs.sequences.Items[index] := seq_obj;
			end
	  else
		  begin
			  lstRulez.Items.add(seq_name);
			  m_prefs.sequences.add(seq_obj);
		 end;

	end;

	//************************************************************************
	procedure Tfrm_options.chk_SequencesClick(Sender: TObject);
	begin
	  TAB_Sequences.Enabled := chk_Sequences.Checked;
	end;

	//************************************************************************
   procedure Tfrm_options.display_languages;
   var
   	lang_obj: ttranslator;
      lang_names: tstringlist;
      index:integer;
      lang_name: string;
   begin
      //------------ set the languages available -----
      lang_obj := getTranslatorObj;
	  lang_names := lang_obj.Get_Languages_List;
      lst_language.Clear;
      for index := 1 to lang_names.count do
      begin
      	lang_name:=lang_names[index-1];
			lst_language.items.add(lang_name);
	  end;
	  tmiscstrings.selectInList(lst_language,lang_obj.LanguageInUse);
	  lang_names.free;
   end;

	//************************************************************************
  procedure Tfrm_options.lst_languageClick(Sender: TObject);
  var
	lang_obj: ttranslator;
  begin
		lang_obj := getTranslatorObj;
	lang_obj.LanguageInUse := lst_language.Text;
	 tmisclib.alert(localstring('please restart the application for the language choice to take effect'));
  end;

	//************************************************************************
	procedure Tfrm_options.btn_cancelClick(Sender: TObject);
	begin
		close;
	end;

	//************************************************************************
	procedure Tfrm_options.btn_allClick(Sender: TObject);
	var
	  number:byte;
	begin
	  for number := ticket_selection.StartNumber to ticket_selection.MaxNumbers do
			ticket_selection.InPlay[number] := true;
	end;


procedure Tfrm_options.btn_save_prefsClick(Sender: TObject);
begin
	save_prefs;
	showmessage(localstring('Saved'));
end;


procedure Tfrm_options.lst_profilesClick(Sender: TObject);
begin
	m_prefs.load_prefs(lst_profiles.Text);
    pr_update_controls;
end;



procedure Tfrm_options.btn_img_folderClick(Sender: TObject);
var
	sDirname:string;
	bresult: boolean;
begin
	sDirname := txt_bg_folder.Text;
	bresult :=
		SelectDirectory(
			sDirname,
			[sdAllowCreate, sdPerformCreate, sdPrompt],
			0);
    if bresult then txt_bg_folder.Text := sDirname + '\';
end;



//
//####################################################################
(*
	$History: options.pas $
 * 
 * *****************  Version 4  *****************
 * User: Sunil        Date: 6/06/05    Time: 0:23
 * Updated in $/projects/LOTTERY/PICKER/code
 * add a trailing slash
 * 
 * *****************  Version 2  *****************
 * User: Sunil        Date: 2/06/05    Time: 0:33
 * Updated in $/projects/LOTTERY/PICKER/code
 * added background_image_folder
 *
 * *****************  Version 1  *****************
 * User: Sunil        Date: 2/06/05    Time: 0:02
 * Created in $/projects/LOTTERY/PICKER/code
 * 
 * *****************  Version 3  *****************
 * User: Admin        Date: 1/06/05    Time: 23:59
 * Updated in $/projects/LOTTERY/PICKER/code
 * 
 * *****************  Version 14  *****************
 * User: Administrator Date: 8/06/04    Time: 15:06
 * Updated in $/code/projects/LOTTERY/PICKER/code
 * implemented profiles
 *
 * *****************  Version 13  *****************
 * User: Administrator Date: 7/06/04    Time: 17:51
 * Updated in $/code/projects/LOTTERY/PICKER/code
 * added option to save and load profiles - needs more work
 * 
 * *****************  Version 12  *****************
 * User: Administrator Date: 7/06/04    Time: 13:00
 * Updated in $/code/projects/LOTTERY/PICKER/code
 * no longer passes picker ini filename
 * 
 * *****************  Version 11  *****************
 * User: Administrator Date: 3/06/04    Time: 23:30
 * Updated in $/code/projects/LOTTERY/PICKER
 * replaced some square buttons, added an "all" button
 *
 * *****************  Version 10  *****************
 * User: Administrator Date: 31/05/04   Time: 23:53
 * Updated in $/code/projects/LOTTERY/PICKER
 * new cancel button added to options screen
 *
 * *****************  Version 9  *****************
 * User: Administrator Date: 5/05/04    Time: 23:14
 * Updated in $/code/projects/LOTTERY/PICKER
 * split out image misc and it all sort of works
 *
 * *****************  Version 8  *****************
 * User: Sunil        Date: 6-04-03    Time: 11:28p
 * Updated in $/code/LOTTERY/PICKER
 * added sourcesafe headers
*)


procedure Tfrm_options.track_selectChange(Sender: TObject);
begin
	ticket_selection.maxhighlighted := track_select.position +1;
end;

procedure Tfrm_options.track_uptoChange(Sender: TObject);
begin
	ticket_selection.maxnumbers := track_upto.Position;
end;

procedure Tfrm_options.track_ticket_columnsChange(Sender: TObject);
begin
	ticket_selection.columns := track_ticket_columns.Position; //this will validate
	if ticket_selection.columns <> track_ticket_columns.Position then
		track_ticket_columns.position := ticket_selection.columns;
end;



procedure Tfrm_options.track_gap_after_selectionChange(Sender: TObject);
begin
	if track_gap_after_selection.Position > track_pick_window.Position then
			track_pick_window.Position := track_gap_after_selection.Position;

end;

procedure Tfrm_options.track_pick_windowChange(Sender: TObject);
begin
	if track_pick_window.Position < track_gap_after_selection.Position then
			track_gap_after_selection.Position := track_pick_window.Position;

end;

end.

