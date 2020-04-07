program CodeNationChallenge;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, REST.Client, REST.Types, System.JSON, System.Hash;

type
  TJSONRequestRec = record
    numero_casas: Integer;
    token, cifrado, decifrado, resumo_criptografico: String;
  end;

var
  RESTClient: TRESTClient;
  RESTRequest: TRESTRequest;
  RESTResponse: TRESTResponse;
  Input: String;
  JSONValue : TJSonValue;
  JSONRequestRec: TJSONRequestRec;

const
  C_URL = 'https://api.codenation.dev';
  C_RESOURCE = 'v1/challenge/dev-ps/generate-data';
  C_MY_TOKEN = 'e896178d5e18062430bb5522f916c28d3ab5418e';
  C_LINE = '==================================================';

procedure Line;
begin
  Writeln;
  Writeln(C_LINE);
  Writeln;
end;

function GetJSON: string;
begin
  RESTClient:= TRESTClient.Create(C_URL);
  RESTRequest:= TRESTRequest.Create(nil);
  RESTResponse:= TRESTResponse.Create(nil);
  try
    try
      RESTRequest.Client:= RESTClient;
      RESTRequest.Response:= RESTResponse;
      RESTRequest.Resource:= C_RESOURCE;
      RESTRequest.AddParameter('token', C_MY_TOKEN);
      RESTRequest.Method:= rmGET;
      RESTRequest.Execute;

      if RESTResponse.StatusCode = 200 then
        JSONValue := TJSonObject.ParseJSONValue(RESTResponse.Content);

      Writeln('O JSON original é: ');
      Writeln(JSONValue.ToJSON);
      Line;

      JSONRequestRec.numero_casas        := JsonValue.GetValue<Integer>('numero_casas');
      JSONRequestRec.token               := JsonValue.GetValue<string>('token');
      JSONRequestRec.cifrado             := JsonValue.GetValue<string>('cifrado');
      JSONRequestRec.decifrado           := JsonValue.GetValue<string>('decifrado');
      JSONRequestRec.resumo_criptografico:= JsonValue.GetValue<string>('resumo_criptografico');


    finally
      RESTResponse.Free;
      RESTRequest.Free;
      RESTResponse.Free;
    end;
  except
    on E: Exception do
     Writeln('Ocorreu um erro ao receber o JSON!');
  end;
end;

function Decode(ACipher: string; ANumPlace: Integer): string;
var
  QtChars: Integer;
  I: Integer;
  NumChar: Byte;
begin
  QtChars:= ACipher.Length;

  for I := 1 to QtChars do
  begin
    NumChar:= Ord(ACipher[I]);
    if not (NumChar in [46, 0..9]) then
    begin
      if NumChar = 32 then
        Result:= Result + Chr(NumChar)
      else
        Result:= Result + Chr(NumChar - ANumPlace);
    end;
  end;

  Result:= Result.ToLower;
end;

function SetFieldValues:Boolean;
var
  StringDecoded, SHA1: String;
begin
  Result:= False;

  if not JSONRequestRec.cifrado.IsEmpty then
  begin
    //StringDecoded:= Decode('uif cftu xbz up nblf zpvs esfbnt dpnf usvf jt up xblf vq. nvsjfm tjfcfsu', 1);
    StringDecoded:= Decode(JSONRequestRec.cifrado, JSONRequestRec.numero_casas);
    SHA1:= THashSHA1.GetHashString(StringDecoded);

    Writeln('String decodificada: ' + StringDecoded);
    Writeln('Resumo criptográfico - SHA1: ' + SHA1);

    JSONRequestRec.decifrado           := StringDecoded;
    JSONRequestRec.resumo_criptografico:= SHA1;
    Result:= True;
  end
  else
    Writeln('Não há mensagem para decifrar! Obtenha o JSON antes! Opção (1)');

   Line;
end;

procedure PostJSON;
begin

end;

begin
  try
    repeat
      Writeln('Digite a opção desejada: ');
      Writeln('1 - Obter o JSON');
      Writeln('2 - Enviar o JSON com as alterações');
      Writeln('3 - Sair');
      Write('Opção: ');
      Readln(Input);
      Line;

      if Input = '1' then
        GetJSON
      else
      if Input = '2' then
        PostJSON;

    until Input = '3';

    if Assigned(JSONValue) then
      JSONValue.Free;

  finally

  end;
end.
