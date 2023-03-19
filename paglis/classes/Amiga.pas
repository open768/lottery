unit Amiga;
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
{
    This code is placed into the public domain by the author
    If you wish to contribute (ideas or code) in making an amiga
    type workbench filemanage for windows please contact the author.
}
interface

  uses winprocs, wintypes, Classes, sysutils, graphics, dialogs,misclib;

const
  WB_DISKMAGIC        = $e310;        { a magic number, not easily impersonate}
  LAME_WB_DISKMAGIC   = $10e3;        { magic number, byte swapped}

  WBDISK		= 1;
  WBDRAWER	= 2;
  WBTOOL		= 3;
  WBPROJECT	= 4;
  WBGARBAGE	= 5;
  WBDEVICE	= 6;
  WBKICK		= 7;
  WBAPPICON	= 8;

type
  {***************************************************************
  Structure information taken from PCQ Pascal
  ***************************************************************}
Gadget = record
    NextGadget        : Pointer;      { next gadget in the list }
    LeftEdge,TopEdge  : Word;        { "hit box" of gadget }
    Width, Height     : Word;        { "hit box" of gadget }
    Flags             : Word;        { see below for list of defines }
    Activation        : Word;        { see below for list of defines }
    GadgetType        : Word;        { see below for defines }
    GadgetRender      : Pointer;
    SelectRender      : Pointer;
    GadgetText        : Pointer;      { text for this gadget }
    MutualExclude     : Integer;      { set bits mean this gadget excludes that gadget }
    SpecialInfo       : Pointer;
    GadgetID          : Word;        { user-definable ID field }
    UserData          : Pointer;      { ptr to general purpose User data (ignored by In) }
  end;

  DiskObject = record
    do_Magic        : Word;        { a magic number at the start of the file }
    do_Version      : Word;        { a version number, so we can change it }
    do_Gadget       : Gadget;      { a copy of in core gadget }
    do_Type         : Byte;
    pad : array [1..1] of word;
    (*
    do_DefaultTool  : String;
    do_ToolTypes    : Pointer;
    do_CurrentX     : Integer;
    do_CurrentY     : Integer;
    do_DrawerData   : Pointer;
    do_ToolWindow   : String;       { only applies to tools }
    do_StackSize    : Integer;      { only applies to tools }
    *)
  end;

  AmigaImage = record
    LeftEdge, TopEdge, Width, Height, Depth: word;
    (*
    CARD16 *ImageData;
    *)
    foo: array[1..2] of word;
    PlanePick, PlaneOnOff: byte;
    NextImage: Pointer;
  end;

  {----------------exception, needed for later----------------}
  AmigaInfoError = class (Exception);


  {----------------the info file reading thing----------------}
  TAmigaInfoFile = class (TObject)
    private
      lame_bytes: boolean;
      dobj : DiskObject;
      im_obj : AmigaImage;

      function initialise(filename:string): Boolean;
      function init_from_stream(a_stream: THandleStream):Boolean;
      function planar_to_chunky(img_bits: PByteArray; BytesPerRow:integer; x,y:Integer):Tcolor;

    public
      bitmap1,bitmap2: TBitmap;
      constructor Create (filename: String);
      destructor Destroy; override;
  end;

  color_array = array[1..8] of Tcolor;

const
  SysIconColorname: color_array = ($aaaaaa,$000000,$ffffff,$6688bb, $ee4444,$55dd55,$0044dd,$ee9e00);
  MagicWbColorname: color_array = ($aaaaaa,$000000,$ffffff,$6688bb, $999999,$bbbbbb,$bbaa99,$ffbbaa);

implementation



  {***************************************************************
  info file reading code ported from amiwm, an X11 window manager
  written in C copyright
  ***************************************************************}

  constructor TAmigaInfoFile.Create(filename: String);
  begin
    lame_bytes := false;
    if (not initialise(filename)) then
      raise AmigaInfoError.Create(filename + ' is not a valid info file');
  end;

  {*******************************************************************
  *******************************************************************}
  destructor TAmigaInfoFile.Destroy;
  begin
    if assigned (bitmap1) then  bitmap1.free;
    if assigned (bitmap2) then  bitmap2.free;
    inherited Destroy;
  end;

  {*******************************************************************
  *******************************************************************}
  function TAmigaInfoFile.initialise(filename:string): Boolean;
  var
    handle : Integer;
    h_stream: THandleStream;
    valid_info_file: boolean;
    fname : pchar;
    fstruct: TOFSTRUCT;
  begin
    {--- open the file, use windows API because borland couldnt be
     --- bothered to properly implement its stream class           --}
    fname := PasStr(filename);
    handle := OpenFile(fname, fstruct, OF_READ);
    StrDispose(fname);
    h_stream := THandleStream.Create(handle);

    {--------- modularised code dontcha love it?  ----------------}
    valid_info_file := false;
    try
      valid_info_file := init_from_stream(h_stream);
    finally
      H_stream.Free;
      _lclose(handle);
      result := valid_info_file;
    end;

  end;

  {*******************************************************************
   amiga bytes are byte swapped
  *******************************************************************}
  function TAmigaInfoFile.init_from_stream(a_stream: THandleStream):Boolean;
  var
		img_size: word;
    BytesPerRow: integer;
    img_bits:   PByteArray;
    x,y: integer;
  begin
    {- - - - - - - is this an info file, check magic number - - - - - - }
    a_stream.read(dobj, sizeof(dobj));
    if (dobj.do_magic = LAME_WB_DISKMAGIC)
    then
      lame_bytes := true
    else if ( dobj.do_magic <> WB_DISKMAGIC ) then
      begin
        result := false;
			 exit;
      end;

    {- - - read image data? - - dont assume I understand all this - - - -}
    with dobj do
    begin
      if ( (do_Type=WBDISK) or (do_Type=WBDRAWER) or (do_Type=WBGARBAGE)) then
        a_stream.seek(($4e)+$38, 0)
      else
        a_stream.seek($4e, 0);
    end;
    a_stream.read(im_obj, sizeof(im_obj));

		{- - - - - - - swap byte order if necc- - - - - - - - - - - - - - - - - - -}
    if (lame_bytes) then
    begin
    	dobj.do_Gadget.Width := swap16(dobj.do_Gadget.Width);
		  dobj.do_Gadget.Height := swap16(dobj.do_Gadget.Height);
		  im_obj.LeftEdge := swap16(im_obj.LeftEdge);
		  im_obj.TopEdge := swap16(im_obj.TopEdge);
		  im_obj.Width := swap16(im_obj.Width);
		  im_obj.Height := swap16(im_obj.Height);
		  im_obj.Depth := swap16(im_obj.Depth);
    end;

    {--------------read image data, shouldnt there be 2 of them?-------}
		BytesPerRow := 2 * ((im_obj.Width+15) shr 4);
    img_size := BytesPerRow*im_obj.Height*im_obj.Depth;
    img_bits := allocmem(img_size);
    try
      { ======================= first bitmap ============================}
      a_stream.read(img_bits^, img_size);

      { ----- now that all data has been read, create bitmap-----------}
      bitmap1 :=  TBitmap.Create;
      bitmap1.Width := im_obj.Width;
      bitmap1.Height := im_obj.Height;

      {convert read data into a bitmap}
		  for y:=0 to im_obj.Height do
        for x:=0 to im_obj.Width do
            bitmap1.canvas.pixels[x,y] := planar_to_chunky(img_bits, BytesPerRow,x,y);

      { ======================= second bitmap ============================}
      if (dobj.do_Type<>WBDISK) then
      begin
        a_stream.read(img_bits^, img_size);

        bitmap2 :=  TBitmap.Create;
        bitmap2.Width := im_obj.Width;
        bitmap2.Height := im_obj.Height;

			 for y:=0 to im_obj.Height do
          for x:=0 to im_obj.Width do
            bitmap2.canvas.pixels[x,y] := planar_to_chunky(img_bits, BytesPerRow,x,y);
      end;

    finally
      {free memory allocated for read buffer}
      Freemem(img_bits,img_size);
    end;
  end;

  {*************************************************************************************}
  function TAmigaInfoFile.planar_to_chunky(img_bits: PByteArray; BytesPerRow:integer; x,y:Integer):Tcolor;
  var
    bitmask,pixel_colour: byte;
    plane:word;
    lhs, rhs: byte;
  begin

    bitmask := 1;
    pixel_colour := im_obj.PlaneOnOff and (not im_obj.PlanePick);
    plane := 0;

    {planar to chunky conversion ??? doesnt work}
    while( (plane<im_obj.Depth) and (bitmask > 0) ) do
    begin
      if ( bitmask and im_obj.PlanePick) > 0 then
      begin
        lhs := img_bits^[ (plane * im_obj.Height + y)* BytesPerRow + (x shr 3)];
        rhs := 128 shr( x and 7);

        if ( lhs and rhs ) >0 then
        begin
          inc(plane);
          pixel_colour := (pixel_colour or bitmask);
        end;                                    {if lhs}
      end;                                      {if bitmask}
      bitmask := bitmask shl 1;
    end;
                                       {while}
    result := MagicWbColorname[ pixel_colour and 7];
  end;
end.

