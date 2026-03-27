unit rowviewer;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Grids,
  Graphics, LCLType, LCLIntf,
  laz.VirtualTrees, lazaruscompat, dbconnection;

type
  TRowViewerForm = class(TForm)
    GridViewer: TStringGrid;
    pnlBottom: TPanel;
    btnPrev: TButton;
    lblRow: TLabel;
    btnNext: TButton;
    btnClose: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnPrevClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure GridViewerDrawCell(Sender: TObject; ACol, ARow: Integer;
      ARect: TRect; AState: TGridDrawState);
  private
    FGrid: TVirtualStringTree;
    FNode: PVirtualNode;
    FResults: TDBQuery;
    procedure LoadCurrentRow;
    procedure Navigate(Delta: Integer);
  public
    procedure ShowForRow(AGrid: TVirtualStringTree; ANode: PVirtualNode;
      AResults: TDBQuery);
  end;

var
  RowViewerForm: TRowViewerForm;

implementation

{$R *.lfm}

const
  TEXT_NULL = 'NULL';

procedure TRowViewerForm.FormCreate(Sender: TObject);
begin
  GridViewer.Cells[0, 0] := 'Column';
  GridViewer.Cells[1, 0] := 'Value';
  GridViewer.ColWidths[0] := 150;
  GridViewer.ColWidths[1] := GridViewer.ClientWidth - 150 - 4;
end;

procedure TRowViewerForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
  RowViewerForm := nil;
end;

procedure TRowViewerForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE: Close;
    VK_LEFT, VK_PRIOR: if Shift = [] then Navigate(-1);
    VK_RIGHT, VK_NEXT: if Shift = [] then Navigate(1);
  end;
end;

procedure TRowViewerForm.LoadCurrentRow;
var
  RowNum: PInt64;
  i, TotalRows, ColCount: Integer;
  Val: String;
begin
  if (FGrid = nil) or (FNode = nil) or (FResults = nil) then
    Exit;

  ColCount := FResults.ColumnCount;
  if ColCount <= 0 then
    Exit;

  RowNum := FGrid.GetNodeData(FNode);
  if (RowNum = nil) or (RowNum^ < 0) then
    Exit;

  FResults.RecNo := RowNum^;

  TotalRows := FGrid.RootNodeCount;

  GridViewer.RowCount := ColCount + 1;
  for i := 0 to ColCount - 1 do begin
    GridViewer.Cells[0, i + 1] := FResults.ColumnNames[i];
    if FResults.IsNull(i) then
      Val := TEXT_NULL
    else
      Val := FResults.Col(i);
    GridViewer.Cells[1, i + 1] := Val;
  end;

  lblRow.Caption := Format('Row %d of %d', [FNode.Index + 1, TotalRows]);
  btnPrev.Enabled := FGrid.GetPrevious(FNode) <> nil;
  btnNext.Enabled := FGrid.GetNext(FNode) <> nil;
end;

procedure TRowViewerForm.Navigate(Delta: Integer);
var
  NextNode: PVirtualNode;
begin
  if (FGrid = nil) or (FNode = nil) then
    Exit;
  if Delta < 0 then
    NextNode := FGrid.GetPrevious(FNode)
  else
    NextNode := FGrid.GetNext(FNode);
  if NextNode = nil then
    Exit;
  FNode := NextNode;
  FGrid.FocusedNode := FNode;
  FGrid.Selected[FNode] := True;
  FGrid.ScrollIntoView(FNode, False, False);
  LoadCurrentRow;
end;

procedure TRowViewerForm.btnPrevClick(Sender: TObject);
begin
  Navigate(-1);
end;

procedure TRowViewerForm.btnNextClick(Sender: TObject);
begin
  Navigate(1);
end;

procedure TRowViewerForm.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TRowViewerForm.GridViewerDrawCell(Sender: TObject; ACol, ARow: Integer;
  ARect: TRect; AState: TGridDrawState);
var
  CellVal: String;
  TxtRect: TRect;
begin
  if ARow = 0 then
    Exit; // Let default draw the header

  CellVal := GridViewer.Cells[ACol, ARow];

  // Paint NULL values in gray italic
  if (ACol = 1) and (CellVal = TEXT_NULL) then begin
    if gdSelected in AState then
      GridViewer.Canvas.Brush.Color := clHighlight
    else
      GridViewer.Canvas.Brush.Color := GridViewer.Color;
    GridViewer.Canvas.FillRect(ARect);
    GridViewer.Canvas.Font.Color := clGrayText;
    GridViewer.Canvas.Font.Style := [fsItalic];
    TxtRect := ARect;
    InflateRect(TxtRect, -2, 0);
    GridViewer.Canvas.TextRect(TxtRect, TxtRect.Left, TxtRect.Top + 2, CellVal);
    GridViewer.Canvas.Font.Style := [];
  end else begin
    if gdSelected in AState then begin
      GridViewer.Canvas.Brush.Color := clHighlight;
      GridViewer.Canvas.Font.Color := clHighlightText;
    end else begin
      GridViewer.Canvas.Brush.Color := GridViewer.Color;
      GridViewer.Canvas.Font.Color := GridViewer.Font.Color;
    end;
    GridViewer.Canvas.FillRect(ARect);
    TxtRect := ARect;
    InflateRect(TxtRect, -2, 0);
    GridViewer.Canvas.TextRect(TxtRect, TxtRect.Left, TxtRect.Top + 2, CellVal);
  end;
end;

procedure TRowViewerForm.ShowForRow(AGrid: TVirtualStringTree; ANode: PVirtualNode;
  AResults: TDBQuery);
begin
  FGrid := AGrid;
  FNode := ANode;
  FResults := AResults;
  LoadCurrentRow;
  if not Visible then
    Show;
  BringToFront;
end;

end.
