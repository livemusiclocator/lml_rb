import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="explorer-overlay"
export default class extends Controller {
  static targets = ["toggleButton", "content", "expandIcon", "minimizeIcon"]
  static classes = ["expanded", "minimized"]
  static values = { 
    expanded: Boolean,
    autoExpandOnNavigation: Boolean 
  }

  connect() {
    // Set initial state - start expanded by default
    this.expandedValue = true
    this.updateDisplay()
    
    // Listen for navigation events to auto-expand overlay
    if (this.autoExpandOnNavigationValue) {
      document.addEventListener('turbo:before-visit', this.handleNavigation.bind(this))
    }
    
    // Handle responsive behavior
    this.handleResize = this.handleResize.bind(this)
    window.addEventListener('resize', this.handleResize)
  }

  disconnect() {
    if (this.autoExpandOnNavigationValue) {
      document.removeEventListener('turbo:before-visit', this.handleNavigation.bind(this))
    }
    window.removeEventListener('resize', this.handleResize)
  }

  // Main toggle action
  toggle() {
    this.expandedValue = !this.expandedValue
    this.updateDisplay()
    this.announceStateChange()
  }

  // Expand the overlay
  expand() {
    if (!this.expandedValue) {
      this.expandedValue = true
      this.updateDisplay()
      this.announceStateChange()
    }
  }

  // Minimize the overlay
  minimize() {
    if (this.expandedValue) {
      this.expandedValue = false
      this.updateDisplay()
      this.announceStateChange()
    }
  }

  // Update visual state based on expanded/minimized
  updateDisplay() {
    if (this.expandedValue) {
      this.showExpanded()
    } else {
      this.showMinimized()
    }
    this.updateToggleButton()
    this.updateIcons()
  }

  showExpanded() {
    // Remove minimized classes and add expanded classes
    if (this.hasMinimizedClass) {
      this.minimizedClasses.forEach(className => {
        this.element.classList.remove(className)
      })
    }
    
    if (this.hasExpandedClass) {
      this.expandedClasses.forEach(className => {
        this.element.classList.add(className)
      })
    }
    
    // Remove the minimized state class
    this.element.classList.remove('is-minimised')
    
    // Update ARIA attributes
    this.element.setAttribute('aria-expanded', 'true')
    
    // Focus management - focus first interactive element when expanded
    this.focusFirstInteractiveElement()
  }

  showMinimized() {
    // Remove expanded classes and add minimized classes
    if (this.hasExpandedClass) {
      this.expandedClasses.forEach(className => {
        this.element.classList.remove(className)
      })
    }
    
    if (this.hasMinimizedClass) {
      this.minimizedClasses.forEach(className => {
        this.element.classList.add(className)
      })
    }
    
    // Add the minimized state class for styling
    this.element.classList.add('is-minimised')
    
    // Update ARIA attributes
    this.element.setAttribute('aria-expanded', 'false')
  }

  updateToggleButton() {
    if (this.hasToggleButtonTarget) {
      const buttonText = this.expandedValue ? 'Minimize' : 'Expand'
      this.toggleButtonTarget.setAttribute('aria-label', `${buttonText} overlay`)
      this.toggleButtonTarget.setAttribute('title', `${buttonText} overlay`)
    }
  }

  updateIcons() {
    if (this.hasExpandIconTarget && this.hasMinimizeIconTarget) {
      if (this.expandedValue) {
        // Show minimize icon, hide expand icon
        this.expandIconTarget.classList.add('hidden')
        this.minimizeIconTarget.classList.remove('hidden')
      } else {
        // Show expand icon, hide minimize icon
        this.expandIconTarget.classList.remove('hidden')
        this.minimizeIconTarget.classList.add('hidden')
      }
    }
  }

  // Handle navigation events - expand overlay when navigating
  handleNavigation(event) {
    // Auto-expand on navigation to improve UX
    if (!this.expandedValue) {
      this.expand()
    }
  }

  // Handle window resize for responsive behavior
  handleResize() {
    // Force recalculation of heights on resize
    this.updateDisplay()
    
    // On mobile, ensure overlay doesn't get stuck in weird states
    if (window.innerWidth < 768) { // md breakpoint
      this.element.style.maxHeight = '100vh'
    }
  }

  // Accessibility: announce state changes to screen readers
  announceStateChange() {
    const message = this.expandedValue ? 'Overlay expanded' : 'Overlay minimized'
    this.announceToScreenReader(message)
  }

  announceToScreenReader(message) {
    const announcement = document.createElement('div')
    announcement.setAttribute('aria-live', 'polite')
    announcement.setAttribute('aria-atomic', 'true')
    announcement.className = 'sr-only'
    announcement.textContent = message
    
    document.body.appendChild(announcement)
    
    // Remove after announcement
    setTimeout(() => {
      document.body.removeChild(announcement)
    }, 1000)
  }

  // Focus management
  focusFirstInteractiveElement() {
    if (this.hasContentTarget) {
      const firstInput = this.contentTarget.querySelector('input, button, select, textarea, a[href]')
      if (firstInput) {
        // Small delay to ensure element is visible
        setTimeout(() => {
          firstInput.focus()
        }, 100)
      }
    }
  }

  // Keyboard shortcuts
  keydown(event) {
    // Escape key minimizes overlay
    if (event.key === 'Escape' && this.expandedValue) {
      this.minimize()
      this.toggleButtonTarget?.focus()
    }
    
    // Enter or Space on toggle button
    if ((event.key === 'Enter' || event.key === ' ') && event.target === this.toggleButtonTarget) {
      event.preventDefault()
      this.toggle()
    }
  }

  // Touch gestures for mobile
  touchStart(event) {
    this.startY = event.touches[0].clientY
    this.startTime = Date.now()
  }

  touchEnd(event) {
    if (!this.startY) return
    
    const endY = event.changedTouches[0].clientY
    const deltaY = this.startY - endY
    const deltaTime = Date.now() - this.startTime
    
    // Quick swipe detection
    if (deltaTime < 300 && Math.abs(deltaY) > 50) {
      if (deltaY > 0 && !this.expandedValue) {
        // Swipe up to expand
        this.expand()
      } else if (deltaY < 0 && this.expandedValue) {
        // Swipe down to minimize
        this.minimize()
      }
    }
    
    this.startY = null
    this.startTime = null
  }

  // Public API methods for other controllers
  get isExpanded() {
    return this.expandedValue
  }

  get isMinimized() {
    return !this.expandedValue
  }
}