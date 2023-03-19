unit lotteryExtractor;

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
(* $Header: /PAGLIS/lottery/lotteryExtractor.pas 3     21/06/05 0:55 Sunil $ *)
//****************************************************************
//

interface
	uses classes,inifile, regexpr, lotrules;

const
	LOTTERY_EXTRACTOR_INI_FILENAME = 'extractor.ini';
type
	TLotteryExtractorOption = Class
	public
		game_name:string;
		filename:string;
		skip_until:string;
		process_until: string;
		expression:string;
		date_format:string;
		drawn_num_index:integer;
		number_index:integer;
		date_index: integer;
		number_count : integer;
		process_skip_until_line:boolean;
		autonumber:boolean;
		date_autonumber: boolean;
		reverse_autonumbers:boolean;
		rules:string;
	end;

	TlotteryExtractor = class
	private
		c_inifile: tinifile;
		c_list:tstringlist;
		c_rowsProcessed: integer;
		c_rules: TLotteryRules;
		function pr_get_options(ps_lottery_game:string): TLotteryExtractorOption;
		function pr_extract(po_options:TLotteryExtractorOption):tstringlist;
		function pr_index_of_html_break(const astring:string; pi_start:integer):integer;
		function pr_index_of_html(pi_prev_index: integer;const ps_astring, ps_lookfor:string; pi_start:integer):integer;
		function pr_line_matches_format(ps_line:string;po_format:TRegExpr):boolean;
		procedure pr_add_to_list( regexp:tregexpr; po_list:tstringlist; po_options:TLotteryExtractorOption);
		function pr_autonumber(po_options:TLotteryExtractorOption ;po_list: tstringlist): tstringlist;
	public
		constructor create;
		destructor destroy; override;
		procedure extract(DefinedName:String);
	end;

implementation
	uses miscStrings,sysutils, variants, filestream2;

	//################################################################################
	//#
	//################################################################################
	constructor TlotteryExtractor.create;
	begin
		inherited;
		c_list := tstringlist.create;
		c_inifile := Tinifile.Create(LOTTERY_EXTRACTOR_INI_FILENAME);
		c_rules := TLotteryRules.create;
	end;

	//********************************************************************************
	destructor TlotteryExtractor.destroy;
	begin
		c_inifile.Free;
		c_list.free;
		c_rules.free;
		inherited;
	end;

	//################################################################################
	//#
	//################################################################################
	procedure TlotteryExtractor.extract(DefinedName:String);
	var
		options: TLotteryExtractorOption;
		out_list: tstringlist;
	begin

		options := pr_get_options(DefinedName);
		try
			out_list := pr_extract(options);
			if (options.autonumber) and not (options.date_autonumber) then
				out_list := pr_autonumber(options, out_list );
			out_list.SaveToFile(options.game_name + '.out');
			out_list.Free;
		finally
			options.Free;
		end;

	end;

	//################################################################################
	//#
	//################################################################################
	function TlotteryExtractor.pr_extract(po_options:TLotteryExtractorOption): tstringlist;
	var
		 start_processing: boolean;
		html_buffer, raw_line, out_line:string;
		start_index, end_index, buffer_len:integer;
		out_list: tstringlist;
		regExp: TRegExpr;
	begin

		//******************** initilialise ************************************
		//compile regular expression
		regExp := TRegExpr.Create;
		regExp.Expression := po_options.expression;
		try
			regExp.Compile;
		except
			regExp.Free;
			raise Exception.Create('bad regular expression :' + po_options.expression);
			exit;
		end;

		//***************create an empty output list*************************
		out_list := TStringList.Create;	//output list
		c_rowsProcessed := 0;

        //********** figure out whether to start processing immediately or later
		start_processing := po_options.process_skip_until_line;
		if (not start_processing) and (po_options.skip_until = '') then
			start_processing := true;


		//******************** read file into buffer ****************************
		html_buffer := g_miscstrings.read_file(po_options.filename);
		start_index := 1;
		buffer_len := length(html_buffer);

		//***********************************************************************
		//process the buffer, looking for breaks;
		while start_index < buffer_len do
		begin
			end_index := pr_index_of_html_break(html_buffer, start_index);
			if end_index = 0 then
				end_index := buffer_len;

			raw_line := g_miscstrings.mid_string(html_buffer, start_index, end_index-start_index);

			//------------- strip out extra spaces and html ----------------
			out_line := g_miscstrings.strip_html(raw_line);
			out_line := g_miscstrings.collapse_spaces(out_line);
			out_line := g_miscstrings.trim(out_line);

			//---------- ignore blank lines------------------------------
			if out_line <> '' then
			begin

				//------------- is not allowed to start processing	----------------
				if not start_processing then
				begin
					if length(out_line) >= length(po_options.skip_until) then
						if g_miscstrings.instr( po_options.skip_until, out_line,1,true) > 0 then
							start_processing := true;
				end;

				//------------- do something with the line -------------
				if start_processing then
					if pr_line_matches_format(out_line,regExp) then
						pr_add_to_list( regexp, out_list, po_options);

				//------------- time to stop  ----------------
				if po_options.process_until <> '' then
				begin
					if length(out_line) >= length(po_options.process_until) then
						if g_miscstrings.instr( po_options.process_until, out_line,1,true) >0 then
							break;
				end;
			end;

			//-------------get ready for next line ------------------
			if end_index >= buffer_len then break;
			
			start_index := g_miscstrings.instr('>',html_buffer, end_index);
			if (start_index =0) then start_index := end_index;
			inc(start_index);
		 end;

		 regExp.Free;
		 result := out_list;
	end;

	//********************************************************************************
	function TlotteryExtractor.pr_get_options(ps_lottery_game:string): TLotteryExtractorOption;
	var
		po_options: TLotteryExtractorOption;
	begin
		po_options := TLotteryExtractorOption.create;
		po_options.game_name := ps_lottery_game;
		po_options.filename := c_inifile.read(ps_lottery_game, 'file', '');
		po_options.skip_until := c_inifile.read(ps_lottery_game, 'skip_until', '');
		po_options.date_format := c_inifile.read(ps_lottery_game, 'date_format', '');
		po_options.expression := c_inifile.read(ps_lottery_game, 'format', '');
		po_options.process_until := c_inifile.read(ps_lottery_game, 'process_until', '');
		po_options.process_skip_until_line := c_inifile.read(ps_lottery_game, 'process_skip_line', false);
		po_options.drawn_num_index := c_inifile.read(ps_lottery_game, 'draw num index', -1);
		po_options.number_index := c_inifile.read(ps_lottery_game, 'first num index', -1);
		po_options.number_count := c_inifile.read(ps_lottery_game, 'n_balls', 1);
		po_options.autonumber := c_inifile.read(ps_lottery_game, 'autonumber', false);
		po_options.reverse_autonumbers  := c_inifile.read(ps_lottery_game, 'reverse_autonumber', false);
		po_options.date_autonumber := c_inifile.read(ps_lottery_game, 'autonumber_from_rules', false);
		po_options.rules := c_inifile.read(ps_lottery_game, 'rules', '');
		po_options.date_index := c_inifile.read(ps_lottery_game, 'date_index', -1);

		if (po_options.date_autonumber) then
			if	(po_options.rules <> '') then
				c_rules.parse_rules( po_options.rules)
			else
				po_options.date_autonumber := false;
		result := po_options;
	end;

	//************************************************************
	function TlotteryExtractor.pr_index_of_html(pi_prev_index: integer;const ps_astring, ps_lookfor:string; pi_start:integer):integer;
	var
		index: integer;
	begin
		result := pi_prev_index;

		index  := g_miscstrings.instr( ps_lookfor,ps_astring,pi_start,true);
		if index>0 then
			if (pi_prev_index =0) or (index< pi_prev_index) then
				result := index
	end;

	//************************************************************
	//p,tr,br,ul,li,ol,dir,dt,dd)
	function TlotteryExtractor.pr_index_of_html_break(const astring:string;pi_start:integer):integer;
	var
		index:integer;
	begin
		INDEX  := g_miscstrings.instr(#10, astring, pi_start, true);
		INDEX := pr_index_of_html( INDEX, astring, '<P', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '<script', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '</script', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '<title', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '</title', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '</html', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '<html', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '</p', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '<tr', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '</tr', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '<br', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '<ul', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '<ol', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '<li', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '</ul', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '</ol', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '</dt', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '</dd', pi_start);
		INDEX := pr_index_of_html( INDEX, astring, '<dir', pi_start);


		result := INDEX;
	end;

	//************************************************************
	function TlotteryExtractor.pr_line_matches_format(ps_line:string;po_format:TRegExpr):boolean;
	var
		matched:boolean;
	begin
		matched := po_format.Exec(ps_line);
		result := matched;
	end;


	//************************************************************
	procedure TlotteryExtractor.pr_add_to_list( regexp:TRegExpr; po_list:tstringlist; po_options:TLotteryExtractorOption);
	var
		sDate, key:string;
		value: string;
		index: integer;
		dDate: tdatetime;
	begin
		//clear out list and inc number of rowas processed successfully
		inc(c_rowsProcessed) ;
		c_list.clear;

		//determine draw number
		if po_options.autonumber then begin
			if po_options.date_autonumber then begin
				sDate := regexp.Match[ po_options.date_index];
				ddate:=VarToDateTime(sDate);
				index :=  c_rules.get_draw_number_from_date(dDate);
				key := inttostr(index);
			end else
				key := inttostr( c_rowsProcessed)
		end else
			key := regexp.Match[ po_options.drawn_num_index];

		//read each of the drawn numbers and concatenate into a string
		for index :=0 to po_options.number_count -1 do
			c_list.add( regexp.Match[ index +po_options.number_index]);

		value := g_miscstrings.join(c_list,' ');

		//store the value
		po_list.Add(key + '=' + value);
	end;

	//************************************************************
	function TlotteryExtractor.pr_autonumber(po_options:TLotteryExtractorOption ;po_list: tstringlist): tstringlist;
	var
		olist: tstringlist;
		row,increment: integer;
	begin
		//--------- a new list ---------------------------
		olist := tstringlist.Create;

		//-------------do stuff --------------------------
		row := 1;
		increment := 1;
		if po_options.reverse_autonumbers then begin
			row := po_list.Count;
			increment := -1;
		end;

		//return the new list (zap the old one) ----------
		po_list.Free;
		result := olist;
	end;


//
//####################################################################
(*
	$History: lotteryExtractor.pas $
 * 
 * *****************  Version 3  *****************
 * User: Sunil        Date: 21/06/05   Time: 0:55
 * Updated in $/PAGLIS/lottery
 * autonumbers from draw date 
 * 
 * *****************  Version 1  *****************
 * User: Sunil        Date: 14/02/05   Time: 22:16
 * Created in $/PAGLIS/lottery
 * 
 * *****************  Version 7  *****************
 * User: Sunil        Date: 18-02-03   Time: 12:45p
 * Updated in $/code/paglis/lottery
 * added headers and footers
*)
//####################################################################
//
end.
