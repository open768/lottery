unit Plandata;

interface
uses
  classes,sysutils, lottery,lottype, misclib,inifile;

var
  plan_names: TStringList;

type
  TTicket =
    record
      boards: array[ 1..UK_BOARDS, 1.. MAX_DRAWN_BALLS] of byte;
      used_boards:byte
    end;

  PTicket = ^TTicket;
  TTicketlist = array[0..0] of PTicket;
  PTicketlist = ^TTicketlist;


  TPlanData = class(Tobject)
  private
    tickets: PTicketlist;
    ticket_count: integer;
    tickets_size: longint;
    tickets_allocated: integer;
    waffle: Tstringlist;

    procedure destroy_all_mem;
    procedure allocate_mem(n_tickets:integer);
    procedure empty_ticket(ticket_number:integer);

    procedure plan_read_ticket_data(var handle: textfile);
    procedure plan_read_board_data(ticket_number:integer;board_string:string);
    procedure decipher_board_key(key:string; var ticket_num, board_num:integer);

  public
    plan_name: string;

    constructor Create;
    destructor Destroy; override;
    function get_value(ticket_number,board,position:integer):byte;
    procedure set_value(ticket_number,board,position:integer; value:byte);
    function boards_in_use(ticket_number:integer):integer;
    procedure clear;
    function size: integer;

    function load_from_plan_file(filename:string): boolean;
    function load_from_ini(desired_plan_name:string):boolean;
    procedure save_to_ini;
    procedure delete_permanently(a_plan_name:string);
    procedure delete_ticket(ticket_number:integer);

    property Strings:tstringlist read waffle;
  end;

function is_valid_planfile(filename:string): boolean;
function is_plan_known(plan_name:string):boolean;
procedure get_plan_names(strings : tstrings);

procedure deinit_plan_names;
procedure init_plan_names;
function plan_exists(plan_name: string):boolean;
function planfile_was_loaded(filename:string):boolean;
procedure mark_planfile_as_loaded(filename:string);



implementation


const
  DEFAULT_ALLOCATED=10;
  PLAN_IDENTIFIER = '- please enter these boards as follows';
  NUMBERS_COVERED = 'The numbers you are covering with this system are these';
  MARK_STRING_TOP = 'On ticket no.';
  MARK_STRING_BOTTOM = 'please mark the';
  BOARD_IDENTIFIER = 'Board ';
  WAFFLE_SECTION_SUFFIX = '.Waffle';
  NUMBER_SECTION_SUFFIX = '.Numbers';
  PLAN_NAMES_SECTION = 'Plan.names';
  LOADED_SECTION = 'Loaded.Success';
  PLAN_INI_FNAME = 'plans.ini';
  TICKET_CHAR = 'T';
  BOARD_CHAR = 'B';



{#########################################################################}
constructor TPlanData.Create;
begin
  inherited create;

  {--------------------------------------------------------}
  tickets:= nil;
  ticket_count := 0;
  tickets_allocated := 0;
  tickets_size := 0;
  waffle := tstringlist.create;

  {--------------------------------------------------------}
  allocate_mem( DEFAULT_ALLOCATED);
end;

{**************************************************************}
destructor TPlanData.Destroy;
begin
  waffle.free;
  if tickets_allocated > 0 then
    destroy_all_mem;

  inherited Destroy;
end;


{**************************************************************}
procedure TPlanData.destroy_all_mem;
var
  ticket_num: integer;
begin
  for ticket_num:= 1 to tickets_allocated do
    dispose(tickets^[ticket_num-1]);
  freemem(tickets,tickets_size);
end;

{**************************************************************}
procedure TPlanData.allocate_mem(n_tickets:integer);
var
  new_size: longint;
  old_allocated: integer;
  ticket_num: integer;
begin
  {-------------allocate memory to accomodate tickets------------}
  new_size := n_tickets * sizeof(PTicket);
	if tickets = nil then
		getMem(tickets, new_size)
  else
    ReAllocMem( tickets, new_size);

  tickets_size := new_size;
  old_allocated := tickets_allocated;
  tickets_allocated := n_tickets;

  {-------------populate with pointers------------}
  for ticket_num := (old_allocated+1) to tickets_allocated do
  begin
    tickets^[ticket_num -1] := new(PTicket);
    empty_ticket(ticket_num);
  end;
end;


{**************************************************************}
function TPlanData.load_from_plan_file(filename:string): boolean;
var
  line:string;
  handle:TextFile;
  text_pos, text_pos_2: integer;
begin
  {----------------------------------------------------------}
  load_from_plan_file := false;
  if not is_valid_planfile(filename) then
    exit;
  clear;

  {---------------- open the file ------------------------}
  assignfile(handle, filename);
  reset(handle);

  {---------------- get the plan name ------------------------}
  line := read_a_line(handle);
  text_pos := pos( PLAN_IDENTIFIER, line);
  plan_name := copy(line,1,text_pos-1);
  plan_name := trim(plan_name);

  {------- get the numbers covered and other waffle ------------}
  waffle.clear;
  line := read_a_line(handle);
  waffle.add(line);
  while not eof(handle) do
  begin
    readln(handle, line);
    text_pos := pos(MARK_STRING_TOP,line);
    text_pos_2 := pos(MARK_STRING_BOTTOM,line);
    if (text_pos <> 0) and (text_pos_2 <> 0) then
      break
    else
      waffle.add(line);
  end;

  {------- read the ticket data itself;-------------------}
  plan_read_ticket_data(handle);

  {---------------- close the file ------------------------}
  closefile(handle);
end;

{**************************************************************}
procedure TPlanData.plan_read_ticket_data(var handle: textfile);
var
  ticket_number:integer;
  line, left_board, right_board: string;
  board_letter: char;
  text_pos, text_pos_2:integer;
begin
  ticket_number := 0;

  while not eof(handle) do
  begin
    {- - - - - only interested in lines that start with the word Board - -}
    line := read_a_line(handle);
    text_pos := pos(BOARD_IDENTIFIER,line);
    if text_pos <> 1 then continue;

    {- - - - - split into the two - -}
    text_pos_2 := instr(BOARD_IDENTIFIER,line, text_pos +1);
    if text_pos_2 = 0 then
      begin
        left_board := line;
        right_board := '';
      end
    else
      begin
        left_board := left_string(line, text_pos_2 -1);
        left_board := trim(left_board);
        right_board := to_string_end(line,text_pos_2);
      end;

    {- - - - - if board letter is an A, move to next ticket- - - - -}
    board_letter := left_board[length(BOARD_IDENTIFIER)+1];
    if (board_letter = 'A') then
      if ticket_number = 0 then
        ticket_number := 1
      else
        ticket_number := ticket_number +2;

    {- - - - - read board data from string - - - - - -}
    plan_read_board_data(ticket_number, left_board);
    if right_board <> '' then  plan_read_board_data(ticket_number+1, right_board);
  end;
end;

{**************************************************************}
procedure TPlanData.plan_read_board_data(ticket_number:integer;board_string:string);
var
  board_code: char;
  board_number, index: integer;
  numbers: array[1..UK_NSELECT] of integer;
begin
  board_code := board_string[length(BOARD_IDENTIFIER)+1];
  board_number := ord(board_code) - ord('A') + 1;
  get_numbers( board_string, numbers);
  for index := 1 to UK_NSELECT do
    set_value(ticket_number,board_number, index, numbers[index]);
end;



{**************************************************************}
function TPlanData.load_from_ini(desired_plan_name:string):boolean;
var
  section_name, key, value:string;
  ini_file:tinifile;
  index, number_index: integer;
  ticket_number, board_number:integer;
  numbers: array[1..UK_NSELECT] of integer;
  section_list: tstringlist;
begin
  clear;

  {--------------------- only load plans that are known----------}
  if not is_plan_known(desired_plan_name) then
  begin
    result := false;
    exit;
  end;

  {--------------------------------------------------}
  ini_file := Tinifile.create(PLAN_INI_FNAME);
  plan_name := desired_plan_name;

  {------------------- read any waffle -------------------------}
  section_name := plan_name + WAFFLE_SECTION_SUFFIX;
  section_list  := ini_file.read_section( section_name);
  for index := 1 to section_list.count do
    waffle.add(section_list.names[index-1]);

  {------------------- read the numberdata ---------------------}
  section_name := plan_name + NUMBER_SECTION_SUFFIX;
  section_list  := ini_file.read_section( section_name);
  for index := 1 to section_list.count  do
  begin
    key := section_list.names[index-1];
    value := section_list.values[key];

    decipher_board_key(key, ticket_number, board_number);
    get_numbers( value, numbers);

    for number_index:=1 to uk_nselect do
      set_value(ticket_number,board_number, number_index, numbers[number_index]);
  end;

  ini_file.free;
  result := true;
end;

{**************************************************************}
procedure TPlanData.save_to_ini;
var
  ini_file :Tinifile;
  index, ticket_index, board_index:integer;
  section_name, key_name, value:string;
begin
  ini_file := tinifile.create(PLAN_INI_FNAME);

  {---------------save the plan name-------------------}
  ini_file.write_Boolean(PLAN_NAMES_SECTION,plan_name,true);

  {---------------save the waffle-------------------}
  section_name := plan_name + WAFFLE_SECTION_SUFFIX;
  ini_file.delete_section(section_name);
  for index := 1 to waffle.count do
  begin
    key_name := intToStr(index);
    value := waffle.strings[index-1];
    ini_file.write_String(section_name, key_name, value);
  end;

  {--------------save the numbers-------------------}
  section_name := plan_name + NUMBER_SECTION_SUFFIX;
  ini_file.delete_section(section_name);
  for ticket_index := 1 to ticket_count do
    with tickets^[ticket_index-1]^ do
      for board_index := 1 to used_boards do
      begin
        key_name := TICKET_CHAR + inttostr(ticket_index);
        key_name := key_name + BOARD_CHAR + inttostr( board_index);
        value := '';
        for index := 1 to UK_NSELECT do
          value := value + inttostr(boards[board_index,index]) + ' ';
        ini_file.write_string(section_name,key_name,value);
      end;

  {--------------------------------------------------}
  ini_file.free;
end;

{**************************************************************}
procedure TPlanData.delete_permanently(a_plan_name:string);
var
  ini_file: Tinifile;
begin
  {--------gone from the ini file-------------}
  ini_file := tinifile.create(PLAN_INI_FNAME);
  ini_file.delete_section(a_plan_name + NUMBER_SECTION_SUFFIX);
  ini_file.delete_section(a_plan_name + WAFFLE_SECTION_SUFFIX);
  ini_file.delete_key(PLAN_NAMES_SECTION,a_plan_name);
  ini_file.free;

  {--------and from current plan data-----------}
  if a_plan_name = plan_name then
    clear;
end;

{**************************************************************}
function TPlanData.get_value(ticket_number,board,position:integer):byte;
begin
  get_value := 0;

  if ticket_number <= ticket_count then
    with tickets^[ticket_number-1]^ do
      if board <= used_boards then
        get_value :=  boards[board,position];
end;

{**************************************************************}
procedure TPlanData.set_value(ticket_number,board,position:integer; value:byte);
begin
  if ticket_number > tickets_allocated then
    allocate_mem(ticket_number + DEFAULT_ALLOCATED);

  if ticket_number > ticket_count then
    ticket_count := ticket_number;

  with tickets^[ticket_number-1]^ do
  begin
    boards[board,position] := value;
    if board > used_boards then
      used_boards := board;
  end;
end;

{**************************************************************}
procedure TPlanData.clear;
var
  index:integer;
begin
  for index := 1 to tickets_allocated do
    empty_ticket(index);
  ticket_count := 0;
  waffle.clear;
end;

{**************************************************************}
procedure TPlanData.empty_ticket(ticket_number:integer);
var
  board,position:integer;
begin
  if ticket_number <= tickets_allocated then
    with tickets^[ticket_number-1]^ do
    begin
      used_boards := 0;
      for board:= 1 to UK_BOARDS do
        for position := 1 to MAX_DRAWN_BALLS do
          boards[board,position] := 0;
    end;
end;

{**************************************************************}
function TPlanData.size: integer;
begin
  size := ticket_count;
end;

{**************************************************************}
procedure TPlanData.decipher_board_key(key:string; var ticket_num, board_num:integer);
var
  b_pos:integer;
  ticket_string, board_string:string;
begin
  b_pos := pos(BOARD_CHAR, key);
  ticket_string := copy(key,2,b_pos-2);
  board_string := to_string_end(key,b_pos +1);

  ticket_num := strtoint(ticket_string);
  board_num := strtoint(board_string);
end;

{**************************************************************}
function TPlanData.boards_in_use(ticket_number:integer):integer;
begin
  if (ticket_number > ticket_count) or (ticket_number <1)then
    result := 0
  else
    result := tickets^[ticket_number-1]^.used_boards;
end;

{**************************************************************}
procedure TPlanData.delete_ticket(ticket_number:integer);
var
  referenced_ticket:PTicket;
  index:integer;
begin
  {----------------------------------------------------------}
  if (ticket_number > ticket_count) or (ticket_count < 1) then
    exit;

  {----------------------------------------------------------
  no need to free the memory, instead just move pointers around
  ----------------------------------------------------------}
  empty_ticket(ticket_number);
  referenced_ticket := tickets^[ticket_number-1];
  for index := ticket_number to ticket_count-1 do
  begin
    tickets^[index-1] := tickets^[index];
    tickets^[index] := nil;
  end;
  tickets^[ticket_count-1] := referenced_ticket;
  dec(ticket_count);
end;

{********************************************************}
procedure deinit_plan_names;
begin
  if assigned(plan_names) then
    plan_names.free;
end;

{********************************************************}
procedure init_plan_names;
begin
  {---------------- create list of plans ---------------}
  if not assigned(plan_names) then
    plan_names := TStringList.Create;
  get_plan_names(plan_names);
end;

{********************************************************}
function plan_exists(plan_name: string):boolean;
var
  position:integer;
begin
  plan_exists := false;

  if assigned(plan_names) then
  begin
    position := plan_names.indexof(plan_name);
    plan_exists := (position <> -1);
  end;
end;

{********************************************************}
function is_valid_planfile(filename:string): boolean;
var
  handle: TextFile;
  line:string;
begin
  {----------------------open file ---------------------}
  is_valid_planfile := false;
  assignfile(handle, filename);
  reset(handle);

  {-----check that both plan identifier and numbers covered are there---}
  line := read_a_line(handle);

  if pos( PLAN_IDENTIFIER, line) <> 0 then
  begin
    line := read_a_line(handle);
    if pos( NUMBERS_COVERED, line) <> 0 then
      is_valid_planfile := true;
  end;

  {----------------close file ------------------------------}
  closefile(handle);
end;

{**************************************************************}
function is_plan_known(plan_name:string):boolean;
var
  ini_file:tinifile;
begin
  ini_file := tinifile.create(PLAN_INI_FNAME);
  result := ini_file.read_boolean(PLAN_NAMES_SECTION,plan_name,false);
  ini_file.free;
end;


{**************************************************************}
procedure get_plan_names(strings :tstrings);
var
  ini_file:tinifile;
  index:integer;
  plan_name:string;
  section_list: tstringlist;
begin
  ini_file := Tinifile.create(PLAN_INI_FNAME);
  strings.clear;
  section_list:= ini_file.read_section(PLAN_NAMES_SECTION);
  for index := 1 to section_list.count do
  begin
    plan_name := section_list.names[index-1];
    strings.add(plan_name);
  end;
  ini_file.free;
end;

{**************************************************************}
function planfile_was_loaded(filename:string):boolean;
var
  ini_file:tinifile;
begin
  ini_file := tinifile.create(PLAN_INI_FNAME);
  result := ini_file.read_boolean(LOADED_SECTION,filename,false);
  ini_file.free;
end;

{**************************************************************}
procedure mark_planfile_as_loaded(filename:string);
var
  ini_file:tinifile;
begin
  ini_file := tinifile.create(PLAN_INI_FNAME);
  ini_file.write_boolean(LOADED_SECTION,filename,true);
  ini_file.free;
end;



end.

