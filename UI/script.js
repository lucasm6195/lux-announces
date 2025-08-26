
let currentJobData = null
let selectedDuration = 10
let selectedVisibility = "all"
let customCategoryData = null
let categoryEnabled = false
let availableJobs = []
let config = null
let shareLocationEnabled = false
let anuncioTimeoutId = null
// Used to cancel previous announce timeout and avoid hiding new announce too early

window.addEventListener("message", (event) => {
	var item = event.data

	if (item.type === "anuncio") {
		var anuncioDiv = document.getElementById("anuncio")
		var anuncioImagen = document.getElementById("anuncioImagen")
		var anuncioCategory = document.getElementById("anuncioCategory")
		var markerButton = document.querySelector(".marker")

		document.getElementById("anuncioTitulo").innerText = item.title
		document.getElementById("anuncioContenido").innerText = item.content

		if (item.image) {
			anuncioImagen.src = item.image
			anuncioImagen.style.display = "block"
		} else {
			anuncioImagen.style.display = "none"
		}

		// Show category if it exists
		if (item.category) {
			anuncioCategory.innerHTML = item.category.name
			anuncioCategory.style.backgroundColor = item.category.color
			anuncioCategory.style.display = "inline-flex"
		} else {
			anuncioCategory.style.display = "none"
		}

		// Update GPS button text if configured
		if (item.gpsText && markerButton) {
			const markerText = markerButton.querySelector('.marker-text')
			if (markerText) {
				markerText.textContent = item.gpsText
			} else {
				// If text element doesn't exist, update entire button content
				markerButton.innerHTML = `
					<span class="marker-h">H</span> 
					<svg class="marker-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
						<path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
						<circle cx="12" cy="10" r="3"/>
					</svg>
					<span class="marker-text">${item.gpsText}</span>
				`
			}
		}

		anuncioDiv.style.display = "flex"
		anuncioDiv.style.animation = "slideInFromTop 0.7s ease-out forwards"

		var sound = new Audio("sound.mp3")
		sound.volume = 0.1
		sound.play().catch((e) => console.log("Audio play failed:", e))

		const duration = (item.duration || selectedDuration) * 1000

		// Cancel previous timeout to prevent hiding new announce too early
		if (anuncioTimeoutId) {
			clearTimeout(anuncioTimeoutId)
			anuncioTimeoutId = null
		}

		setTimeout(() => {
			anuncioDiv.style.animation = "slideOutToTop 0.7s ease-out forwards"
		}, duration - 500)

		anuncioTimeoutId = setTimeout(() => {
			anuncioDiv.style.display = "none"
			anuncioTimeoutId = null
		}, duration)
	}

	if (item.type === "openCreateInterface") {
		currentJobData = item.jobData
		availableJobs = item.jobData.availableJobs || []
		config = item.jobData.config || {}
		openCreateInterface(item.jobData)
	}
})

function openCreateInterface(jobData) {
	const createInterface = document.getElementById("createInterface")
	const jobNameDisplay = document.getElementById("jobNameDisplay")
	const jobAvatar = document.getElementById("jobAvatar")
	const previewTitle = document.getElementById("previewTitle")
	const previewImage = document.getElementById("previewImage")
	const announceContent = document.getElementById("announceContent")
	const previewContent = document.getElementById("previewContent")
	const publishBtn = document.getElementById("publishBtn")
	const charCount = document.getElementById("charCount")

	createInterface.style.display = "flex"

	// Apply configurable texts
	if (config.texts) {
		updateInterfaceTexts()
	}

	const jobDisplayText = jobData.jobGrade !== undefined ?
		`${jobData.jobName} (Rank ${jobData.jobGrade})` :
		jobData.jobName

	jobNameDisplay.innerText = jobDisplayText
	jobAvatar.src = jobData.jobImage
	previewTitle.innerText = jobData.jobName
	previewImage.src = jobData.jobImage

	// Set initial share location state from job data
	shareLocationEnabled = jobData.shareLocation || false

	// Get the share location checkbox element
	const shareLocationCheckbox = document.getElementById("shareLocation")
	if (shareLocationCheckbox) {
		// Set checkbox checked state based on job data
		shareLocationCheckbox.checked = shareLocationEnabled

		// Show or hide the preview marker based on checkbox state
		const previewMarker = document.querySelector(".preview-marker")
		if (previewMarker) {
			previewMarker.style.display = shareLocationCheckbox.checked ? "flex" : "none"
		}

		// If job does not allow location modification, disable checkbox and force value
		if (jobData.hasOwnProperty('canModifyLocation') && jobData.canModifyLocation === false) {
			shareLocationCheckbox.disabled = true
			shareLocationCheckbox.checked = !!jobData.shareLocation
			if (previewMarker) previewMarker.style.display = jobData.shareLocation ? "flex" : "none"
		} else {
			// Otherwise, enable checkbox for user interaction
			shareLocationCheckbox.disabled = false
		}
	}

	// Update preview and notify UI for share location state
	updateShareLocationCreation()
	updateShareLocationNotify()

	// Ensure GPS marker button is visible in notification if announcement is shown
	const markerButtonNotify = document.getElementById("anuncio")?.querySelector(".marker")
	if (markerButtonNotify && document.getElementById("anuncio").style.display !== "none") markerButtonNotify.style.display = "flex"

	announceContent.value = ""
	previewContent.innerText = config.texts?.Interface?.PreviewContent || "The announcement content will appear here..."
	publishBtn.disabled = true
	charCount.innerText = "0"

	// Reset selectors with configurable default values
	selectedDuration = config.defaultDuration || 10
	selectedVisibility = "all"
	customCategoryData = null
	categoryEnabled = false

	// Configure duration
	const durationDisplay = document.getElementById("durationDisplay")
	if (config.enableDurationSelection) {
		const defaultOption = config.durationOptions?.find(opt => opt.value === selectedDuration)
		durationDisplay.innerText = defaultOption?.text || `${selectedDuration} seconds`
	} else {
		durationDisplay.innerText = `${selectedDuration} seconds`
	}

	// Configure visibility
	document.getElementById("visibilityDisplay").innerText = config.texts?.Interface?.VisibilityAll || "Visible to everyone"

	// Handle categories section
	const categoryGroup = document.querySelector('.form-group:has(#enableCategory)')
	const enableCategoryCheckbox = document.getElementById("enableCategory")
	const categorySection = document.getElementById("categorySection")

	if (config.enableCategories) {
		if (categoryGroup) categoryGroup.style.display = "flex"
		if (enableCategoryCheckbox) enableCategoryCheckbox.checked = false
		if (categorySection) {
			categorySection.style.display = "none"
			categorySection.classList.remove("active")
		}
	} else {
		if (categoryGroup) categoryGroup.style.display = "none"
	}

	// Handle duration section
	const durationGroup = document.querySelector('.form-group:has(#durationDisplay)')
	if (config.enableDurationSelection) {
		if (durationGroup) durationGroup.style.display = "flex"
		generateDurationOptions()
	} else {
		if (durationGroup) durationGroup.style.display = "none"
	}

	// Handle visibility section
	const visibilityGroup = document.querySelector('.form-group:has(#visibilityDisplay)')
	if (config.enableVisibilitySelection) {
		if (visibilityGroup) visibilityGroup.style.display = "flex"
		generateVisibilityOptions()
	} else {
		if (visibilityGroup) visibilityGroup.style.display = "none"
	}

	// Reset custom category fields
	if (config.enableCategories) {
		document.getElementById("customCategoryName").value = ""
		document.getElementById("customCategoryColor").value = "#3498db"
		document.getElementById("customCategoryColorText").value = "#3498db"
	}

	updateDurationPreview()
	updateVisibilityPreview()
	updateCustomCategoryPreview()

	// Load Lucide icons
	loadLucideIcons()

	setTimeout(() => {
		announceContent.focus()
	}, 100)
}

function updateInterfaceTexts() {
	const texts = config.texts?.Interface
	if (!texts) return

	// Update titles and labels
	const headerTitle = document.querySelector('.header-title')
	if (headerTitle && texts.CreateTitle) headerTitle.textContent = texts.CreateTitle

	const headerSubtitle = document.querySelector('.header-subtitle')
	if (headerSubtitle && texts.CreateSubtitle) headerSubtitle.textContent = texts.CreateSubtitle

	const jobStatus = document.querySelector('.job-status')
	if (jobStatus && texts.JobPermissionsVerified) {
		jobStatus.innerHTML = `
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="20,6 9,17 4,12"/>
      </svg>
      ${texts.JobPermissionsVerified}
    `
	}

	// Update placeholders and form labels
	const announceContent = document.getElementById("announceContent")
	if (announceContent && texts.ContentPlaceholder) {
		announceContent.placeholder = texts.ContentPlaceholder
	}

	const customCategoryName = document.getElementById("customCategoryName")
	if (customCategoryName && texts.CategoryNamePlaceholder) {
		customCategoryName.placeholder = texts.CategoryNamePlaceholder
	}

	const shareLocationLabel = document.getElementById("shareLocationLabel")
	if (shareLocationLabel && texts.ShareLocationLabel) {
		shareLocationLabel.innerHTML = `
		<div class="custom-checkbox">
			<input type="checkbox" id="shareLocation" onchange="toggleShareLocation()">
			<div class="checkbox-indicator">
				<svg class="checkbox-icon" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
					<polyline points="20,6 9,17 4,12"/>
				</svg>
			</div>
		</div>
		<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
			<path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
			<circle cx="12" cy="10" r="3"/>
		</svg>
		${texts.ShareLocationLabel}
		`
	}

	// Update buttons
	const cancelButton = document.querySelector('.cancel-button')
	if (cancelButton && texts.CancelButton) {
		cancelButton.innerHTML = `
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <line x1="18" y1="6" x2="6" y2="18"/>
        <line x1="6" y1="6" x2="18" y2="18"/>
      </svg>
      ${texts.CancelButton}
    `
	}

	const publishButton = document.querySelector('.publish-button')
	if (publishButton && texts.PublishButton) {
		publishButton.innerHTML = `
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M22 2L11 13"/>
        <polygon points="22,2 15,22 11,13 2,9 22,2"/>
      </svg>
      ${texts.PublishButton}
    `
	}

	// Update preview
	const previewHeader = document.querySelector('.preview-header span')
	if (previewHeader && texts.PreviewTitle) previewHeader.textContent = texts.PreviewTitle
}

function generateDurationOptions() {
	if (!config.enableDurationSelection || !config.durationOptions) return

	const dropdown = document.getElementById("durationDropdown")
	if (!dropdown) return

	dropdown.innerHTML = ""

	config.durationOptions.forEach((option, index) => {
		const isSelected = option.value === selectedDuration ? "selected" : ""
		dropdown.innerHTML += `<div class="select-option ${isSelected}" data-value="${option.value}" onclick="selectDuration(${option.value}, '${option.text}')">${option.text}</div>`
	})
}

function toggleCategorySection() {
	if (!config.enableCategories) return

	const checkbox = document.getElementById("enableCategory")
	const section = document.getElementById("categorySection")

	if (!checkbox || !section) {
		console.warn("Category elements not found")
		return
	}

	categoryEnabled = checkbox.checked

	if (categoryEnabled) {
		section.style.display = "block"
		setTimeout(() => {
			section.classList.add("active")
		}, 10)
	} else {
		section.classList.remove("active")
		setTimeout(() => {
			section.style.display = "none"
		}, 300)
		customCategoryData = null
		updateCategoryPreview()
	}

	updatePublishButton()
}

// Handles toggling and updating share location UI elements
function toggleShareLocation() {
	shareLocationEnabled = document.getElementById("shareLocation").checked
	updateShareLocationCreation()
	updateShareLocationNotify()
	// If announcement is visible, ensure GPS button is shown
	const markerButtonNotify = document.getElementById("anuncio")?.querySelector(".marker")
	if (markerButtonNotify && document.getElementById("anuncio").style.display !== "none") markerButtonNotify.style.display = "flex"
}

// Updates the preview marker for location sharing
function updateShareLocationCreation() {
	const previewMarker = document.querySelector(".preview-marker")
	if (previewMarker) {
		previewMarker.style.display = shareLocationEnabled ? "flex" : "none"
	}

	const markerButtonNotify = document.getElementById("anuncio")?.querySelector(".marker")
	if (markerButtonNotify && document.getElementById("anuncio").style.display !== "none") markerButtonNotify.style.display = "flex"
}

// Updates the GPS button in the announcement
function updateShareLocationNotify() {
	const marker = document.querySelector(".marker")
	if (marker) {
		marker.style.display = "flex"
	}

	const markerButtonNotify = document.getElementById("anuncio")?.querySelector(".marker")
	if (markerButtonNotify && document.getElementById("anuncio").style.display !== "none") markerButtonNotify.style.display = "flex"
}

function updateCustomCategoryPreview() {
	if (!config.enableCategories) return

	const name = document.getElementById("customCategoryName")?.value.trim() || ""
	const color = document.getElementById("customCategoryColor")?.value || "#3498db"

	const previewTag = document.querySelector(".preview-tag")
	const previewText = previewTag?.querySelector(".preview-text")

	if (previewText) {
		previewText.textContent = name || (config.texts?.Interface?.CategoryPreview || "Preview")
	}
	if (previewTag) {
		previewTag.style.backgroundColor = color
	}

	// Update custom category data - only require name
	if (name) {
		customCategoryData = {
			id: "custom",
			name: name,
			color: color
		}
	} else {
		customCategoryData = null
	}

	updateCategoryPreview()
	updatePublishButton()
}

function updateCustomCategoryColorFromText() {
	if (!config.enableCategories) return

	const colorText = document.getElementById("customCategoryColorText")?.value
	const colorPicker = document.getElementById("customCategoryColor")

	// Validate hex color
	if (colorText && /^#[0-9A-F]{6}$/i.test(colorText) && colorPicker) {
		colorPicker.value = colorText
		updateCustomCategoryPreview()
	}
}

// Update color text when color picker changes
document.addEventListener('DOMContentLoaded', function () {
	const colorPicker = document.getElementById("customCategoryColor")
	if (colorPicker) {
		colorPicker.addEventListener('input', function () {
			const colorText = document.getElementById("customCategoryColorText")
			if (colorText) {
				colorText.value = this.value
			}
		})
	}
})

function updateCategoryPreview() {
	if (!config.enableCategories) return

	const previewContainer = document.querySelector(".preview-ad")
	if (!previewContainer) return

	// Remove existing category badge
	const existingBadge = previewContainer.querySelector(".category-badge")
	if (existingBadge) {
		existingBadge.remove()
	}

	if (!categoryEnabled || !customCategoryData) {
		return
	}

	const categoryBadge = document.createElement("div")
	categoryBadge.className = "category-badge"
	categoryBadge.style.backgroundColor = customCategoryData.color
	categoryBadge.innerHTML = customCategoryData.name

	// Insert after the image
	const previewImage = previewContainer.querySelector(".preview-ad-img")
	if (previewImage) {
		previewImage.parentNode.insertBefore(categoryBadge, previewImage.nextSibling)
	}
}

function updatePublishButton() {
	const announceContent = document.getElementById("announceContent")
	const publishBtn = document.getElementById("publishBtn")

	if (!announceContent || !publishBtn) {
		return
	}

	const hasContent = announceContent.value.trim().length > 0
	let categoryValid = true

	if (config.enableCategories && categoryEnabled) {
		categoryValid = customCategoryData !== null
	}

	publishBtn.disabled = !(hasContent && categoryValid)
}

function loadLucideIcons() {
	// Load Lucide icons library if not already loaded
	if (typeof lucide === 'undefined') {
		const script = document.createElement('script')
		script.src = 'https://unpkg.com/lucide@latest/dist/umd/lucide.js'
		script.onload = function () {
			lucide.createIcons()
		}
		document.head.appendChild(script)
	} else {
		lucide.createIcons()
	}
}

function createAnnounce() {
	const content = document.getElementById("announceContent").value.trim()

	if (content === "") {
		return
	}

	// Prepare category data
	let categoryData = null
	if (config.enableCategories && categoryEnabled && customCategoryData) {
		categoryData = customCategoryData
	}

	const publishBtn = document.getElementById("publishBtn")
	const originalText = publishBtn.innerHTML

	const publishingText = config.texts?.Interface?.PublishingButton || "Publishing..."
	publishBtn.innerHTML = `
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="animation: spin 1s linear infinite;">
      <path d="M21 12a9 9 0 11-6.219-8.56"/>
    </svg>
    ${publishingText}
  `
	publishBtn.disabled = true

	const requestData = {
		content: content,
		duration: config.enableDurationSelection ? selectedDuration : config.defaultDuration,
		visibility: config.enableVisibilitySelection ? selectedVisibility : "all",
		category: categoryData
	}

	fetch(`https://lux-announces/createAnnounce`, {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
		},
		body: JSON.stringify(requestData),
	})
		.then(() => {
			setTimeout(() => {
				publishBtn.innerHTML = originalText
				publishBtn.disabled = false
				// Close panel after successful publishing
				closeCreateInterface()
			}, 1000)
		})
		.catch((e) => {
			console.log("Fetch failed:", e)
			publishBtn.innerHTML = originalText
			publishBtn.disabled = false
		})
}

function closeAnnouncement() {
	var anuncioDiv = document.querySelector("#anuncio")
	anuncioDiv.style.animation = "slideOutToTop 0.7s ease-out forwards"

	setTimeout(() => {
		anuncioDiv.style.display = "none"
	}, 500)
}

function markOnGPS() {
	fetch(`https://lux-announces/marcarGPS`, {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
		},
	}).catch((e) => console.log("Fetch failed:", e))
}

// Close dropdowns when clicking outside
document.addEventListener("click", (event) => {
	if (!event.target.closest(".custom-select")) {
		document.querySelectorAll(".custom-select").forEach((select) => {
			select.classList.remove("open")
		})
	}
})

document.addEventListener("keydown", (event) => {
	if (event.key === "Escape") {
		closeCreateInterface()
	}
})

// Missing functions that are called from HTML
function updatePreview() {
	const announceContent = document.getElementById("announceContent")
	const previewContent = document.getElementById("previewContent")
	const charCount = document.getElementById("charCount")

	if (!announceContent || !previewContent || !charCount) {
		return
	}

	const content = announceContent.value
	const defaultText = config.texts?.Interface?.PreviewContent || "The announcement content will appear here..."
	previewContent.innerText = content || defaultText
	charCount.innerText = content.length

	updatePublishButton()
}

function toggleDropdown(dropdownId) {
	const dropdown = document.getElementById(dropdownId)
	if (!dropdown) return

	const customSelect = dropdown.closest('.custom-select')
	if (!customSelect) return

	// Close all other dropdowns
	document.querySelectorAll('.custom-select').forEach(select => {
		if (select !== customSelect) {
			select.classList.remove('open')
		}
	})

	// Toggle current dropdown
	customSelect.classList.toggle('open')
}

function selectDuration(value, text) {
	if (!config.enableDurationSelection) return

	selectedDuration = value
	document.getElementById("durationDisplay").innerText = text
	document.getElementById("durationInfo").innerText = `${config.texts?.Interface?.DurationInfo?.replace('%s', text) || `Duration: ${text}`}`

	// Close dropdown
	document.querySelector('#durationDropdown').closest('.custom-select').classList.remove('open')

	updateDurationPreview()
}

function selectVisibility(value, text) {
	if (!config.enableVisibilitySelection) return

	selectedVisibility = value
	document.getElementById("visibilityDisplay").innerText = text
	document.getElementById("visibilityInfo").innerText = text

	// Close dropdown
	document.querySelector('#visibilityDropdown').closest('.custom-select').classList.remove('open')

	updateVisibilityPreview()
}

function generateVisibilityOptions() {
	if (!config.enableVisibilitySelection) return

	const dropdown = document.getElementById("visibilityDropdown")
	if (!dropdown) return

	const texts = config.texts?.Interface
	const visibilityAll = texts?.VisibilityAll || "Visible to everyone"
	const visibilityJob = texts?.VisibilityJob || "Only my team"

	dropdown.innerHTML = `
    <div class="select-option selected" onclick="selectVisibility('all', '${visibilityAll}')">${visibilityAll}</div>
    <div class="select-option" onclick="selectVisibility('job', '${visibilityJob}')">${visibilityJob}</div>
  `

	// Add available jobs if any
	if (availableJobs && availableJobs.length > 0) {
		dropdown.innerHTML += '<div class="select-separator"></div>'
		availableJobs.forEach(job => {
			dropdown.innerHTML += `<div class="select-option" onclick="selectVisibility('${job.name}', '${job.label}')">${job.label}</div>`
		})
	}
}

function updateDurationPreview() {
	const durationInfo = document.getElementById("durationInfo")
	if (durationInfo) {
		const durationText = config.enableDurationSelection ?
			(config.durationOptions?.find(opt => opt.value === selectedDuration)?.text || `${selectedDuration} seconds`) :
			`${selectedDuration} seconds`

		const infoText = config.texts?.Interface?.DurationInfo?.replace('%s', durationText) || `Duration: ${durationText}`
		durationInfo.innerText = infoText
	}
}

function updateVisibilityPreview() {
	const visibilityInfo = document.getElementById("visibilityInfo")
	const visibilityDisplay = document.getElementById("visibilityDisplay")

	if (visibilityInfo && visibilityDisplay) {
		visibilityInfo.innerText = visibilityDisplay.innerText
	}
}

function closeCreateInterface() {
	const createInterface = document.getElementById("createInterface")
	if (createInterface) {
		createInterface.style.display = "none"
	}

	// Send close event to Lua
	fetch(`https://lux-announces/closeCreateInterface`, {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
		},
	}).catch((e) => console.log("Fetch failed:", e))

	// Si hay anuncio en pantalla, asegúrate que el botón GPS del notify esté visible
	const markerButtonNotify = document.getElementById("anuncio")?.querySelector(".marker")
	if (markerButtonNotify && document.getElementById("anuncio").style.display !== "none") markerButtonNotify.style.display = "flex"
}