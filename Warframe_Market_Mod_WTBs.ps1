
#region File validations

if(!(Test-Path -Path "$PSScriptRoot\Log_Files" -PathType Container) ){
    New-Item -Path "$PSScriptRoot\Log_Files" -ItemType Directory
}

$Missing_Files = $false

if(!(Test-path -Path "$PSScriptRoot/CSV_Files" -PathType Container)){
    Write-Host "Missing source files for Syndicate Mods.`nPlease add the missing .CSV files to $PSScriptRoot/CSV_Files"
    $Missing_Files = $True
}

if(!(Test-path -Path "$PSScriptRoot/CSV_Files/Loka.csv" -PathType Leaf)){
    Write-Host "Missing source file for New Loka Syndicate Mods.`nPlease add the missing .CSV file to $PSScriptRoot/CSV_Files"
    $Missing_Files = $True
}

if(!(Test-path -Path "$PSScriptRoot/CSV_Files/Suda.csv" -PathType Leaf)){
    Write-Host "Missing source file for Cephalon Suda Syndicate Mods.`nPlease add the missing .CSV file to $PSScriptRoot/CSV_Files"
    $Missing_Files = $True
}

if(!(Test-path -Path "$PSScriptRoot/CSV_Files/Hexis.csv" -PathType Leaf)){
    Write-Host "Missing source file for Arbiters of Hexis Syndicate Mods.`nPlease add the missing .CSV file to $PSScriptRoot/CSV_Files"
    $Missing_Files = $True
}

if(!(Test-path -Path "$PSScriptRoot/CSV_Files/Veil.csv" -PathType Leaf)){
    Write-Host "Missing source file for Red Veil Syndicate Mods.`nPlease add the missing .CSV fils to $PSScriptRoot/CSV_Files"
    $Missing_Files = $True
}

if(!(Test-path -Path "$PSScriptRoot/CSV_Files/Perrin.csv" -PathType Leaf)){
    Write-Host "Missing source file for The Perrin Sequence Syndicate Mods.`nPlease add the missing .CSV file to $PSScriptRoot/CSV_Files"
    $Missing_Files = $True
}

if(!(Test-path -Path "$PSScriptRoot/CSV_Files/Meridian.csv" -PathType Leaf)){
    Write-Host "Missing source file for Steel Meridian Syndicate Mods.`nPlease add the missing .CSV file to $PSScriptRoot/CSV_Files"
    $Missing_Files = $True
}

if($Missing_Files) {
    pause
    Exit
}

#endregion

Write-Host "Please select the Syndicate's you want to check the mod sales on by inputting the digit next to them. Once you have selected all, Press enter to contine"
Write-Host "1. New Loka `n2. Cephalon Suda `n3. Arbiters of Hexis `n4. Red Veil `n5. The Perrin Sequence `n6. Steel Meridian"

$Syndicate_Mod_Lists = @()
$Syndicate_Selected = $false
$Loka = $false
$Suda = $false
$Hexis = $false
$Veil = $false
$Perrin = $false
$Meridian = $false

While(!$Syndicate_Selected) {
    $Syndicate_Input = Read-Host "Please enter a number or press enter to finish"
    switch ($Syndicate_Input)
    {
        '1' {
            if(!$Loka){$Syndicate_Mod_Lists += "$PSScriptRoot/CSV_Files/Loka.csv"; $Loka = $true }else{Write-Host "New Loka is allready selected. Please enter another number or press enter to finish"}
        }
        '2' {
            if(!$Suda){$Syndicate_Mod_Lists += "$PSScriptRoot/CSV_Files/Suda.csv"; $Suda = $true }else{Write-Host "Cephalon Suda is allready selected. Please enter another number or press enter to finish"}
        }
        '3' {
            if(!$Hexis){$Syndicate_Mod_Lists += "$PSScriptRoot/CSV_Files/Hexis.csv"; $Hexis = $true }else{Write-Host "Arbiters of Hexis is allready selected. Please enter another number or press enter to finish"}
        }
        '4' {
            if(!$Veil){$Syndicate_Mod_Lists += "$PSScriptRoot/CSV_Files/Veil.csv"; $Veil = $true }else{Write-Host "Red Veil is allready selected. Please enter another number or press enter to finish"}
        }
        '5' {
            if(!$Perrin){$Syndicate_Mod_Lists += "$PSScriptRoot/CSV_Files/Perrin.csv"; $Perrin = $true }else{Write-Host "The Perrin Sequence is allready selected. Please enter another number or press enter to finish"}
        }
        '6' {
            if(!$Meridian){$Syndicate_Mod_Lists += "$PSScriptRoot/CSV_Files/Meridian.csv"; $Meridian = $true }else{Write-Host "Steel Meridian is allready selected. Please enter another number or press enter to finish"}
        }
        '' {
            if($Syndicate_Mod_Lists.count -gt 0){$Syndicate_Selected = $true}else{Write-Host "Please select atleast 1 syndicate to continue"}
        }
        Default {Write-Host "Please input a number between 1 & 6 or press enter to finish"}
    }
}

$Minimum_Price_Selected = $false
$Minimum_Price = 0
While(!$Minimum_Price_Selected){
    
    $Minimum_Price_Input_Valid = [int]::TryParse((Read-Host 'Please input the minimum price you wish to see offers for'), [ref]$Minimum_Price)

    if($Minimum_Price_Input_Valid) { $Minimum_Price_Selected = $true;} else { Write-Host "Please input a number"}

}

$Filter_Online = $false
$Filter_Online_Input = Read-Host "Enter y to filter to online users only or press enter see all"
if($Filter_Online_Input.ToLower() -eq "y"){$Filter_Online = $true} 

$ModList = @()

Foreach($Link in $Syndicate_Mod_Lists) {
    $ModList += Import-Csv -Path $Link 
}

$Sorted_ModList = $ModList | select -Unique -Property Mod_Name

$Headers = @{
    'content-type' = 'application/json'
	'accept' = 'application/json'
	'platform' = 'pc'
	'language' = 'en'
}

$Querys = 0
$Total_Mods = $Sorted_ModList.Count
$Current_Mod = 1

$All_Buyers = @()

Foreach($Mod in $Sorted_ModList){

    $URI = "https://api.warframe.market/v1/items/$($Mod.Mod_Name)/orders?include=item".ToLower()
    
    if($Querys -ge 2) {
        sleep 1
        Write-Host "Too many Querys. Sleeping"
        $Querys = 0
    }

    Write-Host "Getting buyers for $($Mod.Mod_Name). $Current_Mod / $Total_Mods"
    $Current_Mod++

    $Orders = Invoke-RestMethod -Method Get -Headers $Headers -Uri $URI
    $Querys++

    $Buyers = @()

    Foreach ($order in $Orders.payload.orders){
        #$Order
        if($order.order_type.ToString() -eq "buy") {Write-Host "Found Buy";  $Buyers += $order}
    }

    $Valid_Buyers = @()

    Foreach($buy in $Buyers){
        if([int]$buy.platinum -ge $Minimum_Price){
        
        Write-Host "Found valid Price";

            if($Filter_Online){
                if($buy.user.status -eq "ingame" -or $buy.user.status -eq "online"){
                    Write-Host "Found Online Buyer"
                    $Valid_Buyers += $buy
                }
            }else{
                $Valid_Buyers += $buy
         
             }
         }
    }

    foreach($Valid_Buy in $Valid_Buyers) {
        $All_Buyers += [PSCustomObject]@{
            'Mod Name' = $Mod.Mod_Name
            'Price' = $Valid_Buy.platinum
            'Mod Rank' = $Valid_Buy.mod_rank
            'Username' = $Valid_Buy.user.ingame_name
            'Status' = $Valid_Buy.user.status
        } 
    }
}

$CurrentDateTime = Get-Date -Format "dd.MM.yyyyHH.mm".ToString()
$OutputPathCSV = "$PSScriptRoot\Log_Files\Buyers_List_$CurrentDateTime.csv"

$All_Buyers | Select 'Mod Name','Price','Mod Rank','Username','Status' | Export-Csv -Path $OutputPathCSV -NoTypeInformation