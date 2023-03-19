unit Shwrchck;
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
(* $Header: /PAGLIS/confidential/Shwrchck.pas 1     14/02/05 22:17 Sunil $ *)
//****************************************************************
//

interface
uses
	Windows,
	sysutils, Classes, dialogs, Inifile,shellapi, reg, internet;
type
	TregisterResult = (RegNone,RegYes,RegTemp,RegPerm,RegNo,RegBadSerial,RegExpired,RegHacked, RegHackedSerial, RegNoConnection);

	ESharewareChecker = class (Exception);

	TSharewareData = record
		name, name_code, date, date_code, checked_date, checked_date_code:string;
	end;

	{######################################################################}
	TSharewareChecker = class(TComponent)
	PROTECTED
	private
		{----------------------------------------------------------------------}
		F_program_name, ini_program_name, F_Key, f_registered_to :String;
		F_First_time, F_not_registered, F_Hacked, f_serial_hacked, F_expired: string;
		F_registered_ok, F_password_bad, F_message: string;
		f_copyright:string;
		F_Quiet: Boolean;
		f_show_success_alert: boolean;
		F_has_grace_period: Boolean;
		F_grace_period: byte;
		c_personal_key:String;
		c_data_has_been_read:boolean;
		f_ignore_serial_check: boolean;
		f_bypass_all_checks: boolean;
		f_bypassed_serial_number: string;
		f_email: string;
		f_url: string;

		c_ini_data, c_reg_data:TSharewareData;
		c_registry: Tregistry;

		{----------------------------------------------------------------------}
		procedure pr_blurt(what:string);

		function pr_is_program_registered:TregisterResult;
		function pr_register_program( psUserName,psPassword,psDiskSerial:string):TregisterResult;
		function pr_get_expiry_date:tdatetime;
		procedure pr_set_program_name(value:string);

		function pr_read_from_ini:TSharewareData;
		procedure pr_write_to_ini(data:TSharewareData);
		function pr_read_from_reg:TSharewareData;
		procedure pr_write_to_reg(data:TSharewareData);

		function compare_reg_ini_data:boolean;
		function reg_data_is_empty:boolean;
		function Generate_registration_data(in_data:TsharewareData; for_ini:boolean): TsharewareData;
		function data_matches(data_1,data_2:TsharewareData):boolean;
		function check_time_stamp(data:TsharewareData):TregisterResult;

		procedure time_stamp_registry;

		function get_personal_key:string;
		procedure check_program_name(program_name:string);
		function compare_personal_key: boolean;
		function generate_personal_key(key:string):string;
		function pr_get_password(ps_user_name:string; ps_serial_num:string):string;

  protected
	{ Protected declarations }
  public
	 { Public declarations }
		property IgnoreSerialCheck: boolean write f_ignore_serial_check;
		property ByPassAllChecks:boolean write f_bypass_all_checks;
		procedure read_data(force:boolean);
		constructor create(Aowner:Tcomponent); override;
		destructor Destroy; override;

		function Check_registered: TregisterResult;
		function register(psUsername, psPassword, psDiskSerial: string):boolean;
		function webregister(psEmail:string):TregisterResult;
		function is_registered:boolean;

	published
	 { Published declarations }
		property Expired: String read F_expired write F_expired;
		property Copyright: string read F_copyright write F_copyright;
		property FirstTime: String read F_First_time write F_First_time;
		property GracePeriod: Byte read F_grace_period write F_grace_period;
		property SerialHacked: String read F_serial_hacked write F_serial_hacked;
		property Hacked: String read F_hacked write F_hacked;
		property HasGracePeriod: Boolean read F_has_grace_period write F_has_grace_period;
		property Key: String read F_Key write F_Key;
		property NotRegistered: String read F_not_registered write F_not_registered;
		property PasswordBad:string read F_password_bad write F_password_bad;
		property ProgramName: String read F_program_name write pr_set_program_name;
		property Quiet: boolean read F_quiet write F_quiet;
		property RegisteredOk: string read F_registered_OK write F_registered_OK;
		property TheMessage: string read f_message;
		property SuccessAlert: boolean read f_show_success_alert write f_show_success_alert;
		property RegisteredTo: string read f_registered_to;
		property Email: string read f_email write f_email;
		property URL: string read f_url write f_url;
	end;

	{######################################################################}
	procedure Register;

implementation
uses
	misclib, miscstrings, miscencode, misccrypt, translator,shwrgen;

const
	DEFAULT_FIRST_TIME = 'Configuring for first use - hope you like it';
	DEFAULT_NOT_REGISTERED = 'This program is shareware.';
	DEFAULT_HACKED = 'The program configuration is corrupt!!' + CRLF +'Please enter your registration details again.';
	DEFAULT_SERIAL_HACKED = 'The program configuration is corrupt!!' + CRLF + 'This programs uses unique information about your computer.' + crlf + 'It appears that this copy of picker was registered for another computer. Please contact the author now.';
	DEFAULT_EXPIRED =
	 'You must register this program now.' + CRLF +
	 'Continued unregistered use of this program breaches International Law!';
	DEFAULT_QUIET = false;
	DEFAULT_REGISTERED_OK = 'Thankyou for registering this program';
	DEFAULT_PASSWORD_BAD = 'Unable to register program. Check the username and passwords';
	DEFAULT_HAS_GRACE_PERIOD = true;
	DEFAULT_GRACE_PERIOD = 30;
	BUFSIZ=40;
	NO_REG_INFORMATION = 'NO REG INFO';
	NOT_REGISTERED = 'NOT REGISTERED';
	DEFAULT_URL = 'http://www.paglis.co.uk/peehpee/shareware/index.php';

	REGISTRATION_SECTION = 'REGISTRATION_INFORMATION';
	REG_LENGTH=16;
	REG_ENCRYPTED_LENGTH=20;

	REG_DATE_KEY = 'Apple';
	REG_NAME_KEY = 'Pear';
	REG_LAST_CHECKED_KEY = 'Orange';
	REG_ENCRYPTED_DATE_KEY = 'Cherry';
	REG_ENCRYPTED_NAME_KEY = 'Guava';
	REG_ENCRYPTED_LAST_CHECKED_KEY = 'Pineapple';

	REG_PERSONAL_ROOT_KEY = 'Software\Microsoft\Shared Tools\silgaP';
	REG_PERSONAL_KEY = 'Mandarin';
	REG_PERSONAL_RANDOM = 'Banana';
	PERSONAL_KEY_LENGTH = 12;

	PREFIX_REG = 'REG';
	PREFIX_INI = 'INI';
	CLEAR_USERNAME = 'clear';

	{######################################################################}
	procedure Register;
	begin
		RegisterComponents('Paglis Utils', [TSharewareChecker]);
	end;

	{######################################################################}
	constructor TSharewareChecker.create(Aowner:Tcomponent);
	var
		dd,mm,yy:word;
	begin
		inherited create(aowner);

		{-------------------------------------------------------}
		ShortDateFormat := 'dd/mm/yyyy';
		c_registry := Tregistry.Create;
		f_ignore_serial_check := false;
		f_bypass_all_checks := false;
		f_email := 'no email provided';
		f_url := DEFAULT_URL;
		
		{-------------------------------------------------------}
		f_show_success_alert := true;
		f_registered_to := localstring('unknown');
		F_First_time := DEFAULT_FIRST_TIME;
		F_not_registered := DEFAULT_NOT_REGISTERED;
		F_Hacked := DEFAULT_HACKED;
		F_serial_hacked := DEFAULT_SERIAL_HACKED;
		F_expired := DEFAULT_EXPIRED;
		F_quiet := DEFAULT_QUIET;
		F_program_name := '';
		F_key := '';
		F_Registered_ok := DEFAULT_REGISTERED_OK ;
		F_PASSWORD_BAD := DEFAULT_PASSWORD_BAD;
		F_has_grace_period := DEFAULT_HAS_GRACE_PERIOD;
		F_grace_period := DEFAULT_GRACE_PERIOD;

		{-------------------------------------------------------}
		c_personal_key := get_personal_key;

		{-------------------------------------------------------}
		decodedate(date,yy,mm,dd);
		F_copyright := 'Copyright 1997-' + inttostr(yy) + ' Sunil Gupta, Berkshire UK';

		c_data_has_been_read := false;
	end;

	{**********************************************************}
	destructor TSharewareChecker.Destroy;
	begin
		if assigned(c_registry) then	  c_registry.free;

		inherited Destroy;
	end;

	{######################################################################}
	procedure TSharewareChecker.pr_blurt(what:string);
	begin
		if not f_quiet then
			messageDlg(what,mtinformation,[mbok],0);
		f_message := what;
	end;

	{**********************************************************}
	procedure TSharewareChecker.read_data(force:Boolean);
	begin
		if (not force) and c_data_has_been_read then exit;

		c_ini_data := pr_read_from_ini;
		c_reg_data := pr_read_from_reg;

		c_data_has_been_read := true;
	end;

	{**********************************************************}
	procedure TSharewareChecker.check_program_name(program_name:string);
	begin
		if program_name = '' then
			raise ESharewareChecker.Create('No program name has been set!');
	end;

	//######################################################################
	//# PROPS
	//######################################################################
	procedure TSharewareChecker.pr_set_program_name(value:string);
	begin
		if value <> f_program_name then
		begin
			F_program_name := value;
			if length(f_program_name) > 8 then
			 ini_program_name := g_miscstrings.left_string(f_program_name,8)
			else
			 ini_program_name := f_program_name;
			ini_program_name := ini_program_name + '.INI';

			f_key := g_misccrypt.get_standard_cipherkey(f_program_name);
			read_data(true);
		end;
	end;

	//######################################################################
	//# PROCESS
	//######################################################################
	function TSharewareChecker.webregister(psEmail:string):TregisterResult;
	var
		oInternetFuncs: tmiscinternet;
		bConnected: boolean;
		sEncodedEmail,sUrl,sResponse, sGeneratedKey,sSerial,sEncodedSerial: string;
	begin
		sSerial:=g_misccrypt.get_serial_number;
		
		//1-------------- is there a connection to the internet --------------
		oInternetFuncs := TMiscInternet.Create;
		try
			bConnected := oInternetFuncs.IsConnectedToInternet(f_url);

			if not bconnected then
			begin
				pr_blurt ( localstring('No internet connection detected'));
				result :=  RegNoConnection;
				exit;
			end;

			//-------fetch the password from the server ---------------
			sEncodedEmail := oInternetFuncs.encode(psEmail);
			sEncodedSerial := oInternetFuncs.encode(sSerial);
			sUrl := f_url + '?email=' + sEncodedEmail + '&program=' + F_program_name + '&serial=' + sEncodedSerial;
			sResponse := oInternetFuncs.get(sUrl);
		finally
			oInternetFuncs.Free;
		end;

		//--------if password is "unknown", this isnt a known email address
		if (sResponse = 'unknown') then	begin
			pr_blurt ( localstring('Sorry, email address isnt registered'));
			result := RegNo;
			exit;
		end;
		if (sResponse = 'bad') then	begin
			pr_blurt ( localstring('Sorry, serial number doesnt match'));
			result := RegHackedSerial;
			exit;
		end;

		//2 --------------validate --------
		sGeneratedKey := get_web_password(psEmail,F_Key ,REG_LENGTH);
		if sGeneratedKey <> sResponse then begin
			pr_blurt ( localstring('Sorry, email or serial number do not match'));
			result := RegHackedSerial;
			exit;
		end;

		//3 --------------full registration --------
		sGeneratedKey := pr_get_password(psEmail,sSerial);
		if register(psEmail,sGeneratedKey, sSerial) then
			Result := RegYes
		else
			result := RegNo;
	end;

	//**********************************************************
	function TSharewareChecker.register(psUsername, psPassword, psDiskSerial: string):boolean;
	var
		register_result: TregisterResult;
	begin
		check_program_name(f_program_name);

		register_result := pr_register_program(psUsername, psPassword, psDiskSerial);
		if register_result = regyes then begin
			 result := true;
			 if f_show_success_alert then
				pr_blurt(F_registered_ok);
		end else begin
			result := false;
			case register_result of
				RegBadSerial:
					pr_blurt(F_password_bad + CRLF + LocalString('The Serial used to generate the key does not match the serial number of your computer'));
				RegHacked:
					pr_blurt(F_password_bad + CRLF + LocalString('Some system settings needed for registration appear are inconsistent'));
				else
					pr_blurt(F_password_bad);
			end;
		end;
	end;

	//**********************************************************
	function TSharewareChecker.is_registered:boolean;
	var
		was_quiet:boolean;
		status:Tregisterresult;
	begin
		was_quiet := F_quiet;
		f_quiet := true;
		status := check_registered;
		result := (status = regyes);
		f_quiet := was_quiet;
	end;


	{**********************************************************
	 find out whether the current application is registered
	 puts information into ini file and windows c_registry.
	 Two entries mean that its possible to detect if
	 someone has tried to get around the registration procedure.
	 not hacker-proof.

	 Added code to check when last checked to reduce hackability.
	 uses a personal key stored elsewhere in the c_registry.
	**********************************************************}
	function TSharewareChecker.pr_is_program_registered:TregisterResult;
	var
		 compare_ini_data, compare_reg_data: TsharewareData;
	begin

		read_data(true);

		//--------------------------------------------------------------------------------
		//check that the personal key hasnt been tampered with
		if not compare_personal_key then
		begin
			result := RegHackedSerial;
			exit;
		end;

		//--------------------------------------------------------------------------------
		//--- check that both ini and reg have similar plaintext data. }
		if not compare_reg_ini_data then
		begin
			result := regHacked;
			exit;
		end;

		//--------------------------------------------------------------------------------
		{-------- if c_registry is empty, program hasnt been run before---------}
		if reg_data_is_empty then
		begin
			result := regNone;
			exit
		end;

		{-------- compare encrypted data ---------}
		compare_ini_data := Generate_registration_data(c_ini_data, true);
		if not data_matches(c_ini_data, compare_ini_data) then
		begin
			result := regHacked;
			exit;
		end;

		compare_reg_data := Generate_registration_data(c_reg_data, false);
		if not data_matches(c_reg_data, compare_reg_data) then
		begin
			result := regHacked;
			exit;
		end;

		{-------- if a valid username, stop right here---------}
		if c_ini_data.name <> NOT_REGISTERED then
		begin
			result := RegYes;
			exit;
		end;

		{---------update timestamp in c_registry ---------------}
		time_stamp_registry;
		result := check_time_stamp(c_ini_data)
	end;

	{**********************************************************
	 save the registration information to the ini file and the windows
	 registration, doesnt check anything.
	**********************************************************}
	function TSharewareChecker.pr_register_program(psUserName, psPassword,psDiskSerial:string):TregisterResult;
	var
		 sVerifyPassword, sVerifySerial: string;
		 in_data:tsharewaredata;
	begin

		{---------------------check the supplied password------------------------}
		if not f_bypass_all_checks then
		begin
			if not f_ignore_serial_check then begin
				sVerifySerial := g_misccrypt.get_serial_number;
				if sVerifySerial <> psDiskSerial then begin
					result := RegBadSerial;	  {passwords didnt match}
					exit;
				end;
			end;
			f_ignore_serial_check := false;		//reset serial check everytime

			//----------------------------------------------------------------------
			sVerifyPassword := pr_get_password(psUserName, psDiskSerial);
			if psPassword <> sVerifyPassword then
			begin
				result := regno;	  {passwords didnt match}
				exit;
			end;
		end;

		{---------------------reset registration detrails------------------------}
		if ( pos(CLEAR_USERNAME, psUserName) = 1) then
		begin
			showmessage(LocalString('Clearing registration details'));
			psUserName := '';
		end;

		{--------------------- copy data into structure -----------------------}
		in_data.name := psUserName;
		if (in_data.name = '') then  in_data.name := NOT_REGISTERED;
		in_data.date := DateToStr(Date);
		in_data.checked_date := '';

		{--------------------- generate encrypted codes -----------------------}
		c_ini_data := Generate_registration_data(in_data,true);
		pr_write_to_ini(c_ini_data);
		c_reg_data := Generate_registration_data(in_data,false);
		pr_write_to_reg(c_reg_data);

		{-----------------------ok all done, go back to your stations------------------}
		c_data_has_been_read := false;
		result := regyes;
	end;

	{**********************************************************
	-----------------return when the program expired-------------
	**********************************************************}
	function TSharewareChecker.pr_get_expiry_date:tdatetime;
	var
		 is_registered: TregisterResult;
	begin
		 read_data(false);

		 {-----------------------display depending on result-----------------------}
		 is_registered := pr_is_program_registered;
		 case is_registered of
			RegYes:
				result := encodedate(0,0,0);

			 RegNo, regexpired:
				result := StrToDate(c_ini_data.date) + F_grace_period;

			else
				result := encodedate(9999,12,31);
		 end;
	end;

	{**********************************************************}
	function TSharewareChecker.Check_registered: TregisterResult;
	var
		registered:TregisterResult;
		expiry_date: Tdatetime;
		days_since_expiry:integer;
	begin
		check_program_name(f_program_name);
		 registered := pr_is_program_registered;

		 case registered of
			 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
			 RegNone:
				begin
				 pr_blurt (localstring(F_First_time));
				 f_bypass_all_checks := true;
				 pr_register_program('','','');
				end;

			 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
			 RegNo:
				if F_has_grace_period then
					 begin
					expiry_date := pr_get_expiry_date;
					pr_blurt (
						  F_not_registered + CRLF + CRLF +
					  LocalString('Program expires on #' + DateToStr(expiry_date) +'#') + CRLF +
					  LocalString('You are advised to register well before then.') +crlf + crlf +
					  F_copyright
					);
				end
				else
				pr_blurt (localstring(F_not_registered));

			 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
			 RegHacked:
				pr_blurt (localstring(F_hacked));

			 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
			 RegHackedSerial:
				pr_blurt (localstring(F_Serial_hacked));

			 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
			 RegExpired: begin
				 expiry_date := pr_get_expiry_date;
				 days_since_expiry := trunc(date- expiry_date);
					pr_blurt(
					  LocalString(
						'It''s been #' + inttostr(days_since_expiry) +  '# days since the program expired.'
						+ CRLF + crlf+ F_expired)
					);
				end;

			 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
			 RegYes: begin
				f_registered_to :=  c_ini_data.name;
				if f_show_success_alert then
					pr_blurt (LocalString('registered to: #' + f_registered_to + '#'));
			 end;
		end;
		Check_registered := registered;
	end;

	{*********************************************************}
	function TSharewareChecker.get_personal_key:string;
	var
		program_hkey:hkey;
		personal_key, random_string:string;
		reg_result:longint;
	begin
		reg_result := c_registry.create_key(HKEY_CURRENT_USER, REG_PERSONAL_ROOT_KEY, program_hkey);
		if reg_result = ERROR_SUCCESS then
		begin	{.}
			personal_key := c_registry.query_value(program_hkey, REG_PERSONAL_KEY, NO_REG_INFORMATION);
			if personal_key = NO_REG_INFORMATION then
			begin {..}
				random_string := g_miscstrings.random_string(7,'');
				personal_key := generate_personal_key(random_string);

				c_registry.set_value(program_hkey ,REG_PERSONAL_KEY, personal_key);
				c_registry.set_value(program_hkey ,REG_PERSONAL_RANDOM, random_string);
			end; {..}
			c_registry.close_key(program_hkey);
		end;	{.}

		get_personal_key :=	personal_key;
	end;


	//######################################################################
	//# CHECK
	//######################################################################
{**********************************************************}
	function TSharewareChecker.compare_reg_ini_data:boolean;
	begin
		compare_reg_ini_data	:= false;

		if c_ini_data.name <> c_reg_data.name then exit;
		if c_ini_data.date <> c_reg_data.date then exit;

		compare_reg_ini_data := true;

	end;

	{**********************************************************}
	function TSharewareChecker.reg_data_is_empty:boolean;
	begin
		reg_data_is_empty := false;

		with c_reg_data do
		begin
			if name <> NOT_REGISTERED then exit;
			if name_code <> NO_REG_INFORMATION then exit;
			if date <> NO_REG_INFORMATION then exit;
			if date_code <> NO_REG_INFORMATION then exit;
			if checked_date <> NO_REG_INFORMATION then exit;
			if checked_date_code <> NO_REG_INFORMATION then exit;
		end;

		 reg_data_is_empty := true;
	end;


	{**********************************************************}
	function TSharewareChecker.Generate_registration_data(in_data:TsharewareData; for_ini:boolean): TsharewareData;
		var out_data:TsharewareData;
		var encrypted_code:string;
	begin

		with out_data do
		begin
			{----------------------------------------------------------------------}
			name := in_data.name;
			if for_ini then
				begin
				  encrypted_code := pr_get_password(name, g_misccrypt.get_serial_number);
				  name_code := g_misccrypt.feedback_encode(encrypted_code ,F_key,REG_ENCRYPTED_LENGTH);
				end
			ELSE
				name_code := g_misccrypt.feedback_encode(name ,c_personal_key,REG_LENGTH);

			{----------------------------------------------------------------------}
			date := in_data.date;
			if for_ini then
				date_code := g_misccrypt.feedback_encode(date+Prefix_INI,F_Key,REG_LENGTH)
			ELSE
				date_code := g_misccrypt.feedback_encode(date ,c_personal_key,REG_LENGTH);

			{----------------------------------------------------------------------}
			if for_ini then
				begin
				  checked_date := '';
				  checked_date_code := '';
				end
			ELSE
				begin
				  checked_date := in_data.checked_date;
				  if (checked_date='') or (checked_date=NO_REG_INFORMATION) then
					  checked_date := date;
				  checked_date_code := g_misccrypt.feedback_encode(checked_date,c_personal_key,REG_LENGTH);
				end;
		end;

		Generate_registration_data := out_data;
	end;

	{****only check name and date *****************************}
	function TSharewareChecker.data_matches(data_1,data_2:TsharewareData):boolean;
	begin
		data_matches := false;

		with data_1 do
		begin
			if (name <> data_2.name) then exit;
			if (name_code <> data_2.name_code) then exit;
			if (date <> data_2.date) then exit;
			if (date_code <> data_2.date_code) then exit;
			if (checked_date <> '') and	(checked_date_code <> '') then
			begin
				if (checked_date <> data_2.checked_date) then exit;
				if (checked_date_code <> data_2.checked_date_code) then exit;
			end;
		end;

		data_matches := true;
	end;

	{*************************************************************}
	function TSharewareChecker.check_time_stamp(data:TsharewareData):TregisterResult;
	var
		 ini_date_value, now_date_value: TDateTime;
	begin
		{---------------If there's no grace period then its not registered------------}
		if not f_has_grace_period then
		begin
			check_time_stamp := RegNo;
			exit;
		end;

		{---------------has the registration period expired------------}
		try
			now_date_value := Date;
			ini_date_value := StrToDate(c_ini_data.date) -1.0;

			if (now_date_value - ini_date_value) > F_grace_period then
				check_time_stamp := RegExpired
			else
				check_time_stamp := RegNo;
		except
			on EConvertError do
				  check_time_stamp := RegHacked;
		end;
	end;

	{*************************************************************}
	function TSharewareChecker.pr_get_password(ps_user_name:string; ps_serial_num:string):string;
	begin
		result := get_encoded_password(ps_user_name,ps_serial_num,F_Key ,REG_LENGTH);
	end;
	
	//######################################################################
	//# IO INI FILE
	//######################################################################
	function TSharewareChecker.pr_read_from_ini:TSharewareData;
	var
		ini_file:Tinifile;
		data: TSharewareData;
	begin
		 {-----------------------read from the ini file----------------------------}
		 ini_file := TInifile.Create(ini_program_name);

		 with data do
		 begin
			name := ini_file.read(REGISTRATION_SECTION, REG_NAME_KEY,NOT_REGISTERED);
			name_code := ini_file.read(REGISTRATION_SECTION,REG_ENCRYPTED_NAME_KEY,NO_REG_INFORMATION);
			date := ini_file.read(REGISTRATION_SECTION,REG_DATE_KEY, NO_REG_INFORMATION);
			date_code := ini_file.read(REGISTRATION_SECTION,REG_ENCRYPTED_DATE_KEY, NO_REG_INFORMATION);
			checked_date := '';
			checked_date_code := '';
		 end;


		 ini_file.free;
		 pr_read_from_ini := data;
	end;

	{**********************************************************}
	procedure TSharewareChecker.pr_write_to_ini(data:TSharewareData);
	var
		ini_file:Tinifile;
	begin
		 ini_file := TInifile.Create(ini_program_name);

		 with data do
		 begin
			ini_file.write(REGISTRATION_SECTION, REG_NAME_KEY,name);
			ini_file.write(REGISTRATION_SECTION,REG_ENCRYPTED_NAME_KEY,name_code);
			ini_file.write(REGISTRATION_SECTION,REG_DATE_KEY, date);
			ini_file.write(REGISTRATION_SECTION,REG_ENCRYPTED_DATE_KEY, date_code);
		 end;

		 ini_file.free;
	end;

	//######################################################################
	//# IO c_registry
	//######################################################################
	function TSharewareChecker.pr_read_from_reg:TSharewareData;
	var
		program_hkey:hkey;
		reg_result:longint;
		data: TSharewareData;
	begin
		 {------------------initialise variables ----------------}
		 with data do
		 begin  {.}
			name := NOT_REGISTERED;
			name_code := NO_REG_INFORMATION;
			date := NO_REG_INFORMATION;
			date_code := NO_REG_INFORMATION;
			checked_date := NO_REG_INFORMATION;
			checked_date_code := NO_REG_INFORMATION;

			{------------------read info from windows registration ----------------}

			reg_result := g_misccrypt.get_program_key(c_registry,program_hkey,f_program_name);
			if reg_result = ERROR_SUCCESS then
			begin {..}
				 name := c_registry.query_value(program_hkey, REG_NAME_KEY,NOT_REGISTERED);
				 name_code := c_registry.query_value(program_hkey, REG_ENCRYPTED_NAME_KEY, NO_REG_INFORMATION);
				 date := c_registry.query_value(program_hkey, REG_DATE_KEY, NO_REG_INFORMATION);
				 date_code := c_registry.query_value(program_hkey, REG_ENCRYPTED_DATE_KEY, NO_REG_INFORMATION);
				 checked_date:= c_registry.query_value(program_hkey, REG_LAST_CHECKED_KEY, NO_REG_INFORMATION);
				 checked_date_code:= c_registry.query_value(program_hkey, REG_ENCRYPTED_LAST_CHECKED_KEY, NO_REG_INFORMATION);

				 c_registry.close_key(program_hkey);
			end;{..}
		 end; {.}
		 pr_read_from_reg := data;
	end;

	{**********************************************************}
	procedure TSharewareChecker.time_stamp_registry;
	var

		reg_result:longint;
		program_hkey:hkey;
		checked_date, checked_date_code:string;
	begin
		 checked_date := datetoStr(date);
		 checked_date_code := g_misccrypt.feedback_encode(checked_date,c_personal_key,REG_LENGTH);

		 reg_result := g_misccrypt.get_program_key(c_registry,program_hkey,f_program_name);
		 if reg_result = ERROR_SUCCESS then
		 begin
			c_registry.set_value(program_hkey, REG_LAST_CHECKED_KEY, checked_date);
			c_registry.set_value(program_hkey, REG_ENCRYPTED_LAST_CHECKED_KEY, checked_date_code);
			c_registry.Close_Key(program_hkey);
		 end;
	end;

	//**********************************************************}
	procedure TSharewareChecker.pr_write_to_reg(data:TSharewareData);
	var
		program_hkey:hkey;
		reg_result:longint;
	begin
		 {-------------------- write info to windows registration ----------------}
		 reg_result := g_misccrypt.get_program_key(c_registry,program_hkey,f_program_name);
		 if reg_result = ERROR_SUCCESS then
		 begin
			c_registry.set_value(program_hkey, REG_NAME_KEY, c_reg_data.name);
			c_registry.set_value(program_hkey, REG_ENCRYPTED_NAME_KEY, c_reg_data.name_code);
			c_registry.set_value(program_hkey, REG_DATE_KEY, c_reg_data.date);
			c_registry.set_value(program_hkey, REG_ENCRYPTED_DATE_KEY, c_reg_data.date_code);
			c_registry.set_value(program_hkey, REG_LAST_CHECKED_KEY, c_reg_data.checked_date);
			c_registry.set_value(program_hkey, REG_ENCRYPTED_LAST_CHECKED_KEY, c_reg_data.checked_date_code);

			c_registry.Close_Key(program_hkey);
		 end;
	end;

	//**********************************************************}
	function TSharewareChecker.compare_personal_key: boolean;
	var
		reg_result:longint;
		personal_hkey: hkey;
		reg_random, reg_encoded, encoded: string;
	begin
		result := false;
		
		reg_result := c_registry.open_Key(HKEY_CURRENT_USER, REG_PERSONAL_ROOT_KEY, personal_hkey);
		if reg_result = ERROR_SUCCESS then
		begin
			reg_random  := c_registry.query_value(personal_hkey, REG_PERSONAL_RANDOM, NO_REG_INFORMATION);
			reg_encoded := c_registry.query_value(personal_hkey, REG_PERSONAL_KEY, NO_REG_INFORMATION);

			encoded := generate_personal_key(reg_random);

			if encoded = reg_encoded then
				result := true;
			 
		c_registry.close_key( personal_hkey);
		end;

	end;

	//**********************************************************}
	function TSharewareChecker.generate_personal_key(key:string):string;
	var
		encoded,serial_num:string;
	begin
		serial_num := g_misccrypt.get_serial_number;
		encoded := g_misccrypt.feedback_encode(serial_num ,key,REG_LENGTH);
		result := g_miscencode.hex_encode(encoded);
	end;


//
//####################################################################
(*
	$History: Shwrchck.pas $
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:17
 * Created in $/PAGLIS/confidential
 * 
 * *****************  Version 10  *****************
 * User: Administrator Date: 23/09/04   Time: 11:10p
 * Updated in $/code/paglis/controls
 * 
 * *****************  Version 9  *****************
 * User: Administrator Date: 22/09/04   Time: 11:30p
 * Updated in $/code/paglis/controls
 * web register functionality complete
 * 
 * *****************  Version 8  *****************
 * User: Administrator Date: 4/07/04    Time: 17:30
 * Updated in $/code/paglis/controls
 * added ability to bypass disk serial test to allow checking of
 * registration codes for machines with different serial numbers
 * 
 * *****************  Version 7  *****************
 * User: Administrator Date: 2/06/04    Time: 23:48
 * Updated in $/code/paglis/controls
 * forces re-reading data when checking registration
 * 
 * *****************  Version 6  *****************
 * User: Administrator Date: 2/06/04    Time: 23:24
 * Updated in $/code/paglis/controls
 * added on request from DW - does not blurt message on successful
 * registration check
 * 
 * *****************  Version 5  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/controls
 * added headers and footers
*)
//####################################################################
//
end.

