// ActionButton.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 ActionButton
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


public typealias ActionButtonAction = (ActionButton) -> Void

@objc open class ActionButton: NSObject {

    /// The action the button should perform when tapped
    fileprivate var action: ActionButtonAction?

    /// The button's background color : set default color and selected color
    @objc open var backgroundColor: UIColor = UIColor(red: 238.0/255.0, green: 130.0/255.0, blue: 34.0/255.0, alpha:1.0) {
        willSet {
            floatButton.backgroundColor = newValue
            backgroundColorSelected = newValue
        }
    }

    /// The button's background color : set default color
    @objc open var backgroundColorSelected: UIColor = UIColor(red: 238.0/255.0, green: 130.0/255.0, blue: 34.0/255.0, alpha:1.0)

    /// Indicates if the buttons is active (showing its items)
    @objc fileprivate(set) open var active: Bool = false

    /// An array of items that the button will present
    @objc open var items: [ActionButtonItem]? {
        willSet {
            for abi in self.items! {
                abi.view.removeFromSuperview()
            }
        }
        didSet {
            placeButtonItems()
            showActive(true)
        }
    }

    /// The button that will be presented to the user
    fileprivate var floatButton: UIButton!

    /// Wether the float button should be hidden or not
    @objc open var hidden: Bool = false {
        didSet {
            self.floatButton.isHidden = self.hidden;
        }
    }


    /// View that will hold the placement of the button's actions
    fileprivate var contentView: UIView!

    /// View where the *floatButton* will be displayed
    fileprivate var parentView: UIView!

    /// Blur effect that will be presented when the button is active
    fileprivate var blurVisualEffectView: UIVisualEffectView!

    // Distance between each item action
    fileprivate let itemOffset = -55

    /// the float button's radius
    fileprivate let floatButtonRadius = 50


    @objc open func setAction(_ action : @escaping ActionButtonAction) -> ActionButton{
        self.action = action
        return self
    }
    @objc public init(attachedToView view: UIView, items: [ActionButtonItem]?) {
        super.init()

        self.parentView = view
        self.items = items
        let bounds = self.parentView.bounds

        self.floatButton = UIButton(type: .custom)
        self.floatButton.layer.cornerRadius = CGFloat(floatButtonRadius / 2)
        self.floatButton.layer.shadowOpacity = 1
        self.floatButton.layer.shadowRadius = 2
        self.floatButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        self.floatButton.layer.shadowColor = UIColor.gray.cgColor
        self.floatButton.setTitle("+", for: UIControlState())
        self.floatButton.setImage(nil, for: UIControlState())
        self.floatButton.backgroundColor = self.backgroundColor
        self.floatButton.titleLabel!.font = UIFont(name: "HelveticaNeue-Light", size: 35)
        self.floatButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        self.floatButton.isUserInteractionEnabled = true
        self.floatButton.translatesAutoresizingMaskIntoConstraints = false

        self.floatButton.addTarget(self, action: #selector(ActionButton.buttonTapped(_:)), for: .touchUpInside)
        self.floatButton.addTarget(self, action: #selector(ActionButton.buttonTouchDown(_:)), for: .touchDown)
        self.parentView.addSubview(self.floatButton)

        self.contentView = UIView(frame: bounds)
        self.contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.contentView.isOpaque = false
        self.contentView.backgroundColor = UIColor.clear

        self.blurVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        self.blurVisualEffectView.alpha = 0.0
        self.blurVisualEffectView.frame = self.contentView.frame
        self.blurVisualEffectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        let tap = UITapGestureRecognizer(target: self, action: #selector(ActionButton.backgroundTapped(_:)))
        self.contentView.addGestureRecognizer(tap)

        self.installConstraints()
    }

    @objc open func setTitle(_ title: String?, forState state: UIControlState) -> ActionButton {
        if let newTitle = title {
            self.floatButton.setTitle(newTitle, for: state)
            self.floatButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: newTitle.characters.count > 0 ? 8 : 0, right: 0)
        }
        return self
    }

    @objc open func setImage(_ image: UIImage?, forState state: UIControlState) -> ActionButton {
        if let newImage = image{
            self.floatButton.setImage(newImage, for: state)
            self.floatButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: self.floatButton.currentTitle?.characters.count > 0 ? 0 : 8, right: 0)
        }
        return self
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Auto Layout Methods
    /**
     Install all the necessary constraints for the button. By the default the button will be placed at 15pts from the bottom and the 15pts from the right of its *parentView*
     */
    fileprivate func installConstraints() {
        let views: [String: UIView]  = ["floatButton":self.floatButton, "parentView":self.parentView]
        let width = NSLayoutConstraint.constraints(withVisualFormat: "H:[floatButton(\(floatButtonRadius))]", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: views)
        let height = NSLayoutConstraint.constraints(withVisualFormat: "V:[floatButton(\(floatButtonRadius))]", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: views)
        self.floatButton.addConstraints(width)
        self.floatButton.addConstraints(height)

        let trailingSpacing = NSLayoutConstraint.constraints(withVisualFormat: "V:[floatButton]-15-|", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: views)
        let bottomSpacing = NSLayoutConstraint.constraints(withVisualFormat: "H:[floatButton]-15-|", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: views)
        self.parentView.addConstraints(trailingSpacing)
        self.parentView.addConstraints(bottomSpacing)
    }

    //MARK: - Button Actions Methods
    @objc func buttonTapped(_ sender: UIControl) {
        animatePressingWithScale(1.0)

        if let unwrappedAction = self.action {
            unwrappedAction(self)
        }
    }

    @objc func buttonTouchDown(_ sender: UIButton) {
        animatePressingWithScale(0.9)
    }

    //MARK: - Gesture Recognizer Methods
    @objc func backgroundTapped(_ gesture: UIGestureRecognizer) {
        if self.active {
            self.toggle()
        }
    }

    //MARK: - Custom Methods
    /**
     Presents or hides all the ActionButton's actions
     */
    @objc open func toggleMenu() {
        self.placeButtonItems()
        self.toggle()
    }

    //MARK: - Action Button Items Placement
    /**
     Defines the position of all the ActionButton's actions
     */
    fileprivate func placeButtonItems() {
        if let optionalItems = self.items {
            for item in optionalItems {
                item.view.center = CGPoint(x: self.floatButton.center.x - 133, y: self.floatButton.center.y)
                item.view.removeFromSuperview()
                item.view.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]

                self.contentView.addSubview(item.view)
            }
        }
    }

    //MARK - Float Menu Methods
    /**
     Presents or hides all the ActionButton's actions and changes the *active* state
     */
    fileprivate func toggle() {
        self.animateMenu()

        self.active = !self.active

        if (self.active) {
            self.showBlur()
        }

        self.floatButton.backgroundColor = self.active ? backgroundColorSelected : backgroundColor
        self.floatButton.isSelected = self.active
    }

    fileprivate func animateMenu() {
        let pi4 = Double.pi / 4.0
        let rotation = self.active ? CGFloat(-pi4 / 2.0) : CGFloat(pi4 + (pi4 / 2.0))

        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: UIViewAnimationOptions.allowAnimatedContent, animations: {

            if self.floatButton.currentTitle == "+" && self.floatButton.imageView?.image == nil {
                self.floatButton.transform = CGAffineTransform(rotationAngle: rotation)
            }

            self.showActive(false)

            if self.active {
                self.blurVisualEffectView.alpha = 0.0
            }

        }, completion: { completed in
            UIView.animate(withDuration: 0.08, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: UIViewAnimationOptions.allowAnimatedContent, animations: {

                if self.floatButton.currentTitle == "+" && self.floatButton.imageView?.image == nil {
                    self.floatButton.transform = CGAffineTransform(rotationAngle: self.active ? CGFloat(pi4) : CGFloat(0))
                }

                if (!self.active) {
                    self.blurVisualEffectView.removeFromSuperview()
                    self.contentView.removeFromSuperview()
                }

            }, completion: {
                completed in
            })
        })
    }

    fileprivate func showActive(_ active: Bool) {
        if self.active == active {
            self.contentView.alpha = 1.0

            if let optionalItems = self.items {
                for (index, item) in optionalItems.enumerated() {
                    let offset = index + 1
                    let translation = self.itemOffset * offset
                    item.view.transform = CGAffineTransform(translationX: 0, y: CGFloat(translation))
                    item.view.alpha = 1
                }
            }
        } else {
            self.contentView.alpha = 0.0

            if let optionalItems = self.items {
                for item in optionalItems {
                    item.view.transform = CGAffineTransform(translationX: 0, y: 0)
                    item.view.alpha = 0
                }
            }
        }
    }

    fileprivate func showBlur() {
        //self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y, self.parentView.frame.size.width, self.parentView.frame.size.height)
        self.blurVisualEffectView.frame = CGRect(x: self.contentView.frame.origin.x, y: self.contentView.frame.origin.y, width: self.parentView.frame.size.width, height: self.parentView.frame.size.height)

        self.parentView.insertSubview(self.contentView, belowSubview: self.floatButton)
        self.parentView.insertSubview(self.blurVisualEffectView, belowSubview: self.contentView)
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.blurVisualEffectView.alpha = 0.95
        })
    }

    /**
     Animates the button pressing, by the default this method just scales the button down when it's pressed and returns to its normal size when the button is no longer pressed

     - parameter scale: how much the button should be scaled
     */
    fileprivate func animatePressingWithScale(_ scale: CGFloat) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: UIViewAnimationOptions.allowAnimatedContent, animations: {
            self.floatButton.transform = CGAffineTransform(scaleX: scale, y: scale)
        }, completion: nil)
    }
}

