
Add-Type -Path 'C:\ProgramData\Autodesk\Vault 2018\Extensions\DataStandard\Vault\addinVault\UsesWhereUsed.dll'

function OnTabContextChanged_UsesWhereUsed
{
	$xamlFile = [System.IO.Path]::GetFileName($VaultContext.UserControl.XamlFile)
	if ($VaultContext.SelectedObject.TypeId.SelectionContext -eq "FileMaster" -and $xamlFile -eq "Uses - Where used.xaml")
	{
		$file = $vault.DocumentService.GetLatestFileByMasterId($vaultContext.SelectedObject.Id)
		$treeNode = New-Object UsesWhereUsed.TreeNode($file, $vaultConnection)
		$dsWindow.FindName("Uses").ItemsSource = @($treeNode)
	}
}