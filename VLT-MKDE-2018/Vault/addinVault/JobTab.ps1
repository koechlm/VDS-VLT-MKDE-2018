Add-Type @"
public class mJobData
{
	public string CreateDate {get;set;}
	public string CreateUserName {get;set;}
	public string Description {get;set;}
	public string StatusCode {get;set;}
	public string StatusMsg {get;set;}
}
"@

function mFileJobList([STRING] $mFileName) {
	$mJobMaxCount = 100
	$mJobStartDate = Get-Date -Day 01 -Month 01 -Year 2010
	$mFileName = "*" + $mFileName +"*" 
	$mJobList = $vault.JobService.GetJobsByDate($mJobMaxCount, $mJobStartDate)

	$_TableData = @()
	foreach($mJob in $mJobList)
	{
		IF ($mJob.Descr -like $mFileName ) {
			$row = New-Object mJobData
			$row.CreateDate = $mJob.CreateDate
			$row.CreateUserName = $mJob.CreateUserName
			$row.Description = $mJob.Descr
			$row.StatusCode = $mJob.StatusCode
			$row.StatusMsg = $mJob.StatusMsg
			$_TableData += $row
		}
	}
	return $_TableData
}