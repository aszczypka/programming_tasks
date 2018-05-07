param( [string]$InFileName, [string]$OutFileName, [String]$WorksheetName )

$DisplayProgress = $true

Function Show-Progress{
	Param( 
		$record, 
		$totalRecords 
	)
	If ($DisplayProgress) {
		$percents = [math]::round((($record/$totalRecords) * 100), 0)
		Write-Progress -Activity:"Przetwarzam dane " -Status: "przetworzono  $record ze wszystkich $records rekordów ($percents%) " -PercentComplete: $percents
	}

	sleep 1 # Do wykasowania, tylko by pokazaæ progress 
}

Function Walk-Dir{
	Param(        
		$sheet, 
		[PSCustomOBject]$node, 
		[int]$level, 
		[int]$record, 
		[int]$totalRecords,
		[int]$totalColumns		 
	)	
	Show-Progress ($record-1) ($totalRecords-1)
	try{
		while( $record -le $totalRecords -and ![string]::IsNullOrEmpty($Sheet.Cells.Item($record, $level).Text)){		
			$newNode = [PSCustomOBject]@{
				id = $Sheet.Cells.Item($record, $totalColumns).Text 
				Name = $Sheet.Cells.Item($record, $level).Text
			}	
			$record += 1	
			if( ![string]::IsNullOrEmpty($Sheet.Cells.Item($record, $level+1).Text) -and $level+1 -lt $totalColumns ){
				Add-Member -InputObject $newNode  -MemberType NoteProperty -Name Nodes -Value @()
				$record=Walk-Dir $sheet $newNode ($level+1) $record $totalRecords $totalColumns		 		
			} 
			$node.nodes += $newNode
		}
	} catch {
		$ErrorMessage = $_.Exception.Message
		$FailedItem = $_.Exception.ItemName
	    	Write-Error "B³¹d odczytu danych z arkusza, komunikat: $ErrorMessage dla $FailedItem"
	    	Exit
	}

	return $record
}


Function Convert-ExcelSheet {
	Param (
		[String]$InFileName,
		[String]$OutFileName,
		[String]$WorksheetName
	)

	If ($InFileName -eq "") {	
		$commandName = $MyInvocation.MyCommand.Name
		Write-Host "U¿yj przynajmniej w formie:  powershell converter.ps1 [nazwa pliku xlsx]"
		Write-Host "albo  powershell converter.ps1 [nazwa pliku xlsx] [nazwa pliku json] [nazwa arkusza]"
		exit
	}
	If (-not (Test-Path $InFileName)) {
		throw "Plik '$InFileName' nie istnieje."
		exit
	}




	if (-not $InFileName ) {
		$InFileName  = 'test1.xlsx'
	}
	if (-not $OutFileName ) {
		$OutFileName = [io.path]::GetFileNameWithoutExtension($InFileName) + ".json"
	}
	Write-Host "Konwersja z pliku $InFileName do $OutFileName"	

	$InFileName = Resolve-Path $InFileName

	try{
		$Excel = New-Object -com "Excel.Application"
		$Excel.Visible = $false
		$WorkBook = $Excel.WorkBooks.open($InFileName)

		if (-not $WorksheetName) {
			$Sheet = $WorkBook.ActiveSheet
			$WorksheetName = $Sheet.Name
			Write-Host "Arkusz nie okreslony, próbuje otworzyæ domyœlny: $WorksheetName"
		} else {
			$Sheet = $WorkBook.Sheets.Item($WorksheetName)
		}

		If (-not $Sheet) {
			Throw "Nie uda³o sie otworzyæ aruksza:  $WorksheetName"
			exit
		}

		$SheetName = $Sheet.Name
		$totalColumns = $Sheet.UsedRange.Columns.Count
		$totalRecords = $Sheet.UsedRange.Rows.Count
	} catch {
		$ErrorMessage = $_.Exception.Message
		$FailedItem = $_.Exception.ItemName
	    	Write-Error "B³¹d odczytu parametrów z pliku $OutFileName, komunikat: $ErrorMessage dla $FailedItem"
	    	Exit
	}

	Write-Host ("Dane w arkuszu $sheetName zawieraj¹ " + ($totalRecords-1) + " rekordów w " + ($totalColumns-1) + " poziomach!")

	$level=1;		
	$node = [PSCustomOBject]@{
		Name = 'root'	
		Nodes = @()
	}
	For ($record = 2; $record -le $totalRecords; ) {
		$record =  Walk-Dir $sheet $node $level $record $totalRecords $totalColumns
	}

	$WorkBook.Close()
	$Excel.Quit()
	
	try{
		$node | convertto-json -depth 100 | Out-File $OutFileName # normalnie maksymalna g³ebokoœc to 2
	}Catch {
		$ErrorMessage = $_.Exception.Message
		$FailedItem = $_.Exception.ItemName
	    	Write-Error "B³¹d odczytu parametrów z pliku $OutFileName, komunikat: $ErrorMessage dla $FailedItem"
	    	Exit
	}
	Write-Host "Gotowe"	
}

Convert-ExcelSheet $InFileName $OutFileName $WorksheetName 