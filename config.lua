Config = {}

-- ========================================
-- GENERAL CONFIGURATION
-- ========================================

-- Command to create announcements
Config.Command = "createannounce"

-- Default duration of announcements (in seconds)
Config.DefaultDuration = 10

-- ========================================
-- DATABASE CONFIGURATION
-- ========================================

-- Jobs table name (change if your server uses a different table name)
Config.JobsTableName = "jobs"

-- Cache duration for jobs in milliseconds (5 minutes = 300000)
Config.JobsCacheDuration = 300000

-- ========================================
-- FEATURES CONFIGURATION
-- ========================================

-- Enable/Disable categories system
Config.EnableCategories = true

-- Enable/Disable duration selection
Config.EnableDurationSelection = true

-- Enable/Disable visibility selection
Config.EnableVisibilitySelection = true

-- Available duration options (only if EnableDurationSelection = true)
Config.DurationOptions = {
    { value = 5, text = "5 seconds" },
    { value = 10, text = "10 seconds" },
    { value = 15, text = "15 seconds" },
    { value = 20, text = "20 seconds" },
    { value = 30, text = "30 seconds" }
}

-- ========================================
-- CONFIGURABLE TEXTS
-- ========================================

Config.Texts = {
    -- Interface texts
    Interface = {
        CreateTitle = "Create Announcement",
        CreateSubtitle = "Publish your announcement for the entire city",
        JobPermissionsVerified = "Permissions verified",
        CategoryLabel = "Announcement Category (Optional)",
        CategoryNamePlaceholder = "Ex: My Business",
        CategoryColorLabel = "Color:",
        CategoryPreview = "Preview",
        ContentLabel = "Announcement Content",
        ContentPlaceholder = "Write your announcement content here...",
        DurationLabel = "Announcement Duration",
        VisibilityLabel = "Announcement Visibility",
        CancelButton = "Cancel",
        PublishButton = "Publish Announcement",
        PublishingButton = "Publishing...",
        PreviewTitle = "Preview",
        PreviewContent = "The announcement content will appear here...",
        DurationInfo = "Duration: %s",
        VisibilityAll = "Visible to everyone",
        VisibilityJob = "Only my team",
        GPSButtonText = "Mark on GPS"
    },
    
    -- Server notifications
    Notifications = {
        NoPermission = "You don't have permission to make announcements.",
        InsufficientRank = "Your rank is insufficient to create announcements.",
        NoContent = "You haven't entered content for the announcement.",
        PublishSuccess = "Announcement%s published for %s.",
        PublishSuccessWithCategory = " with category \"%s\"",
        VisibilityAll = "all players",
        VisibilityJob = "your work team",
        FilterUsage = "Usage: /filterannounce [category]",
        CategoryNotFound = "Category not found.",
        FilterApplied = "Filter applied: %s"
    },
    
    -- Client notifications (GPS)
    GPS = {
        AlreadyMarked = "You have already marked it on the GPS previously.",
        LocationMarked = "Location marked on GPS.",
        KeyMappingDescription = "Mark announcement location on GPS"
    }
}

-- ========================================
-- JOBS CONFIGURATION
-- ========================================

Config.Announces = {
    unemployed = { 
        name = "Autoexotic", 
        image = "https://vignette.wikia.nocookie.net/de.gta/images/5/5c/Auto-Exotic-Logo.png/revision/latest?cb=20160715173735",
        minGrade = 0
    },
    -- Add more jobs here following the format:
    -- jobname = { name = "Job Name", image = "Image_URL", minGrade = 0 },
    
    -- Examples:
    -- police = { 
    --     name = "LSPD", 
    --     image = "https://example.com/police-logo.png",
    --     minGrade = 2  -- Only sergeants and above can create announcements
    -- },
    -- ambulance = { 
    --     name = "EMS", 
    --     image = "https://example.com/ems-logo.png",
    --     minGrade = 1  -- Only paramedics and above
    -- },
    -- mechanic = { 
    --     name = "Mechanic", 
    --     image = "https://example.com/mechanic-logo.png",
    --     minGrade = 0  -- All ranks can create announcements
    -- },
}