import UIKit

protocol KeyboardViewDelegate: AnyObject {
    func insertText(_ text: String)
    func deleteBackward()
    func insertReturn()
    func switchToNextInputMode()
    func moveCursor(offset: Int)
}

class KeyboardView: UIView {
    
    weak var delegate: KeyboardViewDelegate?
    private weak var keyboardViewController: KeyboardViewController?
    
    // Cached colors for performance - initialize immediately to prevent lazy loading issues
    private var colors: KeyColors
    
    // MARK: - Separated Architecture Components
    
    // Main layout container
    private var stackView: UIStackView!
    
    // Programmer Keys Section (Top)
    private var programmerSection: UIStackView!
    private var programmerButtons: [[UIButton]] = []
    
    // Alphabet Keys Section (Middle)  
    private var alphabetSection: UIStackView!
    private var alphabetButtons: [[UIButton]] = []
    private var shiftButton: UIButton?
    private var backspaceButton: UIButton?
    private var isShiftActive: Bool = false
    
    // Bottom Action Section (Space/Return)
    private var bottomActionSection: UIStackView!
    private var spaceButton: UIButton?
    private var returnButton: UIButton?
    private var leftArrowButton: UIButton?
    private var rightArrowButton: UIButton?
    
    // Long Press State
    private var activePopupView: UIView?
    private var popupButtons: [UIButton] = []
    private let dotAlternatives = [";", ","]
    
    // Key layout definitions - lowercase by default
    private let alphabetKeys = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"]
    ]
    
    // Number and symbol layout for coder keyboard - reorganized for logical grouping
    private let numberSymbolKeys = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["+", "-", "*", "/", "=", "<", ">", "!", "&", "|"],
        ["(", ")", "[", "]", "{", "}", "'", "\"", ":", "."]
    ]
    
    
    init(keyboardViewController: KeyboardViewController) {
        self.keyboardViewController = keyboardViewController
        // Initialize colors with a default value first, then update after super.init
        self.colors = KeyColors(userInterfaceStyle: .light)
        super.init(frame: .zero)
        self.delegate = keyboardViewController
        // Update colors with the current trait collection to prevent flashing
        self.colors = KeyColors(userInterfaceStyle: traitCollection.userInterfaceStyle)
        setupKeyboard()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupKeyboard() {
        
        // Create main container
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill  // Changed from .fillEqually to allow custom sizing
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        
        // Set a minimum height to ensure consistent sizing
        stackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 260).isActive = true
        
        // Create independent sections
        createProgrammerKeySection()
        createAlphabetKeySection()
        createBottomActionSection()
        
        // Start with buttons enabled to prevent flashing during keyboard switching
        updateButtonStates(enabled: true)
        
        // Ensure shift state is properly initialized
        isShiftActive = false
        updateShiftState()
        updateAlphabetKeyTitles()
        
        // Colors are already initialized in init with correct trait collection
        // Register for trait change notifications to handle dynamic appearance changes
        registerForTraitChangeNotifications()
        
    }
    
    // MARK: - Programmer Keys Section (Top Rows)
    private func createProgrammerKeySection() {
        
        programmerSection = UIStackView()
        programmerSection.axis = .vertical
        programmerSection.distribution = .fillEqually
        programmerSection.spacing = 8
        
        programmerButtons.removeAll()
        
        for (_, row) in numberSymbolKeys.enumerated() {
            let rowStack = createRowStackView()
            var buttonRow: [UIButton] = []
            
            for key in row {
                let color = getColorForNumberSymbolKey(key)
                let button = createStandardButton(text: key, color: color, action: #selector(programmerKeyPressed(_:)))
                
                if key == "." {
                    setupLongPress(for: button)
                }
                
                buttonRow.append(button)
                rowStack.addArrangedSubview(button)
            }
            
            programmerButtons.append(buttonRow)
            programmerSection.addArrangedSubview(rowStack)
        }
        
        stackView.addArrangedSubview(programmerSection)
    }
    
    // MARK: - Alphabet Keys Section (Middle Rows)
    private func createAlphabetKeySection() {
        
        alphabetSection = UIStackView()
        alphabetSection.axis = .vertical
        alphabetSection.distribution = .fillEqually
        alphabetSection.spacing = 8
        
        alphabetButtons.removeAll()
        
        for (rowIndex, row) in alphabetKeys.enumerated() {
            let rowStack = createRowStackView()
            var buttonRow: [UIButton] = []
            
            // Add left-side elements for appropriate rows
            if rowIndex == 1 { // Second row (a-l)
                rowStack.addArrangedSubview(createSpacer(width: 20))
            } else if rowIndex == 2 { // Third row (z-m)
                shiftButton = createStandardButton(text: "⇧", color: getCurrentColors().special, action: #selector(shiftPressed))
                shiftButton?.titleLabel?.font = UIFont.systemFont(ofSize: 20)
                shiftButton?.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
                rowStack.addArrangedSubview(shiftButton!)
            }
            
            // Add alphabet keys for the row
            for key in row {
                let button = createStandardButton(text: key, color: getCurrentColors().alphabet, action: #selector(alphabetKeyPressed(_:)))
                buttonRow.append(button)
                rowStack.addArrangedSubview(button)
            }
            
            // Add backspace to the third alphabet row
            if rowIndex == 2 {
                backspaceButton = createStandardButton(text: "⌫", color: getCurrentColors().special, action: #selector(backspacePressed))
                backspaceButton?.titleLabel?.font = UIFont.systemFont(ofSize: 22)
                backspaceButton?.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
                rowStack.addArrangedSubview(backspaceButton!)
            }
            
            alphabetButtons.append(buttonRow)
            alphabetSection.addArrangedSubview(rowStack)
        }
        
        stackView.addArrangedSubview(alphabetSection)
    }
    
    // MARK: - Bottom Action Section (Space/Return)
    private func createBottomActionSection() {
        
        bottomActionSection = UIStackView()
        bottomActionSection.axis = .horizontal
        bottomActionSection.distribution = .fillProportionally
        bottomActionSection.spacing = 6
        
        // Calculate proportionate widths: 3 parts total (Space: 1, Arrows: 1, Return: 1)
        // But implementation uses fillProportionally, so we use width constraints or allow natural compression
        
        // 1. Space Button (Approx 1/3)
        spaceButton = createStandardButton(text: "space", color: getCurrentColors().special, action: #selector(spacePressed))
        spaceButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        
        // 2. Cursor Keys Container (Approx 1/3)
        let cursorStack = UIStackView()
        cursorStack.axis = .horizontal
        cursorStack.distribution = .fillEqually
        cursorStack.spacing = 6
        
        leftArrowButton = createStandardButton(text: "<", color: getCurrentColors().special, action: #selector(cursorLeftPressed))
        rightArrowButton = createStandardButton(text: ">", color: getCurrentColors().special, action: #selector(cursorRightPressed))
        
        cursorStack.addArrangedSubview(leftArrowButton!)
        cursorStack.addArrangedSubview(rightArrowButton!)
        
        // 3. Return Button (Approx 1/3)
        returnButton = createStandardButton(text: "return", color: getCurrentColors().special, action: #selector(returnPressed))
        returnButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        
        // Add to main bottom section
        bottomActionSection.addArrangedSubview(spaceButton!)
        bottomActionSection.addArrangedSubview(cursorStack)
        bottomActionSection.addArrangedSubview(returnButton!)
        
        // Set equal width constraints to ensure they share width equally
        cursorStack.widthAnchor.constraint(equalTo: spaceButton!.widthAnchor).isActive = true
        returnButton!.widthAnchor.constraint(equalTo: spaceButton!.widthAnchor).isActive = true
        
        // Set proper height constraint for bottom row
        bottomActionSection.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        stackView.addArrangedSubview(bottomActionSection)
    }
    
    private func getColorForNumberSymbolKey(_ key: String) -> UIColor {
        let colors = getCurrentColors()
        switch key {
        case "0"..."9":
            return colors.number
        case "(", ")", "[", "]", "{", "}":
            return colors.bracket
        case "+", "-", "*", "/", "=", "<", ">", "!":
            return colors.operator
        case "\"", "'", ".":
            return colors.quote
        case "&", "|", ";", ":":
            return colors.punctuation
        case "_":
            return colors.underscore
        default:
            return colors.punctuation
        }
    }
    
    private func getCurrentColors() -> KeyColors {
        return colors
    }
    
    // MARK: - Standardized Button Creation & Touch Handling
    
    private func createRowStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 6
        return stackView
    }
    
    private func createStandardButton(text: String, color: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(text, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = color
        button.layer.cornerRadius = 6
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 42).isActive = true
        
        // Single touch target for maximum responsiveness
        button.addTarget(self, action: action, for: .touchUpInside)
        
        return button
    }
    
    private func createSpacer(width: CGFloat) -> UIView {
        let spacer = UIView()
        spacer.widthAnchor.constraint(equalToConstant: width).isActive = true
        return spacer
    }
    
    // MARK: - Long Press Handling
    
    private func setupLongPress(for button: UIButton) {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.3
        button.addGestureRecognizer(longPress)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        // Find which button triggered this
        guard let sourceButton = gesture.view as? UIButton else { return }
        
        switch gesture.state {
        case .began:
            showPopup(for: sourceButton, alternatives: dotAlternatives)
            // Initial feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
        case .changed:
            let location = gesture.location(in: activePopupView)
            updatePopupSelection(at: location)
            
        case .ended:
            let location = gesture.location(in: activePopupView)
            if let selectedText = getSelectedAlternative(at: location) {
                delegate?.insertText(selectedText)
            }
            dismissPopup()
            
        case .cancelled, .failed:
            dismissPopup()
            
        default:
            break
        }
    }
    
    private func showPopup(for sourceButton: UIButton, alternatives: [String]) {
        // Remove any existing popup
        dismissPopup()
        
        // Convert source button frame to our coordinate space
        let sourceFrame = sourceButton.convert(sourceButton.bounds, to: self)
        
        // Create container view
        let container = UIView()
        container.backgroundColor = getCurrentColors().special
        container.layer.cornerRadius = 8
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.3
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 4
        
        // Create stack for alternatives
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 1
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        popupButtons = []
        
        for alt in alternatives {
            let btn = UIButton(type: .system)
            btn.setTitle(alt, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 24)
            btn.setTitleColor(.label, for: .normal)
            btn.backgroundColor = .clear // Let container color show
            popupButtons.append(btn)
            stack.addArrangedSubview(btn)
        }
        
        container.addSubview(stack)
        
        // Size calculations
        let buttonWidth: CGFloat = 44
        let totalWidth = buttonWidth * CGFloat(alternatives.count) + CGFloat(alternatives.count - 1) // + spacing
        let height: CGFloat = 54
        
        // Calculate X position centered on key, but clamped to view bounds
        var x = sourceFrame.midX - (totalWidth / 2)
        
        // Ensure within bounds with some padding
        let padding: CGFloat = 5
        let rightEdge = self.bounds.width - padding
        
        if x + totalWidth > rightEdge {
            x = rightEdge - totalWidth
        }
        if x < padding {
            x = padding
        }
        
        container.frame = CGRect(
            x: x,
            y: sourceFrame.minY - height - 10,
            width: totalWidth,
            height: height
        )
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        // Add a small pointer triangle at the bottom? (Optional, skipping for simplicity/robustness first)
        
        addSubview(container)
        activePopupView = container
    }
    
    private func updatePopupSelection(at point: CGPoint) {
        // Reset all backgrounds
        for btn in popupButtons {
            if btn.frame.contains(point) {
                btn.backgroundColor = .systemBlue
                btn.setTitleColor(.white, for: .normal)
            } else {
                btn.backgroundColor = .clear
                btn.setTitleColor(.label, for: .normal)
            }
        }
    }
    
    private func getSelectedAlternative(at point: CGPoint) -> String? {
        for btn in popupButtons {
            if btn.frame.contains(point) {
                return btn.currentTitle
            }
        }
        return nil
    }
    
    private func dismissPopup() {
        activePopupView?.removeFromSuperview()
        activePopupView = nil
        popupButtons = []
    }

    // MARK: - Button Action Methods (Separated by Section)
    
    @objc private func programmerKeyPressed(_ sender: UIButton) {
        guard let text = sender.currentTitle else { return }
        
        guard isKeyboardReady() else { 
            print("Programmer key '\(text)' failed - keyboard not ready")
            return 
        }
        delegate?.insertText(text)
    }
    
    @objc private func alphabetKeyPressed(_ sender: UIButton) {
        // Find the original key from the alphabetKeys array
        guard let originalKey = findOriginalKey(for: sender) else { return }
        
        guard isKeyboardReady() else { return }
        
        let finalText = isShiftActive ? originalKey.uppercased() : originalKey
        delegate?.insertText(finalText)
        
        // Auto-disable shift after typing (like iOS keyboard)
        if isShiftActive {
            isShiftActive = false
            updateShiftState()
            updateAlphabetKeyTitles()
        }
    }
    
    @objc private func shiftPressed() {
        guard isKeyboardReady() else { return }
        
        isShiftActive.toggle()
        updateShiftState()
        updateAlphabetKeyTitles()
    }
    
    @objc private func backspacePressed() {
        guard isKeyboardReady() else { return }
        
        delegate?.deleteBackward()
    }
    
    @objc private func spacePressed() {
        guard let delegate = delegate,
              let keyboardVC = keyboardViewController,
              keyboardVC.isReady() else { 
            print("Space failed: delegate=\(delegate != nil), vc=\(keyboardViewController != nil), ready=\(keyboardViewController?.isReady() ?? false)")
            return 
        }
        
        delegate.insertText(" ")
    }
    
    @objc private func returnPressed() {
        guard let delegate = delegate,
              let keyboardVC = keyboardViewController,
              keyboardVC.isReady() else { return }
        
        delegate.insertReturn()
    }
    
    @objc private func cursorLeftPressed() {
        guard isKeyboardReady() else { return }
        delegate?.moveCursor(offset: -1)
    }
    
    @objc private func cursorRightPressed() {
        guard isKeyboardReady() else { return }
        delegate?.moveCursor(offset: 1)
    }
    
    
    // MARK: - Button State Management
    
    private func updateButtonStates(enabled: Bool) {
        
        // Update programmer buttons
        for row in programmerButtons {
            for button in row {
                button.isEnabled = enabled
                button.alpha = enabled ? 1.0 : 0.6
            }
        }
        
        // Update alphabet buttons
        for row in alphabetButtons {
            for button in row {
                button.isEnabled = enabled
                button.alpha = enabled ? 1.0 : 0.6
            }
        }
        
        // Update special buttons
        shiftButton?.isEnabled = enabled
        shiftButton?.alpha = enabled ? 1.0 : 0.6
        
        backspaceButton?.isEnabled = enabled
        backspaceButton?.alpha = enabled ? 1.0 : 0.6
        
        // Update bottom action buttons
        spaceButton?.isEnabled = enabled
        spaceButton?.alpha = enabled ? 1.0 : 0.6
        
        leftArrowButton?.isEnabled = enabled
        leftArrowButton?.alpha = enabled ? 1.0 : 0.6
        
        rightArrowButton?.isEnabled = enabled
        rightArrowButton?.alpha = enabled ? 1.0 : 0.6
        
        returnButton?.isEnabled = enabled
        returnButton?.alpha = enabled ? 1.0 : 0.6
        
    }
    
    // MARK: - Public Interface for Keyboard State
    
    func enableButtons() {
        // Only update if buttons are currently disabled to prevent unnecessary state changes
        if let firstButton = programmerButtons.first?.first, !firstButton.isEnabled {
            updateButtonStates(enabled: true)
            updateAlphabetKeyTitles()
        }
    }
    
    func disableButtons() {
        // Only update if buttons are currently enabled to prevent unnecessary state changes
        if let firstButton = programmerButtons.first?.first, firstButton.isEnabled {
            updateButtonStates(enabled: false)
            // Reset shift state when disabling buttons
            if isShiftActive {
                isShiftActive = false
                updateShiftState()
                updateAlphabetKeyTitles()
            }
        }
    }
    
    func resetShiftState() {
        if isShiftActive {
            isShiftActive = false
            updateShiftState()
            updateAlphabetKeyTitles()
        }
    }
    
    func isKeyboardReady() -> Bool {
        guard let keyboardVC = keyboardViewController else { return false }
        return keyboardVC.isReady()
    }
    
    // MARK: - Helper Methods
    
    private func findOriginalKey(for button: UIButton) -> String? {
        // Search through alphabetButtons to find the button and get its original key
        for (rowIndex, row) in alphabetButtons.enumerated() {
            for (keyIndex, btn) in row.enumerated() {
                if btn === button {
                    // Return the original key from alphabetKeys array
                    return alphabetKeys[rowIndex][keyIndex]
                }
            }
        }
        return nil
    }
    
    // MARK: - Shift State Management
    
    private func updateShiftState() {
        guard let shiftButton = shiftButton else { return }
        
        let colors = getCurrentColors()
        if isShiftActive {
            shiftButton.backgroundColor = colors.shiftActive
        } else {
            shiftButton.backgroundColor = colors.special
        }
    }
    
    private func updateAlphabetKeyTitles() {
        for (rowIndex, row) in alphabetButtons.enumerated() {
            for (keyIndex, button) in row.enumerated() {
                let originalKey = alphabetKeys[rowIndex][keyIndex]
                let displayText = isShiftActive ? originalKey.uppercased() : originalKey
                button.setTitle(displayText, for: .normal)
                
            }
        }
    }
    
    // MARK: - Visual Feedback (Using Built-in UIButton Behavior)
    // Removed custom touch event handlers - using built-in button visual feedback
    
    
    
    private func registerForTraitChangeNotifications() {
        // Use modern trait change registration on iOS 17+, fallback to traitCollectionDidChange on older versions
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: KeyboardView, previousTraitCollection: UITraitCollection) in
                self.updateKeyboardColorsForCurrentAppearance()
            }
        }
        // For iOS 15-16, traitCollectionDidChange will handle the changes
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // Only call super on iOS versions where it's not deprecated
        if #available(iOS 17.0, *) {
            // Don't call super on iOS 17+ as it's deprecated
        } else {
            super.traitCollectionDidChange(previousTraitCollection)
        }
        
        // Only update colors if the user interface style actually changed
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            updateKeyboardColorsForCurrentAppearance()
        }
    }
    
    private func updateColorsForCurrentTraitCollection() {
        colors = KeyColors(userInterfaceStyle: traitCollection.userInterfaceStyle)
    }
    
    private func updateKeyboardColorsForCurrentAppearance() {
        // Update colors without causing visual flashing
        let newColors = KeyColors(userInterfaceStyle: traitCollection.userInterfaceStyle)
        
        // Only update if colors actually changed to prevent unnecessary updates
        if newColors.alphabet != colors.alphabet {
            colors = newColors
            
            // Use a more efficient approach to prevent flashing
            // Disable implicit animations for all color changes
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            // Update all programmer buttons
            for (rowIndex, row) in programmerButtons.enumerated() {
                for (keyIndex, button) in row.enumerated() {
                    let key = numberSymbolKeys[rowIndex][keyIndex]
                    button.backgroundColor = getColorForNumberSymbolKey(key)
                }
            }
            
            // Update all alphabet buttons
            for row in alphabetButtons {
                for button in row {
                    button.backgroundColor = colors.alphabet
                }
            }
            
            // Update special buttons
            shiftButton?.backgroundColor = isShiftActive ? colors.shiftActive : colors.special
            backspaceButton?.backgroundColor = colors.special
            spaceButton?.backgroundColor = colors.special
            leftArrowButton?.backgroundColor = colors.special
            rightArrowButton?.backgroundColor = colors.special
            returnButton?.backgroundColor = colors.special
            
            CATransaction.commit()
        }
    }
    
}

// MARK: - KeyColors
private struct KeyColors {
    let alphabet: UIColor
    let number: UIColor
    let `operator`: UIColor
    let bracket: UIColor
    let punctuation: UIColor
    let quote: UIColor
    let underscore: UIColor
    let special: UIColor
    let shiftActive: UIColor
    
    init(userInterfaceStyle: UIUserInterfaceStyle) {
        if userInterfaceStyle == .dark {
            alphabet = .systemGray6
            number = .systemOrange
            `operator` = .systemRed
            bracket = .systemBlue
            punctuation = .systemPurple
            quote = .systemYellow
            underscore = .systemGreen
            special = .systemGray5
            shiftActive = .systemBlue
        } else {
            alphabet = .systemGray4
            number = .systemOrange
            `operator` = .systemRed
            bracket = .systemBlue
            punctuation = .systemPurple
            quote = .systemYellow
            underscore = .systemGreen
            special = .systemGray3
            shiftActive = .systemBlue
        }
    }
}

