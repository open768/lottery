unit picked;

interface

uses
	ballGrid, language, Classes, Controls, Grids,
	forms;

type
  TfrmPicked = class(TForm)
    ballGrid1: TballGrid;
    Localiser1: TLocaliser;
    procedure ballGrid1DblClick(Sender: TObject);
  private
	{ Private declarations }
	m_rendered: boolean;
	procedure pr_set_rendered( pbValue:boolean);
  public
	{ Public declarations }
  published
	property Rendered: boolean	read m_rendered write pr_set_rendered;

  end;

var
  frmPicked: TfrmPicked;

implementation
	uses dialogs, sysutils, clipbrd, main, misclib;

{$R *.DFM}
const
    //SEPARATOR = TABCHAR;
    SEPARATOR = ',';


//*********** copy to clipboard ***********************
procedure TfrmPicked.ballGrid1DblClick(Sender: TObject);
var
	row,col: integer;
	copy_string:string; 
begin
	copy_string := localstring('Picked Numbers:') + CRLF + CRLF;
	for row := 1 to ballGrid1.rowcount do
	begin
		for col := 1 to ballGrid1.colcount do
		begin
            if col>1 then copy_string := copy_string + SEPARATOR;
            copy_string := copy_string + ballGrid1.cells[col-1,row-1];
		end;
		copy_string := copy_string+ CRLF;
	end;
	clipboard.clear;
	clipboard.astext := copy_string;
	showmessage( LocalString('numbers have been copied to clipboard'));
end;

procedure TfrmPicked.pr_set_rendered( pbValue:boolean);
begin
	ballGrid1.Rendered := pbValue;
end;


end.
