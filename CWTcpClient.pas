
{ ----------------------------------------------------------------------------
                                  CW TCP CLIENT
  ----------------------------------------------------------------------------

    :Description
       TCWTcpClient: threaded client, multiple file transfer

    :History
       24.06.2004 20:57  Project Started.. 

    :ToDo

  ---------------------------------------------------------------------------- }

unit CWTcpClient;

interface

uses
  SysUtils, Classes, IdTCPClient, IdTCPConnection, Dialogs;

type
  TCWConnectionEvent = procedure(AConnection: TIdTCPConnection) of object;

  TCWTcpClient = class;

  TCWTcpListener = class(TThread)
  private
    FClient: TCWTcpClient;
    FSock: TIdTCPClient;
    function GetActive: Boolean;
    procedure SetActive(const Value: Boolean);
    procedure DoOnConnected(Sender: TObject);
    procedure DoOnDisconnected(Sender: TObject);
    procedure TriggerExecute;
  protected
    procedure Execute; override;
  public
    constructor Create(AClient: TCWTcpClient; HostAddr: string; HostPort: integer);
    destructor Destroy; override;
    property Sock: TIdTCPClient read FSock;
    property Active: Boolean read GetActive write SetActive;
  end;

  TCWTcpClient = class(TComponent)
  private
    FThread: TCWTcpListener;
    FHostPort: integer;
    FHostIP: string;
    FOnConnect: TCWConnectionEvent;
    FOnDisconnect: TCWConnectionEvent;
    function GetActive: Boolean;
    procedure SetActive(const Value: Boolean);
    procedure DoConnect(AConnection: TIdTCPConnection);
    procedure DoDisconnect(AConnection: TIdTCPConnection);
    procedure HandleConnection(AConnection: TIdTCPConnection);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Active: Boolean read GetActive write SetActive;
    property HostIP: string read FHostIP write FHostIP;
    property HostPort: integer read FHostPort write FHostPort;
    property OnConnect: TCWConnectionEvent read FOnConnect write FOnConnect;
    property OnDisconnect: TCWConnectionEvent read FOnDisconnect write FOnDisconnect;
  end;

  procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CeoSoftWorks', [TCWTcpClient]);
end;

{ TCWTcpClient }

constructor TCWTcpClient.Create(AOwner: TComponent);
begin
  inherited;
  FHostIP := '';
  FHostPort := 0;

  FThread := nil;
end;

destructor TCWTcpClient.Destroy;
begin
  if not (FThread = nil) then
  begin
    if FThread.Active then
    begin
      FThread.Active := False;
    end;
    FThread.Terminate;
  end;
  inherited;
end;

procedure TCWTcpClient.DoConnect(AConnection: TIdTCPConnection);
begin
  if Assigned(FOnConnect) then OnConnect(AConnection);
end;

procedure TCWTcpClient.DoDisconnect(AConnection: TIdTCPConnection);
begin
  if Assigned(FOnDisconnect) then OnDisconnect(AConnection);
end;

function TCWTcpClient.GetActive: Boolean;
var
  Status: Boolean;
begin
  if (FThread = nil) then
  begin
    Status := False;
  end
  else begin
    Status := FThread.Active;
  end;
  Result := Status;
end;

procedure TCWTcpClient.HandleConnection(AConnection: TIdTCPConnection);
begin
  // --
end;

procedure TCWTcpClient.SetActive(const Value: Boolean);
begin
  if (Value <> Active) then
  begin
    if (Value = True) then
    begin
      if (FThread = nil) then
      begin
        FThread := TCWTcpListener.Create(Self, FHostIP, FHostPort);
        FThread.Active := True;
      end
      else begin
        FThread.Active := True;
      end;
    end
    else begin
      if (FThread <> nil) then
      begin
        FThread.Active := False;
      end;
    end;
  end;
end;

{ TCWTcpListener }

constructor TCWTcpListener.Create(AClient: TCWTcpClient; HostAddr: string;
  HostPort: integer);
begin
  FreeOnTerminate := True;
  FClient := AClient;

  FSock := TIdTCPClient.Create(nil);
  with FSock do
  begin
    Host := HostAddr;
    Port := HostPort;
    OnConnected := DoOnConnected;
    OnDisconnected := DoOnDisconnected;
  end;

  inherited Create(True);
end;

destructor TCWTcpListener.Destroy;
begin
  if FSock.Connected then
  begin
    FSock.Disconnect;
  end;
  FSock.Free;
  inherited;
end;

procedure TCWTcpListener.DoOnConnected(Sender: TObject);
begin
  FClient.DoConnect(TIdTCPConnection(FSock));
end;

procedure TCWTcpListener.DoOnDisconnected(Sender: TObject);
begin
  FClient.DoDisconnect(TIdTCPConnection(FSock));
end;

procedure TCWTcpListener.Execute;
begin
  inherited;
  while not Terminated do
  begin
    Synchronize(TriggerExecute);
//    FClient.HandleConnection(TIdTCPConnection(FSock));
  end;
end;

function TCWTcpListener.GetActive: Boolean;
begin
  Result := not Suspended;
end;

procedure TCWTcpListener.SetActive(const Value: Boolean);
begin
  if Value <> Active then
  begin
    if (Value = True) then
    begin
      try
        FSock.Connect(3000);
      except
        on E: Exception do
          MessageDlg(E.Message, mtError, [mbOK], 0);
          // may be trigger on client too
      end;
      Resume;
    end
    else begin
      Suspend; // !! BUGGY !!
      FSock.Disconnect; 
    end;
  end;
end;

procedure TCWTcpListener.TriggerExecute;
begin
  FClient.HandleConnection(TIdTCPConnection(FSock));
end;

end.
