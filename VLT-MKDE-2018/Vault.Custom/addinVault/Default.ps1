
#=============================================================================#
# PowerShell script sample for Vault Data Standard                            #
#			 Autodesk Vault - Quickstart 2018  								  #
# This sample is based on VDS 2018 RTM and adds functionality and rules       #
# All additions are marked with 'region Quickstart' - 'endregion'			  #
#                                                                             #
# Copyright (c) Autodesk - All rights reserved.                               #
#                                                                             #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  #
#=============================================================================#

#this function will be called to check if the Ok button can be enabled
function ActivateOkButton
{
		return Validate;
}

# sample validation function
# finds all function definition with names beginning with
# ValidateFile, ValidateFolder and ValidateTask respectively
# these funcions should return a boolean value, $true if the Property is valid
# $false otherwise
# As soon as one property validation function returns $false the entire Validate function will return $false
function Validate
{
	$mWindowName = $dsWindow.Name
	switch($mWindowName)
	{
		"FileWindow"
		{
			foreach ($func in dir function:ValidateFile*) { if(!(&$func)) { return $false } }
			return $true
		}
		"FolderWindow"
		{
			foreach ($func in dir function:ValidateFolder*) { if(!(&$func)) { return $false } }
			return $true
		}
		"CustomObjectWindow"
		{
			foreach ($func in dir function:ValidateCustomObject*) { if(!(&$func)) { return $false } }
			return $true
		}
		default { return $true }
	}
    
}

# sample validation function for the Title property
# if the Title is empty the validation will fail
#function ValidateFileTitle
{
	#if($Prop["_XLTN_TITLE"].Value) { return $true}
	#return $false;
}

# if the File Name is empty the validation will fail
function ValidateFileName
{
	if($dsWindow.FindName("FILENAME").Text -or !$dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
	{
		return $true;
	}
	return $false;
}

function ValidateFolderName
{
	if($dsWindow.FindName("FOLDERNAME").Text -or !$dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
	{
		return $true;
	}
	return $false;
}

function ValidateCustomObjectName
{
	if($dsWindow.FindName("CUSTOMOBJECTNAME").Text -or !$dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
	{
		return $true;
	}
	return $false;
}


function InitializeTabWindow
{
	#$dsDiag.ShowLog()
	#$dsDiag.Inspect()
}

function InitializeWindow
{	      
	#begin rules applying commonly
      
	$Prop["_Category"].add_PropertyChanged({
        if ($_.PropertyName -eq "Value")
        {
			#region quickstart
				#$Prop["_NumSchm"].Value = $Prop["_Category"].Value
				m_CategoryChanged
			#endregion
        }		
    })
	
	#end rules applying commonly
	$mWindowName = $dsWindow.Name
	switch($mWindowName)
	{	
		"FileWindow"
		{
			#rules applying for File
			$dsWindow.Title = SetWindowTitle $UIString["LBL24"] $UIString["LBL25"] $Prop["_FileName"].Value
			if ($Prop["_CreateMode"].Value)
			{
				if ($Prop["_IsOfficeClient"].Value)
				{
					$Prop["_Category"].Value = $UIString["CAT2"]
				}
				else
				{
					$Prop["_Category"].Value = $UIString["CAT1"]
				}

				#region workaround template selection reset
				$dsWindow.FindName("DocTypeCombo").add_SelectionChanged({
					mResetTemplates
				})

				#$dsWindow.FindName("btnTemplateReset").IsEnabled = $false
				$dsWindow.FindName("btnTemplateReset").Opacity = 0.3
				$dsWindow.FindName("TemplateCB").add_SelectionChanged({
					m_TemplateChanged
				})
				#endregion workaround template selection reset
			}
			
			#region CatalogTerm FileWindow switch option
			If ($dsWindow.FindName("tabTermsCatalog"))
			{
				Try{
					Import-Module -FullyQualifiedName "C:\ProgramData\Autodesk\Vault 2018\Extensions\DataStandard\Vault.Custom\addinVault\CatalogTermsTranslations.psm1"
				}
				catch{
					$dsWindow.FindName("tabTermsCatalog").Visibility = "Collapsed"
				   return
				}
								
				Try 
				{
					$dsWindow.FindName("mSearchTermText").text = $Prop["_XLTN_TITLE"].Value
			
					$Prop["_XLTN_TITLE"].add_PropertyChanged({
							param( $parameter)
							$dsWindow.FindName("mSearchTermText").text = $Prop["_XLTN_TITLE"].Value
						})

					mAddCoCombo -_CoName $UIString["Class_00"] #enables classification filter for catalog of terms starting with segment

					$dsWindow.FindName("dataGrdTermsFound").add_SelectionChanged({
						param($sender, $SelectionChangedEventArgs)
						$dsDiag.Trace(".. TermsFoundSelection")
						IF($dsWindow.FindName("dataGrdTermsFound").SelectedItem){
							$dsWindow.FindName("btnAdopt").IsEnabled = $true
							$dsWindow.FindName("btnAdopt").IsDefault = $true
						}
						Else {
							$dsWindow.FindName("btnAdopt").IsEnabled = $false
							$dsWindow.FindName("btnSearchTerm").IsDefault = $true
						}
					})

				}	
				catch { $dsDiag.Trace("WARNING expander TermCatalog is not present")}
			}
			#endregionCatalogTerm

			#region ItemLookUp
			If ($dsWindow.FindName("tabItemLookup"))
				{$dsWindow.FindName("cmbItemCategories").ItemsSource = mGetItemCategories
				Try
				{
					#$dsWindow.FindName("tabCtrlMain").add_SelectionChanged({
					#	param($sender, $SelectionChangedEventArgs)
					#	if ($dsWindow.FindName("tabFileProperties").IsSelected -eq $true)
					#	{
					#		$dsWindow.FindName("TemplateCB").SelectedIndex = $global:mSelectedTemplate
					#	}
					#})

					$dsWindow.FindName("ItemsFound").add_SelectionChanged({
						param()
						$dsDiag.Trace(".. ItemsFoundSelection")
						IF($dsWindow.FindName("ItemsFound").SelectedItem){
							$dsWindow.FindName("btnAdoptItem").IsEnabled = $true
							$dsWindow.FindName("btnAdoptItem").IsDefault = $true
						}
						Else {
							$dsWindow.FindName("btnAdoptItem").IsEnabled = $false
							$dsWindow.FindName("btnSearchItem").IsDefault = $true
						}
					})
				}
				catch{ $dsDiag.Trace("WARNING expander exItemLookup is not present") }
				}
			#endregion
		}
		"FolderWindow"
		{
			#rules applying for Folder
			$dsWindow.Title = SetWindowTitle $UIString["LBL29"] $UIString["LBL30"] $Prop["_FolderName"].Value
			if ($Prop["_CreateMode"].Value)
			{
				$Prop["_Category"].Value = $UIString["CAT5"]
			}
			#region Quickstart - for imported folders easily set title to folder name on edit
			If ($Prop["_EditMode"].Value) {
				If ($Prop["_XLTN_TITLE"]){
					IF ($Prop["_XLTN_TITLE"].Value -eq $null) {
						$Prop["_XLTN_TITLE"].Value = $Prop["Name"].Value
					}
				}
			}
			#endregion Quickstart
		}
		"CustomObjectWindow"
		{
			#rules applying for Custom Object
			$dsWindow.Title = SetWindowTitle $UIString["LBL61"] $UIString["LBL62"] $Prop["_CustomObjectName"].Value
			if ($Prop["_CreateMode"].Value)
			{
				$Prop["_Category"].Value = $Prop["_CustomObjectDefName"].Value

				#region Quickstart
					$dsWindow.FindName("Categories").IsEnabled = $false
					$dsWindow.FindName("NumSchms").Visibility = "Collapsed"
					$Prop["_NumSchm"].Value = $Prop["_Category"].Value
				#endregion
			}
		}

		#region CustomObjectTermWindow-CatalogTermsTranslations
"CustomObjectTermWindow"
{
	IF ($Prop["_CreateMode"].Value -eq $true) 
	{
		$Prop["_Category"].Value = $Prop["_CustomObjectDefName"].Value

			$dsWindow.FindName("Categories").IsEnabled = $false
			$dsWindow.FindName("NumSchms").Visibility = "Collapsed"
			$Prop["_NumSchm"].Value = $Prop["_Category"].Value

		IF($Prop["_XLTN_IDENTNUMBER"]){ $Prop["_XLTN_IDENTNUMBER"].Value = $UIString["LBL27"]}
	}

	#region EditMode
	IF ($Prop["_EditMode"].Value -eq $true) 
	{
		#read existing classification elements
		$_classes = @()
		Try{ #likely not all properties are used...
			If ($Prop["_XLTN_SEGMENT"].Value.Length -gt 1){
				$_classes += $Prop["_XLTN_SEGMENT"].Value
				If ($Prop["_XLTN_MAINGROUP"].Value.Length -gt 1){
					$_classes += $Prop["_XLTN_MAINGROUP"].Value
					If ($Prop["_XLTN_GROUP"].Value.Length -gt 1){
						$_classes += $Prop["_XLTN_GROUP"].Value
						If ($Prop["_XLTN_SEGMENT"].Value.Length -gt 1){
							$_classes += $Prop["_XLTN_SUBGROUP"].Value
						}
					}
				}
			}
		}
		catch {}
	}
	#endregion EditMode
	mAddCoCombo -_CoName "Segment" -_classes $_classes #enables classification for catalog of terms
	# ToDo: createmode: activate last used classification
			
	} # objectterm Window
#endregion CatalogTermsTranslations-CustomObjectTermsWindow

	}
}

function SetWindowTitle($newFile, $editFile, $name)
{
	if ($Prop["_CreateMode"].Value)
    {
		$windowTitle = ($newFile)
	}
	elseif ($Prop["_EditMode"].Value)
	{
		$windowTitle = "$($editFile) - $($name)"
	}
	elseif ($Prop["_ReadOnly"].Value)
	{
		$windowTitle = "$($editFile) - $($name)$($UIString["LBL26"])"
	}
	return $windowTitle
}

function OnLogOn
{
	#Executed when User logs on Vault
	#$vaultUsername can be used to get the username, which is used in Vault on login
}
function OnLogOff
{
	#Executed when User logs off Vault
}

function GetTitleWindow
{
	$message = "Autodesk Data Standard - Create/Edit "+$Prop["_FileName"]
	return $message
}

#fired when the file selection changes
function OnTabContextChanged
{
	$xamlFile = [System.IO.Path]::GetFileName($VaultContext.UserControl.XamlFile)
	
	if ($VaultContext.SelectedObject.TypeId.SelectionContext -eq "FileMaster" -and $xamlFile -eq "CAD BOM.xaml")
	{
		$fileMasterId = $vaultContext.SelectedObject.Id
		$file = $vault.DocumentService.GetLatestFileByMasterId($fileMasterId)
		$global:_ExportFileName = $file.Name # added to export CSV or XML files
		$bom = @(GetFileBOM($file.id))
		$dsWindow.FindName("bomList").ItemsSource = $bom
	}
	if ($VaultContext.SelectedObject.TypeId.SelectionContext -eq "ItemMaster" -and $xamlFile -eq "Associated Files.xaml")
	{
		$items = $vault.ItemService.GetItemsByIds(@($vaultContext.SelectedObject.Id))
		$item = $items[0]
		$itemids = @($item.Id)
		$assocFiles = @(GetAssociatedFiles $itemids $([System.IO.Path]::GetDirectoryName($VaultContext.UserControl.XamlFile)))
		$dsWindow.FindName("AssoicatedFiles").ItemsSource = $assocFiles
	}
	#region Documentstructure Extension
		if ($VaultContext.SelectedObject.TypeId.SelectionContext -eq "FileMaster" -and $xamlFile -eq "DocumentStructure.xaml")
		{
			Add-Type -Path 'C:\ProgramData\Autodesk\Vault 2018\Extensions\DataStandard\Vault.Custom\addinVault\UsesWhereUsed.dll'
			$file = $vault.DocumentService.GetLatestFileByMasterId($vaultContext.SelectedObject.Id)
			$treeNode = New-Object UsesWhereUsed.TreeNode($file, $vaultConnection)
			$dsWindow.FindName("Uses").ItemsSource = @($treeNode)
			$dsWindow.FindName("Uses").add_SelectedItemChanged({
				mUwUsdChldrnClick
			})
			$dsWindow.FindName("WhereUsed").add_SelectedItemChanged({
				mUwUsdPrntClick
			})

		}
	#endregion documentstructure

	#region Joblist
		if ($VaultContext.SelectedObject.TypeId.SelectionContext -eq "FileMaster" -and $xamlFile -eq "Jobs.xaml") 
		{
			Try{
				$fileMasterId = $vaultContext.SelectedObject.Id
				$file = $vault.DocumentService.GetLatestFileByMasterId($fileMasterId)
				$m_JobData = @(mFileJobList($file.Name))
				$dsWindow.FindName("dtGrdJobs").ItemsSource = $m_JobData
				If ($m_JobData) { $dsWindow.FindName("txtJobQueue").Visibility = "Collapsed"}
			Else { $dsWindow.FindName("txtJobQueue").Visibility = "Visible"}
				}
			catch{
				$dsWindow.FindName("txtJobQueue").Visibility = "Collapsed"
				$dsWindow.FindName("txtJobQueue").Visibility = "Visible"
				$dsWindow.FindName("txtJobQueue").Text = "File selection disposed, contact your VDS Administrator"
			}
		}
	#endregion joblist

	#region Claim-ECO-Links
	if ($VaultContext.SelectedObject.TypeId.SelectionContext -eq "ChangeOrder" -and $xamlFile -eq "LinkedCustomObjects.xaml")
	{
		$mCoId = $VaultContext.SelectedObject.Id
		
		[System.Reflection.Assembly]::LoadFrom($Env:ProgramData + "\Autodesk\Vault 2018\Extensions\DataStandard" + '\Vault.Custom\addinVault\QuickstartUtilityLibrary.dll')
		$_mVltHelpers = New-Object QuickstartUtilityLibrary.VltHelpers

		#to get links of COs to CUSTENT we need to analyse the CUSTENTS for linked children of type CO
		#get all CUSTENTS of category $_CoName first, then iterate the result and analyse each items links: do they link to the current CO id?
        $_CoName = $UIString["ADSK-ClaimMgr-00"]
		$_allCustents = mgetCustomEntityList $_CoName
		$_LinkedCustentIDs = @()
		Foreach ($_Custent in $_allCustents)
		{
			$_AllLinks1 = $_mVltHelpers.mGetLinkedChildren1($vaultConnection, $_Custent.Id, "CUSTENT", "CO")
			If($_AllLinks1) #the current custent has links; check that the current ECO is one of these link's target
			{
				$_match = $_AllLinks1 | Where { $_ -eq $mCoId }
				If($_match){ $_LinkedCustentIDs += $_Custent.Id}
			}		
		}
		#get all detail information of $_LinkedCustentIDs and push to the datagrid

		If($_LinkedCustentIDs.Count -ne 0)
		{
			$_LinkedCustentsMeta = @(mGetAssocCustents $_LinkedCustentIDs)
		}
		$dsWindow.FindName("dataGrdLinks").ItemsSource = $_LinkedCustentsMeta
		$dsWindow.FindName("dataGrdLinks").add_SelectionChanged({
			$dsWindow.FindName("txtComments").Text = $dsWindow.FindName("dataGrdLinks").SelectedItem.Comments
		})
	}
	#endregion

	#region derivation tree
	if ($VaultContext.SelectedObject.TypeId.SelectionContext -eq "FileMaster" -and $xamlFile -eq "Derivation Tree.xaml")
	{
		mDerivativesSelectNothing
		$fileMasterId = $vaultContext.SelectedObject.Id
		$file = $vault.DocumentService.GetLatestFileByMasterId($fileMasterId)

		$mDerivativesSource = @(mGetDerivativeSource($file)) #querying all file versions (historical) of the source
		if($mDerivativesSource.Count -eq 0) { 
			$dsWindow.FindName("mDerivatives").Visibility = "Collapsed"
			$dsWindow.FindName("txtBlck_Notification1").Text = $UIString["DerivationTree_13"]
			$dsWindow.FindName("txtBlck_Notification1").Visibility = "Visible"
			$dsWindow.FindName("SourceTree").IsExpanded = $false
			mDerivativesSelectNothing
		}
		Else{
			$dsWindow.FindName("mDerivatives").ItemsSource = $mDerivativesSource
			$dsWindow.FindName("mDerivatives").Visibility = "Visible"
			$dsWindow.FindName("SourceTree").IsExpanded = $true
			
		}
		$dsWindow.FindName("mDerivatives").add_SelectionChanged({
				mDerivativesClick
			})

		$mDerivativesParallels = @(mGetDerivativeParallels($file)) #querying all file versions (historical) of the source
		if($mDerivativesParallels.Count -eq 0) { 
			$dsWindow.FindName("mDerivatives1").Visibility = "Collapsed"
			$dsWindow.FindName("txtBlck_Notification2").Text = $UIString["DerivationTree_14"]
			$dsWindow.FindName("txtBlck_Notification2").Visibility = "Visible"
			$dsWindow.FindName("ParallelsTree").IsExpanded = $false
			mDerivativesSelectNothing
		}
		Else{
			$dsWindow.FindName("mDerivatives1").ItemsSource = $mDerivativesParallels
			$dsWindow.FindName("mDerivatives1").Visibility = "Visible"
			$dsWindow.FindName("ParallelsTree").IsExpanded = $true
			
		}
		$dsWindow.FindName("mDerivatives1").add_SelectionChanged({
				mDerivatives1Click
			})
		$mDerivativesCopies = @(mGetDerivativeCopies($file)) #querying all file versions (historical) of the source
		if($mDerivativesCopies.Count -eq 0) { 
			$dsWindow.FindName("mDerivatives2").Visibility = "Collapsed"
			$dsWindow.FindName("txtBlck_Notification3").Text = $UIString["DerivationTree_15"]
			$dsWindow.FindName("txtBlck_Notification3").Visibility = "Visible"
			$dsWindow.FindName("DerivedTree").IsExpanded = $false
			mDerivativesSelectNothing
		}
		Else{
			$dsWindow.FindName("mDerivatives2").ItemsSource = $mDerivativesCopies
			$dsWindow.FindName("mDerivatives2").Visibility = "Visible"
			$dsWindow.FindName("DerivedTree").IsExpanded = $true
			
		}
		$dsWindow.FindName("mDerivatives2").add_SelectionChanged({
				mDerivatives2Click
			})
	}
	#endregion derivation tree

	#region ItemTab-FileImport
	if ($VaultContext.SelectedObject.TypeId.SelectionContext -eq "ItemMaster" -and $xamlFile -eq "FileImport.xaml")
		{
			$items = $vault.ItemService.GetItemsByIds(@($vaultContext.SelectedObject.Id))
			$item = $items[0]
		
			If (!$item.Locked)
			{
				$dsWindow.FindName("mDragAreaEnabled").Source = "C:\ProgramData\Autodesk\Vault 2018\Extensions\DataStandard\Vault.Custom\Configuration\Item\DragFilesActive.png"
				$dsWindow.FindName("mDragAreaEnabled").Visibility = "Visible"
				$dsWindow.FindName("mDragAreaDisabled").Visibility = "Collapsed"
				$dsWindow.FindName("txtActionInfo").Visibility = "Visible"
			}
			Else
			{
				$dsWindow.FindName("mDragAreaDisabled").Source = "C:\ProgramData\Autodesk\Vault 2018\Extensions\DataStandard\Vault.Custom\Configuration\Item\DragFilesLocked.png"
				$dsWindow.FindName("mDragAreaDisabled").Visibility = "Visible"
				$dsWindow.FindName("mDragAreaEnabled").Visibility = "Collapsed"
				$dsWindow.FindName("txtActionInfo").Visibility = "Collapsed"
			}

			Try{
				Import-Module powerVault
			}
			catch{
			   [System.Windows.MessageBox]::Show("This feature requires powerVault installed; check for its availability", "Extension Title")
			   return
			}

			$dsWindow.FindName("mImportProgress").Value = 0
			$dsWindow.FindName("mDragAreaEnabled").add_Drop({			
				param( $sender, $e)
				$items = $vault.ItemService.GetItemsByIds(@($vaultContext.SelectedObject.Id))
				$item = $items[0]

				#check that the item is editable for the current user, if not, we shouldn't add the files, before we try to attach
				try{
					$vault.ItemService.EditItems(@($item.RevId))
					#[System.Windows.MessageBox]::Show("Item is accessible", "Item-File Attachment Import")
					$_ItemIsEditable = $true
				}
				catch {
					#[System.Windows.MessageBox]::Show("Item is NOT accessible", "Item-File Attachment Import")
					$_ItemIsEditable = $false
				}
				If($_ItemIsEditable)
				{
					$vault.ItemService.UndoEditItems(@($item.RevId))
					$vault.ItemService.DeleteUncommittedItems($true)
					#[System.Windows.MessageBox]::Show("Item Lock Removed to continue", "Item-File Attachment Import")
				}
			
				[System.Windows.DataObject]$mDragData = $e.Data
				$mFileList = $mDragData.GetFileDropList()
				#Filter folders, we attach files directly selected only
				$mFileList = $mFileList | Where { (get-item $_).PSIsContainer -eq $false }
				If ($mFileList -and $_ItemIsEditable)
				{
					$dsWindow.Cursor = "Wait"
					$_NumFiles = $mFileList.Count
					$_n = 0
					$dsWindow.FindName("mImportProgress").Value = 0
					$mExtExclude = @(".ipt", ".iam", ".ipn", ".dwg", ".idw", ".slddrw", ".sldprt", ".sldasm")
					$m_ImpFileList = @() #filepath array of imported files to be attached
					ForEach ($_file in $mFileList)
					{
						$m_FileName = [System.IO.Path]::GetFileNameWithoutExtension($_file)
						$m_Ext = [System.IO.Path]::GetExtension($_file)
						If ($mExtExclude -contains $m_Ext){
							$mCADWarning = $true
							break;
						}
						$m_Dir = [System.IO.Path]::GetDirectoryName($_file)
					
						#get new number and create new file name
						[System.Collections.ArrayList]$numSchems = @($vault.DocumentService.GetNumberingSchemesByType('Activated'))
						if ($numSchems.Count -gt 1)
						{							
							$_DfltNumSchm = $numSchems | Where { $_.Name -eq $UIString["ADSK-ItemFileImport_00"]}
							if($_DfltNumSchm)
							{
								$NumGenArgs = @("")
								$_newFile=$vault.DocumentService.GenerateFileNumber($_DfltNumSchm.SchmID, $NumGenArgs)
							}		
						}

						#add file
						If($_newFile)
						{
							#get appropriate folder number (limit 1k files per folder)
							Try{
								$mTargetPath = mGetFolderNumber $_newFile 3 #hand over the file number (name) and number of files / folder
							}
							catch { 
								[System.Windows.MessageBox]::Show($UIString["ADSK-ItemFileImport_01"], "Item-File Attachment Import")
							}
							#add extension to number
							$_newFile = $_newFile + $m_Ext
							$mFullTargetPath = $mTargetPath + $_newFile
							$m_ImportedFile = Add-VaultFile -From $_file -To $mFullTargetPath -Comment $UIString["ADSK-ItemFileImport_02"]
							$m_ImpFileList += $m_ImportedFile._FullPath
						}
						Else #continue with the given file name
						{
							$mTargetPath = "$/xDMS/"
							$mFullTargetPath = $mTargetPath + $m_FileName
							$m_ImportedFile = Add-VaultFile -From $_file -To $mFullTargetPath -Comment $UIString["ADSK-ItemFileImport_02"]
							$m_ImpFileList += $m_ImportedFile._FullPath
						}
						$_n += 1
						$dsWindow.FindName("mImportProgress").Value = (($_n/$_NumFiles)*100)-10

					} #for each file
					#attach file to current item
					$parent = Get-VaultItem -Number $item.ItemNum	
					$parentUpdated = Update-VaultItem -Number $parent._Number -AddAttachments $m_ImpFileList -Comment $UIString["ADSK-ItemFileImport_03"]
					$dsWindow.FindName("mImportProgress").Value = (($_n/$_NumFiles)*100)
					If ($mCADWarning)
					{
						[System.Windows.MessageBox]::Show($UIString["ADSK-ItemFileImport_04"], "Item-File Attachment Import")
					}
				}
				$mFileList = $null
				$dsWindow.Cursor = "Arrow"
				$dsWindow.FindName("mDragAreaEnabled").remove_Drop()
				}) #end drag & drop
		}
	#endregion ItemTab-FileImport
}

function GetNewCustomObjectName
{
	$dsDiag.Trace(">> GetNewCustomObjectName")

	#region Quickstart
		$m_Cat = $Prop["_Category"].Value
		switch ($m_Cat)
		{
			$UIString["ClassTerms_00"] #CatalogTermsTranslations
			{
				if($dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty -eq $false)
				{
					$Prop["_XLTN_IDENTNUMBER"].Value = $Prop["_GeneratedNumber"].Value
				}
				$customObjectName = $Prop["_XLTN_TERM"].Value

				return $customObjectName
			}

			$UIString["MSDCE_CO02"] #Person
			{
				if($dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty -eq $false)
				{
					$Prop["_XLTN_IDENTNUMBER"].Value = $Prop["_GeneratedNumber"].Value
				}
				$customObjectName = $Prop["_XLTN_FIRSTNAME"].Value + " " + $Prop["_XLTN_LASTNAME"].Value
				return $customObjectName
			}

			"Werksnorm" {
				if($dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty -eq $false)
				{
					$Prop["Werksnorm"].Value = $Prop["_GeneratedNumber"].Value
				}
				$customObjectName = $Prop["Werksnorm"].Value
				return $customObjectName
			}

			#region Claim-ECO-Link
			$UIString["ADSK-ClaimMgr-00"] {
				if($dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty -eq $false)
				{
					$customObjectName = $Prop["_GeneratedNumber"].Value
				}
				Else { $customObjectName = $dsWindow.FindName("CUSTOMOBJECTNAME").Text}
				return $customObjectName
			}
			#endregion claim-ECO-Link

			Default 
			{
				#$dsDiag.Trace("-- GetNewObjectName Default = all categories ---")
				if($dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty -eq $false)
				{
					if($Prop["_XLTN_IDENTNUMBER"]){ $Prop["_XLTN_IDENTNUMBER"].Value = $Prop["_GeneratedNumber"].Value}
				}
				$customObjectName = $dsWindow.FindName("CUSTOMOBJECTNAME").Text
				#$dsDiag.Trace("--- txtName returns $customObjectName ") 
				IF ($customObjectName -eq "") 
				{ 
					$customObjectName = $Prop["_XLTN_TITLE"].Value
					#$dsDiag.Trace("--- Title gets the new object name") 
				}
				#$dsDiag.Trace("--- GetNewCustomObjectName returns $customObjectName") 
				return $customObjectName
			}
		}
}

#Constructs the filename(numschems based or handtyped)and returns it.
function GetNewFileName
{
	$dsDiag.Trace(">> GetNewFileName")
	if($dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
	{	
		$dsDiag.Trace("read text from TextBox FILENAME")
		$fileName = $dsWindow.FindName("FILENAME").Text
		$dsDiag.Trace("fileName = $fileName")
	}
	else{
		#$dsDiag.Trace("-> GenerateNumber")
		$fileName = $Prop["_GeneratedNumber"].Value
		#$dsDiag.Trace("fileName = $fileName")
		#Quickstart
			If($Prop["_XLTN_PARTNUMBER"]) { $Prop["_XLTN_PARTNUMBER"].Value = $Prop["_GeneratedNumber"].Value }
		#Quickstart
	}
	$newfileName = $fileName + $Prop["_FileExt"].Value
	$dsDiag.Trace("<< GetNewFileName $newfileName")
	return $newfileName
}

function GetNewFolderName
{
	$dsDiag.Trace(">> GetNewFolderName")
	if($dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
	{	
		$dsDiag.Trace("read text from TextBox FOLDERNAME")
		$folderName = $dsWindow.FindName("FOLDERNAME").Text
		$dsDiag.Trace("folderName = $folderName")
	}
	else{
		$dsDiag.Trace("-> GenerateNumber")
		$folderName = $Prop["_GeneratedNumber"].Value
		$dsDiag.Trace("folderName = $folderName")
	}
	$dsDiag.Trace("<< GetNewFolderName $folderName")
	return $folderName
}

# This function can be used to force a specific folder when using "New Standard File" or "New Standard Folder" functions.
# If an empty string is returned the selected folder is used
# ! Do not remove the function
function GetParentFolderName
{
	$folderName = ""
	return $folderName
}

function GetCategories
{
	if ($dsWindow.Name -eq "FileWindow")
	{
		#return $vault.CategoryService.GetCategoriesByEntityClassId("FILE", $true)
		#region quickstart
			$global:mFileCategories = $vault.CategoryService.GetCategoriesByEntityClassId("FILE", $true)
			return $global:mFileCategories
		#endregion
	}
	elseif ($dsWindow.Name -eq "FolderWindow")
	{
		return $vault.CategoryService.GetCategoriesByEntityClassId("FLDR", $true)
	}
	elseif ($dsWindow.Name -eq "CustomObjectWindow")
	{
		return $vault.CategoryService.GetCategoriesByEntityClassId("CUSTENT", $true)
	}
	elseif ($dsWindow.Name -eq "CustomObjectTermWindow")
	{
		return $vault.CategoryService.GetCategoriesByEntityClassId("CUSTENT", $true)
	}
}

function GetNumSchms
{
	if ($Prop["_CreateMode"].Value)
	{
		try
		{
			[System.Collections.ArrayList]$numSchems = @($vault.DocumentService.GetNumberingSchemesByType('Activated'))
			if ($numSchems.Count -gt 1)
			{
					$mWindowName = $dsWindow.Name
					switch($mWindowName)
					{
						"FileWindow"
						{
							$numSchems = $numSchems | Sort-Object -Property IsDflt -Descending
							
							#region	InheritProjectIdToFile
									$_Templist = @()
									$_Templist += $numSchems |? { $_.Name -eq "Projekt-Dokument-Nr"} #toDo: adopt custom name of numbering scheme used					
									IF ($_Templist.Count -gt 0) {
										#only if a parent project is found
										$_ProjectID = mGetParentProjectId
										If ($_ProjectID)
										{
											#$dsWindow.FindName("NumSchms").SelectedIndex = 0
											$_Templist[0].FieldArray[0].DfltVal = $_ProjectID
											$numSchems = $_Templist
										}
									}
							#endregion InheritProjectIdToFile
							
							return $numSchems
						}

						"FolderWindow" 
						{
							#numbering schemes are available for items and files specificly; 
							#for folders we use the file numbering schemes and filter to these, that have a corresponding name in folder categories
							$_FolderCats = $vault.CategoryService.GetCategoriesByEntityClassId("FLDR", $true)
							$_FilteredNumSchems = @()
							Foreach ($item in $_FolderCats) 
							{
								$_temp = $numSchems | Where { $_.Name -eq $item.Name}
								$_FilteredNumSchems += ($_temp)
							}
							#we need an option to unselect a previosly selected numbering; to achieve that we add a virtual one, named "None"
							$noneNumSchm = New-Object 'Autodesk.Connectivity.WebServices.NumSchm'
							$noneNumSchm.Name = "None"
							$_FilteredNumSchems += ($noneNumSchm)

							return $_FilteredNumSchems
						}

						"CustomObjectWindow"
						{
							$_FilteredNumSchems = $numSchems | Where { $_.Name -eq $Prop["_Category"].Value}
							return $_FilteredNumSchems
						}
						"CustomObjectWindow"
						{
							$_FilteredNumSchems = $numSchems | Where { $_.Name -eq $Prop["_Category"].Value}
							return $_FilteredNumSchems
						}
						default
						{
							$numSchems = $numSchems | Sort-Object -Property IsDflt -Descending
							return $numSchems
						}
					}
			}
			Else {
				$dsWindow.FindName("NumSchms").IsEnabled = $false
			}
			return $numSchems
		}
		catch [System.Exception]
		{		
			#[System.Windows.MessageBox]::Show($error)
		}
	}
}


# Decides if the NumSchmes field should be visible
function IsVisibleNumSchems
{
	$ret = "Collapsed"
	$numSchems = $vault.DocumentService.GetNumberingSchemesByType([Autodesk.Connectivity.WebServices.NumSchmType]::Activated)
	if($numSchems.Length -gt 0)
	{	$ret = "Visible" }
	return $ret
}

#Decides if the FileName should be enabled, it should only when the NumSchmField isnt
function ShouldEnableFileName
{
	$ret = "true"
	$numSchems = $vault.DocumentService.GetNumberingSchemesByType([Autodesk.Connectivity.WebServices.NumSchmType]::Activated)
	if($numSchems.Length -gt 0)
	{	$ret = "false" }
	return $ret
}

function ShouldEnableNumSchms
{
	$ret = "false"
	$numSchems = $vault.DocumentService.GetNumberingSchemesByType([Autodesk.Connectivity.WebServices.NumSchmType]::Activated)
	if($numSchems.Length -gt 0)
	{	$ret = "true" }
	return $ret
}

#define the parametrisation for the number generator here
function GenerateNumber
{
	#$dsDiag.Trace(">> GenerateNumber")
	#$selected = $dsWindow.FindName("NumSchms").Text
	#if($selected -eq "") { return "na" }

	#$ns = $global:numSchems | Where-Object { $_.Name.Equals($selected) }
	#switch ($selected) {
	#	"Sequential" { $NumGenArgs = @(""); break; }
	#	default      { $NumGenArgs = @(""); break; }
	#}
	#$dsDiag.Trace("GenerateFileNumber($($ns.SchmID), $NumGenArgs)")
	#$vault.DocumentService.GenerateFileNumber($ns.SchmID, $NumGenArgs)
	#$dsDiag.Trace("<< GenerateNumber")
}

#define here how the numbering preview should look like
function GetNumberPreview
{
	#$selected = $dsWindow.FindName("NumSchms").Text
	#switch ($selected) {
	#	"Sequential" { $Prop["_FileName"].Value="???????"; break; }
	#	"Short" { $Prop["_FileName"].Value=$Prop["Project"].Value + "-?????"; break; }
	#	"Long" { $Prop["_FileName"].Value=$Prop["Project"].Value + "." + $Prop["Material"].Value + "-?????"; break; }
	#	default { $Prop["_FileName"].Value="NA" }
	#}
}

#Workaround for Property names containing round brackets
#Xaml fails to parse
function ItemTitle
{
    if ($Prop)
	{
       $val = $Prop["_XLTN_TITLE_ITEM_CO"].Value
	   return $val
    }
}

#Workaround for Property names containing round brackets
#Xaml fails to parse
function ItemDescription
{
	if($Prop)#Tab gets loaded before the SelectionChanged event gets fired resulting with null Prop. Happens when the vault is started with Change Order as the last view.
    {
       $val = $Prop["_XLTN_DESCRIPTION_ITEM_CO"].Value
	   return $val
    }
}

#region Quickstart 
function m_TemplateChanged {
	$dsDiag.Trace(">> Template Changed ...")
	$mContext = $dsWindow.DataContext
	$mTemplatePath = $mContext.TemplatePath
	#region workaround to block a selected template
	$global:_tcCounter += 1
	If($global:_tcCounter -eq 2)
	{
		
	}
	#endregion workaround to block a selected template
	$mTemplateFile = $mContext.SelectedTemplate
	$mTemplate = $mTemplatePath + "/" + $mTemplateFile
	$mFolder = $vault.DocumentService.GetFolderByPath($mTemplatePath)
	$mFiles = $vault.DocumentService.GetLatestFilesByFolderId($mFolder.Id,$false)
	$mTemplateFile = $mFiles | Where-Object { $_.Name -eq $mTemplateFile }
	$Prop["_Category"].Value = $mTemplateFile.Cat.CatName
	$mCatName = $mTemplateFile.Cat.CatName
	$dsWindow.FindName("Categories").SelectedValue = $mCatName
	If ($mCatName) #if something went wrong the user should be able to select a category
	{
		$dsWindow.FindName("Categories").IsEnabled = $false #comment out this line if admins like to release the choice to the user
	}
	$dsDiag.Trace(" ... TemplateChanged finished <<")
}

function m_CategoryChanged 
{
	$mWindowName = $dsWindow.Name
    switch($mWindowName)
	{
		"FileWindow"
		{
			#Quickstart uses the default numbering scheme for files; GoTo GetNumSchms function to disable this filter incase you'd like to apply numbering per category for files as well
			#$dsWindow.FindName("TemplateCB").add_SelectionChanged({
			#	#m_TemplateChanged
			#})
			$Prop['_XLTN_AUTHOR'].Value = $VaultConnection.UserName
			
			$Prop["_NumSchm"].Value = $Prop["_Category"].Value
			IF ($dsWindow.FindName("DSNumSchmsCtrl").Scheme.Name -eq $Prop["_Category"].Value) 
			{
				$dsWindow.FindName("NumSchms").SelectedValue = $Prop["_Category"].Value
				$dsWindow.FindName("NumSchms").IsEnabled = $false
			}
			Else
			{
				$dsWindow.FindName("NumSchms").SelectedIndex = 0
				$dsWindow.FindName("NumSchms").IsEnabled = $false
			}
		}

		"FolderWindow" 
		{
			$dsWindow.FindName("NumSchms").SelectedItem = $null
			$dsWindow.FindName("NumSchms").Visibility = "Collapsed"
			$dsWindow.FindName("DSNumSchmsCtrl").Visibility = "Collapsed"
			$dsWindow.FindName("FOLDERNAME").Visibility = "Visible"
					
			$Prop["_NumSchm"].Value = $Prop["_Category"].Value
			IF ($dsWindow.FindName("DSNumSchmsCtrl").Scheme.Name -eq $Prop["_Category"].Value) 
			{
				$dsWindow.FindName("DSNumSchmsCtrl").Visibility = "Visible"
				$dsWindow.FindName("FOLDERNAME").Visibility = "Collapsed"
			}
			Else
			{
				$Prop["_NumSchm"].Value = "None" #we need to reset in case a user switches back from existing numbering scheme to manual input
			}
			
			#set the start date = today for project category
			If ($Prop["_Category"].Value -eq $UIString["CAT6"] -and $Prop["_XLTN_DATESTART"] )		
			{
				$Prop["_XLTN_DATESTART"].Value = Get-Date -displayhint date
			}

			#region link tab
			#initialize the link tab for project category
			If ($Prop["_Category"].Value -eq $UIString["CAT6"])
			{
				$dsWindow.FindName("tabFldLinks").Visibility = "Visible"
				mGetCustents # located in ProjectOrganisationLink.ps1
				$dsWindow.FindName("cmbOrganisation").ItemsSource = mGetOrganisations
				If ($dsWindow.FindName("cmbOrganisation").Items.Count -gt 1) { $dsWindow.FindName("cmbOrganisation").IsDropDownOpen = $true  }
			}
			Else 
			{
				$dsWindow.FindName("tabFldLinks").Visibility = "Collapsed"
			}
			#endregion
		}

		"CustomObjectWindow"
		{
			#categories are bound to CO type name
		}
		default
		{
			#nothing for 'unknown' new window type names
		}			
	} #end switch window
} #end function m_CategoryChanged


function mGetParentProjectId
{
			$mProjectFound = $false
			$mPath = $Prop["_FilePath"].Value #the selected folder, where the New File... command started
			$mFld = $vault.DocumentService.GetFolderByPath($mPath)

			IF ($mFld.Cat.CatName -eq $UIString["CAT6"]) { $mProjectFound = $true} #CAT6: localization string for folder category project
			Else {
				Do {
					$mParID = $mFld.ParID
					$mFld = $vault.DocumentService.GetFolderByID($mParID)
					IF ($mFld.Cat.CatName -eq $UIString["CAT6"]) { $mProjectFound = $true}
				} Until (($mFld.Cat.CatName -eq $UIString["CAT6"]) -or ($mFld.FullName -eq "$"))
			}

			If ($mProjectFound -eq $true) 
			{
				$mProjectID = mGetFolderPropValue $mFld.Id $UIString["LBL19"] #toDo: adopt custom field name containing project number, if not the folder's name equals 
				return $mProjectID
			} 
}


function mHelp ([Int] $mHContext) {
	Try
	{
		Switch ($mHContext){
			500 {
				$mHPage = "V.2File.html";
			}
			550 {
				$mHPage = "V.3OfficeFile.html";
			}
			600 {
				$mHPage = "V.1Folder.html";
			}
			700 {
				$mHPage = "V.6CustomObject.html";
			}
			Default {
				$mHPage = "Index.html";
			}
		}
		$mHelpTarget = "C:\ProgramData\Autodesk\Vault 2018\Extensions\DataStandard\HelpFiles\"+$mHPage
		$mhelpfile = Invoke-Item $mHelpTarget 
	}
	Catch
	{
		[System.Windows.MessageBox]::Show("Help Target not found", "Vault Quickstart Client")
	}
}

#endregion quickstart


#region CAD-BOMExportToCsvOrXML
function mExportCSV ()
{
	$_Data = $dsWindow.FindName("bomList").Items
	$_FileNameArray = $global:_ExportFileName.Split(".")
	$_FileExt = "." + $_FileNameArray[$_FileNameArray.Count-1]
	$_FileName = $global:_ExportFileName.Replace($_FileExt, "")
	$mWf = $env:USERPROFILE + "\Downloads\"
	$_ExportPath = mSetFileName $mWf $_FileName "Excel/Text/CSV (*.csv)| *.csv"
	If($_ExportPath){
		$_Data.SourceCollection | Export-CSV -Path $_ExportPath -UseCulture -Encoding UTF8 -NoTypeInformation
	}
}

function mExportXML ()
{
	$_Data = $dsWindow.FindName("bomList").Items
	$_FileNameArray = $global:_ExportFileName.Split(".")
	$_FileExt = "." + $_FileNameArray[$_FileNameArray.Count-1]
	$_FileName = $global:_ExportFileName.Replace($_FileExt, "")
	$mWf = $env:USERPROFILE + "\Downloads\"
	$_ExportPath = mSetFileName $mWf $_FileName "XML-File (*.xml)| *.xml"
	If($_ExportPath){
		$mXmlBOM = [XML]($_Data.SourceCollection | ConvertTo-XML -NoTypeInformation)
		$mXmlBOM.Save($_ExportPath)
	}
}

function mSetFileName($initialDirectory, $mFileName, $mFileType)
{
	$SaveFileDialog = New-Object windows.forms.savefiledialog   
    $SaveFileDialog.initialDirectory = $initialDirectory
    $SaveFileDialog.title = "Save File to Disk"   
    $SaveFileDialog.filter = $mFileType
	$SaveFileDialog.FileName = $mFileName 
    $result = $SaveFileDialog.ShowDialog()    
	if($result -eq "OK")    
	{    
        $SaveFileDialog.filename   
    } 
    else { Write-Host "File Save Dialog Cancelled!" -ForegroundColor Yellow}
	$SaveFileDialog.Dispose()#dispose as you are done.
}
#endregion CAD-BOMExportToCsvOrXML

function mItemLookUpClick
{
	$dsWindow.FindName("tabItemLookup").IsSelected = $true
}

function mResetTemplates
{
	$dsWindow.FindName("TemplateCB").ItemsSource = $dsWindow.DataContext.Templates
	#$dsWindow.FindName("btnTemplateReset").IsEnabled = $false
	$dsWindow.FindName("btnTemplateReset").Opacity = 0.3
}
