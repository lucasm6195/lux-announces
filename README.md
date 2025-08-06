# 📢 Lux Anuncios - Advanced Announcement System

A modern and feature-rich announcement system for FiveM servers using ESX framework. This resource allows players with specific job permissions to create and broadcast announcements with customizable categories, durations, and visibility settings.

## ✨ Features

### 🎯 Core Functionality
- **Job-based Permissions**: Only authorized jobs can create announcements
- **Real-time UI**: Modern, responsive interface with live preview
- **GPS Integration**: Players can mark announcement locations on their GPS
- **Sound Notifications**: Audio alerts when announcements are displayed
- **Smooth Animations**: Professional slide-in/out animations

### 🛠️ Customization Options
- **Categories System**: Optional custom categories with color coding
- **Duration Control**: Configurable announcement display duration (5-30 seconds)
- **Visibility Settings**: 
  - All players
  - Same job only
  - Specific job targeting
- **Multilingual Support**: Fully configurable text strings
- **Custom Styling**: Modern dark theme with customizable elements

### 🎨 User Interface
- **Live Preview**: Real-time preview of announcements before publishing
- **Character Counter**: 200 character limit with live counting
- **Color Picker**: Custom category colors with hex input
- **Responsive Design**: Works on different screen sizes
- **Accessibility**: Keyboard shortcuts (ESC to close, H to mark GPS)

## 📋 Requirements

- **ESX Framework**: Latest version
- **ox_lib**: For notifications and UI components
- **mysql-async**: For database operations (if needed)

## 🚀 Installation

1. **Download** the resource and place it in your `resources/[lsx]/` folder
2. **Add** the following line to your `server.cfg`:
   ```
   ensure lux-anuncios
   ```
3. **Configure** the resource by editing `config.lua`
4. **Restart** your server

## ⚙️ Configuration

### Basic Setup

Edit `config.lua` to customize the resource:

```lua
-- Command to create announcements
Config.Command = "createannounce"

-- Default duration of announcements (in seconds)
Config.DefaultDuration = 10

-- Enable/Disable features
Config.EnableCategories = true
Config.EnableDurationSelection = true
Config.EnableVisibilitySelection = true
```

### Job Configuration

Add jobs that can create announcements:

```lua
Config.Announces = {
    police = { 
        name = "LSPD", 
        image = "https://example.com/police-logo.png" 
    },
    ambulance = { 
        name = "EMS", 
        image = "https://example.com/ems-logo.png" 
    },
    mechanic = { 
        name = "Mechanic", 
        image = "https://example.com/mechanic-logo.png" 
    },
}
```

### Duration Options

Customize available duration options:

```lua
Config.DurationOptions = {
    { value = 5, text = "5 seconds" },
    { value = 10, text = "10 seconds" },
    { value = 15, text = "15 seconds" },
    { value = 20, text = "20 seconds" },
    { value = 30, text = "30 seconds" }
}
```

### Text Customization

All interface texts are configurable:

```lua
Config.Texts = {
    Interface = {
        CreateTitle = "Create Announcement",
        CreateSubtitle = "Publish your announcement for the entire city",
        ContentPlaceholder = "Write your announcement content here...",
        -- ... more text options
    },
    Notifications = {
        NoPermission = "You don't have permission to make announcements.",
        PublishSuccess = "Announcement%s published for %s.",
        -- ... more notification texts
    }
}
```

## 🎮 Usage

### For Players

1. **Open Interface**: Use the configured command (default: `/createannounce`)
2. **Write Content**: Enter your announcement text (max 200 characters)
3. **Set Options**: 
   - Choose duration (if enabled)
   - Select visibility (all, job, specific job)
   - Add category (if enabled)
4. **Preview**: Check the live preview on the right panel
5. **Publish**: Click "Publish Announcement" to broadcast

### For Administrators

1. **Configure Jobs**: Add job permissions in `config.lua`
2. **Customize Features**: Enable/disable categories, duration selection, etc.
3. **Modify Texts**: Change all interface texts to match your server language
4. **Set Defaults**: Configure default duration and other settings

## 🎯 Commands

| Command | Description | Permission |
|---------|-------------|------------|
| `/createannounce` | Open announcement creation interface | Configured jobs only |
| `/markGPS` | Mark last announcement location on GPS | All players |

## 🔧 Key Bindings

| Key | Action |
|-----|--------|
| `H` | Mark announcement location on GPS |
| `ESC` | Close announcement creation interface |
