
{ ----------------------------------------------------------------------------
                                   CW STREAMER
  ----------------------------------------------------------------------------

    :Description
       TCWFile: Enables fixed sized segmenting for the read-write operations
         of the files.

    :History
       06.08.2004 00:25 [+] Connection property added to TCWFile
       09.07.2004 02:14 [+] Link property.. For to store the related
                            connection object
       24.06.2004 00:00 [#] TCWFile created(stable)

    :ToDo
       [+] OnTransfer
       [+] TCWFileList, TCWFileManager(for file related events..)

  ---------------------------------------------------------------------------- }

unit CWStreamer;

interface

uses
  SysUtils, Classes, CWTcpProtocol, Windows, Contnrs;

type
  TCWFile = class;

//  TCWStreamMode = (smRead, smWrite);

  TCWExFileMaster = class(TObject)
  private
    FNode: TCWP2PNode;
    FFiles: TList;
    function GetFiles(i: integer): TCWFile;
  public
    constructor Create(ANode: TCWP2PNode);
    destructor Destroy; override;
    function Add(AFile: string; AMode: TCWStreamMode; AConnection: TCWTcpConnection): TCWFile; overload;
    function Delete(AConnection: TCWTcpConnection): Boolean; overload;
    property Files[i: integer]: TCWFile read GetFiles;
  end;

  TCWExFile = class(TObject)
  private
    FData: TFileStream;
    FTempData: TMemoryStream;
    FIsThisFirstData: Boolean;
    FFileSize: integer;
    FSegmentSize: integer;
    FOnCompleted: TNotifyEvent;
    FFileName: string;
    FPosition: integer;
    FFileMode: TCWStreamMode;
    FFinished: Boolean;
    FActive: Boolean;
    FLink: Pointer;
    FConnection: TCWTcpConnection;

    procedure AddPackHeader(AType: TCW_Pack_Type; ALength: integer; var Strm: TMemoryStream);
    procedure AddFileInfoHeader(APos, ALength: integer; var Strm: TMemoryStream);
    procedure AddFileHeader(ALength: integer; var Strm: TMemoryStream);

    procedure DoOnComplete(Sender: TObject);
    function GetFileSize: integer;
    function GetPosition: integer;
    procedure SetPosition(const Value: integer);
    procedure SetFileSize(const Value: integer);
    function GetFileHandle: HWND;
  public
    constructor Create(AFile: string; AMode: TCWStreamMode);
    destructor Destroy; override;

    procedure FlushToDrive;

    procedure WriteSegment(ASegment: Pointer; ADataLen: integer);
    function ReadSegment(var DataSize: integer): Pointer;

    property SegmentSize: integer read FSegmentSize write FSegmentSize;
    property FileName: string read FFileName;
    property FileSize: integer read GetFileSize write SetFileSize;
    property FileMode: TCWStreamMode read FFileMode;
    property Position: integer read GetPosition write SetPosition;
    property Finished: Boolean read FFinished write FFinished;
    property FileHandle: HWND read GetFileHandle; // can be use by threads..
    property Active: Boolean read FActive write FActive;
    property OnCompleted: TNotifyEvent read FOnCompleted write FOnCompleted;
    property Link: Pointer read FLink write FLink;
    property Connection: TCWTcpConnection read FConnection;
  end;

  

implementation

uses
  Dialogs;

{ TCWStreamer }

procedure TCWExFile.AddFileHeader(ALength: integer; var Strm: TMemoryStream);
var
  FileHdr: PCW_File_Hdr;
begin
  New(FileHdr);
  try
    with FileHdr^ do
    begin
      DataLen := ALength;
    end;
    Strm.Write(FileHdr^, SizeOf(TCW_File_Hdr));
  finally
    Dispose(FileHdr);
  end;
end;

procedure TCWExFile.AddFileInfoHeader(APos, ALength: integer; var Strm: TMemoryStream);
var
  InfoPackHdr: PCW_File_Info_Hdr;
begin
  New(InfoPackHdr);
  try
    with InfoPackHdr^ do
    begin
      Caption := FFileName;
      IndicatorPos := APos;
      DataLen := ALength;
    end;
    Strm.Write(InfoPackHdr^, SizeOf(TCW_File_Info_Hdr));
  finally
    Dispose(InfoPackHdr);
  end;
end;

procedure TCWExFile.AddPackHeader(AType: TCW_Pack_Type; ALength: integer; var Strm: TMemoryStream);
var
  PackHdr: PCW_Pack_Hdr;
begin
  New(PackHdr);
  try
    with PackHdr^ do
    begin
      Integrity := 'oktay';
      PackType := AType;
      DataLen := ALength;
    end;
    Strm.Write(PackHdr^, SizeOf(TCW_Pack_Hdr));
  finally
    Dispose(PackHdr);
  end;
end;

constructor TCWExFile.Create(AFile: string; AMode: TCWStreamMode);
begin
  Active := True;
  FFileName := AFile;
  FFileMode := AMode;
  FIsThisFirstData := True;
  Finished := False;
  FTempData := TMemoryStream.Create;
  try
    case FFileMode of
      smRead:
        begin
          FData := TFileStream.Create(FFileName, fmOpenRead, fmShareDenyWrite);
        end;
      smWrite:
        begin
          FData := TFileStream.Create(FFileName, fmCreate, fmShareExclusive);
        end;
    end;
  except
    on E: Exception do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
  FPosition := 0;
  FSegmentSize := 4096;
end;

destructor TCWExFile.Destroy;
begin
  FreeAndNil(FData);
  FreeAndNil(FTempData);
  inherited;
end;

procedure TCWExFile.DoOnComplete(Sender: TObject);
begin
  FFinished := True;
  if Assigned(FOnCompleted) then OnCompleted(Self);
end;

procedure TCWExFile.FlushToDrive;
begin
  FlushFileBuffers(FData.Handle);
end;

function TCWExFile.GetFileHandle: HWND;
begin
  Result := FData.Handle;
end;

function TCWExFile.GetFileSize: integer;
begin
  if (FFileMode = smRead) then
  begin
    Result := FData.Size;
  end
  else begin
    Result := FFileSize;
  end;
end;

function TCWExFile.GetPosition: integer;
begin
  Result := FData.Position;
end;

function TCWExFile.ReadSegment(var DataSize: integer): Pointer;
var // do we need to set the position to 0 ??
  Tag: integer;
  DataLength: integer;

  PTemp: Pointer;
begin
  FTempData.Clear;
  DataSize := 0;
  Result := FTempData.Memory; // nil
  try
    if FData.Position < FData.Size then
    begin
      if FIsThisFirstData then
      begin
        AddPackHeader(ptFileInfo, SizeOf(TCW_File_Info_Hdr), FTempData);
        AddFileInfoHeader(Position, FileSize, FTempData);  // 
        FIsThisFirstData := False;
      end;

      AddPackHeader(ptFile, SizeOf(TCW_File_Hdr), FTempData);

      if (FData.Size - FData.Position) >= (SegmentSize - (FTempData.Size + SizeOf(TCW_File_Hdr))) then
      begin
        Tag := SegmentSize - (FTempData.Size + SizeOf(TCW_File_Hdr));
      end
      else begin
        Tag := FData.Size - FData.Position;
      end;
      AddFileHeader(Tag, FTempData);

      FTempData.CopyFrom(FData, Tag);
      DataSize := FTempData.Size;

      Result := FTempData.Memory;
    end
    else begin
      DoOnComplete(Self);
    end;
  finally
    // --
  end;
end;

procedure TCWExFile.SetFileSize(const Value: integer);
begin
  if (FFileMode = smWrite) then
  begin
    FFileSize := Value;
  end;
end;

procedure TCWExFile.SetPosition(const Value: integer);
begin
  if Value <> FData.Position then
  begin
    FData.Position := Value;
  end;
end;

procedure TCWExFile.WriteSegment(ASegment: Pointer; ADataLen: integer);
begin
  if (Position < FileSize) then
  begin
    try
      FData.WriteBuffer(ASegment^, ADataLen);
      FlushToDrive;
    except
      on E: Exception do
        MessageDlg(E.Message, mtError, [mbOK], 0);
    end;
    if not (FData.Position < FData.Size) then
    begin
      DoOnComplete(Self);
    end;
  end
  else begin
    DoOnComplete(Self);
  end;
end;

{ TCWFileMaster }

function TCWExFileMaster.Add(AFile: string; AMode: TCWStreamMode;
  AConnection: TCWTcpConnection): TCWFile;
begin

end;

constructor TCWExFileMaster.Create(ANode: TCWP2PNode);
begin
  FNode := ANode;
  FFiles := TList.Create;
end;

function TCWExFileMaster.Delete(AConnection: TCWTcpConnection): Boolean;
var
  Found: Boolean;
  i: integer;
begin
  Found := False;
  if (FFiles.Count > 0) then
  begin
    for i := FFiles.Count - 1 downto 0 do
    begin
      if CompareMem(AConnection, TCWTcpConnection(FFiles.Items[i]), SizeOf(AConnection)) then
      begin
        Found := True;
        
        TCWFile(FFiles.Items[i]).Free;
        FFiles.Delete(i);
        Break;
      end;
    end;
  end;
  Result := Found;
end;

destructor TCWExFileMaster.Destroy;
begin
  FFiles.Free;
  inherited;
end;

function TCWExFileMaster.GetFiles(i: integer): TCWFile;
var
  Fl: TCWFile;
begin
  Fl := nil;
  if (i >= 0) and (i < FFiles.Count) then
  begin
    Fl := TCWFile(FFiles.Items[i]);
  end;
  Result := Fl;
end;

end.
