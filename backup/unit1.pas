unit Unit1;

{$mode delphi}{$H+}

interface

uses
  Windows, Math, MMSystem, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
	ComCtrls, ActnList, fgl;

type

  { TForm1 }

  TForm1 = class(TForm)
		ButtonMove: TButton;
    ButtonStart: TButton;
    ButtonPause: TButton;
    Image1: TImage;
		Image2: TImage;
		LabelScore: TLabel;
		LabelLastScore: TLabel;
		TimerUpdate: TTimer;
		TimerCreate: TTimer;
    TimerRender: TTimer;
    procedure ButtonStartClick(Sender: TObject);
    procedure ButtonPauseClick(Sender: TObject);
		procedure ButtonMoveKeyPress(Sender: TObject; var Key: char);
    procedure FormCreate(Sender: TObject);
    procedure ClearCanvas();
		procedure LabelScoreClick(Sender: TObject);
		procedure TimerCreateTimer(Sender: TObject);
    procedure TimerRenderTimer(Sender: TObject);
		procedure TimerUpdateTimer(Sender: TObject);
  private

  public

  end;

  Shape = class
    pos: integer;         // posisi bagian terkiri objek
    dx, dy, dz: integer;  // perpindahan objek dari titik 0, 0, 0
    Xspeed: integer;      // Kecepatan gerak objek pada sumbu x
    tebal: integer;       // tebal objek pada sumbu x
    constructor Create(); virtual;
    procedure Draw(); virtual;
    procedure Update(); virtual;
	end;

  Jalur = class(Shape)
    procedure Draw(); override;
    procedure Update(); override;
	end;

  Kotak = class(Shape)
    noJalur: Integer;
    constructor Create(nJalur: Integer);
    procedure Draw(); override;
    procedure Update(); override;
	end;

  Manusia = class(Shape)
    noJalur: Integer;
    constructor Create(nJalur: integer);
    procedure Draw(); override;
    procedure Update(); override;
	end;

  Kartesius = class(Shape)
    procedure Draw(); override;
    procedure Update(); override;
	end;

  InsideContainer = TFPGObjectList<Shape>;

const
  M = 2000;   // Jarak antara user dan layar

var
  Form1: TForm1;
  Lane: TFPGObjectList<TFPGObjectList<Shape>>;
  posXManusia: integer;  // posisi terkiri manusia pada sumbu x
  posYManusia: integer;  // posisi manusia ada di jalur berapa
  tebalManusia: integer; // tebal objek manusia pada sumbu x
  YOffset: integer = -300;
  Score: integer = 0;
  isPaused: boolean = false;
  StyleManusia: integer;

implementation

{$R *.lfm}

// Konversi koordinat kartesius ke koordinat layar
function CoorX(x: Integer): Integer;
begin
  Exit(Form1.Image1.Width div 2 + x);
end;

function CoorY(y: Integer): Integer;
begin
  Exit(-175 - y);
end;

// Proyeksi 3d ke 2d
function ZtoX(X: Integer; Z: Integer) : Integer;
begin
  if Z = M then
    Exit( Round(X / (1 - Z/(M+1))) )
  else
    Exit( Round(X / (1 - Z/M)) );
end;

function ZtoY(Y: Integer; Z: Integer) : Integer;
begin
  if Z = M then
    Exit( Round(Y / (1 - Z/(M+1))))
  else
    Exit( Round(Y / (1 - Z/M)) );
end;

// Menjalankan semua timer
procedure Start();
begin
  with Form1 do
  begin
    TimerRender.Enabled := true;
	  TimerUpdate.Enabled := true;
	  TimerCreate.Enabled := true;
	end;
end;

// Menghentikan semua timer
procedure Stop();
begin
  with Form1 do
  begin
    TimerRender.Enabled := false;
	  TimerUpdate.Enabled := false;
	  TimerCreate.Enabled := false;
	end;
end;

// prosedur ini digunakan untuk mereset jika pemain kalah
procedure Reset();
var
  i, j: integer;
begin
  with Form1 do
  begin
    // Reset score
	  LabelLastScore.Caption := 'Last Score : ' + IntToStr(Score);
	  Score := 0;
	  LabelScore.Caption := 'Score : 0';

	  // Bersihkan semua obstacle
	  for i := Lane.Count-1 downto 0 do
	  begin
	    for j:= Lane[i].Count-1 downto 0 do
	    begin
	      Lane[i].Delete(j);
	    end;
		end;

	  // Aktifkan button start
	  ButtonStart.Enabled := true;

    // Nonaktifkan button pause
    ButtonPause.Enabled := false;
	end;
end;

{ TForm1 }
procedure TForm1.ButtonStartClick(Sender: TObject);
begin
  PlaySound(nil, 0, SND_ASYNC);   // stop musik latar belakang
  ButtonMove.SetFocus;
  ButtonPause.Enabled := True;
  ButtonStart.Enabled := false;
  Start();      // nyalakan semua timer
end;

procedure TForm1.ButtonPauseClick(Sender: TObject);
begin
  if isPaused then
  begin
    ButtonMove.SetFocus;
	  Start();
    ButtonPause.Caption := 'Pause';
    isPaused := false;
    PlaySound(nil, 0, SND_ASYNC);
	end else
  begin
    Stop();
    ButtonPause.Caption := 'Resume';
    isPaused := true;
    if FileExists('background music.wav') then
      PlaySound(pchar('background music.wav'), 0, SND_ASYNC OR SND_LOOP);
	end;
end;

procedure TForm1.ButtonMoveKeyPress(Sender: TObject; var Key: char);
begin
  if LowerCase(Key) = 's' then
  begin
	  if posYManusia <> 3 then
    begin
	    posYManusia := posYManusia + 1;
      if FileExists('move sound.wav') then
        PlaySound(pchar('move sound.wav'), 0, SND_ASYNC);
		end;
	end else if LowerCase(Key) = 'w' then
  begin
    if posYManusia <> 0 then
    begin
      posYManusia := posYManusia - 1;
      if FileExists('move sound.wav') then
        PlaySound(pchar('move sound.wav'), 0, SND_ASYNC);
		end;
	end;

end;

procedure TForm1.TimerRenderTimer(Sender: TObject);
var
  i, j: integer;
  jal: Jalur;
  man: Manusia;
begin
  ClearCanvas();
  jal := Jalur.Create();
  man := Manusia.Create(posYManusia);

  man.Draw();
  jal.Draw();

  for i:=0 to Lane.Count-1 do
  begin
    if i = posYManusia then man.Draw();
    for j:=Lane[i].Count-1 downto 0 do
    begin
      if Lane[i][j].pos + Lane[i][j].tebal < posXManusia then
      begin
        Lane[i][j].Draw();
        if i = posYManusia then man.Draw();
			end else
			  Lane[i][j].Draw();
    end;
	end;

  jal.Free();
  man.Free();
end;

procedure TForm1.TimerUpdateTimer(Sender: TObject);
var
  i, j: integer;
  SpeedMultiplier: integer;
begin
  // Update posisi
  for i := Lane.Count-1 downto 0 do
  begin
    for j:= Lane[i].Count-1 downto 0 do
    begin
      Lane[i][j].Update();
    end;
	end;

  // Delete yang sudah di luar layar
  for i := Lane.Count-1 downto 0 do
  begin
    for j:= Lane[i].Count-1 downto 0 do
    begin
      if Lane[i][j].pos < -Form1.Image1.Width div 2 - 25 then
        Lane[i].Delete(j);
    end;
	end;

  // Check jika ada collision antara manusia dan obstacle
  if Lane[posYManusia].Count > 0 then  // check hanya jika obstacle sudah dibuat
  for i:=0 to Lane[posYManusia].Count-1 do
  begin
    if NOT((posXManusia + tebalManusia < Lane[posYManusia][i].pos) OR
      (posXManusia > Lane[posYManusia][i].pos + Lane[posYManusia][i].tebal)) then
    begin
      Stop();                   // Stop semua timer
      TimerRenderTimer(nil);    // Render dulu sekali supaya tidak ada jarak saat tabrakan
      Reset();  // Reset game
      ButtonStart.SetFocus;
      if FileExists('lose sound.wav') then    // Jalankan music kalah
        PlaySound(pchar('lose sound.wav'), 0, SND_ASYNC);
      Sleep(1000);    // Tunggu sampai musik kalah selesai diputar
      if FileExists('background music.wav') then    // Jalankan musik background
        PlaySound(pchar('background music.wav'), 0, SND_ASYNC OR SND_LOOP);
      Exit();   // Keluar dari prosedur ini
    end;
	end;

  // update score
  Score := Score + 1;
  LabelScore.Caption := 'Score : ' + IntToStr(Score);

  // update kecepatan dan interval generate rintangan berdasarkan score
  SpeedMultiplier := Ceil(Score / 1000) + 5;
  TimerCreate.Interval := 3000 - 200 * SpeedMultiplier;
  for i := Lane.Count-1 downto 0 do
  begin
    for j:= Lane[i].Count-1 downto 0 do
    begin
      Lane[i][j].XSpeed := -1 * SpeedMultiplier;
    end;
	end;

  // Update style manusia
  if Score mod 30 = 0 then
    StyleManusia := (StyleManusia + 1) mod 2;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  if FileExists('background music.wav') then
    PlaySound(pchar('background music.wav'), 0, SND_ASYNC OR SND_LOOP);

  Image2.Picture.LoadFromFile('background.jpg');

  // Siapkan container 2D untuk menampung objek rintangan
  Lane := TFPGObjectList< InsideContainer >.Create();
  Lane.Add(TFPGObjectList<Shape>.Create);
  Lane.Add(TFPGObjectList<Shape>.Create);
  Lane.Add(TFPGObjectList<Shape>.Create);
  Lane.Add(TFPGObjectList<Shape>.Create);

  posXManusia := -Form1.Image1.Width div 2 + 200;
  posYManusia := 0;
  tebalManusia := 220 div 2;
  StyleManusia := 0;

  Score := 0;

  Randomize;
end;

procedure TForm1.ClearCanvas();
begin
  Image1.Canvas.Pen.Style := psSolid;
  Image1.Canvas.Pen.Color := clWhite;
  Image1.Canvas.Brush.Color := clWhite;
  Image1.Canvas.Brush.Style := bsSolid;

  Image1.Canvas.Rectangle(0, 0, Image1.Width, Image1.Height);
end;

procedure TForm1.LabelScoreClick(Sender: TObject);
begin

end;

procedure TForm1.TimerCreateTimer(Sender: TObject);
var
  NoJalurKosong: Integer; // no jalur di mana tdk ada obstacle
  i: integer;
begin
  NoJalurKosong := RandomRange(0, 4);

  for i:=0 to 3 do
  begin
    if i = NoJalurKosong then continue;
    Lane[i].Add(Kotak.Create(i));
	end;
end;


{ Shape }
constructor Shape.Create();
begin
  pos := 0;
  dx := 0;
  dy := 0;
  dz := 0;
  XSpeed := 0;
  tebal := 0;
end;

procedure Shape.Draw();
begin

end;

procedure Shape.Update();
begin

end;

{ Jalur }
procedure Jalur.Draw();
var
  xx: integer;
  yy: integer;
  i: integer;
  space: integer;    // jarak antar garis (bukan jalur)
begin
  with Form1 do
  begin
    Image1.Canvas.Pen.Style := psSolid;
    Image1.Canvas.Pen.Color := clYellow;
    Image1.Canvas.Pen.Width := 2;
    Image1.Canvas.Brush.Style := bsSolid;
    Image1.Canvas.Brush.Color := RGB(202,114,114);

    XX := Image1.Width div 2;
	  yy := Image1.Height div 2;

    space := 0;
    for i:=1 to 4 do
    begin
      Image1.Canvas.Polygon([
	      Point(CoorX(ZtoX(-xx, 0 + space)), CoorY(ZToY(0 + YOffset, 0 + space))),
	      Point(CoorX(ZtoX(-xx, 0 + space)), CoorY(ZToY(0 + YOffset, 125 + space))),
	      Point(CoorX(ZtoX(xx, 0 + space)), CoorY(ZToY(0 + YOffset, 125 + space))),
	      Point(CoorX(ZtoX(xx, 0 + space)), CoorY(ZToY(0 + YOffset, 0 + space)))
      ]);

      space := space + 125;
	  end;

    Image1.Canvas.Pen.Width := 1;
	end;
end;

procedure Jalur.Update();
begin

end;

{ Kotak }
constructor Kotak.Create(nJalur: Integer);
begin
  inherited Create;
  dx := Form1.Image1.Width div 2;
  dy := 0;
  pos := dx;
  XSpeed := -1;         // negatif artinya bergerak ke arah kiri
  tebal := 25;
  noJalur := nJalur;
end;

procedure Kotak.Draw();
var
  x, y, z: array[1..8] of Integer;
  i: integer;
begin
  with Form1 do
  begin
	  Image1.Canvas.Pen.Style := psSolid;
	  Image1.Canvas.Pen.Color := clWhite;
	  Image1.Canvas.Pen.Width := 3;
	  //Image1.Canvas.Brush.Style := bsClear;
	  Image1.Canvas.Brush.Color := clWhite;

	  x[1] := 0 + dx;
	  x[2] := tebal + dx;
	  x[3] := tebal + dx;
	  x[4] := 0 + dx;
	  x[5] := 0 + dx;
	  x[6] := tebal + dx;
	  x[7] := tebal + dx;
	  x[8] := 0 + dx;

	  y[1] := 0 + dy + YOffset;
	  y[2] := 0 + dy + YOffset;
	  y[3] := 100 + dy + YOffset;
	  y[4] := 100 + dy + YOffset;
	  y[5] := 0 + dy + YOffset;
	  y[6] := 0 + dy + YOffset;
	  y[7] := 100 + dy + YOffset;
	  y[8] := 100 + dy + YOffset;

	  z[1] := 125 * noJalur + dz;
	  z[2] := 125 * noJalur + dz;
	  z[3] := 125 * noJalur + dz;
	  z[4] := 125 * noJalur + dz;
	  z[5] := 125 * (noJalur+1) + dz;
	  z[6] := 125 * (noJalur+1) + dz;
	  z[7] := 125 * (noJalur+1) + dz;
	  z[8] := 125 * (noJalur+1) + dz;

	  //// Bagian Belakang
	  //Image1.Canvas.Brush.Color := clBlue;
	  //Image1.Canvas.Polygon([
	  //  Point( CoorX(ZtoX(x[1], z[1])), CoorY(ZtoY(y[1], z[1])) ),
	  //  Point( CoorX(ZtoX(x[2], z[2])), CoorY(ZtoY(y[2], z[2])) ),
	  //  Point( CoorX(ZtoX(x[3], z[3])), CoorY(ZtoY(y[3], z[3])) ),
	  //  Point( CoorX(ZtoX(x[4], z[4])), CoorY(ZtoY(y[4], z[4])) )
	  //]);
   //
   //
	  //// Bagian Bawah
	  //Image1.Canvas.Brush.Color := clPurple;
	  //Image1.Canvas.Polygon([
	  //  Point( CoorX(ZtoX(x[1], z[1])), CoorY(ZtoY(y[1], z[1])) ),
	  //  Point( CoorX(ZtoX(x[2], z[2])), CoorY(ZtoY(y[2], z[2])) ),
	  //  Point( CoorX(ZtoX(x[6], z[6])), CoorY(ZtoY(y[6], z[6])) ),
	  //  Point( CoorX(ZtoX(x[5], z[5])), CoorY(ZtoY(y[5], z[5])) )
	  //]);

    if dx < 0 then
    begin
      // Bagian kanan
		  Image1.Canvas.Brush.Color := clRed;
		  Image1.Canvas.Polygon([
		    Point( CoorX(ZtoX(x[2], z[2])), CoorY(ZtoY(y[2], z[2])) ),
		    Point( CoorX(ZtoX(x[3], z[3])), CoorY(ZtoY(y[3], z[3])) ),
		    Point( CoorX(ZtoX(x[7], z[7])), CoorY(ZtoY(y[7], z[7])) ),
		    Point( CoorX(ZtoX(x[6], z[6])), CoorY(ZtoY(y[6], z[6])) )
		  ]);
		end
    else
    begin
      // Bagian kiri
		  Image1.Canvas.Brush.Color := clYellow;
		  Image1.Canvas.Polygon([
		    Point( CoorX(ZtoX(x[1], z[1])), CoorY(ZtoY(y[1], z[1])) ),
		    Point( CoorX(ZtoX(x[5], z[5])), CoorY(ZtoY(y[5], z[5])) ),
		    Point( CoorX(ZtoX(x[8], z[8])), CoorY(ZtoY(y[8], z[8])) ),
		    Point( CoorX(ZtoX(x[4], z[4])), CoorY(ZtoY(y[4], z[4])) )
		  ]);
		end;

	  // Bagian Atas
	  Image1.Canvas.Brush.Color := clGreen;
	  Image1.Canvas.Polygon([
	    Point( CoorX(ZtoX(x[4], z[4])), CoorY(ZtoY(y[4], z[4])) ),
	    Point( CoorX(ZtoX(x[3], z[3])), CoorY(ZtoY(y[3], z[3])) ),
	    Point( CoorX(ZtoX(x[7], z[7])), CoorY(ZtoY(y[7], z[7])) ),
	    Point( CoorX(ZtoX(x[8], z[8])), CoorY(ZtoY(y[8], z[8])) )
	  ]);

	  // Bagian Depan
	  Image1.Canvas.Brush.Color := clBlack;
	  Image1.Canvas.Polygon([
	    Point( CoorX(ZtoX(x[5], z[5])), CoorY(ZtoY(y[5], z[5])) ),
	    Point( CoorX(ZtoX(x[6], z[6])), CoorY(ZtoY(y[6], z[6])) ),
	    Point( CoorX(ZtoX(x[7], z[7])), CoorY(ZtoY(y[7], z[7])) ),
	    Point( CoorX(ZtoX(x[8], z[8])), CoorY(ZtoY(y[8], z[8])) )
	  ]);
	end;
end;

procedure Kotak.Update();
begin
  dx := dx + XSpeed;
  pos := dx;
end;

{ Manusia }
constructor Manusia.Create(nJalur: integer);
begin
  inherited Create();
  noJalur := nJalur;
  dx := posXManusia;
  pos := dx;
  tebal := tebalManusia;
end;

procedure Manusia.Draw();
var
  x, y, z: array[1..8] of Integer;
  i: integer;
begin
  with Form1 do
  begin
    dz := 125 * noJalur + 125 div 2;

	  Image1.Canvas.Pen.Style := psSolid;
	  Image1.Canvas.Pen.Color := clBlack;
	  Image1.Canvas.Pen.Width := 15;;
	  Image1.Canvas.Brush.Style := bsSolid;
	  Image1.Canvas.Brush.Color := clBlack;

    // Gambar kepala
	  Image1.Canvas.Ellipse(
	    CoorX(ZtoX(220 div 2 + dx,0 + dz)), CoorY(ZtoY(150 div 2 + YOffset + dy,0 + dz)),
	    CoorX(ZtoX(150 div 2 + dx,0 + dz)), CoorY(ZtoY(220 div 2 + YOffset + dy,0 + dz))
    );

    if StyleManusia = 0 then
    begin
      Image1.Canvas.MoveTo(CoorX(ZtoX(dx + 140 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 140 div 2, dz + 0)));
			Image1.Canvas.LineTo(CoorX(ZtoX(dx + 5 div 2, dz + 0)),   CoorY(ZtoY(YOffset + dy + 5 div 2, dz + 0)));
			Image1.Canvas.MoveTo(CoorX(ZtoX(dx + 140 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 140 div 2, dz + 0)));
			Image1.Canvas.LineTo(CoorX(ZtoX(dx + 170 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 80 div 2, dz + 0)));
			Image1.Canvas.MoveTo(CoorX(ZtoX(dx + 170 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 80 div 2, dz + 0)));
			Image1.Canvas.LineTo(CoorX(ZtoX(dx + 220 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 110 div 2, dz + 0)));
			Image1.Canvas.MoveTo(CoorX(ZtoX(dx + 140 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 140 div 2, dz + 0)));
			Image1.Canvas.LineTo(CoorX(ZtoX(dx + 60 div 2, dz + 0)),  CoorY(ZtoY(YOffset + dy + 110 div 2, dz + 0)));
			Image1.Canvas.MoveTo(CoorX(ZtoX(dx + 60 div 2, dz + 0)),  CoorY(ZtoY(YOffset + dy + 110 div 2, dz + 0)));
			Image1.Canvas.LineTo(CoorX(ZtoX(dx + 115 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 90 div 2, dz + 0)));
			Image1.Canvas.MoveTo(CoorX(ZtoX(dx + 80 div 2, dz + 0)),  CoorY(ZtoY(YOffset + dy + 80 div 2, dz + 0)));
			Image1.Canvas.LineTo(CoorX(ZtoX(dx + 130 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 45 div 2, dz + 0)));
			Image1.Canvas.MoveTo(CoorX(ZtoX(dx + 130 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 45 div 2, dz + 0)));
			Image1.Canvas.LineTo(CoorX(ZtoX(dx + 90 div 2, dz + 0)),  CoorY(ZtoY(YOffset + dy + 5 div 2, dz + 0)));
		end else
    begin
      Image1.Canvas.MoveTo(CoorX(ZtoX(dx + 140 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 140 div 2, dz + 0)));
			Image1.Canvas.LineTo(CoorX(ZtoX(dx + 5 div 2, dz + 0)),   CoorY(ZtoY(YOffset + dy + 5 div 2, dz + 0)));
			Image1.Canvas.MoveTo(CoorX(ZtoX(dx + 140 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 140 div 2, dz + 0)));
			Image1.Canvas.LineTo(CoorX(ZtoX(dx + 140 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 90 div 2, dz + 0)));
			Image1.Canvas.MoveTo(CoorX(ZtoX(dx + 140 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 90 div 2, dz + 0)));
			Image1.Canvas.LineTo(CoorX(ZtoX(dx + 190 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 100 div 2, dz + 0)));
			Image1.Canvas.MoveTo(CoorX(ZtoX(dx + 140 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 140 div 2, dz + 0)));
			Image1.Canvas.LineTo(CoorX(ZtoX(dx + 70 div 2, dz + 0)),  CoorY(ZtoY(YOffset + dy + 130 div 2, dz + 0)));
			Image1.Canvas.MoveTo(CoorX(ZtoX(dx + 70 div 2, dz + 0)),  CoorY(ZtoY(YOffset + dy + 130 div 2, dz + 0)));
			Image1.Canvas.LineTo(CoorX(ZtoX(dx + 45 div 2, dz + 0)),  CoorY(ZtoY(YOffset + dy + 95 div 2, dz + 0)));
			Image1.Canvas.MoveTo(CoorX(ZtoX(dx + 90 div 2, dz + 0)),  CoorY(ZtoY(YOffset + dy + 90 div 2, dz + 0)));
			Image1.Canvas.LineTo(CoorX(ZtoX(dx + 140 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 30 div 2, dz + 0)));
			Image1.Canvas.MoveTo(CoorX(ZtoX(dx + 140 div 2, dz + 0)), CoorY(ZtoY(YOffset + dy + 30 div 2, dz + 0)));
			Image1.Canvas.LineTo(CoorX(ZtoX(dx + 70 div 2, dz + 0)),  CoorY(ZtoY(YOffset + dy + 5 div 2, dz + 0)));
    end;
	end;
end;

procedure Manusia.Update();
begin

end;

{ Kartesius }
procedure Kartesius.Draw();
begin
  with Form1 do
  begin
    Image1.Canvas.Pen.Style := psDash;
	  Image1.Canvas.Pen.Color := clBlack;

	  // Sumbu x
	  Image1.Canvas.MoveTo(CoorX(-Image1.Width div 2), CoorY(0));
	  Image1.Canvas.LineTo(CoorX(Image1.Width div 2), CoorY(0));

	  // Sumbu y
	  Image1.Canvas.MoveTo(CoorX(0), CoorY(Image1.Height div 2));
	  Image1.Canvas.LineTo(CoorX(0), CoorY(-Image1.Height div 2));
	end;
end;

procedure Kartesius.Update();
begin

end;


end.



