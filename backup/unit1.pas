unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ExtCtrls, Spin, ColorBox, ExtDlgs;

type

  { TMainForm }

  TMainForm = class(TForm)
    ButtonLoad: TButton;
    ButtonClear: TButton;
    CheckBox1: TCheckBox;      // Жирный
    CheckBox2: TCheckBox;      // Курсив
    CheckBox3: TCheckBox;      // Подчеркнутый
    ColorBox1: TColorBox;
    cmbFontName: TComboBox;
    Edit1: TEdit;              // От кого
    EditRecipient: TEdit;      // Кому
    GroupBoxFont: TGroupBox;
    GroupBoxText: TGroupBox;
    GroupBoxAddress: TGroupBox;
    imgPreview: TImage;
    ImageList1: TImageList;
    Label1: TLabel;            // Шрифт
    Label2: TLabel;            // Размер
    Label3: TLabel;            // Цвет
    Label4: TLabel;            // Кому
    Label5: TLabel;            // От кого
    LabelSep: TLabel;
    MemoText: TMemo;
    OpenPictureDialog1: TOpenPictureDialog;
    PageControls: TPageControl;
    PanelPreview: TPanel;
    RadioButton1: TRadioButton; // Слева
    RadioButton2: TRadioButton; // Центр
    RadioButton3: TRadioButton; // Справа
    SpinEdit1: TSpinEdit;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    tsEditor: TTabSheet;
    tsGallery: TTabSheet;
    tsAbout: TTabSheet;
    ToolBar1: TToolBar;
    ToolButtonNew: TToolButton;
    ToolButton2: TToolButton;
    ToolButtonGallery: TToolButton;
    ToolButton4: TToolButton;
    ToolButtonSave: TToolButton;
    ToolButton6: TToolButton;
    ToolButtonHelp: TToolButton;

    procedure ButtonLoadClick(Sender: TObject);
    procedure ButtonClearClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ToolButtonGalleryClick(Sender: TObject);
    procedure ToolButtonHelpClick(Sender: TObject);
    procedure ToolButtonNewClick(Sender: TObject);
    procedure ToolButtonSaveClick(Sender: TObject);

    // Обработчики для элементов редактора
    procedure cmbFontNameChange(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
    procedure ColorBox1Change(Sender: TObject);
    procedure CheckBoxClick(Sender: TObject);
    procedure RadioButtonClick(Sender: TObject);
    procedure EditChange(Sender: TObject);
    procedure MemoTextChange(Sender: TObject);

  private
    FOriginalBackground: TBitmap;      // Оригинал фона
    FUpdateTimer: TTimer;              // Таймер для отложенного обновления (пока не используется, но оставим)
    FNeedsUpdate: Boolean;             // Флаг (резерв)

    procedure UpdateStatus(const Msg: string);
    procedure SwitchToEditor;
    procedure SwitchToGallery;
    procedure SwitchToAbout;
    procedure ApplyModernStyle;
    procedure UpdatePreview;            // Главный метод перерисовки
    procedure DelayedUpdateTimer(Sender: TObject); // (запасной)
    procedure SetupUpdateTimer;         // Инициализация таймера

  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

// ---- Инициализация и завершение ----

procedure TMainForm.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  PanelPreview.DoubleBuffered := True;

  imgPreview.Transparent := False;
  imgPreview.AutoSize := False;

  StatusBar1.SimplePanel := True;
  StatusBar1.SimpleText := 'Готово';

  ToolBar1.Flat := True;
  ToolBar1.Transparent := False;

  // Настройка диалога выбора фона
  OpenPictureDialog1.Filter := 'Изображения|*.bmp;*.jpg;*.jpeg;*.png|Все файлы|*.*';
  OpenPictureDialog1.Title := 'Выберите фоновое изображение';
  OpenPictureDialog1.Options := [ofFileMustExist, ofHideReadOnly];

  // Заполнение списка шрифтов
  cmbFontName.Items := Screen.Fonts;
  if cmbFontName.Items.IndexOf('Arial') >= 0 then
    cmbFontName.ItemIndex := cmbFontName.Items.IndexOf('Arial')
  else if cmbFontName.Items.Count > 0 then
    cmbFontName.ItemIndex := 0;

  // Создание объекта для фона
  FOriginalBackground := TBitmap.Create;

  // Настройка таймера (оставим для возможного использования позже)
  SetupUpdateTimer;

  // Применение стилей
  ApplyModernStyle;

  SwitchToEditor;

  // Первоначальное обновление предпросмотра
  UpdatePreview;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FOriginalBackground);
  FreeAndNil(FUpdateTimer);
end;

procedure TMainForm.SetupUpdateTimer;
begin
  FUpdateTimer := TTimer.Create(Self);
  FUpdateTimer.Interval := 300;
  FUpdateTimer.Enabled := False;
  FUpdateTimer.OnTimer := @DelayedUpdateTimer;
end;

procedure TMainForm.DelayedUpdateTimer(Sender: TObject);
begin
  FUpdateTimer.Enabled := False;
  if FNeedsUpdate then
  begin
    UpdatePreview;
    FNeedsUpdate := False;
  end;
end;

// ---- Стилизация интерфейса ----

procedure TMainForm.ApplyModernStyle;
var
  i: Integer;
begin
  PageControls.TabHeight := 1;

  ToolBar1.Flat := True;
  ToolBar1.Transparent := False;
  ToolBar1.ShowCaptions := True;
  ToolBar1.Indent := 4;
  ToolBar1.ButtonWidth := 80;
  ToolBar1.ButtonHeight := 46;

  for i := 0 to ToolBar1.ButtonCount - 1 do
    if ToolBar1.Buttons[i].Style <> tbsDivider then
      ToolBar1.Buttons[i].AutoSize := True;

  StatusBar1.Font.Style := [fsBold];

  tsEditor.Caption := 'Редактор';
  tsGallery.Caption := 'Галерея';
  tsAbout.Caption := 'О программе';

  Color := clBtnFace;

  cmbFontName.Style := csDropDownList;
  cmbFontName.DropDownCount := 15;
  cmbFontName.Sorted := True;
end;

// ---- Переключение режимов ----

procedure TMainForm.SwitchToEditor;
begin
  PageControls.ActivePage := tsEditor;
  ToolButtonNew.Down := True;
  ToolButtonGallery.Down := False;
  ToolButtonHelp.Down := False;
  if not DirectoryExists('cards') then
    CreateDir('cards');
end;

procedure TMainForm.SwitchToGallery;
begin
  PageControls.ActivePage := tsGallery;
  ToolButtonNew.Down := False;
  ToolButtonGallery.Down := True;
  ToolButtonHelp.Down := False;
end;

procedure TMainForm.SwitchToAbout;
begin
  PageControls.ActivePage := tsAbout;
  ToolButtonNew.Down := False;
  ToolButtonGallery.Down := False;
  ToolButtonHelp.Down := True;
end;

procedure TMainForm.UpdateStatus(const Msg: string);
begin
  StatusBar1.SimpleText := Msg;
end;

// ---- Обработчики кнопок тулбара ----

procedure TMainForm.ToolButtonNewClick(Sender: TObject);
begin
  SwitchToEditor;
  UpdateStatus('Создание новой открытки');
end;

procedure TMainForm.ToolButtonSaveClick(Sender: TObject);
begin
  // TODO: сохранение
  UpdateStatus('Открытка сохранена');
end;

procedure TMainForm.ToolButtonGalleryClick(Sender: TObject);
begin
  SwitchToGallery;
  UpdateStatus('Просмотр галереи открыток');
end;

procedure TMainForm.ToolButtonHelpClick(Sender: TObject);
begin
  SwitchToAbout;
  UpdateStatus('Справка по программе');
end;

// ---- Горячие клавиши ----

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    Ord('H'): if ssCtrl in Shift then ToolButtonHelpClick(Self);
    Ord('N'): if ssCtrl in Shift then ToolButtonNewClick(Self);
    Ord('G'): if ssCtrl in Shift then ToolButtonGalleryClick(Self);
    Ord('S'): if ssCtrl in Shift then ToolButtonSaveClick(Self);
  end;
  if Key = 13 then
     ShowMessage('Enter в форме');
end;

// ---- Загрузка фона ----

procedure TMainForm.ButtonLoadClick(Sender: TObject);
var
  Picture: TPicture;
begin
  if OpenPictureDialog1.Execute then
  begin
    Picture := TPicture.Create;
    try
      Picture.LoadFromFile(OpenPictureDialog1.FileName);
      FOriginalBackground.Assign(Picture.Graphic);
      UpdatePreview;
      UpdateStatus('Фон загружен: ' + ExtractFileName(OpenPictureDialog1.FileName));
    except
      on E: Exception do
        ShowMessage('Ошибка загрузки изображения: ' + E.Message);
    end;
    Picture.Free;
  end;
end;

// ---- Очистка редактора ----

procedure TMainForm.ButtonClearClick(Sender: TObject);
begin
  if MessageDlg('Очистка', 'Очистить редактор и начать новую открытку?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FOriginalBackground.SetSize(0, 0);
    MemoText.Clear;
    EditRecipient.Clear;
    Edit1.Clear;
    cmbFontName.ItemIndex := cmbFontName.Items.IndexOf('Arial');
    if cmbFontName.ItemIndex = -1 then cmbFontName.ItemIndex := 0;
    SpinEdit1.Value := 24;
    ColorBox1.Selected := clRed;
    CheckBox1.Checked := False;
    CheckBox2.Checked := False;
    CheckBox3.Checked := False;
    RadioButton2.Checked := True;
    UpdatePreview;
    UpdateStatus('Редактор очищен');
  end;
end;

// ---- Метод UpdatePreview ----

procedure TMainForm.UpdatePreview;
var
  Buffer: TBitmap;
  TextRect: TRect;
  TextY: Integer;
  TS: TTextStyle;
begin
  Buffer := TBitmap.Create;
  try
    // Определяем размер буфера
    if (FOriginalBackground.Width > 0) and (FOriginalBackground.Height > 0) then
    begin
      Buffer.Width := FOriginalBackground.Width;
      Buffer.Height := FOriginalBackground.Height;
      Buffer.Canvas.Draw(0, 0, FOriginalBackground);
    end
    else
    begin
      Buffer.Width := 800;
      Buffer.Height := 600;
      Buffer.Canvas.Brush.Color := clWhite;
      Buffer.Canvas.FillRect(0, 0, Buffer.Width, Buffer.Height);
    end;

    // Настройка шрифта
    Buffer.Canvas.Font.Name := cmbFontName.Text;
    Buffer.Canvas.Font.Size := SpinEdit1.Value;
    Buffer.Canvas.Font.Color := ColorBox1.Selected;

    // Стили шрифта
    Buffer.Canvas.Font.Style := [];
    if CheckBox1.Checked then
      Buffer.Canvas.Font.Style := Buffer.Canvas.Font.Style + [fsBold];
    if CheckBox2.Checked then
      Buffer.Canvas.Font.Style := Buffer.Canvas.Font.Style + [fsItalic];
    if CheckBox3.Checked then
      Buffer.Canvas.Font.Style := Buffer.Canvas.Font.Style + [fsUnderline];

    // Выравнивание
    TS := Buffer.Canvas.TextStyle;
    if RadioButton1.Checked then
      TS.Alignment := taLeftJustify
    else if RadioButton2.Checked then
      TS.Alignment := taCenter
    else if RadioButton3.Checked then
      TS.Alignment := taRightJustify;
    TS.WordBreak := True;
    Buffer.Canvas.TextStyle := TS;

    Buffer.Canvas.Brush.Style := bsClear; // прозрачный фон

    // Область для основного текста (с защитой от слишком узкого буфера)
    if Buffer.Width > 100 then
      TextRect := Rect(50, 50, Buffer.Width - 50, Buffer.Height - 100)
    else
      TextRect := Rect(5, 5, Buffer.Width - 5, Buffer.Height - 10);

    // Рисуем основной текст (если пусто – подсказка)
    if MemoText.Text <> '' then
      Buffer.Canvas.TextRect(TextRect, TextRect.Left, TextRect.Top, MemoText.Text)
    else
      Buffer.Canvas.TextRect(TextRect, TextRect.Left, TextRect.Top, 'Введите текст поздравления');

    // Рисуем "Кому" и "От кого"
    Buffer.Canvas.Font.Size := 16;
    TextY := Buffer.Height - 40;
    if EditRecipient.Text <> '' then
      Buffer.Canvas.TextOut(50, TextY, 'Для: ' + EditRecipient.Text);
    if Edit1.Text <> '' then
      Buffer.Canvas.TextOut(Buffer.Width - 50 -
        Buffer.Canvas.TextWidth('От: ' + Edit1.Text),
        TextY, 'От: ' + Edit1.Text);

    // Отображаем результат
    imgPreview.Picture.Assign(Buffer);
    imgPreview.Refresh;

  finally
    Buffer.Free;
  end;
end;

// ---- Обработчики изменений параметров ----
// Все обработчики, кроме MemoTextChange, вызывают UpdatePreview немедленно.
// MemoTextChange также вызывает UpdatePreview напрямую (без таймера), чтобы текст обновлялся сразу.

procedure TMainForm.cmbFontNameChange(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TMainForm.SpinEdit1Change(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TMainForm.ColorBox1Change(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TMainForm.CheckBoxClick(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TMainForm.RadioButtonClick(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TMainForm.EditChange(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TMainForm.MemoTextChange(Sender: TObject);
begin
  // Немедленное обновление – текст должен появляться сразу
  UpdatePreview;
end;

end.
