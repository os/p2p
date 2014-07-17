
{ ----------------------------------------------------------------------------
                                  CW TCP CONNECTION
  ----------------------------------------------------------------------------

    :Description
       TCWTcpConnection:

    :History

    :Features

    :ToDo
       [+] Associate timer and IsAlive
       [+] Add AConnectionMaster in OnCreate
       [+] Ping mechanism
       [+] Extended peer info. Includes CW Protocol related infos..

  ----------------------------------------------------------------------------
  [#] Improvements   [-] Feature Removed
  [!] Bug/BugFix     [+] Feature Added
  ---------------------------------------------------------------------------- }

unit CWTcpConnection;

interface

uses
  SysUtils, Classes, IdTCPConnection, CWTcpClient, CWTcpProtocol, ExtCtrls;

type
  TCWTcpConnectionType = (ctIncoming, ctOutgoing);

  TCWTcpConnection = class(TObject)
  private
    FConnectionMaster: TCWConnectionMaster;
    FSock: TIdTCPConnection;
    FTimer: TTimer;
    FData: Pointer;
    FConnectionType: TCWTcpConnectionType;
    FIsAlive: Boolean;
    FKeepAliveMeter: integer;
    procedure DoOnTimer(Sender: TObject);
    procedure SetIsAlive(const Value: Boolean);
  public
    constructor Create(ASock: TIdTCPConnection; AConnType: TCWTcpConnectionType);
    destructor Destroy; override;

    property ConnectionType: TCWTcpConnectionType read FConnectionType;
    property Sock: TIdTCPConnection read FSock;
    property Data: Pointer read FData write FData;
    property IsAlive: Boolean read FIsAlive write SetIsAlive;
  end;

implementation

uses
  CWP2PNode;  

{ TCWTcpConnection }

constructor TCWTcpConnection.Create(ASock: TIdTCPConnection; AConnType: TCWTcpConnectionType);
begin
  FConnectionType := AConnType;
  FSock := ASock;

  FData := nil;
  FIsAlive := True;
  FKeepAliveMeter := 0;
    
  FTimer := TTimer.Create(nil);
  with FTimer do
  begin
//    Interval := FConnectionMaster.PingInterval
    OnTimer := DoOnTimer;
  end;
end;

destructor TCWTcpConnection.Destroy;
begin

  inherited;
end;

procedure TCWTcpConnection.DoOnTimer(Sender: TObject);
begin
  Inc(FKeepAliveMeter);
  if (FKeepAliveMeter >= FConnectionMaster.KeepAliveSensitivity) then
  begin
    FIsKeepAlive := False;
  end;
  // trigger ConnectionMaster's DoPingTimer
end;

procedure TCWTcpConnection.SetIsAlive(const Value: Boolean);
begin
  if Value <> FIsAlive then
  begin
    FIsAlive := Value;
    if FIsAlive then
    begin
      FKeepAliveMeter := 0;
    end;
  end;
end;

end.
