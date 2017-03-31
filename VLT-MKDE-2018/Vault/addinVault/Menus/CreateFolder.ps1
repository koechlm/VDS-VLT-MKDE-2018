#--------------------------------------------------------
# CreateFolder_Subfolders_Properties.ps1
# Note - Requires Default_Extensions_QS-VDS.ps1 available
#
#--------------------------------------------------------

#Replace / edit the default CreateFolder.ps1 file by this code:

$folderId = $vaultContext.CurrentSelectionSet[0].Id
$vaultContext.ForceRefresh = $true
$dialog = $dsCommands.GetCreateFolderDialog($folderId)
$xamlFile = New-Object CreateObject.WPF.XamlFile "testxaml", "%ProgramData%\Autodesk\Vault 2018\Extensions\DataStandard\Vault\Configuration\Folder.xaml"
$dialog.XamlFile = $xamlFile

$result = $dialog.Execute()
$dsDiag.Trace($result)

if($result)
{
	#new folder can be found in $dialog.CurrentFolder
	$folder = $vault.DocumentService.GetFolderById($folderId)
	#region create subfolders for particular categories only
	$NewFolder = $dialog.CurrentFolder
	$path = $folder.FullName+"/"+$dialog.CurrentFolder.Name
	If ($NewFolder.cat.CatName -eq "Projekt") {
		#get Ids of all entities and definitions
		$mCat = mGetCategoryDef "FLDR" "Ordner" #change the name according category of 1st level's subfolders
		$mCat2 = mGetCategoryDef "FLDR" "Projekt-Konstruktion" #change the name according category of 2nd level's subfolders
		#region create folder level 1
			$_SubFolder = $vault.DocumentService.AddFolder("CAD", $NewFolder.Id, $false)
			$vault.DocumentServiceExtensions.UpdateFolderCategories(@($_SubFolder.Id), @($mCat2))
			$mFldPropUpdated = mUpdateFldrProperties $_SubFolder.Id "Titel" "CAD Mechanik"
			$mFldPropUpdated = mUpdateFldrProperties $_SubFolder.Id "Beschreibung" "2D, 3D CAD, Berechnungen etc."
		#endregion

		#region create folder level 1
			$_SubFolder =$vault.DocumentService.AddFolder("CAE", $NewFolder.Id, $false)
			$vault.DocumentServiceExtensions.UpdateFolderCategories(@($_SubFolder.Id), @($mCat2))
			$mFldPropUpdated = mUpdateFldrProperties $_SubFolder.Id "Titel" "CAE Elektrotechnik"
			$mFldPropUpdated = mUpdateFldrProperties $_SubFolder.Id "Beschreibung" "Elektro-, SPS-, Fluid- Schemata"
		#endregion

		#region create folder level 1
			$_SubFolder =$vault.DocumentService.AddFolder("Spezifikationen", $NewFolder.Id, $false)
			$vault.DocumentServiceExtensions.UpdateFolderCategories(@($_SubFolder.Id), @($mCat))
			$mFldPropUpdated = mUpdateFldrProperties $_SubFolder.Id "Titel" "Spezifikationen"
			$mFldPropUpdated = mUpdateFldrProperties $_SubFolder.Id "Beschreibung" "Beschreibende Dokumente, Berechnungen, etc."
		#endregion

		#region create folder level 1
			$_SubFolder =$vault.DocumentService.AddFolder("Schriftverkehr", $NewFolder.Id, $false)
			$vault.DocumentServiceExtensions.UpdateFolderCategories(@($_SubFolder.Id), @($mCat))
			$mFldPropUpdated = mUpdateFldrProperties $_SubFolder.Id "Titel" "Schriftverkehr"
			$mFldPropUpdated = mUpdateFldrProperties $_SubFolder.Id "Beschreibung" "Office Dokumente, Email, Scan-Dateien"

			#region create folder level 2
				$_SubFldr2 = $vault.DocumentService.AddFolder("Kunde", $_SubFolder.Id, $false)
				$vault.DocumentServiceExtensions.UpdateFolderCategories(@($_SubFldr2.Id), @($mCat))
				$mFldPropUpdated = mUpdateFldrProperties $_SubFldr2.Id "Titel" "Schriftverkehr Kunden"

				$_SubFldr2 = $vault.DocumentService.AddFolder("Lieferanten", $_SubFolder.Id, $false)
				$vault.DocumentServiceExtensions.UpdateFolderCategories(@($_SubFldr2.Id), @($mCat))
				$mFldPropUpdated = mUpdateFldrProperties $_SubFldr2.Id "Titel" "Schriftverkehr Lieferanten"
			#endregion
		#endregion

		#region create folder level 1
			$_SubFolder =$vault.DocumentService.AddFolder("Techn Dokumentation", $NewFolder.Id, $false)
			$vault.DocumentServiceExtensions.UpdateFolderCategories(@($_SubFolder.Id), @($mCat))
			$mFldPropUpdated = mUpdateFldrProperties $_SubFolder.Id "Titel" "Technische Dokumentation"
			$mFldPropUpdated = mUpdateFldrProperties $_SubFolder.Id "Beschreibung" "Ersatzteilverzeichnisse, Montage- und Wartungsanleitungen, etc..."
		#endregion
	}

	#endregion
	[System.Reflection.Assembly]::LoadFrom("C:\Program Files\Autodesk\Vault Professional 2018\Explorer\Autodesk.Connectivity.Explorer.Extensibility.dll")
	$selectionId = [Autodesk.Connectivity.Explorer.Extensibility.SelectionTypeId]::Folder
	$location = New-Object Autodesk.Connectivity.Explorer.Extensibility.LocationContext $selectionId, $path
	$vaultContext.GoToLocation = $location
}