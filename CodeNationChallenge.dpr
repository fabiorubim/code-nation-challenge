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
  C_GET_URL = 'https://api.codenation.dev';
  C_GET_RESOURCE = 'v1/challenge/dev-ps/generate-data';

  C_POST_URL = 'https://api.codenation.dev';
  C_POST_RESOURCE = 'v1/challenge/dev-ps/submit-solution';
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
  RESTClient:= TRESTClient.Create(C_GET_URL);
  RESTRequest:= TRESTRequest.Create(nil);
  RESTResponse:= TRESTResponse.Create(nil);
  try
    try
      RESTRequest.Client:= RESTClient;
      RESTRequest.Response:= RESTResponse;
      RESTRequest.Resource:= C_GET_RESOURCE;
      RESTRequest.AddParameter('token', C_MY_TOKEN);
      RESTRequest.Method:= rmGET;
      RESTRequest.Execute;

      if RESTResponse.StatusCode = 200 then
      begin
        JSONValue := TJSonObject.ParseJSONValue(RESTResponse.Content);

        Writeln('O JSON original é: ');
        Writeln(JSONValue.ToJSON);
        Line;

        JSONRequestRec.numero_casas        := JsonValue.GetValue<Integer>('numero_casas');
        JSONRequestRec.token               := JsonValue.GetValue<string>('token');
        JSONRequestRec.cifrado             := JsonValue.GetValue<string>('cifrado');
        JSONRequestRec.decifrado           := JsonValue.GetValue<string>('decifrado');
        JSONRequestRec.resumo_criptografico:= JsonValue.GetValue<string>('resumo_criptografico');
      end;
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
    if NumChar in [32, 46, 0..9] then
      Result:= Result + Chr(NumChar)
    else
      Result:= Result + Chr(NumChar - ANumPlace);
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

function GenerateJSONtoPost(var AJSONPost: string): Boolean;
var
  JSONObject: TJSONObject;
begin
  Result:= False;
  JSONObject:= TJSONObject.Create;
  try
    if SetFieldValues then
    begin
      JSONObject.AddPair(TJSONPair.Create('numero_casas', JSONRequestRec.numero_casas.ToString));
      JSONObject.AddPair(TJSONPair.Create('token', JSONRequestRec.token));
      JSONObject.AddPair(TJSONPair.Create('cifrado', JSONRequestRec.cifrado));
      JSONObject.AddPair(TJSONPair.Create('decifrado', JSONRequestRec.decifrado));
      JSONObject.AddPair(TJSONPair.Create('resumo_criptografico', JSONRequestRec.resumo_criptografico));
      AJSONPost:= JSONObject.ToJSON;
      Result:= True;
    end;
  finally
    JSONObject.Free;
  end;
end;

procedure PostJSON;
var
  JSONtoPost: string;
begin
  if GenerateJSONtoPost(JSONtoPost) then
  begin
    RESTClient:= TRESTClient.Create(C_POST_URL);
    RESTRequest:= TRESTRequest.Create(nil);
    RESTResponse:= TRESTResponse.Create(nil);
    try
      try
        RESTRequest.Client:= RESTClient;
        RESTRequest.Response:= RESTResponse;
        RESTRequest.Resource:= C_POST_RESOURCE;
        RESTRequest.AddParameter('token', C_MY_TOKEN);
        RESTRequest.AddBody(JSONtoPost, TRESTContentType.ctMULTIPART_FORM_DATA);
        RESTRequest.Method:= rmPOST;
        RESTRequest.Execute;

        if RESTResponse.StatusCode = 200 then
        begin
          JSONValue := TJSonObject.ParseJSONValue(RESTResponse.Content);

          Writeln('Status da submissão: ');
          Writeln(JSONValue.ToJSON);
          Line;
        end;
      finally
        RESTResponse.Free;
        RESTRequest.Free;
        RESTResponse.Free;
      end;
    except
      on E: Exception do
       Writeln('Ocorreu um erro ao submeter o JSON!');
    end;
  end;
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
