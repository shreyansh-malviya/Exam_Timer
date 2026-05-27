# Load the WPF and Windows API assemblies
Add-Type -AssemblyName PresentationFramework

# Define the exam date and time (set this to your exam date)
$examDate = Get-Date "2025-01-22 00:00:00"

# Import necessary functions from user32.dll for click-through functionality
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class WinAPI {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern int SetWindowLong(IntPtr hWnd, IntPtr nIndex, int dwNewLong);
        [DllImport("user32.dll", SetLastError = true)]
        public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
        [DllImport("user32.dll")]
        public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);
        [DllImport("user32.dll")]
        public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
    }
"@

# Constants for window styles
$GWL_EXSTYLE = -20
$WS_EX_TRANSPARENT = 0x20
$WS_EX_LAYERED = 0x80000

# Create a new WPF window
$window = New-Object System.Windows.Window
$window.Title = "Exam Countdown Timer"
$window.Width = 255
$window.Height = 60
$window.Topmost = $true
$window.WindowStyle = 'None'
$window.ResizeMode = 'CanResizeWithGrip'
$window.AllowsTransparency = $true
$window.Background = [System.Windows.Media.Brushes]::Transparent
$window.ShowInTaskbar = $false
$window.ShowActivated = $false

# Set the initial position of the window to the upper-left corner
$window.Left = 0
$window.Top = 0

# Create a grid to hold the border and resize grip
$grid = New-Object System.Windows.Controls.Grid

# Create a semi-transparent border for the content
$border = New-Object System.Windows.Controls.Border
$border.Background = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromArgb(50, 0, 0, 0))
$border.BorderBrush = [System.Windows.Media.Brushes]::Gray  # Changed to gray for initial click-through state
$border.BorderThickness = 1
$border.CornerRadius = New-Object System.Windows.CornerRadius(10)
$border.Margin = 0

# Create a label for the countdown text
$countdownLabel = New-Object System.Windows.Controls.Label
$countdownLabel.HorizontalContentAlignment = 'Center'
$countdownLabel.VerticalContentAlignment = 'Center'
$countdownLabel.FontSize = 20
$countdownLabel.Foreground = [System.Windows.Media.Brushes]::White
$countdownLabel.Margin = '5'

# Add tooltip to show instructions
$border.ToolTip = "Press Alt+C to toggle click-through mode`nDrag window to move"

# Add the label to the border
$border.Child = $countdownLabel

# Add the border to the grid
$grid.Children.Add($border)

# Add the grid to the window
$window.Content = $grid

# Variable to track click-through state - Set to true initially
$script:isClickThrough = $true

# Function to toggle click-through mode
function Toggle-ClickThrough {
    $hwnd = [System.Windows.Interop.WindowInteropHelper]::new($window).Handle
    $currentStyle = [WinAPI]::GetWindowLong($hwnd, $GWL_EXSTYLE)
    
    if ($script:isClickThrough) {
        # Disable click-through
        [WinAPI]::SetWindowLong($hwnd, $GWL_EXSTYLE, $currentStyle -band -bnot $WS_EX_TRANSPARENT)
        $border.BorderBrush = [System.Windows.Media.Brushes]::White
        $script:isClickThrough = $false
    } else {
        # Enable click-through
        [WinAPI]::SetWindowLong($hwnd, $GWL_EXSTYLE, $currentStyle -bor $WS_EX_TRANSPARENT)
        $border.BorderBrush = [System.Windows.Media.Brushes]::Gray
        $script:isClickThrough = $true
    }
}

# Function to update the countdown
$updateCountdown = {
    $currentDate = Get-Date
    $timeRemaining = $examDate - $currentDate
    if ($timeRemaining.TotalSeconds -le 0) {
        $countdownLabel.Content = "Exam time!"
    } else {
        $days = $timeRemaining.Days
        $hours = $timeRemaining.Hours
        $minutes = $timeRemaining.Minutes
        $seconds = $timeRemaining.Seconds
        $countdownLabel.Content = "42C, $days D $hours H $minutes M $seconds S"
    }
}

# Create a timer to refresh the countdown
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(1)
$timer.add_Tick($updateCountdown)
$timer.Start()

# Handle window loaded event for initial setup
$window.Add_Loaded({
    # Register Alt+C hotkey
    $hwnd = [System.Windows.Interop.WindowInteropHelper]::new($window).Handle
    [WinAPI]::RegisterHotKey($hwnd, 9000, 0x0001, 0x43) # Alt + C
    
    # Enable click-through mode initially
    $currentStyle = [WinAPI]::GetWindowLong($hwnd, $GWL_EXSTYLE)
    [WinAPI]::SetWindowLong($hwnd, $GWL_EXSTYLE, $currentStyle -bor $WS_EX_TRANSPARENT)
})

# Handle window closing event
$window.Add_Closed({
    $hwnd = [System.Windows.Interop.WindowInteropHelper]::new($window).Handle
    [WinAPI]::UnregisterHotKey($hwnd, 9000)
})

# Handle hotkey press
$window.Add_SourceInitialized({
    $helper = New-Object System.Windows.Interop.WindowInteropHelper($window)
    $source = [System.Windows.Interop.HwndSource]::FromHwnd($helper.Handle)
    
    $source.AddHook({
        param($hwnd, $msg, $wParam, $lParam, $handled)
        
        if ($msg -eq 0x0312) { # WM_HOTKEY
            if ([int]$wParam -eq 9000) {
                Toggle-ClickThrough
                $handled = $true
            }
        }
    })
})

# Enable window dragging
$border.Add_MouseLeftButtonDown({
    if (-not $script:isClickThrough) {
        $window.DragMove()
    }
})

# Show the window
$window.ShowDialog()