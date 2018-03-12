$fileId=$vaultContext.CurrentSelectionSet[0].Id
$folderId = $vaultContext.NavSelectionSet[0].Id
$folder = $vault.DocumentService.GetFolderById($folderId)

#proceed only for ipt 
Import-Module powerVault
$mComp = Get-VaultFile -FileId $fileId

if($mComp._Extension -eq 'ipt')
{
	[System.Reflection.Assembly]::LoadFrom($Env:ProgramData + "\Autodesk\Vault 2018\Extensions\DataStandard" + '\Vault.Custom\addinVault\QuickstartUtilityLibrary.dll')
	$_mInvHelpers = New-Object QuickstartUtilityLibrary.InvHelpers
	$_mInvHelpers.
	$_mVaultHelpers = New-Object QuickstartUtilityLibrary.VltHelpers
	$mInventorApplication = $_mInvHelpers.m_InventorApplication()
	$mInvActiveDocFullFileName = $_mInvHelpers.m_ActiveDocFullFileName($mInventorApplication)
	$mInvActiveDoc = Get-Item -Path $mInvActiveDocFullFileName
	If(!$mInvActiveDoc -and $mInvActiveDoc.Extension -ne ".iam" ) #proceed only for active doc = assembly
	{
		[System.Windows.MessageBox]::Show("This command expects Inventor having an assembly file active!
			Did you save the assembly?" , "Insert CAD: Component Copy")
		return
	}
	
	$mNumSchms = $vault.DocumentService.GetNumberingSchemesByType([Autodesk.Connectivity.WebServices.NumSchmType]::ApplicationDefault)
	$mNs = $mNumSchms[0]
	$NumGenArgs = @("") #add arguments in case the default is not just a sequence
	$mNewFileNumber = $vault.DocumentService.GenerateFileNumber($mNs.SchmID, $NumGenArgs)

	$path = $mInvActiveDoc.Directory.FullName

	$mComp = Get-VaultFile -FileId $fileId -DownloadPath $path
	Set-ItemProperty -Path $mComp.LocalPath -Name IsReadOnly -Value $false
	$mCompCopy = Copy-Item ($mComp.LocalPath) -Destination ($path + '\' + $mNewFileNumber + '.' + $mComp._Extension) -PassThru
	if($mCompCopy) 
	{
		$_mInvHelpers.m_PlaceComponent($mInventorApplication, $mCompCopy.FullName)
	}

} #end if IPT
Else
{
	[System.Windows.MessageBox]::Show("Command supports Inventor part files only!" , "Insert CAD: Component Copy")
}