unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ExtCtrls, Spin, ColorBox, ExtDlgs, SynEdit;

type

  { TMainForm }

  TMainForm = class(TForm)
    ButtonLoad: TButton;
    ButtonClear: TButton;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    ColorBox1: TColorBox;
    cmbFontName: TComboBox;
    Edit1: TEdit;
    EditRecipient: TEdit;
    GroupBoxFont: TGroupBox;
    GroupBoxText: TGroupBox;
    GroupBoxAddress: TGroupBox;
    imgPreview: TImage;
    ImageList1: TImageList;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    LabelSep: TLabel;
    MemoText: TMemo;
    OpenPictureDialog1: TOpenPictureDialog;
    PageControls: TPageControl;
    PanelPreview: TPanel;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    RadioButton3: TRadioButton;
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
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ToolButtonGalleryClick(Sender: TObject);
    procedure ToolButtonHelpClick(Sender: TObject);
    procedure ToolButtonNewClick(Sender: TObject);
    procedure ToolButtonSaveClick(Sender: TObject);
  private
    procedure UpdateStatus(const Msg: string);
    procedure SwitchToEditor;
    procedure SwitchToGallery;
    procedure SwitchToAbout;
    procedure ApplyModernStyle;

  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }


// ---- Работа с интерфейсом ----


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

  // ---- Настройка загрузки фона ----
  OpenPictureDialog1.Filter := 'Изображения|*.bmp;*.jpg;*.jpeg;*.png|Все файлы|*.*';
  OpenPictureDialog1.Title := 'Выберите фоновое изображение';
  OpenPictureDialog1.Options := [ofFileMustExist, ofHideReadOnly];

  // ---- Настройка ComboBox ----
  cmbFontName.Items := Screen.Fonts;
  Application.ProcessMessages;

  if cmbFontName.Items.IndexOf('Arial') >= 0 then
    cmbFontName.ItemIndex := cmbFontName.Items.IndexOf('Arial')
  else
    cmbFontName.ItemIndex := 0;

  ApplyModernStyle;

  SwitchToEditor;
end;


// ---- Стилизация интерфейса ----


procedure TMainForm.ApplyModernStyle;
var
  i: Integer;
begin
  // Настройка PageControl
  PageControls.TabHeight := 1;

  ToolBar1.Flat := True;
  ToolBar1.Transparent := False;
  ToolBar1.ShowCaptions := True;
  ToolBar1.Indent := 4;
  ToolBar1.ButtonWidth := 80;
  ToolBar1.ButtonHeight := 46;

  // Авторазмер для всех кнопок (кроме разделителей)
  for i := 0 to ToolBar1.ButtonCount - 1 do
  begin
    if ToolBar1.Buttons[i].Style <> tbsDivider then
    begin
      ToolBar1.Buttons[i].AutoSize := True;
    end;
  end;

  // Настройка StatusBar
  StatusBar1.Font.Style := [fsBold];

  // Настройка вкладок
  tsEditor.Caption := 'Редактор';
  tsGallery.Caption := 'Галерея';
  tsAbout.Caption := 'О программе';

  Color := clBtnFace;

  cmbFontName.Style := csDropDownList;
  cmbFontName.DropDownCount := 15;
  cmbFontName.Sorted := True;
end;


// ---- Работа с ToolBar ----


procedure TMainForm.ToolButtonNewClick(Sender: TObject);
begin
  SwitchToEditor;
  // Здесь будет код очистки редактора для новой открытки
  UpdateStatus('Создание новой открытки');
end;


// ---- Редактор открыток ----



// ---- Загрузка фона ----

procedure TMainForm.ButtonLoadClick(Sender: TObject);
begin
  if OpenPictureDialog1.Execute then
  begin
    try
      // Загружаем изображение в imgPreview
      imgPreview.Picture.LoadFromFile(OpenPictureDialog1.FileName);

      // Можно сохранить путь к файлу для дальнейшего использования
      FBackgroundFileName := OpenPictureDialog1.FileName;

      // Обновляем статус
      UpdateStatus('Фон загружен: ' + ExtractFileName(OpenPictureDialog1.FileName));

      // Перерисовываем текст поверх нового фона
      UpdatePreview;
    except
      on E: Exception do
        ShowMessage('Ошибка загрузки изображения: ' + E.Message);
    end;
  end;

end;

procedure TMainForm.ToolButtonSaveClick(Sender: TObject);
begin
  // Сохранение открытки
  UpdateStatus('Открытка сохранена');
  // Здесь будет вызов функции сохранения
end;

procedure TMainForm.ToolButtonGalleryClick(Sender: TObject);
begin
  SwitchToGallery;
  // Здесь будет код обновления галереи
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
    Ord('H'): if ssCtrl in Shift then   // Ctrl+H - справка
                ToolButtonHelpClick(Self);
    Ord('N'): if ssCtrl in Shift then   // Ctrl+N - новая
                ToolButtonNewClick(Self);
    Ord('G'): if ssCtrl in Shift then   // Ctrl+G - галерея
                ToolButtonGalleryClick(Self);
    Ord('S'): if ssCtrl in Shift then   // Ctrl+S - сохранить
                ToolButtonSaveClick(Self);
  end;
end;


// ---- Переключение между режимами ----


procedure TMainForm.SwitchToEditor;
begin
  PageControls.ActivePage := tsEditor;
  ToolButtonNew.Down := True;
  ToolButtonGallery.Down := False;
  ToolButtonHelp.Down := False;
  if DirectoryExists('cards') then

  else
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

end.

