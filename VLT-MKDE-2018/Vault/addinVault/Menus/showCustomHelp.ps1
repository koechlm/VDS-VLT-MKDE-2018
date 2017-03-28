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