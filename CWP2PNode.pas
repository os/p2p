
{ ----------------------------------------------------------------------------
                                  CW P2P NODE
  ----------------------------------------------------------------------------

    :Description

       P2P file sharing and messaging application.

    :History
       17.01.2005 03:53 [+] ECWRemoteHostNotFound added and works perfectly
                            at the app level
       14.12.2004 04:31 [!] UniqueId problem fixed
       14.12.2004 01:46 [+] IsNeedToSleep for thread memory loads
       07.09.2004 15:56 [+] GetFileInOrder added but not tested yet !!
       26.08.2004 03:15 [*] TCWFile's UniqueId changed to string
       12.08.2004 22:38 [#] TCWFileMaster completed..
       12.08.2004 22:26 [+] UniqueID feature added to the TCWFile and it's
                            master
       06.08.2004 00:36 [*] TCWConnectionMaster GetConnection modified
       06.08.2004 00:25 [+] Connection property added to TCWFile
       02.08.2004 01:38 [+] OnConnect, OnDisconnect events added..
       28.07.2004 01:22 [*] Incoming and Outgoing connection's disconnect
                            events activated and re-designed
       28.07.2004 01:14 [!] AV on connection's destroy fixed by re-design the
                            existing disconnect system
       25.07.2004 01:41 [#] Ping mechanism works perfectly
       25.07.2004 01:25 [#] Tested with 100+ connection with %0 memory
                            load. Works fine..
       20.07.2004 03:39 [+] Ping feature added to the TCWTcpConnection and
                            TCWConnectionMaster
       18.07.2004 02:00 [!] Error on TriggerServerDisconnect fixed with
                            (AThread.Data := nil)
       15.07.2004 17:45 [#] TCWConnectionMaster completed(not tested !!)
       09.07.2004 02:14 [+] Link property added to TCWFile.. For to store the
                            related connection object
       24.06.2004 00:00 [#] TCWFile created(stable)

    :Features
       [o] P2P file sharing

    :ToDo
       [+] Manage connections' speeds..
       [*] Remove duplicated codes with creating new stream read functions.
       [+] Different versions of Files property (TCWFileMaster)
       [+] Add all needed triggers

  ----------------------------------------------------------------------------
  [#] Improvements   [-] Feature Removed   [*] Modified/Needs Modify
  [!] Bug/BugFix     [+] Feature Added
  ---------------------------------------------------------------------------- }

unit CWP2PNode;

interface

uses
  SysUtils, Classes, IdTCPConnection, IdTCPClient, IdTCPServer, CWTcpClient,
  IdComponent, CWTcpProtocol, ExtCtrls, Windows, IdException, CWException, Contnrs,
  CWUtils, eDebugServer;

type
  TCWBlobs = class;
  TCWP2PNode = class;
  TCWConnectionMaster = class;

  TCWTcpConnectionType = (ctIncoming, ctOutgoing); // ctCommandIncoming, ctCommandOutgoing, ctFileTransfer

  TCWFileMaster = class;
  TCWFile = class;

  TCWTcpConnection = class(TPersistent)
  private
    FConnectionMaster: TCWConnectionMaster;
    FBlobs: TCWBlobs;
    FFiles: TCWFileMaster;

    FSock: TIdTCPConnection;
    FTimer: TTimer;
    FData: Pointer;
    FConnectionType: TCWTcpConnectionType;
    FIsAlive: Boolean;
    FKeepAliveMeter: integer;
    FPingAvailable: Boolean;
    FNodeIP: string;
    FCUID: string;
    FExistingFileId: integer;
    procedure DoOnTimer(Sender: TObject);
    procedure SetIsAlive(const Value: Boolean);
  public
    constructor Create(AConnectionMaster: TCWConnectionMaster; ASock: TIdTCPConnection;
      AConnType: TCWTcpConnectionType);
    destructor Destroy; override;

    procedure SendMessage(AMsg: string); { TODO : SendMessage, SendFile, SendCommand }
    procedure SendFile(AFile: string);

    property ConnectionType: TCWTcpConnectionType
             read FConnectionType;

    property NodeIP: string read FNodeIP;

    property Sock: TIdTCPConnection
             read FSock write FSock;

    property Data: Pointer
             read FData
             write FData;

    property IsAlive: Boolean
             read FIsAlive
             write SetIsAlive; //can be use to detect the disconnects for all
             
    property PingAvailable: Boolean
             read FPingAvailable
             write FPingAvailable;

    property ExistingFileId: integer
             read FExistingFileId
             write FExistingFileId;

    property CUID: string read FCUID;
  end;

  TCWTcpConnectionEvent = procedure(AConnection: TCWTcpConnection) of object;

  TCWConnectionMaster = class(TObject)
  private
    FNode: TCWP2PNode;
    FConnections: TList;
    FKeepAliveSensitivity: integer;
    FKeepAliveInterval: integer;
    function GetConnection(i: integer): TCWTcpConnection;
    procedure ClearConnection(AConnection: TCWTcpConnection);
    function GetCount: integer;
    function GetConnectionByIP(ANodeIP: string): TCWTcpConnection;
  protected
    procedure DoKeepAliveTimer(AConnection: TCWTcpConnection);
  public
    constructor Create(ANode: TCWP2PNode);
    destructor Destroy; override;

    function Add(AConnection: TIdTCPConnection; AConnType: TCWTcpConnectionType): TCWTcpConnection; overload;
    function Add(AHost: string; APort: integer): TCWTcpConnection; overload;

    function Delete(AConnection: TCWTcpConnection): Boolean; overload;
    function Delete(AIP: string): Boolean; overload;
    function Delete(AIndex: integer): Boolean; overload;

    property Count: integer
             read GetCount;

    property Connection[i: integer]: TCWTcpConnection
             read GetConnection;

    property ConnectionByIP[ANodeIP: string]: TCWTcpConnection
             read GetConnectionByIP;

    property KeepAliveSensitivity: integer // default is 3
             read FKeepAliveSensitivity
             write FKeepAliveSensitivity;

    property KeepAliveInterval: integer
             read FKeepAliveInterval
             write FKeepAliveInterval;
  end;

  TCWStreamMode = (smRead, smWrite);

  TCWFileMaster = class(TObject)
  private
    FNode: TCWP2PNode;
    FUIDCounter: integer;
    FFiles: TList;
    function GetFiles(i: integer): TCWFile;
    function GetFileByUID(AUID: string): TCWFile;
    function GetCount: integer;
    procedure DoFileComplete(AFile: TCWFile);
  public
    constructor Create(ANode: TCWP2PNode);
    destructor Destroy; override;

    function Add(AConnection: TCWTcpConnection; AFile: string; AMode: TCWStreamMode): TCWFile; overload;
    function Delete(AUID: string): Boolean; overload;
    function Delete(AFile: TCWFile): Boolean; overload;
    function Delete(AConnection: TCWTcpConnection): Boolean; overload;
    function GetFileInOrder(AConnection: TCWTcpConnection; ATag: integer): TCWFile; // returns the next file
    { TODO : trigger OnComplete }
    property Count: integer
             read GetCount;

    property Files[i: integer]: TCWFile
             read GetFiles;

    property FileByUID[AUID: string]: TCWFile
             read GetFileByUID;
  end;

  TCWFileCompleteEvent = procedure(AFile: TCWFile) of object;

  TCWFile = class(TObject)
  private
    FData: TFileStream;
    FTempData: TMemoryStream;
    FIsThisFirstData: Boolean;
    FFileSize: integer;
    FSegmentSize: integer;
    FFileName: string;
    FPosition: integer;
    FFileMode: TCWStreamMode;
    FFinished: Boolean;
    FActive: Boolean;
    FLink: Pointer;
    FTag: integer;
    FUniqueId: string;
    FOnCompleted: TCWFileCompleteEvent;

    function GetFileSize: integer;
    function GetPosition: integer;
    procedure SetPosition(const Value: integer);
    procedure SetFileSize(const Value: integer);
    function GetFileHandle: HWND;
    procedure DoOnComplete(AFile: TCWFile);

    procedure AddPackHeader(AType: TCW_Pack_Type; ALength: integer; var Strm: TMemoryStream);
    procedure AddFileInfoHeader(APos, ALength: integer; var Strm: TMemoryStream);
    procedure AddFileHeader(ALength: integer; var Strm: TMemoryStream);
  public
    constructor Create(AFile: string; AMode: TCWStreamMode);
    destructor Destroy; override;

    procedure FlushToDrive;

    procedure WriteSegment(ASegment: Pointer; ADataLen: integer);
    function ReadSegment(var DataSize: integer): Pointer;

    property SegmentSize: integer
             read FSegmentSize
             write FSegmentSize;
             
    property FileName: string
             read FFileName;

    property FileSize: integer
             read GetFileSize
             write SetFileSize;
             
    property FileMode: TCWStreamMode
             read FFileMode;

    property FileHandle: HWND
             read GetFileHandle; // can be use by threads..
             
    property Position: integer
             read GetPosition
             write SetPosition;

    property Link: Pointer
             read FLink
             write FLink;

    property Tag: integer
             read FTag
             write FTag; // creation order of item

    property UniqueId: string
             read FUniqueId
             write FUniqueId;

    property Finished: Boolean
             read FFinished
             write FFinished;

    property Active: Boolean
             read FActive
             write FActive;

    property OnCompleted: TCWFileCompleteEvent
             read FOnCompleted
             write FOnCompleted;
    { TODO : OnStatusChange event }
  end;

  TCW_Blob_Type = (btMessage, btCommand);

  TCWBlobItem = class(TObject)
  private
    FBlobType: TCW_Blob_Type;
    FLink: Pointer;
    FDataSize: integer;
  public
    property BlobType: TCW_Blob_Type
             read FBlobType
             write FBlobType;

    property Link: Pointer
             read FLink
             write FLink;

    property DataSize: integer
             read FDataSize
             write FDataSize;
  end;

  TCWBlobs = class(TObject)
  private
    FConnection: TCWTcpConnection;
    FBlobs: TList;
    function GetBlob(i: integer): TCWBlobItem;
    function GetBlobCount: integer;
  public
    constructor Create(AConnection: TCWTcpConnection);
    destructor Destroy; override;

    function Add(ABlobType: TCW_Blob_Type; AData: Pointer; ADataSize: integer): TCWBlobItem; overload;
    procedure Delete(i: integer);

    property Blob[i: integer]: TCWBlobItem
             read GetBlob;

    property BlobCount: integer read GetBlobCount;
  end;

  TCWTcpMessageReceiveEvent = procedure(AConnection: TCWTcpConnection; AMsg: string) of object;

  TCWP2PNode = class(TComponent)
  private
    FServer: TIdTCPServer;
    FConnections: TCWConnectionMaster;
    FOnConnectionRun: TCWTcpConnectionEvent;
    FOnDisconnect: TCWTcpConnectionEvent;
    FOnConnect: TCWTcpConnectionEvent;
    FOnMessageReceive: TCWTcpMessageReceiveEvent;
    FFileList: TCWFileMaster;
    procedure SetServer(const Value: TIdTCPServer);
    
    function ReadPacketHdr(var AConnection: TIdTCPConnection; APackHdr: PCW_Pack_Hdr): Boolean;
    procedure ReadMessagePack(var AConnection: TIdTCPConnection; AMessage: TStringStream);
    procedure SendBlobPack(AConnection: TCWTcpConnection);
    //-- SendFilePack
  protected
  { events for servers }
    procedure TriggerServerConnect(AThread: TIdPeerThread);
    procedure TriggerServerDisconnect(AThread: TIdPeerThread); // WE MAY NOT NEED TO TRIGGER THIS EVENT
    procedure TriggerServerExecute(AThread: TIdPeerThread); // server thread handler
    procedure TriggerServerException(AThread: TIdPeerThread; AException: Exception);
  { events for clients }
    procedure TriggerClientConnected(Sender: TObject);
    procedure TriggerClientDisconnected(Sender: TObject); // MAY NOT TRIGGER (not active just now)
    procedure TriggerClientRead(ASender: TCWTcpClient);
    procedure TriggerClientWrite(ASender: TCWTcpClient);
  { global events for incoming and outgoing connections }
    procedure DoConnect(AConnection: TCWTcpConnection);
    procedure DoDisconnect(AConnection: TCWTcpConnection);
    procedure DoConnectionRun(AConnection: TCWTcpConnection); // place for to handle all internal jobs
    procedure DoMessageReceive(AConnection: TCWTcpConnection; AMsg: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Connections: TCWConnectionMaster read FConnections;
    property FileList: TCWFileMaster read FFileList;
  published
    property Server: TIdTCPServer
             read FServer
             write SetServer;

    property OnConnect: TCWTcpConnectionEvent
             read FOnConnect
             write FOnConnect;

    property OnDisconnect: TCWTcpConnectionEvent
             read FOnDisconnect
             write FOnDisconnect;

    property OnConnectionRun: TCWTcpConnectionEvent
             read FOnConnectionRun
             write FOnConnectionRun;

    property OnMessageReceive: TCWTcpMessageReceiveEvent
             read FOnMessageReceive
             write FOnMessageReceive;
  end;

  procedure Register;

implementation

uses
  Dialogs;

procedure Register;
begin
  RegisterComponents('CeoSoftWorks', [TCWP2PNode]);
end;

procedure TCWFile.AddPackHeader(AType: TCW_Pack_Type; ALength: integer; var Strm: TMemoryStream);
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

procedure TCWFile.AddFileInfoHeader(APos, ALength: integer; var Strm: TMemoryStream);
var
  FileInfoHdr: PCW_File_Info_Hdr;
begin
  New(FileInfoHdr);
  try
    with FileInfoHdr^ do
    begin
      UniqueId := Self.UniqueId;
      IndicatorPos := APos;
      DataLen := ALength;
    end;
    Strm.Write(FileInfoHdr^, SizeOf(TCW_File_Info_Hdr));
  finally
    Dispose(FileInfoHdr);
  end;
end;

procedure TCWFile.AddFileHeader(ALength: integer; var Strm: TMemoryStream);
var
  FileHdr: PCW_File_Hdr;
begin
  New(FileHdr);
  try
    FileHdr^.UniqueId := Self.UniqueId;
    FileHdr^.DataLen := ALength;
    
    Strm.Write(FileHdr^, SizeOf(TCW_File_Hdr));
  finally
    Dispose(FileHdr);
  end;
end;

{ TCWP2PNode }

constructor TCWP2PNode.Create(AOwner: TComponent);
begin
  inherited;
  FConnections := TCWConnectionMaster.Create(Self);
  FFileList := TCWFileMaster.Create(Self);
end;

destructor TCWP2PNode.Destroy;
begin
  if (FServer <> nil) and (FServer.Active) then
  begin
    FServer.Active := False;
  end;
  FreeAndNil(FConnections);
  FreeAndNil(FFileList);

  inherited Destroy;
end;

procedure TCWP2PNode.DoConnect(AConnection: TCWTcpConnection);
begin
  if Assigned(FOnConnect) then OnConnect(AConnection);
end;

procedure TCWP2PNode.DoConnectionRun(AConnection: TCWTcpConnection); { TODO : ### Outgoing or Incoming, both of them can send-receive !! ### }
begin
  { TODO : Global OnExecute }
end;

procedure TCWP2PNode.DoDisconnect(AConnection: TCWTcpConnection);
begin
  if Assigned(FOnDisconnect) then OnDisconnect(AConnection);
//  AConnection := nil;
end;

procedure TCWP2PNode.DoMessageReceive(AConnection: TCWTcpConnection;
  AMsg: string);
begin
  if Assigned(FOnMessageReceive) then OnMessageReceive(AConnection, AMsg);
end;

procedure TCWP2PNode.ReadMessagePack(var AConnection: TIdTCPConnection; AMessage: TStringStream);
var
  MsgPack: PCW_Message_Pack;
  MsgStrm: TStringStream;

  Buff: TMemoryStream;
  PData: Pointer;
begin
  Buff := TMemoryStream.Create;
  New(MsgPack);
  try
    AConnection.ReadBuffer(MsgPack^, SizeOf(TCW_Message_Pack));
    GetMem(PData, MsgPack^.DataSize);
    try
      AConnection.ReadBuffer(PData^, MsgPack^.DataSize);
      Buff.Write(PData^, MsgPack^.DataSize);
      AMessage.CopyFrom(Buff, 0);
    finally
      FreeMem(PData);
    end;
  finally
    FreeAndNil(Buff);
    Dispose(MsgPack);
  end;
end;

function TCWP2PNode.ReadPacketHdr(var AConnection: TIdTCPConnection; APackHdr: PCW_Pack_Hdr): Boolean;
begin
  Result := False;
  try
    AConnection.ReadBuffer(APackHdr^, SizeOf(TCW_Pack_Hdr));
    Result := True;
  except
    { TODO : raise specific errors here and handle in execute }
  end;
end;

procedure TCWP2PNode.SendBlobPack(AConnection: TCWTcpConnection);
begin
  if (AConnection.FBlobs.BlobCount > 0) then
  begin
    with TMemoryStream(AConnection.FBlobs.Blob[0].Link) do
    begin
      TIdPeerThread(AConnection.Data).Connection.WriteBuffer(Memory^, Size);
    end;

    AConnection.FBlobs.Delete(0);
  end;
end;

procedure TCWP2PNode.SetServer(const Value: TIdTCPServer);
begin
  FServer := Value;
  if (FServer <> nil) then
  begin
    with FServer do
    begin
      OnConnect := TriggerServerConnect;
      OnDisconnect := TriggerServerDisconnect;
      OnExecute := TriggerServerExecute;
      OnException := TriggerServerException;
    end;
  end;
end;

procedure TCWP2PNode.TriggerClientConnected(Sender: TObject);
begin
  DoConnect(TCWTcpConnection((Sender as TCWTcpClient).Data));
end;

procedure TCWP2PNode.TriggerClientDisconnected(Sender: TObject);
begin
  { DONE : Sender as TCWTcpClient.. Frees the client and remove from connection list }
//  DoDisconnect(TCWTcpConnection((Sender as TCWTcpClient).Data));
//  FConnections.Delete(TCWTcpConnection(TCWTcpClient(Sender).Data));
//  if Assigned(FOnDisconnect) then OnDisconnect(TCWTcpConnection((Sender as TCWTcpClient).Data));
  FConnections.Delete(TCWTCPClient(Sender).Socket.Binding.PeerIP);
//  TCWTcpClient(Sender).Data := nil;
//  TCWTcpClient(Sender).Free;
end;

procedure TCWP2PNode.TriggerClientRead(ASender: TCWTcpClient);
var
  PackHdr: PCW_Pack_Hdr;
  MsgPack: PCW_Message_Pack;
  FileInfHdr: PCW_File_Info_Hdr;
  FileHdr: PCW_File_Hdr;

  PData: Pointer; // data container..

  TempBuff: TMemoryStream;
  MsgStrm: TStringStream;

  AConnection: TIdTCPConnection;
  ACWConnection: TCWTcpConnection;
  AFile: TCWFile;
begin
  AConnection := TIdTCPConnection(ASender);
  ACWConnection := TCWTcpConnection(ASender.Data);
  // don't forget to clear the TempBuff everytime you use !!
  TempBuff := TMemoryStream.Create;
  New(PackHdr);
  New(MsgPack);
  New(FileHdr);
  New(FileInfHdr);
  try
    ASender.ReadBuffer(PackHdr^, SizeOf(TCW_Pack_Hdr));

    if (PackHdr^.PackType = ptMessage) then
    begin
      ASender.ReadBuffer(MsgPack^, PackHdr^.DataLen);

      GetMem(PData, MsgPack^.DataSize);
      ASender.ReadBuffer(PData^, MsgPack^.DataSize);
      TempBuff.Write(PData^, MsgPack^.DataSize);
      FreeMem(PData);

      MsgStrm := TStringStream.Create('');
      try
        MsgStrm.CopyFrom(TempBuff, 0);
        DoMessageReceive(TCWTcpConnection(ASender), MsgStrm.DataString);
      finally
        FreeAndNil(MsgStrm);
        TempBuff.Clear;
      end;
    end;

    if (PackHdr^.PackType = ptFileInfo) then
    begin
    { DONE : check the file existance, if exists, relocate the position }
      AConnection.ReadBuffer(FileInfHdr^, SizeOf(TCW_File_Info_Hdr));

      AFile := Self.FileList.FileByUID[FileInfHdr^.UniqueId];
      if (AFile = nil) then
      begin
        AFile := Self.FileList.Add(ACWConnection, 'C:\send.txt'{FileInfHdr^.Caption}, smWrite);
        AFile.FileSize := FileInfHdr^.DataLen;
        AFile.UniqueId := FileInfHdr^.UniqueId;
      end
      else begin
        AFile.Position := FileInfHdr^.IndicatorPos;
      end;
    end;

    if (PackHdr^.PackType = ptFile) then
    begin
      AConnection.ReadBuffer(FileHdr^, SizeOf(TCW_File_Hdr));

      GetMem(PData, FileHdr^.DataLen);
      try
      { DONE : act like there is only one file so it needs to modify }
        AConnection.ReadBuffer(PData^, FileHdr^.DataLen);
        AFile := Self.FileList.FileByUID[FileHdr^.UniqueId];
        if (AFile <> nil) then
        begin
          AFile.WriteSegment(PData, FileHdr^.DataLen);
        end;
      finally
        FreeMem(PData);
      end;
    end;
  finally
    TempBuff.Free;
    Dispose(PackHdr);
    Dispose(MsgPack);
    Dispose(FileHdr);
    Dispose(FileInfHdr);
  end;
//  Sleep(5);
end;


procedure TCWP2PNode.TriggerClientWrite(ASender: TCWTcpClient);
var
  ACWConnection: TCWTcpConnection;
  AConnection: TIdTCPConnection;
  AFile: TCWFile;

  PData: Pointer;
  DSize: integer;

  IsNeedToSleep: Boolean;
begin
  AConnection := TCWTcpConnection(ASender.Data).Sock;
  ACWConnection := TCWTcpConnection(ASender.Data);

  IsNeedToSleep := True;

  if (ACWConnection.FBlobs.BlobCount > 0) then
  begin
    with TMemoryStream(ACWConnection.FBlobs.Blob[0].Link) do
    begin
      ACWConnection.Sock.WriteBuffer(Memory^, Size);
      IsNeedToSleep := False;
    end;

    ACWConnection.FBlobs.Delete(0);
  end;

  if (Self.FileList.Count > 0) then
  begin
  { DONE : act like there is only one file so it needs to support GetFileInOrder }
//    AFile := Self.FileList.GetFiles(0);
    AFile := Self.FileList.GetFileInOrder(ACWConnection, 0);
    if (AFile <> nil) then
    begin
      PData := AFile.ReadSegment(DSize);
      if (DSize > 0) then
      begin
        AConnection.WriteBuffer(PData^, DSize);
        IsNeedToSleep := False;
      end;
    end;
  end;

  if (IsNeedToSleep) then
  begin
    Sleep(5);
  end;
end;

procedure TCWP2PNode.TriggerServerConnect(AThread: TIdPeerThread);
var
  NewConnection: TCWTcpConnection;
begin
{ if the previous connection from the same IP not removed properly, this add
  method may not work correctly !! }
  NewConnection := FConnections.Add(TIdTCPConnection(AThread.Connection), ctIncoming);
  { TODO : add connection info to the TCWTcpConnection }
  if (NewConnection <> nil) then
  begin
    with NewConnection do
    begin
      Data := AThread;
    end;
    AThread.Connection.ReadTimeout := 10; { TODO : !!! CHECK IT !!! }
    AThread.Data := NewConnection;
    DoConnect(NewConnection);
  end;
end;

procedure TCWP2PNode.TriggerServerDisconnect(AThread: TIdPeerThread);
begin
//  DoDisconnect(TCWTcpConnection(AThread.Data));
  FConnections.Delete(TCWTcpConnection(AThread.Data));
  AThread.Data := nil; {!}
end;

procedure TCWP2PNode.TriggerServerException(AThread: TIdPeerThread;
  AException: Exception);
begin
  //--
end;

procedure TCWP2PNode.TriggerServerExecute(AThread: TIdPeerThread);
var
  PackHdr: PCW_Pack_Hdr;
  FileInfHdr: PCW_File_Info_Hdr;
  FileHdr: PCW_File_Hdr;

  TempBuff: TMemoryStream;
  PData: Pointer;
  DSize: integer;

  AMessage: TStringStream;
  AConnection: TIdTCPConnection;
  ACWConnection: TCWTcpConnection;
  AFile: TCWFile;
begin
  AConnection := TIdTCPConnection(AThread.Connection);
  ACWConnection := TCWTcpConnection(AThread.Data);
  // don't forget to clear the TempBuff everytime you use !!
  TempBuff := TMemoryStream.Create;
  New(PackHdr);
  New(FileInfHdr);
  New(FileHdr);
  try
    try
      if (ReadPacketHdr(AConnection, PackHdr)) then
      begin

        if (PackHdr^.PackType = ptMessage) then
        begin
          AMessage := TStringStream.Create('');
          try
            ReadMessagePack(AConnection, AMessage);
            if (AMessage.DataString <> '') then
            begin
              DoMessageReceive(ACWConnection, AMessage.DataString);
            end;
          finally
            FreeAndNil(AMessage);
          end;
        end;
             
        if (PackHdr^.PackType = ptFileInfo) then
        begin
        { DONE : check the file existance, if exists, relocate the position }
          AConnection.ReadBuffer(FileInfHdr^, SizeOf(TCW_File_Info_Hdr));

          AFile := Self.FileList.FileByUID[FileInfHdr^.UniqueId];
          if (AFile = nil) then
          begin
            AFile := Self.FileList.Add(ACWConnection, FileInfHdr^.Caption, smWrite);
            AFile.FileSize := FileInfHdr^.DataLen;
            AFile.UniqueId := FileInfHdr^.UniqueId;
          end
          else begin
            AFile.Position := FileInfHdr^.IndicatorPos;
          end;
        end;

        if (PackHdr^.PackType = ptFile) then
        begin
          AConnection.ReadBuffer(FileHdr^, SizeOf(TCW_File_Hdr));

          GetMem(PData, FileHdr^.DataLen);
          try
          { DONE : act like there is only one file... }
            AConnection.ReadBuffer(PData^, FileHdr^.DataLen);
            AFile := Self.FileList.FileByUID[FileHdr^.UniqueId];
            if (AFile <> nil) then
            begin
              AFile.WriteSegment(PData, FileHdr^.DataLen);
            end;
          finally
            FreeMem(PData);
          end;
        end;

      end;
    except
      on E: Exception do
      begin
        if not (E is EIdReadTimeout) then Raise;
      end;
    end;

    if (Self.FileList.Count > 0) then
    begin
    { DONE : act like there is only one file so it needs to support GetFileInOrder }
//    AFile := Self.FileList.GetFiles(0);
      AFile := Self.FileList.GetFileInOrder(ACWConnection, 0);
      if (AFile <> nil) then
      begin
        PData := AFile.ReadSegment(DSize);
        if (DSize > 0) then
        begin
          AConnection.WriteBuffer(PData^, DSize);
        end;
      end;
    end;

    SendBlobPack(ACWConnection);
  finally
    TempBuff.Free;
    Dispose(PackHdr);
    Dispose(FileInfHdr);
    Dispose(FileHdr);
  end;
//  Sleep(5);
  //   DoConnectionRun(TCWTcpConnection(AThread.Data));
end;

{ TCWConnectionMaster }

function TCWConnectionMaster.Add(AConnection: TIdTCPConnection; AConnType: TCWTcpConnectionType): TCWTcpConnection;
var
  i: integer;
  Found: Boolean;
  NewConnection: TCWTcpConnection;
begin
  Found := False;
  for i := FConnections.Count - 1 downto 0 do
  begin
    if CompareMem(AConnection, TCWTcpConnection(FConnections.Items[i]), SizeOf(AConnection)) then
    begin
      Found := True;
      Break;
    end;
  end;
  if not Found then
  begin
    NewConnection := TCWTcpConnection.Create(Self, AConnection, ctIncoming);
    FConnections.Add(NewConnection);
  end
  else begin
    NewConnection := nil;                                  
  end;
  Result := NewConnection;
end;

function TCWConnectionMaster.Add(AHost: string; APort: integer): TCWTcpConnection;
var
  i: integer;
  NewConnection: TCWTcpConnection;
  NewClient: TCWTcpClient;
  EFailToConnect: ECWRemoteHostNotFound;
begin
  NewConnection := nil;

  if (FConnections.Count > 0) then
  begin
     for i := FConnections.Count - 1 to 0 do
     begin
      if (TCWTcpConnection(FConnections.Items[i]).Sock.Socket.Binding.PeerIP = AHost) and
         (TCWTcpConnection(FConnections.Items[i]).Sock.Socket.Binding.Port = APort) then
      begin
        NewConnection := TCWTcpConnection(FConnections.Items[i]);
        Break;
      end;
    end;
  end;

  if (NewConnection = nil) then
  begin
    NewClient := TCWTcpClient.Create(nil);
    with NewClient do
    begin
      Host := AHost;
      Port := APort;
      OnConnected := FNode.TriggerClientConnected;
      OnRead := FNode.TriggerClientRead;
      OnWrite := FNode.TriggerClientWrite;
      OnDisconnected :=  FNode.TriggerClientDisconnected;
//      OnExecute := FNode.TriggerClientExecute;
      try
        Connect(5000); { TODO : make it customizable }
      except
        on E: Exception do
        begin
          { TODO : raise could not connect exception !! }
          if (E is EIdException) then
          begin
            EFailToConnect := ECWRemoteHostNotFound.Create('');
            with EFailToConnect do
            begin
              RemHost := Host;
              RemPort := Port;
            end;
            raise EFailToConnect;
          end
          else begin
            raise;
          end;
//          MessageDlg('Could not connect to remote machine !!', mtError, [mbOK], 0);
          Exit;
        end;
      end;
    end;
    NewConnection := TCWTcpConnection.Create(Self, TIdTCPConnection(NewClient), ctOutgoing);
    NewClient.Data := NewConnection;
    FConnections.Add(NewConnection);
  end;
  
  Result := NewConnection;
end;

procedure TCWConnectionMaster.ClearConnection(AConnection: TCWTcpConnection);
var
  conntype: TCWTcpConnectionType;
begin
  try
//    AConnection.Sock.Disconnect;
    FNode.DoDisconnect(AConnection);

    conntype := AConnection.ConnectionType;

    if (AConnection.ConnectionType = ctIncoming) then
    begin
      // --
      AConnection.Data := nil; 
    end;

    if (AConnection.ConnectionType = ctOutgoing) then
    begin
      // free TCWTcpClients by using AConnection's Data property
      if (AConnection.Data <> nil) then
      begin
        TCWTcpClient(AConnection.Data).Data := nil;
        TCWTcpClient(AConnection.Data).Free;
        AConnection.Data := nil;
      end;
    end;
  finally
    AConnection.Sock := nil;
//    FreeAndNil(AConnection);
    AConnection.Free;
  end;
end;

constructor TCWConnectionMaster.Create(ANode: TCWP2PNode);
begin
  FNode := ANode;
  FConnections := TList.Create;
  FKeepAliveInterval := 15000;
  FKeepAliveSensitivity := 3;
end;

function TCWConnectionMaster.Delete(
  AConnection: TCWTcpConnection): Boolean;
var
  i: integer;
  Found: Boolean;
begin
  Found := False;
  if (FConnections.Count > 0) then
  begin
    for i := FConnections.Count - 1 downto 0 do
    begin 
      if CompareMem(AConnection, TCWTcpConnection(FConnections.Items[i]), SizeOf(AConnection)) then
      begin
        Found := True;
        ClearConnection(TCWTcpConnection(FConnections.Items[i]));
        FConnections.Delete(i);
        Break;
      end;
    end;
  end;
  
  Result := Found;
end;

function TCWConnectionMaster.Delete(AIP: string): Boolean;
var
  i: integer;
  Found: Boolean;
begin
  Found := False;
  if (FConnections.Count > 0) then
  begin
    for i := FConnections.Count - 1 to 0 do
    begin
      if (AIP = TCWTcpConnection(FConnections.Items[i]).Sock.Socket.Binding.PeerIP) then
      begin
        Found := True;
        ClearConnection(TCWTcpConnection(FConnections.Items[i]));
        FConnections.Items[i] := nil; // ?
        FConnections.Delete(i);
        Break;
      end;
    end;
  end;
  
  Result := Found;
end;

function TCWConnectionMaster.Delete(AIndex: integer): Boolean;
begin
  Result := False;
  if (AIndex <= FConnections.Count - 1) and (FConnections.Count > 0) then
  begin
    Result := True;
    ClearConnection(TCWTcpConnection(FConnections.Items[AIndex]));
    FConnections.Delete(AIndex);
  end;
end;

destructor TCWConnectionMaster.Destroy;
var
  i: integer;
begin
  if FConnections.Count > 0 then
  begin
    for i := FConnections.Count - 1 downto 0 do
    begin
     {
      ClearConnection(TCWTcpConnection(FConnections.Items[i]));
      FConnections.Delete(i);
      }
      Delete(i);
    end;
  end;
  FConnections.Free;
  inherited;
end;

procedure TCWConnectionMaster.DoKeepAliveTimer(AConnection: TCWTcpConnection);
begin
  // is it making coincidence between normal data and pings
  if (AConnection.ConnectionType = ctIncoming) then
  begin
    if not AConnection.IsAlive then
    begin
      // -- clear the connection and delete, then you may trigger for P2P node
      Delete(AConnection);
    end;
  end;

  if (AConnection.ConnectionType = ctOutgoing) then
  begin
    // -- send ping message but check if it's connected
    // syncronize the ping transfer and normal data operations
    // Should i send like AThread.Connection.WriteBuffer or AConnection.WriteBuffer ?
  end;
end;

function TCWConnectionMaster.GetConnection(i: integer): TCWTcpConnection;
var
  Conn: TCWTcpConnection;
begin
  Conn := nil;
  if (i >= 0) and (i < FConnections.Count) then
  begin
    Conn := TCWTcpConnection(FConnections.Items[i]);
  end;
  Result := Conn;
end;

function TCWConnectionMaster.GetConnectionByIP(
  ANodeIP: string): TCWTcpConnection;
var
  i: integer;
begin
  Result := nil;
  if (FConnections.Count > 0) then
  begin
    for i := FConnections.Count - 1 downto 0 do
    begin
      if (TCWTcpConnection(FConnections.Items[i]).NodeIP = ANodeIP) then
      begin
        Result := TCWTcpConnection(FConnections.Items[i]);
        Break;
      end;
    end;
  end;
end;

function TCWConnectionMaster.GetCount: integer;
begin
  Result := FConnections.Count;
end;

{ TCWTcpConnection }

constructor TCWTcpConnection.Create(AConnectionMaster: TCWConnectionMaster; ASock: TIdTCPConnection; AConnType: TCWTcpConnectionType);
begin
  FConnectionMaster := AConnectionMaster;
  FBlobs := TCWBlobs.Create(Self);
  FCUID := GetRandomString(10);

  FExistingFileId := 0;

  FConnectionType := AConnType;
  FSock := ASock;
  FNodeIP := ASock.Socket.Binding.PeerIP;

  FData := nil;
  FIsAlive := True;
  FKeepAliveMeter := 0;
  FPingAvailable := False;
    
  FTimer := TTimer.Create(nil);
  with FTimer do
  begin
    Interval := FConnectionMaster.KeepAliveInterval;
    OnTimer := DoOnTimer;
//    Enabled := True;
  end;
end;

destructor TCWTcpConnection.Destroy;
begin
  FTimer.Enabled := False;
  FreeAndNil(FTimer);
  FreeAndNil(FBlobs);

  FSock := nil;

  inherited;
end;

procedure TCWTcpConnection.DoOnTimer(Sender: TObject);
begin
  Inc(FKeepAliveMeter);
  PingAvailable := True; // set it to False after send the ping into OnExecute
  if (FKeepAliveMeter >= FConnectionMaster.KeepAliveSensitivity) then
  begin
    FIsAlive := False;
  end;
  FConnectionMaster.DoKeepAliveTimer(Self);
end;

procedure TCWTcpConnection.SendFile(AFile: string);
begin
  FConnectionMaster.FNode.FileList.Add(Self, AFile, smRead);
end;

procedure TCWTcpConnection.SendMessage(AMsg: string);
var
  MsgStrm: TMemoryStream;

  PackHdr: PCW_Pack_Hdr;
  MsgPack: PCW_Message_Pack;
begin
  New(PackHdr);
  New(MsgPack);
//  Msg := TStringStream.Create(AMsg);
  MsgStrm := TMemoryStream.Create;
  try
    with PackHdr^ do
    begin
      Integrity := 'oktay';
      PackType := ptMessage;
      DataLen := SizeOf(TCW_Message_Pack);
    end;
    MsgStrm.Write(PackHdr^, SizeOf(TCW_Pack_Hdr));

    with MsgPack^ do
    begin
      MsgTime := Now;
      DataSize := Length(AMsg)
    end;
    MsgStrm.Write(MsgPack^, SizeOf(TCW_Message_Pack));

//    MsgStrm.CopyFrom(Msg, Msg.Size);
    MsgStrm.Write(AMsg[1], Length(AMsg));
//    MsgStrm.Position := 0; // ??
    FBlobs.Add(btMessage, MsgStrm, MsgStrm.Size); { TODO : should free from the caller funct }
  finally
    Dispose(PackHdr);
    Dispose(MsgPack);
//    FreeAndNil(Msg);
  end;
end;

procedure TCWTcpConnection.SetIsAlive(const Value: Boolean);
begin
  if Value <> FIsAlive then
  begin
    FIsAlive := Value;
    if FIsAlive then
    begin
      FKeepAliveMeter := 0;
      FPingAvailable := False;
    end;
  end;
end;

constructor TCWFile.Create(AFile: string; AMode: TCWStreamMode);
begin
  Active := True;
  FFileName := AFile;
  FFileMode := AMode;
  FIsThisFirstData := True;
  Finished := False;
  FUniqueId := '';
  FTempData := TMemoryStream.Create;
  try
    case FFileMode of
      smRead:
        begin
          FData := TFileStream.Create(FFileName, fmOpenRead, fmShareDenyWrite);
          FUniqueId := TimeToStr(Now) + GetRandomString(8);
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

destructor TCWFile.Destroy;
begin
  FreeAndNil(FData);
  FreeAndNil(FTempData);
  inherited;
end;

procedure TCWFile.DoOnComplete(AFile: TCWFile);
begin
  FFinished := True;
  if Assigned(FOnCompleted) then OnCompleted(Self);
end;

procedure TCWFile.FlushToDrive;
begin
  FlushFileBuffers(FData.Handle);
end;

function TCWFile.GetFileHandle: HWND;
begin
  Result := FData.Handle;
end;

function TCWFile.GetFileSize: integer;
begin
  if (FFileMode = smRead) then
  begin
    Result := FData.Size;
  end
  else begin
    Result := FFileSize;
  end;
end;

function TCWFile.GetPosition: integer;
begin
  Result := FData.Position;
end;

function TCWFile.ReadSegment(var DataSize: integer): Pointer;
var // do we need to set the position to 0 ??
  Tag: integer;
//  DataLength: integer;

//  PTemp: Pointer;
begin
  FTempData.Clear; // should it be free in here or from the place we use ??
  DataSize := 0;
  Result := FTempData.Memory;
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

procedure TCWFile.SetFileSize(const Value: integer);
begin
  if (FFileMode = smWrite) then
  begin
    FFileSize := Value;
  end;
end;

procedure TCWFile.SetPosition(const Value: integer);
begin
  if Value <> FData.Position then
  begin
    FData.Position := Value;
  end;
end;

procedure TCWFile.WriteSegment(ASegment: Pointer; ADataLen: integer);
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

function TCWFileMaster.Add(AConnection: TCWTcpConnection; AFile: string; AMode: TCWStreamMode): TCWFile;
var
  Found: Boolean;
  i: integer;
  NewFile: TCWFile;
begin                 { TODO : Raise Exception when the file operations fails }
  Found := False;
  if (FFiles.Count > 0) then
  begin
    for i := FFiles.Count - 1 downto 0 do { TODO : test it !! }
    begin
      if (AFile = TCWFile(FFiles.Items[i]).FileName) and
         (AMode = TCWFile(FFiles.Items[i]).FileMode) then
      begin
        Found := True;
        Break;
      end;
    end;
  end;

  if not Found then
  begin
    Inc(FUIDCounter);
    NewFile := TCWFile.Create(AFile, AMode);
    with NewFile do
    begin
      Link := AConnection;
//      OnCompleted := DoFileComplete;
    end;
    FFiles.Add(NewFile);
  end
  else begin
    NewFile := nil;
  end;

  Result := NewFile;
end;

constructor TCWFileMaster.Create(ANode: TCWP2PNode);
begin
  FFiles := TList.Create;
  FNode := ANode;
  FUIDCounter := 0;
end;

function TCWFileMaster.Delete(AConnection: TCWTcpConnection): Boolean;
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
        { TODO : check this delete operation.. }
        TCWFile(FFiles.Items[i]).Free;
        FFiles.Delete(i);
//        Break;
      end;
    end;
  end;
  Result := Found;
end;

function TCWFileMaster.Delete(AFile: TCWFile): Boolean;
var
  Found: Boolean;
  i: integer;
begin
  Found := False;
  if (FFiles.Count > 0) then
  begin
    for i := FFiles.Count - 1 downto 0 do
    begin
      if (CompareMem(AFile, TCWFile(FFiles.Items[i]), SizeOf(AFile))) then
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

function TCWFileMaster.Delete(AUID: string): Boolean;
begin
  { TODO : complete this proc }
end;

destructor TCWFileMaster.Destroy;
begin
  FFiles.Free;
  { TODO : file items should be free here !! }
  inherited;
end;

procedure TCWFileMaster.DoFileComplete(AFile: TCWFile);
begin
  AFile.Free;
end;

function TCWFileMaster.GetCount: integer;
begin
  Result := FFiles.Count;
end;

function TCWFileMaster.GetFileByUID(AUID: string): TCWFile;
var
  i: integer;
begin
  Result := nil;
  if (FFiles.Count > 0) then
  begin
    for i := FFiles.Count - 1 downto 0 do
    begin
      if (TCWFile(FFiles.Items[i]).UniqueId = AUID) then
      begin
        Result := TCWFile(FFiles.Items[i]);
        Break;
      end;
    end;
  end;
end;

function TCWFileMaster.GetFileInOrder(AConnection: TCWTcpConnection; ATag: integer): TCWFile;
var
  i: integer;
  { TODO : test this function !! }
begin
  Result := nil;
  for i := FFiles.Count - 1 downto 0 do
  begin
    if (TCWFile(FFiles.Items[i]) <> nil) then
    begin
      if (CompareMem(AConnection, TCWTcpConnection(TCWFile(FFiles.Items[i]).Link), SizeOf(AConnection))) and
         (ATag > TCWFile(FFiles.Items[i]).Tag) and
         (TCWFile(FFiles.Items[i]).Active) then
      begin
        Result := TCWFile(FFiles.Items[i]);
        Break;
      end;
    end;
  end;

  if (Result = nil) then
  begin
    for i := FFiles.Count - 1 downto 0 do
    begin
      if (CompareMem(AConnection, TCWTcpConnection(TCWFile(FFiles.Items[i]).Link), SizeOf(AConnection))) and
         (TCWFile(FFiles.Items[i]).Active) then
      begin
        Result := TCWFile(FFiles.Items[i]);
        Break;
      end;
    end;
  end;
end;

function TCWFileMaster.GetFiles(i: integer): TCWFile;
begin
  Result := nil;
  if (i >= 0) and (i < FFiles.Count) then
  begin
    Result := TCWFile(FFiles.Items[i]);
  end;
end;

{ TCWBlobs }

function TCWBlobs.Add(ABlobType: TCW_Blob_Type; AData: Pointer;
  ADataSize: integer): TCWBlobItem;
var
  Blob: TCWBlobItem;
begin
  Blob := TCWBlobItem.Create;

  with Blob do
  begin
    BlobType := ABlobType;
    Link :=  AData;
    DataSize := ADataSize;
  end;

  FBlobs.Add(Blob);
end;

constructor TCWBlobs.Create(AConnection: TCWTcpConnection);
begin
  FConnection := AConnection;
  FBlobs := TList.Create;
end;

procedure TCWBlobs.Delete(i: integer);
begin
  if (FBlobs.Items[i] <> nil) then
  begin
    TMemoryStream(TCWBlobItem(FBlobs.Items[i]).Link).Free; { TODO : check it }
    TCWBlobItem(FBlobs.Items[i]).Free;
    FBlobs.Delete(i);
  end;
end;

destructor TCWBlobs.Destroy;
begin
  FreeAndNil(FBlobs);
  inherited;
end;

function TCWBlobs.GetBlob(i: integer): TCWBlobItem;
begin
  Result := TCWBlobItem(FBlobs.Items[i]);
end;

function TCWBlobs.GetBlobCount: integer;
begin
  Result := FBlobs.Count;
end;

end.

