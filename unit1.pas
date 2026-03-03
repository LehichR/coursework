unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ExtCtrls, Spin, ColorBox, ExtDlgs; // SynEdit удалён

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
    FBackgroundFileName: string;       // Путь к последнему загруженному фону
    FUpdateTimer: TTimer;              // Таймер для отложенного обновления
    FNeedsUpdate: Boolean;             // Флаг необходимости обновления

    procedure UpdateStatus(const Msg: string);
    procedure SwitchToEditor;
    procedure SwitchToGallery;
    procedure SwitchToAbout;
    procedure ApplyModernStyle;
    procedure UpdatePreview;            // Главный метод перерисовки
    procedure DelayedUpdateTimer(Sender: TObject); // Обработчик таймера
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

  // Настройка таймера для отложенного обновления
  SetupUpdateTimer;

  // Применение стилей
  ApplyModernStyle;

  SwitchToEditor;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FOriginalBackground);
  FreeAndNil(FUpdateTimer);
end;

procedure TMainForm.SetupUpdateTimer;
begin
  FUpdateTimer := TTimer.Create(Self);
  FUpdateTimer.Interval := 300; // 300 мс задержки
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
  // Создаём папку cards, если её нет
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
  // Очистка редактора (можно реализовать позже)
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
end;

// ---- Загрузка фона ----

procedure TMainForm.ButtonLoadClick(Sender: TObject);
begin
  if OpenPictureDialog1.Execute then
  begin
    try
      FBackgroundFileName := OpenPictureDialog1.FileName;
      FOriginalBackground.LoadFromFile(FBackgroundFileName);
      UpdatePreview;
      UpdateStatus('Фон загружен: ' + ExtractFileName(FBackgroundFileName));
    except
      on E: Exception do
        ShowMessage('Ошибка загрузки изображения: ' + E.Message);
    end;
  end;
end;

// ---- Очистка редактора ----

procedure TMainForm.ButtonClearClick(Sender: TObject);
begin
  if MessageDlg('Очистка', 'Очистить редактор и начать новую открытку?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    // Очищаем фон
    FOriginalBackground.SetSize(0, 0); // или Free и Create заново
    // Очищаем текстовые поля
    MemoText.Clear;
    EditRecipient.Clear;
    Edit1.Clear;
    // Сбрасываем настройки по умолчанию (опционально)
    cmbFontName.ItemIndex := cmbFontName.Items.IndexOf('Arial');
    SpinEdit1.Value := 24;
    ColorBox1.Selected := clRed;
    CheckBox1.Checked := False;
    CheckBox2.Checked := False;
    CheckBox3.Checked := False;
    RadioButton2.Checked := True; // По центру
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
  TS: TTextStyle;              // Для работы с TextStyle
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

    // Настройка стилей шрифта (жирный, курсив, подчеркнутый)
    Buffer.Canvas.Font.Style := [];
    if CheckBox1.Checked then
      Buffer.Canvas.Font.Style := Buffer.Canvas.Font.Style + [fsBold];
    if CheckBox2.Checked then
      Buffer.Canvas.Font.Style := Buffer.Canvas.Font.Style + [fsItalic];
    if CheckBox3.Checked then
      Buffer.Canvas.Font.Style := Buffer.Canvas.Font.Style + [fsUnderline];

    // ---- ИСПРАВЛЕНО: работа с TextStyle ----
    TS := Buffer.Canvas.TextStyle;  // Читаем текущие настройки

    // Выравнивание
    if RadioButton1.Checked then
      TS.Alignment := taLeftJustify
    else if RadioButton2.Checked then
      TS.Alignment := taCenter
    else if RadioButton3.Checked then
      TS.Alignment := taRightJustify;

    TS.WordBreak := True;           // Перенос слов
    Buffer.Canvas.TextStyle := TS;  // Применяем настройки
    // ---------------------------------------

    Buffer.Canvas.Brush.Style := bsClear; // Прозрачный фон для текста

    // Область для основного текста (с отступами)
    TextRect := Rect(50, 50, Buffer.Width - 50, Buffer.Height - 100);

    // Рисуем основной текст
    Buffer.Canvas.TextRect(TextRect, TextRect.Left, TextRect.Top, MemoText.Text);

    // Рисуем "Кому" и "От кого" внизу
    Buffer.Canvas.Font.Size := 16; // Меньше основного
    TextY := Buffer.Height - 40;

    if EditRecipient.Text <> '' then
      Buffer.Canvas.TextOut(50, TextY, 'Для: ' + EditRecipient.Text);

    if Edit1.Text <> '' then
    begin
      // Выравниваем "От кого" по правому краю
      Buffer.Canvas.TextOut(Buffer.Width - 50 -
        Buffer.Canvas.TextWidth('От: ' + Edit1.Text),
        TextY, 'От: ' + Edit1.Text);
    end;

    // Отображаем результат
    imgPreview.Picture.Assign(Buffer);

  finally
    Buffer.Free;
  end;
end;

// ---- Обработчики изменений параметров ----

procedure TMainForm.cmbFontNameChange(Sender: TObject);
begin
  UpdatePreview; // Мгновенно, т.к. это не текст
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
  // Для полей "Кому" и "От кого" тоже можно обновлять сразу
  UpdatePreview;
end;

procedure TMainForm.MemoTextChange(Sender: TObject);
begin
  // При изменении текста запускаем таймер с задержкой
  FNeedsUpdate := True;
  FUpdateTimer.Enabled := False;  // Сброс
  FUpdateTimer.Enabled := True;
end;

end.
