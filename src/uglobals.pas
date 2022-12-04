{***************************************************************************}
{*     This file is a part of                                              *}
{*                                                                         *}
{* @@@@@@  @@@@@@@  @@@@@@@@ @@@@@@@  @@@ @@@@@@@   @@@  @@@         @@@   *}
{*@@@@@@@  @@@@@@@@ @@@@@@@@ @@@@@@@@ @@@ @@@@@@@   @@@  @@@        @@@@   *}
{*!@@      @@!  @@@ @@!      @@!  @@@ @@!   @@!     @@!  @@@       @@!@!   *}
{*!@!      !@!  @!@ !@!      !@!  @!@ !@!   !@!     !@!  @!@      !@!!@!   *}
{*!!@@!!   @!@@!@!  @!!!:!   @!@  !@! !!@   @!!     @!@  !@!     @!! @!!   *}
{* !!@!!!  !!@!!!   !!!!!:   !@!  !!! !!!   !!!     !@!  !!!    !!!  !@!   *}
{*     !:! !!:      !!:      !!:  !!! !!:   !!:     :!:  !!:    :!!:!:!!:  *}
{*    !:!  :!:      :!:      :!:  !:! :!:   :!:      ::!!:! :!: !:::!!:::  *}
{*:::: ::   ::       :: ::::  :::: ::  ::    ::       ::::  :::      :::   *}
{*:: : :    :       : :: ::  :: :  :  :      :         :    :::      :::   *}
{*                                                                         *}
{***************************************************************************}
{*    Sprite Editor 4.0                                                    *}
{*    Copyright (c) 2000-2022 by Vadim Vitomsky                            *}
{*                                                                         *}
{*    See the file LICENSE, included in this distribution, for details.    *}
{*                                                                         *}
{*    This program is distributed in the hope that it will be useful,      *}
{*    but WITHOUT ANY WARRANTY; without even the implied warranty of       *}
{*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                 *}
{***************************************************************************}
unit uglobals;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}


interface

uses
  {$IFDEF DEBUG}LazLoggerBase,{$ENDIF} LCLTranslator,
  Classes, sysutils, StrUtils, Graphics, IniFiles, fpjson,
  BGRABitmap, BGRABitmapTypes, fgl;

resourcestring
  rsColors = 'Colors: ';
  rsFG = 'FG: ';
  rsBG = ' / BG: ';
  rsWarning = 'Warning!';
  rsPaletteWillB = 'Palette will be resetted to default colors! Are You shure?';
  rsImageHasTooM = 'Image has too many colors!';
  rsPleaseInputN = 'Please input new library name';
  rsHasNonIntege = ' has non-integer value!';
  rsLayerName = 'Layer name';
  rsInputNewLaye = 'Input new layer name:';
  rsYouMustOverr = 'You must override MouseUp() method! Class name: ';
  rsYouMustOverr2 = 'You must override MouseMove() method! Class name: ';


const
      //MAX_FRAMES = 50;           //it will be enought for one animation?
      MAX_PALETTE_COLORS = 255;  //max colors count in palette
      MAX_PIXELS = 512*512;      //max pixels array (sprite size 512x512 pixels)
      //MAX_LAYERS = 10;           //max layers count in one frame

      cINTERNALLAYERANDFRAME = 'spedit v.4'; //default frame name and background layer name
      //background layer needed for merged image from all layers
      csDRAWLAYER = 'Draw layer';  //layer name for drawing buffer


type
 // TWorkMode = (wrkProject,wrkSpriteActions,wrkEditor,wrkSourceImage,wrkLibrary,wrkSettings);
  //uses for check which tab now active

  TDrawGridMode = (dgmNone,dgmMove,dgmDraw);

  TColors = array[0..MAX_PALETTE_COLORS] of TBGRAPixel;  //palette - array of colors
  TPixels = array[0..MAX_PIXELS] of TBGRAPixel;      //array of pixels

  { TPalette }

  //PPalette = ^TPalette;

  TPalette = record
    private
     fCount : Byte;   //colors in palette
     fColors : TPixels; //colors array
     fSelected : Byte;
     FSelectedColor: TBGRAPixel;
     function GetColor(Index : Byte): TBGRAPixel;
    public
     property Count : Byte read fCount;
     property SelectedColor : TBGRAPixel read FSelectedColor;
     function isEmpty : Boolean; //check if palette is empty
     procedure Clear;
     procedure Reset; //reset palette to default 16 colors
     procedure SelectColor(Index : Byte);//Select active color
     procedure SaveToFile(aName : TFileName);//save palette to HEX file (with colors hex codes)
     function LoadFromFile(aName : TFileName) : Boolean;//load from HEX file
     property Color[Index : Byte] : TBGRAPixel read GetColor; //get color by index
     function AddColor(aColor : TBGRAPixel) : Integer;   //add new color to palette. Return index for new color or if color exists. If palette full returns -1
    private
     procedure Sort; //sort colors in palette
     function ColorExists(aColor : TBGRAPixel) : Integer; //check if color in palette before adding
  end;

  {class for undo/redo posibilities}

  PSPUndoRec = ^TSPUndoRec;

  { TSPUndoRec }

  TSPUndoRec = class
  private
    FLayerName: String;
    fFramename: String;
    fLayerIdx : Integer;
    fImg : TBGRABitmap;
  public
   constructor Create(aLayerName : String); //layer name where will be draw
   destructor Destroy; override;
   procedure Undo;   //undo drawing simple restore previous layer image
  end;

  TSPUndoRedoList = specialize TFPGObjectList<TSPUndoRec>; //for undo/redo mecanics

  TSPUnoRedoManager=class(TSPUndoRedoList)

  end;

 { PLayer = ^TLayer;
  PFrame = ^TFrame; }


  { TSPLayer }
  {Uses for layers in every frame.
  }


  TSPLayer = class
   private
    FHeight: Integer;
    FLocked: Boolean;
    fName: String;
    fTemporary: Boolean;
    fVisible : Boolean;
    fLayerImg : TBGRABitmap; //layer image
    FWidth: Integer;
    FFrames : TStringList;
   public
    property LayerName : String read fName write fName; //text to layers list identify
    property Visible : Boolean read fVisible write fVisible default True; //is drawable
    property Locked : Boolean read FLocked write FLocked default False; //can be changed
    property Temporary : Boolean read fTemporary write fTemporary default False; //temporary created - not visible in layers form
    property Height : Integer read FHeight;
    property Width : Integer read FWidth;
    property Drawable : TBGRABitmap read fLayerImg write fLayerImg;  //BGRABitmap for drawing
    //property FramesList : TStringList read FFrames; //frame names list containing current layer
    procedure Resize(newWidth, NewHeight: Integer; Stretched: Boolean=False); //resize layer
    procedure AddToFrame(FrameName : String); //add layer to frame
    function DeleteFromFrame(aFrameName : String) : Boolean; //remove frame name from internal list of frames where layer belongs
    constructor Create(aName : String; aWidth : Integer = 32; aHeight : Integer = 32);
    procedure ClearDrawable; //clear BGRABitmap for new drawing
    destructor Destroy; override;

    procedure Clear;
  end;


  { TSPFrame }

  TSPFrame = class
   private
    FCount : Byte;
    fFrameName: String;
    FHeight: Integer;
    FIndex: Integer;
    fLayers : TStringList;
    FWidth: Integer;
    procedure SetIndex(AValue: Integer);
   public
    constructor Create(aName : String; w : Integer = 32; h : integer = 32);
    destructor Destroy; override;

    property FrameName : String read fFrameName;//unique frame name for correct managing in mapped list
    property LayersList : TStringList read fLayers;  //layers mapped list
    property Index : Integer read FIndex write SetIndex;
    property Width : Integer read FWidth;
    property Height : Integer read FHeight;
    function AddLayer(LayerName : String): Boolean; //add new layer and return it`s index or -1 if error
    function DeleteLayer(aLayerName : String): Boolean;      //remove layer from frame
  end;

  { TCellCursor - for drawing red rectangle followed by mouse cursor or moved by arrow keys}

  TCellCursor = class
   private
     FCells: Byte;
     FPrevX: Integer;
     FPrevY: Integer;
     FX: Integer;
     FY: Integer;
     function GetPrevCoords: TPoint;
     procedure SetCells(AValue: Byte);
     procedure SetCoords(AValue: TPoint);
     function GetCoords : TPoint;
   public
    property X : Integer read FX write FX default 0;
    property Y : Integer read FY write FY default 0;
    property Coords : TPoint read GetCoords write SetCoords; //cell coords
    property PrevCoords : TPoint read GetPrevCoords; //prevoius coords for correct moving
    property PrevX : Integer read FPrevX default 0;
    property PrevY : Integer read FPrevY default 0;
    property Cells : Byte read FCells write SetCells default 1; //cursor size in cells i.e. 2x2, 4x4 etc.
  end;

  { TFrameGrid }

  TFrameGrid = class
   private
    fActiveFrame: String;
    FActiveLayer: String;
    FCellCursor: TCellCursor;
    FBackground: Boolean;
    FCheckersSize  : Byte;
    fPreview       : TBGRABitmap; //for draw image preview
    fBuffer        : TBGRABitmap; //for zoomed draw
    fFrameGridSize : Word;   //current grid size
    fFrameWidth,
    fFrameHeight   : Integer;   //frame size in pixels
    fFrameZoom     : Integer;//zoom coeff for drawing grid (0 for normal size)
    fRect          : TRect;  //grid area on canvas
    fShowGrid      : Boolean;//if true grid will be draw
    fOffset        : TPoint; //offset to draw frame on canvas
    procedure CalcGridRect;
    procedure SetCheckersSize(AValue: Byte);
    procedure SetFrameZoom(AValue: Integer);
    procedure SetOffset(AValue: TPoint);
   public
    function Coords(x,y : Integer): TPoint; //return pixel coordinates in grid cell
    function PixelPos(x,y : Integer) : Integer; //return pixel index in array

    constructor Create(aW: Integer = 32; aH : Integer = 32; aSize : Word = 10);
    constructor Create(aImg : TFileName); //create frame from image file
    destructor Destroy; override;

    function HasCoords(aPoint : TPoint) : Boolean; //check if frame has point
    procedure RenderAndDraw(Canvas : TCanvas);  //draw background and all layers data to canvas
    procedure RenderPicture(Canvas : TCanvas);
    procedure ExpotPng(aFilename : TFileName);  //export frame to file
    property ShowGrid : Boolean read fShowGrid write fShowGrid;      //draw grid
    property FrameZoom : Integer read fFrameZoom write SetFrameZoom; //scale index
    property Offset : TPoint read FOffset write SetOffset;
    property CheckersSize : Byte read FCheckersSize write SetCheckersSize default 16;
    property FrameWidth : Integer read fFrameWidth;
    property FrameHeight : Integer read fFrameHeight;
    property ActiveFrame : String read fActiveFrame write fActiveFrame; //work frame name to access through mapped list
    property ActiveLayer : String read FActiveLayer write FActiveLayer; //current layer to draw
    property CellCursor : TCellCursor read FCellCursor; //just red frame to show where draw in grid
  end;


  TLayers = specialize TFPGMapObject<String,TSPLayer>;  //mapped layers list
  TFrames = specialize TFPGMapObject<String,TSPFrame>;  //mapped frames list

var

  UserSettingsPath : UTF8String;
  SpriteLibPath    : UTF8String;
  AppSettingsFile  : UTF8String;
  INI              : TIniFile;
  SpriteLibNames   : TStringList;
  CurrentLibName   : UTF8String;//selected library name
  libpath          : UTF8String;//selected library full path
  BufferLayer      : TSPLayer;    //for temporary drawing

  //Drawing colors
  spclForeColor : TBGRAPixel;  //foreground color - left mouse button drawing
  spclBackColor : TBGRAPixel; //background color - right mouse button drawing
  //Work palette
  Palette       : TPalette;

  FrameGrid     : TFrameGrid;
  Layers        : TLayers;
  Frames        : TFrames;

  //**********************************************************************
  function IsDigits(s : String) : Boolean;
  //check string for digits only

  function ConvertHtmlHexToTColor(HexColor: String):TColor;
  function CheckHexForHash(col: string):string;
  function ConvertTColorToHTML(aColor: TColor) : String;
  function CheckLayerName(aName : String) : String; //check layer name if exists return aName+'1' on aName if not
  function DetectPOLanguage(pofile : TFileName) : String;  //return language code for localization
  function LayerExists(aKey : String) : Boolean; inline; //check if layer key exists
  procedure ClearBitmap(const aBmp : TBGRABitmap);//replase all pixels to BGRAPixelTransparent
  procedure ResizeLayers(aW,aH : Integer); //resize al layers when change frame size

implementation

procedure LoadSpriteLibDirs;
var
  sr: TSearchRec;
begin
  If SpriteLibPath[Length(SpriteLibPath)] <> PathDelim then
    SpriteLibPath := SpriteLibPath + PathDelim;
  If FindFirst(SpriteLibPath + '*', faDirectory, sr) = 0 then
    repeat
      If (sr.Name = '') or (sr.Name = '.') or (sr.Name = '..') then
       Continue;
       SpriteLibNames.Add(sr.Name);
    until (FindNext(sr) <> 0);
  FindClose(sr);
end;

function IsDigits(s: String): Boolean;
var
  C: Char;
  B: Boolean;
begin
  for C in S do
  begin
    B := C in ['0'..'9'];
    if not B then Break;
  end;
  result := B;
end;

function ConvertHtmlHexToTColor(HexColor: String): TColor;
var
    rColor : TColor;
begin
     HexColor := CheckHexForHash(HexColor);

     if (length(Hexcolor) = 6) then
     begin
           {remember that TColor is bgr not rgb: so you need to switch then around}
           hexcolor := '$00' + copy(hexcolor,5,2) + copy(hexcolor,3,2) + copy(hexcolor,1,2);
           rColor := StrToInt(hexcolor);
     end;

     result := rColor;
end;

function CheckHexForHash(col: string): string;
begin
     if col[1] = '#' then
           col := StringReplace(col,'#','',[rfReplaceAll]);
     result := col;
end;

function ConvertTColorToHTML(aColor: TColor): String;
begin
   Result := '#'+IntToHex(Blue(aColor))+IntToHex(Green(aColor))+IntToHex(Red(aColor));
end;

function CheckLayerName(aName: String): String;
var i : Integer;
begin
  Result:=aName;
  for i:=0 to Layers.Count-1 do begin
    if Layers.Keys[i]=aName then begin
       Result:=aName+'1';
       Break;
    end;
  end;
end;

function NumCountChars(const Char: char; const S: String): Integer;
var
  I : Integer;
begin
  Result := 0;
  if Length(S) > 0 then
    for I := 1 to Length(S) do
      if S[I] = Char then Inc(Result);
end;


procedure CreateInternalFrameAndLayer;
begin
 Frames[cINTERNALLAYERANDFRAME]:=TSPFrame.Create(cINTERNALLAYERANDFRAME);
 Layers[cINTERNALLAYERANDFRAME]:=TSPLayer.Create(cINTERNALLAYERANDFRAME);
 Layers[csDRAWLAYER]:=TSPLayer.Create(csDRAWLAYER);
 Layers[cINTERNALLAYERANDFRAME].AddToFrame(cINTERNALLAYERANDFRAME);
 Frames[cINTERNALLAYERANDFRAME].AddLayer(cINTERNALLAYERANDFRAME);
end;

procedure ClearFramesAndLayers;
var
    f , l : Integer;
    aKey  : String;
begin
  while l>0 do begin
    aKey:=Layers.Keys[l];
    Layers.Remove(aKey);
  end;
  f:=Frames.Count-1;
  while f>0 do begin
    aKey:=Frames.Keys[f];
    Frames.Remove(aKey);
  end;
end;

{ TSPUndoRec }

constructor TSPUndoRec.Create(aLayerName: String);
begin
  FLayerName:=aLayerName;
  fFramename:=FrameGrid.ActiveFrame;
  //todo: get selected layer index from active frame layers list
  //fLayerIdx:=Frames[fFramename].;
  fImg:=TBGRABitmap.Create(Layers[FLayerName].Drawable);
end;

destructor TSPUndoRec.Destroy;
begin
  FreeAndNil(fImg);
end;

procedure TSPUndoRec.Undo;
begin
  if not LayerExists(FLayerName) then begin     //todo: restore deleted layer to frame with previous index
   Layers[FLayerName]:=TSPLayer.Create(FLayerName,FrameGrid.FrameWidth,FrameGrid.FrameHeight);
  end;
  ClearBitmap(Layers[FLayerName].Drawable);
  Layers[FLayerName].Drawable.PutImage(0,0,fImg,dmSetExceptTransparent);
end;

{ TCellCursor }

procedure TCellCursor.SetCoords(AValue: TPoint);
begin
  if ((AValue.X<0) or (AValue.Y<0) or(AValue.X>FrameGrid.FrameWidth-1) or (AValue.Y>FrameGrid.FrameHeight-1)) then Exit;
  X:=AValue.X;

  Y:=AValue.Y;
end;

function TCellCursor.GetPrevCoords: TPoint;
begin
  Result := Point(PrevX,PrevY);
end;

procedure TCellCursor.SetCells(AValue: Byte);
begin
  //if (AValue<1) or (AValue>3) then Exit;
  FCells:=AValue;
end;

function TCellCursor.GetCoords: TPoint;
begin
  Result := Point(X,Y);
end;

{ TSPFrame }

procedure TSPFrame.SetIndex(AValue: Integer);
begin
  if (FIndex=AValue) or (AValue>FCount) then Exit;
  FIndex:=AValue;
end;

constructor TSPFrame.Create(aName: String; w: Integer; h: integer);
begin
 //create an empty frame without layers
 fFrameName:=aName;
 FWidth:=w;
 FHeight:=h;
 fLayers:=TStringList.Create;
end;

destructor TSPFrame.Destroy;
begin
  fLayers.Clear;
  FreeAndNil(fLayers);
  inherited Destroy;
end;

function TSPFrame.AddLayer(LayerName: String): Boolean;
begin
  result := False;
  if fLayers.IndexOf(LayerName)<>-1 then Exit;
  fLayers.Add(LayerName);
  Result:=True;
end;

function TSPFrame.DeleteLayer(aLayerName: String): Boolean;
 var i : Integer;
begin
  Result:=False;
  i:=fLayers.IndexOf(aLayerName);
  if i>0 then begin
    fLayers.Delete(i);
    Result:=True;
  end;
end;

{ TSPLayer }

procedure TSPLayer.Resize(newWidth, NewHeight: Integer; Stretched: Boolean);
begin
  if Stretched then begin
    fLayerImg:=fLayerImg.Resample(newWidth,NewHeight);
  end else begin
    fLayerImg.SetSize(newWidth,NewHeight);
  end;

end;

procedure TSPLayer.AddToFrame(FrameName: String);
begin
  FFrames.Add(FrameName);
end;

function TSPLayer.DeleteFromFrame(aFrameName: String): Boolean;
var i : Integer;
begin
 Result:=False;
 i:=FFrames.IndexOf(aFrameName);
 if i>0 then begin
   FFrames.Delete(i);
   Result:=True;
 end;
end;

constructor TSPLayer.Create(aName: String; aWidth: Integer; aHeight: Integer);
begin
  fLayerImg := TBGRABitmap.Create(aWidth,aHeight);
  fVisible:=True;
  FLocked:=False;
  FFrames := TStringList.Create;
  FFrames.CaseSensitive:=false;
end;

destructor TSPLayer.Destroy;
begin
  FFrames.Clear;
  FreeAndNil(FFrames);
  FreeAndNil(fLayerImg);
  inherited Destroy;
end;

procedure TSPLayer.Clear;
begin
 fLayerImg.EraseRect(0,0,fLayerImg.Width,fLayerImg.Height,255);
end;

procedure TSPLayer.ClearDrawable;
begin
  ClearBitmap(fLayerImg);
end;

{ TFrameGrid }

procedure TFrameGrid.SetOffset(AValue: TPoint);
begin
  FOffset.Offset(AValue);
  CalcGridRect;
end;

function TFrameGrid.Coords(x, y: Integer): TPoint;
var posx,posy : Integer; //relative grid coordinates
begin
  Result := Point(-1,-1);
  if fRect.Contains(Point(x,y)) then begin
     posx:=x-fOffset.X;
     posy:=y-fOffset.Y;
     Result.X:= posx div (fFrameGridSize+fFrameZoom);
     Result.Y:= posy div (fFrameGridSize+fFrameZoom);
  end;
end;

function TFrameGrid.PixelPos(x, y: Integer): Integer;
begin
    if ((x<0) or (y<0)) then Result:=-1 else
    Result := y*fFrameWidth+x;
end;

procedure TFrameGrid.SetFrameZoom(AValue: Integer);
begin
  if fFrameZoom=AValue then Exit;
  fFrameZoom:=AValue;
  CalcGridRect;
end;

procedure TFrameGrid.SetCheckersSize(AValue: Byte);
begin
  if FCheckersSize=AValue then Exit;
  if (AValue>0) and (AValue<255) then FCheckersSize:=AValue;
end;

procedure TFrameGrid.CalcGridRect;
begin
  fRect.Create(fOffset, fFrameWidth*(fFrameGridSize+fFrameZoom)+1,
                        fFrameHeight*(fFrameGridSize+fFrameZoom)+1);
  if Assigned(fBuffer) then
     BGRAReplace(fBuffer,fBuffer.Resample(fRect.Width,fRect.Height));
end;

constructor TFrameGrid.Create(aW: Integer; aH: Integer; aSize: Word);
begin
  fFrameGridSize:=aSize;
  fFrameHeight:=aH;
  fFrameWidth:=aW;
  FCheckersSize:=INI.ReadInteger('INTERFACE','CHECKERS SIZE',32);
  fFrameZoom:=0;
  CalcGridRect;
  fPreview:=TBGRABitmap.Create(aW,aH);
  FCellCursor := TCellCursor.Create;
  FCellCursor.Cells:=1;
  {$IFDEF DEBUG}
  DebugLn(DateTimeToStr(Now), ': In  TFrameGrid.Create() Layers count ',IntToStr(Layers.Count));
  {$ENDIF}
  FActiveLayer:=cINTERNALLAYERANDFRAME;
  fActiveFrame:=cINTERNALLAYERANDFRAME;
  fBuffer:=TBGRABitmap.Create(fFrameWidth*(fFrameGridSize+fFrameZoom),
                              fFrameHeight*(fFrameGridSize+fFrameZoom));
  ResizeLayers(FrameWidth,FrameHeight);
end;

constructor TFrameGrid.Create(aImg: TFileName);
var aBmp : TBGRABitmap;
    aFrameName : String;
    i: Integer;
begin
    aBmp:=TBGRABitmap.Create(aImg);
    Create(aBmp.Width,aBmp.Height);
    aFrameName:=ExtractFileName(aImg);
    Frames[aFrameName]:=TSPFrame.Create(aFrameName, FrameWidth, FrameHeight);
    Layers[aFrameName]:=TSPLayer.Create(aFrameName,FrameWidth,FrameHeight);
    ActiveFrame:=aFrameName;

    Frames[aFrameName].AddLayer(aFrameName);
    Layers[cINTERNALLAYERANDFRAME].AddToFrame(aFrameName);
    ClearBitmap(Layers[cINTERNALLAYERANDFRAME].Drawable);
    ResizeLayers(FrameWidth,FrameHeight);
    Layers[cINTERNALLAYERANDFRAME].Drawable.PutImage(0,0,aBmp,dmSetExceptTransparent);
    FreeAndNil(aBmp);
end;

destructor TFrameGrid.Destroy;
begin
  INI.WriteInteger('INTERFACE','CHECKERS SIZE',FCheckersSize);
  FreeAndNil(fPreview);
  FreeAndNil(fBuffer);
  FreeAndNil(FCellCursor);
  inherited Destroy;
end;

function TFrameGrid.HasCoords(aPoint: TPoint): Boolean;
begin
  result := fRect.Contains(aPoint);
end;

procedure TFrameGrid.RenderAndDraw(Canvas: TCanvas);
var
  i, _i: Integer;

  procedure DrawGrid(x1,y1,x2,y2 : Integer; size : Integer);
   var i, xsize, ysize : Integer;
  begin
    xsize := (x2-x1) div size;
    ysize := (y2-y1) div size;
    For i := 1 to ysize do fBuffer.DrawLine(x1,y1+i*size,x2,y1+i*size,ColorToBGRA(clNavy),False);
    For i := 1 to xsize do fBuffer.DrawLine(x1+i*size,y1,x1+i*size,y2,ColorToBGRA(clNavy),False);
    fBuffer.Rectangle(x1,y1,x2,y2,ColorToBGRA(clNavy));
  end;

  procedure InternalDrawLayer(const aLayer : TSPLayer);
  var
    x,y: Integer;
    tmpPix : TBGRAPixel;
  begin
    {$IFDEF DEBUG}
    Assert(Assigned(aLayer),'Layer not assigned!');
    {$ENDIF}
     for x := 0 to aLayer.Drawable.Width-1 do
    for y:= 0 to aLayer.Drawable.Height-1 do begin
      tmpPix := aLayer.Drawable.GetPixel(x,y);
      if tmpPix.alpha>0 then begin
        //draw filled rectangle
         fBuffer.Rectangle(X*(fFrameGridSize+fFrameZoom)+1,
                    Y*(fFrameGridSize+fFrameZoom)+1,
                    X*(fFrameGridSize+fFrameZoom)+(fFrameGridSize+fFrameZoom),
                    Y*(fFrameGridSize+fFrameZoom)+(fFrameGridSize+fFrameZoom),
                    tmpPix,tmpPix);
      end;
    end;
  end;

begin
  ShowGrid:=(fFrameGridSize+fFrameZoom)>3;
  {$IFDEF DEBUG}
   DebugLn(DateTimeToStr(Now()),' In: TFrameGrid.RenderAndDraw(); FrameWidth=',IntToStr(fBuffer.Width),' FrameHeight=',IntToStr(fBuffer.Height));
  {$ENDIF}
  fBuffer.DrawCheckers(Rect(0,0,fBuffer.Width,fBuffer.Height),
                       ColorToBGRA($BFBFBF),
                       ColorToBGRA($FFFFFF),
                       FCheckersSize,
                       FCheckersSize);;

  if ShowGrid then DrawGrid(0,0,fBuffer.Width-1,fBuffer.Height-1,fFrameGridSize+fFrameZoom);


  //draw all layers to fBuffer
  {$IFDEF DEBUG}
  DebugLn(DateTimeToStr(Now), ' In: RenderAndDraw(); Active frame: ',ActiveFrame,' layers: ',Frames[ActiveFrame].fLayers.Text);
  DebugLn(DateTimeToStr(Now), ' In: RenderAndDraw(); Layer names:',IntToStr(Frames[ActiveFrame].fLayers.Count));
  {$ENDIF}

  //first draw internal layer
  if LayerExists(cINTERNALLAYERANDFRAME) then InternalDrawLayer(Layers[cINTERNALLAYERANDFRAME]);
  if Frames[ActiveFrame].fLayers.Count>0 then
  for i:=0 to Frames[ActiveFrame].fLayers.Count-1 do begin
     if LayerExists(Frames[ActiveFrame].fLayers.Strings[i]) and
        Layers[Frames[ActiveFrame].fLayers.Strings[i]].Visible then
          InternalDrawLayer(Layers[Frames[ActiveFrame].fLayers.Strings[i]]);
  end;
  //last draw DRAWLAYER from drawing tool
  if LayerExists(csDRAWLAYER) then InternalDrawLayer(Layers[csDRAWLAYER]);

  //draw highlited cell cursor over the grid
  fBuffer.Rectangle(CellCursor.X*(fFrameGridSize+fFrameZoom),
                    CellCursor.Y*(fFrameGridSize+fFrameZoom),
                    CellCursor.X*(fFrameGridSize+fFrameZoom)+(fFrameGridSize+fFrameZoom)*CellCursor.Cells,
                    CellCursor.Y*(fFrameGridSize+fFrameZoom)+(fFrameGridSize+fFrameZoom)*CellCursor.Cells,clRed);
  fBuffer.Draw(Canvas,fOffset.X,fOffset.Y);
end;

procedure TFrameGrid.RenderPicture(Canvas: TCanvas);
 var
   i : Integer;

begin
  ClearBitmap(fPreview);
  if Canvas<>nil then
    fPreview.DrawCheckers(Rect(0,0,fPreview.Width,fPreview.Height),
                        ColorToBGRA($BFBFBF),
                        ColorToBGRA($FFFFFF),
                        4,
                        4);
  //draw all layers to canvas
  {$IFDEF DEBUG}
  DebugLn(DateTimeToStr(Now), ' In: RenderPicture(); Active frame: ',ActiveFrame,' layers: ',Frames[ActiveFrame].fLayers.Text);
  {$ENDIF}
  if LayerExists(cINTERNALLAYERANDFRAME) then fPreview.PutImage(0,0,Layers[cINTERNALLAYERANDFRAME].Drawable,dmDrawWithTransparency);
  for i:=0 to Frames[ActiveFrame].fLayers.Count-1 do
    if LayerExists(Frames[ActiveFrame].fLayers.Strings[i]) then
      fPreview.PutImage(0,0,Layers[Frames[ActiveFrame].fLayers.Strings[i]].Drawable,dmDrawWithTransparency);
  if LayerExists(csDRAWLAYER) then fPreview.PutImage(0,0,Layers[csDRAWLAYER].Drawable,dmDrawWithTransparency);
  if Assigned(Canvas) then fPreview.Draw(Canvas,0,0,true);
end;

procedure TFrameGrid.ExpotPng(aFilename: TFileName);
begin
  if aFilename<>'' then begin
   RenderPicture(nil);
   fPreview.SaveToFileUTF8(aFilename);
  end;
end;

{ TPalette }

function TPalette.GetColor(Index: Byte): TBGRAPixel;
begin
  if Index>fCount then Result:=clNone
   else Result:=fColors[Index];
end;

function TPalette.isEmpty: Boolean;
begin
  Result:=fCount=0;
end;


procedure TPalette.Clear;
var
  i: Integer;
begin
  fCount :=  0;
  fSelected:=0;
  for i :=  0 to MAX_PALETTE_COLORS do fColors[i]:=clNone;
end;

procedure TPalette.Reset;
begin
  Clear;
  AddColor(clBlackOpaque);
  AddColor(clMaroon);
  AddColor(clGreen);
  AddColor(clOlive);
  AddColor(clNavy);
  AddColor(clPurple);
  AddColor(clTeal);
  AddColor(clGray);
  AddColor(clSilver);
  AddColor(clRed);
  AddColor(clLime);
  AddColor(clYellow);
  AddColor(clBlue);
  AddColor(clFuchsia);
  AddColor(clAqua);
  AddColor(clWhite);
  AddColor(clCream);
  AddColor(clMedGray);
  AddColor(clMoneyGreen);
  AddColor(clSkyBlue);
end;

procedure TPalette.SelectColor(Index: Byte);
begin
  FSelectedColor:=Color[Index];
end;

procedure TPalette.SaveToFile(aName: TFileName);
var l : TStringList;
  i: Integer;
begin
  l:=TStringList.Create;
  for i := 0 to fCount-1 do l.Add(ConvertTColorToHTML(fColors[i]));
  l.SaveToFile(aName);
  FreeAndNil(l);
end;

function TPalette.LoadFromFile(aName: TFileName): Boolean;
var l : TStringList;
  i: Integer;
begin
  result := False;
  Clear;
  l:=TStringList.Create;
  l.LoadFromFile(aName);
  for i:=0 to l.Count-1 do begin
    if l.Strings[i]<>'' then begin
      AddColor(ConvertHtmlHexToTColor(l.Strings[i]));
    end;
  end;
  FreeAndNil(l);
end;

function TPalette.AddColor(aColor: TBGRAPixel): Integer;
begin
  if fCount=0 then begin
    fColors[fCount]:=aColor;
    Inc(fCount);
    Result:=fCount;
    Exit;
  end;
  //check if color exists
  Result:= ColorExists(aColor);
  if (Result=-1) and (fCount<MAX_PALETTE_COLORS) then begin
    fColors[fCount]:=aColor;
    Inc(fCount);
    Result:=fCount;
  end;
  Sort;
end;

procedure TPalette.Sort;
var  Temp: Integer;
  i: Integer;
  Changed: Boolean;
begin
  //todo: change sort algorithm
  repeat
    Changed:= False;
    for i:= 1 to fCount - 1 do
      if (fColors[i].ToColor > fColors[i + 1].ToColor) then
      begin
        Temp:= fColors[i];
        fColors[i]:= fColors[i + 1];
        fColors[i + 1]:= Temp;
        Changed:= True;
      end;
  until not Changed;
end;

function TPalette.ColorExists(aColor: TBGRAPixel): Integer;
var
  i: Integer;
begin
  result := -1; //color NOT exists in palette
  if fCount=0 then Exit;
  for i:=0 to fCount-1 do begin
    if fColors[i]=aColor then begin
      Result:=i;
      Break;
    end;
  end;

end;


function GetAppName : String;
begin
  Result := 'spedit';
end;

function DetectPOLanguage(pofile : TFileName) : String;
var s : String;
  strl : TStringList;
begin
   result := '';
   if pofile='' then Exit;
   strl:=TStringList.Create;
   strl.LoadFromFile(pofile);
   s:=strl.Text;
   Delete(s,1,Pos('Language:',s)+Length('Language:'));
   Delete(s,Pos('\n"',s),Length(s));
   s:=Trim(s);
   FreeAndNil(strl);
   SetDefaultLang(s,ExtractFileDir(pofile));
   Result:=s;
 end;

function LayerExists(aKey: String): Boolean;
begin
  result := (Layers.IndexOf(aKey)<>-1);
end;

procedure ClearBitmap(const aBmp: TBGRABitmap);
var
  p: PBGRAPixel;
  n: integer;
begin
  p := aBmp.Data;
  for n := aBmp.NbPixels - 1 downto 0 do
  begin
      p^ := BGRAPixelTransparent;
    Inc(p);
  end;
  aBmp.InvalidateBitmap;
end;

procedure ResizeLayers(aW, aH: Integer);
var
  i : Integer;
  aKey : String;
begin
 for i:=0 to Layers.Count-1 do begin
  aKey:=Layers.Keys[i];
  Layers[aKey].Resize(aW,aH);
  ClearBitmap(Layers[aKey].Drawable);
 end;
end;

initialization

 OnGetApplicationName := @GetAppName;
 // get app settings path and file
 UserSettingsPath:=GetAppConfigDir(false);
 AppSettingsFile:=GetAppConfigFile(false);
 SpriteLibPath:=GetUserDir+DirectorySeparator+'spedit 4 spritelib';

 INI:= TIniFile.Create(AppSettingsFile,[]);

 //load sprite library names from spedit usersettings path
 //Every library stored in own directory
 SpriteLibNames:=TStringList.Create;
 ForceDirectories(SpriteLibPath);
 LoadSpriteLibDirs;
 //get last spritelib name
 CurrentLibName:=INI.ReadString('INTERFACE','SPRITELIB','default');
 libpath:=SpriteLibPath+DirectorySeparator+CurrentLibName;
 //frame editor params
 spclBackColor:=INI.ReadInteger('FRAME EDITOR','BACKGROUND COLOR',clNone);
 spclForeColor:=INI.ReadInteger('FRAME EDITOR','FOREGROUND COLOR',clBlackOpaque);
 //palette with default colors
 Palette.Reset;

 //mapped lists of frames and layers
 Frames:=TFrames.Create;
 Layers :=TLayers.Create;
 CreateInternalFrameAndLayer;


 finalization
  INI.WriteString('INTERFACE','SPRITELIB',CurrentLibName);
  //ClearFramesAndLayers;
  FreeAndNil(Layers);
  FreeAndNil(Frames);
  FreeAndNil(FrameGrid);
  FreeAndNil(SpriteLibNames);
  FreeAndNil(INI);
end.

