unit Machine;
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
(* $Header: /PAGLIS/lottery/Machine.pas 4     6/06/05 0:24 Sunil $ *)
//****************************************************************
//


//* pre-render numbered balls
//* show droppped balls coming out of the machine

interface

uses
	SysUtils, WinProcs,  Classes, Graphics,
	retained,lottrender, vectors, lottype, lotseq, ballsrv,misclib,lottpref, intlist,
	jpeg;
const
	MAX_TUBES = 10;

type
	TlotteryMachineStyle = (LmsPlain, LmsRendered);

	//***********************************************************************
	R_lottery_tube = record
		x,y:integer;
		ball : LottoBall;
		has_ball : Boolean;
	end;

	//***********************************************************************
	R_lottery_ball = record
		value: LottoBall;
		tube :byte;
		colour :Tcolor;
		ball_type :TLottBallType;
		position,velocity:TVector;
		sqr_speed:Real;
		in_tube,in_bucket:Boolean;
		is_active, been_picked: Boolean;
	end;

	//***********************************************************************
	R_rack_data = record
		center: Tpoint;
		coords: array[1..4] of Tpoint;
		draw_rack: boolean;
		angle_increment : integer;
		release_angle: integer;
		cos_release, sin_release:real;
		sweeping_release: boolean;
	end;

	//***********************************************************************
	R_lottery_paddle = record
		buckets:array[1..3] of LottoBall;
		spokes:array[1..3] of Tpoint;
		angle: degree;
		grab_paddle,release_paddle: LottoBall;
	end;

	//***********************************************************************
	R_paddle_data = record
		speed: degree;
		front_paddle,rear_paddle: R_lottery_paddle;
		paddle_width : word;
		grabbing_balls: boolean;
		grab_distance: word;
	end;

	//***********************************************************************
	R_Tube_Data = record
		tubes : array[1..MAX_TUBES] of R_lottery_tube;
		tube_increment: Tvector;
		sqr_length:word;
		exit_multiplier: real;
		exit_speed: byte;
		random_kick: Boolean;
		random_drop_delay: Boolean;
		num_tubes: byte;
	end;

	//***********************************************************************
	R_Drum_data = record
		bitmap:Tbitmap;
		radius:integer;
		perturb_height: word;
		use_bg_bitmaps: boolean;
		bg_bitmap_folder: string;
		bg_bitmaps: Tstringlist;
		bg_bitmap_index:integer;
		bg_bitmap_counter: integer;
		bg_bitmap_change_speed: integer;
	end;

	//***********************************************************************
	R_machine_state_data = record
		selecting_balls, stepping, use_sequences:Boolean;
		selected_balls, current_sequence:byte;
		waiting_time: word;
		last_select_time:tdatetime;
	end;

	//***********************************************************************
	R_ball_data = record
		balls : array[0..MAX_LOTTERY_NUM] of R_lottery_ball;
		bounce_radius_squared: word;
		ball_server: TBallServer;
		render_style: TlotteryMachineStyle;
		ball_radius: byte;
		balls_selected:byte;
		balls_to_select: byte;
		total_balls_to_select: byte;
		picked_balls: byte;
		prefs_balls : Tintlist;
		// - - - - - - - - - - - - - - - - - - - - - - -
		balls_struct:TRenderedBalls;
		display_number: boolean;
	end;

	R_picked_ball = record
		being_picked, flash : boolean;
		ball : LottoBall;
		dx: integer;
	end;

	//***********************************************************************
	seconds = word;
	P_lottery_ball = ^R_lottery_ball;
	TSelectBallEvent = procedure(ball_num:LottoBall) of object;
	TSelectSequenceEvent = procedure(seq_number:byte; seq_obj : TLotterySequence) of object;
	LotteryError = class (Exception);

	
	//***********************************************************************
	TLotteryMachine = class(TRetainedCanvas)
	private
		//- - - - - - - - - - - - - - - - - - - - - - -
		F_start_at_zero:Boolean;
		F_colour: Tcolor;
		F_bg_colour: Tcolor;
		F_max_numbers: LottoBall;

		// - - - - - - - - - - - - - - - - - - - - - - -
		M_sequences: TlotterySequencelist;
		M_rack: R_rack_data;
		M_tubes: R_Tube_Data;
		M_paddles: R_paddle_data;
		M_drum: R_Drum_data;
		M_state: R_machine_state_data;
		m_balls:	R_ball_data;
		m_picked_ball: r_picked_ball;

		//- - - - - - - Tnotifyevent type proc - - - - 
		F_Ball_dropped: TSelectBallEvent;
		F_ball_reactivated: TSelectBallEvent;
		F_pr_select_sequence:		TSelectSequenceEvent;
		F_Select_Ball: TSelectBallEvent;
		F_Select_Start: TNotifyEvent;
		F_Select_finish: TNotifyEvent;
		F_ReleaseAngleChanged: TNotifyEvent;
		F_Sequence_incomplete:TNotifyEvent;
		F_all_balls_dropped: TNotifyEvent;
		F_Ball_Ejected: TNotifyEvent;

		// - - - - - - - - - - - - - - - - - - - - - - -
		procedure pr_execute_machine;
		procedure pr_initialise_machine;
		procedure pr_select_sequence(seq_index:byte); overload;
		procedure pr_select_sequence(seq_type: TLotterySequenceType; how_many: byte; numbers:tintlist; reload_numbers: boolean); overload;

		// - - - - - - - - - - - - - - - - - - - - - - -
		procedure pr_set_sweeping_release(value:boolean);
		procedure pr_set_ball_radius(value:Byte);
		procedure pr_set_balls_to_select(value:Byte);
		procedure pr_set_bg_colour(value:Tcolor);
		procedure pr_set_colour(value:Tcolor);
		procedure pr_set_input_tubes(value:byte);
		procedure set_tube_exit_speed(value:byte);
		procedure set_max_numbers(value:LottoBall);
		procedure set_paddle_width(value:word);
		procedure set_machine_speed(value:degree);
		procedure set_release_angle(value:integer);
		procedure set_style(value:TlotteryMachineStyle);
		procedure set_drop_style(value:TLotteryDropStyle);
		procedure pr_set_bg_folder(psValue:string);
		procedure set_bg_enabled(value:boolean);
		function get_drop_style: TLotteryDropStyle;
		procedure set_ticket_columns(value:byte);
		function get_ticket_columns:byte;

		// - - - - - - - - - - - - - - - - - - - - - - -
		procedure blit_ball_at(ball_index,x,y:integer; the_type:TLottBallType;Acanvas:Tcanvas);
		procedure draw_machine(Acanvas:TCanvas);
		procedure do_draw_drum;
		procedure draw_drum;
		procedure draw_front_paddles(Acanvas:TCanvas);
		procedure draw_rear_paddles(Acanvas:TCanvas);
		procedure draw_ball_rack(Acanvas:TCanvas);
		procedure draw_balls(Acanvas:TCanvas);
		procedure draw_picked_ball(poCanvas:tcanvas);

		procedure paint_bitmap_on_drum(Sender: TObject);

		function grab_a_ball(x,y: integer):LottoBall;
		procedure grab_balls;
		procedure move_balls;
		procedure move_ball(index:LottoBall);
		procedure pr_move_picked_ball();
		procedure pr_pick_ball(pBall: LottoBall);
		procedure bounce_ball(index:integer; new_pos:Tvector);
		procedure move_ball_in_tube(index:integer);
		procedure select_ball(pbNow: boolean);
		function nearest_ball(x,y:integer):LottoBall;
		function perturb_balls:byte;
		procedure reload_tube(tube_num:integer);
		procedure release_balls;
		procedure adjust_bitmaps;
		function which_grab_paddle(angle:degree):byte;
		function which_release_paddle(angle:degree; front:boolean):byte;
		procedure recalulate_rack;
		function get_point_of_impact(position, velocity: tvector; r2:integer): real;

	protected
	  // Protected declarations
		procedure notify_ball_reactivated(ball_num:LottoBall); dynamic;
		procedure notify_Ball_Dropped(ball_num:LottoBall); dynamic;
		procedure notify_Ball_ejected; dynamic;
		procedure notify_all_balls_dropped; dynamic;
		procedure notify_Select_Ball(ball_num:LottoBall); dynamic;
		procedure notify_Select_finish; dynamic;
		procedure notify_Select_start; dynamic;
		procedure notify_releaseAngleChanged; dynamic;
		procedure notify_pr_select_sequence(seq_number:byte; seq_obj: TLotterySequence); dynamic;
		procedure notify_sequence_incomplete; dynamic;

		procedure OnColorChanged; override;
		procedure OnCreate; override;
		procedure OnDestroy; override;
		procedure OnRedraw; override;
		procedure OnSetbounds; override;
		procedure OnAnimationStart; override;
		procedure OnAnimationTick; override;
		procedure OnAnimationEnd; override;
		procedure onMouseDrag(Shift: TShiftState; currentPos, downPos: Tpoint); override;
		//procedure OnAnimationEnd; override;
	public
		// Public declarations
		procedure reset;
		procedure init_from_prefs(prefs:TLotteryPrefs);
		procedure pick_now;
		property BackdropsFolder: string	read m_drum.bg_bitmap_folder		write pr_set_bg_folder;
		property BackdropsEnabled: boolean	read m_drum.use_bg_bitmaps			write set_bg_enabled;
		property BallsSelected:Byte			read m_balls.balls_selected;
		property BallsToSelect: byte		read m_balls.balls_to_select		write pr_set_balls_to_select;
		property BackdropChangeSpeed: integer read M_drum.bg_bitmap_change_speed write M_drum.bg_bitmap_change_speed; 
		//inherit the destructor
	published
		property Running;

		// Published declarations
		property BackgroundColor:Tcolor		read F_bg_colour					write pr_set_bg_colour;
		property BallRadius:byte			read m_balls.ball_radius			write pr_set_ball_radius;
		property MachineColor:Tcolor		read F_colour						write pr_set_colour;
		property InputTubes:byte			read m_tubes.num_tubes				write pr_set_input_tubes;
		property MachineSpeed: degree		read m_paddles.speed	 			write set_Machine_speed;
		property PaddleWidth: word			read m_paddles.paddle_width			write set_paddle_width;
		property Selecting:Boolean			read m_state.selecting_balls;
		property MaxNumbers:LottoBall		read F_max_numbers					write set_max_numbers;
		property ReleaseAngle:integer		read m_rack.release_angle			write set_release_angle;
		property Style:TlotteryMachineStyle	read m_balls.render_style			write set_style;
		property TubeExitSpeed:byte			read M_tubes.exit_speed				write set_tube_exit_speed;
		property RandomKick:Boolean			read m_tubes.random_kick			write m_tubes.random_kick;
		property RandomDropDelay:Boolean		read m_tubes.random_drop_delay		write m_tubes.random_drop_delay;
		property StartAtZero: Boolean 		read F_start_at_zero 					write F_start_at_zero ;
		property DropStyle: TLotteryDropStyle 	read get_drop_style					write set_drop_style  ;
		property TicketColumns: byte			read get_ticket_columns					write set_ticket_columns;
		property DisplayNumbers: boolean		read m_balls.display_number 			write m_balls.display_number;
		property SweepingRelease: boolean	read m_rack.sweeping_release			write pr_set_sweeping_release;

		property OnBallReactivated: TSelectBallEvent
			read F_ball_reactivated write F_ball_reactivated;
		property OnBallDropped: TSelectBallEvent
			read F_ball_dropped write F_ball_dropped;
		property OnAllBallsDropped:  TNotifyEvent
			read F_all_balls_dropped write F_all_balls_dropped;
		property OnSelectBall: TSelectBallEvent
			read F_Select_Ball write F_Select_Ball;
		property OnSelectStart: TNotifyEvent
			read F_Select_Start write F_Select_Start;
		property OnSelectFinish: TNotifyEvent
			read F_Select_finish write F_Select_finish;
		property OnReleaseAngleChanged: TNotifyEvent
			read F_ReleaseAngleChanged write F_ReleaseAngleChanged;
		property OnSelectSequence: TSelectSequenceEvent
			read F_pr_select_sequence write F_pr_select_sequence;
		property OnSequenceIncomplete: TNotifyEvent
			read F_Sequence_incomplete write F_Sequence_incomplete;
		property OnBallEjected: TNotifyEvent
			read F_Ball_Ejected write F_Ball_Ejected;

		property Hint;
		property ParentShowHint;
		property ShowHint;
		property ParentColor;
		property Color;
		property Font;
		property ParentFont;
	end;

procedure Register;

implementation
	uses
		lottery,sine, imgreader, math,miscimage;
	var
		S_vector: TvectorFunctions;
	const
		DEFAULT_BALLS_TO_SELECT =6;
		GRAVITY = 1.0;
		DEFAULT_TUBES = 5;
		DEFAULT_TUBE_EXIT_SPEED =35;
		TUBE_MULTIPLIER = 6;
		DEFAULT_bg_COLOUR = clwindow;
		DEFAULT_COLOUR = clblack;
		DEFAULT_SPEED = 9 ;
		DEFAULT_BALL_RADIUS = 5;
		DEFAULT_PADDLE_WIDTH = DEFAULT_BALL_RADIUS;
		MIN_SIZE = 150;
		TICK_TIME_INTERVAL = 10;					//.01 of a second
		SELECT_TIME_INTERVAL = 2;
		SELECT_TIME_WINDOW = 10;
		NO_PADDLE = 0;
		MIN_PERTURB_SPEED = 2.0;
		BUCKET_SHAPE_ANGLE = 5;
		PADDLE_SPACING = 120;
		FRONT_PADDLE_RELEASE_START = 202;
		FRONT_PADDLE_RELEASE_END = 247;
		REAR_PADDLE_RELEASE_START = 315;
		REAR_PADDLE_RELEASE_END = 337;
		GRAB_START = 67;
		GRAB_END = 112;
		VELOCITY_INCREMENT = 0.5;
		X_ENERGY_LOSS = 0.85;
		Y_ENERGY_LOSS = 0.75;
		RELEASE_X = 4;
		RELEASE_Y = -5;
		RANDOM_RELEASE_X = 3;
		EXTRA_RACK_WIDTH = 10;
		MAX_RELEASE_ANGLE = 160;
		FONT_SIZE = 5;
		MAX_RACK_ANGLE_INCREMENT = 5;
		DEFAULT_CHANGE_DRUM_BITMAP = 10;
		CHANGE_BITMAP_MULTIPLIER = 100;
		PICKED_BALL_SLOWDOWN = 1 ;
	//#################################################################
	//#		MAIN
	//#################################################################

	//********************************************************************
	procedure Register;
	begin
	  RegisterComponents('Paglis lottery', [TLotteryMachine]);
	end;

	//************************************************************
	// ---------create the thing and initialise is size------------
	// ************************************************************
	procedure TLotteryMachine.OnCreate;
	begin
		//--------------------initialise properties------------
		M_rack.sweeping_release := false;
		m_drum.use_bg_bitmaps := false;
		M_drum.bg_bitmaps := nil;
		m_drum.bg_bitmap_index := 0;
		m_drum.bg_bitmap_counter := 0;
		M_drum.bg_bitmap_folder := g_misclib.get_program_pathname;
		M_drum.bg_bitmap_change_speed := CHANGE_BITMAP_MULTIPLIER * DEFAULT_CHANGE_DRUM_BITMAP;

		S_vector := TvectorFunctions.create;
		m_balls.balls_struct := TRenderedBalls.create;

		M_sequences := nil;
		m_state.current_sequence := 0;
		m_state.use_sequences := false;

		m_balls.ball_server:= TBallServer.create;
		m_balls.display_number := false;
		m_balls.render_style := LmsPlain;
		m_balls.ball_radius:= DEFAULT_BALL_RADIUS;

		f_start_at_zero := false;

		m_drum.bitmap := Tbitmap.create;

		m_tubes.random_kick := false;
		m_tubes.random_drop_delay := false;
		m_paddles.grab_distance :=  4* m_balls.ball_radius * m_balls.ball_radius;

		m_tubes.num_tubes:= DEFAULT_TUBES;
		F_colour:= DEFAULT_COLOUR;
		F_bg_colour:= DEFAULT_bg_COLOUR;
		m_paddles.speed := DEFAULT_SPEED;
		m_paddles.paddle_width := DEFAULT_PADDLE_WIDTH;
		m_balls.balls_to_select:= DEFAULT_BALLS_TO_SELECT;
		F_max_numbers:= MAX_UK_LOTTERY_NUM;
		m_rack.draw_rack	:= true;


		m_rack.release_angle := 0; //clockwise from vertical
		m_tubes.exit_speed := DEFAULT_TUBE_EXIT_SPEED;

		clear_sine_cache;
		m_balls.prefs_balls :=nil;

		m_state.stepping := false;

		//-------------load bitmaps from resources-----------------
		ComponentIsAnimated := true;

		//-------------------------------------------------------------------
		setbounds(left,top,MIN_SIZE,MIN_SIZE);  //preperties set, now resize
		pr_initialise_machine;			  //set the states of all the balls
		adjust_bitmaps;						//load prerendered balls

		//-------------------------------------------------------------------
		Randomize;				  //re-seed random number generator
	end;

	//************************************************************
	// --------------------------get rid of bitmap------------
	// ************************************************************
	procedure TLotteryMachine.OnDestroy;
	begin
		//-------------free bitmaps from resources-----------------
		m_balls.balls_struct.free;
		m_drum.bitmap.free;
		m_balls.ball_server.free;
		S_vector.free;
		if assigned(m_drum.bg_bitmaps) then m_drum.bg_bitmaps.free;

		if assigned(M_sequences) then M_sequences.free;
		if assigned(m_balls.prefs_balls) then  m_balls.prefs_balls.free;
	end;

	//#################################################################
	//#		OVERRIDES
	//#################################################################
	//************************************************************
	// executes the machine and updates display - run from timer.
	 //************************************************************
	procedure TLotteryMachine.OnAnimationEnd;
	begin
		m_rack.draw_rack := true;
	end;

	//************************************************************
	procedure TLotteryMachine.OnAnimationTick;
	begin
		//---single step machine ------------
		pr_execute_machine;
		draw_machine(Transientcanvas);
	end;

	//************************************************************
	procedure TLotteryMachine.OnAnimationStart;
	var
		tube_number: integer;
	begin
		pr_initialise_machine;
		m_balls.total_balls_to_select := m_balls.balls_to_select;
		m_balls.picked_balls := 0;

		if M_state.use_sequences then pr_select_sequence( M_sequences.FromIndex); //first sequence
		m_rack.draw_rack := true;
		for tube_number := 1 to m_tubes.num_tubes do
			reload_tube(tube_number);
	end;


	//************************************************************
	procedure TLotteryMachine.onMouseDrag(Shift: TShiftState; currentPos, downPos: Tpoint);
	var
		p: tpoint;
		tan_theta, theta, degrees: real;
		angle: integer;
	begin
		if running then exit;

		p.x := currentpos.x - m_drum.radius;
		p.y := m_drum.radius- currentpos.y;
		
		if p.x=0 then
			begin
				if p.y <0 then
					ReleaseAngle := 180
				else
					releaseangle := 0;
			end
			else
			begin
				tan_theta:= p.y/p.x;
				theta := arctan(tan_theta);
				degrees := radtodeg(theta);
				angle := round(degrees);
				if p.x>0 then
					releaseangle := 90 - angle    //ok
				else
					releaseangle := -90 - angle;		  //
			end;

	  notify_releaseAngleChanged;
	end;

	//************************************************************
	procedure TLotteryMachine.OnColorChanged;
	begin
			pr_set_bg_colour(color);
	end;

	//************************************************************
	// ----------- the is called whenever a dimension is changed.--
	//************************************************************
	procedure TLotteryMachine.OnSetbounds;
	var
	  size:integer;
	begin
	  //----------- only interested in a square machine-----------
	  size := max(width,height);
	  if (width <> height) or (size < MIN_SIZE)then
	  begin
			size := max(width,height);
			size := max(size,MIN_SIZE);
			setbounds(left,top,size,size);
			exit;
	  end;

	  //- - - - - - - -save machine dimensions- - - - - - - - - - - -
	  m_drum.radius := size div 2;
	  m_balls.bounce_radius_squared := (m_drum.radius - m_balls.ball_radius)*(m_drum.radius - m_balls.ball_radius);
	  m_drum.perturb_height := round(m_drum.radius * 2.0 /3.0);

	  //- - - - - - -	- - - - - - - - - - - -
	  recalulate_rack;

	  //- - - - - - - -draw the drum - - - - - - - - - - - -
	  m_drum.bitmap.width := size;
	  m_drum.bitmap.height := size;
	  draw_drum;
	end;

	//************************************************************
	procedure TLotteryMachine.OnRedraw;
	begin
	  draw_machine(offscreencanvas);
	end;

	//#################################################################
	//#		PROPS
	//#################################################################
	//************************************************************
	// sets folder from which to pick up background bitmaps
	// ************************************************************
	procedure TLotteryMachine.pr_set_bg_folder(psValue:string);
	begin
		if inDesignMode then exit;
		if (psValue = M_drum.bg_bitmap_folder) then exit;

		M_drum.bg_bitmap_folder := psValue;
		if ( not Running) then begin
			if assigned (m_drum.bg_bitmaps) then m_drum.bg_bitmaps.free;
			m_drum.bg_bitmaps := g_miscimage.make_picture_list(M_drum.bg_bitmap_folder);
			if m_drum.bg_bitmaps.Count = 0 then
				m_drum.use_bg_bitmaps := false;
		end;
	end;

	//************************************************************
	// enables use of bitmaps in background to machine
	// ************************************************************
	procedure TLotteryMachine.set_bg_enabled(value:boolean);
	begin
		m_drum.use_bg_bitmaps := value;
		if inDesignMode then exit;

		//----build a list of bitmaps to go through
		if m_drum.use_bg_bitmaps then
		begin
			if not assigned (m_drum.bg_bitmaps) then
				m_drum.bg_bitmaps := g_miscimage.make_picture_list(M_drum.bg_bitmap_folder);

			//-----if no pictures cancel backgrounds
			if m_drum.bg_bitmaps.Count = 0 then
				m_drum.use_bg_bitmaps := false;
		end;

		draw_drum;
	end;

	//************************************************************
	//------------------sets size of the M_balls------------
	// ************************************************************
	 procedure TLotteryMachine.set_tube_exit_speed(value:byte);
	 begin
		 if (not running) and (value <> m_tubes.exit_speed) then
			m_tubes.exit_speed := value;
	 end;

	//************************************************************
	// ------------------sets whether the paddles sweep------------
		//************************************************************
	procedure TLotteryMachine.pr_set_sweeping_release(value:boolean);
	begin
		if (not running) and (value <> M_rack.sweeping_release) then
			M_rack.sweeping_release := value;
	end;
	
	//************************************************************
	// ------------------sets size of the M_balls------------
		//************************************************************
	procedure TLotteryMachine.pr_set_ball_radius(value:Byte);
	begin
	  if (not Running) and (value <> m_balls.ball_radius) then
	  begin
			m_balls.ball_radius := value;
			m_paddles.grab_distance :=	 4* m_balls.ball_radius * m_balls.ball_radius;
			m_tubes.sqr_length := (TUBE_MULTIPLIER	* m_balls.ball_radius) * (TUBE_MULTIPLIER * m_balls.ball_radius);
			pr_initialise_machine;
			adjust_bitmaps;
			redraw;
	  end;
	end;

	//************************************************************
	// how many balls to select?
	// ************************************************************
	procedure TLotteryMachine.pr_set_balls_to_select(value:Byte);
	var
	  n_available: integer;

	begin
	  n_available := F_max_numbers;
	  if f_start_at_zero then
			inc(n_available);
			
	  if value = 0 then value := 1; 


	  if (not Running) then
		 if (value < MAX_LOTTERY_NUM) and ( value < n_available) then
			 m_balls.balls_to_select := value;
	end;

	//************************************************************
	// number pool - does this need validation
	// ************************************************************
	procedure TLotteryMachine.set_max_numbers(value:LottoBall);
	begin
	  if (not Running) then
			if (value <= MAX_LOTTERY_NUM) and (value > 0) then
			begin
			  F_max_numbers := value;
			  pr_initialise_machine;
		 end;
	end;

	//************************************************************
	// --------sets how many input M_tubes the M_balls fall down---
	// ************************************************************
	procedure TLotteryMachine.pr_set_input_tubes(value:byte);
	begin
	  if (not Running) and (value <> m_tubes.num_tubes) then
      begin
			if (value * 2 * m_balls.ball_radius) >= width then
			  raise LotteryError.Create('input M_tubes wont fit on top of machine')
			else if value > F_max_numbers then
			  value := f_max_numbers;

          m_tubes.num_tubes := value;
          pr_initialise_machine;
          redraw;
      end;
	end;

	//************************************************************
	// set ball release angle
	// ************************************************************
	procedure TLotteryMachine.set_release_angle(value:integer);
	var
	  angle_from_180:degree;
	begin
	  if (not Running) and (value <> m_rack.release_angle) then
			while (value <0) do
			begin
			 value := 360 + value;
			end;

			while (value > 360) do
			begin
			 value := value - 360;
			end;

		 if (value< MAX_RELEASE_ANGLE) or (value > (360 - MAX_RELEASE_ANGLE)) then
		 begin
			m_rack.release_angle := value;
			recalulate_rack;

			angle_from_180 := abs(value-180);
			m_tubes.exit_multiplier := (180 - angle_from_180)/180.0;

			redraw;
		 end;
	end;

	//************************************************************
	// --------sets background colour of machine drum, normally black----
	// ************************************************************
	procedure TLotteryMachine.pr_set_colour(value:Tcolor);
	begin
	  if (not Running) and (value <> F_colour) then
	  begin
		 F_colour := value;
			redraw;
	  end;
	end;

	//************************************************************
	// --------sets background colour normally grey----
	// ************************************************************
	procedure TLotteryMachine.pr_set_bg_colour(value:Tcolor);
	begin
	  if (not Running) and (value <> F_bg_colour) then
	  begin
		 F_bg_colour := value;
		 draw_drum;
		 redraw;
	  end;
	end;

	//************************************************************
	// --- paddle width doesn't affect display as it is viewed from front only
	// ************************************************************
	procedure TLotteryMachine.set_paddle_width(value:word);
	begin
	  if (not Running) and (value <> m_paddles.paddle_width) then
			m_paddles.paddle_width := value;
	end;

	//************************************************************
	// --- machine speed doesn't affect display as only matters in iterations----
	// ************************************************************
	procedure TLotteryMachine.set_machine_speed(value:degree);
	begin
	  if value <> m_paddles.speed then
			m_paddles.speed := value;
	end;

	//************************************************************
	procedure TLotteryMachine.set_style(value:TlotteryMachineStyle);
	begin
	  if value = m_balls.render_style then exit;

	  m_balls.render_style := value;
	  m_balls.balls_struct.Rendered := (value = LmsRendered);
	  redraw;
	end;

	//************************************************************
	procedure TLotteryMachine.set_drop_style(value:TLotteryDropStyle);
	begin
	  m_balls.ball_server.DropStyle := value;
	end;

	function TLotteryMachine.get_drop_style: TLotteryDropStyle;
	begin
	  get_drop_style := m_balls.ball_server.DropStyle;
	end;

	//************************************************************
	procedure TLotteryMachine.set_ticket_columns(value:byte);
	begin
	  m_balls.ball_server.Columns := value;
	end;

	function TLotteryMachine.get_ticket_columns: byte;
	begin
	  get_ticket_columns := m_balls.ball_server.Columns;
	end;


	//#################################################################
	//#		NOTIFY
	//#################################################################
	//************************************************************
	procedure TLotteryMachine.notify_ball_reactivated(ball_num:LottoBall);
	begin
		if assigned(F_ball_reactivated) then
			 F_ball_reactivated(ball_num);
	end;

	//************************************************************
	procedure TLotteryMachine.notify_all_balls_dropped;
	begin
		if assigned(F_all_balls_dropped) then
			 F_all_balls_dropped(self);
	end;

	//************************************************************
	procedure TLotteryMachine.notify_Ball_Dropped(ball_num:LottoBall);
	begin
		if assigned(F_Ball_dropped) then
			 F_Ball_dropped(ball_num);
	end;

	//************************************************************
	procedure TLotteryMachine.notify_Ball_ejected();
	begin
		if assigned(F_Ball_ejected) then
			 F_Ball_ejected(self);
	end;

	//************************************************************
	//  tell the world that the release angle has been dragged
	// ************************************************************
	procedure TLotteryMachine.notify_releaseAngleChanged;
	begin
		if assigned(F_ReleaseAngleChanged) then
			 F_ReleaseAngleChanged(self);
	end;

	//************************************************************
	//  tell the world that I've selecting a ball
	// ************************************************************
	procedure TLotteryMachine.notify_Select_Ball(ball_num:LottoBall);
	begin
	  inc(m_balls.picked_balls);
		if assigned(F_Select_Ball) then
			F_Select_Ball(ball_num);
	end;

	//************************************************************
	//  tell the world that I've started selecting
	// ************************************************************
	procedure TLotteryMachine.notify_Select_start;
	begin
		if assigned(F_Select_start) then
			F_Select_start(self);
	end;

	//************************************************************
	//  tell the world that I've finished selecting
	// ************************************************************
	procedure TLotteryMachine.notify_Select_finish;
	begin
		if assigned(F_Select_finish) then
			 F_Select_finish(self);
	end;

	procedure TLotteryMachine.notify_sequence_incomplete;
	begin
		if assigned(F_Sequence_incomplete) then
			 F_Sequence_incomplete(self);
	end;

	//************************************************************
	//  tell the world that I'm using a particular sequence
	// ************************************************************
	procedure TLotteryMachine.notify_pr_select_sequence(seq_number: byte; seq_obj: TLotterySequence);
	begin
		if assigned(F_pr_select_sequence) then
			 F_pr_select_sequence(seq_number, seq_obj);
	end;

	//############################################################
	//#  SIMULATE
	//############################################################
	procedure TLotteryMachine.pick_now;
	begin
		select_ball(true);
	end;

	//**************************************************************
	procedure TLotteryMachine.init_from_prefs(prefs: TLotteryPrefs);
	begin
		//--------------------------------------------------------
		Reset;
		BallsToSelect := prefs.select;

		startAtZero := prefs.start_at_zero;
		MaxNumbers := prefs.highest_ball;

		RandomKick := prefs.random_kick;
		displayNumbers:= prefs.show_numbers;

		//------load balls----------------------------------------
		m_balls.ball_server.init_from_prefs(prefs);
	  
		//------copy balls from preferences for initialising sequences ------
		if assigned(m_balls.prefs_balls) then  m_balls.prefs_balls.free;
		m_balls.prefs_balls := prefs.currentInPlay.clone;

		//--------------------------------------------------------
		ticketcolumns := prefs.columns;
		dropstyle := TLotteryDropStyle (prefs.drop_style);
		InputTubes := prefs.machine_columns;

		//--------------------------------------------------------
		if prefs.rendered then
			style := lmsRendered
		else
			style := lmsplain;

		//--------------------------------------------------------
		M_state.use_sequences := prefs.use_sequences;
		if M_state.use_sequences then
		begin
			if assigned(M_sequences) then
				M_sequences.free;
		 	M_sequences := prefs.sequences.clone;
		end;

		//--------------------------------------------------------
		BackdropsFolder := prefs.background_image_folder;
		BackdropChangeSpeed := prefs.background_speed * CHANGE_BITMAP_MULTIPLIER;
		BackdropsEnabled := prefs.use_background_images;

		//--------------------------------------------------------
	  	redraw;
	end;

	//############################################################
	//#  SIMULATE
	//############################################################
	//************************************************************
	//  This models the motion of the M_balls. to make things simpler M_balls
	//  pass straight through one another and collide only with the
	//  drum and the rotating paddles. Rotational forces are not modelled
  //
	//  A more detailed model would use a lattice gas cellular automata
	//  modelling the M_balls as point objects but rendering as spheres
	//  unfortunately such precision would cause an unacceptable slowdown.
  //
	//  programming is full of compromises.
  //
	// ************************************************************
	procedure TLotteryMachine.pr_execute_machine;
	var
	  number_perturbed:byte;
	  hour,min,sec,msec:word;
	  finished: boolean;
	begin
	  //-------------------move paddles---------------------
	  m_paddles.front_paddle.angle:= g_misclib.inc_degree(m_paddles.front_paddle.angle, m_paddles.speed);
	  m_paddles.rear_paddle.angle:= g_misclib.dec_degree(m_paddles.rear_paddle.angle, m_paddles.speed);

	  //-------------------process every ball---------------------
	  move_balls;			//discrete time interval
	  release_balls;		//from paddles
	  grab_balls;			//using paddles
	  number_perturbed := perturb_balls;	//jiggle randomly
	  pr_move_picked_ball;	//move the picked ball

	  //------------------------------------------------------------------
	  // start the timer for selecion of balls
	  //------------------------------------------------------------------
	  if (not m_state.selecting_balls) and (number_perturbed >0) then
	  begin
			m_state.selecting_balls := true;
			m_balls.balls_selected := 0;
			notify_select_start;

			decodetime(now,hour,min,sec,msec);
			m_state.last_select_time:= encodetime(hour,min,sec,msec);
			m_state.waiting_time := SELECT_TIME_INTERVAL + random(SELECT_TIME_WINDOW);
	  end;

	  //------------------------------------------------------------------
	  // select a ball if the waiting time is over.
	  //------------------------------------------------------------------
	  if m_state.selecting_balls then
		select_ball(false);

	  //------------------------------------------------------------------
			//- - - - - -have we finished?- - - - - - - - - - - - -
	  //------------------------------------------------------------------
	  if (m_balls.balls_selected >= m_balls.balls_to_select) or (F_max_numbers = m_balls.balls_selected ) then
	  begin
			finished := true;

			//------ if we're using seqeuences, load next sequence.
			if m_balls.picked_balls <> m_balls.total_balls_to_select then
			  if m_state.use_sequences then
			  begin
				 if m_state.current_sequence < M_sequences.ToIndex then
				 begin
					 finished := false;
					 pr_select_sequence( m_state.current_sequence +1 );
				 end;

				 if finished then		//no more sequences, but must pick more balls 
				 begin
					 notify_sequence_incomplete;
					 pr_select_sequence(lseqRandom, (m_balls.total_balls_to_select - m_balls.picked_balls), nil,false);
					 finished := false;
				 end;
			  end;

			if finished then
			begin
				if m_picked_ball.being_picked then
					notify_Select_Ball(m_picked_ball.ball);

			  stop;
			  m_state.selecting_balls := false;
			  notify_select_finish;
			end;
	  end;

	end;

	//************************************************************
	// * select a ball if the waiting time is over.
	// ************************************************************
	procedure TLotteryMachine.select_ball(pbNow:boolean);
	var
	  ball_index:LottoBall;
	  hour,min,sec,msec:word;
	  this_time,diff_time:tdatetime;
	begin
	  if not m_state.selecting_balls then
	  	exit;

	  decodetime(now, hour, min, sec, msec);
	  this_time := encodetime(hour,min,sec,msec);
	  diff_time := this_time - m_state.last_select_time ;
	  decodetime(diff_time, hour, min, sec, msec);

	  if pbnow or (sec >= m_state.waiting_time) then begin
		 //- - - - - -get the nearest ball - - - - - - - - - - -
		 ball_index := nearest_ball(0,m_drum.radius);

		 //- - - - - -tell the world - - - - - - - - - - -
		 if ball_index <> INVALID_LOTTERY_NUMBER then
			pr_pick_ball(ball_index);

		 m_state.last_select_time := this_time;
		 m_state.waiting_time := SELECT_TIME_INTERVAL + random(SELECT_TIME_WINDOW);
	  end;
	end;

	//************************************************************
	// a way to re-start the machine from scratch
	// ************************************************************
	procedure TLotteryMachine.reset;
	begin
	  stop;
	  pr_initialise_machine;
	  redraw;
	end;

	//************************************************************
	// CODE SPLIT OUT FROM pr_execute_machine
	// ************************************************************
	procedure TLotteryMachine.move_balls;
	var
	  ball_index:LottoBall;
	begin
	  for ball_index := 0 to F_max_numbers do
		with m_balls.balls[ball_index] do
			if is_active and (not been_picked) then
				if in_tube then
					move_ball_in_tube(ball_index)
				else if (not in_bucket) then
					move_ball(ball_index);
	end;

	//************************************************************
	// reset position and velocities of M_balls.
	// ************************************************************
	procedure TLotteryMachine.pr_initialise_machine;
	var
	  ball_index:LottoBall;
	  tube_no,paddle: byte;
	  angle:degree;
	begin
	  recalulate_rack;

	  m_state.current_sequence := 0;
	  m_balls.ball_server.reset;
	  m_balls.picked_balls := 0;

	  //----initialise all M_balls -----
	  for ball_index := 0 to MAX_LOTTERY_NUM do
			with m_balls.balls[ball_index] do begin
			  value := ball_index;
			  colour := lottery_ball_colour(ball_index);
			  ball_type := lottery_ball(ball_index);

			  //-----------------all M_balls start with no velocity-------------
			  velocity  := S_vector.new_vector(0,0,0);
			  sqr_speed :=0;

			  //-----------------------all are inactive-------------------------
			  in_tube := false;
			  in_bucket := false;
			  is_active := false;
			  been_picked := false;
			end;
	

	  //------empty M_tubes------
	  for tube_no := 1 to m_tubes.num_tubes do
		m_tubes.tubes[tube_no].has_ball := false;

	  //------put the first row of M_balls into the input M_tubes------
	  if InDesignMode then
			for tube_no := 1 to m_tubes.num_tubes do
			  reload_tube(tube_no);

	  //------set the paddles in a Y shape-------------------------
	  m_paddles.front_paddle.angle := 30;
	  m_paddles.rear_paddle.angle := m_paddles.front_paddle.angle;

	  //------paddles dont have any M_balls--------------------------
	  for paddle:=1 to 3 do  begin
		 m_paddles.front_paddle.buckets[paddle] := INVALID_LOTTERY_NUMBER;
		 m_paddles.rear_paddle.buckets[paddle] := INVALID_LOTTERY_NUMBER;
	  end;

	  m_paddles.front_paddle.grab_paddle := NO_PADDLE;
	  m_paddles.front_paddle.release_paddle := NO_PADDLE;
	  m_paddles.rear_paddle.grab_paddle := NO_PADDLE;
	  m_paddles.rear_paddle.release_paddle := NO_PADDLE;

	  //------both sets of paddles start at the same place.---------
	  angle := m_paddles.front_paddle.angle;
	  for paddle:=1 to 3 do	  begin
			with (m_paddles.rear_paddle.spokes[paddle]) do	begin
			  x := round((m_drum.radius-m_balls.ball_radius) * the_cos(angle));
			  y := round((m_drum.radius-m_balls.ball_radius) * the_sine(angle));
			end;

			with (m_paddles.front_paddle.spokes[paddle]) do	begin
			  x := m_paddles.rear_paddle.spokes[paddle].x;
			  y := m_paddles.rear_paddle.spokes[paddle].y;
			end;

		 angle := g_misclib.inc_degree( angle, PADDLE_SPACING);
	  end;

	  // ------------ nothing being picked at this moment ------------
	  m_picked_ball.being_picked := false;

	  //-------------------------other things.-----------------------
	  m_state.selected_balls := 0;
	  m_paddles.grabbing_balls := false;
	  m_state.selecting_balls := false;
	  m_balls.balls_selected :=0;
	end;


  //********************************************************************
	//  models simple collision between ball and drum
	//  + adds effects of gravity
  //
	//  collisions dont but should take into account distances between
	//  drum and ball.
  //
	//  MINOR BUG -M_balls can be forced through wall of cylinder due to
	//  strange behaviour when ball is on boundary. can live with that
	//  at the moment
	//************************************************************
  procedure TLotteryMachine.bounce_ball(index:integer; new_pos:Tvector);
	var
		pos_increment, impact_pos, drum_normal,new_position,old_speed,new_speed: Tvector;
		x_loss, y_loss:real;
	 cos_theta, t:real;
  begin
	with m_balls.balls[index] do
	begin
			// ----------- find exactly where ball hits ------------------
		t := get_point_of_impact(position, velocity,m_balls.bounce_radius_squared);
		pos_increment:= S_vector.multiply(velocity, t);
		impact_pos := S_vector.add(position, pos_increment);

		//- - normal vector is the position of the ball relative to the centre
		//- - of drum. needs to be flipped to point into drum - - - -
		drum_normal := S_vector.reverse(impact_pos);
		S_vector.normalise(drum_normal);

		//- - - - flip speed vector, so ball ends up going in correct direction - - - -
		old_speed  := S_vector.reverse(velocity);

		//- - - -  if horizontal speed is zero add random x component,
		//- - - -  dont let balls bounce up and down on spot
		if old_speed.x=0 then
			old_speed.x := random(4)-2.5;

		//- - dot product of old speed vecotr and drum normal gives cosine of
		//- - angle between normal and ball
		cos_theta := S_vector.dot(old_speed,drum_normal);
		
		//add random component to cos_theta of <1%
		cos_theta := cos_theta;

		//- - calculate new velocity vector, by adding cosX to original velocity vector twice. - - -
		new_speed :=
			 S_vector.new_vector(
			  2 * (cos_theta  * drum_normal.i ) - old_speed.i,
			  2 * (cos_theta  * drum_normal.j ) - old_speed.j,
			  0.0
			 );

		//- - - -- make a random energy loss for uneven bounce- -
		x_loss := X_ENERGY_LOSS - (0.1 * random);
		y_loss := Y_ENERGY_LOSS - (0.1 * random);

		//- - - --copy the speed vector, apply loss of energy- - -
		velocity :=
			 S_vector.new_vector(
			  new_speed.i * x_loss,
			  new_speed.j * y_loss,
			  0.0
			 );

		//- - - - - - apply to original position - - - - - - - - -
		new_position := S_vector.add(position, velocity);
		position := S_vector.copy(new_position);	//copy new position of ball
	end;
  end;

	//************************************************************
	procedure TLotteryMachine.move_ball(index:integer);
	var
		new_distance: real;
		new_position: Tvector;
	begin

	  with m_balls.balls[index] do
	  begin
			//------------------move ball------------------------------------
			new_position := S_vector.add(position, velocity);
			new_distance := S_vector.magnitude_squared(new_position);

			//---------will there be a collision? in 2d with the drum?--------
			if (new_distance >= m_balls.bounce_radius_squared) then
			  bounce_ball(index, new_position)
			else
			begin
			position := S_vector.copy(new_position);	//copy new position of ball
			velocity.y := velocity.y + GRAVITY;				//apply gravity to velocity
		end;

			//- - - - - remember magnitude^2 of velocity -- - - - - - - - - - -
			sqr_speed :=		S_vector.magnitude_squared(velocity);
	  end;
	end;

	//************************************************************
	procedure TLotteryMachine.pr_move_picked_ball();
	begin
		if m_picked_ball.being_picked then
			with m_picked_ball do
			begin
				dx := dx + 1 + (dx div PICKED_BALL_SLOWDOWN);
				flash := not flash;
				if dx > m_drum.radius then
				begin
					being_picked := false;
					notify_select_ball(ball)
				end;
			end;
	end;

	//************************************************************
	procedure TLotteryMachine.pr_pick_ball(pBall: LottoBall);
	begin
		// update internal state of machine
		inc(m_balls.balls_selected);
		m_balls.balls[pBall].is_active := false;
		m_balls.balls[pBall].been_picked := true;

		with m_picked_ball do
		begin
			//------- clear out picked ball in motion --------
			if m_picked_ball.being_picked then
				notify_select_ball(m_picked_ball.ball);

			// start process of ejecting ball from machine
			notify_Ball_ejected;
			being_picked := true;
			ball := pBall;
			dx := 1;
			flash := false;
		end;
	end;


	//************************************************************
	// release M_balls - please release me!!!
	//************************************************************
	procedure TLotteryMachine.release_balls;
	var
	  release_paddle:byte;
	  ball:LottoBall;
	begin
	  //-------clear flags on which paddles are releasing----
	  m_paddles.front_paddle.release_paddle := NO_PADDLE;
	  m_paddles.rear_paddle.release_paddle := NO_PADDLE;

	  //---front paddles release M_balls near the top of their clockwise arc.---
	  release_paddle := which_release_paddle(m_paddles.front_paddle.angle,true);
	  if release_paddle <> NO_PADDLE then
	  begin
			ball := m_paddles.front_paddle.buckets[release_paddle];
			if ball <> INVALID_LOTTERY_NUMBER then
			begin
			  m_paddles.front_paddle.buckets[release_paddle] := INVALID_LOTTERY_NUMBER;
			  m_paddles.front_paddle.release_paddle := release_paddle;
			  with	m_balls.balls[ball] do
			  begin
				  position.x := m_paddles.front_paddle.spokes[release_paddle].x;
				  position.y := m_paddles.front_paddle.spokes[release_paddle].y;
				  velocity.x := RELEASE_X + random(RANDOM_RELEASE_X);
				  velocity.y := RELEASE_Y;
				  in_bucket := false;
			  end;
			end;
	  end;

	  //---rear paddles release M_balls near the top of anticlockwise arc.---
	  release_paddle := which_release_paddle(m_paddles.rear_paddle.angle,false);
	  if release_paddle <> NO_PADDLE then
	  begin
			ball := m_paddles.rear_paddle.buckets[release_paddle];
			if ball <> INVALID_LOTTERY_NUMBER then
			begin
			  m_paddles.rear_paddle.buckets[release_paddle] := INVALID_LOTTERY_NUMBER;
			  m_paddles.rear_paddle.release_paddle := release_paddle;
			  with	m_balls.balls[ball] do
			  begin
				  in_bucket := false;
				  position.x := m_paddles.rear_paddle.spokes[release_paddle].x;
				  position.y := m_paddles.rear_paddle.spokes[release_paddle].y;
				  velocity.x := -RELEASE_X - random(RANDOM_RELEASE_X);
				  velocity.y := RELEASE_Y;
			  end;
			end;
	  end;
	end;

	//************************************************************
	// grab_balls - with both hands!! errr paddles
	//************************************************************
	procedure TLotteryMachine.grab_balls;
	var
		grab_paddle:byte;
		ball:LottoBall;
	begin

		//-------clear flags on which paddles are grabbing or releasing----
		m_paddles.front_paddle.grab_paddle := NO_PADDLE;
		m_paddles.rear_paddle.grab_paddle := NO_PADDLE;
		m_paddles.grabbing_balls := false;

		//---front paddles grab M_balls near the bottom of their clockwise arc.---
		grab_paddle := which_grab_paddle(m_paddles.front_paddle.angle);
		if grab_paddle <> NO_PADDLE then
		begin
			m_paddles.grabbing_balls := true;
			if m_paddles.front_paddle.buckets[grab_paddle] = INVALID_LOTTERY_NUMBER then
			begin
			  m_paddles.front_paddle.grab_paddle := grab_paddle;
			  with m_paddles.front_paddle.spokes[grab_paddle]do
				  ball := grab_a_ball(x,y);

			  if ball <> INVALID_LOTTERY_NUMBER then
			  begin
				  m_paddles.front_paddle.buckets[grab_paddle] := ball;
				  m_balls.balls[ball].in_bucket := true;
			 end;
			end;
		end;

		//---rear paddles grab M_balls near the bottom of anticlockwise arc.---
		grab_paddle := which_grab_paddle(m_paddles.rear_paddle.angle);
		if grab_paddle <> NO_PADDLE then
		begin
			m_paddles.grabbing_balls := true;
			if m_paddles.rear_paddle.buckets[grab_paddle] = INVALID_LOTTERY_NUMBER then
			begin
			 m_paddles.rear_paddle.grab_paddle := grab_paddle;
			  with m_paddles.rear_paddle.spokes[grab_paddle]do
				  ball := grab_a_ball(x,y);

			  if ball <> INVALID_LOTTERY_NUMBER then
			  begin
				  m_paddles.rear_paddle.buckets[grab_paddle] := ball;
				  m_balls.balls[ball].in_bucket := true;
			 end;
			end;
		end;
	end;


	//************************************************************
	// move M_balls in proximity of paddles, adds a random factor to machine
	// done after M_balls are bounced so will always have a distance
	//************************************************************
	function TLotteryMachine.perturb_balls:byte;
	var
		ball:LottoBall;
		perturb_factor:real;
		perturbed: byte;
	begin
	  perturbed := 0;

	  //---	 perturb M_balls below a certain height but when grabbing-----
	  perturb_factor := 1.0+ (2.0 * random);
	  if m_paddles.grabbing_balls then
			for ball:= 0 to F_max_numbers do
			  with m_balls.balls[ball] do
				  if is_active and (not in_bucket) and (not in_tube) and
					  (position.y	> m_drum.perturb_height) and (sqr_speed < MIN_PERTURB_SPEED)  then
					 begin
						velocity.y := velocity.y * perturb_factor;
						velocity.x := velocity.x * perturb_factor;
						inc(perturbed);
					 end;

	  //--------how many were perturbed?---------------------------------
	  perturb_balls := perturbed;
	end;

	//************************************************************
	procedure TLotteryMachine.move_ball_in_tube(index:integer);
	var
		sqr_distance :real;
		tube_exit_speed:real;
	begin

	 with m_balls.balls[index] do
	 begin
		with position do
		begin
			//-------------------------move ball in tube-------------------
			with velocity do
			begin
			  x := x + m_tubes.tube_increment.x;
			  y := y + m_tubes.tube_increment.y;
			end;

			x := x + velocity.x;
			  y := y + velocity.y;
			  sqr_distance := x*x + y*y;

			//-------if left tube, reload tube-------------------------
			if sqr_distance < (m_balls.bounce_radius_squared - m_tubes.sqr_length)then
			begin
			 //- - - - -kick the ball out of the tube - - - - - - - - -
			 if m_tubes.random_kick then
				  tube_exit_speed := random(m_tubes.exit_speed)
			  else
				  tube_exit_speed := m_tubes.exit_speed;

			  tube_exit_speed := tube_exit_speed * m_tubes.exit_multiplier;

			  velocity.x := velocity.x + (tube_exit_speed * m_tubes.tube_increment.x);
			  velocity.y := velocity.y + (tube_exit_speed * m_tubes.tube_increment.y);

			  sqr_speed :=  (velocity.x *  velocity.x) + (velocity.y  * velocity.y );

			  //- - - - -mark ball as being outside tube - - - - - - - - -
			  in_tube := false;
			  M_tubes.tubes[tube].has_ball := false;
			  notify_Ball_Dropped(index);

			  reload_tube(tube);
			end;
		end;
	 end;

	end;


	//************************************************************
	//  which bucket is at the release point?
	//  release happens after 5/4 PI (clockwise from horizontal)
	//************************************************************
	function TLotteryMachine.which_release_paddle(angle:degree; front:boolean):byte;
	var
		current_angle :degree;
		paddle,found_paddle:byte;
	begin
	  current_angle := angle;
	  found_paddle := NO_PADDLE;

	  for paddle:=1 to 3 do
	  begin //.
			if (front) then
			  begin //..
				  if (current_angle > FRONT_PADDLE_RELEASE_START) and (current_angle < FRONT_PADDLE_RELEASE_END) then
				  begin   //...
					  found_paddle := paddle;
					  break
				  end; //...
			  end //..
			else if (current_angle > REAR_PADDLE_RELEASE_START) and (current_angle < REAR_PADDLE_RELEASE_END) then
			  begin //..
				  found_paddle := paddle;
				  break;
			  end; //..

			current_angle := g_misclib.inc_degree(current_angle, PADDLE_SPACING);
	  end; //.

	  which_release_paddle := found_paddle;
	end;

	//************************************************************
	//  which bucket is at the grab point ?
	//  grab point is in 3PI/8 to 5PI/8  (clockwise from horizontal)
	//************************************************************
	function TLotteryMachine.which_grab_paddle(angle:degree):byte;
	var
		current_angle :degree;
		paddle,found_paddle:byte;
	begin
		current_angle := angle;
		found_paddle := NO_PADDLE;

		for paddle:=1 to 3 do
		begin
			if (current_angle > GRAB_START) and (current_angle < GRAB_END) then
			begin
			  found_paddle := paddle;
			  break;
			end;
			current_angle := g_misclib.inc_degree(current_angle, PADDLE_SPACING);
		end;

		which_grab_paddle := found_paddle;
	end;

	//************************************************************
	//  get any ball within a distance <radius of this point
	//************************************************************
	function TLotteryMachine.grab_a_ball(x,y: integer):LottoBall;
	var
		ball,found_ball: LottoBall;
		dx,dy: Real;
	begin
	  //-------------BE A PESSIMIST-------------------------
	  found_ball := INVALID_LOTTERY_NUMBER;

	  //----------------grope M_balls for an answer------------
	  for ball:=0 to F_max_numbers do
			if m_balls.balls[ball].is_active and (not m_balls.balls[ball].in_bucket) then
			  begin
				  dx := sqr(m_balls.balls[ball].position.x - x);
				  dy := sqr(m_balls.balls[ball].position.y - y);
				  if (dx*dx) + (dy*dy) <= m_paddles.grab_distance then
				  begin
					  found_ball := ball;
					  break;
				  end;
			  end;

		//----------------return whatever.---------------------
		grab_a_ball := found_ball;
	end;

	//******************which is the closest ball to this point?****
	function TLotteryMachine.nearest_ball(x,y: integer):LottoBall;
	var
		ball_index,closest_ball: LottoBall;
		sqr_min_distance,distance: real;
	begin
	  closest_ball := INVALID_LOTTERY_NUMBER;
	  sqr_min_distance := 1000;

	  for ball_index := 0 to F_max_numbers do
			with m_balls.balls[ball_index] do
			  if is_active and (not in_bucket) then
			  begin
				  distance := sqr( position.x - x) + sqr(position.y - y);
				  if distance < sqr_min_distance then
				  begin
					  closest_ball := ball_index;
					  sqr_min_distance := distance;
				  end;
			 end;

		nearest_ball := closest_ball;
	end;

	//******************set which M_balls can be used.**************
	procedure TLotteryMachine.recalulate_rack;
	var
	  dx,dy,tube: integer;
	  half_rack_width, ball_diameter: integer;
	  midpoint:Tpoint;
	begin
	  // -------------set some angles-------------------
	  M_rack.cos_release := the_cos(m_rack.release_angle);
	  M_rack.sin_release := the_sine(m_rack.release_angle);

	  //-----------calculate the center of the rack------
	  ball_diameter := 2 * m_balls.ball_radius;
	  M_rack.center.x := m_drum.radius + round((m_drum.radius-ball_diameter) * M_rack.sin_release);
	  M_rack.center.y := m_drum.radius - round((m_drum.radius-m_balls.ball_radius) * M_rack.cos_release);

	  //----------and now the coordinates of the rack itself---------------
	  half_rack_width := (m_balls.ball_radius *  m_tubes.num_tubes) + EXTRA_RACK_WIDTH;
	  dx :=  round (half_rack_width * M_rack.cos_release);
	  dy :=  round (half_rack_width * M_rack.sin_release);
	  M_rack.coords[1].x := M_rack.center.x -	dx;
	  M_rack.coords[1].y := M_rack.center.y -	dy;
	  M_rack.coords[2].x := M_rack.center.x +	dx;
	  M_rack.coords[2].y := M_rack.center.y +	dy;

	  dx :=  round (m_balls.ball_radius* M_rack.sin_release);
	  dy :=  round (m_balls.ball_radius * M_rack.cos_release);
	  M_rack.coords[3].x := M_rack.coords[2].x + dx;
	  M_rack.coords[3].y := M_rack.coords[2].y - dy;
	  M_rack.coords[4].x := M_rack.coords[1].x + dx;
	  M_rack.coords[4].y := M_rack.coords[1].y - dy;

	  //----------and the start positions of the M_tubes---------------
	  dx :=  round (m_balls.ball_radius* M_rack.cos_release);
	  dy :=  round (m_balls.ball_radius * M_rack.sin_release);
	  midpoint.x := (M_rack.coords[1].x + M_rack.coords[2].x) div 2;
	  midpoint.y := (M_rack.coords[1].y + M_rack.coords[2].y) div 2;
	  m_tubes.tubes[1].x := midpoint.x -m_drum.radius - (dx*(m_tubes.num_tubes-1));
	  m_tubes.tubes[1].y := midpoint.y -m_drum.radius -(dy*(m_tubes.num_tubes-1));
	  for tube := 2 to m_tubes.num_tubes do
	  begin
			m_tubes.tubes[tube].x := m_tubes.tubes[tube-1].x+ (dx*2);
			m_tubes.tubes[tube].y := m_tubes.tubes[tube-1].y+ (dy*2);
	  end;

	  //-------------and by how much the M_balls move in the tube---
	  m_tubes.tube_increment.x := - VELOCITY_INCREMENT * M_rack.sin_release;
	  m_tubes.tube_increment.y := VELOCITY_INCREMENT * M_rack.cos_release;
	end;

	//************************************************************
	procedure TLotteryMachine.reload_tube(tube_num:integer);
	var
	  ball_index: integer;
	begin
	  //----------- dont reload a full tube ------
	  if M_tubes.tubes[tube_num].has_ball then
			exit;

	  //--------------------------------------------------
	  ball_index := m_balls.ball_server.get_ball;
	  if (ball_index = -1) then
	  begin
			notify_all_balls_dropped;
			m_rack.draw_rack  := false;
			exit;
	  end;
	  M_tubes.tubes[tube_num].has_ball := true;
	
	  //------------- initialise ball	-------------
	  with m_balls.balls[ball_index] do
	  begin
			is_active := true;
			been_picked := false;

			in_tube := true;
			tube := tube_num;
			m_tubes.tubes[tube_num].ball := ball_index;

			with position do
			begin
			  x:= m_tubes.tubes[tube_num].x;
			  y:= m_tubes.tubes[tube_num].y;
			  z:= 0;
			end;	//with
	  end;  //with

	end;

	//************************************************************
	// build a new list of balls to give ball server.
	// exclude balls allready picked
	//************************************************************
	procedure TLotteryMachine.pr_select_sequence(seq_type: TLotterySequenceType; how_many: byte; numbers:tintlist; reload_numbers: boolean);
	var
	  start_num, end_num: LottoBall;
	  index, tube_no, paddle: byte;
	  flags: tintlist;
	begin

	  //--------- update state -------------------
	  m_state.selected_balls := 0;
	  m_paddles.grabbing_balls := false;
	  m_state.selecting_balls := false;
	  m_balls.balls_selected :=0;

	  // ------------nowt in paddles ---------------------
	  for paddle:=1 to 3 do
	  begin
		 m_paddles.front_paddle.buckets[paddle] := INVALID_LOTTERY_NUMBER;
		 m_paddles.rear_paddle.buckets[paddle] := INVALID_LOTTERY_NUMBER;
	  end;

	  //--------- build lottery flags --------------
	  m_balls.balls_to_select := how_many;

	  //- - - - - - - - - all numbers are not available - - - -
	  flags := tintlist.create;
	  for index := 0 to MAX_LOTTERY_NUM do
			flags.BoolValue[index] := false;

	  //- - - - - - - - - mark applicable numbers available - - - -
	  case seq_type of
			lseqRandom:
			  for index := 0 to F_max_numbers do
				  flags.BoolValue[index] := true;
			lseqRange:
			  begin
				  start_num := numbers.ByteValue[numbers.FromIndex];
				  end_num := numbers.ByteValue[numbers.toIndex];
				  for index := start_num to  end_num do
					  flags.BoolValue[index] := true;
			  end;

			lseqNumbers:
			  for index := numbers.FromIndex to	numbers.toIndex do
				  flags.BoolValue[numbers.ByteValue[index]] := true;
	  end;

	  //- - - - - - - - - remove nonselected numbers - - - -
	  if assigned(m_balls.prefs_balls) then
			for index := 0 to F_max_numbers do
			  if  not m_balls.prefs_balls.boolvalue[index] then 
				  flags.BoolValue[index] := false;

	  //- - - - - - - - - remove picked numbers - - - -
	  for index := 0 to F_max_numbers do
	  if  M_balls.balls[index].been_picked then
		if reload_numbers then
			notify_ball_reactivated(index)				//ball reinstated
		else
			flags.BoolValue[index] := false;

	  //- - - - - - - - - reactivate all remaining balls - - - -
	  for index := 0 to F_max_numbers do
	  if  flags.BoolValue[index] then
			notify_ball_reactivated(index);				//ball reinstated

	  //- - - - - - - - - make numbers INactive  - - - -
	  for index := 0 to MAX_LOTTERY_NUM do
			if flags.BoolValue[index] then
			  with m_balls.balls[index] do
			  begin
				  //-----------------all M_balls start with no velocity-------------
				  velocity	:= S_vector.new_vector(0,0,0);
				  sqr_speed :=0;

				  //-----------------------all are inactive-------------------------
				  in_tube := false;
				  in_bucket := false;
				  is_active := false;
				  been_picked := false;
			  end;

	  //- - - - - - - - - tell ball server - - - -
	  M_balls.ball_server.init_from_flags(flags);
	  flags.free;

	  //- - - - - - - reload tubes - - - - - - - - 
	  for tube_no := 1 to m_tubes.num_tubes do
			reload_tube(tube_no);

	end;

	//***************************************************************
	procedure TLotteryMachine.pr_select_sequence(seq_index:byte);
	var
	  seq: TLotterySequence;
	begin
	  //--------- build lottery flags --------------
	  seq := TLotterySequence(M_sequences.items[ seq_index]);
	  if seq <> nil then
			begin
				//duff sequence valid
				pr_select_sequence( seq.seq_type, seq.how_many, seq.numbers, seq.reuse);
				m_state.current_sequence := seq_index;
				notify_pr_select_sequence(seq_index, seq);
			end
	  else
			begin
			  //duff sequence
			  notify_sequence_incomplete;
			  pr_select_sequence(lseqRandom, (m_balls.total_balls_to_select - m_balls.picked_balls), nil, false);
			end;

	  //--------- update globals -------------------
	end;

	//############################################################
	//#  PAINT
	//############################################################
	//************************************************************
	procedure TLotteryMachine.draw_machine(Acanvas:TCanvas);
	begin
		//--------- todo use threads to read the image -----------
		if m_drum.use_bg_bitmaps and running then
		begin
			inc(m_drum.bg_bitmap_counter);
			if m_drum.bg_bitmap_counter > M_drum.bg_bitmap_change_speed then
			begin
				m_drum.bg_bitmap_counter := 0;
				inc (m_drum.bg_bitmap_index);
				if m_drum.bg_bitmap_index >= m_drum.bg_bitmaps.count then
					m_drum.bg_bitmap_index := 0;
				draw_drum;
			end;
		end;

		//------------------------------------------------------------
		Acanvas.draw(0,0, m_drum.bitmap);
		draw_rear_paddles(Acanvas);
		draw_balls(Acanvas);
		draw_front_paddles(Acanvas);
		draw_ball_rack(Acanvas);
		draw_picked_ball(Acanvas);
	end;

	//************************************************************
	procedure TLotteryMachine.draw_drum;
	var
		index:integer;
		filename:string;
		aThread : TImageReaderThread;
	begin
		if (not inDesignMode) and m_drum.use_bg_bitmaps then
			begin
				index := m_drum.bg_bitmap_index;
				filename := m_drum.bg_bitmaps[index];
				athread := TImageReaderThread.create(filename);
				athread.OnTerminate := paint_bitmap_on_drum;
			end
		else
			do_draw_drum;
	end;

	//************************************************************
	//* separated draw routine to prevent momentary blank drum appearing  
	procedure TLotteryMachine.do_draw_drum;
	begin
		//---------------------draw the drum-------------
		with m_drum.bitmap.canvas do
		begin
			//----------------- clear background and draw circle for drum ----
			pen.color := F_bg_colour;
			brush.color := F_bg_colour;
			brush.style := bsSolid;
			rectangle(0, 0, self.width, self.height);

			brush.color := f_colour;
			ellipse(0,0,width,height);
		end;
	end;

	//************************************************************
	procedure TLotteryMachine.paint_bitmap_on_drum(Sender: TObject);
	var
		mask: Tbitmap;
		rect:trect;
		aThread : TImageReaderThread;
	begin
		do_draw_drum;
		
		//----------------- get useful info--------------------------
		aThread := TImageReaderThread(sender);
		rect := getclientrect;

		//----------------- make mask --------------------------
		mask := Tbitmap.create();
		with mask do
		begin
			width := self.width;
			height := self.height;
			canvas.brush.color := clwhite;
			canvas.brush.style := bssolid;
			canvas.FillRect(rect);
			canvas.brush.color := clblack;
			canvas.brush.style := bssolid;
			canvas.ellipse(0,0,width,height);
		end;

		//---------------- paint jpeg onto ellipse in mask------------------
		mask.canvas.copymode := cmSrcpaint;
		mask.canvas.StretchDraw(rect,athread.jpg);

		//---------------- put a white mask on drum bitmap--------------
		with m_drum.bitmap.canvas do
		begin
			brush.color := clwhite;
			ellipse(0,0,width,height);

			//---------------- put mask onto drum bitmap -------------------
			copymode := cmSrcAnd;
			draw(0,0,mask);

			//---------------- give it a black border --------------
			copymode := cmmergecopy;
			pen.color := clblack;
			brush.style := bsclear;
			ellipse(0,0,width,height);
		end;
		
		//------------------------------------------------
		mask.free;
	end;

	//************************************************************
	// rear paddles rotate at same speed as front paddles but
	// in opposite direction. These are easier as no central hub to draw
	// ************************************************************
	procedure TLotteryMachine.draw_rear_paddles(Acanvas:TCanvas);
	var
		dx1,dy1,dx2,dy2,paddle,xpos,ypos:integer;
		ball_index: LottoBall;
		angle:degree;
		cosangle,sinangle:real;
	begin
	  with Acanvas do
	  begin
		 pen.color := clwhite;
		brush.style := bsclear;
	  end;

	  angle := m_paddles.rear_paddle.angle;
	  for paddle := 1 to 3 do
	  begin
			cosangle := the_cos(angle);
			sinangle := the_sine(angle);

			//--------------calculate where the line goes----------------
			dx1 := round(m_drum.radius * cosangle);
			dy1 := round(m_drum.radius * sinangle);
			dx2 := round((m_drum.radius-m_balls.ball_radius) * cosangle);
			dy2 := round((m_drum.radius-m_balls.ball_radius) * sinangle);

			//---remember the point where the where the spoke hits the drum----
			m_paddles.rear_paddle.spokes[paddle].x := dx2;
			m_paddles.rear_paddle.spokes[paddle].y := dy2;

			//-------draw the ball in this paddle------------------------
			ball_index := m_paddles.rear_paddle.buckets[paddle];
			if ball_index <> INVALID_LOTTERY_NUMBER then
			begin
			  xpos := m_drum.radius + dx2;
			  ypos := m_drum.radius + dy2;
			  blit_ball_at( ball_index, xpos, ypos, m_balls.balls[ball_index].ball_type,Acanvas);
			end;

			//------------------------draw the line----------------------
			with Acanvas do
			begin
			  moveto(m_drum.radius + dx1, m_drum.radius + dy1);
			  lineto(m_drum.radius + dx2, m_drum.radius + dy2);
			end;

			//--------------------the next paddle is 120 degrees away-----
			angle := g_misclib.inc_degree(angle, PADDLE_SPACING);
	  end;
	end;

	//************************************************************
	// just draw them as they are (things with -ve y are above the
	// machine and invisible
	// ************************************************************
	procedure TLotteryMachine.draw_balls(Acanvas:Tcanvas);
	var
		ball_index:LottoBall;
		xpos,ypos:integer;
	begin
	  //------------draw the active M_balls ------------------
	  for ball_index := 0 to F_max_numbers do
			with m_balls.balls[ball_index] do
			  if is_active and (not in_bucket) then
			  begin
				  xpos := m_drum.radius + round(position.x);
				  ypos := m_drum.radius + round(position.y);

				  //------DEBUG- show M_balls below M_perturb_height------
				  if (not in_tube) and (position.y > m_drum.perturb_height) and (sqr_speed < MIN_PERTURB_SPEED) then
					  blit_ball_at(ball_index, xpos,ypos, Ball_flash,acanvas)
				  else
					  blit_ball_at(ball_index, xpos,ypos, ball_type,acanvas);
			  end;	//if
	end;  

	//************************************************************
	procedure TLotteryMachine.draw_ball_rack(Acanvas:Tcanvas);
	begin
	  if m_rack.draw_rack	then
		with acanvas do
		begin
			brush.color := clwhite;
			pen.color := clblack;
				polygon(M_rack.coords);
		end;
	end;


	//************************************************************
	// fast ball
	// ************************************************************
	procedure TLotteryMachine.blit_ball_at(ball_index, x,y:integer; the_type:TLottBallType;Acanvas:Tcanvas);
	var
	  machine_rect:Trect;
	  text_width, text_height: integer;
	  num_text:string;
	  text_locator: Tpoint;
	  old_colour : tcolor;
	begin
	  //-------set up rectangle to clip from offsceen bitmap-------
	  with machine_rect do
	  begin
			top := y - m_balls.ball_radius;
			left := x - m_balls.ball_radius;
		bottom := y + m_balls.ball_radius;
		 right := x + m_balls.ball_radius;
	  end;

	  //----blit-----------------------------------------------
	  m_balls.balls_struct.blit_ball(
		ball_index,
		 ACanvas,
		 machine_rect,
		 the_type);

	  //---------- and the text -------------------------------
	  if m_balls.display_number then
	  begin
			old_colour := Acanvas.font.color;

			Acanvas.font.size := FONT_SIZE;
			num_text := inttostr(ball_index);
			text_width := acanvas.textwidth(num_text);
			text_height := acanvas.textheight(num_text);

			text_locator.x := x - (text_width div 2);
			text_locator.y := y - (text_height div 2);

			Acanvas.font.color := clwhite;
			Acanvas.textout( text_locator.x-1, text_locator.y-1, num_text);
			Acanvas.textout( text_locator.x+1, text_locator.y+1, num_text);
			Acanvas.font.color := clblack;
			Acanvas.textout( text_locator.x, text_locator.y, num_text);

			Acanvas.font.color := old_colour;
	  end;

	end;

	//************************************************************
	// these also have a central hub with spokes connected to the paddles.
	// ************************************************************
	procedure TLotteryMachine.draw_front_paddles(Acanvas:Tcanvas);
	var
		dx1,dy1,dx2,dy2,dx3,dy3,paddle:integer;
		xpos, ypos:integer;
		ball_index:lottoball;
		cosangle,sinangle:real;
		angle:degree;
		triangle: array[1..3] of Tpoint;
	begin

	  //--------------------work through each paddle--------------------
	  angle := m_paddles.front_paddle.angle;
	  for paddle := 1 to 3 do
	  begin
		 //--------------calculate where the bucket goes----------------
		 cosangle := the_cos(angle);
		 sinangle := the_sine(angle);

		 dx1 := round(m_drum.radius * cosangle);
		 dy1 := round(m_drum.radius * sinangle);
		 dx2 := round((m_drum.radius-m_balls.ball_radius) * cosangle);
		 dy2 := round((m_drum.radius-m_balls.ball_radius) * sinangle);
		 dx3 := round(m_drum.radius * the_cos(angle+BUCKET_SHAPE_ANGLE));
		 dy3 := round(m_drum.radius * the_sine(angle+BUCKET_SHAPE_ANGLE));

		 triangle[1].x := m_drum.radius + dx1;
		 triangle[1].y := m_drum.radius + dy1;
		 triangle[2].x := m_drum.radius + dx2;
		 triangle[2].y := m_drum.radius + dy2;
		 triangle[3].x := m_drum.radius + dx3;
		 triangle[3].y := m_drum.radius + dy3;

		 //---remember the point where the where the spoke hits the drum----
		 m_paddles.front_paddle.spokes[paddle].x := dx2;
		 m_paddles.front_paddle.spokes[paddle].y := dy2;

		 //-------draw the ball in this paddle------------------------
		 ball_index := m_paddles.front_paddle.buckets[paddle];
		 if ball_index <> INVALID_LOTTERY_NUMBER then
		 begin
			 xpos := m_drum.radius + dx2;
			 ypos := m_drum.radius + dy2;
			 blit_ball_at( ball_index, xpos, ypos, m_balls.balls[ball_index].ball_type,acanvas);
		 end;

		//-------------draw the polygon and line to hub-----------------
		 with acanvas do
		 begin
			brush.color := clwhite;
			brush.style := bssolid;

			pen.color := clblack;
			polygon(triangle);
			moveto(m_drum.radius,m_drum.radius);
			pen.mode := pmNot;	
			lineto(triangle[2].x, triangle[2].y);
			pen.mode := pmcopy;
		 end;

		 //--------------------the next paddle is 120 degrees away-----
		 angle := g_misclib.inc_degree(angle, PADDLE_SPACING);
	  end;

	  //--------------- draw hub --------------------------
	  with acanvas do
	  begin
			pen.color := clblack;
		ellipse(
			m_drum.radius-m_balls.ball_radius, m_drum.radius-m_balls.ball_radius,
			m_drum.radius+m_balls.ball_radius, m_drum.radius+m_balls.ball_radius);
	  end;

	end;

	//************************************************************
	procedure TLotteryMachine.draw_picked_ball(poCanvas:tcanvas);
	var
		xpos, ypos:integer;
		ball_type: TLottBallType;
	begin
		with m_picked_ball do
			if being_picked then
			begin
				 xpos := m_drum.radius + dx;
				 ypos := (2 * m_drum.radius) - m_balls.ball_radius;
				 if flash then
					ball_type:= Ball_flash
				 else
					ball_type := m_balls.balls[ball].ball_type;

				 blit_ball_at( ball, xpos, ypos, ball_type,poCanvas);
			end;
	end;
	
	//************************************************************
	// use a pre-rendered ball in a resource
	// ************************************************************
	procedure TLotteryMachine.adjust_bitmaps;
	var
	  ball_diameter: integer;
	begin
	  ball_diameter := m_balls.ball_radius * 2;

	  //-------------draw the M_balls	------------
	  m_balls.balls_struct.Diameter:= ball_diameter;
	end;


  //***************************************************************
	// (x + t*dx)^2 + (y + t*dy)^2 = r^2
  // (x^2 + 2*t*x*dx + t^2*dx^2) + (y^2 + 2*t*y*dy + t^2*dy^2) = r^2
  // (xy)^2-r^2 + 2*t*(x*dx+y*dy) + t^2*(dx^2+dy^2) = 0
  // gives a qudratic which is computationally expensive to solve
  // so try an discrete incremental approach.
	function TLotteryMachine.get_point_of_impact(position, velocity: tvector; r2:integer): real;
  begin
		result := 0.0;
  end;



//
//####################################################################
(*
	$History: Machine.pas $
 * 
 * *****************  Version 4  *****************
 * User: Sunil        Date: 6/06/05    Time: 0:24
 * Updated in $/PAGLIS/lottery
 * added new property to control how fast bitmaps are changed
 * 
 * *****************  Version 3  *****************
 * User: Sunil        Date: 5/06/05    Time: 1:25
 * Updated in $/PAGLIS/lottery
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/lottery
 * 
 * *****************  Version 11  *****************
 * User: Administrator Date: 7/06/04    Time: 10:57
 * Updated in $/code/paglis/lottery
 * added feature to pick a ball immediately
 * 
 * *****************  Version 10  *****************
 * User: Administrator Date: 5/05/04    Time: 23:14
 * Updated in $/code/paglis/lottery
 * split out image misc and it all sort of works
 * 
 * *****************  Version 9  *****************
 * User: Administrator Date: 24/04/04   Time: 14:40
 * Updated in $/code/paglis/lottery
 * 
 * *****************  Version 8  *****************
 * User: Administrator Date: 5/08/03    Time: 10:38
 * Updated in $/code/paglis/lottery
 * changed data type for lotteryballs
 * 
 * *****************  Version 7  *****************
 * User: Sunil        Date: 15-04-03   Time: 12:34a
 * Updated in $/code/paglis/lottery
 * changed the way rendered balls are drawn, still some improvements to
 * make yet.
 * 
 * *****************  Version 6  *****************
 * User: Sunil        Date: 12-04-03   Time: 11:49a
 * Updated in $/code/paglis/lottery
 * changed behaviour of rendered balls, uses propoerties instead of
 * passing stuff in.
 * 
 * *****************  Version 5  *****************
 * User: Sunil        Date: 6-04-03    Time: 11:29p
 * Updated in $/code/paglis/lottery
 * shows ball being ejected from machine
 * 
 * *****************  Version 4  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/lottery
 * added headers and footers
*)
//####################################################################
//
end.
