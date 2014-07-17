
{ ============================================================================
                                  CW TCP PROTOCOL
  ============================================================================

    :Description
       CW TCP Protocol Specifications..

    :History
       18.07.2004 03:30 [+] TCW_Ping_Pack template added

    :ToDo

    :Design
       + TCW_Ping_Pack
         - PID
         - Time (for to learn the network speed..)

  ============================================================================ }

unit CWTcpProtocol;

interface

uses
  SysUtils, Messages;

type
{ ---| Messages |------------------------------------------------------------- }
  PCW_Message_Pack = ^TCW_Message_Pack;
  TCW_Message_Pack = record
    MsgTime: TDateTime; 
    DataSize: integer;
  end;
{ ---------------------------------------------------------------------------- }

{ ---| Commands |------------------------------------------------------------- }
  TCW_Command_Type = (ctInternal, ctExternal);

  TCW_Command = (cmdDisconnect, cmdStop, cmdStart, cmdFileRequest);

  PCW_Comm_Pack = ^TCW_Comm_Pack;
  TCW_Comm_Pack = record
    CommandType: TCW_Command_Type;
    Command: TCW_Command;
    Params: string[255];
//    SecurityKey: string[20];
  end;
{ ---------------------------------------------------------------------------- }

{ ---| Headers |-------------------------------------------------------------- }
  TCW_Pack_Type = (ptUndefined, ptFile, ptFileInfo, ptCommand, ptMessage, ptPing);

  PCW_Pack_Hdr = ^TCW_Pack_Hdr;
  TCW_Pack_Hdr = record
//    CWProtoVersion: string[5]; // 1.2
    Integrity: string[5]; // check if it's oktay
    PackType: TCW_Pack_Type;
    DataLen: integer;
  end;

  TCW_Unique_Id = TDateTime;

  PCW_File_Info_Hdr = ^TCW_File_Info_Hdr;
  TCW_File_Info_Hdr = record
    UniqueId: string[16];
    Caption: string[255];
    IndicatorPos: integer; // 0, start from the beginning, if not, from indic.
    DataLen: integer;
  end;

  PCW_File_Hdr = ^TCW_File_Hdr;
  TCW_File_Hdr = record
    // FileID
    UniqueId: string[16];
    DataLen: integer;
  end;

  PCW_Ping_Pack = ^TCW_Ping_Pack;
  TCW_Ping_Pack = record
    PingTime: TDateTime;
  end;
{ ---------------------------------------------------------------------------- }

{ ---| CW XML Protocol | -----------------------------------------------------
  <?xml version="1.0" encoding="UTF-8" ?>
  <ceosoftworks version = "1.01">
  
    <messages>
        <offlinemsgs>
            <offlinemsg>
                <from>Oktay</from>
                <time>23.10.2004</time>
                <msgbody>When you come back call me please !!</msgbody>
            </offlinemsg>
            <offlinemsg>
                <from>Can</from>
                <time>13.10.2004</time>
                <msgbody>Did you read my email ?</msgbody>
            </offlinemsg>
        </offlinemsgs>
        <onlinemsgs>
            <onlinemsg>
                <from>Can</from>
                <time>13.10.2004</time>
                <msgbody>Hey are you there ?</msgbody>
            </onlinemsg>
        </onlinemsgs>
    </messages>

    <files>
        <incomingfile>
            <name>school.bmp</name>
            <size>34523</size>
        </incomingfile>
        <outgoingfile>
            <name>c:\delphi32.exe</name>
        </outgoingfile>
    </files>

  </ceosoftworks>
 ----------------------------------------------------------------------------- }
implementation

end.
