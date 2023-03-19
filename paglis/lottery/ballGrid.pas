unit ballGrid;

interface

uses
	ballrack, WinProcs, Classes, Graphics, Grids, lottype, lottrender;
type
	TballGrid = class(TStringGrid)
	private
		c_rendered_balls:TRenderedBalls;
		c_rendered: boolean;
		procedure pr_set_rendered( pbValue: boolean);
	protected
		procedure DrawCell(ACol, ARow: Longint; ARect: TRect; AState: TGridDrawState); override;
		procedure RowHeightsChanged; override;
	public
		constructor Create(AOwner: TComponent); override;
		destructor Destroy; override;
	published
		property Rendered: boolean	read c_rendered write pr_set_rendered;
	end;

procedure Register;

implementation
uses
	sysutils, lottery, misclib, math;

	//***********************************************************
	constructor TballGrid.Create(AOwner: TComponent);
	begin
		inherited;
		DefaultRowHeight := 32;
		c_rendered_balls := TRenderedBalls.create;
		c_rendered_balls.Diameter := DefaultRowHeight;
	end;

	//***********************************************************
	destructor TballGrid.Destroy;
	begin
		c_rendered_balls.free;
		inherited;
	end;

	//***********************************************************
	procedure TballGrid.DrawCell(ACol, ARow: Longint; ARect: TRect; AState: TGridDrawState);
	var
		ball_string:string;
		rect_height, ball:integer;
		ball_rect, font_rect:trect;
		font_extent: tsize;
	begin
		//-------------- convert string -------------
		ball_string := cells[acol,arow];
		if (ball_string = '') then
		begin
			inherited;
			exit;
		end;

		try
			ball := strtoint(ball_string);
		except
			on EConvertError do
				begin
					inherited;
					exit;
				end
		end;

		//-------------- determine where to put ball  -------------
		rect_height := min(arect.right-arect.left, arect.bottom - arect.top);
		ball_rect.left := (arect.left + arect.right - rect_height) div 2;
		ball_rect.right := ball_rect.left + rect_height;
		ball_rect.top := (arect.top + arect.bottom - rect_height) div 2;
		ball_rect.bottom := ball_rect.top + rect_height;

		//-------------- blit the ball -------------
		c_rendered_balls.blit_ball( ball, canvas,ball_rect);
		
		//-------------- determine where to put text  -------------
		font_extent:= canvas.textextent(ball_string);
		font_rect.left := (arect.left + arect.right - font_extent.cx) div 2;
		font_rect.top := (arect.top + arect.bottom - font_extent.cy) div 2;

		//-------------- paint the text on the ball -------------
		canvas.brush.Style := bsClear;
		canvas.font.color := clwhite;
		canvas.TextOut( font_rect.left-1,font_rect.top-1, ball_string);
		canvas.font.color := clblack;
		canvas.TextOut( font_rect.left,font_rect.top, ball_string);
	end;

	//***********************************************************
	procedure TballGrid.RowHeightsChanged;
	var
		row: integer;
	begin
		for row:= 1 to rowcount do
		begin
			if rowheights[row-1] < DefaultRowHeight then
				rowheights[row-1] := DefaultRowHeight;
		end;
		inherited;
	end;

	//***********************************************************
	procedure Register;
	begin
	  RegisterComponents('Paglis lottery', [TballGrid]);
	end;

	procedure TballGrid.pr_set_rendered( pbValue: boolean);
	begin
		if pbValue <> c_rendered then
		begin
			c_rendered := pbValue;
			c_rendered_balls.Rendered := pbValue;
			invalidate
		end;
	end;


end.
