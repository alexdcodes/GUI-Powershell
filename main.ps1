Add-Type -AssemblyName PresentationFramework

function Get-RestartEventLogs {
    param (
        $HostName = $HostNameBox.Text
    )
    if (Test-Connection $HostName -Quiet -Count 2) {
        try {
            $Logs = Get-EventLog -LogName System -Source user32 -ComputerName $HostName -Newest 10 -ErrorAction Stop
            foreach ($event in $logs) {
                $TempFileName = [System.IO.Path]::GetTempFileName()
                $event.Message | Out-File -FilePath $TempFileName
                $event | Select-Object UserName, TimeWritten, MachineName, @{N='Message'; E={(Get-Content -Path $TempFileName)[0]}}
                
            }
        }
        catch {
            [System.Windows.MessageBox]::Show("Cannot retrive event logs from your Host $HostName. Check permissions.", "Host unreachable")
        }
    }
    else {
        [System.Windows.MessageBox]::Show("Your Provided Host is not reachable.", "Host unreachable")
    }
}

[xml]$Form = @"
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Restart Log Applet - View Log Files" Height="390" Width="600" ResizeMode="NoResize">
    <Grid>
        <Label Name="ComputerLabel" Content="HOST or IP" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top" Height="30" Width="110"/>
        <Button Name="RestartLogsButton" Content="Restart Logs" HorizontalAlignment="Left" Margin="200,43,0,0" VerticalAlignment="Top" Width="126" RenderTransformOrigin="2,1.227"/>
        <Button Name="TestButton" Content="RDP Check" HorizontalAlignment="Left" Margin="90,43,0,0" VerticalAlignment="Top" Width="126" RenderTransformOrigin="2,1.227"/>
        <TextBox Name="HostNameBox" HorizontalAlignment="Left" Height="28" Margin="125,10,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="201" ToolTip="Type valid Computer name or IP address" AutomationProperties.HelpText="Type valid Computer name or IP address"/>
        <DataGrid Name="ResultDataGrid" HorizontalAlignment="Left" Margin="10,70,0,0" VerticalAlignment="Top" Height="257" Width="565"/>
        <TextBlock Name="Url" HorizontalAlignment="Left" Margin="206,331,0,0" TextWrapping="Wrap" Text="Edited by Alex Diker" VerticalAlignment="Top" Width="120"/>
    </Grid>
</Window>
"@

$XMLReader = (New-Object System.Xml.XmlNodeReader $Form)
$XMLForm = [Windows.Markup.XamlReader]::Load($XMLReader)

$HostNameBox = $XMLForm.FindName('HostNameBox')
$RestartLogsButton = $XMLForm.FindName('RestartLogsButton')
$TestButton = $XMLForm.FindName('TestButton') #Add Control for testing button
$ResultDataGrid = $XMLForm.FindName('ResultDataGrid')

$HostNameBox.Text = $env:COMPUTERNAME

$RestartEventList = New-Object System.Collections.ArrayList

$TestButton.add_click({
    reset session 65536 
    rwinsta 65536
    [System.Windows.MessageBox]::Show("would work with admin privs", "TEST")
})

$RestartLogsButton.add_click({
    if ($HostNameBox.Text -eq '') {
        [System.Windows.MessageBox]::Show("Text empty.", "Textbox empty")
    }

    $Events = Get-RestartEventLogs -ComputerName $HostNameBox.Text
    
    if ($Events -ne 'OK') {
        $RestartEventList.AddRange($Events)
        $ResultDataGrid.ItemsSource=@($RestartEventList)
    }
})

$XMLForm.ShowDialog()
