unit Main.View;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.ListView.Types,
  FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base,
  FMX.ListView,
  FMX.Objects,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  //-------------------------------------
  FMX.Surfaces,
  FMX.Helpers.Android,
  System.Permissions,
  System.IOUtils,
  System.Generics.Collections,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.Helpers,
  Androidapi.JNIBridge;

type
  TFormMain = class(TForm)
    RectBackground: TRectangle;
    ListView1: TListView;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
    procedure ListView1ItemClick(const Sender: TObject;
      const AItem: TListViewItem);
  private
    { Private declarations }
  public
    function GetActivityAppList: JList;
    function GetAppIcon(AAppInfo: JApplicationInfo): TBitmap;
    procedure LoadListInfo;
    procedure AddListItem(AAppName, APackageName, ADataPath: string;
      AIcon: TBitmap);
  end;

var
  FormMain: TFormMain;

implementation

{$R *.fmx}

function TFormMain.GetActivityAppList: JList;
var
  LTempList: JList;
  LIntent: JIntent;
  LManager: JPackageManager;
begin
  LIntent := TJIntent.Create;
  LIntent.SetAction(TJIntent.JavaClass.ACTION_MAIN);
  LIntent.AddCategory(TJIntent.JavaClass.CATEGORY_LAUNCHER);
  LManager := SharedActivity.GetPackageManager;
  LTempList := nil;
  LTempList := LManager.QueryIntentActivities(LIntent, 0);
  Result := LTempList;
end;

function TFormMain.GetAppIcon(AAppInfo: JApplicationInfo): TBitmap;
var
  LDrawable: JDrawable;
  LBitmap: JBitmap;
  LItemBitmap: TBitmap;
  LSurface: TBitmapSurface;
  LCanvas: JCanvas;
begin
  try
    Result := nil;

    if not Assigned(AAppInfo) then
      Exit;

    LItemBitmap := TBitmap.Create;

    LDrawable := AAppInfo.loadIcon(SharedActivity.getPackageManager);

    if not Assigned(LDrawable) then
      Exit;

    if LDrawable is TJBitmapDrawable then
    begin
      LBitmap := TJBitmapDrawable.Wrap((LDrawable as ILocalObject).GetObjectID).getBitmap;
      LSurface := TBitmapSurface.Create;
      try
        if JBitmapToSurface(LBitmap, LSurface) then
          LItemBitmap.Assign(LSurface);
      finally
        LSurface.Free;
      end;
    end
    else
    begin
      LBitmap := TJBitmap.JavaClass.createBitmap(LDrawable.getIntrinsicWidth, LDrawable.getIntrinsicHeight, TJBitmap_Config.JavaClass.ARGB_8888);

      LCanvas := TJCanvas.JavaClass.init(LBitmap);
      LDrawable.setBounds(0, 0, LCanvas.getWidth, LCanvas.getHeight);
      LDrawable.Draw(LCanvas);

      LSurface := TBitmapSurface.Create;
      try
        if JBitmapToSurface(LBitmap, LSurface) then
          LItemBitmap.Assign(LSurface);
      finally
        LSurface.Free;
      end;
    end;

    Result := LItemBitmap;
  except
    on E: Exception do
    begin
    end;
  end;
end;

procedure TFormMain.LoadListInfo;
var
  LJavaList: JList;
  I: Integer;
  LResolveInfo: JResolveInfo;
  LInfo: JActivityInfo;
  LAppInfo: JApplicationInfo;
begin
  LJavaList := GetActivityAppList;
  for I := 0 to LJavaList.Size - 1 do
  begin
    // Pega as informações do aplicativo
    LResolveInfo := TJResolveInfo.Wrap((LJavaList.Get(I) as ILocalObject).GetObjectID);
    LInfo := TJActivityInfo.Wrap((LResolveInfo.ActivityInfo as ILocalObject).GetObjectID);
    LAppInfo := TJApplicationInfo.Wrap((LInfo.ApplicationInfo as ILocalObject).GetObjectID);

    // Adiciona o item ao ListView com o nome do app, pacote, caminho de dados e ícone
    AddListItem(JStringToString(LAppInfo.LoadLabel(SharedActivity.GetPackageManager).toString),
                JStringToString(LInfo.PackageName),
                JStringToString(LAppInfo.DataDir),
                GetAppIcon(LAppInfo));

  end;
end;

procedure TFormMain.AddListItem(AAppName, APackageName, ADataPath: string;
  AIcon: TBitmap);
var
  LItem: TListViewItem;
begin
  LItem := ListView1.Items.Add;

  LItem.Objects.FindObject('TextAppName').Data := AAppName;
  LItem.Objects.FindObject('TextPackageName').Data := APackageName;
  LItem.Objects.FindObject('TextDataPath').Data := ADataPath;
  TListItemImage(LItem.Objects.FindDrawable('ImageIconApp')).Bitmap := AIcon;
  LItem.TagString := APackageName;
end;

procedure TFormMain.Button1Click(Sender: TObject);
begin
  LoadListInfo;
end;

procedure TFormMain.ListView1ItemClick(const Sender: TObject;
  const AItem: TListViewItem);
var
  LPackageName: string;
  LIntent: JIntent;
  LPackageManager: JPackageManager;
begin
  LPackageName := AItem.TagString;

  if LPackageName <> '' then
  begin
    LPackageManager := SharedActivity.getPackageManager;
    LIntent := LPackageManager.getLaunchIntentForPackage(StringToJString(LPackageName));

    if LIntent <> nil then
    begin
      SharedActivity.startActivity(LIntent);  // Inicia o aplicativo
    end
    else
    begin
      ShowMessage('Não foi possível iniciar o aplicativo.');
    end;
  end;
end;

end.

