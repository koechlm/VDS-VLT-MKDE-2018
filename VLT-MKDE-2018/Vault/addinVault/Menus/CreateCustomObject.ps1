#$vaultContext.ForceRefresh = $true
$selectionSet = $vaultContext.CurrentSelectionSet[0]
$id= $selectionSet.Id
$dialog = $dsCommands.GetCreateCustomObjectDialog($id)

$xamlFile = New-Object CreateObject.WPF.XamlFile "CustomObject.xaml", "%ProgramData%\Autodesk\Vault 2018\Extensions\DataStandard\Vault\Configuration\CustomObject.xaml"
$dialog.XamlFile = $xamlFile

$result = $dialog.Execute()
$dsDiag.Trace($result)

if ($result)
{
	$entityNumber = $dialog.CurrentEntity.Num
	$entityGuid = $selectionSet.TypeId.EntityClassSubType
	$selectionTypeId = New-Object Autodesk.Connectivity.Explorer.Extensibility.SelectionTypeId $entityGuid
	$location = New-Object Autodesk.Connectivity.Explorer.Extensibility.LocationContext $selectionTypeId, $entityNumber
	$vaultContext.GoToLocation = $location
}